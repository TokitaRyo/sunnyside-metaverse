import Phaser from "phaser";
import {
  EMOTES,
  FOOT_H,
  FOOT_W,
  RUN_SPEED,
  SEND_INTERVAL_MS,
  WALK_SPEED,
  type ChatBroadcast,
  type CorrectMessage,
  type EmoteBroadcast,
  type EmoteId,
  type Player,
} from "@metaverse/shared";
import { map, sprites, type ObjectDef, type TileLayerDef } from "../config";
import { TILES_KEY, elementKey, objectKey, tilesetKey } from "../game/assets";
import { Character } from "../game/Character";
import type { InputState } from "../game/InputState";
import { Network } from "../net/Network";
import { Hud } from "../ui/Hud";
import { Talk } from "../ui/Talk";

export const EV_JOINED = "joined";
export const EV_JOIN_FAILED = "join-failed";
export const EV_CONN = "conn-state";

export interface WorldInit {
  name: string;
  hair: string;
  input: InputState;
}

/**
 * 他プレイヤー補間の係数。1秒あたり「距離の 99.9% を詰める」強さ。
 * 小さいほどキビキビ(でもカクつく)、大きいほど滑らか(でも遅れる)。
 * 送信15Hz/patch20Hz に対して 0.001 で実機確認済みの落としどころ。触るなら docs/decisions.md も更新。
 */
const REMOTE_SMOOTHING = 0.001;
/** これ以上離れたら補間せず瞬間移動（入室直後・棄却復帰など） */
const REMOTE_SNAP_DIST = 96;

/** ワープのロード画面: 画面が覆われるまで(CSSのフェード)と、ロードバーが満ちるまで */
const WARP_COVER_MS = 300;
const WARP_LOAD_MS = 1100;
const WARP_TIPS = [
  "黄色い足場に乗ると、となりの島へ移動できます",
  "エモートは 1〜6 キー、チャットは Enter",
  "雲の上の島は、みんなの待ち合わせ場所",
  "Shift を押しながら動くと走れます",
];

/** NPCの足元からこの距離(px)以内に入ると「話す」が選べる。会話中にこれ+TALK_LEAVE_EXTRA 以上離れたら閉じる */
const TALK_RANGE = 40;
const TALK_LEAVE_EXTRA = 24;

const DEPTH_GROUND = -2;
const DEPTH_DECO = -1;
/** キャラや木(depth=y)より必ず手前に出す */
const DEPTH_OVERHEAD = 100000;
/** tileLayers 用: 床タイル群は最背面から順に、床の上に敷く影などはその上、キャラ(depth=y>=0)より下 */
const DEPTH_FLOOR_TILES = -20000;
const DEPTH_FLOOR_OBJECTS = -5000;
/** 最前面の雲を半透明にして、下にいる人が見えるようにする */
const TOP_LAYER_ALPHA = 0.6;

const TS = map.tileSize;
const WORLD_W = map.width * TS;
const WORLD_H = map.height * TS;

interface Remote {
  char: Character;
  /** 最新の状態上のアクション（1回再生エモートは "idle" として保持） */
  lastAction: string;
}
interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

/** 描画済みのタイル層（エディタが1マスずつ張り替えられるよう参照を持つ） */
export interface TileLayerRuntime {
  mode: TileLayerDef["mode"];
  /** このレイヤーのタイル1辺(px) */
  size: number;
  make: (data: number[][], y: number) => Phaser.Tilemaps.TilemapLayer;
  /** floor/top は key=0 の1枚、ysort は 行番号→その行の層 */
  layers: Map<number, Phaser.Tilemaps.TilemapLayer>;
}
/** 配置物1個ぶんの「データ」と「描画」 */
export interface ObjectEntry {
  o: ObjectDef;
  s: Phaser.GameObjects.Sprite;
}

export class WorldScene extends Phaser.Scene {
  private init0!: WorldInit;
  private net = new Network();
  private hud!: Hud;
  private talk?: Talk;
  /** 話しかけられる位置にいる相手（いなければ null） */
  private npcNear: ObjectEntry | null = null;
  /** 会話中の相手 */
  private npcTalking: ObjectEntry | null = null;
  private me?: Character;
  private myId = "";
  private remotes = new Map<string, Remote>();
  private mobs: Character[] = [];
  protected obstacles: Rect[] = [];
  protected tileLayerRuntime: TileLayerRuntime[] = [];
  protected objectEntries: ObjectEntry[] = [];
  private emote: { id: EmoteId } | null = null;
  private flipX = false;
  private sendAcc = 0;
  private sent = { x: NaN, y: NaN, flipX: false, action: "" };
  private lost = false;
  /** ワープのロード画面を出している間は、自分の操作・移動送信を止める */
  private warping = false;
  /** pagehide のリスナーはページ全体で1回だけ張る（マップエディタとの行き来で何度も接続しても積み重ねない） */
  private pagehideBound = false;

  constructor(key = "World") {
    super(key);
  }

  init(data?: WorldInit): void {
    this.init0 = data as WorldInit;
    this.tileLayerRuntime = [];
    this.objectEntries = [];
    this.net = new Network();
    this.remotes.clear();
    this.mobs = [];
    this.obstacles = [];
    this.me = undefined;
    this.emote = null;
    this.lost = false;
    this.warping = false;
    this.talk = undefined;
    this.npcNear = null;
    this.npcTalking = null;
    this.sent = { x: NaN, y: NaN, flipX: false, action: "" };
  }

  create(): void {
    if (map.tileLayers) {
      this.buildTileLayers();
      this.buildObjects();
    } else {
      this.buildMap();
    }
    this.buildProps();
    this.buildMobs();

    const cam = this.cameras.main;
    cam.setBackgroundColor("#1b2a1a");
    cam.setBounds(0, 0, WORLD_W, WORLD_H);
    cam.roundPixels = true;
    this.applyZoom();
    this.scale.on("resize", () => this.applyZoom());
    cam.on(Phaser.Cameras.Scene2D.Events.POST_RENDER, this.updateTags, this);

    void this.connect();
  }

  // ---------------------------------------------------------------- マップ描画
  private buildMap(): void {
    const layers: [number[][], number][] = [
      [map.layers.ground, DEPTH_GROUND],
      [map.layers.deco, DEPTH_DECO],
      [map.layers.overhead, DEPTH_OVERHEAD],
    ];
    for (const [data, depth] of layers) {
      const tm = this.make.tilemap({ data, tileWidth: TS, tileHeight: TS });
      const ts = tm.addTilesetImage(TILES_KEY, TILES_KEY, TS, TS, 0, 0)!;
      tm.createLayer(0, ts, 0, 0)!.setDepth(depth);
    }
  }

  /**
   * 任意枚数のタイル層（GameMakerルーム由来など）。
   *  floor : マップ全体を1枚の層として、キャラより下に描く
   *  ysort : 1行ずつ別の層にして depth=その行の下端Y。キャラの足元Yと比べて前後が決まる
   *          （建物の裏を歩くと隠れ、手前を歩くと重なる）
   *  top   : 最前面（雲）。プレイヤーが隠れきらないよう半透明にする
   */
  protected buildTileLayers(): void {
    map.tileLayers!.forEach((l, i) => {
      const def = map.tilesets![l.tileset];
      const key = tilesetKey(l.tileset);
      const s = def.tileSize;
      const make = (data: number[][], y: number) => {
        const tm = this.make.tilemap({ data, tileWidth: s, tileHeight: s });
        const ts = tm.addTilesetImage(key, key, s, s, 0, 0)!;
        return tm.createLayer(0, ts, 0, y)!;
      };
      const rt: TileLayerRuntime = { mode: l.mode, size: s, make, layers: new Map() };
      this.tileLayerRuntime[i] = rt;
      if (l.mode === "ysort") {
        l.data.forEach((row, ry) => {
          if (row.every((v) => v < 0)) return;
          rt.layers.set(ry, make([row], ry * s).setDepth((ry + 1) * s));
        });
      } else if (l.mode === "top") {
        rt.layers.set(0, make(l.data, 0).setDepth(DEPTH_OVERHEAD + i).setAlpha(TOP_LAYER_ALPHA));
      } else {
        rt.layers.set(0, make(l.data, 0).setDepth(DEPTH_FLOOR_TILES + i));
      }
    });
  }

  /** 配置物の前後関係。床に敷くものは最背面、それ以外は足元Y */
  protected objectDepth(o: ObjectDef): number {
    return o.sort === "floor" ? DEPTH_FLOOR_OBJECTS : o.by;
  }

  /** 配置物を1個つくる（スプライト生成・原点・拡大率・回転・アニメ）。当たり判定は obstacles に加える */
  protected spawnObject(o: ObjectDef): ObjectEntry {
    const def = map.sprites![o.sprite];
    const key = objectKey(o.sprite);
    const animated = def.frames > 1 && this.anims.exists(key);
    // 念のため 0..frames-1 に収める（負の値・範囲外でも落とさない）
    const start = animated ? (((o.frame ?? 0) % def.frames) + def.frames) % def.frames : 0;
    const s = this.add.sprite(o.x, o.y, key, start);
    s.setOrigin(def.ox / def.fw, def.oy / def.fh);
    if (o.sx !== undefined || o.sy !== undefined) s.setScale(o.sx ?? 1, o.sy ?? 1);
    if (o.angle) s.setAngle(o.angle);
    s.setDepth(this.objectDepth(o));
    if (animated) s.play({ key, frameRate: def.fps * (o.speed ?? 1), startFrame: start, repeat: -1 });
    if (o.hit) this.obstacles.push({ x: (o.hx ?? o.x) - o.hit[0] / 2, y: o.by - o.hit[1], w: o.hit[0], h: o.hit[1] });
    return { o, s };
  }

  /** 元ルームの配置物（木・動物・ゴブリン・樽・影…）。足元Yで前後判定し、hit があれば当たり判定に加える */
  protected buildObjects(): void {
    for (const o of map.objects ?? []) this.objectEntries.push(this.spawnObject(o));
  }

  private buildProps(): void {
    for (const p of map.props) {
      const def = sprites.elements[p.sprite];
      const key = elementKey(p.sprite);
      const px = p.x * TS;
      const py = p.y * TS;
      // 装飾は「タイル左上の点」に、下端中央を合わせる（demo_map_render.png と一致）
      const s = this.add.sprite(px, py, key, def.frameWidth ? 0 : undefined).setOrigin(0.5, 1).setDepth(py);
      if (def.frameWidth && this.anims.exists(key)) {
        s.play(key);
        s.anims.setProgress(Math.random()); // 木が全部同じタイミングで揺れないように
      }
      if (p.collide) {
        const w = p.hitbox?.w ?? FOOT_W;
        const h = p.hitbox?.h ?? FOOT_H;
        this.obstacles.push({ x: px - w / 2, y: py - h, w, h });
      }
    }
  }

  private buildMobs(): void {
    // モブはサーバー同期しない。全クライアントが同じ map.json を読んで同じ絵になる（SPEC 4.5）
    map.mobs.forEach((m) => {
      const x = m.x * TS;
      const y = m.y * TS;
      const c = new Character(this, x, y, m.sprite, m.hair, m.action);
      c.setFlip(!!m.flipX);
      c.syncDepth();
      this.mobs.push(c);
      this.obstacles.push({ x: x - 5, y: y - 6, w: 10, h: 6 });
    });
  }

  protected applyZoom(): void {
    const { width, height } = this.scale;
    // ピクセルアートが滲まないよう整数倍のみ。2〜3倍を基準にする（SPEC 4.4）
    const zoom = Phaser.Math.Clamp(Math.floor(Math.min(width / 320, height / 200)), 2, 3);
    this.cameras.main.setZoom(zoom);
  }

  // ---------------------------------------------------------------- 接続
  protected async connect(): Promise<void> {
    const { name, hair, input } = this.init0;
    try {
      await this.net.join(name, hair, {
        onPlayerAdd: (p, id) => this.onPlayerAdd(p, id),
        onPlayerChange: (p, id) => this.onPlayerChange(p, id),
        onPlayerRemove: (_p, id) => this.onPlayerRemove(id),
        onChat: (m) => this.onChat(m),
        onEmote: (m) => this.onEmote(m),
        onCorrect: (m) => this.onCorrect(m),
        onDrop: () => this.game.events.emit(EV_CONN, "reconnecting"),
        onReconnect: () => this.game.events.emit(EV_CONN, "ok"),
        onLost: (code) => {
          if (!this.lost) this.game.events.emit(EV_CONN, "lost", code);
        },
      });
    } catch (e) {
      console.error("[net] join failed", e);
      this.game.events.emit(EV_JOIN_FAILED, e instanceof Error ? e.message : String(e));
      this.scene.stop();
      return;
    }
    // 接続が終わる前に（マップエディタへの切り替えなどで）シーンが止められていたら、
    // 静かに退室するだけにする。HUDは作らない（片付け対象が増えるだけなので）。
    if (!this.scene.isActive()) {
      this.net.leave();
      return;
    }
    this.myId = this.net.sessionId;
    this.hud = new Hud(input, {
      onSend: (text) => this.net.sendChat(text),
      onEmote: (id) => this.triggerEmote(id),
    });
    this.talk = new Talk({ onPrompt: () => this.onTalkKey(), onAdvance: () => this.onTalkKey() });
    input.onAction = () => this.onTalkKey();
    input.onEscape = () => this.endTalk();
    // タブを閉じたら即座にキャラを消す（consented leave。しないと再接続待ちの間ゴーストが残る）。
    // ページで1回だけ張る（マップエディタと行き来して何度も接続しても、閉じるときに1回leaveすれば十分）
    if (!this.pagehideBound) {
      this.pagehideBound = true;
      window.addEventListener("pagehide", () => {
        this.lost = true;
        this.net.leave();
      });
    }
    // マップエディタへの切り替えなどでシーンが止まったら、自分を退室させてHUDを片付ける。
    // 各シーン停止のたびに1回だけ発火する（Phaserのシーン内イベントなので、rejoinごとに張り直しても積み重ならない）。
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      if (!this.lost) {
        this.lost = true;
        this.net.leave();
      }
      this.endTalk();
      input.onAction = undefined;
      input.onEscape = undefined;
      document.getElementById("hud")!.hidden = true;
      document.getElementById("labels")!.replaceChildren();
    });
    // 参加直後に届いていた自分の onAdd はHUD生成前に処理済みなので、ここで名札を補う
    this.attachSelfTagIfNeeded();
    this.game.events.emit(EV_JOINED);
  }

  private attachSelfTagIfNeeded(): void {
    if (this.me) this.hud.addTag(this.myId, this.nameOf(this.myId), "self");
    for (const id of this.remotes.keys()) this.hud.addTag(id, this.nameOf(id), "peer");
    this.mobs.forEach((c, i) => {
      const name = map.mobs[i].name;
      if (name) this.hud.addTag(`mob:${i}`, name, "mob");
    });
    // 話しかけられる物には 💬 の目印（名前があれば名前も）。位置は動かないので1回だけ置く
    this.objectEntries.forEach((e, i) => {
      if (!e.o.npc) return;
      this.hud.addTag(`npc:${i}`, `💬${e.o.npc.name ? " " + e.o.npc.name : ""}`, "mob");
    });
  }

  // ---------------------------------------------------------------- NPCと会話
  private npcEntries(): ObjectEntry[] {
    return this.objectEntries.filter((e) => e.o.npc);
  }

  /** 足元 (x,y) から TALK_RANGE 以内で一番近いNPC */
  private nearestNpc(x: number, y: number): ObjectEntry | null {
    let best: ObjectEntry | null = null;
    let bestD = TALK_RANGE;
    for (const e of this.npcEntries()) {
      const d = Math.hypot(x - e.o.x, y - e.o.by);
      if (d <= bestD) {
        best = e;
        bestD = d;
      }
    }
    return best;
  }

  /** E / Space / 「話す」ボタン / 会話ウィンドウのクリック */
  private onTalkKey(): void {
    if (!this.scene.isActive() || !this.me || !this.talk || this.warping) return;
    if (this.npcTalking) {
      this.talk.advance();
      if (!this.talk.isOpen) this.npcTalking = null;
    } else if (this.npcNear?.o.npc) {
      this.npcTalking = this.npcNear;
      this.init0.input.clear();
      this.talk.open(this.npcNear.o.npc);
    }
  }

  private endTalk(): void {
    this.npcTalking = null;
    this.talk?.close();
  }

  /** 毎フレーム: 近くのNPCを探して「話す」ボタンを出し、会話中に離れすぎたら閉じる */
  private updateTalk(): void {
    const me = this.me;
    if (!me || !this.talk) return;
    if (this.npcTalking) {
      const o = this.npcTalking.o;
      if (Math.hypot(me.x - o.x, me.y - o.by) > TALK_RANGE + TALK_LEAVE_EXTRA) this.endTalk();
      return;
    }
    this.npcNear = this.nearestNpc(me.x, me.y);
    this.talk.setPrompt(this.npcNear ? (this.npcNear.o.npc!.name ?? "") : null);
  }

  private nameOf(id: string): string {
    return this.net.room.state.players.get(id)?.name ?? "";
  }

  // ---------------------------------------------------------------- 状態同期
  private onPlayerAdd(p: Player, id: string): void {
    if (id === this.net.room.sessionId) {
      this.myId = id;
      this.me = new Character(this, p.x, p.y, "human", p.hair);
      this.flipX = p.flipX;
      this.me.setFlip(this.flipX);
      this.cameras.main.startFollow(this.me, true, 0.2, 0.2);
      this.cameras.main.centerOn(p.x, p.y);
      this.hud?.addTag(id, p.name, "self");
      return;
    }
    const char = new Character(this, p.x, p.y, "human", p.hair);
    char.setFlip(p.flipX);
    const r: Remote = { char, lastAction: "idle" };
    this.remotes.set(id, r);
    this.applyRemoteAction(r, p.action);
    this.hud?.addTag(id, p.name, "peer");
  }

  private onPlayerChange(p: Player, id: string): void {
    if (id === this.myId) return; // 自分はサーバー座標で上書きしない（ガタつきの原因）
    const r = this.remotes.get(id);
    if (!r) return;
    r.char.targetX = p.x;
    r.char.targetY = p.y;
    if (r.char.flipX !== p.flipX) r.char.setFlip(p.flipX);
    this.applyRemoteAction(r, p.action);
  }

  private onPlayerRemove(id: string): void {
    const r = this.remotes.get(id);
    if (!r) return;
    r.char.destroy();
    this.remotes.delete(id);
    this.hud?.removeTag(id);
  }

  /**
   * state.action を見た目に反映する。
   * 1回再生のエモートは "emote" メッセージ側で再生する（同じエモートの連続でも state は変化しないため）。
   */
  private applyRemoteAction(r: Remote, action: string): void {
    const emote = EMOTES[action as EmoteId];
    if (action === "idle" || action === "walk" || action === "run") {
      r.lastAction = action;
      // 再生中のエモートは最後まで見せる。ただし歩き出したら即キャンセル
      if (action === "idle" && r.char.isOneShotPlaying()) return;
      r.char.play(action);
    } else if (emote?.loop) {
      r.lastAction = action;
      r.char.play(emote.action);
    } else {
      r.lastAction = "idle";
    }
  }

  private onEmote(m: EmoteBroadcast): void {
    const r = this.remotes.get(m.sessionId);
    const def = EMOTES[m.id];
    if (!r || !def) return;
    if (def.loop) {
      r.lastAction = m.id;
      r.char.play(def.action, { restart: true });
    } else {
      r.char.play(def.action, {
        restart: true,
        onComplete: () => {
          const back = EMOTES[r.lastAction as EmoteId]?.action ?? r.lastAction;
          r.char.play(back || "idle");
        },
      });
    }
  }

  private onChat(m: ChatBroadcast): void {
    const self = m.sessionId === this.myId;
    this.hud.addChatLine(m.name, m.text, self);
    this.hud.showBubble(m.sessionId, m.text);
  }

  private onCorrect(m: CorrectMessage): void {
    if (!this.me) return;
    if (m.warp) {
      this.playWarp(m.x, m.y);
      return;
    }
    // ワープ中は操作を止めているが、ワープ直前に送った移動が棄却されて補正が届くことがある。ロード画面が出ている間は無視する
    if (this.warping) return;
    this.me.setPosition(m.x, m.y);
    this.sent.x = m.x;
    this.sent.y = m.y;
  }

  /**
   * ワープ演出: ロード画面(#warp-fade)で覆い、読み込み中のように少し待ってから瞬間移動し、画面を戻す。
   * サーバーは受け取った時点でもう移動先に動かしているので、待っている間に自分が動いて棄却されないよう操作は止める。
   */
  private playWarp(x: number, y: number): void {
    if (this.warping) return;
    this.warping = true;
    this.endTalk();
    this.talk?.setPrompt(null);
    this.init0.input.clear();
    this.me?.play("idle");
    const fade = document.getElementById("warp-fade");
    const tip = document.getElementById("wl-tip");
    if (tip) tip.textContent = WARP_TIPS[Math.floor(Math.random() * WARP_TIPS.length)];
    fade?.style.setProperty("--wl-ms", `${WARP_LOAD_MS}ms`);
    fade?.classList.add("on");
    window.setTimeout(() => {
      if (this.me) {
        this.me.setPosition(x, y);
        this.sent.x = x;
        this.sent.y = y;
        this.cameras.main.centerOn(x, y); // startFollow のlerpだと1フレーム分ズレるので、瞬間移動に合わせて中心も合わせ直す
      }
      fade?.classList.remove("on");
      window.setTimeout(() => (this.warping = false), 300); // フェードが戻りきってから操作を再開
    }, WARP_COVER_MS + WARP_LOAD_MS);
  }

  // ---------------------------------------------------------------- エモート（自分）
  private triggerEmote(id: EmoteId): void {
    if (!this.me) return;
    const def = EMOTES[id];
    if (def.loop && this.emote?.id === id) {
      this.endEmote(); // 座る＝トグル。もう一度押すと解除
      return;
    }
    this.emote = { id };
    this.me.play(def.action, {
      restart: true,
      onComplete: def.loop
        ? undefined
        : () => {
            if (this.emote?.id === id) this.endEmote();
          },
    });
    this.hud.setEmoteOn("sit", id === "sit");
    this.net.sendEmote(id);
  }

  private endEmote(): void {
    this.emote = null;
    this.hud.setEmoteOn("sit", false);
  }

  // ---------------------------------------------------------------- 毎フレーム
  update(_time: number, delta: number): void {
    const dt = Math.min(delta / 1000, 0.05);

    // 他プレイヤー: 受信座標を目標値にして毎フレーム近づける（フレームレート非依存）
    const t = 1 - Math.pow(REMOTE_SMOOTHING, dt);
    for (const { char } of this.remotes.values()) {
      if (Math.hypot(char.targetX - char.x, char.targetY - char.y) > REMOTE_SNAP_DIST) {
        char.setPosition(char.targetX, char.targetY);
      } else {
        char.x += (char.targetX - char.x) * t;
        char.y += (char.targetY - char.y) * t;
      }
      char.syncDepth();
    }

    if (this.me && this.hud && !this.warping) this.updateLocal(dt, delta);
  }

  private updateLocal(dt: number, deltaMs: number): void {
    const me = this.me!;
    const input = this.init0.input;
    this.updateTalk();
    // 会話中はその場で立ち止まる
    const v = this.npcTalking ? { x: 0, y: 0 } : input.vector;
    const moving = v.x !== 0 || v.y !== 0;

    // 移動入力でエモートは即キャンセル
    if (moving && this.emote) this.endEmote();

    let loco: "idle" | "walk" | "run" = "idle";
    if (moving && !this.emote) {
      const len = Math.hypot(v.x, v.y);
      const running = input.run;
      const speed = (running ? RUN_SPEED : WALK_SPEED) * dt;
      const dx = (v.x / len) * speed;
      const dy = (v.y / len) * speed;
      // 軸ごとに判定して壁沿いに滑らせる。万一すでに埋まっている場合は判定を外して抜け出せるようにする
      const stuck = this.blocked(me.x, me.y);
      if (stuck || !this.blocked(me.x + dx, me.y)) me.x += dx;
      if (stuck || !this.blocked(me.x, me.y + dy)) me.y += dy;
      // 向きは左右のみ。上下移動では変えない（SPEC 3.3）
      if (v.x < 0) this.flipX = true;
      else if (v.x > 0) this.flipX = false;
      loco = running ? "run" : "walk";
    }

    if (me.flipX !== this.flipX) me.setFlip(this.flipX);
    if (!this.emote && me.currentAction !== loco) me.play(loco);
    me.syncDepth();

    // 送信は 15Hz、しかも値が変わったときだけ（SPEC 4.3）
    this.sendAcc += deltaMs;
    if (this.sendAcc >= SEND_INTERVAL_MS) {
      this.sendAcc %= SEND_INTERVAL_MS;
      const action = this.emote ? this.emote.id : loco;
      const x = Math.round(me.x * 10) / 10;
      const y = Math.round(me.y * 10) / 10;
      const s = this.sent;
      if (x !== s.x || y !== s.y || this.flipX !== s.flipX || action !== s.action) {
        this.net.sendMove({ x, y, flipX: this.flipX, action });
        this.sent = { x, y, flipX: this.flipX, action };
      }
    }
  }

  /** 足元 12×8 の判定。タイルの collision と props/モブの矩形に当たるか。 */
  private blocked(cx: number, cy: number): boolean {
    const l = cx - FOOT_W / 2;
    const r = cx + FOOT_W / 2;
    const t = cy - FOOT_H;
    const b = cy;
    if (l < 0 || t < 0 || r > WORLD_W || b > WORLD_H) return true;

    const c0 = Math.floor(l / TS);
    const c1 = Math.floor((r - 0.001) / TS);
    const r0 = Math.floor(t / TS);
    const r1 = Math.floor((b - 0.001) / TS);
    for (let row = r0; row <= r1; row++) {
      for (let col = c0; col <= c1; col++) {
        if (map.layers.collision[row]?.[col] === 1) return true;
      }
    }
    for (const o of this.obstacles) {
      if (l < o.x + o.w && r > o.x && t < o.y + o.h && b > o.y) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------- DOMラベル追従
  /** カメラ描画直後に呼ばれる（worldView が最新なので名札が1フレーム遅れない） */
  private updateTags(): void {
    if (!this.hud) return;
    const cam = this.cameras.main;
    const wv = cam.worldView;
    const z = cam.zoom;
    const HEAD = 20; // 足元から頭上までのワールドpx
    const place = (id: string, x: number, y: number) => {
      const sx = (x - wv.x) * z;
      const sy = (y - HEAD - wv.y) * z;
      this.hud.moveTag(id, sx, sy);
    };
    if (this.me) place(this.myId, this.me.x, this.me.y);
    for (const [id, r] of this.remotes) place(id, r.char.x, r.char.y);
    this.mobs.forEach((c, i) => place(`mob:${i}`, c.x, c.y));
    this.objectEntries.forEach((e, i) => {
      if (e.o.npc) place(`npc:${i}`, e.o.x, e.o.by);
    });
  }
}
