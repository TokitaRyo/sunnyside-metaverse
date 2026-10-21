import { ACCESSORY_IDS, HAIRS, NAME_MAX, sanitizeLook, type Hair, type Look } from "@metaverse/shared";
import { humanLayers } from "../game/assets";
import { loadStampSheet, stampFrame, stampIconUrl } from "../game/stampIcons";
import { hasConsented, saveConsent, visitorId } from "../game/visitor";
import { AvatarPreview } from "./AvatarPreview";
import { DIVE_FADE_AT_MS } from "./intro";
import { renderTerms } from "./terms";

const HAIR_LABEL: Record<Hair, string> = {
  bowlhair: "ボウル",
  curlyhair: "カール",
  longhair: "ロング",
  mophair: "モップ",
  shorthair: "ショート",
  spikeyhair: "ツンツン",
};

/** 色えらび。パステルを中心に。どの行も、先頭は「もとの色」、最後は好きな色（カラーピッカー） */
type ColorKey = "hairColor" | "eyeColor" | "top" | "bottom";
const COLOR_ROWS: { key: ColorKey; label: string; colors: string[] }[] = [
  { key: "hairColor", label: "かみ", colors: ["#3b2a26", "#7a5a48", "#d49a68", "#f2d27a", "#ff9ec7", "#ff8f8f", "#ffb870", "#9be3b5", "#8fd3ff", "#a99dff", "#ffffff", "#8a96b4"] },
  { key: "eyeColor", label: "め", colors: ["#4a6cff", "#2fb0a8", "#3f9f5a", "#8a5a3a", "#a74fd6", "#e0486a", "#e0a63a", "#2b2b3a", "#5ab4ff", "#ff7fb0"] },
  { key: "top", label: "ふく（うえ）", colors: ["#ffb3c8", "#ffd27f", "#fff09a", "#b8f0c8", "#9be3ff", "#b9b4ff", "#ffffff", "#ff8f8f", "#f7b7ee", "#8fa6ff", "#e0e0e8", "#4a4a66"] },
  { key: "bottom", label: "ふく（した）", colors: ["#8fb4ff", "#9be3ff", "#b9b4ff", "#ffd2a8", "#b8f0c8", "#ffb3c8", "#ffffff", "#5b6a99", "#4a4a66", "#f0e0a0", "#c9a0ff", "#7fd6c2"] },
];
const ACC_LABEL: Record<string, string> = {
  okonomiyaki: "お好み焼き", taiyaki: "たい焼き", cafe: "コーヒー", chocobanana: "チョコバナナ", takoyaki: "たこ焼き", shateki: "まと", suisougaku: "トランペット",
  sadokado: "おちゃ", aburasoba: "油そば", wataame: "わたあめ", potato: "ポテト", casino: "チップ", obakeyashiki: "おばけ", programming: "パソコン", science: "フラスコ",
  library: "ほん", handmade: "くらげ", photoart: "カメラ", dtm: "ヘッドホン", amateurradio: "むせん", volleyball: "バレーボール",
};

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const STORE_KEY = "sunnyside.profile";
/** 決定したあと、えらんだアバターを大きく見せる最低限の時間 */
const SHOWCASE_MS = 1800;

export interface JoinInfo {
  name: string;
  look: Look;
}

const rand = <T,>(a: readonly T[]): T => a[Math.floor(Math.random() * a.length)];

/**
 * 入室画面: なまえ、アバターづくり（髪型6種＋髪・目・服の色＋かざり）、規約への同意。白い背景にパステルの画面。
 * 決定すると、えらんだアバターが画面に大きく出て（showcase）、そのあと従来の「惑星へ降りる」演出につながる。
 */
export class JoinScreen {
  private look: Look = { hair: rand(HAIRS) };
  private loaded = false;
  private busy = false;
  private consent = false;
  private accSlot: "head" | "hand" = "head";
  private preview!: AvatarPreview;
  private showPreview?: AvatarPreview;
  private showTimer = 0;
  onSubmit?: (info: JoinInfo) => void;

  constructor() {
    const saved = this.restore();
    if (saved?.look) this.look = saved.look;
    const nameEl = $<HTMLInputElement>("join-name");
    nameEl.value = saved?.name ?? "";

    this.buildHairGrid();
    this.buildColorRows();
    this.buildAccessoryGrid();
    this.preview = new AvatarPreview($<HTMLCanvasElement>("av-canvas"));
    this.preview.setLook(this.look);
    this.preview.start();
    $("av-wave").addEventListener("click", () => this.preview.wave());
    $("av-random").addEventListener("click", () => this.randomize());
    $("acc-tab-head").addEventListener("click", () => this.setSlot("head"));
    $("acc-tab-hand").addEventListener("click", () => this.setSlot("hand"));
    this.refresh();

    // 利用規約・データの取り扱いへの同意（同意しないと入室できない）。同じ版に同意済みなら、チェックを入れた状態で始める
    const box = $<HTMLInputElement>("consent");
    this.consent = hasConsented();
    box.checked = this.consent;
    box.addEventListener("change", () => {
      this.consent = box.checked;
      saveConsent(this.consent);
      this.updateButton();
    });
    const terms = $("terms");
    const openTerms = () => {
      renderTerms($("terms-body"), visitorId());
      terms.hidden = false;
      $("terms-body").scrollTop = 0;
    };
    const closeTerms = () => (terms.hidden = true);
    $("terms-open").addEventListener("click", (e) => {
      e.preventDefault();
      openTerms();
    });
    $("terms-close").addEventListener("click", closeTerms);
    $("terms-back").addEventListener("click", closeTerms);
    $("terms-agree").addEventListener("click", () => {
      box.checked = true;
      this.consent = true;
      saveConsent(true);
      this.updateButton();
      closeTerms();
    });
    terms.addEventListener("click", (e) => {
      if (e.target === terms) closeTerms();
    });

    $("join-form").addEventListener("submit", (e) => {
      e.preventDefault();
      if (!this.loaded || this.busy || !this.consent) return;
      const name = Array.from(nameEl.value.trim()).slice(0, NAME_MAX).join("") || "ゲスト";
      this.persist({ name, look: this.look });
      this.setBusy(true);
      this.onSubmit?.({ name, look: this.look });
    });
  }

  // ---------------------------------------------------------------- つくる
  private buildHairGrid(): void {
    const grid = $("hair-grid");
    for (const h of HAIRS) {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "hair-opt";
      btn.setAttribute("role", "radio");
      btn.dataset.hair = h;
      // 人間キャラの idle 1フレーム目を、base+hair+tools の3枚重ねでCSS表示（Phaser不要）
      const pv = document.createElement("div");
      pv.className = "pv";
      pv.style.backgroundImage = humanLayers(h)
        .reverse()
        .map((l) => `url(${import.meta.env.BASE_URL}assets/characters/human/${l}/idle.png)`)
        .join(",");
      const label = document.createElement("small");
      label.textContent = HAIR_LABEL[h];
      btn.append(pv, label);
      btn.addEventListener("click", () => {
        this.look = { ...this.look, hair: h };
        this.changed();
      });
      grid.append(btn);
    }
  }

  private buildColorRows(): void {
    const box = $("color-rows");
    for (const row of COLOR_ROWS) {
      const wrap = document.createElement("div");
      wrap.className = "color-row";
      wrap.dataset.key = row.key;
      const label = document.createElement("span");
      label.className = "color-label";
      label.textContent = row.label;
      const sw = document.createElement("div");
      sw.className = "swatches";
      const none = document.createElement("button");
      none.type = "button";
      none.className = "swatch none";
      none.title = "もとの色";
      none.setAttribute("aria-label", `${row.label}: もとの色`);
      none.addEventListener("click", () => this.setColor(row.key, undefined));
      sw.append(none);
      for (const c of row.colors) {
        const b = document.createElement("button");
        b.type = "button";
        b.className = "swatch";
        b.dataset.color = c;
        b.title = c;
        b.setAttribute("aria-label", `${row.label}: ${c}`);
        b.style.background = c;
        b.addEventListener("click", () => this.setColor(row.key, c));
        sw.append(b);
      }
      // 好きな色（ブラウザのカラーピッカー）
      const custom = document.createElement("label");
      custom.className = "swatch custom";
      custom.title = "好きな色";
      const input = document.createElement("input");
      input.type = "color";
      input.value = row.colors[0];
      input.setAttribute("aria-label", `${row.label}: 好きな色`);
      input.addEventListener("input", () => this.setColor(row.key, input.value));
      custom.append(input);
      sw.append(custom);
      wrap.append(label, sw);
      box.append(wrap);
    }
  }

  private buildAccessoryGrid(): void {
    const grid = $("acc-grid");
    const build = () => {
      grid.replaceChildren();
      const none = document.createElement("button");
      none.type = "button";
      none.className = "acc none";
      none.textContent = "なし";
      none.addEventListener("click", () => this.setAccessory(undefined));
      grid.append(none);
      for (const id of ACCESSORY_IDS) {
        const b = document.createElement("button");
        b.type = "button";
        b.className = "acc";
        b.dataset.acc = id;
        b.title = ACC_LABEL[id] ?? id;
        b.setAttribute("aria-label", ACC_LABEL[id] ?? id);
        const f = stampFrame(id);
        const img = new Image();
        img.alt = "";
        img.src = stampIconUrl(f, 3);
        b.append(img);
        b.addEventListener("click", () => this.setAccessory(id));
        grid.append(b);
      }
      this.refresh();
    };
    build();
    // 絵のシートが読み込めたら、描き直す
    void loadStampSheet().then((img) => img && build());
  }

  private setSlot(slot: "head" | "hand"): void {
    this.accSlot = slot;
    this.refresh();
  }

  private setColor(key: ColorKey, color: string | undefined): void {
    const look = { ...this.look };
    if (color) look[key] = color;
    else delete look[key];
    this.look = look;
    this.changed();
  }

  private setAccessory(id: Look["head"]): void {
    const look = { ...this.look };
    if (id) look[this.accSlot] = id;
    else delete look[this.accSlot];
    this.look = look;
    this.changed();
  }

  private randomize(): void {
    const look: Look = { hair: rand(HAIRS) };
    for (const row of COLOR_ROWS) if (Math.random() < 0.85) look[row.key] = rand(row.colors);
    if (Math.random() < 0.7) look.head = rand(ACCESSORY_IDS);
    if (Math.random() < 0.5) look.hand = rand(ACCESSORY_IDS);
    this.look = look;
    this.changed();
    this.preview.wave();
  }

  private changed(): void {
    this.look = sanitizeLook(this.look) ?? { hair: HAIRS[0] };
    this.preview.setLook(this.look);
    this.refresh();
  }

  /** ボタンの「えらんでいる」表示を、いまの見た目に合わせる */
  private refresh(): void {
    const look = this.look;
    document.querySelectorAll<HTMLElement>(".hair-opt").forEach((el) => el.setAttribute("aria-checked", String(el.dataset.hair === look.hair)));
    document.querySelectorAll<HTMLElement>(".color-row").forEach((row) => {
      const cur = look[row.dataset.key as ColorKey];
      row.querySelectorAll<HTMLElement>(".swatch").forEach((s) => {
        const on = s.classList.contains("none") ? !cur : s.dataset.color === cur;
        s.classList.toggle("on", on);
        s.setAttribute("aria-pressed", String(on));
      });
      const custom = row.querySelector<HTMLElement>(".swatch.custom");
      // 好きな色が選ばれているときは、その色をカラーピッカーの丸に出す
      if (custom) {
        const preset = [...row.querySelectorAll<HTMLElement>(".swatch[data-color]")].some((s) => s.dataset.color === cur);
        custom.classList.toggle("on", !!cur && !preset);
        custom.style.background = cur && !preset ? cur : "";
      }
    });
    const cur = look[this.accSlot];
    document.querySelectorAll<HTMLElement>("#acc-grid .acc").forEach((b) => b.classList.toggle("on", b.classList.contains("none") ? !cur : b.dataset.acc === cur));
    for (const slot of ["head", "hand"] as const) {
      const tab = $(`acc-tab-${slot}`);
      tab.classList.toggle("on", this.accSlot === slot);
      tab.setAttribute("aria-selected", String(this.accSlot === slot));
      tab.textContent = (slot === "head" ? "あたま" : "て") + (look[slot] ? " ●" : "");
    }
  }

  // ---------------------------------------------------------------- 状態
  setProgress(p: number): void {
    $("load-bar").style.width = `${Math.round(p * 100)}%`;
  }

  setReady(): void {
    this.loaded = true;
    this.updateButton();
  }

  /** 入室ボタンの状態: 読み込み中 → 同意待ち → 入室できる */
  private updateButton(): void {
    const btn = $<HTMLButtonElement>("join-btn");
    if (this.busy) {
      btn.disabled = true;
      btn.textContent = "接続中…";
    } else if (!this.loaded) {
      btn.disabled = true;
      btn.textContent = "読み込み中…";
    } else if (!this.consent) {
      btn.disabled = true;
      btn.textContent = "同意すると入室できます";
    } else {
      btn.disabled = false;
      btn.textContent = "この姿で入室する";
    }
  }

  setBusy(busy: boolean): void {
    this.busy = busy;
    if (busy) $("join-error").hidden = true;
    this.updateButton();
  }

  showError(msg: string): void {
    this.exitShowcase();
    const el = $("join-error");
    el.textContent = msg;
    el.hidden = false;
    this.setBusy(false);
  }

  // ---------------------------------------------------------------- 決定したあとの、大きな表示
  /**
   * えらんだアバターを画面に大きく出す。最低 SHOWCASE_MS たったら解決する（そのあとゲームに接続して、降下の演出へ）。
   * 接続に失敗したら showError が元の画面に戻す。
   */
  showcase(info: JoinInfo): Promise<void> {
    $("join").classList.add("showcase");
    $("oz-show").hidden = false;
    $("show-name").textContent = `ようこそ、${info.name}！`;
    this.showPreview?.stop();
    this.showPreview = new AvatarPreview($<HTMLCanvasElement>("show-canvas"));
    this.showPreview.setLook(info.look);
    this.showPreview.start();
    window.setTimeout(() => this.showPreview?.wave(), 350);
    return new Promise((resolve) => {
      window.clearTimeout(this.showTimer);
      this.showTimer = window.setTimeout(resolve, SHOWCASE_MS);
    });
  }

  private exitShowcase(): void {
    window.clearTimeout(this.showTimer);
    this.showPreview?.stop();
    this.showPreview = undefined;
    $("join").classList.remove("showcase");
    $("oz-show").hidden = true;
  }

  hide(): void {
    this.clearDive();
    this.preview.stop();
    this.showPreview?.stop();
    $("join").hidden = true;
  }

  /**
   * 入室の演出: 白い画面が消えて宇宙が見え、パネルとロゴが消え、惑星に向かって急降下し、ゲーム画面（上空からの映像）へ溶け込む。
   * 画面を覆っているのはこの要素なので、終わったら hide() と同じ状態になる。
   * ゲーム側（WorldScene）のカメラ演出は DIVE_COVER_MS 後から始まる前提で時間を合わせている。
   */
  dive(): void {
    const el = $("join");
    this.clearDive();
    el.classList.add("dive");
    // 惑星がほぼ画面を覆ったところから、全体をゆっくり消してゲーム画面を見せる
    this.diveTimers.push(window.setTimeout(() => el.classList.add("out"), DIVE_FADE_AT_MS));
    this.diveTimers.push(window.setTimeout(() => this.hide(), DIVE_FADE_AT_MS + 800));
  }

  private clearDive(): void {
    this.diveTimers.forEach((t) => window.clearTimeout(t));
    this.diveTimers = [];
  }

  /** マップエディタから戻ったときなど、もう一度この画面を使えるようにする */
  reset(): void {
    this.clearDive();
    this.exitShowcase();
    this.setBusy(false);
    $("join-error").hidden = true;
    const el = $("join");
    el.classList.remove("dive", "out");
    el.hidden = false;
    this.preview.start();
  }

  private diveTimers: number[] = [];

  private restore(): { name?: string; look?: Look } | null {
    try {
      const v = JSON.parse(localStorage.getItem(STORE_KEY) ?? "null") as { name?: string; hair?: string; look?: Record<string, unknown> } | null;
      if (!v) return null;
      // 前の版は髪型だけ（hair）を保存していた
      const look = sanitizeLook(v.look as never) ?? (v.hair ? sanitizeLook({ hair: v.hair }) : null);
      return { name: v.name, look: look ?? undefined };
    } catch {
      return null;
    }
  }

  private persist(info: { name: string; look: Look }): void {
    try {
      localStorage.setItem(STORE_KEY, JSON.stringify({ name: info.name, hair: info.look.hair, look: info.look }));
    } catch {
      /* プライベートモード等では保存しない */
    }
  }
}
