/**
 * Sunnyside World 元パックの GameMaker ルーム(Room1)を、このプロジェクトの map.json に変換する。
 *   node scripts/import-gm-room.mjs "<...>/Sunnyside_World_ASSET_PACK_V2.1"   (Assets と Gamemaker が並ぶ階層)
 *
 * 出力:
 *   client/src/config/map.json            タイル13層 + 配置物(objects) + スプライト定義 + 衝突
 *   client/public/assets/tilesets/*_ext.png   反転・回転を焼き込んだ拡張タイルセット
 *   client/public/assets/gm/<sprite>.png      配置物のスプライトシート(フレームを横一列)
 *
 * 反転・回転の解釈は実物との照合で確定済み: 「ミラー/フリップ → 90°時計回り回転」(scripts/gm-tiles-test.mjs)。
 */
import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { PNG } from "pngjs";
import { parseYY, decodeTiles, splitTile, makeExtendedTileset, buildGmSprite } from "./lib/gm.mjs";
import { addMobCatalog } from "./lib/mobcatalog.mjs";

const PACK = process.argv[2];
if (!PACK) throw new Error("usage: node scripts/import-gm-room.mjs <pack root>");
const GM = join(PACK, "Sunnyside_World_Gamemaker");
const OUT_MAP = process.argv.includes("--out") ? process.argv[process.argv.indexOf("--out") + 1] : "client/src/config/map.json";
const T = 16;

const room = parseYY(join(GM, "rooms", "Room1", "Room1.yy"));
const layerByName = (n) => room.layers.find((l) => l.name === n);

// ---------------------------------------------------------------- 1. 拡張タイルセット
const opts = { order: "flip-first", rotDir: "cw" };
const mainBase = PNG.sync.read(readFileSync("client/public/assets/tilesets/sunnyside_16.png"));
const forestBase = PNG.sync.read(readFileSync("client/public/assets/tilesets/sunnyside_forest_32.png"));
const extMain = makeExtendedTileset(mainBase, 16, 64, opts);
const extForest = makeExtendedTileset(forestBase, 32, 10, opts);

// 奥→手前の順（GameMaker は depth が大きいほど奥）。mode: floor=キャラより下 / ysort=行ごとにキャラと前後判定 / top=最前面
const LAYERS = [
  ["sea", "floor"], ["clouds_02", "floor"], ["land", "floor"], ["paths", "floor"], ["shadows", "floor"], ["decoration_01", "floor"],
  ["forest", "ysort"], ["building", "ysort"], ["walls", "ysort"], ["decoration_02", "ysort"], ["decoration_03", "ysort"],
  ["cloud_shadow", "top"], ["clouds_01", "top"],
];
const tileLayers = [];
const rawIds = {}; // 衝突判定用（変換前のタイル番号）
for (const [name, mode] of LAYERS) {
  const l = layerByName(name);
  const isForest = l.tilesetId.name === "tileset_forest";
  const { w, h, values } = decodeTiles(l);
  const tiles = values.map(splitTile);
  const ext = isForest ? extForest : extMain;
  const ids = tiles.map((t) => ext.resolve(t));
  const data = [];
  for (let y = 0; y < h; y++) data.push(ids.slice(y * w, (y + 1) * w));
  tileLayers.push({ name, tileset: isForest ? "forest" : "main", mode, data });
  rawIds[name] = { w, h, tiles, ids, isForest };
}
mkdirSync("client/public/assets/tilesets", { recursive: true });
writeFileSync("client/public/assets/tilesets/sunnyside_16_ext.png", PNG.sync.write(extMain.build()));
if (extForest.count() > 0) writeFileSync("client/public/assets/tilesets/sunnyside_forest_32_ext.png", PNG.sync.write(extForest.build()));
const forestImage = extForest.count() > 0 ? "tilesets/sunnyside_forest_32_ext.png" : "tilesets/sunnyside_forest_32.png";
console.log(`tilesets: main variants ${extMain.count()}, forest variants ${extForest.count()}`);

// ---------------------------------------------------------------- 2. 配置物（スプライト）
const assets = [...layerByName("Assets_1").assets.map((a) => ({ a, layer: "a1" })), ...layerByName("Assets_2").assets.map((a) => ({ a, layer: "a2" }))];
const spriteDefs = {};
mkdirSync("client/public/assets/gm", { recursive: true });

const buildSprite = (name) => buildGmSprite(GM, name);

// 影・床に敷くものは「キャラより下」、それ以外は足元Yで前後判定
const FLOOR_SPRITES = /shadow|charactershadow/;
// 当たり判定（足元中央を基準にした幅×高さ px）。木・樽・箱・井戸など
const SOLID = (name, def) => {
  if (name === "spr_deco_tree_01" || name === "spr_deco_tree_02") return [12, 8];
  if (/barrel|crate|chest|jar_0|well|anvil|firepit|campfire|minecart|sidetable|trough|chair/.test(name)) return [Math.max(6, Math.min(def.fw - 2, 14)), 6];
  return null;
};
const objects = [];
for (const { a, layer } of assets) {
  const name = a.spriteId?.name;
  if (!name) continue;
  if (!spriteDefs[name]) spriteDefs[name] = buildSprite(name);
  const def = spriteDefs[name];
  const sx = a.scaleX, sy = a.scaleY;
  // 足元Y: 原点から見た下端。キャラ(96x64)は原点が体の中央なので足元は原点+8
  const isChar = def.fw === 96 && def.fh === 64;
  const bottom = isChar ? a.y + 8 : a.y + (def.fh - def.oy) * Math.abs(sy);
  const sort = FLOOR_SPRITES.test(name) ? "floor" : "y";
  const o = { sprite: name, x: round(a.x), y: round(a.y), sort, by: round(bottom) };
  if (sx !== 1) o.sx = round(sx, 4);
  if (sy !== 1) o.sy = round(sy, 4);
  if (a.rotation) o.angle = round(-a.rotation, 3); // GameMaker は反時計回りが正、Phaser は時計回りが正
  // headPosition は負になりうる（アニメの周期で回る）ので、0..frames-1 に正規化する
  if (a.headPosition) o.frame = ((Math.floor(a.headPosition) % def.frames) + def.frames) % def.frames;
  if (a.animationSpeed !== 1) o.speed = round(a.animationSpeed, 3);
  const hit = SOLID(name, def);
  if (hit) {
    o.hit = hit;
    // 当たり判定の中心X（原点が左上のスプライトは画像の中央下）
    o.hx = round(a.x + (def.fw / 2 - def.ox) * sx);
  }
  objects.push(o);
}
console.log(`objects: ${objects.length}, unique sprites: ${Object.keys(spriteDefs).length}`);

// ---------------------------------------------------------------- 3. 衝突判定（86x48）
const W = 86, H = 48;
const tsPixels = (img, cols, size) => (id) => {
  const c = id % cols, r = Math.floor(id / cols);
  const px = [];
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const i = ((r * size + y) * img.width + c * size + x) * 4;
    if (img.data[i + 3] > 200) px.push([img.data[i], img.data[i + 1], img.data[i + 2]]);
  }
  return px;
};
const mainPx = tsPixels(PNG.sync.read(readFileSync("client/public/assets/tilesets/sunnyside_16_ext.png")), 64, 16);
const classCache = new Map();
/** 地面タイルの種類: walk=歩ける / cliff=崖の面 / water=水 / none=ほぼ透明 */
function groundClass(id) {
  if (classCache.has(id)) return classCache.get(id);
  const px = mainPx(id);
  let water = 0, cliff = 0, walk = 0, dark = 0;
  for (const [r, g, b] of px) {
    if (b > r + 50 && b > 140) water++;
    else if (g > r + 20 && g > b + 20) walk++; // 草
    else if (r > 200 && g > 150 && b < 150 && r >= g) walk++; // 土・砂
    else if (r < 110 && g < 80) dark++; // 鉱山の暗い床
    else if (r > g + 25 && g >= b && r >= 110 && r < 215) cliff++; // 崖の茶色（波模様・赤茶の無地）
  }
  const n = px.length;
  // 崖と言い切れるのは「ほぼ茶色だけ」のタイル。台地の縁（草+崖の斜め）は歩ける側として扱う
  const cls = n < 20 ? "none" : water / n > 0.4 ? "water" : cliff / n > CLIFF_FRAC ? "cliff" : "walk";
  classCache.set(id, cls);
  return cls;
}

// paths 層のタイルが「どのくらい不透明なら地面として歩けるか」。縁取りの細い帯(~15%)は除き、坂道の斜めタイル(~50%)は含める
const PATH_OPAQUE = Number(process.argv.includes("--path-opaque") ? process.argv[process.argv.indexOf("--path-opaque") + 1] : 0.3);
const CLIFF_FRAC = Number(process.argv.includes("--cliff-frac") ? process.argv[process.argv.indexOf("--cliff-frac") + 1] : 0.7);
// 柵・家具などの装飾タイル(decoration_02/03)は既定では通れるままにする。塞ぐと台地や畑・牧場が分断され、
// 本島の連結領域が 629→1186 マスに半減するため（元のゲームでも見た目だけで、歩行制限は無い）
const DECO_SOLID = process.argv.includes("--deco-solid");
const FOREST_SOLID = !process.argv.includes("--no-forest-solid");
const collision = Array.from({ length: H }, () => Array(W).fill(1));
const at = (name, x, y) => rawIds[name].ids[y * W + x];
const rawAt = (name, x, y) => rawIds[name].tiles[y * W + x];
const opaqueFrac = (id) => mainPx(id).length / (T * T);
// はしご(decoration_01)は崖の上でも歩ける。実測: 上端 746 / 中間 810 / 下端 874
const LADDER = new Set([746, 810, 874]);
for (let y = 0; y < H; y++)
  for (let x = 0; x < W; x++) {
    // 崖・水は land 層のタイルで判定する。land が無いマスは海。
    const l = at("land", x, y);
    let walk = l >= 0 && groundClass(l) === "walk";
    // paths 層の「ほぼ不透明」なタイル(土の道・橋・桟橋)は、下が水や崖でも歩ける。縁取りの薄いタイルは対象外。
    const p = at("paths", x, y);
    if (p >= 0 && opaqueFrac(p) >= PATH_OPAQUE) walk = true;
    const d1 = rawAt("decoration_01", x, y);
    if (d1 && LADDER.has(d1.index)) walk = true;
    // 建物・壁・森・固い装飾があれば通れない
    if (at("building", x, y) >= 0 || at("walls", x, y) >= 0) walk = false;
    if (DECO_SOLID && (at("decoration_02", x, y) >= 0 || at("decoration_03", x, y) >= 0)) walk = false;
    const f = rawIds.forest;
    // 森タイル(32px)は幹のある下半分(16px行)だけ塞ぐ。上半分は樹冠で、下を通れる
    if (FOREST_SOLID && y % 2 === 1 && f.ids[Math.floor(y / 2) * f.w + Math.floor(x / 2)] >= 0) walk = false;
    collision[y][x] = walk ? 0 : 1;
  }

// ---------------------------------------------------------------- 4. スポーン: 中央付近で、周囲が広く歩ける場所
// 歩ける場所を4近傍でつないだ「連結領域」のうち最大のもの（本島）の中でスポーンを選ぶ。孤島や飛び地に出ないため。
function largestComponent() {
  const seen = Array.from({ length: H }, () => Array(W).fill(false));
  let best = [];
  for (let sy = 0; sy < H; sy++)
    for (let sx = 0; sx < W; sx++) {
      if (collision[sy][sx] === 1 || seen[sy][sx]) continue;
      const comp = [], stack = [[sx, sy]];
      seen[sy][sx] = true;
      while (stack.length) {
        const [x, y] = stack.pop();
        comp.push([x, y]);
        for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          const nx = x + dx, ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= W || ny >= H || seen[ny][nx] || collision[ny][nx] === 1) continue;
          seen[ny][nx] = true;
          stack.push([nx, ny]);
        }
      }
      if (comp.length > best.length) best = comp;
    }
  return best;
}
const mainIsland = largestComponent();
function findSpawn() {
  const cx = 43, cy = 26; // マップ中央に近いところ
  const inIsland = new Set(mainIsland.map(([x, y]) => `${x},${y}`));
  let best = null;
  for (const [x, y] of mainIsland) {
    let ok = true;
    for (let j = -1; j <= 1 && ok; j++) for (let i = -1; i <= 1; i++) if (!inIsland.has(`${x + i},${y + j}`)) { ok = false; break; }
    if (!ok) continue;
    const d = Math.hypot(x - cx, y - cy);
    if (!best || d < best.d) best = { x, y, d };
  }
  return best ? { x: best.x, y: best.y } : { x: mainIsland[0][0], y: mainIsland[0][1] };
}
const spawn = findSpawn();
console.log(`main walkable island: ${mainIsland.length} cells`);

// ---------------------------------------------------------------- 5. 書き出し
const empty = Array.from({ length: H }, () => Array(W).fill(-1));
const map = {
  name: "sunnyside_world_example",
  tileset: "sunnyside_16",
  tileSize: T,
  width: W,
  height: H,
  spawn,
  tilesets: {
    main: { image: "tilesets/sunnyside_16_ext.png", tileSize: 16, columns: 64 },
    forest: { image: forestImage, tileSize: 32, columns: 10 },
  },
  tileLayers,
  sprites: spriteDefs,
  objects,
  layers: { ground: empty, deco: empty, overhead: empty, collision },
  props: [],
  mobs: [],
};
// マップで使っていないモブ（ゴブリン全動作・スケルトン・人間・動物）も、エディタから置けるようカタログとして登録する
console.log(`mob catalog: +${addMobCatalog(map, GM)} sprites`);
writeFileSync(OUT_MAP, JSON.stringify(map));
const walkCells = collision.flat().filter((v) => v === 0).length;
console.log(`wrote ${OUT_MAP}: ${W}x${H}, spawn (${spawn.x},${spawn.y}), walkable ${walkCells}/${W * H} cells`);

function round(v, d = 2) {
  const k = 10 ** d;
  return Math.round(v * k) / k;
}
