import type Phaser from "phaser";

/** キーアイテム／スタンプの星（13×13のドット絵）。o=縁 y=金 h=ハイライト */
const ROWS = [
  "......o......",
  ".....oyo.....",
  ".....oyo.....",
  "....oyhyo....",
  "oooooyhyooooo",
  "oyyyyyhyyyyyo",
  ".oyyyyhyyyyo.",
  "..oyyyyyyyo..",
  "..oyyyyyyyo..",
  ".oyyyoooyyyo.",
  ".oyyoo.ooyyo.",
  ".oyo.....oyo.",
  "..o.......o..",
];
const COLORS: Record<string, string> = { o: "#7a4a12", y: "#ffd23f", h: "#fff6b0" };

export const STAR_TEX = "keyitem-star";
export const STAR_SIZE = 13;

function draw(scale: number, dim = false): HTMLCanvasElement {
  const cv = document.createElement("canvas");
  cv.width = STAR_SIZE * scale;
  cv.height = STAR_SIZE * scale;
  const ctx = cv.getContext("2d")!;
  ROWS.forEach((row, y) => {
    [...row].forEach((c, x) => {
      const col = COLORS[c];
      if (!col) return;
      ctx.fillStyle = dim ? (c === "o" ? "#8a8f8a" : "#c9cdc6") : col;
      ctx.fillRect(x * scale, y * scale, scale, scale);
    });
  });
  return cv;
}

/** Phaser のテクスチャを（なければ）作る */
export function ensureStarTexture(textures: Phaser.Textures.TextureManager): void {
  if (textures.exists(STAR_TEX)) return;
  textures.addCanvas(STAR_TEX, draw(1));
}

/** スタンプカードで使う画像(data URL)。dim=未取得のうすい星 */
export function starDataUrl(scale: number, dim = false): string {
  return draw(scale, dim).toDataURL();
}
