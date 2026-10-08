/**
 * 朝・昼・夜の時間帯。実時間の10分ごとに 朝 → 昼 → 夜 → 朝 … と切り替わる。
 * 時刻は端末の時計(Date.now())を PHASE_MS で割るだけなので、サーバーも通信も使わず、時計が合っていれば全員が同じ時間帯になる。
 * 世界の色合いは、時間帯ごとの色を「乗算」で重ねて変える（昼は白＝変化なし）。切り替わりの最初の FADE_MS でなめらかに混ぜる。
 */

export const PHASE_MS = 10 * 60 * 1000;
/** 時間帯が変わるとき、前の色から新しい色へ移る時間 */
export const FADE_MS = 30 * 1000;

export type PhaseId = "morning" | "day" | "night";

export interface Phase {
  id: PhaseId;
  label: string;
  icon: string;
  /** 世界に乗算で重ねる色 0xRRGGBB（白=そのまま、暗い色=暗くなる） */
  tint: number;
}

/** 並び順 = 切り替わる順（実時間を PHASE_MS で割った商 % 3） */
export const PHASES: readonly Phase[] = [
  { id: "morning", label: "朝", icon: "🌅", tint: 0xffd9b3 },
  { id: "day", label: "昼", icon: "☀️", tint: 0xffffff },
  { id: "night", label: "夜", icon: "🌙", tint: 0x5b6cab },
];

const FORCED: Record<string, number> = { morning: 0, day: 1, night: 2 };

/** ?tod=morning|day|night で時間帯を固定できる（確認・撮影用） */
function forced(): number | null {
  try {
    const v = new URLSearchParams(location.search).get("tod");
    return v && v in FORCED ? FORCED[v] : null;
  } catch {
    return null;
  }
}

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
const smooth = (t: number) => t * t * (3 - 2 * t);

function mix(a: number, b: number, t: number): number {
  const r = Math.round(lerp((a >> 16) & 255, (b >> 16) & 255, t));
  const g = Math.round(lerp((a >> 8) & 255, (b >> 8) & 255, t));
  const bl = Math.round(lerp(a & 255, b & 255, t));
  return (r << 16) | (g << 8) | bl;
}

export interface DayState {
  phase: Phase;
  /** 今の世界の色（切り替わり直後は前の時間帯の色から混ざっている） */
  tint: number;
  /** 次の時間帯までの残り(ms) */
  remainingMs: number;
}

export function dayState(now = Date.now()): DayState {
  const f = forced();
  if (f !== null) return { phase: PHASES[f], tint: PHASES[f].tint, remainingMs: PHASE_MS };
  const n = Math.floor(now / PHASE_MS);
  const into = now - n * PHASE_MS;
  const idx = ((n % PHASES.length) + PHASES.length) % PHASES.length;
  const phase = PHASES[idx];
  const prev = PHASES[(idx + PHASES.length - 1) % PHASES.length];
  const tint = into < FADE_MS ? mix(prev.tint, phase.tint, smooth(into / FADE_MS)) : phase.tint;
  return { phase, tint, remainingMs: PHASE_MS - into };
}

/** 夜の光る物（看板・提灯・ネオンなど）を、色合いの重ねの上に出すための名前判定 */
const LIGHT_RE =
  /(?:^|_)(sign|vsign|lantern|lamp|lamppost|glow|beam|beams|marquee|neon|sparkle|glint|flame|fire|campfire|blinking|monitor|mon|bigscreen|screen|laptop|tower|kbd|strip|slot|wheel|dice|candle|garland|bulb|tube|tank|bottle|hang|drift|hitodama|win|truss|backdrop|aframe)(?:_|\d|$)/;
export const isLightSprite = (name: string): boolean => LIGHT_RE.test(name);
