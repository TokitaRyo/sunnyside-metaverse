/**
 * BGM再生。ページで1つだけ（マップエディタとの行き来をまたいで鳴り続ける）。
 * Phaser の audio は main.ts で明示的に無効化している(noAudio: true)ため、
 * ここでは素の HTMLAudioElement で完結させる。
 *
 * ブラウザの自動再生制限があるため start() は必ずユーザー操作(クリック等)のハンドラ内から呼ぶこと。
 */

const TRACKS = [
  "audio/bgm/rainy-day.mp3",
  "audio/bgm/goodbye.mp3",
  "audio/bgm/observatory-and-chill-2.mp3",
  "audio/bgm/brain-empty.mp3",
  "audio/bgm/lofi-beats-to-ride-dragons-with.mp3",
  "audio/bgm/birds-song.mp3",
  "audio/bgm/between-the-dunes.mp3",
  "audio/bgm/summer2.mp3",
  "audio/bgm/7pm.mp3",
];

const STORE_KEY = "sunnyside.bgm";
const VOLUME = 0.35;

function shuffle<T>(arr: readonly T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

class BgmPlayer {
  private audio = new Audio();
  private order = shuffle(TRACKS);
  private idx = 0;
  private started = false;
  muted: boolean;

  constructor() {
    this.muted = this.restore();
    this.audio.volume = VOLUME;
    this.audio.muted = this.muted;
    this.audio.preload = "auto";
    this.audio.addEventListener("ended", () => this.playNext());
  }

  /** 初回のみ再生を始める。以後は呼んでも無視する（再入室・エディタ往復で鳴り直さない）。 */
  start(): void {
    if (this.started) return;
    this.started = true;
    this.playCurrent();
  }

  toggleMute(): boolean {
    this.muted = !this.muted;
    this.audio.muted = this.muted;
    this.persist();
    return this.muted;
  }

  private playCurrent(): void {
    this.audio.src = `${import.meta.env.BASE_URL}assets/${this.order[this.idx]}`;
    void this.audio.play().catch(() => {
      /* 自動再生がブロックされた場合は諦める。ミュート操作自体は引き続きできる */
    });
  }

  private playNext(): void {
    this.idx += 1;
    if (this.idx >= this.order.length) {
      this.idx = 0;
      this.order = shuffle(TRACKS); // 一周したら並びを変える
    }
    this.playCurrent();
  }

  private restore(): boolean {
    try {
      return localStorage.getItem(STORE_KEY) === "muted";
    } catch {
      return false;
    }
  }

  private persist(): void {
    try {
      localStorage.setItem(STORE_KEY, this.muted ? "muted" : "on");
    } catch {
      /* プライベートモード等では保存しない */
    }
  }
}

export const bgm = new BgmPlayer();
