import type Phaser from "phaser";
import { tilesetKey } from "../game/assets";
import type { CropRect } from "../game/cropSprites";

/**
 * タイルセット画像の中から「1個の絵」を自動で見つける。
 * 透明でない画素のつながり（斜めもつながっているとみなす）を1個の絵とし、
 * 枠が重なっているもの（本体と影など）は1個にまとめる。大きすぎるもの（地形・建物の屋根など）は除く。
 */
export interface TileItem extends CropRect {
  /** 透明でない画素の数 */
  px: number;
}

/** これより大きい(幅か高さがpx)ものは地形・建物の部品とみなして除く */
const MAX_SIDE = 80;
/** これより小さい(画素数)ものは、ごみとして除く */
const MIN_PIXELS = 6;
/** 透明とみなすアルファ値の上限 */
const ALPHA_MIN = 8;

const cache = new Map<string, TileItem[]>();

export function detectTileItems(textures: Phaser.Textures.TextureManager, tileset: string): TileItem[] {
  const hit = cache.get(tileset);
  if (hit) return hit;
  if (!textures.exists(tilesetKey(tileset))) return [];
  const img = textures.get(tilesetKey(tileset)).getSourceImage() as HTMLImageElement;
  const W = img.width, H = img.height;
  const cv = document.createElement("canvas");
  cv.width = W;
  cv.height = H;
  const ctx = cv.getContext("2d", { willReadFrequently: true })!;
  ctx.drawImage(img, 0, 0);
  const data = ctx.getImageData(0, 0, W, H).data;

  // 連結成分（8近傍）
  const seen = new Uint8Array(W * H);
  const stack: number[] = [];
  const comps: { x0: number; y0: number; x1: number; y1: number; px: number }[] = [];
  for (let start = 0; start < W * H; start++) {
    if (seen[start] || data[start * 4 + 3] <= ALPHA_MIN) continue;
    let x0 = W, y0 = H, x1 = -1, y1 = -1, px = 0;
    stack.push(start);
    seen[start] = 1;
    while (stack.length) {
      const p = stack.pop()!;
      const x = p % W, y = (p / W) | 0;
      px++;
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
      if (y < y0) y0 = y;
      if (y > y1) y1 = y;
      for (let dy = -1; dy <= 1; dy++) {
        const ny = y + dy;
        if (ny < 0 || ny >= H) continue;
        for (let dx = -1; dx <= 1; dx++) {
          const nx = x + dx;
          if (nx < 0 || nx >= W) continue;
          const q = ny * W + nx;
          if (seen[q] || data[q * 4 + 3] <= ALPHA_MIN) continue;
          seen[q] = 1;
          stack.push(q);
        }
      }
    }
    // 巨大な塊は、あとで除くのでここで打ち切る必要はない（走査は1回で済む）
    comps.push({ x0, y0, x1, y1, px });
  }

  // 枠が重なるものを1つにまとめる（まとまった結果が別の枠と重なることもあるので、変化がなくなるまで繰り返す）
  let list = comps;
  for (let changed = true; changed; ) {
    changed = false;
    const out: typeof comps = [];
    const used = new Array(list.length).fill(false);
    for (let i = 0; i < list.length; i++) {
      if (used[i]) continue;
      const a = { ...list[i] };
      for (let j = i + 1; j < list.length; j++) {
        if (used[j]) continue;
        const b = list[j];
        if (a.x0 <= b.x1 && b.x0 <= a.x1 && a.y0 <= b.y1 && b.y0 <= a.y1) {
          a.x0 = Math.min(a.x0, b.x0);
          a.y0 = Math.min(a.y0, b.y0);
          a.x1 = Math.max(a.x1, b.x1);
          a.y1 = Math.max(a.y1, b.y1);
          a.px += b.px;
          used[j] = true;
          changed = true;
        }
      }
      out.push(a);
    }
    list = out;
  }

  const items = list
    .filter((c) => c.px >= MIN_PIXELS && c.x1 - c.x0 + 1 <= MAX_SIDE && c.y1 - c.y0 + 1 <= MAX_SIDE)
    .map((c) => ({ tileset, x: c.x0, y: c.y0, w: c.x1 - c.x0 + 1, h: c.y1 - c.y0 + 1, px: c.px }))
    // 画面の読み順（上から、同じ段なら左から）。段は16pxで区切る
    .sort((a, b) => Math.floor(a.y / 16) - Math.floor(b.y / 16) || a.x - b.x || a.y - b.y);
  cache.set(tileset, items);
  return items;
}
