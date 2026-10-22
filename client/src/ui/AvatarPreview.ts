import { HAIRS, colorKey, type Look } from "@metaverse/shared";
import { sprites } from "../config/spritesOnly";
import { recolorImageData } from "../game/avatarColors";
import { STAMP_FRAME, loadStampSheet, stampFrame } from "../game/stampIcons";

/**
 * 入室画面のアバターのプレビュー（DOM の canvas。Phaser は使わない）。
 * ゲーム中と同じ色替え（avatarColors）と、同じ位置のかざりで描き、待機（idle）のアニメを動かす。「手をふる」は doing を1回。
 * 元の絵の1コマは 96x64 だが、体は中央の約11x16pxなので、まわりを切り出して小さな canvas に描き、CSS で大きく拡大する。
 */
const FW = sprites.meta.frameWidth;
const FH = sprites.meta.frameHeight;
/** 切り出す範囲（1コマの中。体・髪・頭の上のかざり・手のかざりが入る大きさ） */
const CROP = { x: 33, y: 8, w: 30, h: 36 };
/** かざりの位置（Character.ts と同じ。足元=(48,40) を原点にした座標を、コマの座標にする） */
const ORIGIN = { x: FW * 0.5, y: FH * 0.625 };
const HEAD = { y: -18, scale: 0.75 };
const HAND = { x: 10, y: -6, scale: 0.625 };

const actionDef = (a: string) => sprites.characters.human.actions[a];
const base = `${import.meta.env.BASE_URL}assets/characters/human`;

const images = new Map<string, Promise<HTMLImageElement>>();
/** 読み込み済みの画像（描くときは同期で取り出す） */
const loaded = new Map<string, HTMLImageElement>();
function load(layer: string, action: string): Promise<HTMLImageElement> {
  const url = `${base}/${layer}/${action}.png`;
  let p = images.get(url);
  if (!p) {
    p = new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => {
        loaded.set(url, img);
        resolve(img);
      };
      img.onerror = () => reject(new Error(url));
      img.src = url;
    });
    images.set(url, p);
  }
  return p;
}

/** 色替えしたシート（canvas）のキャッシュ。色の組み合わせと層・アクションごと */
const sheets = new Map<string, HTMLCanvasElement>();
function sheet(layer: "base" | "hair" | "tools", style: string, look: Look, action: string, img: HTMLImageElement): HTMLCanvasElement {
  const name = layer === "hair" ? style : layer;
  const key = `${layer}|${name}|${layer === "base" ? [look.eyeColor, look.top, look.bottom].join() : layer === "hair" ? look.hairColor : ""}|${action}`;
  let cv = sheets.get(key);
  if (cv) return cv;
  cv = document.createElement("canvas");
  cv.width = img.width;
  cv.height = img.height;
  const ctx = cv.getContext("2d", { willReadFrequently: true })!;
  ctx.drawImage(img, 0, 0);
  if (layer !== "tools") {
    const data = ctx.getImageData(0, 0, cv.width, cv.height);
    recolorImageData(data, layer, look);
    ctx.putImageData(data, 0, 0);
  }
  sheets.set(key, cv);
  return cv;
}

export class AvatarPreview {
  private ctx: CanvasRenderingContext2D;
  private look: Look = { hair: HAIRS[0] };
  private action = "idle";
  private frame = 0;
  private timer = 0;
  private ready = false;
  private stamps: HTMLImageElement | null = null;
  private lastKey = "";

  constructor(private canvas: HTMLCanvasElement) {
    canvas.width = CROP.w;
    canvas.height = CROP.h;
    this.ctx = canvas.getContext("2d", { willReadFrequently: false })!;
    this.ctx.imageSmoothingEnabled = false;
    void this.preload();
  }

  private async preload(): Promise<void> {
    const jobs: Promise<unknown>[] = [loadStampSheet().then((i) => (this.stamps = i))];
    for (const a of ["idle", "doing"]) {
      jobs.push(load("base", a), load("tools", a));
      for (const h of HAIRS) jobs.push(load(h, a));
    }
    try {
      await Promise.all(jobs);
    } catch (e) {
      console.warn("[avatar] 読み込めない絵があります", e);
    }
    this.ready = true;
    this.lastKey = "";
    this.draw();
  }

  setLook(look: Look): void {
    this.look = look;
    this.lastKey = "";
    this.draw();
  }

  /** 手をふる（doing を1回。終わると待機に戻る） */
  wave(): void {
    this.action = "doing";
    this.frame = 0;
  }

  start(): void {
    this.stop();
    this.timer = window.setInterval(() => this.tick(), 1000 / 8);
  }

  stop(): void {
    window.clearInterval(this.timer);
    this.timer = 0;
  }

  private tick(): void {
    const def = actionDef(this.action);
    this.frame++;
    if (this.frame >= def.frames) {
      this.frame = 0;
      if (this.action !== "idle") this.action = "idle";
    }
    this.draw();
  }

  private draw(): void {
    if (!this.ready) return;
    const look = this.look;
    const key = `${colorKey(look)}|${look.head}|${look.hand}|${this.action}|${this.frame}`;
    if (key === this.lastKey) return;
    this.lastKey = key;
    const a = this.action;
    const ctx = this.ctx;
    ctx.clearRect(0, 0, CROP.w, CROP.h);
    const layers: ["base" | "hair" | "tools", string][] = [["base", "base"], ["hair", look.hair], ["tools", "tools"]];
    for (const [kind, name] of layers) {
      const img = loaded.get(`${base}/${name}/${a}.png`);
      if (!img) continue;
      const cv = sheet(kind, name, look, a, img);
      ctx.drawImage(cv, this.frame * FW + CROP.x, CROP.y, CROP.w, CROP.h, 0, 0, CROP.w, CROP.h);
    }
    // かざり（ゲーム中と同じ位置・大きさ）
    this.drawAccessory(look.head, ORIGIN.x - (STAMP_FRAME * HEAD.scale) / 2, ORIGIN.y + HEAD.y - STAMP_FRAME * HEAD.scale, HEAD.scale);
    this.drawAccessory(look.hand, ORIGIN.x + HAND.x - (STAMP_FRAME * HAND.scale) / 2, ORIGIN.y + HAND.y - (STAMP_FRAME * HAND.scale) / 2, HAND.scale);
  }

  private drawAccessory(id: string | undefined, fx: number, fy: number, scale: number): void {
    const f = stampFrame(id);
    if (f < 0 || !this.stamps) return;
    const s = STAMP_FRAME * scale;
    this.ctx.drawImage(this.stamps, f * STAMP_FRAME, 0, STAMP_FRAME, STAMP_FRAME, Math.round(fx - CROP.x), Math.round(fy - CROP.y), s, s);
  }
}
