import type { RankRow, Ranking, RtaDone } from "@metaverse/shared";
import { stamps } from "../game/stamps";
import { sfx } from "../game/sfx";

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

/** 開いているあいだ、ランキングを聞き直す間隔 */
const POLL_MS = 10000;
/** RTA を終えたあと、タイマーを出しておく時間 */
const TIMER_KEEP_MS = 10000;

/** ミリ秒を「1:23.4」の形に */
export function fmtMs(ms: number): string {
  const s = ms / 1000;
  const m = Math.floor(s / 60);
  return `${m}:${(s - m * 60).toFixed(1).padStart(4, "0")}`;
}
const fmtStay = (sec: number) => (sec >= 3600 ? `${Math.floor(sec / 3600)}時間${Math.floor((sec % 3600) / 60)}分` : `${Math.max(1, Math.round(sec / 60))}分`);

type Tab = "rta" | "tour";

/**
 * ランキング（DOM）: 左上の 🏆 ボタン、スタンプRTAのタイマー、ランキングのカード。
 * ・スタンプRTA: 動き出した瞬間から、スタンプを全部（はじめから）集めきるまでの速さ。取得はサーバーが確かめる。
 * ・今日の出店めぐり: 訪れた出店の数（サーバーが、いた場所から数える）。
 * 名前は textContent で出す（書かれた HTML は動かない）。リスナーはページで1回だけ張る（StampCard と同じ理由）。
 */
export class RankingPanel {
  private static bound = false;
  private static current: RankingPanel | null = null;

  private btn = $<HTMLButtonElement>("rank-btn");
  private card = $("rank-card");
  private list = $("rank-list");
  private mineEl = $("rank-mine");
  private resultEl = $("rank-result");
  private hintEl = $("rank-hint");
  private timerEl = $("rank-timer");
  private tabBtns = [...document.querySelectorAll<HTMLButtonElement>("#rank-tabs button")];
  private tab: Tab = "rta";
  private data: Ranking | null = null;
  private poll = 0;
  private tick = 0;
  /** RTA の計測中の開始時刻（このブラウザの時計。表示用。記録はサーバーが取る）。0 なら計測していない */
  private runStart = 0;
  private hideTimer = 0;

  constructor(private request: () => void) {
    RankingPanel.current = this;
    if (!RankingPanel.bound) {
      RankingPanel.bound = true;
      $("rank-btn").addEventListener("click", () => RankingPanel.current?.toggle());
      $("rank-close").addEventListener("click", () => RankingPanel.current?.close());
      document.querySelectorAll<HTMLButtonElement>("#rank-tabs button").forEach((b) =>
        b.addEventListener("click", () => RankingPanel.current?.setTab(b.dataset.tab === "tour" ? "tour" : "rta")),
      );
    }
    this.btn.hidden = false;
    this.card.hidden = true;
    this.timerEl.hidden = true;
    this.resultEl.hidden = true;
    this.render();
  }

  get isOpen(): boolean {
    return !this.card.hidden;
  }

  open(): void {
    this.card.hidden = false;
    this.request();
    window.clearInterval(this.poll);
    this.poll = window.setInterval(() => this.request(), POLL_MS);
    this.render();
  }

  close(): void {
    this.card.hidden = true;
    window.clearInterval(this.poll);
    this.poll = 0;
  }

  toggle(): void {
    if (this.isOpen) this.close();
    else this.open();
  }

  private setTab(t: Tab): void {
    this.tab = t;
    this.render();
  }

  /** サーバーからのランキング */
  update(r: Ranking): void {
    this.data = r;
    this.render();
  }

  // ---------------------------------------------------------------- RTA のタイマー
  /** サーバーが「動き出した」と知らせた。はじめからの人（スタンプ0個）だけ、タイマーを出す */
  rtaStart(): void {
    window.clearTimeout(this.hideTimer);
    if (stamps.count > 0 || stamps.total === 0) {
      this.runStart = 0;
      this.timerEl.hidden = true;
      return;
    }
    this.runStart = Date.now();
    this.timerEl.classList.remove("done");
    this.timerEl.hidden = false;
    window.clearInterval(this.tick);
    this.tick = window.setInterval(() => this.paintTimer(), 100);
    this.paintTimer();
  }

  private paintTimer(): void {
    if (this.runStart) this.timerEl.textContent = `⏱ ${fmtMs(Date.now() - this.runStart)}`;
  }

  /** サーバーが、RTA の結果を知らせた */
  rtaDone(d: RtaDone): void {
    window.clearInterval(this.tick);
    this.tick = 0;
    this.runStart = 0;
    this.timerEl.textContent = `⏱ ${fmtMs(d.ms)}`;
    this.timerEl.classList.add("done");
    this.timerEl.hidden = false;
    window.clearTimeout(this.hideTimer);
    this.hideTimer = window.setTimeout(() => (this.timerEl.hidden = true), TIMER_KEEP_MS);
    this.resultEl.hidden = false;
    this.resultEl.textContent = d.best
      ? `🎉 スタンプRTA ${fmtMs(d.ms)}！ 自己ベスト更新・いまのランキング ${d.rank}位`
      : `スタンプRTA ${fmtMs(d.ms)}（自己ベストは ${fmtMs(d.bestMs)}・${d.rank}位）`;
    this.tab = "rta";
    sfx.complete();
    this.open();
  }

  // ---------------------------------------------------------------- 描画
  private render(): void {
    this.tabBtns.forEach((b) => b.classList.toggle("on", b.dataset.tab === this.tab));
    const d = this.data;
    const rows: RankRow[] = !d ? [] : this.tab === "rta" ? d.rta : d.tour;
    this.list.replaceChildren(
      ...(rows.length
        ? rows.map((r) => {
            const li = document.createElement("li");
            if (r.me) li.className = "me";
            const no = document.createElement("b");
            no.textContent = r.rank <= 3 ? ["🥇", "🥈", "🥉"][r.rank - 1] : String(r.rank);
            const name = document.createElement("span");
            name.className = "nm";
            name.textContent = r.name;
            const val = document.createElement("em");
            val.textContent = this.tab === "rta" ? fmtMs(r.ms ?? 0) : `${r.visited ?? 0}/${d?.tourTotal ?? 0} か所${r.stay ? `・${fmtStay(r.stay)}` : ""}`;
            li.append(no, name, val);
            return li;
          })
        : [Object.assign(document.createElement("li"), { className: "empty", textContent: d ? (this.tab === "rta" ? "まだ だれも コンプリートしていません。いちばん乗りを めざそう！" : "まだ 記録がありません。出店に近づいてみよう！") : "読み込み中…" })]),
    );
    const m = d?.mine;
    if (this.tab === "rta") {
      this.mineEl.textContent = m?.rtaMs ? `あなたの自己ベスト: ${fmtMs(m.rtaMs)}（${m.rtaRank}位 / ${d?.counts.rta}人）` : "あなたの記録は まだありません";
      this.hintEl.textContent = "動き出した瞬間から、スタンプを全部、はじめから集めきるまでの速さ。やり直すときは、スタンプカードの「はじめから」を押してね。";
    } else {
      this.mineEl.textContent = m ? `あなた: ${m.visited}/${d?.tourTotal} か所${m.tourRank ? `（${m.tourRank}位 / ${d?.counts.tour}人）` : ""}` : "";
      this.hintEl.textContent = "今日、訪れた出店の数（すこし立ち止まった場所だけ数えます）。同じ数なら、長くいた人が上。";
    }
  }

  /** シーン停止時の片付け */
  hide(): void {
    this.close();
    this.btn.hidden = true;
    this.timerEl.hidden = true;
    window.clearInterval(this.tick);
    window.clearTimeout(this.hideTimer);
  }
}
