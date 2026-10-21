import type Phaser from "phaser";
import { colorKey, hasCustomColors, type Look } from "@metaverse/shared";
import { sprites } from "../config";
import { charKey, playerActions } from "./assets";
import { recolorImageData } from "./avatarColors";

const FW = sprites.meta.frameWidth;
const FH = sprites.meta.frameHeight;

/**
 * 色を変えたアバターのテクスチャを作る（体の層と髪の層。プレイヤーが使う全アクションぶん）。
 * 同じ色の組み合わせは1度だけ作って共有する。作ったキーは `${層}~${id}`（例 "base~longhair_ff8aa8_-_-_-"）で、
 * charKey("human", その名前, アクション) がテクスチャ・アニメのキーになる。
 * 色が無ければ何も作らず null（素材のままの絵を使う）。
 */
export function ensureLookTextures(scene: Phaser.Scene, look: Look | null): string | null {
  if (!look || !hasCustomColors(look)) return null;
  const id = colorKey(look);
  const done = `look:${id}`;
  if (scene.registry.get(done)) return id;
  const human = sprites.characters.human;
  const layers: [string, "base" | "hair"][] = [
    ["base", "base"],
    [look.hair, "hair"],
  ];
  for (const action of playerActions()) {
    const def = human.actions[action];
    if (!def) continue;
    for (const [layer, kind] of layers) {
      const src = charKey("human", layer, action);
      const dst = charKey("human", `${layer}~${id}`, action);
      if (!scene.textures.exists(src) || scene.textures.exists(dst)) continue;
      const img = scene.textures.get(src).getSourceImage() as HTMLImageElement | HTMLCanvasElement;
      const cv = document.createElement("canvas");
      cv.width = img.width;
      cv.height = img.height;
      const ctx = cv.getContext("2d", { willReadFrequently: true })!;
      ctx.drawImage(img, 0, 0);
      const data = ctx.getImageData(0, 0, cv.width, cv.height);
      recolorImageData(data, kind, look);
      ctx.putImageData(data, 0, 0);
      const tex = scene.textures.addCanvas(dst, cv)!;
      const n = Math.floor(cv.width / FW);
      for (let i = 0; i < n; i++) tex.add(i, 0, i * FW, 0, FW, FH);
      if (!scene.anims.exists(dst)) {
        scene.anims.create({
          key: dst,
          frames: scene.anims.generateFrameNumbers(dst, { start: 0, end: def.frames - 1 }),
          frameRate: def.frameRate,
          repeat: def.repeat,
        });
      }
    }
  }
  scene.registry.set(done, true);
  return id;
}
