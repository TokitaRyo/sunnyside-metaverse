// GameMaker(.yy) ルーム読み込みと、タイルの反転・回転を焼き込んだ拡張タイルセットの生成
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { PNG } from "pngjs";

/** GameMaker の .yy は末尾カンマ付きJSON */
export const parseYY = (p) => JSON.parse(readFileSync(p, "utf8").replace(/,(\s*[}\]])/g, "$1"));

/**
 * GameMaker のスプライト(フレームごとのPNG)を、フレームを横一列に並べた1枚のシートにして
 * client/public/assets/gm/<name>.png に書き出し、map.json の sprites 用の定義を返す。
 */
export function buildGmSprite(GM, name, outDir = "client/public/assets/gm") {
  const yy = parseYY(join(GM, "sprites", name, `${name}.yy`));
  const fw = yy.width, fh = yy.height, n = yy.frames.length;
  const sheet = new PNG({ width: fw * n, height: fh });
  sheet.data.fill(0);
  yy.frames.forEach((f, i) => {
    const png = PNG.sync.read(readFileSync(join(GM, "sprites", name, `${f.name}.png`)));
    for (let y = 0; y < Math.min(fh, png.height); y++)
      for (let x = 0; x < Math.min(fw, png.width); x++) sheet.data.set(png.data.subarray((y * png.width + x) * 4, (y * png.width + x) * 4 + 4), (y * sheet.width + i * fw + x) * 4);
  });
  mkdirSync(outDir, { recursive: true });
  writeFileSync(`${outDir}/${name}.png`, PNG.sync.write(sheet));
  const speed = yy.sequence.playbackSpeedType === 0 ? yy.sequence.playbackSpeed : yy.sequence.playbackSpeed * 60;
  return { file: `gm/${name}.png`, fw, fh, frames: n, fps: speed, ox: yy.sequence.xorigin, oy: yy.sequence.yorigin };
}

const EMPTY = 0x80000000;

/** TileCompressedData(RLE) または TileSerialiseData を、w*h の生の値配列にする */
export function decodeTiles(layer) {
  const { SerialiseWidth: w, SerialiseHeight: h, TileCompressedData: comp, TileSerialiseData: raw } = layer.tiles;
  let out;
  if (raw) out = raw.slice();
  else {
    // 負の数 n: 次の値を -n 回繰り返す / 正の数 n: 続く n 個はそのまま
    out = [];
    for (let i = 0; i < comp.length; ) {
      const n = comp[i++];
      if (n < 0) {
        const v = comp[i++];
        for (let k = 0; k < -n; k++) out.push(v);
      } else for (let k = 0; k < n; k++) out.push(comp[i++]);
    }
  }
  if (out.length !== w * h) throw new Error(`${layer.name}: decoded ${out.length} != ${w}x${h}`);
  return { w, h, values: out };
}

/** 値 → {index, mirror, flip, rotate}。空マスは null */
export function splitTile(v) {
  const u = v >>> 0;
  if (u === EMPTY) return null;
  const index = u & 0x7ffff;
  if (index === 0) return null; // タイル0は透明
  return { index, mirror: !!(u & 0x10000000), flip: !!(u & 0x20000000), rotate: !!(u & 0x40000000) };
}

/** RGBA 画像上の (col,row) タイルを切り出す */
function cutTile(img, col, row, size) {
  const out = new Uint8Array(size * size * 4);
  for (let y = 0; y < size; y++)
    for (let x = 0; x < size; x++) {
      const si = ((row * size + y) * img.width + col * size + x) * 4;
      out.set(img.data.subarray(si, si + 4), (y * size + x) * 4);
    }
  return out;
}

/** タイル画像に変換を適用。order: "rot-first" | "flip-first"、rotDir: "cw" | "ccw" */
function transformTile(px, size, t, { order, rotDir }) {
  const at = (buf, x, y) => (y * size + x) * 4;
  const mirrorFlip = (src) => {
    const dst = new Uint8Array(src.length);
    for (let y = 0; y < size; y++)
      for (let x = 0; x < size; x++) {
        const sx = t.mirror ? size - 1 - x : x;
        const sy = t.flip ? size - 1 - y : y;
        dst.set(src.subarray(at(src, sx, sy), at(src, sx, sy) + 4), at(dst, x, y));
      }
    return dst;
  };
  const rotate = (src) => {
    const dst = new Uint8Array(src.length);
    for (let y = 0; y < size; y++)
      for (let x = 0; x < size; x++) {
        // cw: dst(x,y) = src(y, size-1-x)   ccw: dst(x,y) = src(size-1-y, x)
        const [sx, sy] = rotDir === "cw" ? [y, size - 1 - x] : [size - 1 - y, x];
        dst.set(src.subarray(at(src, sx, sy), at(src, sx, sy) + 4), at(dst, x, y));
      }
    return dst;
  };
  if (!t.rotate) return mirrorFlip(px);
  return order === "rot-first" ? mirrorFlip(rotate(px)) : rotate(mirrorFlip(px));
}

/**
 * 元タイルセット(PNG)に、使われている「変換つきタイル」を末尾行に追加した拡張タイルセットを作る。
 * 戻り値 resolve(tile) は、変換込みの新しいタイルIDを返す（row*columns+col の規則は同じ）。
 */
export function makeExtendedTileset(basePng, size, columns, opts) {
  const baseRows = Math.floor(basePng.height / size);
  const variants = new Map(); // key -> {tile, newIndex}
  const resolve = (t) => {
    if (!t) return -1;
    if (!t.mirror && !t.flip && !t.rotate) return t.index;
    const key = `${t.index}:${+t.mirror}${+t.flip}${+t.rotate}`;
    if (!variants.has(key)) variants.set(key, { t, newIndex: baseRows * columns + variants.size });
    return variants.get(key).newIndex;
  };
  const build = () => {
    const extraRows = Math.ceil(variants.size / columns);
    const out = new PNG({ width: basePng.width, height: (baseRows + extraRows) * size });
    out.data.fill(0);
    basePng.data.copy(out.data, 0, 0, basePng.data.length);
    for (const { t, newIndex } of variants.values()) {
      const src = cutTile(basePng, t.index % columns, Math.floor(t.index / columns), size);
      const px = transformTile(src, size, t, opts);
      const col = newIndex % columns, row = Math.floor(newIndex / columns);
      for (let y = 0; y < size; y++)
        for (let x = 0; x < size; x++) out.data.set(px.subarray((y * size + x) * 4, (y * size + x) * 4 + 4), ((row * size + y) * out.width + col * size + x) * 4);
    }
    return out;
  };
  return { resolve, build, count: () => variants.size };
}
