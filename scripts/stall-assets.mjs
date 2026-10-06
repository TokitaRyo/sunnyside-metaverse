/**
 * 出店づくりで使える素材を調べる道具。
 *   node scripts/stall-assets.mjs sprites [正規表現]        … 使えるスプライト名と大きさ（例: sprites "plate|mug|jar"）
 *   node scripts/stall-assets.mjs items [x0 y0 x1 y1]       … タイルセット(main)から自動で見つかる「1個の絵」の一覧（範囲指定可）
 *   node scripts/stall-assets.mjs crop x y w h [scale] [out.png]  … タイルセットの一部を拡大して画像にする（Read で見られる）
 *   node scripts/stall-assets.mjs sheet [scale] [out.png]   … 自動検出した全アイテムに番号を振らず、位置の目安つきで全体を拡大して出す
 * 画像の既定の出力先は reference/stall-previews/（git管理外）。
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";
import { loadSheet, tileItems } from "./lib/stall-kit.mjs";

const [cmd, ...rest] = process.argv.slice(2);
mkdirSync("reference/stall-previews", { recursive: true });

if (cmd === "sprites") {
  const re = rest[0] ? new RegExp(rest[0]) : null;
  const map = JSON.parse(readFileSync("client/src/config/map.json", "utf8"));
  for (const [name, d] of Object.entries(map.sprites).sort(([a], [b]) => a.localeCompare(b))) {
    if (d.crop || name.startsWith("okonomi_")) continue;
    if (re && !re.test(name)) continue;
    console.log(`${name}\t${d.fw}x${d.fh}\tframes=${d.frames}\torigin=(${d.ox},${d.oy})`);
  }
} else if (cmd === "items") {
  const [x0 = 0, y0 = 0, x1 = 1e9, y1 = 1e9] = rest.map(Number);
  for (const i of tileItems()) if (i.x >= x0 && i.x < x1 && i.y >= y0 && i.y < y1) console.log(`${i.x},${i.y}\t${i.w}x${i.h}`);
} else if (cmd === "crop") {
  const [x, y, w, h, scale = "4", out = "reference/stall-previews/crop.png"] = rest;
  writeCrop(+x, +y, +w, +h, +scale, out);
} else if (cmd === "sheet") {
  const [scale = "2", out = "reference/stall-previews/tileset.png"] = rest;
  const s = loadSheet();
  writeCrop(0, 0, s.width, s.height, +scale, out);
} else {
  console.error("使い方は、このファイルの先頭のコメントを見てください");
  process.exit(1);
}

function writeCrop(X, Y, W, H, S, out) {
  const src = loadSheet();
  const dst = new PNG({ width: W * S, height: H * S });
  for (let y = 0; y < H * S; y++) {
    for (let x = 0; x < W * S; x++) {
      const sx = X + Math.floor(x / S), sy = Y + Math.floor(y / S);
      const di = (y * dst.width + x) * 4;
      if (sx >= src.width || sy >= src.height) { dst.data[di + 3] = 255; continue; }
      const si = (sy * src.width + sx) * 4, a = src.data[si + 3];
      const chk = (Math.floor(x / 8) + Math.floor(y / 8)) & 1 ? 60 : 80; // 透明は市松で示す
      dst.data[di] = (src.data[si] * a + chk * (255 - a)) / 255;
      dst.data[di + 1] = (src.data[si + 1] * a + chk * (255 - a)) / 255;
      dst.data[di + 2] = (src.data[si + 2] * a + chk * (255 - a)) / 255;
      dst.data[di + 3] = 255;
    }
  }
  writeFileSync(out, PNG.sync.write(dst));
  console.log(`wrote ${out} (${dst.width}x${dst.height})`);
}
