import type { MapSpriteDef } from "../config";

/** エディタでの分類。goblin/skeleton/human/animal がモブ、それ以外は物 */
export type Category = "goblin" | "skeleton" | "human" | "animal" | "other";

export const SHADOW_SPRITE = "spr_deco_charactershadow";

export const CATEGORY_LABEL: Record<Category, string> = {
  goblin: "ゴブリン",
  skeleton: "スケルトン",
  human: "人間",
  animal: "動物・鳥",
  other: "物・その他",
};
export const CATEGORY_ORDER: Category[] = ["goblin", "skeleton", "human", "animal", "other"];

export function categoryOf(name: string, def: MapSpriteDef): Category {
  if (name.startsWith("human_")) return "human";
  if (name.startsWith("skeleton_")) return "skeleton";
  if (/^spr_deco_(cow|sheep_01|pig_01|chicken_01|duck_01|bird_01)$/.test(name)) return "animal";
  // ゴブリンの動作スプライトは 96x64（spr_idle, spr_carry …）。影(16x16)などは対象外
  if (def.fw === 96 && def.fh === 64) return "goblin";
  return "other";
}

export const isMobCategory = (c: Category): boolean => c !== "other";

/**
 * 影を別の物として持つモブ。ゴブリン・スケルトン・人間は足元の少し下に影スプライトを置く。
 * 動物・鳥は絵そのものに影が描かれているので、影の物は不要（実データでも影の物は付いていない）。
 * オフセットは足元(o.x, o.by)から見た影の位置(px)。実データの中央値。
 */
export const SHADOW_OFFSET: Partial<Record<Category, [number, number]>> = {
  goblin: [0, -1],
  skeleton: [0, -8],
  human: [0, -1],
};
export const hasShadow = (c: Category): boolean => c in SHADOW_OFFSET;

const GOBLIN_ACTION: Record<string, string> = {
  idle: "立ち", waiting: "待機", walking: "歩く", run: "走る", jump: "ジャンプ", roll: "転がる", doing: "作業", carry: "運ぶ",
  attack: "攻撃", hurt: "やられ", death: "倒れる", swimming: "泳ぐ", axe: "斧", mining: "採掘", hammering: "金槌", dig: "掘る",
  watering: "水やり", casting: "釣り(投げ)", reeling: "釣り(巻き)", caught: "釣れた",
};
const SKELETON_ACTION: Record<string, string> = { idle: "立ち", walk: "歩く", attack: "攻撃", jump: "ジャンプ", hurt: "やられ", death: "倒れる" };
const HAIR: Record<string, string> = { bowlhair: "ボウル", curlyhair: "カール", longhair: "ロング", mophair: "モップ", shorthair: "ショート", spikeyhair: "ツンツン" };
const HUMAN_ACTION: Record<string, string> = { idle: "立ち", waiting: "待機", walk: "歩く", carry: "運ぶ", doing: "作業" };
const ANIMAL: Record<string, string> = { cow: "牛", sheep_01: "羊", pig_01: "豚", chicken_01: "鶏", duck_01: "アヒル", bird_01: "鳥" };

/** 一覧に出す日本語名。分からないものはスプライト名のまま */
export function labelOf(name: string, cat: Category): string {
  if (cat === "goblin") return GOBLIN_ACTION[name.replace(/^spr_/, "")] ?? name;
  if (cat === "skeleton") return SKELETON_ACTION[name.replace(/^skeleton_/, "")] ?? name;
  if (cat === "human") {
    const m = name.match(/^human_(\w+?)_(\w+)$/);
    return m ? `${HAIR[m[1]] ?? m[1]}・${HUMAN_ACTION[m[2]] ?? m[2]}` : name;
  }
  if (cat === "animal") return ANIMAL[name.replace(/^spr_deco_/, "")] ?? name;
  return name.replace(/^spr_deco_/, "").replace(/^spr_/, "");
}

const ORDER: Record<Category, string[]> = {
  goblin: Object.keys(GOBLIN_ACTION).map((a) => `spr_${a}`),
  skeleton: Object.keys(SKELETON_ACTION).map((a) => `skeleton_${a}`),
  human: [],
  animal: Object.keys(ANIMAL).map((a) => `spr_deco_${a}`),
  other: [],
};

/** カテゴリ内の並び（決めてあるものは決めた順、それ以外は名前順） */
export function sortNames(names: string[], cat: Category): string[] {
  const order = ORDER[cat];
  const rank = (n: string) => (order.indexOf(n) >= 0 ? order.indexOf(n) : 1000);
  return [...names].sort((a, b) => rank(a) - rank(b) || a.localeCompare(b));
}
