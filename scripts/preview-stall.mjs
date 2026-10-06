/**
 * 出店の配置を、map.json に書かずに1枚の絵にして確かめる。
 *   node scripts/preview-stall.mjs <id> [--scale=4] [--grid] [--hit] [--out=path.png]
 * scripts/stalls/<id>.mjs を実行して、島の草地(192x128px)に配置した結果を、足元Yの順（床 → 手前ほど後）で重ねて描く。
 * 出力は既定で reference/stall-previews/<id>.png（git管理外）。Read ツールで画像として見られる。
 * 実際のエディタとの違い: アニメーションは1コマ目だけ・人物の頭上の名前や吹き出し(💬)は出ない・回転は無視。
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { PNG } from "pngjs";
import { loadSheet, makeKit } from "./lib/stall-kit.mjs";

const args = process.argv.slice(2);
const id = args.find((a) => !a.startsWith("--"));
if (!id) {
  console.error("使い方: node scripts/preview-stall.mjs <id> [--scale=4] [--grid] [--hit] [--out=path.png]");
  process.exit(1);
}
const opt = (n, d) => args.find((a) => a.startsWith(`${n}=`))?.slice(n.length + 1) ?? d;
const SCALE = Number(opt("--scale", 4));
const OUT = opt("--out", `reference/stall-previews/${id}.png`);

const map = JSON.parse(readFileSync("client/src/config/map.json", "utf8"));
map.objects = []; // 見本のスプライト定義だけ使い、既存の配置物は持ち込まない
const GW = 192, GH = 128, PAD = 48, CLIFF = 28;
const grass = { x0: PAD, y0: PAD, w: GW, h: GH };
const kit = makeKit(map, grass);
const mod = await import(pathToFileURL(`${process.cwd()}/scripts/stalls/${id}.mjs`).href);
mod.default(kit);

const W = GW + PAD * 2, H = GH + PAD + CLIFF + 20;
const img = new PNG({ width: W, height: H });
const set = (x, y, r, g, b, a = 255) => {
  if (x < 0 || y < 0 || x >= W || y >= H) return;
  const i = (y * W + x) * 4;
  if (a === 255) {
    img.data[i] = r; img.data[i + 1] = g; img.data[i + 2] = b; img.data[i + 3] = 255;
  } else {
    const t = a / 255;
    img.data[i] = Math.round(r * t + img.data[i] * (1 - t));
    img.data[i + 1] = Math.round(g * t + img.data[i + 1] * (1 - t));
    img.data[i + 2] = Math.round(b * t + img.data[i + 2] * (1 - t));
  }
};
// 背景: 空 → 草地（市松）→ がけ
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) set(x, y, 47, 138, 224);
for (let y = 0; y < GH; y++) {
  for (let x = 0; x < GW; x++) {
    const c = (Math.floor(x / 8) + Math.floor(y / 8)) % 2 === 0;
    set(PAD + x, PAD + y, c ? 104 : 96, c ? 196 : 188, c ? 80 : 74);
  }
}
for (let y = 0; y < CLIFF; y++) for (let x = 0; x < GW; x++) set(PAD + x, PAD + GH + y, 190 - (y % 6 < 3 ? 12 : 0), 110, 80);

const spriteCache = new Map();
function pixelsOf(name, def) {
  if (spriteCache.has(name)) return spriteCache.get(name);
  let png;
  let sx0 = 0, sy0 = 0;
  if (def.crop) {
    png = loadSheet();
    sx0 = def.crop.x; sy0 = def.crop.y;
  } else if (def.file.startsWith("../brand/")) {
    png = PNG.sync.read(readFileSync(`client/public/${def.file.slice(3)}`));
  } else {
    png = PNG.sync.read(readFileSync(`client/public/assets/${def.file}`));
  }
  const v = { png, sx0, sy0 };
  spriteCache.set(name, v);
  return v;
}

const objs = kit.map.objects.map((o, i) => ({ o, i }));
const floors = objs.filter((e) => e.o.sort === "floor");
const rest = objs.filter((e) => e.o.sort !== "floor").sort((a, b) => a.o.by - b.o.by || a.i - b.i);
for (const { o } of [...floors, ...rest]) {
  const def = map.sprites[o.sprite];
  const { png, sx0, sy0 } = pixelsOf(o.sprite, def);
  const frame = def.frames > 1 ? (o.frame ?? 0) % def.frames : 0;
  const flip = (o.sx ?? 1) < 0;
  for (let j = 0; j < def.fh; j++) {
    for (let i = 0; i < def.fw; i++) {
      const si = ((sy0 + j) * png.width + sx0 + frame * def.fw + i) * 4;
      const a = png.data[si + 3];
      if (!a) continue;
      const dx = flip ? Math.round(o.x + def.ox - i - 1) : Math.round(o.x - def.ox + i);
      const dy = Math.round(o.y - def.oy + j);
      set(dx, dy, png.data[si], png.data[si + 1], png.data[si + 2], a);
    }
  }
}

// 当たり判定（赤枠）とグリッド
const hitOn = args.includes("--hit"), gridOn = args.includes("--grid");
if (hitOn) {
  for (const o of kit.map.objects) {
    if (!o.hit) continue;
    const x0 = Math.round(o.hx - o.hit[0] / 2), y0 = Math.round(o.by - o.hit[1]);
    for (let i = 0; i < o.hit[0]; i++) { set(x0 + i, y0, 255, 40, 40, 200); set(x0 + i, y0 + o.hit[1] - 1, 255, 40, 40, 200); }
    for (let j = 0; j < o.hit[1]; j++) { set(x0, y0 + j, 255, 40, 40, 200); set(x0 + o.hit[0] - 1, y0 + j, 255, 40, 40, 200); }
  }
}
if (gridOn) {
  for (let x = 0; x <= GW; x += 16) for (let y = -PAD; y < GH + CLIFF; y++) set(PAD + x, PAD + y, 255, 255, 255, 38);
  for (let y = 0; y <= GH; y += 16) for (let x = -PAD; x < GW + PAD; x++) set(PAD + x, PAD + y, 255, 255, 255, 38);
  // 中心線（dx=0）
  for (let y = -PAD; y < GH + CLIFF; y += 2) set(PAD + GW / 2, PAD + y, 255, 255, 0, 150);
}

// 拡大（最近傍）して保存
const out = new PNG({ width: W * SCALE, height: H * SCALE });
for (let y = 0; y < out.height; y++) {
  for (let x = 0; x < out.width; x++) {
    const si = ((Math.floor(y / SCALE)) * W + Math.floor(x / SCALE)) * 4, di = (y * out.width + x) * 4;
    out.data[di] = img.data[si]; out.data[di + 1] = img.data[si + 1]; out.data[di + 2] = img.data[si + 2]; out.data[di + 3] = 255;
  }
}
mkdirSync(OUT.includes("/") ? OUT.slice(0, OUT.lastIndexOf("/")) : ".", { recursive: true });
writeFileSync(OUT, PNG.sync.write(out));
console.log(`${id}: ${kit.map.objects.length} 個を配置 → ${OUT} (${out.width}x${out.height}、草地は (${PAD * SCALE},${PAD * SCALE}) から ${GW * SCALE}x${GH * SCALE})`);
