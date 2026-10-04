import type Phaser from "phaser";
import { map, type MapSpriteDef } from "../config";
import { objectKey, tilesetKey } from "./assets";

/** タイルセット画像の一部（px）を切り出した配置物の絵（map.sprites[name].crop）をテクスチャにする。 */

export interface CropRect {
  tileset: string;
  x: number;
  y: number;
  w: number;
  h: number;
}

export const cropSpriteName = (c: CropRect): string => `crop:${c.tileset}:${c.x},${c.y},${c.w}x${c.h}`;

/** 切り出しの定義。原点は足元中央（木や置物の足元を、クリックした位置に合わせる） */
export function cropSpriteDef(c: CropRect): MapSpriteDef {
  return { file: "", fw: c.w, fh: c.h, frames: 1, fps: 0, ox: c.w / 2, oy: c.h, catalog: true, crop: { ...c } };
}

/** テクスチャを作って登録する。すでにあれば何もしない。使える状態になったら true */
export function buildCropSprite(textures: Phaser.Textures.TextureManager, name: string, def: MapSpriteDef): boolean {
  const key = objectKey(name);
  if (textures.exists(key)) return true;
  const c = def.crop;
  if (!c || !map.tilesets?.[c.tileset] || !textures.exists(tilesetKey(c.tileset))) return false;
  const cv = document.createElement("canvas");
  cv.width = def.fw;
  cv.height = def.fh;
  const ctx = cv.getContext("2d")!;
  ctx.imageSmoothingEnabled = false;
  ctx.drawImage(textures.get(tilesetKey(c.tileset)).getSourceImage() as HTMLImageElement, c.x, c.y, c.w, c.h, 0, 0, def.fw, def.fh);
  const tex = textures.addCanvas(key, cv);
  if (!tex) return false;
  // 配置物は frame 0 で作るので、スプライトシートと同じ名前(0)のフレームを足す
  tex.add(0, 0, 0, 0, def.fw, def.fh);
  return true;
}

/** map.sprites のうち切り出しの絵を全部テクスチャにする。ゲームでは配置されているものだけ、エディタ(editing)では見本も全部 */
export function buildCropSprites(textures: Phaser.Textures.TextureManager, editing: boolean): void {
  const used = new Set((map.objects ?? []).map((o) => o.sprite));
  for (const [name, def] of Object.entries(map.sprites ?? {})) {
    if (!def.crop) continue;
    if (def.catalog && !used.has(name) && !editing) continue;
    buildCropSprite(textures, name, def);
  }
}
