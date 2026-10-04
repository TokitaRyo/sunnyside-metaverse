import Phaser from "phaser";
import { createAnimations, queueAssets } from "../game/assets";
import { buildTileSprites } from "../game/tileSprites";

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
    this.load.on("loaderror", (file: Phaser.Loader.File) => failed.push(file.url as string));
    this.load.on("complete", () => {
      if (failed.length) {
        console.error("[assets] 読み込みに失敗:", failed);
        this.game.events.emit(EV_LOAD_ERROR, failed);
      }
    });
    queueAssets(this.load);
  }

  create(): void {
    buildTileSprites(this.textures, import.meta.env.DEV && new URLSearchParams(location.search).has("edit"));
    createAnimations(this);
    this.game.events.emit(EV_READY);
  }
}
