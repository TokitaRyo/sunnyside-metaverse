import type { NpcDef } from "../config";

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

/** 文字を1つずつ出す速さ（文字/秒） */
const CHARS_PER_SEC = 45;

/**
 * NPCとの会話UI（DOM）: 近づいたときの「話す」ボタンと、画面下の会話ウィンドウ。
 * リスナーはページで1回だけ張り、常に最新の持ち主(WorldScene)へ委譲する（Hud と同じ理由）。
 */
export class Talk {
  private static bound = false;
  private static current: Talk | null = null;

  private prompt = $<HTMLButtonElement>("talk-prompt");
  private box = $("talk-box");
  private nameEl = $("talk-name");
  private textEl = $("talk-text");
  private page = 0;
  private npc: NpcDef | null = null;
  private timer = 0;
  private shown = 0;

  constructor(private cb: { onPrompt(): void; onAdvance(): void }) {
    Talk.current = this;
    if (!Talk.bound) {
      Talk.bound = true;
      // pointerdown で拾う（click だと、ボタンが出る/消えるタイミングによっては取りこぼす）
      $("talk-prompt").addEventListener("pointerdown", (e) => {
        e.preventDefault();
        Talk.current?.cb.onPrompt();
      });
      $("talk-box").addEventListener("pointerdown", (e) => {
        e.preventDefault();
        Talk.current?.cb.onAdvance();
      });
    }
    this.reset();
  }

  get isOpen(): boolean {
    return this.npc !== null;
  }

  /** 近くに話せる相手がいるとき、ボタンを出す（label=相手の名前） */
  setPrompt(label: string | null): void {
    if (label === null || this.isOpen) {
      this.prompt.hidden = true;
      return;
    }
    const text = label ? `💬 ${label}と話す (E)` : "💬 話す (E)";
    if (this.prompt.textContent !== text) this.prompt.textContent = text;
    this.prompt.hidden = false;
  }

  open(npc: NpcDef): void {
    const lines = npc.lines.filter((t) => t.trim());
    this.npc = { name: npc.name, lines: lines.length ? lines : ["……"] };
    this.page = 0;
    this.nameEl.textContent = npc.name ?? "";
    this.nameEl.hidden = !npc.name;
    this.prompt.hidden = true;
    this.box.hidden = false;
    this.showPage();
  }

  /** 次へ。文字が出ている途中なら全文を出すだけ。最後のページなら閉じる */
  advance(): void {
    if (!this.npc) return;
    if (this.shown < this.npc.lines[this.page].length) {
      this.shown = this.npc.lines[this.page].length;
      this.textEl.textContent = this.npc.lines[this.page];
      this.stopTimer();
      this.updateHint();
      return;
    }
    if (this.page + 1 >= this.npc.lines.length) {
      this.close();
      return;
    }
    this.page++;
    this.showPage();
  }

  close(): void {
    this.reset();
  }

  private reset(): void {
    this.stopTimer();
    this.npc = null;
    this.box.hidden = true;
    this.prompt.hidden = true;
  }

  private stopTimer(): void {
    if (this.timer) window.clearInterval(this.timer);
    this.timer = 0;
  }

  private showPage(): void {
    const text = this.npc!.lines[this.page];
    this.stopTimer();
    this.shown = 0;
    this.textEl.textContent = "";
    this.updateHint();
    const start = performance.now();
    this.timer = window.setInterval(() => {
      this.shown = Math.min(text.length, Math.ceil(((performance.now() - start) / 1000) * CHARS_PER_SEC));
      this.textEl.textContent = text.slice(0, this.shown);
      if (this.shown >= text.length) {
        this.stopTimer();
        this.updateHint();
      }
    }, 30);
  }

  private updateHint(): void {
    const n = this.npc!;
    const done = this.shown >= n.lines[this.page].length;
    const last = this.page + 1 >= n.lines.length;
    $("talk-hint").textContent = !done ? "" : last ? "▼ とじる (E)" : `▼ つぎへ (E)  ${this.page + 1}/${n.lines.length}`;
  }
}
