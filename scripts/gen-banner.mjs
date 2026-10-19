/**
 * 横断幕をドット絵風にする第2段階（第1段階は scripts/gen-banner.ps1）。
 *   node scripts/gen-banner.mjs [縮小済みPNG] [出力PNG] [色数]
 * 出力は client/public/brand/stall/banner_amp.png（横断幕）と banner_post.png（柱）。
 * 色を少しあざやかにして、色数を減らし（メディアンカット）、外側に1pxの濃い縁取りを付ける。ディザは使わない（ベタ塗りにする）。
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { PNG } from "pngjs";

const SRC = process.argv[2] ?? "reference/amp-banner-small.png";
const OUT = process.argv[3] ?? "client/public/brand/stall/banner_amp.png";
const COLORS = Number(process.argv[4] ?? 28);
const OUTLINE = [26, 16, 48];

const png = PNG.sync.read(readFileSync(SRC));
const { width: W, height: H, data } = png;

// 少しあざやかに（彩度 +15%、コントラスト少し強め）
const boost = (r, g, b) => {
  const l = 0.299 * r + 0.587 * g + 0.114 * b;
  const f = (c) => Math.max(0, Math.min(255, Math.round((l + (c - l) * 1.15 - 128) * 1.06 + 128)));
  return [f(r), f(g), f(b)];
};
const px = [];
for (let i = 0; i < W * H; i++) px.push(boost(data[i * 4], data[i * 4 + 1], data[i * 4 + 2]));

// メディアンカット
let boxes = [Array.from({ length: px.length }, (_, i) => i)];
const rangeOf = (box) => {
  const mn = [255, 255, 255], mx = [0, 0, 0];
  for (const i of box) for (let c = 0; c < 3; c++) { mn[c] = Math.min(mn[c], px[i][c]); mx[c] = Math.max(mx[c], px[i][c]); }
  const r = [mx[0] - mn[0], mx[1] - mn[1], mx[2] - mn[2]];
  const ch = r.indexOf(Math.max(...r));
  return { ch, size: r[ch] * Math.sqrt(box.length) };
};
while (boxes.length < COLORS) {
  let bi = 0, bs = -1;
  boxes.forEach((b, i) => { if (b.length > 1) { const s = rangeOf(b).size; if (s > bs) { bs = s; bi = i; } } });
  if (bs <= 0) break;
  const box = boxes[bi];
  const { ch } = rangeOf(box);
  box.sort((a, b) => px[a][ch] - px[b][ch]);
  const mid = box.length >> 1;
  boxes.splice(bi, 1, box.slice(0, mid), box.slice(mid));
}
const pal = boxes.map((b) => {
  const s = [0, 0, 0];
  for (const i of b) for (let c = 0; c < 3; c++) s[c] += px[i][c];
  return s.map((v) => Math.round(v / b.length));
});
const near = (p) => {
  let bi = 0, bd = 1e9;
  for (let k = 0; k < pal.length; k++) {
    const d = (p[0] - pal[k][0]) ** 2 + (p[1] - pal[k][1]) ** 2 + (p[2] - pal[k][2]) ** 2;
    if (d < bd) { bd = d; bi = k; }
  }
  return pal[bi];
};

// 外側に1pxの縁取り
const OW = W + 2, OH = H + 2;
const out = new PNG({ width: OW, height: OH });
for (let y = 0; y < OH; y++) {
  for (let x = 0; x < OW; x++) {
    const o = (y * OW + x) * 4;
    const edge = x === 0 || y === 0 || x === OW - 1 || y === OH - 1;
    const c = edge ? OUTLINE : near(px[(y - 1) * W + (x - 1)]);
    out.data[o] = c[0]; out.data[o + 1] = c[1]; out.data[o + 2] = c[2]; out.data[o + 3] = 255;
  }
}
mkdirSync(dirname(OUT), { recursive: true });
writeFileSync(OUT, PNG.sync.write(out));
console.log(`wrote ${OUT} (${OW}x${OH}, ${pal.length} colors)`);

// 横断幕を支える柱 6x48（木の柱。左が明るく右が暗い。上に金具）
{
  const PW = 6, PH = 48;
  const post = new PNG({ width: PW, height: PH });
  const wood = [[196, 144, 92], [160, 110, 66], [118, 78, 48]];
  for (let y = 0; y < PH; y++) {
    for (let x = 0; x < PW; x++) {
      const o = (y * PW + x) * 4;
      let c;
      if (x === 0 || x === PW - 1 || y === PH - 1) c = OUTLINE;
      else if (y < 3) c = [90, 90, 110]; // 金具
      else c = wood[x === 1 ? 0 : x === PW - 2 ? 2 : 1];
      post.data[o] = c[0]; post.data[o + 1] = c[1]; post.data[o + 2] = c[2]; post.data[o + 3] = 255;
    }
  }
  writeFileSync(`${dirname(OUT)}/banner_post.png`, PNG.sync.write(post));
  console.log("wrote banner_post.png");
}
