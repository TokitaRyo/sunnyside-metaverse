/**
 * 空いている島に「お好み焼き屋」の屋台を組み立てて、map.json に書き込む。
 *   node scripts/build-okonomiyaki-stall.mjs [--island="浮島 27"] [--replace] [--dry] [map.json]
 * 先に `powershell -File scripts/gen-okonomiyaki-stall.ps1` で専用ドット絵を作っておく。
 *
 * - 島のラベルで場所を決める（既定は「浮島 27」）。島の範囲に配置物が既にあると、何もせず止まる（--replace で島の中を消して作り直す）。
 * - 書き込む前に reference/map-backups/ へバックアップを取る。マップエディタで未保存の編集があるときは、
 *   エディタ側の「保存」がこの変更を上書きするので、先に保存するか、エディタを閉じてから実行すること。
 * - 配置は「島の草地の中心」からの相対座標。草地の大きさ(192x128)に合わせてある。
 */
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";

const args = process.argv.slice(2);
const flag = (n) => args.includes(n);
const opt = (n, d) => args.find((a) => a.startsWith(`${n}=`))?.slice(n.length + 1) ?? d;
const MAP = args.find((a) => !a.startsWith("--")) ?? "client/src/config/map.json";
const ISLAND = opt("--island", "浮島 27");
const T = 16;

const map = JSON.parse(readFileSync(MAP, "utf8"));
map.objects ??= [];
map.sprites ??= {};

// ---------------------------------------------------------------- 島と草地
const g = (map.groups ?? []).find((x) => x.label === ISLAND);
if (!g) throw new Error(`島「${ISLAND}」が map.groups にありません`);
let minx = 1e9, maxx = -1, miny = 1e9, maxy = -1;
for (let y = g.y; y < g.y + g.h; y++) {
  for (let x = g.x; x < g.x + g.w; x++) {
    if (map.layers.collision[y]?.[x] === 0) {
      minx = Math.min(minx, x); maxx = Math.max(maxx, x); miny = Math.min(miny, y); maxy = Math.max(maxy, y);
    }
  }
}
const grass = { x0: minx * T, y0: miny * T, w: (maxx - minx + 1) * T, h: (maxy - miny + 1) * T };
if (grass.w < 176 || grass.h < 112) throw new Error(`草地が小さすぎます(${grass.w}x${grass.h})`);
const CX = grass.x0 + grass.w / 2; // 草地の中心X
const Y0 = grass.y0; // 草地の上端Y
console.log(`島「${ISLAND}」草地 ${grass.w}x${grass.h}px 原点(${grass.x0},${grass.y0})`);

// 島の範囲に配置物があれば止まる
const inIsland = (o) => o.x >= g.x * T - 40 && o.x < (g.x + g.w) * T + 40 && o.y >= g.y * T - 60 && o.y < (g.y + g.h) * T + 40;
const existing = map.objects.filter(inIsland);
if (existing.length && !flag("--replace")) {
  console.error(`この島には配置物が ${existing.length} 個あります。作り直すなら --replace を付けてください。`);
  process.exit(1);
}
map.objects = map.objects.filter((o) => !inIsland(o));

// ---------------------------------------------------------------- 絵の定義
/** 専用ドット絵（client/public/brand/stall/）。file は素材パックの assets/ からの相対パス */
function customDef(name, ox, oy) {
  const png = PNG.sync.read(readFileSync(`client/public/brand/stall/${name}.png`));
  map.sprites[name] = { file: `../brand/stall/${name}.png`, fw: png.width, fh: png.height, frames: 1, fps: 10, ox: ox ?? png.width / 2, oy: oy ?? png.height, catalog: true };
}
customDef("okonomi_sign");
customDef("okonomi_nobori", 1, 78);
customDef("okonomi_lantern");
customDef("okonomi_menu");
customDef("okonomi_teppan");
customDef("okonomi_plate");
customDef("okonomi_counter");
customDef("okonomi_roof");
customDef("okonomi_post");

// タイルセット画像から「その点にある1個の絵」の枠を探す（editor/tileItems.ts と同じ見つけ方）
const sheet = PNG.sync.read(readFileSync("client/public/assets/tilesets/sunnyside_16_ext.png"));
const items = (() => {
  const W = sheet.width, H = sheet.height, d = sheet.data;
  const seen = new Uint8Array(W * H);
  const comps = [];
  const stack = [];
  for (let s = 0; s < W * H; s++) {
    if (seen[s] || d[s * 4 + 3] <= 8) continue;
    let x0 = W, y0 = H, x1 = -1, y1 = -1, px = 0;
    stack.push(s); seen[s] = 1;
    while (stack.length) {
      const p = stack.pop(); const x = p % W, y = (p / W) | 0; px++;
      x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y);
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
        const q = ny * W + nx;
        if (seen[q] || d[q * 4 + 3] <= 8) continue;
        seen[q] = 1; stack.push(q);
      }
    }
    comps.push({ x0, y0, x1, y1, px });
  }
  let list = comps;
  for (let changed = true; changed;) {
    changed = false;
    const out = []; const used = new Array(list.length).fill(false);
    for (let i = 0; i < list.length; i++) {
      if (used[i]) continue;
      const a = { ...list[i] };
      for (let j = i + 1; j < list.length; j++) {
        if (used[j]) continue; const b = list[j];
        if (a.x0 <= b.x1 && b.x0 <= a.x1 && a.y0 <= b.y1 && b.y0 <= a.y1) {
          a.x0 = Math.min(a.x0, b.x0); a.y0 = Math.min(a.y0, b.y0); a.x1 = Math.max(a.x1, b.x1); a.y1 = Math.max(a.y1, b.y1); a.px += b.px;
          used[j] = true; changed = true;
        }
      }
      out.push(a);
    }
    list = out;
  }
  return list.filter((c) => c.px >= 6 && c.x1 - c.x0 + 1 <= 80 && c.y1 - c.y0 + 1 <= 80).map((c) => ({ x: c.x0, y: c.y0, w: c.x1 - c.x0 + 1, h: c.y1 - c.y0 + 1, px: c.px }));
})();
function cropAt(px, py) {
  const it = items.find((i) => px >= i.x && px < i.x + i.w && py >= i.y && py < i.y + i.h);
  if (!it) throw new Error(`タイルセットの (${px},${py}) に絵が見つかりません`);
  const name = `crop:main:${it.x},${it.y},${it.w}x${it.h}`;
  map.sprites[name] ??= { file: "", fw: it.w, fh: it.h, frames: 1, fps: 0, ox: it.w / 2, oy: it.h, catalog: true, crop: { tileset: "main", x: it.x, y: it.y, w: it.w, h: it.h, px: it.px } };
  return name;
}
/** 自動検出では他の絵とつながって大きくなってしまうもの（敷物）は、枠を直接指定する */
function cropRect(x, y, w, h) {
  const name = `crop:main:${x},${y},${w}x${h}`;
  map.sprites[name] ??= { file: "", fw: w, fh: h, frames: 1, fps: 0, ox: w / 2, oy: h, catalog: true, crop: { tileset: "main", x, y, w, h, px: w * h } };
  return name;
}
const TABLE = cropAt(808, 586); // 四角い木のテーブル
const RUG = cropRect(644, 563, 41, 42); // 赤い敷物
const POT_A = cropAt(825, 519); // ひまわりの鉢
const POT_B = cropAt(841, 519);
const STOOL = cropAt(805, 543); // 小さな丸椅子

// ---------------------------------------------------------------- 配置の道具
/** 足元中央(cx,foot)にスプライトを置く。cx は草地の中心からのずれ、foot は草地の上端からの距離(px)。 */
function put(name, dx, foot, o = {}) {
  const d = map.sprites[name];
  if (!d) throw new Error(`スプライト ${name} が map.sprites にありません`);
  const cx = CX + dx, fy = Y0 + foot;
  const isChar = d.fw === 96 && d.fh === 64;
  const x = isChar ? cx : cx + d.ox - d.fw / 2;
  const y = isChar ? fy - 8 : fy + d.oy - d.fh;
  const obj = { sprite: name, x: Math.round(x * 100) / 100, y: Math.round(y * 100) / 100, sort: o.sort ?? "y", by: o.by !== undefined ? Y0 + o.by : fy };
  if (o.flip) obj.sx = -1;
  if (o.hit) { obj.hit = o.hit; obj.hx = cx; }
  if (o.frame !== undefined) obj.frame = o.frame;
  if (o.npc) obj.npc = o.npc;
  map.objects.push(obj);
  return obj;
}
/** 人物（影つき）。足元に影を別の物として置く（エディタの「影も一緒に置く」と同じ） */
function person(name, dx, foot, npc, flip = false) {
  const o = put(name, dx, foot, { hit: [12, 8], flip, npc });
  map.objects.push({ sprite: "spr_deco_charactershadow", x: o.x, y: o.by - 1 - 0, sort: "floor", by: o.by - 1 + 8 });
  return o;
}
const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

// ---------------------------------------------------------------- 屋台
// 敷物（床）。カウンターの前の「ここに立つ」マット
put(RUG, 0, 108, { sort: "floor" });

// 柱・日よけ・看板
put("okonomi_post", -51, 78, { hit: [6, 6] });
put("okonomi_post", 51, 78, { hit: [6, 6] });
put("okonomi_roof", 0, 42);
put("okonomi_sign", 0, 22);
// 提灯（日よけの下）
put("okonomi_lantern", -34, 64, { by: 60 });
put("okonomi_lantern", 34, 64, { by: 60 });
// のぼり旗（両脇）
put("okonomi_nobori", -74, 76, { hit: [4, 4] });
put("okonomi_nobori", 74, 76, { hit: [4, 4] });

// カウンターの奥: 鉄板・店主・湯気
put("okonomi_teppan", 16, 68);
put("chimneysmoke_03", 8, 44, { by: 70 });
put("chimneysmoke_03", 24, 44, { by: 70 });
put("chimneysmoke_03", 16, 40, { by: 70 });
person(
  "human_shorthair_doing",
  -14,
  56,
  {
    name: "お好み焼き屋さん",
    lines: [
      "いらっしゃい！ お好み焼き、やっています！",
      "キャベツたっぷりの生地を、鉄板でじゅーっと焼くよ。",
      "ミックス、ぶた玉、いか玉。ソースとマヨネーズと青のりは、お好みでどうぞ！",
      "ひっくり返すのが一番むずかしいんだ。コテさばきを見ていってね！",
    ],
  },
);
put("expression_chat", -14, 33, { by: 90 });

// カウンター（赤い前掛け）と、その上の食べ物・飲み物・調味料
put("okonomi_counter", 0, 80, { hit: [100, 10] });
put("kale_05", -42, 64, { by: ON_COUNTER });
put("egg", -30, 64, { by: ON_COUNTER });
put("egg", -22, 65, { by: ON_COUNTER });
put("spr_deco_jar_01", -4, 64, { by: ON_COUNTER }); // ソース
put("spr_deco_mug_02", 28, 63, { by: ON_COUNTER });
put("okonomi_plate", 16 + 18, 63, { by: ON_COUNTER });
put("okonomi_plate", 16 + 38, 63, { by: ON_COUNTER });

// 前のお客さん
person("human_curlyhair_idle", 30, 98, { name: "おきゃくさん", lines: ["ここのお好み焼き、ソースの香りがたまらない！", "ふわふわで、キャベツが甘いんだよ。"] }, true);
put("happiness_01", 30, 74, { by: 120 });
person("human_mophair_waiting", -44, 108, { name: "こども", lines: ["ぼくはマヨネーズ多めがすき！", "あつあつだから、ふーふーして食べるんだ。"] });

// テーブル席: テーブルに皿、丸椅子
put(TABLE, -62, 118, { hit: [18, 8] });
put("okonomi_plate", -66, 106, { by: 119 });
put("okonomi_plate", -56, 108, { by: 119 });
put("spr_deco_mug_01", -50, 106, { by: 119 });
put(STOOL, -84, 120, { hit: [8, 6] });
put(STOOL, -40, 124, { hit: [8, 6] });

// メニュー（右手前の黒板）と飾りのひまわり
put("okonomi_menu", 68, 128, { hit: [44, 6] });
put(POT_A, 86, 126);
put(POT_B, -90, 100);

// ---------------------------------------------------------------- 書き出し
console.log(`配置物は全部で ${map.objects.length} 個`);
if (flag("--dry")) {
  console.log("--dry: 書き込みません");
  process.exit(0);
}
mkdirSync("reference/map-backups", { recursive: true });
const backup = `reference/map-backups/map.before-okonomiyaki-${Date.now()}.json`;
copyFileSync(MAP, backup);
writeFileSync(MAP, JSON.stringify(map));
console.log(`バックアップ: ${backup}\n書き込みました: ${MAP}`);

