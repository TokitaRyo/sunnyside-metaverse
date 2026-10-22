/**
 * 出店（屋台）を、ひとつの大きな島の区画に組み立てて、map.json に書き込む。
 *   node scripts/build-stalls.mjs [--only=okonomiyaki,cafe] [--replace] [--dry] [--island="文化祭島"] [map.json]
 *
 * 各出店は scripts/stalls/<id>.mjs（配置）と scripts/stalls/<id>.ps1（専用ドット絵）の組。
 * 島の草地を 7列 x 5行 の区画(各 192x128px)に分け、下の SLOTS で出店ごとの区画を決める。
 * 配置関数は区画の中心を基準に物を置く。道具は scripts/lib/stall-kit.mjs。
 *
 * - 区画に配置物が既にあると、その出店は何もせず飛ばす（--replace で区画の中を消して作り直す）。
 * - 各出店の「スタンプ」(キーアイテム)を、区画の右どなりの通路に1個ずつ置く（id は stall-<出店id> で固定）。
 * - 出店モジュールが `spawn = { dx, foot }` を export していれば、そこをスポーン地点にする（広場）。
 * - 書き込む前に reference/map-backups/ へバックアップを取る（--dry なら書かない）。
 * - マップエディタで未保存の編集があるときは、エディタ側の「保存」がこの変更を上書きするので、先に保存してから実行すること。
 *
 * マップを白紙から作り直す手順は scripts/rebuild-festival.mjs を参照。
 */
import { copyFileSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { makeKit, T } from "./lib/stall-kit.mjs";

const args = process.argv.slice(2);
const flag = (n) => args.includes(n);
const opt = (n) => args.find((a) => a.startsWith(`${n}=`))?.slice(n.length + 1);
const MAP = args.find((a) => !a.startsWith("--")) ?? "client/src/config/map.json";
const ISLAND = opt("--island") ?? "文化祭島";
const only = opt("--only")?.split(",");

/** 区画の寸法(px)。草の面は 左右・上に MARGIN、区画どうしは通路(GAP)をあける。1区画 = 192x128、看板が上にはみ出す分も通路にある */
const PLOT_W = 192, PLOT_H = 128, GAP_X = 32, PITCH_Y = 176, MARGIN_X = 32, MARGIN_TOP = 32;

/** 出店ごとの区画 [列, 行]（列 0..6 は左から、行 0..4 は上から。7列×5行 = 35区画）。広場は列3・行2（島のまんなか） */
const SLOTS = {
  // 北の2列: 部活・同好会の展示
  obakeyashiki: [0, 0], casino: [1, 0], suisougaku: [2, 0], dtm: [3, 0], programming: [4, 0], science: [5, 0], library: [6, 0],
  handmade: [0, 1], sadokado: [1, 1], photoart: [2, 1], suuri: [3, 1], nazotoki: [4, 1], amateurradio: [5, 1], doujinshi: [6, 1],
  // まんなかの列: ゲーム・ものづくり（広場をはさむ）
  volleyball: [0, 2], shateki: [1, 2], entre: [2, 2], plaza: [3, 2], circuit: [4, 2], printer3d: [5, 2], cafe: [6, 2],
  // 南の2列: 食べ物・飲み物
  takoyaki: [0, 3], okonomiyaki: [1, 3], aburasoba: [2, 3], taiyaki: [3, 3], obanyaki: [4, 3], wataame: [5, 3], potato: [6, 3],
  chocobanana: [0, 4], kushiyaki: [1, 4], hotdog: [2, 4], frankfurt: [3, 4], croffle: [4, 4], tamasen: [5, 4], kirakira: [6, 4],
};

const ids = readdirSync("scripts/stalls").filter((f) => f.endsWith(".mjs")).map((f) => f.replace(/\.mjs$/, "")).sort();
const map = JSON.parse(readFileSync(MAP, "utf8"));
map.objects ??= [];
map.sprites ??= {};
map.keyItems ??= [];
map.areas ??= [];

/** 島ラベルから草地の範囲を求める（衝突が0のマスの外接矩形） */
function grassOf(label) {
  const g = (map.groups ?? []).find((x) => x.label === label);
  if (!g) throw new Error(`島「${label}」が map.groups にありません（先に scripts/rebuild-festival.mjs で島を作る）`);
  let minx = 1e9, maxx = -1, miny = 1e9, maxy = -1;
  for (let y = g.y; y < g.y + g.h; y++) {
    for (let x = g.x; x < g.x + g.w; x++) {
      if (map.layers.collision[y]?.[x] === 0) {
        minx = Math.min(minx, x); maxx = Math.max(maxx, x); miny = Math.min(miny, y); maxy = Math.max(maxy, y);
      }
    }
  }
  return { x0: minx * T, y0: miny * T, w: (maxx - minx + 1) * T, h: (maxy - miny + 1) * T };
}
const island = grassOf(ISLAND);
console.log(`島「${ISLAND}」の草地 ${island.w}x${island.h}px（原点 ${island.x0},${island.y0}）`);

let built = 0;
for (const id of ids) {
  if (only && !only.includes(id)) continue;
  const slot = SLOTS[id];
  const mod = await import(pathToFileURL(`${process.cwd()}/scripts/stalls/${id}.mjs`).href);
  const { meta } = mod;
  if (!slot && !mod.north) {
    console.log(`- ${id}: SLOTS に区画が決まっていないので飛ばします`);
    continue;
  }
  // `north` を export する物（横断幕）は、島の幅の中央・草地の上端の `above` px 上に、下端が来るように置く（区画は使わない）
  const plot = mod.north
    ? { x0: island.x0 + Math.round((island.w - PLOT_W) / 2), y0: island.y0 - mod.north.above - PLOT_H, w: PLOT_W, h: PLOT_H }
    : { x0: island.x0 + MARGIN_X + slot[0] * (PLOT_W + GAP_X), y0: island.y0 + MARGIN_TOP + slot[1] * PITCH_Y, w: PLOT_W, h: PLOT_H };
  if (!mod.north && (plot.x0 + plot.w > island.x0 + island.w || plot.y0 + plot.h > island.y0 + island.h)) throw new Error(`${id}: 区画が島からはみ出します`);
  // 区画とその上の看板・左右の通路ぶんを含む範囲
  const padX = mod.north ? 300 : 0; // 横断幕は区画より横に広い
  const inPlot = (o) => o.x >= plot.x0 - GAP_X / 2 - padX && o.x < plot.x0 + plot.w + GAP_X / 2 + padX && o.y >= plot.y0 - 40 && o.y < plot.y0 + plot.h + 24 + (mod.north ? 40 : 0);
  const existing = map.objects.filter(inPlot);
  if (existing.length && !flag("--replace")) {
    console.log(`- ${meta.label}: 区画に配置物が ${existing.length} 個あるので飛ばします（作り直すなら --replace）`);
    continue;
  }
  map.objects = map.objects.filter((o) => !inPlot(o));
  const before = map.objects.length;
  mod.default(makeKit(map, plot));
  // 区域（入ると名前が出る・ミニマップに描く）。通路ぶんは含めず、区画そのもの。広場は「広場」
  if (!mod.north) {
    map.areas = map.areas.filter((a) => a.id !== id);
    map.areas.push({ id, name: meta.label, x: plot.x0, y: plot.y0, w: plot.w, h: plot.h });
  }
  if (mod.spawn) {
    map.spawn = { x: Math.floor((plot.x0 + plot.w / 2 + mod.spawn.dx) / T), y: Math.floor((plot.y0 + mod.spawn.foot) / T) };
  } else if (!mod.north) {
    // スタンプ（キーアイテム）: 区画の右どなりの通路に置く（マスの中央）
    const kid = `stall-${id}`;
    map.keyItems = map.keyItems.filter((k) => k.id !== kid);
    const kx = Math.floor((plot.x0 + plot.w + GAP_X / 2) / T) * T + T / 2;
    const ky = Math.floor((plot.y0 + 104) / T) * T + T / 2;
    // icon: その出店にちなんだスタンプの絵柄（client/src/game/stampIcons.ts の id。出店の id と同じ）
    map.keyItems.push({ id: kid, x: kx, y: ky, name: meta.label, icon: id });
  }
  console.log(`- ${meta.label}（${slot ? `列${slot[0]} 行${slot[1]}` : "島の北"}）: ${map.objects.length - before} 個を配置`);
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
console.log(`バックアップ: ${backup}\n書き込みました: ${MAP}（配置物 全部で ${map.objects.length} 個、スタンプ ${map.keyItems.length} 個、スポーン ${map.spawn.x},${map.spawn.y}）`);
