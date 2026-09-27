/**
 * 学校テーマのマップ(60x42)を生成して client/src/config/map.json に書き出す。
 *   node scripts/gen-school-map.mjs [--out client/src/config/map.json]
 *
 * 地形(芝・園路・池・柵)は村マップと同じ tilekit.mjs のオートタイルで塗る。
 * 校舎そのものは、公式マップ(sunnyside_world_example)の実在する建物を2棟
 * 矩形ごと「移植」する（壁・屋根タイルをこのプロジェクトの素材だけで新規に描き起こすのは
 * 非現実的なため。実測した座標は reference/crop_candidate*.png で目視確認済み）。
 * 乱数は固定シードなので、実行するたび同じマップになる。
 */
import { readFileSync, writeFileSync } from "node:fs";
import { Grid, tid, paintRegion, paintPond, rectMask } from "./lib/tilekit.mjs";

const W = 60, H = 42;
const out = process.argv.includes("--out") ? process.argv[process.argv.indexOf("--out") + 1] : "client/src/config/map.json";
const SRC_MAP = "reference/map-backups/map.20260927-133146.pre-school-map.json";

const src = JSON.parse(readFileSync(SRC_MAP, "utf8"));

// ---- 固定シード乱数
let seed = 20260927;
const rnd = () => {
  seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const pick = (a) => a[Math.floor(rnd() * a.length)];

// ================================================================== 地形(legacy Grid)
const ground = new Grid(W, H, 0);
const deco = new Grid(W, H);
const overhead = new Grid(W, H);
const collision = new Grid(W, H, 0);
const props = [];
const mobs = [];

const GRASS = [tid(1, 3), tid(2, 3), tid(3, 3), tid(1, 4), tid(2, 4), tid(3, 4)];
const GRASS_DETAIL = [129, 130, 131, 132, 133, 134];
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) ground.set(x, y, rnd() < 0.09 ? pick(GRASS_DETAIL) : pick(GRASS));
const GRASS_FILL = tid(1, 3);

// ---- 区画の定義（タイル座標）
// 校舎A/Bの移植元矩形は建物の壁・屋根だけに絞った(実測: reference/crop_candidate*.png)。
// 余白を持たせすぎると隣接する川・崖・切り株など元マップの地物ごと持ってきてしまうため。
const SRC_A = { x: 39, y: 24, w: 7, h: 7 }; // 青い大屋根の建物
const SRC_B = { x: 32, y: 19, w: 5, h: 6 }; // 赤い小屋
const BLDG_A = { x: 21, y: 5, w: SRC_A.w, h: SRC_A.h }; // 校舎（本館）
const BLDG_B = { x: 11, y: 9, w: SRC_B.w, h: SRC_B.h }; // 別館・図書室
const COURT = [8, 16, 27, 9]; // 中庭
const WALK = [20, 16, 4, 24]; // 正門への通学路
const GATE_Y = 39;
const RIVER = [56, 0, 4, H];
const TRACK_OUT = [35, 12, 18, 17]; // RIVER(x>=56)と重ならないように右端を余裕を持って離す
const TRACK_IN = [38, 15, 12, 11];
const WALK_A = [24, 12, 2, 4]; // 校舎Aの玄関から中庭へ
const TENNIS = [[40, 33, 6, 5], [48, 33, 6, 5]];

// ---- 園路（中庭 + 通学路 + 校舎Aへの短い通路）
const pathMask = rectMask(W, H, [COURT, WALK, WALK_A]);
paintRegion(ground, deco, pathMask, "Path 01", { under: GRASS_FILL });

// ---- 川（東端）
const waterMask = rectMask(W, H, [RIVER]);
paintPond(ground, deco, waterMask);
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (waterMask[y][x]) collision.set(x, y, 1);

// ---- トラック（角丸長方形のリング＝陸上トラック風）を Path 02 で塗る
const outMask = rectMask(W, H, [TRACK_OUT]);
const inMask = rectMask(W, H, [TRACK_IN]);
const trackMask = outMask.map((row, y) => row.map((v, x) => v && !inMask[y][x]));
paintRegion(ground, deco, trackMask, "Path 02", { under: GRASS_FILL });
const TRACK = { cx: TRACK_OUT[0] + TRACK_OUT[2] / 2, cy: TRACK_OUT[1] + TRACK_OUT[3] / 2, rx: TRACK_OUT[2] / 2, ry: TRACK_OUT[3] / 2 };

// ---- 花壇（中庭中央の円形の花壇）
const GARDEN = { cx: 22, cy: 20, r: 3 };
const FLOWERS = [tid(31, 1), tid(31, 2), tid(31, 3), tid(34, 1), tid(34, 2), tid(34, 3)];
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  if (Math.hypot(x - GARDEN.cx, y - GARDEN.cy) <= GARDEN.r) deco.set(x, y, pick(FLOWERS));
}

// ---- 柵ユーティリティ（gen-map.mjs と同じ実測タイル）
const F = {
  hL: tid(38, 2), hM: tid(39, 2), hR: tid(42, 2),
  vT: tid(40, 1), vM: tid(40, 3), vB: tid(40, 4),
  tl: tid(42, 1), tr: tid(41, 1), bl: tid(39, 1), br: tid(38, 1),
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
for (const [tx, ty, tw, th] of TENNIS) fenceRect(tx, ty, tw, th, [[tx + Math.floor(tw / 2), ty + th - 1]]);

// ---- 石垣+正門（村マップと同じ意匠。中庭からの通学路の先、南端）
const WALL_Y = GATE_Y, WALL_X0 = 18, WALL_X1 = 26;
for (let x = WALL_X0; x <= WALL_X1; x++) {
  const id = x === WALL_X0 ? tid(44, 1) : x === WALL_X1 ? tid(47, 1) : tid(45 + (x % 2), 1);
  deco.set(x, WALL_Y, id);
  collision.set(x, WALL_Y, 1);
}
collision.set(21, WALL_Y, 0); collision.set(22, WALL_Y, 0);
deco.set(21, WALL_Y, tid(45, 2)); deco.set(22, WALL_Y, tid(46, 2));

// ---- 点在する草花・低木・岩（校舎裏・外周）
const DECOR = [
  { ids: [tid(31, 1), tid(31, 2), tid(31, 3), tid(34, 1), tid(34, 2), tid(34, 3), tid(35, 3)], w: 5, solid: false },
  { ids: [tid(27, 1), tid(28, 1), tid(29, 1), tid(30, 1), tid(27, 2), tid(28, 2), tid(27, 3), tid(28, 3)], w: 3, solid: false },
  { ids: [tid(31, 4), tid(32, 4), tid(33, 4), tid(34, 4)], w: 2, solid: true },
];
const reserved = (x, y) => {
  const inR = ({ x: rx, y: ry, w: rw, h: rh }, m = 0) => x >= rx - m && x < rx + rw + m && y >= ry - m && y < ry + rh + m;
  const inRA = ([rx, ry, rw, rh], m = 0) => x >= rx - m && x < rx + rw + m && y >= ry - m && y < ry + rh + m;
  return (
    inR(BLDG_A, 1) || inR(BLDG_B, 1) || inRA(COURT, 1) || inRA(WALK, 1) || inRA(WALK_A, 1) || inRA(RIVER, 2) ||
    TENNIS.some((t) => inRA(t, 1)) || (y >= WALL_Y - 1 && y <= WALL_Y + 1 && x >= WALL_X0 - 1 && x <= WALL_X1 + 1) ||
    Math.hypot(x - TRACK.cx, y - TRACK.cy) <= TRACK.rx + 1
  );
};
for (let y = 1; y < H - 1; y++)
  for (let x = 1; x < W - 1; x++) {
    if (reserved(x, y) || deco.get(x, y) !== -1 || collision.get(x, y) === 1) continue;
    if (rnd() > 0.06) continue;
    const total = DECOR.reduce((s, d) => s + d.w, 0);
    let r = rnd() * total;
    const kind = DECOR.find((d) => (r -= d.w) < 0) ?? DECOR[0];
    deco.set(x, y, pick(kind.ids));
    if (kind.solid) collision.set(x, y, 1);
  }

// ---- 木（校庭の外周・川沿いの森）
const trees = [];
const near = (x, y, d) => trees.some((t) => Math.hypot(t.x - x, t.y - y) < d);
const treeOk = (x, y) => !reserved(x - 1, y) && !reserved(x + 1, y) && !reserved(x, y) && !reserved(x, y - 1) && !reserved(x, y - 2);
for (let attempt = 0; attempt < 5000 && trees.length < 70; attempt++) {
  const x = 1 + Math.floor(rnd() * (W - 2));
  const y = 1 + Math.floor(rnd() * (H - 2));
  const edge = Math.min(x, W - x, y, H - y);
  const nearRiver = x > RIVER[0] - 4;
  if (rnd() > (nearRiver ? 0.85 : edge < 6 ? 0.55 : 0.12)) continue;
  if (!treeOk(x, y) || near(x, y, nearRiver ? 1.6 : edge < 6 ? 2.2 : 4.5)) continue;
  trees.push({ x, y });
}
for (const t of trees) props.push({ sprite: rnd() < 0.72 ? "tree_01" : "tree_02", x: t.x, y: t.y, collide: true });

// キノコ（点景）
for (let i = 0; i < 6; i++) {
  const x = 2 + Math.floor(rnd() * (W - 4)), y = 2 + Math.floor(rnd() * (H - 4));
  if (!reserved(x, y) && collision.get(x, y) === 0 && !near(x, y, 1.5)) props.push({ sprite: pick(["mushroom_red_01", "mushroom_blue_01", "mushroom_blue_02"]), x: x + 0.5, y: y + 0.9, collide: false });
}

// ---- NPC（同期しない背景キャラ）
mobs.push(
  { sprite: "human", action: "waiting", x: BLDG_A.x + 4.5, y: BLDG_A.y + BLDG_A.h + 1, flipX: false, name: "先生", hair: "bowlhair" },
  { sprite: "human", action: "idle", x: BLDG_A.x + 2, y: BLDG_A.y + BLDG_A.h + 1.5, flipX: true, name: "生徒", hair: "spikeyhair" },
  { sprite: "human", action: "carry", x: BLDG_B.x + 3, y: BLDG_B.y + BLDG_B.h + 0.5, flipX: false, name: "図書委員", hair: "longhair" },
  { sprite: "human", action: "idle", x: GARDEN.cx + 2, y: GARDEN.cy + 2, flipX: false, name: "生徒", hair: "curlyhair" },
  { sprite: "human", action: "idle", x: TRACK.cx, y: TRACK.cy - TRACK.ry + 1, flipX: false, name: "生徒", hair: "mophair" },
  { sprite: "skeleton", action: "idle", x: BLDG_B.x + BLDG_B.w + 1, y: BLDG_B.y + BLDG_B.h - 1, flipX: true, name: "骨格模型（理科室）" },
);

const spawn = { x: GARDEN.cx, y: GARDEN.cy + 5 };

// ================================================================== 校舎の移植(tileLayers)
const FLOOR_IDX = [0, 1, 2, 3, 4, 5];
const YSORT_IDX = [7, 8, 9, 10];

function blankLayers() {
  const mk = (mode, tileset, i) => ({
    name: `${mode}_${i}`,
    tileset,
    mode,
    data: Array.from({ length: H }, () => Array(W).fill(-1)),
  });
  return {
    floor: FLOOR_IDX.map((i) => mk("floor", "main", i)),
    ysort: [mk("ysort", "main", 0)], // 1枚に統合。行ごとにY-sortされるので複数枚に分ける必要はない
  };
}
const out_layers = blankLayers();

/** 元マップの矩形(タイル座標)を新マップの(dx,dy)へコピーする */
function transplantBuilding(rect, dest) {
  FLOOR_IDX.forEach((srcI, i) => {
    const srcLayer = src.tileLayers[srcI];
    const dstLayer = out_layers.floor[i];
    for (let ry = 0; ry < rect.h; ry++) {
      const srcRow = srcLayer.data[rect.y + ry];
      if (!srcRow) continue;
      for (let rx = 0; rx < rect.w; rx++) {
        const id = srcRow[rect.x + rx];
        if (id >= 0) dstLayer.data[dest.y + ry][dest.x + rx] = id;
      }
    }
  });
  YSORT_IDX.forEach((srcI) => {
    const srcLayer = src.tileLayers[srcI];
    const dstLayer = out_layers.ysort[0];
    for (let ry = 0; ry < rect.h; ry++) {
      const srcRow = srcLayer.data[rect.y + ry];
      if (!srcRow) continue;
      const dstRow = dstLayer.data[dest.y + ry];
      for (let rx = 0; rx < rect.w; rx++) {
        const id = srcRow[rect.x + rx];
        if (id >= 0) dstRow[dest.x + rx] = id;
      }
    }
  });
}

const objects = [];
// 校舎A（移植元: 青い大屋根の建物）
transplantBuilding(SRC_A, BLDG_A);
for (let ry = 0; ry < BLDG_A.h - 2; ry++) for (let rx = 0; rx < BLDG_A.w; rx++) collision.set(BLDG_A.x + rx, BLDG_A.y + ry, 1);

// 校舎B（移植元: 赤い小屋。煙突の煙(chimneysmoke_04)も一緒に移す）
transplantBuilding(SRC_B, BLDG_B);
for (let ry = 0; ry < BLDG_B.h - 2; ry++) for (let rx = 0; rx < BLDG_B.w; rx++) collision.set(BLDG_B.x + rx, BLDG_B.y + ry, 1);
{
  const srcOrigin = { x: SRC_B.x * 16, y: SRC_B.y * 16 };
  const chimney = src.objects.find((o) => o.sprite === "chimneysmoke_04" && Math.abs(o.x - 531) < 1 && Math.abs(o.y - 308) < 1);
  if (chimney) {
    const dx = chimney.x - srcOrigin.x, dy = chimney.y - srcOrigin.y;
    objects.push({ ...chimney, x: BLDG_B.x * 16 + dx, y: BLDG_B.y * 16 + dy, by: BLDG_B.y * 16 + dy + (chimney.by - chimney.y) });
  }
}

// ================================================================== 書き出し
const map = {
  name: "sunnyside_school",
  tileset: "sunnyside_16",
  tileSize: 16,
  width: W,
  height: H,
  spawn,
  layers: {
    ground: Array.from({ length: H }, () => Array(W).fill(-1)),
    deco: Array.from({ length: H }, () => Array(W).fill(-1)),
    overhead: Array.from({ length: H }, () => Array(W).fill(-1)),
    collision: collision.a,
  },
  props,
  mobs,
  tilesets: src.tilesets,
  sprites: src.sprites,
  objects,
  // sunnyside_16(base)と main(sunnyside_16_ext)はタイルID体系が共通(拡張は末尾に追加のみ)なので、
  // 自前地形(芝・園路・柵・花壇)の tileLayer も "main" として登録する。
  tileLayers: [
    { name: "terrain", tileset: "main", mode: "floor", data: ground.a },
    { name: "terrain_deco", tileset: "main", mode: "floor", data: deco.a },
    ...out_layers.floor,
    ...out_layers.ysort,
  ],
};

writeFileSync(out, JSON.stringify(map));
console.log(`wrote ${out}: props ${props.length} (trees ${trees.length}), mobs ${mobs.length}, objects ${objects.length}`);
