/**
 * 「0から」編集するための空っぽのキャンバスを client/src/config/map.json に書き出す。
 *   node scripts/gen-blank-canvas.mjs [--out client/src/config/map.json] [--w 86] [--h 48]
 *
 * タイルセット(main/forest)とスプライトカタログ(map.sprites)は公式マップからそのまま流用する
 * （エディタのパレットに絵を出すための「定義」であって、配置済みの中身ではないので問題ない）。
 * tileLayers の中身・objects・collision はすべて空にする。ユーザーがエディタ(?edit=1 / 切り替えボタン)で
 * タイル・配置物・当たり判定・スポーンを1から置いていく前提。
 */
import { readFileSync, writeFileSync } from "node:fs";

const args = process.argv.slice(2);
const opt = (k, d) => (args.includes(`--${k}`) ? args[args.indexOf(`--${k}`) + 1] : d);
const out = opt("out", "client/src/config/map.json");
const W = Number(opt("w", 86));
const H = Number(opt("h", 48));
const SRC_MAP = "reference/map-backups/map.20260927-133146.pre-school-map.json";

const src = JSON.parse(readFileSync(SRC_MAP, "utf8"));

const blankGrid = (w, h, fill) => Array.from({ length: h }, () => Array(w).fill(fill));

const map = {
  name: "sunnyside_school",
  tileset: "sunnyside_16",
  tileSize: 16,
  width: W,
  height: H,
  spawn: { x: Math.floor(W / 2), y: Math.floor(H / 2) },
  layers: {
    ground: blankGrid(W, H, -1),
    deco: blankGrid(W, H, -1),
    overhead: blankGrid(W, H, -1),
    collision: blankGrid(W, H, 0),
  },
  props: [],
  mobs: [],
  tilesets: src.tilesets,
  sprites: src.sprites,
  objects: [],
  groups: [],
  tileLayers: src.tileLayers.map((l) => {
    const ts = src.tilesets[l.tileset];
    const cols = Math.ceil((W * 16) / ts.tileSize);
    const rows = Math.ceil((H * 16) / ts.tileSize);
    return { name: l.name ?? `${l.mode}_${l.tileset}`, tileset: l.tileset, mode: l.mode, data: blankGrid(cols, rows, -1) };
  }),
};

writeFileSync(out, JSON.stringify(map));
console.log(`wrote ${out}: ${W}x${H}, tileLayers ${map.tileLayers.length}枚(空), spawn (${map.spawn.x},${map.spawn.y})`);
