import { map } from "../config";

/** スタンプラリーの進み具合。端末のブラウザ(localStorage)に覚えるだけで、サーバーには送らない。 */
const STORE = "sunnyside.stamps.v1";

function load(): Set<string> {
  try {
    const v = JSON.parse(localStorage.getItem(STORE) ?? "[]");
    return new Set(Array.isArray(v) ? v.filter((s): s is string => typeof s === "string") : []);
  } catch {
    return new Set();
  }
}

const collected = load();

function save(): void {
  try {
    localStorage.setItem(STORE, JSON.stringify([...collected]));
  } catch {
    /* 保存できなくても、このページを開いている間は動く */
  }
}

export const stamps = {
  has: (id: string): boolean => collected.has(id),
  /** 新しく取得したら true */
  add(id: string): boolean {
    if (collected.has(id)) return false;
    collected.add(id);
    save();
    return true;
  },
  reset(): void {
    collected.clear();
    save();
  },
  /** 今のマップにあるキーアイテムのうち取得済みの数（マップから消えたIDは数えない） */
  get count(): number {
    return (map.keyItems ?? []).filter((k) => collected.has(k.id)).length;
  },
  get total(): number {
    return map.keyItems?.length ?? 0;
  },
};
