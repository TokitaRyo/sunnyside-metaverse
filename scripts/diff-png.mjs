// 2枚のPNGの差分ピクセル数と、差の大きい領域を報告する
import { readFileSync } from "node:fs";
import { PNG } from "pngjs";
const [a, b] = process.argv.slice(2).map((p) => PNG.sync.read(readFileSync(p)));
let diff = 0;
const cells = new Map();
for (let i = 0; i < a.data.length; i += 4) {
  if (a.data[i] !== b.data[i] || a.data[i + 1] !== b.data[i + 1] || a.data[i + 2] !== b.data[i + 2]) {
    diff++;
    const p = i / 4, x = p % a.width, y = Math.floor(p / a.width);
    const key = `${Math.floor(x / 16)},${Math.floor(y / 16)}`;
    cells.set(key, (cells.get(key) ?? 0) + 1);
  }
}
console.log(`different pixels: ${diff}  in ${cells.size} tiles`, [...cells.keys()].slice(0, 8).join(" "));
