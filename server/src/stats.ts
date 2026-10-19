import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { DATA_RETENTION_DAYS } from "@metaverse/shared";

/**
 * 運営のための記録と集計（同意した人だけが対象）。
 *
 * 記録するもの: 入退室の時刻・滞在時間・出店ごとの滞在時間・スタンプの数・エモートの数・チャット本文。
 * 記録しないもの: IPアドレス・本名・位置の履歴（出店ごとの合計時間だけ）。
 * 保存先: DATA_DIR（無ければ /data があれば /data、なければ ./data）。1行1件の JSON（JSONL）で追記し、起動時に読み戻す。
 * 保存期間: DATA_RETENTION_DAYS（30日）を過ぎたものは、起動時と6時間ごとに消す。
 *
 * Fly.io の Volume を /data にマウントしないと、再起動・デプロイで消える（管理ページに「永続化されていない」と出す）。
 */

const DAY_MS = 24 * 60 * 60 * 1000;
/** メモリに持つ最大件数（保存期間内でも、これを超えたら古いものから捨てる） */
const MAX_CHAT = 30000;
const MAX_SESSIONS = 20000;
/** オンライン人数の記録の間隔 */
const SAMPLE_MS = 5 * 60 * 1000;

export interface Area {
  id: string;
  name: string;
}

export interface SessionRecord {
  sid: string;
  vid: string;
  name: string;
  hair: string;
  device: "touch" | "desktop";
  consent: string;
  joinedAt: number;
  leftAt: number;
  /** 滞在秒数 */
  stay: number;
  chats: number;
  emotes: number;
  stamps: number;
  stampTotal: number;
  /** 出店ごとの滞在秒数 */
  dwell: Record<string, number>;
}

interface ActiveSession extends Omit<SessionRecord, "leftAt" | "stay"> {
  area: string;
}

export interface ChatRecord {
  id: number;
  t: number;
  sid: string;
  vid: string;
  name: string;
  text: string;
  /** chat=参加者, system=運営のおしらせ */
  kind: "chat" | "system";
}

export interface SamplePoint {
  t: number;
  n: number;
}

function resolveDir(): string {
  if (process.env.DATA_DIR) return process.env.DATA_DIR;
  return existsSync("/data") ? "/data" : join(process.cwd(), "data");
}

class Stats {
  readonly dir = resolveDir();
  /** /data を使っているか（Volume が付いていれば永続化される見込み） */
  readonly persistent = this.dir === "/data" || !!process.env.DATA_DIR;
  readonly startedAt = Date.now();

  private active = new Map<string, ActiveSession>();
  private sessions: SessionRecord[] = [];
  private chat: ChatRecord[] = [];
  private samples: SamplePoint[] = [];
  private chatSeq = 1;
  private peak = 0;
  private peakAt = 0;
  private lastSample = 0;
  private enabled = true;

  constructor() {
    try {
      mkdirSync(this.dir, { recursive: true });
    } catch (e) {
      console.warn("[stats] 保存先を作れません。記録はメモリだけになります:", e);
      this.enabled = false;
    }
    this.load();
    this.prune();
    setInterval(() => this.prune(), 6 * 60 * 60 * 1000).unref();
    // 終了時に、入室中の人のぶんも記録する
    const flush = () => {
      this.finishAll();
    };
    process.once("SIGTERM", flush);
    process.once("SIGINT", flush);
  }

  // ---------------------------------------------------------------- 保存と読み込み
  private file(name: string): string {
    return join(this.dir, name);
  }

  private append(name: string, obj: unknown): void {
    if (!this.enabled) return;
    try {
      appendFileSync(this.file(name), JSON.stringify(obj) + "\n");
    } catch (e) {
      console.warn(`[stats] ${name} に書けません:`, e);
    }
  }

  private readLines<T>(name: string): T[] {
    const p = this.file(name);
    if (!this.enabled || !existsSync(p)) return [];
    const out: T[] = [];
    for (const line of readFileSync(p, "utf8").split("\n")) {
      if (!line) continue;
      try {
        out.push(JSON.parse(line) as T);
      } catch {
        /* 壊れた行は飛ばす */
      }
    }
    return out;
  }

  private load(): void {
    this.sessions = this.readLines<SessionRecord>("sessions.jsonl");
    this.chat = this.readLines<ChatRecord>("chat.jsonl");
    this.samples = this.readLines<SamplePoint>("online.jsonl");
    this.chatSeq = this.chat.reduce((m, c) => Math.max(m, c.id), 0) + 1;
    for (const s of this.samples) {
      if (s.n > this.peak) {
        this.peak = s.n;
        this.peakAt = s.t;
      }
    }
    console.log(`[stats] 読み込み: セッション ${this.sessions.length} 件、チャット ${this.chat.length} 件（保存先 ${this.dir}）`);
  }

  /** 保存期間を過ぎたものを消し、ファイルを書き直す */
  prune(): void {
    const limit = Date.now() - DATA_RETENTION_DAYS * DAY_MS;
    const s0 = this.sessions.length, c0 = this.chat.length, o0 = this.samples.length;
    this.sessions = this.sessions.filter((s) => s.leftAt >= limit).slice(-MAX_SESSIONS);
    this.chat = this.chat.filter((c) => c.t >= limit).slice(-MAX_CHAT);
    this.samples = this.samples.filter((p) => p.t >= limit);
    if (s0 !== this.sessions.length || c0 !== this.chat.length || o0 !== this.samples.length) this.rewrite();
  }

  private rewrite(): void {
    if (!this.enabled) return;
    try {
      writeFileSync(this.file("sessions.jsonl"), this.sessions.map((s) => JSON.stringify(s)).join("\n") + (this.sessions.length ? "\n" : ""));
      writeFileSync(this.file("chat.jsonl"), this.chat.map((s) => JSON.stringify(s)).join("\n") + (this.chat.length ? "\n" : ""));
      writeFileSync(this.file("online.jsonl"), this.samples.map((s) => JSON.stringify(s)).join("\n") + (this.samples.length ? "\n" : ""));
    } catch (e) {
      console.warn("[stats] 書き直しに失敗:", e);
    }
  }

  // ---------------------------------------------------------------- 記録
  join(sid: string, info: { vid: string; name: string; hair: string; device: "touch" | "desktop"; consent: string }): void {
    this.active.set(sid, {
      sid,
      vid: info.vid,
      name: info.name,
      hair: info.hair,
      device: info.device,
      consent: info.consent,
      joinedAt: Date.now(),
      chats: 0,
      emotes: 0,
      stamps: 0,
      stampTotal: 0,
      dwell: {},
      area: "",
    });
    this.sample(true);
  }

  leave(sid: string): void {
    const a = this.active.get(sid);
    if (!a) return;
    this.active.delete(sid);
    const { area: _area, ...rest } = a;
    void _area;
    const now = Date.now();
    const rec: SessionRecord = { ...rest, leftAt: now, stay: Math.round((now - a.joinedAt) / 1000) };
    this.sessions.push(rec);
    this.append("sessions.jsonl", rec);
  }

  private finishAll(): void {
    for (const sid of [...this.active.keys()]) this.leave(sid);
  }

  addChat(sid: string, name: string, text: string, kind: "chat" | "system" = "chat"): void {
    const a = this.active.get(sid);
    if (a && kind === "chat") a.chats++;
    const rec: ChatRecord = { id: this.chatSeq++, t: Date.now(), sid, vid: a?.vid ?? "", name, text, kind };
    this.chat.push(rec);
    if (this.chat.length > MAX_CHAT) this.chat.shift();
    this.append("chat.jsonl", rec);
  }

  emote(sid: string): void {
    const a = this.active.get(sid);
    if (a) a.emotes++;
  }

  stamps(sid: string, count: number, total: number): void {
    const a = this.active.get(sid);
    if (!a || !Number.isFinite(count) || !Number.isFinite(total)) return;
    a.stampTotal = Math.max(0, Math.min(200, Math.floor(total)));
    a.stamps = Math.max(0, Math.min(a.stampTotal, Math.floor(count)));
  }

  /** 1秒ごとに呼ぶ。いまの位置から、出店ごとの滞在秒数を足す */
  tick(positions: { sid: string; areaId: string }[]): void {
    for (const p of positions) {
      const a = this.active.get(p.sid);
      if (!a) continue;
      a.area = p.areaId;
      if (p.areaId) a.dwell[p.areaId] = (a.dwell[p.areaId] ?? 0) + 1;
    }
    this.sample(false);
  }

  /** オンライン人数の推移（5分ごと）とピークを記録する */
  private sample(force: boolean): void {
    const now = Date.now();
    const n = this.active.size;
    if (n > this.peak) {
      this.peak = n;
      this.peakAt = now;
    }
    if (!force && now - this.lastSample < SAMPLE_MS) return;
    if (force && now - this.lastSample < 20000) return;
    this.lastSample = now;
    const pt: SamplePoint = { t: now, n };
    this.samples.push(pt);
    this.append("online.jsonl", pt);
  }

  // ---------------------------------------------------------------- 削除（本人の求め・運営の判断）
  deleteVisitor(vid: string): { sessions: number; chats: number } {
    const s0 = this.sessions.length, c0 = this.chat.length;
    this.sessions = this.sessions.filter((s) => s.vid !== vid);
    this.chat = this.chat.filter((c) => c.vid !== vid);
    this.rewrite();
    return { sessions: s0 - this.sessions.length, chats: c0 - this.chat.length };
  }

  purgeAll(): void {
    this.sessions = [];
    this.chat = [];
    this.samples = [];
    this.peak = this.active.size;
    this.rewrite();
  }

  // ---------------------------------------------------------------- 取り出し（管理ページ用）
  onlineList(now = Date.now()) {
    return [...this.active.values()].map((a) => ({
      sid: a.sid,
      vid: a.vid,
      name: a.name,
      device: a.device,
      stay: Math.round((now - a.joinedAt) / 1000),
      area: a.area,
      stamps: a.stamps,
      stampTotal: a.stampTotal,
      chats: a.chats,
    }));
  }

  recentSessions(limit: number): SessionRecord[] {
    return this.sessions.slice(-limit).reverse();
  }

  chatLog(opts: { limit: number; beforeId?: number; q?: string; vid?: string }): ChatRecord[] {
    const q = opts.q?.toLowerCase();
    const out: ChatRecord[] = [];
    for (let i = this.chat.length - 1; i >= 0 && out.length < opts.limit; i--) {
      const c = this.chat[i];
      if (opts.beforeId !== undefined && c.id >= opts.beforeId) continue;
      if (opts.vid && c.vid !== opts.vid) continue;
      if (q && !(c.text.toLowerCase().includes(q) || c.name.toLowerCase().includes(q))) continue;
      out.push(c);
    }
    return out;
  }

  allChat(): ChatRecord[] {
    return this.chat;
  }
  allSessions(): SessionRecord[] {
    return this.sessions;
  }

  /** 集計。いま入室中の人も、滞在中として含める */
  summary(areas: Area[], now = Date.now()) {
    const act = [...this.active.values()];
    const all: (SessionRecord | (ActiveSession & { leftAt: number; stay: number }))[] = [
      ...this.sessions,
      ...act.map((a) => ({ ...a, leftAt: now, stay: Math.round((now - a.joinedAt) / 1000) })),
    ];
    const jst = (t: number) => new Date(t + 9 * 3600 * 1000);
    const dayKey = (t: number) => jst(t).toISOString().slice(0, 10);
    const hourKey = (t: number) => jst(t).toISOString().slice(0, 13);
    const today = dayKey(now);

    const visitors = new Map<string, number>(); // vid -> 入室回数
    for (const s of all) visitors.set(s.vid, (visitors.get(s.vid) ?? 0) + 1);
    const stays = all.map((s) => s.stay).sort((a, b) => a - b);
    const sum = stays.reduce((m, v) => m + v, 0);
    const pct = (p: number) => (stays.length ? stays[Math.min(stays.length - 1, Math.floor(stays.length * p))] : 0);

    // 滞在時間の分布
    const buckets = [
      { label: "1分未満", max: 60 },
      { label: "1〜3分", max: 180 },
      { label: "3〜10分", max: 600 },
      { label: "10〜30分", max: 1800 },
      { label: "30分以上", max: Infinity },
    ].map((b) => ({ label: b.label, n: 0, max: b.max }));
    for (const v of stays) {
      const b = buckets.find((x) => v < x.max);
      if (b) b.n++;
    }

    // 日ごと・時間ごと
    const daily = new Map<string, { sessions: number; vids: Set<string> }>();
    const hourly = new Map<string, number>();
    for (const s of all) {
      const d = daily.get(dayKey(s.joinedAt)) ?? { sessions: 0, vids: new Set() };
      d.sessions++;
      d.vids.add(s.vid);
      daily.set(dayKey(s.joinedAt), d);
      hourly.set(hourKey(s.joinedAt), (hourly.get(hourKey(s.joinedAt)) ?? 0) + 1);
    }

    // 出店ごと
    const stalls = areas.map((a) => {
      let secs = 0;
      const v = new Set<string>();
      for (const s of all) {
        const d = s.dwell[a.id];
        if (d) {
          secs += d;
          v.add(s.vid);
        }
      }
      return { id: a.id, name: a.name, visitors: v.size, seconds: secs, avg: v.size ? Math.round(secs / v.size) : 0 };
    });

    // スタンプ
    const complete = all.filter((s) => s.stampTotal > 0 && s.stamps >= s.stampTotal);
    const completeVids = new Set(complete.map((s) => s.vid));
    const stampBuckets = new Map<number, number>();
    for (const s of all) stampBuckets.set(s.stamps, (stampBuckets.get(s.stamps) ?? 0) + 1);

    const devices = { touch: 0, desktop: 0 };
    for (const s of all) devices[s.device]++;

    const todaySessions = all.filter((s) => dayKey(s.joinedAt) === today);
    return {
      now,
      startedAt: this.startedAt,
      online: act.length,
      peak: { n: this.peak, at: this.peakAt },
      storage: { dir: this.dir, persistent: this.persistent, enabled: this.enabled, retentionDays: DATA_RETENTION_DAYS },
      totals: {
        sessions: all.length,
        visitors: visitors.size,
        returning: [...visitors.values()].filter((n) => n > 1).length,
        avgStay: stays.length ? Math.round(sum / stays.length) : 0,
        medianStay: pct(0.5),
        p90Stay: pct(0.9),
        chats: this.chat.filter((c) => c.kind === "chat").length,
        emotes: all.reduce((m, s) => m + s.emotes, 0),
        completed: completeVids.size,
        todaySessions: todaySessions.length,
        todayVisitors: new Set(todaySessions.map((s) => s.vid)).size,
      },
      stayBuckets: buckets.map(({ label, n }) => ({ label, n })),
      daily: [...daily.entries()].sort().map(([date, d]) => ({ date, sessions: d.sessions, visitors: d.vids.size })),
      hourly: [...hourly.entries()].sort().slice(-48).map(([hour, joins]) => ({ hour, joins })),
      online24h: this.samples.filter((p) => p.t >= now - DAY_MS),
      stalls,
      stampDist: [...stampBuckets.entries()].sort((a, b) => a[0] - b[0]).map(([stamps, n]) => ({ stamps, n })),
      devices,
    };
  }
}

export const stats = new Stats();
