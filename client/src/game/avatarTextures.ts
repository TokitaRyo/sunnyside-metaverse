import type Phaser from "phaser";
import { colorKey, hasCustomColors, type Look } from "@metaverse/shared";
import { sprites } from "../config";
import { charKey, playerActions } from "./assets";
import { recolorImageData } from "./avatarColors";

const FW = sprites.meta.frameWidth;
const FH = sprites.meta.frameHeight;

/** 入室した直後から必ず要る動き。これだけを先に作る（残りのエモートなどは、使うときに作る） */
const BASE_ACTIONS = ["idle", "walk", "run"];
/** 使っていない（だれの画面にも出ていない）色替えテクスチャを、とっておく数。これを超えたら、古いものから捨てる */
const IDLE_CACHE_MAX = 20;

interface LookEntry {
  look: Look;
  /** この色の組み合わせを使っているキャラの数 */
  refs: number;
  /** 最後に使い終わった時刻（古いものから捨てる） */
  last: number;
  /** 作った (アクション)。捨てるときに、全部消す */
  built: Set<string>;
}

/** 色の組み合わせ（colorKey）ごとの、作ったテクスチャの記録。ゲーム全体で1つ（registry に持つ） */
function entries(scene: Phaser.Scene): Map<string, LookEntry> {
  let m = scene.registry.get("look-entries") as Map<string, LookEntry> | undefined;
  if (!m) {
    m = new Map();
    scene.registry.set("look-entries", m);
  }
  return m;
}

const layersOf = (look: Look): [string, "base" | "hair"][] => [
  ["base", "base"],
  [look.hair, "hair"],
];

/** 1つの動きぶんの、体と髪の色替えテクスチャ・アニメを作る（すでにあれば何もしない） */
function buildAction(scene: Phaser.Scene, look: Look, id: string, action: string, e: LookEntry): void {
  if (e.built.has(action)) return;
  const def = sprites.characters.human.actions[action];
  if (!def) return;
  for (const [layer, kind] of layersOf(look)) {
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
  e.built.add(action);
}

/**
 * 色を変えたアバターのテクスチャを作る（体の層と髪の層）。同じ色の組み合わせは1度だけ作って共有する。
 * 作るのは、立つ・歩く・走るだけ。エモートなどの動きは、使うとき（ensureLookAction）に作る。
 * 100人以上いても、画面に出している数人ぶんだけを持ち、使わなくなったものは古い順に捨てる（メモリを増やさないため）。
 * 作ったキーは `${層}~${id}`（例 "base~longhair_ff8aa8_-_-_-"）で、charKey("human", その名前, アクション) がテクスチャ・アニメのキー。
 * 色が無ければ何も作らず null（素材のままの絵を使う）。
 */
export function ensureLookTextures(scene: Phaser.Scene, look: Look | null): string | null {
  if (!look || !hasCustomColors(look)) return null;
  const id = colorKey(look);
  const map = entries(scene);
  let e = map.get(id);
  if (!e) {
    e = { look, refs: 0, last: performance.now(), built: new Set() };
    map.set(id, e);
  }
  for (const action of BASE_ACTIONS) buildAction(scene, look, id, action, e);
  return id;
}

/** その動きの色替えテクスチャが無ければ作る（エモート・ジャンプなど、初めて使うとき） */
export function ensureLookAction(scene: Phaser.Scene, look: Look, action: string): void {
  if (!playerActions().includes(action)) return;
  if (!hasCustomColors(look)) return;
  const id = colorKey(look);
  const e = entries(scene).get(id);
  if (e) buildAction(scene, look, id, action, e);
}

/** このキャラが、その色のテクスチャを使い始めた */
export function retainLook(scene: Phaser.Scene, id: string): void {
  const e = entries(scene).get(id);
  if (e) e.refs++;
}

/** このキャラが消えた。使う人がいなくなった色は、とっておく数を超えたぶんを古い順に捨てる */
export function releaseLook(scene: Phaser.Scene, id: string): void {
  const map = entries(scene);
  const e = map.get(id);
  if (!e) return;
  e.refs = Math.max(0, e.refs - 1);
  if (e.refs > 0) return;
  e.last = performance.now();
  const idle = [...map].filter(([, v]) => v.refs === 0).sort((a, b) => a[1].last - b[1].last);
  for (const [key, v] of idle.slice(0, Math.max(0, idle.length - IDLE_CACHE_MAX))) {
    for (const action of v.built) {
      for (const [layer] of layersOf(v.look)) {
        const dst = charKey("human", `${layer}~${key}`, action);
        if (scene.anims.exists(dst)) scene.anims.remove(dst);
        if (scene.textures.exists(dst)) scene.textures.remove(dst);
      }
    }
    map.delete(key);
  }
}
