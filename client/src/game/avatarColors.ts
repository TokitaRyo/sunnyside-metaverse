import type { Look } from "@metaverse/shared";

/**
 * アバターの色替え。素材の人物（約11x16pxの小さなドット絵）は色数がとても少ないので、
 * 「どの色がどの部分か」を色で見分けて、その部分の色だけを新しい色に置き換える。
 *  - 髪（髪型ごとの絵）: 髪の色（ふち取りの濃い色と、肌の色は変えない）
 *  - 服の上（赤い部分）・服の下（青いオーバーオール）
 *  - 目: 顔の中にある、肌に囲まれた濃い点（ふち取りと同じ色の2ドット）
 * 明るい色・暗い色（かげ・ハイライト）は、元の絵の「本体の色との明るさの差」を保ったまま新しい色に移す。
 * DOM（入室画面のプレビュー）と Phaser（ゲーム中のテクスチャ）の両方から、同じ関数を使う。
 */

type RGB = [number, number, number];

export function hexToRgb(hex: string): RGB {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function rgbToHsl(r: number, g: number, b: number): [number, number, number] {
  r /= 255; g /= 255; b /= 255;
  const mx = Math.max(r, g, b), mn = Math.min(r, g, b);
  const l = (mx + mn) / 2;
  if (mx === mn) return [0, 0, l];
  const d = mx - mn;
  const s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
  let h = mx === r ? (g - b) / d + (g < b ? 6 : 0) : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
  h *= 60;
  return [h, s, l];
}

function hslToRgb(h: number, s: number, l: number): RGB {
  h = (((h % 360) + 360) % 360) / 360;
  if (s === 0) {
    const v = Math.round(l * 255);
    return [v, v, v];
  }
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  const f = (t: number) => {
    t = (t + 1) % 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };
  return [Math.round(f(h + 1 / 3) * 255), Math.round(f(h) * 255), Math.round(f(h - 1 / 3) * 255)];
}

const clamp = (v: number, a: number, b: number) => Math.max(a, Math.min(b, v));
const dist = (a: RGB, b: RGB) => Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]) + Math.abs(a[2] - b[2]);

// ---- 素材の色（実測）
const SKIN: RGB = [232, 173, 125]; // e8ad7d
const SKIN_SHADES: RGB[] = [[200, 127, 92], [197, 129, 88], [187, 109, 83]]; // c87f5c / c58158 / bb6d53（前髪の下の影など）
const TOP_MAIN: RGB = [233, 50, 69]; // e93245（服の上の本体。明るい fa717a・暗い a51f33 がある）
const BOTTOM_MAIN: RGB = [55, 68, 100]; // 374464（服の下の本体。暗い 252c43 がある）

const isOutline = (r: number, g: number, b: number) => r <= 42 && g <= 42 && b <= 42; // 171424 など
const isSkin = (r: number, g: number, b: number) => dist([r, g, b], SKIN) <= 10;
const isSkinShade = (r: number, g: number, b: number) => SKIN_SHADES.some((s) => dist([r, g, b], s) <= 8);

/** 色を「基準の色(main)との明るさの差」を保ったまま、target の色合いに移す */
function shift(src: RGB, main: RGB, target: RGB): RGB {
  const [, s0, l0] = rgbToHsl(...src);
  const [, ms, ml] = rgbToHsl(...main);
  const [th, ts, tl] = rgbToHsl(...target);
  const dL = l0 - ml;
  const L = clamp(tl + dL * (dL < 0 ? 1 : 0.8), 0.07, 0.96);
  const S = clamp(ts * clamp(ms > 0.01 ? s0 / ms : 1, 0.6, 1.15), 0, 1);
  return hslToRgb(th, S, L);
}

/** 目の色は、肌の上で読めるように、明るすぎないところまでに抑える */
function eyeShade(target: RGB): RGB {
  const [h, s, l] = rgbToHsl(...target);
  return hslToRgb(h, Math.max(s, 0.35), Math.min(l, 0.42));
}

/**
 * ImageData（1枚のシート）を、その場で色替えする。
 * layer: "base" = 体（肌・目・服）, "hair" = 髪型の絵。tools など他の層は色替えしない。
 */
export function recolorImageData(img: ImageData, layer: "base" | "hair", look: Look): void {
  const { width: W, height: H, data } = img;
  const px = new Uint32Array(data.buffer);
  const at = (x: number, y: number) => {
    if (x < 0 || y < 0 || x >= W || y >= H) return -1;
    return (y * W + x) * 4;
  };

  if (layer === "hair") {
    if (!look.hairColor) return;
    const target = hexToRgb(look.hairColor);
    // この髪型の「本体の色」= ふち取り・肌・影を除いて、いちばん多い色
    const count = new Map<number, number>();
    for (let i = 0; i < px.length; i++) {
      const o = i * 4;
      if (data[o + 3] < 10) continue;
      const r = data[o], g = data[o + 1], b = data[o + 2];
      if (isOutline(r, g, b) || isSkin(r, g, b) || isSkinShade(r, g, b)) continue;
      const k = (r << 16) | (g << 8) | b;
      count.set(k, (count.get(k) ?? 0) + 1);
    }
    let main: RGB = [98, 53, 48];
    let best = 0;
    for (const [k, n] of count) if (n > best) { best = n; main = [(k >> 16) & 255, (k >> 8) & 255, k & 255]; }
    const cache = new Map<number, RGB>();
    for (let i = 0; i < px.length; i++) {
      const o = i * 4;
      if (data[o + 3] < 10) continue;
      const r = data[o], g = data[o + 1], b = data[o + 2];
      if (isOutline(r, g, b) || isSkin(r, g, b) || isSkinShade(r, g, b)) continue;
      const k = (r << 16) | (g << 8) | b;
      let c = cache.get(k);
      if (!c) cache.set(k, (c = shift([r, g, b], main, target)));
      data[o] = c[0]; data[o + 1] = c[1]; data[o + 2] = c[2];
    }
    return;
  }

  // ---- 体の層
  const top = look.top ? hexToRgb(look.top) : null;
  const bottom = look.bottom ? hexToRgb(look.bottom) : null;
  const eye = look.eyeColor ? eyeShade(hexToRgb(look.eyeColor)) : null;
  if (!top && !bottom && !eye) return;
  const skinAt = (x: number, y: number) => {
    const o = at(x, y);
    return o >= 0 && data[o + 3] >= 10 && isSkin(data[o], data[o + 1], data[o + 2]);
  };
  const skinNeighbors = (x: number, y: number) => (skinAt(x - 1, y) ? 1 : 0) + (skinAt(x + 1, y) ? 1 : 0) + (skinAt(x, y - 1) ? 1 : 0) + (skinAt(x, y + 1) ? 1 : 0);
  // 先に判定だけして（元の色を見て）、あとでまとめて書き込む（書き換えた色が隣の判定に影響しないように）
  const writes: [number, RGB][] = [];
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const o = (y * W + x) * 4;
      if (data[o + 3] < 10) continue;
      const r = data[o], g = data[o + 1], b = data[o + 2];
      if (isOutline(r, g, b)) {
        if (eye && skinNeighbors(x, y) >= 3) writes.push([o, eye]); // 肌に囲まれた濃い点 = 目
        continue;
      }
      if (isSkin(r, g, b) || isSkinShade(r, g, b)) continue;
      const [h, s, l] = rgbToHsl(r, g, b);
      // 服の上（赤）: 彩度が高く、色相が赤。ほっぺ（肌に囲まれたピンク）は変えない
      if (top && s >= 0.6 && (h <= 15 || h >= 340) && l > 0.2 && skinNeighbors(x, y) < 3) {
        writes.push([o, shift([r, g, b], TOP_MAIN, top)]);
        continue;
      }
      // 服の下（青いオーバーオール）
      if (bottom && h >= 190 && h <= 260 && l < 0.45 && b > r) writes.push([o, shift([r, g, b], BOTTOM_MAIN, bottom)]);
    }
  }
  for (const [o, c] of writes) {
    data[o] = c[0]; data[o + 1] = c[1]; data[o + 2] = c[2];
  }
}
