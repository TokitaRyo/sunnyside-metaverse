import Phaser from "phaser";
import { EMOTES, emoteBubble, type ChatBroadcast, type EmoteBroadcast, type EmoteId, type Player } from "@metaverse/shared";
import { map } from "../config";
import { Network } from "../net/Network";
import { WorldScene, type Remote } from "../scenes/WorldScene";

/** 接続の状態（true=つながっている）。ショー画面（show/main.ts）が受けて表示を変える */
export const EV_SPECTATE = "spectate-state";

const WORLD_W = map.width * map.tileSize;
const WORLD_H = map.height * map.tileSize;
/** キャラや木(depth=y)より必ず手前に出す（WorldScene の DEPTH_OVERHEAD と同じ値） */
const DEPTH_TOP = 100000;
const FONT = '"Hiragino Sans","Noto Sans JP","Yu Gothic UI",Meiryo,sans-serif';
const BUBBLE_MS = 6000;
const RETRY_MS = 3000;

interface Label {
  name: Phaser.GameObjects.Text;
  bubble?: Phaser.GameObjects.Text;
  bubbleUntil: number;
}

/**
 * 管理者のショー画面用の「観客」シーン。ゲームの部屋に見るだけの立場でつなぎ（プレイヤーとしては出ない）、
 * 選んだ1人のキャラをカメラで追いかける。ゲーム本体の WorldScene と同じ地図・同じ描画を使うので、見た目は遊んでいる画面そのもの。
 * 全員の位置が届くので、追っている人の近くにいる人も、ふつうに動いて見える。
 */
export class SpectatorScene extends WorldScene {
  private target = "";
  private labels = new Map<string, Label>();
  private transition?: Phaser.Tweens.Tween;
  private moving = false;
  private stopped = false;

  constructor() {
    super("Spectate");
  }

  // ---------------------------------------------------------------- 外から使う操作
  /** この人を追いかける（null なら、島ぜんぶが見える引きの映像）。遠いときは、いったん引いてから寄る */
  follow(sid: string | null): void {
    this.target = sid ?? "";
    const r = this.remotes.get(this.target);
    if (r) this.flyTo(r);
    else this.overview();
  }

  /** いま追っている人がいるか（つながり直した直後など、まだ届いていない間は false） */
  get hasTarget(): boolean {
    return this.remotes.has(this.target);
  }

  // ---------------------------------------------------------------- ズーム・カメラ
  /** ピクセルが滲まない整数倍。画面（このシーンの表示領域）に合わせて 2〜5倍 */
  private watchZoom(): number {
    const { width, height } = this.scale;
    return Phaser.Math.Clamp(Math.floor(Math.min(width / 300, height / 190)), 2, 5);
  }

  protected override applyZoom(): void {
    if (this.moving) return;
    const cam = this.cameras.main;
    if (this.hasTarget) cam.setZoom(this.watchZoom());
    else this.overview();
  }

  /** 島ぜんたいを映す（だれも追っていないとき） */
  private overview(): void {
    this.transition?.stop();
    this.moving = false;
    const cam = this.cameras.main;
    cam.stopFollow();
    cam.removeBounds();
    const { width, height } = this.scale;
    cam.setZoom(Math.min(width / WORLD_W, height / WORLD_H) * 0.96);
    cam.centerOn(WORLD_W / 2, WORLD_H / 2);
  }

  private flyTo(r: Remote): void {
    this.transition?.stop();
    const cam = this.cameras.main;
    const char = r.char;
    const from = { x: cam.midPoint.x, y: cam.midPoint.y, z: cam.zoom };
    const z1 = this.watchZoom();
    const dist = Math.hypot(char.x - from.x, char.y - from.y);
    // 近ければ、そのまま滑らせる。遠ければ、いったん引いて（島が見える）から寄る
    const far = dist > 200;
    this.moving = true;
    cam.stopFollow();
    cam.removeBounds();
    this.transition = this.tweens.addCounter({
      from: 0,
      to: 1,
      duration: far ? 1800 : 700,
      ease: "Sine.easeInOut",
      onUpdate: (tw) => {
        const t = tw.getValue() ?? 0;
        const base = from.z * Math.pow(z1 / from.z, t);
        const dip = far ? 1 - 0.62 * Math.sin(Math.PI * t) : 1;
        cam.setZoom(base * dip);
        cam.centerOn(from.x + (char.x - from.x) * t, from.y + (char.y - from.y) * t);
      },
      onComplete: () => {
        this.moving = false;
        cam.setBounds(0, 0, WORLD_W, WORLD_H);
        cam.setZoom(z1);
        if (this.remotes.get(this.target)?.char === char) cam.startFollow(char, true, 0.12, 0.12);
      },
    });
  }

  // ---------------------------------------------------------------- 接続（落ちても、つなぎ直し続ける）
  protected override async connect(): Promise<void> {
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.stopped = true;
      this.net.leave();
    });
    while (!this.stopped) {
      let lost: () => void = () => undefined;
      const gone = new Promise<void>((res) => (lost = res));
      try {
        const token = await this.fetchToken();
        this.net = new Network();
        await this.net.joinSpectator(token, {
          onPlayerAdd: (p, id) => this.onPlayerAdd(p, id),
          onPlayerChange: (p, id) => this.onPlayerChange(p, id),
          onPlayerRemove: (_p, id) => this.onPlayerRemove(id),
          onChat: (m) => this.say(m),
          onChatState: () => undefined,
          onChatDelete: () => undefined,
          onEmote: (m) => this.emoteOf(m),
          onCorrect: () => undefined,
          onDrop: () => this.game.events.emit(EV_SPECTATE, false),
          onReconnect: () => this.game.events.emit(EV_SPECTATE, true),
          onLost: () => lost(),
        });
        this.game.events.emit(EV_SPECTATE, true);
        await gone;
      } catch (e) {
        console.warn("[show] 観客としての接続に失敗:", e);
      }
      if (this.stopped) return;
      this.game.events.emit(EV_SPECTATE, false);
      this.clearPeers();
      await new Promise((res) => window.setTimeout(res, RETRY_MS));
    }
  }

  /** 管理用 API から、入場券（短命トークン）をもらう。管理ページと同じパスワードの内側 */
  private async fetchToken(): Promise<string> {
    const r = await fetch("/admin/api/spectator-token", { cache: "no-store" });
    if (!r.ok) throw new Error(`spectator-token ${r.status}`);
    const j = (await r.json()) as { token?: string };
    if (!j.token) throw new Error("no token");
    return j.token;
  }

  private clearPeers(): void {
    for (const id of [...this.remotes.keys()]) this.onPlayerRemove(id);
  }

  // ---------------------------------------------------------------- 参加者（名札・ふきだし）
  protected override onPlayerAdd(p: Player, id: string): void {
    super.onPlayerAdd(p, id);
    const name = this.add
      .text(0, 0, p.name, { fontFamily: FONT, fontSize: "7px", fontStyle: "bold", color: "#ffffff", stroke: "#3a2f5c", strokeThickness: 2 })
      .setOrigin(0.5, 1)
      .setResolution(8)
      .setDepth(DEPTH_TOP);
    this.labels.set(id, { name, bubbleUntil: 0 });
    // 追いたい人が、いま届いた（入室の直後・つなぎ直しの後）
    if (id === this.target) this.flyTo(this.remotes.get(id)!);
  }

  protected override onPlayerRemove(id: string): void {
    super.onPlayerRemove(id);
    const l = this.labels.get(id);
    if (l) {
      l.name.destroy();
      l.bubble?.destroy();
      this.labels.delete(id);
    }
  }

  private bubbleText(id: string, text: string): void {
    const l = this.labels.get(id);
    if (!l) return;
    l.bubble?.destroy();
    l.bubble = this.add
      .text(0, 0, text, {
        fontFamily: FONT,
        fontSize: "7px",
        fontStyle: "bold",
        color: "#34456b",
        backgroundColor: "#ffffff",
        padding: { x: 3, y: 2 },
        wordWrap: { width: 90 },
        align: "center",
      })
      .setOrigin(0.5, 1)
      .setResolution(8)
      .setDepth(DEPTH_TOP + 1);
    l.bubbleUntil = this.time.now + BUBBLE_MS;
  }

  private say(m: ChatBroadcast): void {
    this.bubbleText(m.sessionId, m.text);
  }

  private emoteOf(m: EmoteBroadcast): void {
    const r = this.remotes.get(m.sessionId);
    const def = EMOTES[m.id as EmoteId];
    if (!r || !def) return;
    const bubble = emoteBubble(m.id);
    if (bubble) this.bubbleText(m.sessionId, bubble);
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

  // ---------------------------------------------------------------- 毎フレーム
  override update(time: number, delta: number): void {
    super.update(time, delta);
    for (const [id, r] of this.remotes) {
      const l = this.labels.get(id);
      if (!l) continue;
      const watched = id === this.target;
      const top = r.char.y - 22 - (r.char.headAccessory ? 11 : 0);
      l.name.setPosition(r.char.x, top);
      // 追っている人は、名札を目立たせる
      l.name.setColor(watched ? "#fff0a0" : "#ffffff").setScale(watched ? 1.25 : 1);
      if (l.bubble) {
        if (time > l.bubbleUntil) {
          l.bubble.destroy();
          l.bubble = undefined;
        } else {
          l.bubble.setPosition(r.char.x, top - 9);
        }
      }
    }
  }
}
