import Phaser from "phaser";
import { CHAR_ORIGIN_X, CHAR_ORIGIN_Y } from "@metaverse/shared";
import { sprites } from "../config";
import { charKey, humanLayers } from "./assets";

/**
 * 1人のキャラ。人間は base + hair + tools の3枚を同座標に重ねて1つの Container にまとめる。
 * Container の (x, y) が「足元」。子スプライトは origin(0.5, 0.625) で足元に合わせる。
 */
export class Character extends Phaser.GameObjects.Container {
  readonly kind: string;
  readonly hair: string | undefined;
  private sprites: Phaser.GameObjects.Sprite[] = [];
  private layerNames: (string | null)[];
  currentAction = "";
  /** リモート補間用の目標座標 */
  targetX: number;
  targetY: number;

  constructor(scene: Phaser.Scene, x: number, y: number, kind: string, hair?: string, initialAction = "idle") {
    super(scene, x, y);
    this.kind = kind;
    this.hair = hair;
    this.targetX = x;
    this.targetY = y;

    const def = sprites.characters[kind];
    this.layerNames = def.layered ? humanLayers(hair ?? def.hairOptions![0]) : [null];
    for (const layer of this.layerNames) {
      const s = scene.add.sprite(0, 0, charKey(kind, layer, initialAction));
      s.setOrigin(CHAR_ORIGIN_X, CHAR_ORIGIN_Y);
      this.sprites.push(s);
    }
    this.add(this.sprites);
    scene.add.existing(this);
    this.play(initialAction);
  }

  hasAction(action: string): boolean {
    return this.scene.anims.exists(charKey(this.kind, this.layerNames[0], action));
  }

  /** 全レイヤーを同じアクションで同時に再生する（フレームを揃えるため）。 */
  play(action: string, opts: { restart?: boolean; onComplete?: () => void } = {}): this {
    if (!this.hasAction(action)) action = "idle";
    const anim = this.scene.anims.get(charKey(this.kind, this.layerNames[0], action));
    const looping = anim.repeat === -1;
    if (!opts.restart && looping && this.currentAction === action) return this;

    this.currentAction = action;
    this.layerNames.forEach((layer, i) => {
      this.sprites[i].play(charKey(this.kind, layer, action), true);
      if (opts.restart) this.sprites[i].anims.restart();
    });
    // 完了通知は先頭レイヤーだけで受ける
    this.sprites[0].off(Phaser.Animations.Events.ANIMATION_COMPLETE);
    if (opts.onComplete) this.sprites[0].once(Phaser.Animations.Events.ANIMATION_COMPLETE, opts.onComplete);
    return this;
  }

  /** 現在のアクションが「1回再生で終わるもの」か */
  isOneShotPlaying(): boolean {
    const a = this.sprites[0].anims;
    return a.isPlaying && a.currentAnim?.repeat !== -1;
  }

  setFlip(flipX: boolean): this {
    for (const s of this.sprites) s.setFlipX(flipX);
    return this;
  }

  get flipX(): boolean {
    return this.sprites[0].flipX;
  }

  /** 手前のキャラ／木が奥を隠すよう、Y座標で深度を決める（SPEC 4.4） */
  syncDepth(): void {
    this.setDepth(this.y);
  }
}
