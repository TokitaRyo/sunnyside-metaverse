import Phaser from "phaser";
import { CHAR_ORIGIN_X, CHAR_ORIGIN_Y, type Look } from "@metaverse/shared";
import { sprites } from "../config";
import { charKey, humanLayers } from "./assets";
import { ensureLookTextures } from "./avatarTextures";
import { STAMP_TEX, stampFrame } from "./stampIcons";

/** かざりの位置（足元を原点にした、キャラの中の座標）。体は約11x16px、あたまの上は y=-18、手は右に +9 */
const HEAD_Y = -18;
const HAND_X = 10;
const HAND_Y = -6;
const HEAD_SCALE = 0.75;
const HAND_SCALE = 0.625;

/**
 * 1人のキャラ。人間は base + hair + tools の3枚を同座標に重ねて1つの Container にまとめる。
 * Container の (x, y) が「足元」。子スプライトは origin(0.5, 0.625) で足元に合わせる。
 */
export class Character extends Phaser.GameObjects.Container {
  readonly kind: string;
  readonly hair: string | undefined;
  private sprites: Phaser.GameObjects.Sprite[] = [];
  private layerNames: (string | null)[];
  private accHand?: Phaser.GameObjects.Image;
  /** あたまにかざりを付けている（名札を、そのぶん上に出す） */
  headAccessory = false;
  currentAction = "";
  /** 画面に出しているか（出さない間は描かず、アニメも止めて、軽くする） */
  private shown = true;
  /** リモート補間用の目標座標 */
  targetX: number;
  targetY: number;

  constructor(scene: Phaser.Scene, x: number, y: number, kind: string, hair?: string, initialAction = "idle", look?: Look | null) {
    super(scene, x, y);
    this.kind = kind;
    this.hair = hair;
    this.targetX = x;
    this.targetY = y;

    const def = sprites.characters[kind];
    // 色を変えたアバターは、色替え済みの体・髪のテクスチャを使う（tools は素材のまま）
    const lookId = kind === "human" ? ensureLookTextures(scene, look ?? null) : null;
    const layers = def.layered ? humanLayers(hair ?? def.hairOptions![0]) : [null];
    this.layerNames = lookId ? layers.map((l) => (l === "base" || l === (hair ?? "")) ? `${l}~${lookId}` : l) : layers;
    for (const layer of this.layerNames) {
      const s = scene.add.sprite(0, 0, charKey(kind, layer, initialAction));
      s.setOrigin(CHAR_ORIGIN_X, CHAR_ORIGIN_Y);
      this.sprites.push(s);
    }
    this.add(this.sprites);
    if (look) this.addAccessories(look);
    scene.add.existing(this);
    this.play(initialAction);
  }

  /** かざり（出店のスタンプの絵）。あたまの上と、手に持つもの */
  private addAccessories(look: Look): void {
    if (!this.scene.textures.exists(STAMP_TEX)) return;
    const make = (id: string | undefined, scale: number) => {
      const f = stampFrame(id);
      return f >= 0 ? this.scene.add.image(0, 0, STAMP_TEX, f).setScale(scale) : undefined;
    };
    const head = make(look.head, HEAD_SCALE)?.setOrigin(0.5, 1).setPosition(0, HEAD_Y);
    const hand = make(look.hand, HAND_SCALE)?.setOrigin(0.5, 0.5).setPosition(HAND_X, HAND_Y);
    this.accHand = hand;
    this.headAccessory = !!head;
    for (const a of [head, hand]) if (a) this.add(a);
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

  /** 出す／出さない。出さない間はアニメを止める（人が多いとき、近くの数人だけ描くため） */
  setShown(v: boolean): this {
    if (this.shown === v) return this;
    this.shown = v;
    this.setVisible(v);
    for (const s of this.sprites) {
      if (v) s.anims.resume();
      else s.anims.pause();
    }
    return this;
  }

  get isShown(): boolean {
    return this.shown;
  }

  setFlip(flipX: boolean): this {
    for (const s of this.sprites) s.setFlipX(flipX);
    // 手に持つかざりは、向いている側の手に
    if (this.accHand) this.accHand.setPosition(flipX ? -HAND_X : HAND_X, HAND_Y).setFlipX(flipX);
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
