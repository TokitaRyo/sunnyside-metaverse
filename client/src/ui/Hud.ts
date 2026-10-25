import { CHAT_BUBBLE_MS, CHAT_LOG_MAX, EMOTES, EMOTE_IDS, PHRASES, type EmoteId } from "@metaverse/shared";
import type { InputState } from "../game/InputState";

interface Tag {
  root: HTMLDivElement;
  bubble?: HTMLDivElement;
  /** いま出している吹き出しの発言の番号（運営が消したら、吹き出しも消す） */
  bubbleMsg?: number;
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
    private cb: {
      onSend(text: string): void;
      onPhrase(id: number): void;
      onEmote(id: EmoteId): void;
      /** この人を、自分の画面から消す・戻す */
      onBlock(id: string, on: boolean): void;
      isBlocked(id: string): boolean;
      /** この人を通報する */
      onReport(id: string): void;
    },
  ) {
    Hud.current = this;
    $("hud").hidden = false;
    this.buildEmoteBar();
    this.buildPhraseBar();
    if (!Hud.staticBound) {
      Hud.staticBound = true;
      this.bindChat();
      this.bindPad();
      this.bindTouchToggles();
      this.bindChatVisibility();
      this.bindPeerMenu();
    }
    if (matchMedia("(pointer: coarse)").matches || new URLSearchParams(location.search).has("pad")) {
      document.body.classList.add("touch");
    }
    inputState.onEnter = () => {
      // チャット欄を隠しているとき・停止中は、Enter で入力欄を開かない
      if (document.body.classList.contains("chat-hidden") || this.input.disabled) return;
      this.input.focus();
    };
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
    if (kind === "peer") {
      nameEl.title = "この人への操作（ブロック・通報）";
      nameEl.addEventListener("click", (e) => {
        e.stopPropagation();
        this.openPeerMenu(id, name, nameEl);
      });
    }
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

  showBubble(id: string, text: string, msgId?: number): void {
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
    t.bubbleMsg = msgId;
    t.timer = window.setTimeout(() => {
      b.remove();
      if (t.bubble === b) {
        t.bubble = undefined;
        t.bubbleMsg = undefined;
      }
    }, CHAT_BUBBLE_MS);
  }

  // ---------- チャットログ ----------
  addChatLine(name: string, text: string, self: boolean, msgId?: number): void {
    const line = document.createElement("div");
    line.className = `line${self ? " self" : ""}`;
    if (msgId !== undefined) line.dataset.msg = String(msgId);
    const who = document.createElement("span");
    who.className = "who";
    who.textContent = name;
    line.append(who, document.createTextNode(text));
    const stick = this.log.scrollTop + this.log.clientHeight >= this.log.scrollHeight - 8;
    this.log.append(line);
    while (this.log.childElementCount > CHAT_LOG_MAX) this.log.firstElementChild?.remove();
    if (stick) this.log.scrollTop = this.log.scrollHeight;
  }

  /** 運営が消した発言を、チャット欄と吹き出しから消す */
  removeChatMessages(ids: number[]): void {
    const set = new Set(ids.map(String));
    this.log.querySelectorAll<HTMLElement>("[data-msg]").forEach((el) => {
      if (set.has(el.dataset.msg ?? "")) el.remove();
    });
    for (const t of this.tags.values()) {
      if (t.bubbleMsg !== undefined && set.has(String(t.bubbleMsg))) {
        window.clearTimeout(t.timer);
        t.bubble?.remove();
        t.bubble = undefined;
        t.bubbleMsg = undefined;
      }
    }
  }

  /** チャットの状態: 運営の停止・定型文だけ（荒らしが増えたとき自動で切り替わる）。切り替わったときは、チャット欄に1行出す */
  setChatState(locked: boolean, phrases: boolean): void {
    const was = document.body.classList.contains("chat-phrases");
    document.body.classList.toggle("chat-phrases", phrases && !locked);
    if (phrases !== was && !locked) {
      this.notice(phrases ? "いまは 定型文だけ つかえます（下のボタンから えらんでね）" : "ふつうのチャットに もどりました", "phrases");
      if (!phrases) $("phrase-bar").classList.remove("open");
    }
    this.setChatLocked(locked);
  }

  /** 自動の対応の知らせ（書き込みが送れなかった理由・通報の受付など）。チャット欄に1行と、画面の上に少しだけ出す */
  notice(text: string, _code?: string): void {
    if (!text) return;
    const line = document.createElement("div");
    line.className = "line notice";
    line.textContent = text;
    this.log.append(line);
    while (this.log.childElementCount > CHAT_LOG_MAX) this.log.firstElementChild?.remove();
    this.log.scrollTop = this.log.scrollHeight;
    const toast = $("mod-toast");
    toast.textContent = text;
    toast.hidden = false;
    window.clearTimeout(Hud.toastTimer);
    Hud.toastTimer = window.setTimeout(() => (toast.hidden = true), 3200);
  }
  private static toastTimer = 0;

  /** 運営がチャットを停止している間は、入力できなくして、知らせる。切り替わったときだけ、チャット欄にも1行出す */
  setChatLocked(locked: boolean): void {
    const was = document.body.classList.contains("chat-locked");
    document.body.classList.toggle("chat-locked", locked);
    this.input.disabled = locked;
    this.input.placeholder = locked ? "いま、チャットは 停止中です" : "Enter でチャット / Esc で戻る";
    if (locked) this.input.blur();
    if (locked !== was && (locked || was)) {
      const line = document.createElement("div");
      line.className = "line notice";
      line.textContent = locked ? "チャットは、運営によって停止されました" : "チャットが、再開されました";
      this.log.append(line);
      this.log.scrollTop = this.log.scrollHeight;
    }
  }

  /**
   * チャット欄（ログと入力欄）を、出す・隠す。パソコンもスマホも同じ。選んだ状態は端末に残す。
   * 左上のボタン（#chat-vis-btn）で切り替える。隠していても、吹き出し（頭の上の発言）は出る。
   */
  private bindChatVisibility(): void {
    const key = "amplifire.chat.hidden";
    const btn = $<HTMLButtonElement>("chat-vis-btn");
    const apply = (hidden: boolean) => {
      document.body.classList.toggle("chat-hidden", hidden);
      btn.classList.toggle("off", hidden);
      btn.setAttribute("aria-pressed", String(!hidden));
      btn.title = btn.ariaLabel = hidden ? "チャット欄を出す" : "チャット欄を隠す";
      if (hidden) this.input.blur();
    };
    let hidden = false;
    try {
      hidden = localStorage.getItem(key) === "1";
    } catch {
      /* 保存されていなければ、出した状態 */
    }
    apply(hidden);
    btn.addEventListener("click", () => {
      hidden = !document.body.classList.contains("chat-hidden");
      apply(hidden);
      try {
        localStorage.setItem(key, hidden ? "1" : "0");
      } catch {
        /* 保存できなくても動く */
      }
    });
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

  /** 定型文のボタン（自由な書き込みが止まっているときに使う）。毎回作り直す */
  private buildPhraseBar(): void {
    const bar = $("phrase-bar");
    bar.replaceChildren();
    PHRASES.forEach((text, i) => {
      const b = document.createElement("button");
      b.type = "button";
      b.textContent = text;
      b.addEventListener("click", () => {
        Hud.current?.cb.onPhrase(i);
        bar.classList.remove("open");
        b.blur();
      });
      bar.append(b);
    });
  }

  private peerMenuFor = "";
  /** 他の参加者の名前を押したときに出る、小さなメニュー（ブロック／通報／とじる）。リスナーは、ページで1回だけ張る（bindPeerMenu） */
  private openPeerMenu(id: string, name: string, anchor: HTMLElement): void {
    const menu = $("peer-menu");
    this.peerMenuFor = id;
    $("peer-menu-name").textContent = name || "この人";
    $("peer-block").textContent = this.cb.isBlocked(id) ? "ブロックを やめる" : "見えなくする（ブロック）";
    const r = anchor.getBoundingClientRect();
    menu.hidden = false;
    const w = menu.offsetWidth || 190;
    const h = menu.offsetHeight || 150;
    const left = Math.max(8, Math.min(innerWidth - w - 8, r.left + r.width / 2 - w / 2));
    const top = r.top - h - 8 > 8 ? r.top - h - 8 : Math.min(innerHeight - h - 8, r.bottom + 8);
    menu.style.left = `${Math.round(left)}px`;
    menu.style.top = `${Math.round(top)}px`;
  }

  private bindPeerMenu(): void {
    const menu = $("peer-menu");
    const close = () => (menu.hidden = true);
    $("peer-close").addEventListener("click", close);
    $("peer-block").addEventListener("click", () => {
      const cur = Hud.current;
      if (!cur || !cur.peerMenuFor) return;
      const on = !cur.cb.isBlocked(cur.peerMenuFor);
      cur.cb.onBlock(cur.peerMenuFor, on);
      cur.notice(on ? "この人を 見えなくしました（あなたの画面だけ）" : "ブロックを やめました");
      close();
    });
    $("peer-report").addEventListener("click", () => {
      const cur = Hud.current;
      if (!cur || !cur.peerMenuFor) return;
      if (confirm("この人を 運営に ほうこくしますか？（べつべつの人から ほうこくが たくさん あると、自動で チャットが とまります）")) cur.cb.onReport(cur.peerMenuFor);
      close();
    });
    // メニューの外を押したら閉じる
    document.addEventListener("pointerdown", (e) => {
      if (!menu.hidden && !(e.target as HTMLElement).closest("#peer-menu, .tag.peer .name")) close();
    });
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

  /**
   * スマホ用の「エモート」「チャット」ボタン。エモートは押すと一覧が開き、選ぶと閉じる。
   * チャットは押すと入力欄が出て（キーボードも開く）、送信するか外をタップすると閉じる。リスナーはページで1回だけ。
   */
  private bindTouchToggles(): void {
    const bar = $("emote-bar");
    const et = $<HTMLButtonElement>("emote-toggle");
    const setEmote = (open: boolean) => {
      bar.classList.toggle("open", open);
      document.body.classList.toggle("emote-open", open); // 開いている間は「話す」ボタンを隠す（狭い画面で重ならないように）
      et.setAttribute("aria-expanded", String(open));
    };
    et.addEventListener("click", () => setEmote(!bar.classList.contains("open")));
    // 一覧のどれかを選んだら閉じる（ボタン側の click はその前に実行される）
    bar.addEventListener("click", (e) => {
      if ((e.target as HTMLElement).closest("button")) setEmote(false);
    });
    const form = $("chat-form");
    const input = $<HTMLInputElement>("chat-input");
    $("chat-toggle").addEventListener("click", () => {
      if (document.body.classList.contains("chat-locked")) return; // 運営が停止中
      setEmote(false);
      // 定型文だけのとき: 入力欄ではなく、定型文のボタンを開く（もういちど押すと閉じる）
      if (document.body.classList.contains("chat-phrases")) {
        $("phrase-bar").classList.toggle("open");
        return;
      }
      form.classList.add("open");
      document.body.classList.add("chat-open"); // 入力中は、パッドなど下のボタンを隠す
      input.focus(); // タップの操作の中で focus しないと、iOS ではキーボードが開かない
    });
    input.addEventListener("blur", () => {
      form.classList.remove("open");
      document.body.classList.remove("chat-open");
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
