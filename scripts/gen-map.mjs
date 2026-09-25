/**
 * 村マップ(60x40)を生成して client/src/config/map.json に書き出す。
 *   node scripts/gen-map.mjs [--out client/src/config/map.json]
 * 部品のタイルIDは reference/crop_*.png（tile_picker を拡大したもの）から読み取った実測値。
 * 乱数は固定シードなので、実行するたび同じマップになる。
 */
import { writeFileSync } from "node:fs";
import { Grid, makeMap, tid, paintRegion, paintPond, rectMask } from "./lib/tilekit.mjs";

const W = 60, H = 40;
const out = process.argv.includes("--out") ? process.argv[process.argv.indexOf("--out") + 1] : "client/src/config/map.json";

// ---- 固定シード乱数
let seed = 20260919;
const rnd = () => {
  seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const pick = (a) => a[Math.floor(rnd() * a.length)];

const ground = new Grid(W, H, 0);
const deco = new Grid(W, H);
const overhead = new Grid(W, H);
const collision = new Grid(W, H, 0);
const props = [];
const mobs = [];

// ---- 1. 草: ほとんど無地、たまに草むら模様（自然な見た目にする）
// 縁取り付きのタイル(196, 197, 198 など)は縞模様になるので使わない。r2 は草むら模様、r3/r4 は無地寄り
const GRASS = [tid(1, 3), tid(2, 3), tid(3, 3), tid(1, 4), tid(2, 4), tid(3, 4)];
const GRASS_DETAIL = [129, 130, 131, 132, 133, 134];
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) ground.set(x, y, rnd() < 0.09 ? pick(GRASS_DETAIL) : pick(GRASS));
const GRASS_FILL = tid(1, 3);

// ---- 領域の定義（タイル座標）
const ROAD_V = [28, 0, 3, H];
const ROAD_H = [0, 17, W, 3];
const PLAZA = [25, 14, 9, 9];
// 角を段階的に削って自然な丸みのある池にする
const POND = [[45, 25, 8, 1], [43, 26, 12, 5], [44, 31, 10, 1], [46, 32, 6, 2]];
const FARM = [2, 2, 17, 12]; // 柵の外周
const PASTURE = [13, 24, 13, 10];
const GRAVES = [3, 26, 8, 7];
const WALL_Y = 6, WALL_X0 = 38, WALL_X1 = 57;

// ---- 2. 道（幅3。マップ端まで伸ばして端の丸めを出さない）
const pathMask = rectMask(W, H, [ROAD_V, ROAD_H, PLAZA]);
paintRegion(ground, deco, pathMask, "Path 01", { under: GRASS_FILL, clampEdges: true });

// ---- 3. 池
const waterMask = rectMask(W, H, POND);
paintPond(ground, deco, waterMask);
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (waterMask[y][x]) collision.set(x, y, 1);

// ---- 4. 柵ユーティリティ（実測タイル: 端/中間/角/T字）
const F = {
  hL: tid(38, 2), hM: tid(39, 2), hR: tid(42, 2), // 横: 左端・中間・右端
  vT: tid(40, 1), vM: tid(40, 3), vB: tid(40, 4), // 縦: 上端・中間・下端
  tl: tid(42, 1), tr: tid(41, 1), bl: tid(39, 1), br: tid(38, 1), // 角
};
function fenceRect(x, y, w, h, gaps = []) {
  const put = (fx, fy, id) => {
    if (gaps.some(([gx, gy]) => gx === fx && gy === fy)) return;
    deco.set(fx, fy, id);
    collision.set(fx, fy, 1);
  };
  for (let i = 1; i < w - 1; i++) { put(x + i, y, F.hM); put(x + i, y + h - 1, F.hM); }
  for (let j = 1; j < h - 1; j++) { put(x, y + j, F.vM); put(x + w - 1, y + j, F.vM); }
  put(x, y, F.tl); put(x + w - 1, y, F.tr); put(x, y + h - 1, F.bl); put(x + w - 1, y + h - 1, F.br);
}

// ---- 5. 農場（左上）: 柵で囲み、耕した土に作物
fenceRect(...FARM, [[10, 13], [11, 13]]);
const plots = [[4, 4, 5, 3, "carrot_05"], [11, 4, 5, 3, "cabbage_04"], [4, 8, 5, 3, "sunflower_05"], [11, 8, 5, 3, "pumpkin_05"]];
for (const [px, py, pw, ph] of plots) paintRegion(ground, deco, rectMask(W, H, [[px, py, pw, ph]]), "Path 02", { under: GRASS_FILL });
for (const [px, py, pw, ph, crop] of plots) {
  for (let j = 0; j < ph; j++) for (let i = 0; i < pw; i++) {
    if ((i === 0 || i === pw - 1) && (j === 0 || j === ph - 1)) continue; // 丸めた角は空ける
    props.push({ sprite: crop, x: px + i + 0.5, y: py + j + 0.85, collide: false });
  }
}

// ---- 6. 牧場（下中央左）: 動物たち
fenceRect(...PASTURE, [[19, 24], [20, 24]]);
const animals = [["cow", 16, 28], ["cow", 22, 30], ["sheep_01", 18, 26], ["sheep_01", 23, 27], ["pig_01", 15, 31], ["chicken_01", 20, 32], ["chicken_01", 24, 32], ["chicken_01", 17, 29]];
for (const [s, x, y] of animals) props.push({ sprite: s, x: x + 0.5, y: y + 0.9, collide: false });

// ---- 7. 墓地（左下）: 墓石と塚。スケルトンが立つ
fenceRect(...GRAVES, [[6, 26], [7, 26]]);
// 墓石(上)+塚(下)で縦2タイルの部品。2列に並べる（形違いを交互に）
for (const [row, shift] of [[GRAVES[1] + 2, 0], [GRAVES[1] + 4, 2]]) {
  for (let i = 0; i < 5; i++) {
    const gx = GRAVES[0] + 1 + i + (i > 4 ? 1 : 0);
    deco.stamp(gx, row, 43 + ((i + shift) % 5), 16, 1, 2, { skipEmpty: false });
    collision.set(gx, row, 1);
  }
}

// ---- 8. 広場: 像・井戸・焚き火
deco.stamp(28, 15, 43, 18, 3, 4);
for (const x of [28, 29, 30]) for (const y of [17, 18]) collision.set(x, y, 1);
deco.stamp(26, 21, 37, 19, 2, 2); // 井戸
for (const x of [26, 27]) for (const y of [21, 22]) collision.set(x, y, 1);
deco.stamp(31, 21, 37, 21, 2, 2); // 焚き火跡
collision.set(31, 22, 1); collision.set(32, 22, 1);
props.push({ sprite: "fire_02", x: 32, y: 22.2, collide: false });

// ---- 9. 石垣（右上）: 1行の石ブロック。中央に木の門
for (let x = WALL_X0; x <= WALL_X1; x++) {
  const id = x === WALL_X0 ? tid(44, 1) : x === WALL_X1 ? tid(47, 1) : tid(45 + (x % 2), 1);
  deco.set(x, WALL_Y, id);
  collision.set(x, WALL_Y, 1);
}
collision.set(47, WALL_Y, 0); collision.set(48, WALL_Y, 0); // 門の通り抜け（見た目は木の門）
deco.set(47, WALL_Y, tid(45, 2)); deco.set(48, WALL_Y, tid(46, 2));

// （風車は素材が「羽根だけ」で本体が無く、宙に浮いて見えるので置かない）

// ---- 11. 点在する草花・低木・岩・切り株（deco 1タイル部品。空きマスにだけ置く）
const DECOR = [
  { ids: [tid(31, 1), tid(31, 2), tid(31, 3), tid(34, 1), tid(34, 2), tid(34, 3), tid(35, 3)], w: 5, solid: false }, // 花
  { ids: [tid(27, 1), tid(28, 1), tid(29, 1), tid(30, 1), tid(27, 2), tid(28, 2), tid(27, 3), tid(28, 3)], w: 3, solid: false }, // 低木
  { ids: [tid(31, 4), tid(32, 4), tid(33, 4), tid(34, 4)], w: 2, solid: true }, // 岩
  { ids: [tid(31, 5), tid(32, 5)], w: 1, solid: true }, // 切り株
];
const zone = { x0: 0, y0: 0 };
const reserved = (x, y) => {
  const inR = ([rx, ry, rw, rh], m = 0) => x >= rx - m && x < rx + rw + m && y >= ry - m && y < ry + rh + m;
  return (
    inR(ROAD_V, 1) || inR(ROAD_H, 1) || inR(PLAZA, 1) || inR(FARM, 1) || inR(PASTURE, 1) || inR(GRAVES, 1) ||
    POND.some((r) => inR(r, 2)) || (y >= WALL_Y - 1 && y <= WALL_Y + 1 && x >= WALL_X0 - 1 && x <= WALL_X1 + 1)
  );
};
for (let y = 1; y < H - 1; y++)
  for (let x = 1; x < W - 1; x++) {
    if (reserved(x, y) || deco.get(x, y) !== -1 || collision.get(x, y) === 1) continue;
    if (rnd() > 0.075) continue;
    const total = DECOR.reduce((s, d) => s + d.w, 0);
    let r = rnd() * total;
    const kind = DECOR.find((d) => (r -= d.w) < 0) ?? DECOR[0];
    deco.set(x, y, pick(kind.ids));
    if (kind.solid) collision.set(x, y, 1);
  }

// ---- 12. 木（props・揺れるアニメ付き）。道や施設を避け、間隔を空けて森っぽく
const trees = [];
const near = (x, y, d) => trees.some((t) => Math.hypot(t.x - x, t.y - y) < d);
const treeOk = (x, y) => !reserved(x - 1, y) && !reserved(x + 1, y) && !reserved(x, y) && !reserved(x, y - 1) && !reserved(x, y - 2);
for (let attempt = 0; attempt < 4000 && trees.length < 60; attempt++) {
  const x = 1 + Math.floor(rnd() * (W - 2));
  const y = 3 + Math.floor(rnd() * (H - 4));
  // 外周ほど密に: 中心から離れるほど採用
  const edge = Math.min(x, W - x, y, H - y);
  if (rnd() > (edge < 8 ? 0.9 : 0.16)) continue;
  if (!treeOk(x, y) || near(x, y, edge < 8 ? 2.4 : 5)) continue;
  trees.push({ x, y });
}
for (const t of trees) props.push({ sprite: rnd() < 0.72 ? "tree_01" : "tree_02", x: t.x, y: t.y, collide: true });

// キノコ（あちこち）
for (let i = 0; i < 9; i++) {
  const x = 2 + Math.floor(rnd() * (W - 4)), y = 3 + Math.floor(rnd() * (H - 6));
  if (!reserved(x, y) && collision.get(x, y) === 0 && !near(x, y, 1.5)) props.push({ sprite: pick(["mushroom_red_01", "mushroom_blue_01", "mushroom_blue_02"]), x: x + 0.5, y: y + 0.9, collide: false });
}

// ---- 13. NPC（同期しない背景キャラ）
mobs.push(
  { sprite: "human", action: "waiting", x: 27, y: 20, flipX: false, name: "受付", hair: "longhair" },
  { sprite: "human", action: "carry", x: 9, y: 12, flipX: true, name: "農家", hair: "mophair" },
  { sprite: "human", action: "reeling", x: 47, y: 24, flipX: false, name: "釣り人", hair: "bowlhair" },
  { sprite: "human", action: "swimming", x: 50, y: 28, flipX: false, name: "", hair: "curlyhair" },
  { sprite: "goblin", action: "idle", x: 40, y: 25, flipX: true, name: "ゴブリン" },
  { sprite: "goblin", action: "idle", x: 52, y: 12, flipX: false, name: "" },
  { sprite: "skeleton", action: "idle", x: 7, y: 25, flipX: false, name: "スケルトン" },
);

// 広場の中心付近（像の手前）
const spawn = { x: 29, y: 21 };
const map = makeMap({ name: "sunnyside_village", width: W, height: H, spawn, layers: { ground, deco, overhead, collision }, props, mobs });
writeFileSync(out, JSON.stringify(map));
console.log(`wrote ${out}: props ${props.length} (trees ${trees.length}), mobs ${mobs.length}`);
