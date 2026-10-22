import { HAIRS, type Hair } from "./constants";

/**
 * アバター（見た目）。髪型（今までの6体）に、髪・目・服の色、かざり（出店のスタンプの絵）を組み合わせる。
 * 色が1つも無ければ、素材のままの見た目（今までの6体）。クライアントが作り、サーバーが形を確かめて全員に配る。
 */

/** かざりに使える絵。出店のスタンプの絵柄と同じ（client/src/game/stampIcons.ts の並びと同じ順にする） */
export const ACCESSORY_IDS = [
  "okonomiyaki",
  "taiyaki",
  "cafe",
  "chocobanana",
  "takoyaki",
  "shateki",
  "suisougaku",
  "sadokado",
  "aburasoba",
  "wataame",
  "potato",
  "casino",
  "obakeyashiki",
  "programming",
  "science",
  "library",
  "handmade",
  "photoart",
  "dtm",
  "amateurradio",
  "volleyball",
  "obanyaki",
  "kushiyaki",
  "doujinshi",
  "suuri",
  "nazotoki",
  "entre",
  "hotdog",
  "frankfurt",
  "kirakira",
  "circuit",
  "printer3d",
  "croffle",
  "tamasen",
] as const;
export type AccessoryId = (typeof ACCESSORY_IDS)[number];

export interface Look {
  hair: Hair;
  /** #rrggbb。省略 = 素材の色 */
  hairColor?: string;
  eyeColor?: string;
  /** 服の上（赤い部分） */
  top?: string;
  /** 服の下（青いオーバーオール） */
  bottom?: string;
  /** あたまにのせるかざり */
  head?: AccessoryId;
  /** 手に持つかざり */
  hand?: AccessoryId;
}

const HEX = /^#[0-9a-f]{6}$/;
const color = (v: unknown): string | undefined => (typeof v === "string" && HEX.test(v.toLowerCase()) ? v.toLowerCase() : undefined);
const acc = (v: unknown): AccessoryId | undefined => ((ACCESSORY_IDS as readonly string[]).includes(v as string) ? (v as AccessoryId) : undefined);

/** 形の正しいものだけを取り出す（信用しない入力を、安全な Look にする）。髪型が不正なら null */
export function sanitizeLook(v: Partial<Record<keyof Look, unknown>> | null | undefined): Look | null {
  if (!v || !(HAIRS as readonly string[]).includes(v.hair as string)) return null;
  const look: Look = { hair: v.hair as Hair };
  const set = <K extends keyof Look>(k: K, x: Look[K] | undefined) => {
    if (x !== undefined) look[k] = x;
  };
  set("hairColor", color(v.hairColor));
  set("eyeColor", color(v.eyeColor));
  set("top", color(v.top));
  set("bottom", color(v.bottom));
  set("head", acc(v.head));
  set("hand", acc(v.hand));
  return look;
}

const FIELDS = ["hair", "hairColor", "eyeColor", "top", "bottom", "head", "hand"] as const;

/** 状態（Player.look）に入れる短い文字列。"髪型|髪色|目|服上|服下|あたま|手"（無い項目は空） */
export function encodeLook(l: Look): string {
  return FIELDS.map((k) => l[k] ?? "").join("|");
}

export function decodeLook(s: string | undefined): Look | null {
  if (!s) return null;
  const p = s.split("|");
  const raw: Record<string, string> = {};
  FIELDS.forEach((k, i) => {
    if (p[i]) raw[k] = p[i];
  });
  return sanitizeLook(raw);
}

/** 色を変えているか（変えていなければ、素材の絵をそのまま使う） */
export const hasCustomColors = (l: Look | null | undefined): boolean => !!l && !!(l.hairColor || l.eyeColor || l.top || l.bottom);

/** 色の組み合わせだけの名前（テクスチャの共有に使う。かざりは含めない） */
export function colorKey(l: Look): string {
  return [l.hair, l.hairColor, l.eyeColor, l.top, l.bottom].map((x) => (x ?? "-").replace("#", "")).join("_");
}
