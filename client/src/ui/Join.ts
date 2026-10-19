import { HAIRS, NAME_MAX, type Hair } from "@metaverse/shared";
import { humanLayers } from "../game/assets";
import { DIVE_FADE_AT_MS } from "./intro";
import { hasConsented, saveConsent, visitorId } from "../game/visitor";
import { renderTerms } from "./terms";

const HAIR_LABEL: Record<Hair, string> = {
  bowlhair: "ボウル",
  curlyhair: "カール",
  longhair: "ロング",
  mophair: "モップ",
  shorthair: "ショート",
  spikeyhair: "ツンツン",
};

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const STORE_KEY = "sunnyside.profile";

export interface JoinInfo {
  name: string;
  hair: Hair;
}

/** 入室画面（名前＋髪型6種）。読み込み進捗も表示する。 */
export class JoinScreen {
  private hair: Hair = HAIRS[Math.floor(Math.random() * HAIRS.length)];
  private loaded = false;
  private busy = false;
  private consent = false;
  onSubmit?: (info: JoinInfo) => void;

  constructor() {
    const saved = this.restore();
    if (saved?.hair && (HAIRS as readonly string[]).includes(saved.hair)) this.hair = saved.hair;
    const nameEl = $<HTMLInputElement>("join-name");
    nameEl.value = saved?.name ?? "";

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
        this.hair = h;
        this.refresh();
      });
      grid.append(btn);
    }
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
      this.persist({ name, hair: this.hair });
      this.setBusy(true);
      this.onSubmit?.({ name, hair: this.hair });
    });
  }

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
      btn.textContent = "入室する";
    }
  }

  setBusy(busy: boolean): void {
    this.busy = busy;
    if (busy) $("join-error").hidden = true;
    this.updateButton();
  }

  showError(msg: string): void {
    const el = $("join-error");
    el.textContent = msg;
    el.hidden = false;
    this.setBusy(false);
  }

  hide(): void {
    this.clearDive();
    $("join").hidden = true;
  }

  /**
   * 入室の演出: パネルとロゴが消え、惑星に向かって急降下し、ゲーム画面（上空からの映像）へ溶け込む。
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
    this.setBusy(false);
    $("join-error").hidden = true;
    const el = $("join");
    el.classList.remove("dive", "out");
    el.hidden = false;
  }

  private diveTimers: number[] = [];

  private refresh(): void {
    document.querySelectorAll<HTMLElement>(".hair-opt").forEach((el) => {
      el.setAttribute("aria-checked", String(el.dataset.hair === this.hair));
    });
  }

  private restore(): Partial<JoinInfo> | null {
    try {
      return JSON.parse(localStorage.getItem(STORE_KEY) ?? "null");
    } catch {
      return null;
    }
  }

  private persist(info: JoinInfo): void {
    try {
      localStorage.setItem(STORE_KEY, JSON.stringify(info));
    } catch {
      /* プライベートモード等では保存しない */
    }
  }
}
