import { CONSENT_VERSION } from "@metaverse/shared";

const VID_KEY = "amplifire.vid";
const CONSENT_KEY = "amplifire.consent";

/** ブラウザに保存するランダムな訪問者ID（再訪を数えるだけ。個人は特定しない）。保存できないときは、この読み込みの間だけの値 */
let memoryVid = "";
export function visitorId(): string {
  try {
    let v = localStorage.getItem(VID_KEY);
    if (!v || v.length < 8) {
      v = newId();
      localStorage.setItem(VID_KEY, v);
    }
    return v;
  } catch {
    return (memoryVid ||= newId());
  }
}

function newId(): string {
  try {
    return crypto.randomUUID();
  } catch {
    return Array.from({ length: 4 }, () => Math.random().toString(36).slice(2, 10)).join("");
  }
}

/** この端末で、いまの版の規約に同意済みか */
export function hasConsented(): boolean {
  try {
    const c = JSON.parse(localStorage.getItem(CONSENT_KEY) ?? "null") as { v?: string } | null;
    return c?.v === CONSENT_VERSION;
  } catch {
    return false;
  }
}

export function saveConsent(on: boolean): void {
  try {
    if (on) localStorage.setItem(CONSENT_KEY, JSON.stringify({ v: CONSENT_VERSION, at: new Date().toISOString() }));
    else localStorage.removeItem(CONSENT_KEY);
  } catch {
    /* 保存できなくても、その場の同意で入室できる */
  }
}

export const deviceKind = (): "touch" | "desktop" => (matchMedia("(pointer: coarse)").matches ? "touch" : "desktop");
