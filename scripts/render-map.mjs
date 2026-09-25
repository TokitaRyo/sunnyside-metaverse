/**
 * map.json のタイル層(ground/deco/overhead)を PNG に描き出す確認用ツール（ブラウザ不要）。
 *   node scripts/render-map.mjs [map.json] [out.png] [--scale 2] [--crop x,y,w,h(タイル)] [--grid]
 * props / mobs は描かない（タイル配置の確認用）。
 */
import { readFileSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";

const args = process.argv.slice(2);
const pos = args.filter((a, i) => !a.startsWith("--") && !(args[i - 1] ?? "").startsWith("--"));
const mapPath = pos[0] ?? "client/src/config/map.json";
const outPath = pos[1] ?? "reference/render.png";
const opt = (k, d) => (args.includes(`--${k}`) ? args[args.indexOf(`--${k}`) + 1] : d);
const SCALE = Number(opt("scale", 2));
const GRID = args.includes("--grid");
const T = 16;

const map = JSON.parse(readFileSync(mapPath, "utf8"));
const ts = PNG.sync.read(readFileSync("client/public/assets/tilesets/sunnyside_16.png"));
let [cx0, cy0, cw, ch] = (opt("crop", null) ?? `0,0,${map.width},${map.height}`).split(",").map(Number);

const out = new PNG({ width: cw * T * SCALE, height: ch * T * SCALE });
for (let i = 0; i < out.data.length; i += 4) { out.data[i] = 27; out.data[i + 1] = 42; out.data[i + 2] = 26; out.data[i + 3] = 255; }

const put = (id, tx, ty) => {
  if (id < 0) return;
  const c = id % 64, r = Math.floor(id / 64);
  for (let y = 0; y < T; y++)
    for (let x = 0; x < T; x++) {
      const si = ((r * T + y) * ts.width + c * T + x) * 4;
      const a = ts.data[si + 3] / 255;
      if (a === 0) continue;
      for (let sy = 0; sy < SCALE; sy++)
        for (let sx = 0; sx < SCALE; sx++) {
          const di = (((ty * T + y) * SCALE + sy) * out.width + (tx * T + x) * SCALE + sx) * 4;
          for (let k = 0; k < 3; k++) out.data[di + k] = ts.data[si + k] * a + out.data[di + k] * (1 - a);
        }
    }
};
for (const name of ["ground", "deco", "overhead"]) {
  const layer = map.layers[name];
  for (let y = 0; y < ch; y++)
    for (let x = 0; x < cw; x++) put(layer[cy0 + y]?.[cx0 + x] ?? -1, x, y);
}
// 衝突マスを赤い枠で表示
if (args.includes("--collision")) {
  for (let y = 0; y < ch; y++)
    for (let x = 0; x < cw; x++)
      if (map.layers.collision[cy0 + y]?.[cx0 + x] === 1)
        for (let k = 0; k < T * SCALE; k++)
          for (const [px, py] of [[k, 0], [k, T * SCALE - 1], [0, k], [T * SCALE - 1, k]]) {
            const di = ((y * T * SCALE + py) * out.width + x * T * SCALE + px) * 4;
            out.data[di] = 255; out.data[di + 1] = 60; out.data[di + 2] = 60;
          }
}
if (GRID) {
  for (let y = 0; y < out.height; y++)
    for (let x = 0; x < out.width; x++)
      if (x % (T * SCALE) === 0 || y % (T * SCALE) === 0) {
        const di = (y * out.width + x) * 4;
        out.data[di] = out.data[di] * 0.75 + 60; out.data[di + 1] = out.data[di + 1] * 0.75 + 60; out.data[di + 2] = out.data[di + 2] * 0.75 + 60;
      }
}
writeFileSync(outPath, PNG.sync.write(out));
console.log(`wrote ${outPath} (${out.width}x${out.height})`);
