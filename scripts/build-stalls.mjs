/**
 * 出店（屋台）を空いている島に組み立てて、map.json に書き込む。
 *   node scripts/build-stalls.mjs [--only=okonomiyaki,cafe] [--replace] [--dry] [map.json]
 *
 * 各出店は scripts/stalls/<id>.mjs（配置）と scripts/stalls/<id>.ps1（専用ドット絵）の組。
 * 配置関数は `meta.island`（島のラベル）の草地(192x128px)の中心を基準に物を置く。道具は scripts/lib/stall-kit.mjs。
 *
 * - 島の範囲に配置物が既にあると、その出店は何もせず飛ばす（--replace で島の中を消して作り直す）。
 * - 書き込む前に reference/map-backups/ へバックアップを取る（--dry なら書かない）。
 * - マップエディタで未保存の編集があるときは、エディタ側の「保存」がこの変更を上書きするので、先に保存してから実行すること。
 */
import { copyFileSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { makeKit, T } from "./lib/stall-kit.mjs";

const args = process.argv.slice(2);
const flag = (n) => args.includes(n);
const opt = (n) => args.find((a) => a.startsWith(`${n}=`))?.slice(n.length + 1);
const MAP = args.find((a) => !a.startsWith("--")) ?? "client/src/config/map.json";
const only = opt("--only")?.split(",");

const ids = readdirSync("scripts/stalls").filter((f) => f.endsWith(".mjs")).map((f) => f.replace(/\.mjs$/, "")).sort();
const map = JSON.parse(readFileSync(MAP, "utf8"));
map.objects ??= [];
map.sprites ??= {};

/** 島ラベルから草地の範囲を求める（衝突が0のマスの外接矩形） */
function grassOf(label) {
  const g = (map.groups ?? []).find((x) => x.label === label);
  if (!g) throw new Error(`島「${label}」が map.groups にありません`);
  let minx = 1e9, maxx = -1, miny = 1e9, maxy = -1;
  for (let y = g.y; y < g.y + g.h; y++) {
    for (let x = g.x; x < g.x + g.w; x++) {
      if (map.layers.collision[y]?.[x] === 0) {
        minx = Math.min(minx, x); maxx = Math.max(maxx, x); miny = Math.min(miny, y); maxy = Math.max(maxy, y);
      }
    }
  }
  return { g, grass: { x0: minx * T, y0: miny * T, w: (maxx - minx + 1) * T, h: (maxy - miny + 1) * T } };
}

let built = 0;
for (const id of ids) {
  if (only && !only.includes(id)) continue;
  const mod = await import(pathToFileURL(`${process.cwd()}/scripts/stalls/${id}.mjs`).href);
  const { meta } = mod;
  const { g, grass } = grassOf(meta.island);
  if (grass.w < 176 || grass.h < 112) throw new Error(`${id}: 草地が小さすぎます(${grass.w}x${grass.h})`);
  const inIsland = (o) => o.x >= g.x * T - 40 && o.x < (g.x + g.w) * T + 40 && o.y >= g.y * T - 60 && o.y < (g.y + g.h) * T + 40;
  const existing = map.objects.filter(inIsland);
  if (existing.length && !flag("--replace")) {
    console.log(`- ${meta.label}（${meta.island}）: 島に配置物が ${existing.length} 個あるので飛ばします（作り直すなら --replace）`);
    continue;
  }
  map.objects = map.objects.filter((o) => !inIsland(o));
  const before = map.objects.length;
  mod.default(makeKit(map, grass));
  console.log(`- ${meta.label}（${meta.island}）: ${map.objects.length - before} 個を配置（草地 ${grass.w}x${grass.h}）`);
  built++;
}

if (!built) {
  console.log("何も組み立てませんでした。");
  process.exit(0);
}
if (flag("--dry")) {
  console.log("--dry: 書き込みません");
  process.exit(0);
}
mkdirSync("reference/map-backups", { recursive: true });
const backup = `reference/map-backups/map.before-stalls-${Date.now()}.json`;
copyFileSync(MAP, backup);
writeFileSync(MAP, JSON.stringify(map));
console.log(`バックアップ: ${backup}\n書き込みました: ${MAP}（配置物 全部で ${map.objects.length} 個）`);
