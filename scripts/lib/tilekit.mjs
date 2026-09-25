// マップ生成用の小さなヘルパー群（gen-map.mjs / 実験スクリプトから使う）
import { readFileSync } from "node:fs";
import { PNG } from "pngjs";

export const T = 16;
const ts = PNG.sync.read(readFileSync("client/public/assets/tilesets/sunnyside_16.png"));

/** タイルセット上でそのタイルが完全に透明か */
export function isEmptyTile(id) {
  const c = id % 64, r = Math.floor(id / 64);
  for (let y = 0; y < T; y++)
    for (let x = 0; x < T; x++) if (ts.data[((r * T + y) * ts.width + c * T + x) * 4 + 3] > 0) return false;
  return true;
}
export const tid = (col, row) => row * 64 + col;

export class Grid {
  constructor(w, h, fill = -1) {
    this.w = w;
    this.h = h;
    this.a = Array.from({ length: h }, () => Array(w).fill(fill));
  }
  set(x, y, id) {
    if (x >= 0 && y >= 0 && x < this.w && y < this.h) this.a[y][x] = id;
  }
  get(x, y) {
    return this.a[y]?.[x] ?? -1;
  }
  fillRect(x, y, w, h, id) {
    for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) this.set(x + i, y + j, id);
  }
  /** タイルセット上の矩形(col,row,w,h)を (x,y) に貼る。透明タイルは skipEmpty なら貼らない */
  stamp(x, y, col, row, w, h, { skipEmpty = true } = {}) {
    for (let j = 0; j < h; j++)
      for (let i = 0; i < w; i++) {
        const id = tid(col + i, row + j);
        if (skipEmpty && isEmptyTile(id)) continue;
        this.set(x + i, y + j, id);
      }
  }
}

const tilesetJson = JSON.parse(readFileSync("client/src/config/tileset.json", "utf8"));

/**
 * autotile グループ(16枚)の配置規則（実測）:
 *   [0]=べた塗り  縁取りは「土タイルの上に重ねる帯」  上[12] 下[3] 左[5] 右[10]
 *   角は斜め半分だけ地面になったタイル(反対側は透過)   左上角[1] 右上角[2] 左下角[4] 右下角[8]
 */
export const EDGE = { fill: 0, N: 12, S: 3, W: 10, E: 5, tl: 1, tr: 2, bl: 4, br: 8 };
// 縁取りは「縁が描かれている側」で呼ぶ: N=タイルの上端に縁 / E=右端に縁 …（実測。左右は直感と逆になりやすい）

/**
 * mask(boolean[][]) で示した領域を autotile グループで塗る。
 * ground に土(fill)を、縁と角は deco に重ねる。凸角セルは地面を敷かず斜めタイルだけにして丸くする。
 */
export function paintRegion(ground, deco, mask, groupName, { under = null, clampEdges = false } = {}) {
  const g = tilesetJson.autotileGroups[groupName];
  const pick = (k) => g.tiles[EDGE[k]];
  const mh = mask.length, mw = mask[0].length;
  // clampEdges: マップ外は端のセルと同じ扱い（道がマップ端まで続くように見せる）
  const inM = (x, y) => (clampEdges ? !!mask[Math.min(mh - 1, Math.max(0, y))][Math.min(mw - 1, Math.max(0, x))] : !!mask[y]?.[x]);
  for (let y = 0; y < mask.length; y++)
    for (let x = 0; x < mask[0].length; x++) {
      if (!inM(x, y)) continue;
      const n = !inM(x, y - 1), s = !inM(x, y + 1), w = !inM(x - 1, y), e = !inM(x + 1, y);
      // 凸角: 隣り合う2辺が領域外 → 斜めタイルだけ置く（地面は敷かない）
      const corner = n && w ? "tl" : n && e ? "tr" : s && w ? "bl" : s && e ? "br" : null;
      if (corner) {
        if (under != null) ground.set(x, y, under);
        deco.set(x, y, pick(corner));
        continue;
      }
      ground.set(x, y, g.fill);
      if (n) deco.set(x, y, pick("N"));
      else if (s) deco.set(x, y, pick("S"));
      else if (w) deco.set(x, y, pick("W"));
      else if (e) deco.set(x, y, pick("E"));
    }
}

/**
 * 池・川 (River グループ)。道とは逆で「水の上に草を重ねる」構造:
 *   水セル: ground=水。角の水セルは草の三角を重ねて丸める。
 *   水に接する陸セル: 縁取り付きの草タイルを置く（縁は水側の辺に描かれている）。
 */
export function paintPond(ground, deco, waterMask, { groupName = "River" } = {}) {
  const g = tilesetJson.autotileGroups[groupName];
  const pick = (k) => g.tiles[EDGE[k]];
  const isW = (x, y) => !!waterMask[y]?.[x];
  const cornerOf = (x, y) => {
    const n = !isW(x, y - 1), s = !isW(x, y + 1), w = !isW(x - 1, y), e = !isW(x + 1, y);
    return n && w ? "tl" : n && e ? "tr" : s && w ? "bl" : s && e ? "br" : null;
  };
  const H = waterMask.length, W = waterMask[0].length;
  for (let y = 0; y < H; y++)
    for (let x = 0; x < W; x++) {
      if (isW(x, y)) {
        ground.set(x, y, g.fill);
        const c = cornerOf(x, y);
        if (c) deco.set(x, y, pick(c));
        continue;
      }
      // 陸セル: 隣の水セルが「角でない」ときだけ縁取りを置く
      const side = (nx, ny) => isW(nx, ny) && !cornerOf(nx, ny);
      if (side(x, y + 1)) deco.set(x, y, pick("S"));
      else if (side(x, y - 1)) deco.set(x, y, pick("N"));
      else if (side(x + 1, y)) deco.set(x, y, pick("E"));
      else if (side(x - 1, y)) deco.set(x, y, pick("W"));
    }
}

/** 矩形の mask を作る */
export function rectMask(w, h, rects) {
  const m = Array.from({ length: h }, () => Array(w).fill(false));
  for (const [x, y, rw, rh] of rects) for (let j = 0; j < rh; j++) for (let i = 0; i < rw; i++) if (m[y + j]) m[y + j][x + i] = true;
  return m;
}

export function makeMap({ name, width, height, spawn, layers, props = [], mobs = [] }) {
  return {
    name,
    tileset: "sunnyside_16",
    tileSize: 16,
    width,
    height,
    spawn,
    layers: { ground: layers.ground.a, deco: layers.deco.a, overhead: layers.overhead.a, collision: layers.collision.a },
    props,
    mobs,
  };
}
