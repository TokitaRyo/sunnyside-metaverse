import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { DATA_RETENTION_DAYS, KEY_ITEM_CLAIM_RANGE, RANKING_TOP, type RankRow, type Ranking as RankingPayload, type RtaDone } from "@metaverse/shared";
import { stats } from "./stats";

/**
 * ランキング（スタンプRTA・今日の出店めぐり）。
 *
 * スタンプRTA: 動き出した瞬間から、全部のスタンプを「この入室のなかで」集めきるまでの時間。
 *   ・スタンプの取得は、サーバーが確かめる（申告のとき、そのスタンプの近く(KEY_ITEM_CLAIM_RANGE)にいたか）。画面の申告の数だけでは、記録にならない。
 *   ・位置はサーバーが速度の上限つきで持っているので、瞬間移動では、速くならない（ただし、上限は走る速さの1.5倍まで許している。改造したクライアントなら、その分だけ有利になりうる）。
 *   ・1人（訪問者ID）につき、いちばん速い記録だけを載せる。名前は、入室のときに検査を通ったものだけ。
 * 今日の出店めぐり: サーバーが見ている「いた場所」（出店の区画）から数える。申告ではないので、ごまかせない。
 *
 * 保存先: 記録ファイル rta.json（stats と同じ保存先。Volume が無ければ再起動で消える）。保存期間は他の記録と同じ。
 */

const DAY_MS = 24 * 60 * 60 * 1000;

export interface RtaRecord {
  vid: string;
  name: string;
  ms: number;
  at: number;
}

interface Run {
  vid: string;
  name: string;
  /** 動き出した時刻（まだなら 0） */
  startedAt: number;
  claims: Set<string>;
  done: boolean;
  /** 入室した場所 */
  ox: number;
  oy: number;
}

/** 入室した場所から、これ(px)以上離れたら、動き出したとみなす */
const START_DIST = 3;

/** 出店めぐりで数える区画（広場は、入室した人が必ずいる場所なので、数えない） */
export const stallIdsOf = (areas: { id: string }[]): Set<string> => new Set(areas.filter((a) => a.id !== "plaza").map((a) => a.id));

export interface KeyItemPos {
  id: string;
  x: number;
  y: number;
}

export type ClaimResult = { kind: "ignored" } | { kind: "ok"; left: number } | { kind: "done"; done: RtaDone; announce: boolean; name: string };

class RankingBoard {
  private best = new Map<string, RtaRecord>();
  private runs = new Map<string, Run>();
  private sorted: RtaRecord[] | null = null;
  private tourCache: { at: number; rows: { vid: string; name: string; visited: number; stay: number }[] } | null = null;

  constructor() {
    this.load();
  }

  private file(): string {
    return join(stats.dir, "rta.json");
  }

  private load(): void {
    try {
      const p = this.file();
      if (!existsSync(p)) return;
      const limit = Date.now() - DATA_RETENTION_DAYS * DAY_MS;
      for (const r of JSON.parse(readFileSync(p, "utf8")) as RtaRecord[]) {
        if (r && typeof r.vid === "string" && typeof r.ms === "number" && typeof r.name === "string" && r.at >= limit) this.best.set(r.vid, r);
      }
    } catch {
      /* 読めなければ、空から始める */
    }
  }

  private save(): void {
    this.sorted = null;
    try {
      writeFileSync(this.file(), JSON.stringify([...this.best.values()]));
    } catch (e) {
      console.warn("[ranking] rta.json を書けません:", e);
    }
  }

  // ---------------------------------------------------------------- 入退室・動き出し
  join(sid: string, vid: string, name: string, x: number, y: number): void {
    this.runs.set(sid, { vid, name, startedAt: 0, claims: new Set(), done: false, ox: x, oy: y });
  }

  leave(sid: string): void {
    this.runs.delete(sid);
  }

  /** 位置が変わったときに呼ぶ。入室した場所から少し(START_DIST px)離れた最初の1回で、RTA が動き出す（動き出したら true）。送る座標の丸めでは、動き出さない */
  moved(sid: string, x: number, y: number, now = Date.now()): boolean {
    const r = this.runs.get(sid);
    if (!r || r.startedAt || Math.hypot(x - r.ox, y - r.oy) < START_DIST) return false;
    r.startedAt = now;
    return true;
  }

  /** 動き出してからの経過(ms)。まだなら -1 */
  elapsed(sid: string, now = Date.now()): number {
    const r = this.runs.get(sid);
    return r?.startedAt ? now - r.startedAt : -1;
  }

  // ---------------------------------------------------------------- スタンプの取得
  /** スタンプの取得の申告。その場所の近くにいたときだけ認める。全部そろったら、記録する */
  claim(sid: string, id: unknown, px: number, py: number, items: KeyItemPos[], now = Date.now()): ClaimResult {
    const r = this.runs.get(sid);
    if (!r || r.done || !r.startedAt || typeof id !== "string" || !items.length) return { kind: "ignored" };
    const item = items.find((k) => k.id === id);
    if (!item || r.claims.has(item.id)) return { kind: "ignored" };
    if (Math.hypot(px - item.x, py - item.y) > KEY_ITEM_CLAIM_RANGE) return { kind: "ignored" };
    r.claims.add(item.id);
    if (r.claims.size < items.length) return { kind: "ok", left: items.length - r.claims.size };

    // 全部そろった
    r.done = true;
    const ms = Math.max(1, now - r.startedAt);
    const prev = this.best.get(r.vid);
    const isBest = !prev || ms < prev.ms;
    if (isBest) {
      this.best.set(r.vid, { vid: r.vid, name: r.name, ms, at: now });
      this.save();
    }
    const bestMs = isBest ? ms : prev!.ms;
    const rank = this.rankOf(r.vid);
    // 全体に知らせるのは、上位に入った自己ベストだけ（毎回流すと、うるさいため）
    return { kind: "done", done: { ms, rank, best: isBest, bestMs }, announce: isBest && rank <= RANKING_TOP, name: r.name };
  }

  private rtaSorted(): RtaRecord[] {
    return (this.sorted ??= [...this.best.values()].sort((a, b) => a.ms - b.ms || a.at - b.at));
  }

  private rankOf(vid: string): number {
    const i = this.rtaSorted().findIndex((r) => r.vid === vid);
    return i < 0 ? 0 : i + 1;
  }

  // ---------------------------------------------------------------- 取り出し
  private tour(stallIds: Set<string>, now: number) {
    // 人数が多いときの負荷を避けるため、5秒はまとめて使い回す
    if (!this.tourCache || now - this.tourCache.at > 5000) this.tourCache = { at: now, rows: stats.tourBoard(stallIds, now) };
    return this.tourCache.rows;
  }

  /** 画面に出す形。vid を渡すと、その人の行に印を付け、自分の成績も付ける */
  snapshot(stallIds: Set<string>, vid?: string, top = RANKING_TOP, now = Date.now()): RankingPayload {
    const rta = this.rtaSorted();
    const tour = this.tour(stallIds, now);
    const rtaRows: RankRow[] = rta.slice(0, top).map((r, i) => ({ rank: i + 1, name: r.name, ms: r.ms, me: vid === r.vid }));
    const tourRows: RankRow[] = tour.slice(0, top).map((r, i) => ({ rank: i + 1, name: r.name, visited: r.visited, stay: r.stay, me: vid === r.vid }));
    let mine: RankingPayload["mine"];
    if (vid) {
      const mineRta = this.best.get(vid);
      const ti = tour.findIndex((r) => r.vid === vid);
      mine = { rtaMs: mineRta?.ms, rtaRank: mineRta ? this.rankOf(vid) : undefined, visited: ti < 0 ? 0 : tour[ti].visited, tourRank: ti < 0 ? undefined : ti + 1 };
    }
    return { rta: rtaRows, tour: tourRows, tourTotal: stallIds.size, mine, counts: { rta: rta.length, tour: tour.length }, at: now };
  }

  // ---------------------------------------------------------------- 削除
  deleteVisitor(vid: string): number {
    const had = this.best.delete(vid);
    if (had) this.save();
    this.tourCache = null;
    return had ? 1 : 0;
  }

  /** ランキングの記録を、すべて消す（RTA の記録。出店めぐりは、入退室の記録から数えるので、そちらの削除に従う） */
  resetRta(): number {
    const n = this.best.size;
    this.best.clear();
    this.save();
    return n;
  }
}

export const ranking = new RankingBoard();
