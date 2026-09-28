/**
 * 「リタイル」: 同じタイルで塗りつぶされた地面を、自然な見た目（オートタイルの縁取り＋濃淡のばらつき）に描き直す。
 *   node scripts/retile.mjs [map.json] [--out map.json]
 *
 * 手順:
 *   1. 対象レイヤー(land/paths/decoration_01)の使用中タイルを、タイルセット画像の平均色から
 *      「緑(草)」「茶(道)」に自動分類する（色で決めるので、次に別の色で塗った場所にもそのまま使える）。
 *   2. 分類できたマスをいったん空にし、Land/Path 01 のオートタイルで塗り直す（境界がなめらかになる）。
 *   3. 緑の範囲にだけ、草むら模様(GRASS_DETAIL)を薄く散らして単調さをなくす。
 * 建物・柵・当たり判定・配置物・ワープは一切触らない。
 */
import { readFileSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";
import { Grid, tid, paintRegion } from "./lib/tilekit.mjs";

const args = process.argv.slice(2);
const opt = (k, d) => (args.includes(`--${k}`) ? args[args.indexOf(`--${k}`) + 1] : d);
const inPath = args.find((a) => !a.startsWith("--")) ?? "client/src/config/map.json";
const outPath = opt("out", inPath);

const map = JSON.parse(readFileSync(inPath, "utf8"));
const W = map.width, H = map.height;
const TS_PX = 16;

const ts = PNG.sync.read(readFileSync("client/public/assets/tilesets/sunnyside_16.png"));
const colorCache = new Map();
function avgColor(id) {
  if (colorCache.has(id)) return colorCache.get(id);
  const c = id % 64, r = Math.floor(id / 64);
  let R = 0, G = 0, B = 0, n = 0;
  for (let y = 0; y < TS_PX; y++)
    for (let x = 0; x < TS_PX; x++) {
      const i = ((r * TS_PX + y) * ts.width + c * TS_PX + x) * 4;
      if (ts.data[i + 3] > 0) { R += ts.data[i]; G += ts.data[i + 1]; B += ts.data[i + 2]; n++; }
    }
  const v = n ? { r: R / n, g: G / n, b: B / n } : null;
  colorCache.set(id, v);
  return v;
}
/** 平均色から「緑」「茶」「その他」に分類 */
function classify(id) {
  if (id < 0 || id >= 4096) return null; // 拡張タイルセット分は対象外（sunnyside_16.pngに無い）
  const c = avgColor(id);
  if (!c) return null;
  if (c.g - c.r > 18 && c.g - c.b > 18) return "green";
  if (c.r - c.g > 25 && c.r - c.b > 30) return "brown";
  return null;
}

const TARGET_LAYERS = ["land", "paths", "decoration_01"];
const greenMask = Array.from({ length: H }, () => Array(W).fill(false));
const brownMask = Array.from({ length: H }, () => Array(W).fill(false));
let greenCount = 0, brownCount = 0;

for (const layer of map.tileLayers) {
  if (!TARGET_LAYERS.includes(layer.name)) continue;
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const id = layer.data[y]?.[x];
      if (id === undefined || id < 0) continue;
      const kind = classify(id);
      if (kind === "green" && !greenMask[y][x]) { greenMask[y][x] = true; greenCount++; }
      else if (kind === "brown" && !brownMask[y][x]) { brownMask[y][x] = true; brownCount++; }
    }
  }
}
console.log(`検出: 緑 ${greenCount}マス・茶 ${brownCount}マス`);
if (!greenCount && !brownCount) {
  console.log("対象タイルが見つかりませんでした（land/paths/decoration_01 に緑・茶系のタイルが無い）。");
  process.exit(0);
}

// ---- 対象マスをいったん空にする
const layerByName = Object.fromEntries(map.tileLayers.filter((l) => TARGET_LAYERS.includes(l.name)).map((l) => [l.name, l]));
for (let y = 0; y < H; y++)
  for (let x = 0; x < W; x++) {
    if (!greenMask[y][x] && !brownMask[y][x]) continue;
    for (const name of TARGET_LAYERS) if (layerByName[name].data[y][x] >= 0) layerByName[name].data[y][x] = -1;
  }

// ---- オートタイルで塗り直す（ground=land/paths、edge/corner=decoration_01 に重ねる）
const greenGround = new Grid(W, H), greenDeco = new Grid(W, H);
paintRegion(greenGround, greenDeco, greenMask, "Land", { under: tid(1, 3) });
const brownGround = new Grid(W, H), brownDeco = new Grid(W, H);
paintRegion(brownGround, brownDeco, brownMask, "Path 01", { under: tid(1, 3) });

const mergeInto = (layerName, grid) => {
  const data = layerByName[layerName].data;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (grid.a[y][x] >= 0) data[y][x] = grid.a[y][x];
};
mergeInto("land", greenGround);
mergeInto("paths", brownGround);
mergeInto("decoration_01", greenDeco);
mergeInto("decoration_01", brownDeco); // 緑と茶は排他なので上書きし合わない

// ---- 緑の範囲に草むら模様(GRASS_DETAIL)を薄く散らす（gen-map.mjs と同じ実測タイル）
let seed = 20260930;
const rnd = () => {
  seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const GRASS_DETAIL = [129, 130, 131, 132, 133, 134];
const decoData = layerByName.decoration_01.data;
let detailCount = 0;
for (let y = 0; y < H; y++)
  for (let x = 0; x < W; x++) {
    if (!greenMask[y][x] || decoData[y][x] >= 0) continue; // 縁のタイルが既にあるマスは避ける
    if (rnd() > 0.08) continue;
    decoData[y][x] = GRASS_DETAIL[Math.floor(rnd() * GRASS_DETAIL.length)];
    detailCount++;
  }
console.log(`草むら模様を ${detailCount}マスに追加`);

writeFileSync(outPath, JSON.stringify(map));
console.log(`wrote ${outPath}`);
