import { CHAT_BUBBLE_MS, CHAT_LOG_MAX, EMOTES, EMOTE_IDS, type EmoteId } from "@metaverse/shared";
import type { InputState } from "../game/InputState";

interface Tag {
  root: HTMLDivElement;
  bubble?: HTMLDivElement;
  timer?: number;
  lastKey: string;
}

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

/**
 * 名前ラベル・吹き出し・チャット欄・エモートバー・バーチャルパッド。
 * 文字をくっきり出すため Phaser のテキストではなく DOM で描き、ワールド座標に追従させる。
 *
 * 入室のたびに新しい Hud を作る（WorldScene.connect() から）が、チャット欄・パッドなど
 * 「静的な DOM 要素」向けのリスナーは1回しか張らない。毎回張ると、マップエディタとの行き来で
 * 何度も入退室したときにリスナーが積み重なり、チャット送信やパッド操作が多重に発火してしまうため。
 * 代わりにリスナーは常に `Hud.current`（最新のインスタンス）へ委譲する。
 */
export class Hud {
  private static current: Hud | null = null;
  private static staticBound = false;

  private tags = new Map<string, Tag>();
  private labels = $("labels");
  private log = $("chat-log");
  private input = $<HTMLInputElement>("chat-input");
  private emoteButtons = new Map<EmoteId, HTMLButtonElement>();

  constructor(
    private inputState: InputState,
    private cb: { onSend(text: string): void; onEmote(id: EmoteId): void },
  ) {
    Hud.current = this;
    $("hud").hidden = false;
    this.buildEmoteBar();
    if (!Hud.staticBound) {
      Hud.staticBound = true;
      this.bindChat();
      this.bindPad();
    }
    if (matchMedia("(pointer: coarse)").matches || new URLSearchParams(location.search).has("pad")) {
      document.body.classList.add("touch");
    }
    inputState.onEnter = () => this.input.focus();
    inputState.onEmoteKey = (i) => {
      const id = EMOTE_IDS[i];
      if (id) cb.onEmote(id);
    };
  }

  // ---------- ラベル／吹き出し ----------
  addTag(id: string, name: string, kind: "self" | "peer" | "mob"): void {
    if (this.tags.has(id)) return;
    const root = document.createElement("div");
    root.className = `tag ${kind}`;
    const nameEl = document.createElement("div");
    nameEl.className = "name";
    nameEl.textContent = name;
    if (!name) nameEl.hidden = true;
    root.append(nameEl);
    this.labels.append(root);
    this.tags.set(id, { root, lastKey: "" });
  }

  removeTag(id: string): void {
    const t = this.tags.get(id);
    if (!t) return;
    window.clearTimeout(t.timer);
    t.root.remove();
    this.tags.delete(id);
  }

  /** 画面座標(CSS px)に配置。頭上中央が (sx, sy)。 */
  moveTag(id: string, sx: number, sy: number): void {
    const t = this.tags.get(id);
    if (!t) return;
    const x = Math.round(sx);
    const y = Math.round(sy);
    const key = `${x},${y}`;
    if (key === t.lastKey) return;
    t.lastKey = key;
    t.root.style.transform = `translate(${x}px, ${y}px) translate(-50%, -100%)`;
  }

  hideTag(id: string): void {
    const t = this.tags.get(id);
    if (t && t.lastKey !== "hidden") {
      t.lastKey = "hidden";
      t.root.style.transform = "translate(-9999px, -9999px)";
    }
  }

  showBubble(id: string, text: string): void {
    const t = this.tags.get(id);
    if (!t) return;
    window.clearTimeout(t.timer);
    t.bubble?.remove();

    const b = document.createElement("div");
    b.className = "bubble";
    for (const c of ["tl", "tc", "tr"]) b.append(Object.assign(document.createElement("i"), { className: c }));
    b.append(Object.assign(document.createElement("i"), { className: "lc" }));
    const txt = document.createElement("div");
    txt.className = "txt";
    txt.textContent = text; // textContent なので HTML は解釈されない
    txt.style.padding = "0 2px";
    b.append(txt);
    b.append(Object.assign(document.createElement("i"), { className: "rc" }));
    for (const c of ["bl", "bc", "br"]) b.append(Object.assign(document.createElement("i"), { className: c }));

    t.root.prepend(b);
    t.bubble = b;
    t.timer = window.setTimeout(() => {
      b.remove();
      if (t.bubble === b) t.bubble = undefined;
    }, CHAT_BUBBLE_MS);
  }

  // ---------- チャットログ ----------
  addChatLine(name: string, text: string, self: boolean): void {
    const line = document.createElement("div");
    line.className = `line${self ? " self" : ""}`;
    const who = document.createElement("span");
    who.className = "who";
    who.textContent = name;
    line.append(who, document.createTextNode(text));
    const stick = this.log.scrollTop + this.log.clientHeight >= this.log.scrollHeight - 8;
    this.log.append(line);
    while (this.log.childElementCount > CHAT_LOG_MAX) this.log.firstElementChild?.remove();
    if (stick) this.log.scrollTop = this.log.scrollHeight;
  }

  // ---------- 内部 ----------
  /** チャット欄のリスナー。ページで1回だけ張り、常に最新の Hud インスタンスへ委譲する。 */
  private bindChat(): void {
    const form = $("chat-form");
    const input = this.input;
    const submit = () => {
      const cur = Hud.current;
      if (!cur) return;
      const text = input.value.trim();
      if (text) cur.cb.onSend(text);
      input.value = "";
      input.blur(); // 送信後は移動に戻る
    };
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      submit();
    });
    input.addEventListener("keydown", (e) => {
      // IME の変換確定 Enter (isComposing) では送信しない
      if (e.key === "Enter" && !e.isComposing) {
        e.preventDefault();
        submit();
      }
      if (e.key === "Escape") {
        input.value = "";
        input.blur();
      }
      e.stopPropagation();
    });
    input.addEventListener("focus", () => Hud.current?.inputState.clear());
  }

  /** エモートバーは毎回作り直す（先に空にするので重複しない）。 */
  private buildEmoteBar(): void {
    const bar = $("emote-bar");
    bar.replaceChildren();
    this.emoteButtons.clear();
    EMOTE_IDS.forEach((id, i) => {
      const btn = document.createElement("button");
      btn.type = "button";
      const kbd = document.createElement("kbd");
      kbd.textContent = String(i + 1);
      btn.append(kbd, EMOTES[id].label);
      btn.addEventListener("click", () => {
        Hud.current?.cb.onEmote(id);
        btn.blur();
      });
      bar.append(btn);
      this.emoteButtons.set(id, btn);
    });
  }

  /** トグル系エモート（座る）のON表示 */
  setEmoteOn(id: EmoteId, on: boolean): void {
    this.emoteButtons.get(id)?.classList.toggle("on", on);
  }

  /** バーチャルパッドのリスナー。ページで1回だけ張り、常に最新の Hud インスタンスへ委譲する。 */
  private bindPad(): void {
    const dirs = ["up", "down", "left", "right"] as const;
    document.querySelectorAll<HTMLButtonElement>("#pad button").forEach((btn) => {
      const dir = btn.dataset.pad as (typeof dirs)[number];
      const set = (v: boolean) => {
        Hud.current?.inputState.setPad(dir, v);
        btn.classList.toggle("active", v);
      };
      btn.addEventListener("pointerdown", (e) => {
        try {
          btn.setPointerCapture(e.pointerId); // 指が外れても離した扱いにならないように
        } catch {
          /* 一部ブラウザでは失敗しうるが、入力自体は続行する */
        }
        set(true);
      });
      for (const ev of ["pointerup", "pointercancel", "lostpointercapture"]) btn.addEventListener(ev, () => set(false));
      btn.addEventListener("contextmenu", (e) => e.preventDefault());
    });
    const run = $("run-btn");
    run.addEventListener("pointerdown", (e) => {
      try {
        run.setPointerCapture(e.pointerId);
      } catch {
        /* 同上 */
      }
      Hud.current?.inputState.setPad("run", true);
      run.classList.add("active");
    });
    for (const ev of ["pointerup", "pointercancel", "lostpointercapture"]) {
      run.addEventListener(ev, () => {
        Hud.current?.inputState.setPad("run", false);
        run.classList.remove("active");
      });
    }
  }
}
