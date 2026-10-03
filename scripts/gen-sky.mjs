/**
 * マップ一面を青空にして、雲と浮島を足す。
 *   node scripts/gen-sky.mjs [map.json] [--out map.json]
 *
 *  1. sea レイヤーの空きマスを、公式マップと同じ 4x4 繰り返しの空(海)タイルで埋める。
 *  2. 浮島: 公式マップの小さな浮島(草の面＋茶色の崖)を「左端・中央の繰り返し・右端」の型に分解し、
 *     幅と高さを変えて何個も作る。草の面は歩ける、崖は通れない。木も数本立てる。
 *  3. 雲: Clouds 01/02 のオートタイルで、角を落とした長方形の雲を空の部分にだけ置く。
 *  4. 当たり判定: 地面(land/paths)が無いマス＝空は通れなくする（既に塞いである所はそのまま）。
 * 既存の地面・建物・配置物・ワープは消さない（空のマスに足すだけ）。
 */
import { readFileSync, writeFileSync } from "node:fs";

const args = process.argv.slice(2);
const opt = (k, d) => (args.includes(`--${k}`) ? args[args.indexOf(`--${k}`) + 1] : d);
const inPath = args.find((a) => !a.startsWith("--")) ?? "client/src/config/map.json";
const outPath = opt("out", inPath);
// --grid 6x5: 同じ形の平らな島を 列x行 並べる（木なし）。--m/--k は島の中央の列数・草の面の行数
const GRID = opt("grid", null);
const IM = Number(opt("m", 10)), IK = Number(opt("k", 6));
const GAPX = Number(opt("gapx", 5)), GAPY = Number(opt("gapy", 4)), MARGIN = Number(opt("margin", 3));
const NO_TREES = args.includes("--no-trees") || !!GRID;

const map = JSON.parse(readFileSync(inPath, "utf8"));
const W = map.width, H = map.height, TS = 16;
const layer = (name) => map.tileLayers.find((l) => l.name === name);
const sea = layer("sea"), land = layer("land"), shadows = layer("shadows");
const paths = layer("paths"), deco1 = layer("decoration_01");
const clouds1 = layer("clouds_01"), clouds2 = layer("clouds_02"), cloudShadow = layer("cloud_shadow");
map.objects ??= [];

let seed = 20261003;
const rnd = () => {
  seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const ri = (a, b) => a + Math.floor(rnd() * (b - a + 1));

const hasGround = (x, y) =>
  [land, paths, deco1, layer("building"), layer("walls")].some((l) => (l.data[y]?.[x] ?? -1) >= 0);

// ---------------------------------------------------------------- 1. 空
// 公式マップの sea は (18+y%4)行目・11+x%4列目 の 4x4 を繰り返している
for (let y = 0; y < H; y++)
  for (let x = 0; x < W; x++) if (sea.data[y][x] < 0) sea.data[y][x] = (18 + (y % 4)) * 64 + 11 + (x % 4);

// ---------------------------------------------------------------- 2. 浮島
// 公式マップ左上の小さな浮島を型にした。列: [左端2列][中央m列(繰り返し)][右端2列]
// 行: 上の縁(T)・草の面(I)×k・草の下端(B)・崖×3(C1,C2,C3)。-1は空き
const ISLAND = {
  T: { l: [-1, 200], mid: () => 196, r: [260, -1] },
  I: { l: [-1, 198], mid: () => 193, r: [259, -1] },
  B: { l: [4096, 262], mid: () => 261, r: [263, 4103] },
  C1: { l: [4113, 266], mid: (i) => (i % 2 ? 203 : 4114), r: [4115, 4116] },
  C2: { l: [4118, 4120], mid: (i) => (i % 2 ? 4114 : 203), r: [147, 403] },
  C3: { l: [-1, 4118], mid: () => 148, r: [403, -1] },
};
const SHADOW_ROW = 76; // 崖の下の影(海の上)

/** 島を ox,oy に置く。中央 m 列・草の面の高さ k 行。置けない(既存の地面と重なる)なら false */
function placeIsland(ox, oy, m, k) {
  const w = m + 4, h = k + 5;
  if (ox < 0 || oy < 0 || ox + w > W || oy + h > H) return false;
  for (let y = oy - 1; y < oy + h + 1; y++)
    for (let x = ox - 1; x < ox + w + 1; x++) if (x >= 0 && y >= 0 && x < W && y < H && hasGround(x, y)) return false;

  const rows = ["T", ...Array(k).fill("I"), "B", "C1", "C2", "C3"];
  rows.forEach((name, j) => {
    const def = ISLAND[name];
    const cells = [...def.l, ...Array.from({ length: m }, (_, i) => def.mid(i)), ...def.r];
    cells.forEach((id, i) => {
      if (id < 0) return;
      const x = ox + i, y = oy + j;
      land.data[y][x] = id;
      // 草の面(T/I/B)は歩ける。B行の両端の小さな角と崖は通れない
      const grass = name === "T" || name === "I" || name === "B";
      const cap = name === "B" && (i === 0 || i === w - 1);
      map.layers.collision[y][x] = grass && !cap ? 0 : 1;
    });
  });
  // 崖の下の影
  const sy = oy + k + 4;
  for (let i = 1; i <= w - 2; i++) if (shadows.data[sy]?.[ox + i] === -1) shadows.data[sy][ox + i] = SHADOW_ROW;

  // 木を数本（スプライトは 32x34、原点は左上。足元は y+34）
  const trees = NO_TREES ? 0 : ri(0, Math.min(3, m - 1));
  const placed = [];
  for (let t = 0; t < trees; t++) {
    for (let attempt = 0; attempt < 12; attempt++) {
      const cx = ox + 2 + ri(0, Math.max(0, m - 2)); // 2マス幅なので中央列の範囲に収める
      const top = oy + ri(0, Math.max(0, k - 1)); // 足元が草の下端(B行)を超えない
      if (placed.some((p) => Math.abs(p.cx - cx) < 3 && Math.abs(p.top - top) < 2)) continue;
      placed.push({ cx, top });
      const x = cx * TS, y = top * TS;
      const sprite = rnd() < 0.7 ? "spr_deco_tree_01" : "spr_deco_tree_02";
      map.objects.push({ sprite, x, y, sort: "y", by: y + 34, frame: ri(0, 3), hit: [12, 8], hx: x + 16 });
      break;
    }
  }
  return true;
}

// 幅(m)・草の高さ(k)を変えた島を、既存の地面と重ならない場所に置く。置けなければ位置をずらして試す
const ISLANDS = [
  [2, 2, 5, 2], [12, 5, 3, 1], [3, 14, 7, 3], [13, 22, 3, 2], [4, 34, 4, 2],
  [47, 2, 7, 3], [55, 11, 3, 1], [46, 20, 8, 4], [54, 31, 3, 2], [47, 35, 5, 1],
];
let made = 0;
if (GRID) {
  // 同じ大きさの平らな島を格子状に並べる。スポーンは中ほどの島の中央に置く
  const [C, R] = GRID.split("x").map(Number);
  const iw = IM + 4, ih = IK + 5;
  const needW = MARGIN * 2 + C * iw + (C - 1) * GAPX, needH = MARGIN * 2 + R * ih + (R - 1) * GAPY;
  if (needW > W || needH > H) {
    console.error(`マップが小さすぎます: ${C}x${R} 個には ${needW}x${needH} マス必要（今は ${W}x${H}）。先に node scripts/gen-blank-canvas.mjs --w ${needW} --h ${needH} で作り直してください`);
    process.exit(1);
  }
  const offX = Math.floor((W - (C * iw + (C - 1) * GAPX)) / 2), offY = Math.floor((H - (R * ih + (R - 1) * GAPY)) / 2);
  const spawnCol = Math.floor((C - 1) / 2), spawnRow = Math.floor((R - 1) / 2);
  for (let r = 0; r < R; r++)
    for (let c = 0; c < C; c++) {
      const ox = offX + c * (iw + GAPX), oy = offY + r * (ih + GAPY);
      if (placeIsland(ox, oy, IM, IK)) made++;
      else console.warn(`島 (${c},${r}) を置けませんでした`);
      if (c === spawnCol && r === spawnRow) map.spawn = { x: ox + 2 + Math.floor(IM / 2), y: oy + 1 + Math.floor(IK / 2) };
    }
  console.log(`浮島 ${made}/${C * R}（${iw}x${ih}マス・平地）、スポーン (${map.spawn.x},${map.spawn.y})`);
} else {
  // スポーン地点が空の上だと動けなくなるので、スポーン(map.spawn)を中心にした大きめの島を最初に置く
  {
    const sx = map.spawn.x, sy = map.spawn.y;
    if (!placeIsland(sx - 6, sy - 4, 8, 5)) console.warn("スポーン島を置けませんでした（既存の地面と重なっています）。スポーンを動かすか、その周りを空けてください");
    else made++;
  }
  for (const [ox, oy, m, k] of ISLANDS) {
    let ok = false;
    for (let dy = 0; dy < 6 && !ok; dy++) for (let dx = 0; dx < 5 && !ok; dx++) ok = placeIsland(ox + dx, oy + dy, m, k);
    if (ok) made++;
    else console.warn(`島 (${ox},${oy}) m=${m} k=${k} は置けませんでした`);
  }
  console.log(`浮島 ${made}/${ISLANDS.length + 1}（スポーン島を含む）`);
}

// ---------------------------------------------------------------- 3. 雲
/** 角を落とした長方形(半幅a・半高b・面取りc)のマスク。マップの外にはみ出した分は clampEdges で続いているように見せる */
function blobMask(cx, cy, a, b, c, avoid) {
  const m = Array.from({ length: H }, () => Array(W).fill(false));
  for (let y = 0; y < H; y++)
    for (let x = 0; x < W; x++) {
      const dx = Math.abs(x - cx), dy = Math.abs(y - cy);
      if (dx > a || dy > b || dx + dy > a + b - c) continue;
      // 島などにぶつかる雲は、欠けた形になるので置かない（nullを返す）
      if (avoid && avoid(x, y)) return null;
      m[y][x] = true;
    }
  return m;
}
const tilesetJson = JSON.parse(readFileSync("client/src/config/tileset.json", "utf8"));
/**
 * 雲のオートタイル。Land/Path と違い、縁・角のタイルは雲の形を1枚で持っている（地面を下に敷かない）。
 * 公式マップの雲の並びから実測した割り当て(tiles配列のindex):
 *   縁 N=3 S=12 W=5 E=10 ／ 外側の角 TL=7 TR=11 SW=13 SE=14 ／ 内側の角 TL=1 TR=2 BL=4 BR=8
 * clamp=true ならマップの外も端と同じ扱い（雲がマップの外へ続いて見える）。
 */
function paintCloud(target, group, mask, clamp) {
  const t = tilesetJson.autotileGroups[group].tiles;
  const inM = (x, y) => (clamp ? mask[Math.min(H - 1, Math.max(0, y))][Math.min(W - 1, Math.max(0, x))] : !!mask[y]?.[x]);
  for (let y = 0; y < H; y++)
    for (let x = 0; x < W; x++) {
      if (!mask[y][x]) continue;
      const n = !inM(x, y - 1), s = !inM(x, y + 1), w = !inM(x - 1, y), e = !inM(x + 1, y);
      let id = t[0];
      if (n && w) id = t[7];
      else if (n && e) id = t[11];
      else if (s && w) id = t[13];
      else if (s && e) id = t[14];
      else if (n) id = t[3];
      else if (s) id = t[12];
      else if (w) id = t[5];
      else if (e) id = t[10];
      else if (!inM(x - 1, y - 1)) id = t[1];
      else if (!inM(x + 1, y - 1)) id = t[2];
      else if (!inM(x - 1, y + 1)) id = t[4];
      else if (!inM(x + 1, y + 1)) id = t[8];
      target.data[y][x] = id;
    }
}
const sky = (x, y) => !hasGround(x, y);
const notSky = (x, y) => !sky(x, y);

// 奥の雲(clouds_02)と、手前の薄い雲(clouds_01)。どちらも地面の上には置かない
let BACK = [
  [8, 10, 4, 2, 2], [18, 3, 5, 2, 2], [56, 7, 4, 2, 2], [10, 28, 5, 2, 2], [58, 28, 4, 3, 2], [52, 42, 6, 2, 2], [4, 42, 5, 2, 2], [40, 1, 3, 1, 1],
  [36, 6, 5, 2, 2], [39, 40, 5, 2, 2], [41, 20, 4, 2, 2], [25, 6, 4, 2, 2], [24, 40, 5, 2, 2], [36, 30, 3, 2, 1],
];
let FRONT = [[1, 22, 3, 2, 1], [62, 20, 3, 3, 1], [34, 43, 6, 2, 2], [20, 40, 4, 2, 2], [60, 2, 3, 2, 1], [38, 13, 4, 2, 2], [31, 36, 4, 2, 2], [44, 27, 3, 1, 1]];
if (GRID) {
  // 島の数に合わせて広いマップなので、雲は乱数で空の部分にばらまく（同じレイヤーの雲同士が重ならないように）
  const taken = { back: new Set(), front: new Set() };
  const gen = (list, key, count) => {
    for (let attempt = 0; attempt < count * 30 && list.length < count; attempt++) {
      // 小さすぎると三角やひし形の破片になるので、半幅3以上・半高2以上にする
      const a = ri(3, 6), b = ri(2, 3), c = 1, cx = ri(0, W - 1), cy = ri(0, H - 1);
      const cells = [];
      for (let y = cy - b - 1; y <= cy + b + 1; y++) for (let x = cx - a - 1; x <= cx + a + 1; x++) cells.push(`${x},${y}`);
      if (cells.some((s) => taken[key].has(s))) continue;
      const mask = blobMask(cx, cy, a, b, c, notSky);
      if (!mask) continue;
      cells.forEach((s) => taken[key].add(s));
      list.push([cx, cy, a, b, c]);
    }
  };
  BACK = [];
  FRONT = [];
  gen(BACK, "back", Math.round((W * H) / 450));
  gen(FRONT, "front", Math.round((W * H) / 800));
}
let cloudCount = 0;
for (const [cx, cy, a, b, c] of BACK) {
  const mask = blobMask(cx, cy, a, b, c, notSky);
  if (!mask) continue;
  paintCloud(clouds2, "Clouds 02", mask, true);
  cloudCount++;
  // 雲の影: 少し下にずらす。雲自身や地面にかかる分は欠けさせずに、その部分だけ影を省く
  const shadow = blobMask(cx, cy + 3, a, b, c, null);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (shadow[y][x] && (mask[y][x] || notSky(x, y))) shadow[y][x] = false;
  paintCloud(cloudShadow, "Cloud Shadow", shadow, true);
}
for (const [cx, cy, a, b, c] of FRONT) {
  const mask = blobMask(cx, cy, a, b, c, notSky);
  if (!mask) continue;
  paintCloud(clouds1, "Clouds 01", mask, true);
  cloudCount++;
}
console.log(`雲 ${cloudCount}/${BACK.length + FRONT.length}`);

// ---------------------------------------------------------------- 4. 当たり判定: 空は通れない
let blocked = 0;
for (let y = 0; y < H; y++)
  for (let x = 0; x < W; x++) {
    const ground = (land.data[y][x] >= 0 || paths.data[y][x] >= 0);
    if (!ground && map.layers.collision[y][x] === 0) { map.layers.collision[y][x] = 1; blocked++; }
  }
console.log(`空のマス ${blocked} を通れなくしました`);

writeFileSync(outPath, JSON.stringify(map));
console.log(`wrote ${outPath}`);
