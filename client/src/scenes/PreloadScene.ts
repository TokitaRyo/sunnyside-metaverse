import Phaser from "phaser";
import { ASSET_BASE, createAnimations, queueAssets, registerAtlasFrames, setAtlas, type AtlasManifest } from "../game/assets";
import { buildCropSprites } from "../game/cropSprites";
import { withBuild } from "../pwa";

export const EV_PROGRESS = "assets-progress";
export const EV_READY = "assets-ready";
export const EV_LOAD_ERROR = "assets-error";

/** 素材の読み込み。進捗は入室画面(DOM)のバーに反映される。 */
export class PreloadScene extends Phaser.Scene {
  constructor() {
    super("Preload");
  }

  preload(): void {
    const failed: string[] = [];
    this.load.on("progress", (v: number) => this.game.events.emit(EV_PROGRESS, v));
    const MANIFEST = "atlas-manifest";
    this.load.on("loaderror", (file: Phaser.Loader.File) => {
      if (file.key === MANIFEST) return; // アトラスが無いのは異常ではない（1枚ずつ読み込む）
      failed.push(file.url as string);
    });
    this.load.on("complete", () => {
      if (failed.length) {
        console.error("[assets] 読み込みに失敗:", failed);
        this.game.events.emit(EV_LOAD_ERROR, failed);
      }
    });
    // 本番ビルドでは、まずアトラスの目録(manifest.json)を読み、あればそれを使って素材を読み込む。無ければ今までどおり。
    // 開発中(npm run dev)とマップエディタでは、アトラスは使わない（エディタが1枚ずつのテクスチャを前提にしているため）
    if (import.meta.env.PROD) {
      this.load.setPath(ASSET_BASE);
      this.load.json(MANIFEST, withBuild("../atlas/manifest.json"));
      let queued = false;
      const go = (m: AtlasManifest | null) => {
        if (queued) return;
        queued = true;
        setAtlas(m);
        queueAssets(this.load);
      };
      this.load.once(`filecomplete-json-${MANIFEST}`, (_k: string, _t: string, data: AtlasManifest) => go(data));
      this.load.on("loaderror", (file: Phaser.Loader.File) => {
        if (file.key === MANIFEST) go(null);
      });
    } else {
      queueAssets(this.load);
    }
  }

  create(): void {
    registerAtlasFrames(this.textures);
    buildCropSprites(this.textures, import.meta.env.DEV && new URLSearchParams(location.search).has("edit"));
    createAnimations(this);
    this.game.events.emit(EV_READY);
  }
}
