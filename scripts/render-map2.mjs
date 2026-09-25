/**
 * 新形式 map.json（tileLayers / objects / sprites）を1枚のPNGに描く確認用ツール（ブラウザ不要）。
 *   node scripts/render-map2.mjs [map.json] [out.png] [--collision] [--scale 1] [--crop x,y,w,h(px)]
 * 描画順はゲームと同じ考え方: floor → (ysort 行 と y-objects を足元Y順) → top
 */
import { readFileSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";

const args = process.argv.slice(2);
const pos = args.filter((a, i) => !a.startsWith("--") && !(args[i - 1] ?? "").startsWith("--"));
const mapPath = pos[0] ?? "client/src/config/map.json";
const outPath = pos[1] ?? "reference/render2.png";
const opt = (k, d) => (args.includes(`--${k}`) ? args[args.indexOf(`--${k}`) + 1] : d);
const SCALE = Number(opt("scale", 1));
const map = JSON.parse(readFileSync(mapPath, "utf8"));
const rd = (p) => PNG.sync.read(readFileSync(`client/public/assets/${p}`));
const tilesets = Object.fromEntries(Object.entries(map.tilesets).map(([k, v]) => [k, { ...v, img: rd(v.image) }]));
const sheets = Object.fromEntries(Object.entries(map.sprites).map(([k, v]) => [k, { ...v, img: rd(v.file) }]));

const PW = map.width * map.tileSize, PH = map.height * map.tileSize;
const [cx0, cy0, cw, ch] = (opt("crop", null) ?? `0,0,${PW},${PH}`).split(",").map(Number);
const out = new PNG({ width: cw * SCALE, height: ch * SCALE });
for (let i = 0; i < out.data.length; i += 4) { out.data[i] = 20; out.data[i + 1] = 30; out.data[i + 2] = 40; out.data[i + 3] = 255; }

const blend = (px, py, r, g, b, a) => {
  // 出力座標(縮尺前のpx)に SCALE 倍で塗る
  const x0 = (px - cx0) * SCALE, y0 = (py - cy0) * SCALE;
  for (let sy = 0; sy < SCALE; sy++) for (let sx = 0; sx < SCALE; sx++) {
    const X = Math.round(x0) + sx, Y = Math.round(y0) + sy;
    if (X < 0 || Y < 0 || X >= out.width || Y >= out.height) continue;
    const di = (Y * out.width + X) * 4;
    out.data[di] = r * a + out.data[di] * (1 - a); out.data[di + 1] = g * a + out.data[di + 1] * (1 - a); out.data[di + 2] = b * a + out.data[di + 2] * (1 - a);
  }
};
function drawTile(ts, id, dx, dy) {
  const s = ts.tileSize, c = id % ts.columns, r = Math.floor(id / ts.columns);
  for (let y = 0; y < s; y++) for (let x = 0; x < s; x++) {
    const i = ((r * s + y) * ts.img.width + c * s + x) * 4;
    const a = ts.img.data[i + 3] / 255;
    if (a) blend(dx + x, dy + y, ts.img.data[i], ts.img.data[i + 1], ts.img.data[i + 2], a);
  }
}
function drawObject(o) {
  const sh = sheets[o.sprite];
  const sx = o.sx ?? 1, sy = o.sy ?? 1, ang = ((o.angle ?? 0) * Math.PI) / 180;
  const f = (o.frame ?? 0) % sh.frames;
  const w = Math.abs(sx) * sh.fw, h = Math.abs(sy) * sh.fh;
  const R = Math.ceil(Math.hypot(w, h)) + 2;
  const cos = Math.cos(ang), sin = Math.sin(ang);
  for (let ty = Math.floor(o.y) - R; ty <= o.y + R; ty++) for (let tx = Math.floor(o.x) - R; tx <= o.x + R; tx++) {
    // 逆変換: 画面点 → スプライトのローカル座標
    const dx = tx + 0.5 - o.x, dy = ty + 0.5 - o.y;
    const rx = dx * cos + dy * sin, ry = -dx * sin + dy * cos;
    const lx = Math.floor(rx / sx + sh.ox), ly = Math.floor(ry / sy + sh.oy);
    if (lx < 0 || ly < 0 || lx >= sh.fw || ly >= sh.fh) continue;
    const i = (ly * sh.img.width + f * sh.fw + lx) * 4;
    const a = sh.img.data[i + 3] / 255;
    if (a) blend(tx, ty, sh.img.data[i], sh.img.data[i + 1], sh.img.data[i + 2], a);
  }
}

// ---- 描画キューを組む
const queue = []; // {z, draw}
let zc = 0;
for (const l of map.tileLayers) {
  const ts = tilesets[l.tileset], s = ts.tileSize;
  if (l.mode === "ysort") {
    l.data.forEach((row, ry) => queue.push({ z: (ry + 1) * s, k: 1, draw: () => row.forEach((id, rx) => id >= 0 && drawTile(ts, id, rx * s, ry * s)) }));
  } else {
    const z = l.mode === "top" ? 1e6 + zc++ : -1e6 + zc++;
    queue.push({ z, k: 0, draw: () => l.data.forEach((row, ry) => row.forEach((id, rx) => id >= 0 && drawTile(ts, id, rx * s, ry * s))) });
  }
}
for (const o of map.objects) queue.push({ z: o.sort === "floor" ? -5e5 : o.by, k: 2, draw: () => drawObject(o) });
queue.sort((a, b) => a.z - b.z || a.k - b.k);
queue.forEach((q) => q.draw());

if (args.includes("--components")) {
  // 歩ける領域を連結成分ごとに色分け（最大=緑、他=成分ごとに別色）。塞がれた所は薄い赤
  const Wt = map.width, Ht = map.height, col = map.layers.collision;
  const id = Array.from({ length: Ht }, () => Array(Wt).fill(-1));
  const sizes = [];
  for (let sy = 0; sy < Ht; sy++) for (let sx = 0; sx < Wt; sx++) {
    if (col[sy][sx] === 1 || id[sy][sx] >= 0) continue;
    const c = sizes.length; let n = 0; const st = [[sx, sy]]; id[sy][sx] = c;
    while (st.length) { const [x, y] = st.pop(); n++; for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) { const nx = x+dx, ny = y+dy; if (nx<0||ny<0||nx>=Wt||ny>=Ht||col[ny][nx]===1||id[ny][nx]>=0) continue; id[ny][nx] = c; st.push([nx, ny]); } }
    sizes.push(n);
  }
  const order = sizes.map((n, i) => [n, i]).sort((a, b) => b[0] - a[0]);
  const palette = [[40, 220, 60], [255, 220, 0], [0, 200, 255], [255, 0, 220], [255, 140, 0], [160, 100, 255], [255, 255, 255]];
  const rank = new Map(order.map(([, i], r) => [i, r]));
  for (let y = 0; y < Ht; y++) for (let x = 0; x < Wt; x++) {
    const c = id[y][x];
    const [r, g, b] = c < 0 ? [255, 40, 40] : palette[Math.min(rank.get(c), palette.length - 1)];
    const a = c < 0 ? 0.25 : 0.5;
    for (let i = 0; i < 256; i++) blend(x * 16 + (i % 16), y * 16 + Math.floor(i / 16), r, g, b, a);
  }
  console.log("component sizes (top 8):", order.slice(0, 8).map(([n]) => n).join(", "));
}
if (args.includes("--collision")) {
  map.layers.collision.forEach((row, y) => row.forEach((v, x) => v === 1 && [...Array(16 * 16)].forEach((_, i) => blend(x * 16 + (i % 16), y * 16 + Math.floor(i / 16), 255, 40, 40, 0.38))));
  for (const o of map.objects) if (o.hit) for (let y = 0; y < o.hit[1]; y++) for (let x = 0; x < o.hit[0]; x++) blend(o.hx - o.hit[0] / 2 + x, o.by - o.hit[1] + y, 255, 200, 0, 0.6);
  blend(map.spawn.x * 16, map.spawn.y * 16, 0, 0, 0, 0);
  for (let i = 0; i < 16; i++) for (let j = 0; j < 16; j++) blend(map.spawn.x * 16 + i, map.spawn.y * 16 + j, 60, 120, 255, 0.7);
}
writeFileSync(outPath, PNG.sync.write(out));
console.log(`wrote ${outPath} (${out.width}x${out.height})`);
