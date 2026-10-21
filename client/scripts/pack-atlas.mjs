/**
 * 配置物のスプライトシート（約580個の小さなPNG）を、数枚の大きな画像（アトラス）に詰め合わせる。
 *   node scripts/pack-atlas.mjs          （client/ で実行。`npm run build -w client` の前に自動で動く）
 *
 * 目的: 読み込みのリクエストを約600個 → 数個にして、読み込みを速くする。描画でも、絵ごとにテクスチャを切り替えずに済む。
 * 入力 : client/src/config/map.json の sprites（クライアントが読み込む絵と同じ条件で選ぶ）
 * 出力 : client/public/atlas/page-N.png と manifest.json（git には入れない。ビルドのたびに作る）
 *
 * manifest.json が無い・読めないときは、クライアントは今までどおり1枚ずつ読み込む（フォールバック）。
 * 2046px より幅の広いシートは詰めずに、1枚ずつ読み込む。
 */
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { PNG } from "pngjs";

const here = dirname(fileURLToPath(import.meta.url));
const clientDir = resolve(here, "..");
const mapPath = join(clientDir, "src/config/map.json");
const assetsDir = join(clientDir, "public/assets");
const outDir = join(clientDir, "public/atlas");

const PAGE = 2048;
const GUTTER = 2;

if (!existsSync(mapPath)) {
  console.log("[atlas] map.json が無いので、アトラスは作りません（1枚ずつ読み込みます）");
  process.exit(0);
}
const map = JSON.parse(readFileSync(mapPath, "utf8"));
const used = new Set((map.objects ?? []).map((o) => o.sprite));

// クライアント（assets.ts の queueAssets）が読み込む絵と同じ条件
const items = [];
for (const [name, sp] of Object.entries(map.sprites ?? {})) {
  if (sp.crop) continue;
  if (sp.catalog && !used.has(name)) continue;
  const file = resolve(assetsDir, sp.file); // "../brand/stall/x.png" は public/brand/stall/x.png になる
  if (!existsSync(file)) continue;
  const png = PNG.sync.read(readFileSync(file));
  if (png.width !== sp.fw * sp.frames || png.height !== sp.fh) continue; // 定義と寸法が合わないものは1枚ずつ（安全のため）
  if (png.width > PAGE - GUTTER * 2) continue;
  items.push({ name, png });
}
items.sort((a, b) => b.png.height - a.png.height || b.png.width - a.png.width);

// 棚詰め（高い順に、左から並べて、はみ出したら次の段・次のページ）
const pages = [];
const place = [];
let page = null;
const newPage = () => {
  page = { shelfY: GUTTER, shelfH: 0, x: GUTTER, usedH: GUTTER, items: [] };
  pages.push(page);
};
newPage();
for (const it of items) {
  const { width: w, height: h } = it.png;
  if (page.x + w + GUTTER > PAGE) {
    page.shelfY += page.shelfH + GUTTER;
    page.shelfH = 0;
    page.x = GUTTER;
  }
  if (page.shelfY + h + GUTTER > PAGE) newPage();
  if (page.shelfH === 0) page.shelfH = h;
  const x = page.x, y = page.shelfY;
  page.x += w + GUTTER;
  page.usedH = Math.max(page.usedH, y + h + GUTTER);
  page.items.push({ it, x, y });
  place.push({ name: it.name, p: pages.length - 1, x, y });
}

if (existsSync(outDir)) for (const f of readdirSync(outDir)) rmSync(join(outDir, f));
mkdirSync(outDir, { recursive: true });

const manifest = { pages: [], sprites: {} };
pages.forEach((pg, i) => {
  if (!pg.items.length) return;
  const H = pg.usedH;
  const out = new PNG({ width: PAGE, height: H });
  for (const { it, x, y } of pg.items) PNG.bitblt(it.png, out, 0, 0, it.png.width, it.png.height, x, y);
  const file = `page-${i}.png`;
  writeFileSync(join(outDir, file), PNG.sync.write(out, { colorType: 6 }));
  manifest.pages[i] = { file: `../atlas/${file}`, w: PAGE, h: H };
});
for (const p of place) manifest.sprites[p.name] = { p: p.p, x: p.x, y: p.y };
writeFileSync(join(outDir, "manifest.json"), JSON.stringify(manifest));
console.log(`[atlas] ${place.length} 枚のシートを ${manifest.pages.length} ページに詰めました（詰めなかったもの ${Object.keys(map.sprites).length - place.length - Object.values(map.sprites).filter((s) => s.crop).length}）`);
