import type Phaser from "phaser";

/**
 * 出店ごとのスタンプの絵柄（16x16のドット絵を横一列に並べた1枚の画像 client/public/brand/stamps/stamps.png）。
 * 並び順 = STAMP_ICON_IDS の順（scripts/gen-stamp-icons.ps1 と同じ順にする）。KeyItemDef.icon にこの id を入れる。
 * 画像が無い・id が無いときは、従来の星にする。
 */
export const STAMP_ICON_IDS = [
  "okonomiyaki",
  "taiyaki",
  "cafe",
  "chocobanana",
  "takoyaki",
  "shateki",
  "suisougaku",
  "sadokado",
  "aburasoba",
  "wataame",
  "potato",
  "casino",
  "obakeyashiki",
  "programming",
  "science",
  "library",
  "handmade",
] as const;

export const STAMP_TEX = "stamp-icons";
export const STAMP_FRAME = 16;

/** その id のフレーム番号。無ければ -1 */
export function stampFrame(icon?: string): number {
  return icon ? (STAMP_ICON_IDS as readonly string[]).indexOf(icon) : -1;
}

/** Phaser のローダーに、スタンプの絵柄のシートを積む（パスは素材のフォルダ assets/ からの相対） */
export function queueStampIcons(load: Phaser.Loader.LoaderPlugin): void {
  load.spritesheet(STAMP_TEX, "../brand/stamps/stamps.png", { frameWidth: STAMP_FRAME, frameHeight: STAMP_FRAME });
}

// ---------------------------------------------------------------- DOM（スタンプカード・通知）で使う画像
let sheet: Promise<HTMLImageElement | null> | null = null;
let sheetImg: HTMLImageElement | null = null;

/** シート画像を読み込む（失敗したら null）。読み込めたら onLoad を呼べるよう、Promise を返す */
export function loadStampSheet(): Promise<HTMLImageElement | null> {
  sheet ??= new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      sheetImg = img;
      resolve(img);
    };
    img.onerror = () => resolve(null);
    img.src = `${import.meta.env.BASE_URL}brand/stamps/stamps.png`;
  });
  return sheet;
}

const urlCache = new Map<string, string>();

/**
 * フレーム番号の絵を scale 倍の画像(data URL)にする。dim=true は、まだ取っていない枠用のうす暗い版（色を落とした影絵）。
 * シートがまだ読み込めていなければ ""。
 */
export function stampIconUrl(frame: number, scale: number, dim = false): string {
  if (!sheetImg || frame < 0) return "";
  const key = `${frame}:${scale}:${dim}`;
  const hit = urlCache.get(key);
  if (hit) return hit;
  const S = STAMP_FRAME;
  const cv = document.createElement("canvas");
  cv.width = S * scale;
  cv.height = S * scale;
  const ctx = cv.getContext("2d")!;
  ctx.imageSmoothingEnabled = false;
  ctx.drawImage(sheetImg, frame * S, 0, S, S, 0, 0, cv.width, cv.height);
  if (dim) {
    const data = ctx.getImageData(0, 0, cv.width, cv.height);
    for (let i = 0; i < data.data.length; i += 4) {
      const lum = data.data[i] * 0.3 + data.data[i + 1] * 0.59 + data.data[i + 2] * 0.11;
      const g = Math.round(150 + lum * 0.28);
      data.data[i] = data.data[i + 1] = data.data[i + 2] = g;
    }
    ctx.putImageData(data, 0, 0);
  }
  const url = cv.toDataURL();
  urlCache.set(key, url);
  return url;
}
