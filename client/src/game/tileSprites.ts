import type Phaser from "phaser";
import { map, type MapSpriteDef } from "../config";
import { objectKey, tilesetKey } from "./assets";

/** タイルから組み立てる配置物の絵（map.sprites[name].tiles）をテクスチャにする。 */

/** 1つのタイルセットの任意の矩形(タイル単位)を、そのまま1枚の絵にしたものの名前 */
export const rectSpriteName = (tileset: string, tx: number, ty: number, tw: number, th: number): string => `tile:${tileset}:${tx},${ty},${tw}x${th}`;
export const prefabSpriteName = (id: string): string => `prefab:${id}`;
export const isTileSprite = (def: MapSpriteDef | undefined): boolean => !!def?.tiles;

/** タイルセット上の矩形を、足元中央を原点とする絵の定義にする */
export function rectSpriteDef(tileset: string, tx: number, ty: number, tw: number, th: number): MapSpriteDef {
  const ts = map.tilesets![tileset];
  const parts: NonNullable<MapSpriteDef["tiles"]>["parts"] = [];
  for (let r = 0; r < th; r++) {
    for (let c = 0; c < tw; c++) parts.push({ tileset, id: (ty + r) * ts.columns + tx + c, x: c * ts.tileSize, y: r * ts.tileSize });
  }
  const fw = tw * ts.tileSize, fh = th * ts.tileSize;
  return { file: "", fw, fh, frames: 1, fps: 0, ox: fw / 2, oy: fh, catalog: true, tiles: { parts } };
}

/** 画像を作って texture に登録する。すでにあれば何もしない。作れたら true */
export function buildTileSprite(textures: Phaser.Textures.TextureManager, name: string, def: MapSpriteDef): boolean {
  const key = objectKey(name);
  if (textures.exists(key)) return true;
  const recipe = def.tiles;
  if (!recipe) return false;
  const cv = document.createElement("canvas");
  cv.width = def.fw;
  cv.height = def.fh;
  const ctx = cv.getContext("2d")!;
  ctx.imageSmoothingEnabled = false;
  for (const p of recipe.parts) {
    const ts = map.tilesets?.[p.tileset];
    if (!ts || p.id < 0 || !textures.exists(tilesetKey(p.tileset))) continue;
    const img = textures.get(tilesetKey(p.tileset)).getSourceImage() as HTMLImageElement;
    ctx.drawImage(img, (p.id % ts.columns) * ts.tileSize, Math.floor(p.id / ts.columns) * ts.tileSize, ts.tileSize, ts.tileSize, p.x, p.y, ts.tileSize, ts.tileSize);
  }
  const tex = textures.addCanvas(key, cv);
  if (!tex) return false;
  // 配置物は frame 0 で作るので、スプライトシートと同じ名前(0)のフレームを足す
  tex.add(0, 0, 0, 0, def.fw, def.fh);
  return true;
}

/**
 * map.sprites のうちタイルで組み立てるものを全部テクスチャにする。
 * ゲームでは配置されているものだけ、エディタ(editing)では見本(catalog)も全部。
 */
export function buildTileSprites(textures: Phaser.Textures.TextureManager, editing: boolean): void {
  const used = new Set((map.objects ?? []).map((o) => o.sprite));
  for (const [name, def] of Object.entries(map.sprites ?? {})) {
    if (!def.tiles) continue;
    if (def.catalog && !used.has(name) && !editing) continue;
    buildTileSprite(textures, name, def);
  }
}
