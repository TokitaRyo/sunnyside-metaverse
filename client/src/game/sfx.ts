import { bgm } from "../audio/Bgm";

/**
 * 効果音。音源ファイルは使わず、WebAudio で短い音を合成する（素材の権利を気にしなくてよい）。
 * BGM のミュート（左上のボタン）に連動する。ブラウザの自動再生制限のため、AudioContext は最初に鳴らすとき（ユーザー操作の後）に作る。
 */
let ctx: AudioContext | null = null;

function audio(): AudioContext | null {
  if (bgm.muted) return null;
  try {
    ctx ??= new AudioContext();
    if (ctx.state === "suspended") void ctx.resume();
    return ctx;
  } catch {
    return null;
  }
}

interface Note {
  /** 周波数 Hz */
  f: number;
  /** 開始までの秒 */
  t: number;
  /** 長さ(秒) */
  d: number;
  type?: OscillatorType;
  vol?: number;
}

function play(notes: Note[]): void {
  const a = audio();
  if (!a) return;
  const now = a.currentTime;
  for (const n of notes) {
    const o = a.createOscillator();
    const g = a.createGain();
    o.type = n.type ?? "square";
    o.frequency.value = n.f;
    const v = n.vol ?? 0.06;
    g.gain.setValueAtTime(0, now + n.t);
    g.gain.linearRampToValueAtTime(v, now + n.t + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, now + n.t + n.d);
    o.connect(g).connect(a.destination);
    o.start(now + n.t);
    o.stop(now + n.t + n.d + 0.05);
  }
}

// 音階（ド=C5 から）
const C5 = 523.25, E5 = 659.25, G5 = 783.99, C6 = 1046.5, E6 = 1318.5, G6 = 1568;

export const sfx = {
  /** スタンプを取ったとき: きらっと上がる2音 */
  stamp(): void {
    play([
      { f: G5, t: 0, d: 0.12 },
      { f: C6, t: 0.09, d: 0.12 },
      { f: E6, t: 0.18, d: 0.28, type: "triangle", vol: 0.08 },
    ]);
  },
  /** 全部そろったとき: 短いファンファーレ */
  complete(): void {
    play([
      { f: C5, t: 0, d: 0.14 },
      { f: E5, t: 0.14, d: 0.14 },
      { f: G5, t: 0.28, d: 0.14 },
      { f: C6, t: 0.42, d: 0.2 },
      { f: G5, t: 0.64, d: 0.1 },
      { f: C6, t: 0.76, d: 0.1 },
      { f: E6, t: 0.88, d: 0.5, type: "triangle", vol: 0.09 },
      { f: G6, t: 0.88, d: 0.5, type: "triangle", vol: 0.05 },
    ]);
  },
  /** エモートのとき: ぽんと軽い音 */
  emote(): void {
    play([
      { f: E5, t: 0, d: 0.08, type: "triangle", vol: 0.07 },
      { f: G5, t: 0.06, d: 0.1, type: "triangle", vol: 0.07 },
    ]);
  },
  /** 写真を撮ったとき: カシャッ */
  shutter(): void {
    play([
      { f: 1900, t: 0, d: 0.04, type: "square", vol: 0.05 },
      { f: 1100, t: 0.05, d: 0.07, type: "square", vol: 0.04 },
    ]);
  },
  /** 出店に入ったとき: やわらかい1音 */
  area(): void {
    play([{ f: G5, t: 0, d: 0.3, type: "sine", vol: 0.05 }]);
  },
};
