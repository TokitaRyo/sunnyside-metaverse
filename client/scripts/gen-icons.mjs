/**
 * ホーム画面に追加したときのアイコン（client/public/icons/）を作る。1度だけ実行して、できた画像を git に入れる。
 *   node scripts/gen-icons.mjs        （client/ で実行）
 * 元は、オリジナルのドット絵の惑星（client/public/brand/earth.png）。濃い紺の地に置く（maskable でも切れないよう、中央に収める）。
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { PNG } from "pngjs";

const clientDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const earth = PNG.sync.read(readFileSync(join(clientDir, "public/brand/earth.png")));
const BG = [11, 10, 26];

/** size x size の紺の地の中央に、惑星を整数倍(scale)に拡大して置く */
function make(size, scale) {
  const out = new PNG({ width: size, height: size });
  for (let i = 0; i < size * size; i++) {
    out.data[i * 4] = BG[0]; out.data[i * 4 + 1] = BG[1]; out.data[i * 4 + 2] = BG[2]; out.data[i * 4 + 3] = 255;
  }
  const w = earth.width * scale;
  const ox = Math.round((size - w) / 2), oy = Math.round((size - w) / 2);
  for (let y = 0; y < w; y++) {
    for (let x = 0; x < w; x++) {
      const s = (Math.floor(y / scale) * earth.width + Math.floor(x / scale)) * 4;
      const a = earth.data[s + 3] / 255;
      if (a === 0) continue;
      const o = ((oy + y) * size + ox + x) * 4;
      for (let c = 0; c < 3; c++) out.data[o + c] = Math.round(earth.data[s + c] * a + out.data[o + c] * (1 - a));
    }
  }
  return out;
}

/** 最近傍で縮める（ドット絵がにじまないように） */
function shrink(src, size) {
  const out = new PNG({ width: size, height: size });
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const s = (Math.floor((y * src.height) / size) * src.width + Math.floor((x * src.width) / size)) * 4;
      const o = (y * size + x) * 4;
      for (let c = 0; c < 4; c++) out.data[o + c] = src.data[s + c];
    }
  }
  return out;
}

const dir = join(clientDir, "public/icons");
mkdirSync(dir, { recursive: true });
const big = make(512, 2); // 惑星 384px を、512px の中央に（周りに 64px の余白）
const write = (name, png) => writeFileSync(join(dir, name), PNG.sync.write(png));
write("icon-512.png", big);
write("icon-192.png", shrink(big, 192));
write("apple-touch-icon.png", shrink(big, 180));
console.log("wrote icons to", dir);
