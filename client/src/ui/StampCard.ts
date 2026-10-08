import { map } from "../config";
import { stamps } from "../game/stamps";
import { starDataUrl } from "../game/starIcon";
import { loadStampSheet, stampFrame, stampIconUrl } from "../game/stampIcons";

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

/** 取得したときの通知を出しておく時間 */
const TOAST_MS = 2600;

/**
 * スタンプカード（DOM）: 画面左上のボタン(取得数)と、枠が並んだカード、取得時の通知。
 * リスナーはページで1回だけ張る（Hud / Talk と同じ理由）。枠はマップのキーアイテム数ぶん作る。
 */
export class StampCard {
  private static bound = false;
  private static current: StampCard | null = null;

  private btn = $<HTMLButtonElement>("stamp-btn");
  private card = $("stamp-card");
  private grid = $("stamp-grid");
  private toastEl = $("stamp-toast");
  private toastTimer = 0;
  private lit = starDataUrl(4);
  private dim = starDataUrl(4, true);

  constructor() {
    StampCard.current = this;
    if (!StampCard.bound) {
      StampCard.bound = true;
      $("stamp-btn").addEventListener("click", () => StampCard.current?.toggle());
      $("stamp-close").addEventListener("click", () => StampCard.current?.close());
      $("stamp-reset").addEventListener("click", () => {
        if (confirm("スタンプを全部消して、はじめからにします。よろしいですか？")) {
          stamps.reset();
          StampCard.current?.refresh();
          // 画面上のキーアイテムを戻すため、ページを読み込み直す
          location.reload();
        }
      });
    }
    this.card.hidden = true;
    this.toastEl.hidden = true;
    this.refresh();
    // 出店ごとの絵柄のシートが読み込めたら、枠を描き直す
    void loadStampSheet().then((img) => img && this.refresh());
  }

  /** その出店のスタンプの絵（取得済みは色つき、未取得はうす暗い影絵）。絵柄が無いときは星 */
  private iconUrl(icon: string | undefined, got: boolean): string {
    const f = stampFrame(icon);
    const u = f >= 0 ? stampIconUrl(f, 3, !got) : "";
    return u || (got ? this.lit : this.dim);
  }

  get isOpen(): boolean {
    return !this.card.hidden;
  }

  /** 枠と数字を今の取得状況に合わせて作り直す */
  refresh(): void {
    const items = map.keyItems ?? [];
    this.btn.hidden = items.length === 0;
    const n = stamps.count;
    this.btn.replaceChildren(Object.assign(new Image(), { src: this.lit, alt: "" }), `${n}/${items.length}`);
    $("stamp-count").textContent = `${n} / ${items.length}`;
    $("stamp-done").hidden = !(items.length > 0 && n === items.length);
    this.grid.replaceChildren(
      ...items.map((k, i) => {
        const got = stamps.has(k.id);
        const slot = document.createElement("div");
        slot.className = `stamp-slot${got ? " got" : ""}`;
        const img = new Image();
        img.src = this.iconUrl(k.icon, got);
        img.alt = "";
        const no = document.createElement("b");
        no.textContent = String(i + 1);
        const name = document.createElement("span");
        name.textContent = got ? (k.name ?? `スタンプ ${i + 1}`) : "？";
        slot.append(no, img, name);
        return slot;
      }),
    );
  }

  open(): void {
    this.refresh();
    this.card.hidden = false;
  }

  close(): void {
    this.card.hidden = true;
  }

  toggle(): void {
    if (this.isOpen) this.close();
    else this.open();
  }

  /** 新しく取得したときの通知＋カード更新 */
  collected(name: string | undefined, icon?: string): void {
    this.refresh();
    const left = stamps.total - stamps.count;
    this.toastEl.replaceChildren(
      Object.assign(new Image(), { src: this.iconUrl(icon, true), alt: "" }),
      Object.assign(document.createElement("div"), {
        textContent: left === 0 ? "コンプリート！ スタンプカードを見てみよう" : `スタンプ GET！${name ? "（" + name + "）" : ""}　あと ${left} 個`,
      }),
    );
    this.toastEl.hidden = false;
    window.clearTimeout(this.toastTimer);
    this.toastTimer = window.setTimeout(() => (this.toastEl.hidden = true), TOAST_MS);
  }

  /** シーン停止時の片付け */
  hide(): void {
    this.close();
    this.toastEl.hidden = true;
    window.clearTimeout(this.toastTimer);
  }
}
