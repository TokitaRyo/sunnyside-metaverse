import { CHAT_MAX, PHRASES, type ModNotice } from "@metaverse/shared";
import { isLocalAddress } from "./geoblock";

/**
 * 自動の荒らし対策（運営がずっと見ていなくても、機能するように）。3つの層で守る:
 *  1. 荒らしが得をしない作り … 名前の検査と予約語、新しい人はすぐには書けない、連絡先・URL は送れない、連投・同じ文は止める
 *  2. 自動で止める … 違反の点数（たまると、チャットを10分→1時間→その日の終わりまで止める）、全体の安全装置（違反が急に増えたら、定型文だけにする）
 *  3. 参加者が自分で守れる … 通報（別々の3人から → 自動でチャット停止）。ブロックは、各自の画面だけで動く（クライアント側）
 * ここは「判断」だけを持つ。部屋の状態を触る処理（切断・配信）は MainRoom がやる。
 */

// ---------------------------------------------------------------- 設定（環境変数で変えられる）
const num = (name: string, d: number): number => {
  const n = Number(process.env[name]);
  return Number.isFinite(n) && n > 0 ? n : d;
};
/** 入室してから、この時間(ms)は書き込めない（スタンプを1つ取れば、すぐ書ける）。使い捨てのボット・入り直しの荒らしへの、安上がりな手間 */
export const NEWCOMER_MS = num("MOD_NEWCOMER_SEC", 15) * 1000;
/** 書き込みの間隔(ms) */
export const CHAT_GAP_MS = num("MOD_CHAT_GAP_SEC", 3) * 1000;
/** 違反の点数が、この窓(ms)のうちに、この点数に達したら、チャットを止める */
const STRIKE_WINDOW_MS = 10 * 60 * 1000;
const STRIKE_LIMIT = num("MOD_STRIKE_LIMIT", 3);
/** 止める時間: 1回目10分、2回目1時間、3回目以降はその日の終わりまで（12時間） */
const MUTE_STEPS_MS = [10 * 60 * 1000, 60 * 60 * 1000, 12 * 60 * 60 * 1000];
/** 重い違反（2回目以降）のとき、同じ回線にも、この時間(ms)の止めを付ける。履歴を消して入り直す荒らし対策（会場の Wi-Fi など共有の回線への巻き添えを減らすため、短く、重いときだけ） */
const IP_MUTE_MS = 30 * 60 * 1000;
/** 全体の安全装置: 直近1分に、違反がこれだけ起きたら、全員のチャットを定型文だけにする */
const BREAKER_THRESHOLD = num("MOD_BREAKER_THRESHOLD", 10);
const BREAKER_WINDOW_MS = 60 * 1000;
/** 安全装置が働くには、違反が、この人数以上の「別々の人」から出ている必要がある（1人の荒らしが、全員のチャットを止められないように） */
const BREAKER_MIN_PEOPLE = num("MOD_BREAKER_MIN_PEOPLE", 3);
const BREAKER_MS = num("MOD_BREAKER_SEC", 5 * 60) * 1000;
/** 同じ回線からの入室は、1分にこの回数まで */
const JOIN_PER_MIN = num("MOD_JOIN_PER_MIN", 10);
/** 運営が退室させた人が、入り直せるまでの時間(ms) */
const KICK_COOLDOWN_MS = 2 * 60 * 1000;
/** エモートの間隔(ms) */
const EMOTE_GAP_MS = 1000;
/** 通報: 別々のこの人数から、この時間(ms)のうちに通報されたら、自動で止める */
const REPORT_NEEDED = num("MOD_REPORT_NEEDED", 3);
const REPORT_WINDOW_MS = 5 * 60 * 1000;
/** 1人が出せる通報は、10分に3回まで。入室から30秒たっていない人の通報は、数えない */
const REPORT_PER_USER = 3;
const REPORTER_MIN_MS = num("MOD_REPORTER_MIN_SEC", 30) * 1000;

/** 試験のときだけ、手元(localhost)の接続にも、回線ごとの制限を適用する */
const STRICT_LOCAL = process.env.MOD_STRICT_LOCAL === "1";
const ipExempt = (ip: string): boolean => !STRICT_LOCAL && (!ip || isLocalAddress(ip));

// ---------------------------------------------------------------- 文字の整え
/* eslint-disable no-control-regex */
const CONTROL = /[\u0000-\u001f\u007f]/g;
/** 見えない文字・向きを変える文字（名前や発言を、空に見せたり、並びをごまかしたりするのに使われる） */
const INVISIBLE = /[­​-‏‪-‮⁠-⁯﻿]/g;

/** 制御文字と見えない文字を取り除き、前後の空白を削って、文字数の上限で切る */
export function cleanText(text: unknown, max: number): string {
  if (typeof text !== "string") return "";
  return Array.from(text.replace(CONTROL, " ").replace(INVISIBLE, "").trim()).slice(0, max).join("");
}

/**
 * 検査用の形にそろえる: 全角・半角をそろえ、小文字にし、カタカナをひらがなにし、文字と数字以外（空白・記号・絵文字・長音）を全部除く。
 * 「死 ね」「し・ね」「シ－ネ」のような、すき間や記号を入れた言い換えを、見つけるため。
 */
export function norm(s: string): string {
  return s
    .normalize("NFKC")
    .toLowerCase()
    .replace(INVISIBLE, "")
    .replace(/[ァ-ヶ]/g, (c) => String.fromCharCode(c.charCodeAt(0) - 0x60))
    .replace(/ー/g, "")
    .replace(/[^\p{L}\p{N}]/gu, "");
}

// ---------------------------------------------------------------- NGワード
// 簡易NGワード（共有画面に映る展示のため、暴言・脅迫・差別語・下ネタ）。完全なモニタリングではない。このリストに足すだけで対象を増やせる。
const NG_WORDS = [
  "死ね", "しね", "殺す", "ころす", "きもい", "キモイ", "うざい", "ウザイ", "消えろ", "きえろ", "ばか", "バカ",
  "fuck", "shit", "bitch", "asshole", "cunt", "nigger", "faggot", "kill you",
  // 下ネタ・性的な語
  "セックス", "せっくす", "sex", "エッチ", "えっち", "エロ", "えろ", "hentai", "porn",
  "ちんこ", "ちんちん", "チンコ", "まんこ", "マンコ", "おっぱい", "パイパン", "レイプ", "強姦", "痴漢", "オナニー", "せんずり",
  "フェラ", "クンニ", "ペニス", "ヴァギナ", "陰茎", "陰部", "童貞", "変態", "ロリコン",
];
// 「ばか」「うざい」「きもい」などは、軽い言葉で、ふつうの文にも混ざりやすいので、そのまま入っているものを伏字にするだけにして、すき間をごまかした言い換えの検出（evasionHit）には使わない
// （「はげます」「かすてら」のような、ふつうの語を巻き込みやすい語は、そもそもリストに入れていない）
const SOFT = new Set(["ばか", "バカ", "うざい", "ウザイ", "きもい", "キモイ"]);
const esc = (w: string) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const NG_RE = new RegExp(NG_WORDS.map(esc).join("|"), "gi");
const NG_NORM = NG_WORDS.filter((w) => !SOFT.has(w)).map(norm).filter((w) => w.length >= 2);

/** 見つけた NG ワードを、伏字（＊）にする。全角・半角はそろえる */
function maskNg(text: string): { text: string; hits: number } {
  let hits = 0;
  const out = text.normalize("NFKC").replace(NG_RE, (m) => {
    hits++;
    return "＊".repeat(m.length);
  });
  return { text: out, hits };
}
/** すき間・記号・かなの種類を変えた NG ワード（「し ね」など）が残っているか */
function evasionHit(maskedText: string): boolean {
  const n = norm(maskedText);
  return NG_NORM.some((w) => n.includes(w));
}

// ---------------------------------------------------------------- 連絡先・URL（子どもが参加するので、聞き出し・書き込みを止める）
const SERVICES_LATIN = /(?<![a-z])(line|discord|insta(gram)?|twitter|tiktok|kakao(talk)?|snap(chat)?|telegram|whatsapp|skype)(?![a-z])/;
const SERVICES_KANA = /(らいん|いんすた|ついった|つぃった|でぃすこ|てぃっくとっく|かかお|すなち|すなっぷ|てれぐらむ|すかいぷ)/;
// norm() で、カタカナはひらがな・長音は除かれた形に対して使う（「でーえむ」は「でえむ」になる）。漢字のものも入れる
const EXCHANGE = /(こうかん|交換|おしえ|教え|ついか|追加|ふぉろ|あど|あいでぃ|でえむ|だいれくと|やろ|やらな|おくっ|おくる|おくれ|送|でんわ|電話|連絡|めあど|めえる|id|dm)/;
/** 連絡先・URL・SNS の書き込みか（あてはまれば、送らない） */
export function hasContact(text: string): boolean {
  const t = text.normalize("NFKC").toLowerCase().replace(INVISIBLE, "").replace(/。/g, ".");
  const flat = t.replace(/\s+/g, "");
  if (/https?:\/\/|www\./.test(flat)) return true;
  if (/[a-z0-9._%+-]+@[a-z0-9-]+(\.[a-z0-9-]+)+/.test(flat) || /(?<![a-z0-9])@[a-z0-9_.]{3,}/.test(flat)) return true;
  if (/[a-z0-9-]{2,}\.(com|jp|net|org|io|me|co|tv|gg|xyz|app|dev|link|ly|be|cc|info|biz)(?![a-z])/.test(flat)) return true;
  // 数字の間の空白・ハイフン・点を詰めて、9桁以上の数字の並びがあれば、電話番号など
  const digits = t.replace(/(?<=\d)[\s\-.()ー・]+(?=\d)/g, "");
  if (/\d{9,}/.test(digits)) return true;
  const n = norm(t);
  const kanaService = SERVICES_KANA.test(n);
  const latinService = SERVICES_LATIN.test(t);
  return (kanaService || latinService) && EXCHANGE.test(n);
}

// ---------------------------------------------------------------- 名前
/** 運営・システムになりすませる名前。日本語のものは、検査用の形に含まれていたら、使えない */
const RESERVED = ["運営", "うんえい", "管理", "かんり", "おしらせ", "お知らせ", "しすてむ", "すたっふ", "実行委員", "じっこういいん", "先生", "せんせい", "公式", "こうしき"].map(norm);
/** 英字のものは、単語として入っているときだけ（badminton のような、ふつうの語を巻き込まないため） */
const RESERVED_LATIN = /(^|[^a-z])(system|admin|administrator|moderator|staff|official)([^a-z]|$)/;

function hashOf(s: string): number {
  let h = 2166136261;
  for (const c of s) h = Math.imul(h ^ c.charCodeAt(0), 16777619) >>> 0;
  return h;
}

/** 入室のなまえを検査する。使えないなまえ（暴言・連絡先・運営のなりすまし・空）は「ゲスト＋数字」に置き換える */
export function vetName(raw: unknown, seed: string, max: number): { name: string; replaced: boolean } {
  const name = cleanText(raw, max);
  const guest = `ゲスト${1000 + (hashOf(seed || String(Math.random())) % 9000)}`;
  if (!name) return { name: "ゲスト", replaced: false };
  const n = norm(name);
  const bad = !n || RESERVED.some((r) => n.includes(r)) || RESERVED_LATIN.test(name.normalize("NFKC").toLowerCase()) || maskNg(name).hits > 0 || evasionHit(name) || hasContact(name);
  return bad ? { name: guest, replaced: true } : { name, replaced: false };
}

// ---------------------------------------------------------------- 記録（管理ページの「自動対応」タブで見る。IP は残さない）
export interface ModEvent {
  t: number;
  kind: string;
  name: string;
  vid: string;
  detail: string;
}
const EVENT_MAX = 300;

interface StrikeRec {
  events: { t: number; p: number }[];
  level: number;
  until: number;
  name: string;
}

export interface VetInput {
  sid: string;
  vid: string;
  ip: string;
  name: string;
  text: string;
  joinedAt: number;
  stamps: number;
  /** 管理者が手動で定型文だけにしているか・安全装置が働いているか */
  phrasesOnly: boolean;
}
export type VetResult = { ok: true; text: string; strike?: Strike } | { ok: false; notice: ModNotice; strike?: Strike };
export interface Strike {
  /** この違反で、チャットを止めることになったか */
  muted: boolean;
  untilMs: number;
}

export class Moderation {
  readonly events: ModEvent[] = [];
  readonly counters = new Map<string, number>();

  private strikes = new Map<string, StrikeRec>();
  private ipMutes = new Map<string, number>();
  private lastChat = new Map<string, number>();
  private lastText = new Map<string, { n: string; t: number }>();
  private recentTexts = new Map<string, { t: number; vids: Set<string> }>();
  private lastEmote = new Map<string, number>();
  private joins = new Map<string, number[]>();
  private cool = new Map<string, number>();
  private violations: { t: number; who: string }[] = [];
  private reports = new Map<string, { t: number; by: string }[]>();
  private reporterLog = new Map<string, number[]>();
  private alertAt = new Map<string, number>();

  /** 安全装置が働いている時刻（これより前なら定型文だけ） */
  private breakerUntil = 0;
  private breakerCount = 0;
  private breakerLast = 0;
  /** 運営が、手動で定型文だけにしているか */
  manualPhrases = false;
  private onPhrases: (() => void) | null = null;

  /** 定型文だけのモードが切り替わったときに呼ぶ関数を、MainRoom が登録する */
  watchPhrases(cb: () => void): void {
    this.onPhrases = cb;
  }

  phrasesActive(now = Date.now()): boolean {
    return this.manualPhrases || now < this.breakerUntil;
  }
  breakerRemainingMs(now = Date.now()): number {
    return Math.max(0, this.breakerUntil - now);
  }

  /** 一定時間ごとに呼ぶ。安全装置の時間が切れたら、通常に戻す */
  tick(now = Date.now()): void {
    if (this.breakerUntil && now >= this.breakerUntil) {
      this.breakerUntil = 0;
      this.log("breaker-off", "", "", "安全装置が解除された（自由な書き込みに戻る）");
      this.onPhrases?.();
    }
    for (const [k, t] of this.ipMutes) if (t <= now) this.ipMutes.delete(k);
    for (const [k, t] of this.cool) if (t <= now) this.cool.delete(k);
    for (const [k, v] of this.recentTexts) if (now - v.t > 20000) this.recentTexts.delete(k);
    for (const [k, v] of this.lastText) if (now - v.t > 60000) this.lastText.delete(k);
  }

  setManualPhrases(on: boolean): void {
    if (this.manualPhrases === on) return;
    this.manualPhrases = on;
    this.log("manual-phrases", "", "", on ? "運営が、定型文だけにした" : "運営が、定型文だけを解いた");
    this.onPhrases?.();
  }

  // ---------------------------------------------------------------- 記録・通知
  log(kind: string, name: string, vid: string, detail: string): void {
    this.events.push({ t: Date.now(), kind, name, vid: vid.slice(0, 12), detail });
    if (this.events.length > EVENT_MAX) this.events.shift();
    this.counters.set(kind, (this.counters.get(kind) ?? 0) + 1);
  }

  /** 環境変数 ALERT_WEBHOOK_URL があれば、運営のチャット（Discord・Slack 互換）へ通知する。個人の情報は載せない。同じ種類は1分に1回まで */
  private alert(kind: string, text: string): void {
    const url = process.env.ALERT_WEBHOOK_URL;
    if (!url || !/^https:\/\//.test(url)) return;
    const now = Date.now();
    if (now - (this.alertAt.get(kind) ?? 0) < 60000) return;
    this.alertAt.set(kind, now);
    const body = JSON.stringify({ content: `[AMPLIFIRE] ${text}`, text: `[AMPLIFIRE] ${text}` });
    void fetch(url, { method: "POST", headers: { "content-type": "application/json" }, body, signal: AbortSignal.timeout(5000) }).catch(() => undefined);
  }

  // ---------------------------------------------------------------- 違反の点数・チャット停止
  private muteKey = (vid: string, sid: string) => vid || sid;

  muteInfo(vid: string, ip: string, sid: string, now = Date.now()): { until: number } | null {
    const rec = this.strikes.get(this.muteKey(vid, sid));
    const until = Math.max(rec?.until ?? 0, ip && !ipExempt(ip) ? (this.ipMutes.get(ip) ?? 0) : 0);
    return until > now ? { until } : null;
  }

  /** 違反の点数を足す。たまったら、チャットを止める（1回目10分・2回目1時間・以降その日の終わりまで） */
  strike(vid: string, sid: string, ip: string, name: string, points: number, reason: string, now = Date.now()): Strike {
    const key = this.muteKey(vid, sid);
    const rec = this.strikes.get(key) ?? { events: [], level: 0, until: 0, name };
    rec.name = name;
    rec.events = rec.events.filter((e) => now - e.t < STRIKE_WINDOW_MS);
    rec.events.push({ t: now, p: points });
    this.strikes.set(key, rec);
    this.note(now, key);
    const sum = rec.events.reduce((a, e) => a + e.p, 0);
    if (sum < STRIKE_LIMIT) return { muted: false, untilMs: 0 };
    rec.level++;
    rec.events = [];
    const ms = MUTE_STEPS_MS[Math.min(rec.level - 1, MUTE_STEPS_MS.length - 1)];
    rec.until = now + ms;
    this.log("auto-mute", name, vid, `${reason}（${rec.level}回目。${Math.round(ms / 60000)}分間、チャットを止めた）`);
    if (rec.level >= 2 && ip && !ipExempt(ip)) {
      this.ipMutes.set(ip, now + IP_MUTE_MS);
      this.log("ip-mute", name, vid, `同じ回線のチャットを${Math.round(IP_MUTE_MS / 60000)}分間止めた`);
    }
    return { muted: true, untilMs: ms };
  }

  unmute(vid: string): boolean {
    const rec = this.strikes.get(vid);
    if (!rec || rec.until <= Date.now()) return false;
    rec.until = 0;
    rec.events = [];
    this.log("unmute", rec.name, vid, "運営が、チャット停止を解いた");
    return true;
  }

  mutedList(now = Date.now()): { vid: string; name: string; level: number; untilMs: number }[] {
    return [...this.strikes]
      .filter(([, r]) => r.until > now)
      .map(([vid, r]) => ({ vid, name: r.name, level: r.level, untilMs: r.until - now }));
  }

  /** 違反が起きた時刻と、だれのものかを記録して、直近1分の数が多く、別々の人が何人もいれば、全体の安全装置（定型文だけ）を入れる */
  private note(now: number, who: string): void {
    this.violations = this.violations.filter((v) => now - v.t < BREAKER_WINDOW_MS);
    this.violations.push({ t: now, who });
    const people = new Set(this.violations.map((v) => v.who)).size;
    if (this.violations.length >= BREAKER_THRESHOLD && people >= BREAKER_MIN_PEOPLE && now >= this.breakerUntil) {
      // 30分以内にまた働いたら、2回目は倍の時間にする
      this.breakerCount = now - this.breakerLast < 30 * 60 * 1000 ? this.breakerCount + 1 : 1;
      this.breakerLast = now;
      const ms = BREAKER_MS * Math.min(this.breakerCount, 3);
      this.breakerUntil = now + ms;
      this.violations = [];
      this.log("breaker-on", "", "", `違反が急に増えたので、${Math.round(ms / 60000)}分間、定型文だけにした（${this.breakerCount}回目）`);
      this.alert("breaker", `荒らしが増えたため、自動でチャットを「定型文だけ」にしました（${Math.round(ms / 60000)}分間。自動で戻ります）。`);
      this.onPhrases?.();
    }
  }

  private block(kind: string, input: VetInput, notice: ModNotice, points: number, reason: string, now: number): VetResult {
    this.log(kind, input.name, input.vid, reason);
    this.lastChat.set(input.sid, now); // 送れなかった書き込みも、間隔の数に入れる（連打で検査の負荷をかけられないように）
    const strike = points > 0 ? this.strike(input.vid, input.sid, input.ip, input.name, points, reason, now) : undefined;
    if (!points) this.note(now, input.vid || input.sid);
    if (strike?.muted) {
      return { ok: false, strike, notice: { code: "muted", text: `ルールを まもらなかったので、${Math.round(strike.untilMs / 60000)}分 チャットを おやすみします`, retryMs: strike.untilMs } };
    }
    return { ok: false, notice, strike };
  }

  // ---------------------------------------------------------------- チャットの検査
  vetChat(input: VetInput, now = Date.now()): VetResult {
    const { sid, vid, ip, text } = input;
    if (input.phrasesOnly) return { ok: false, notice: { code: "phrases", text: "いまは 定型文だけ つかえます" } };
    const mute = this.muteInfo(vid, ip, sid, now);
    if (mute) return { ok: false, notice: { code: "muted", text: `いま チャットは おやすみ中です（あと${Math.ceil((mute.until - now) / 60000)}分）`, retryMs: mute.until - now } };
    if (now - input.joinedAt < NEWCOMER_MS && input.stamps < 1) {
      const retryMs = NEWCOMER_MS - (now - input.joinedAt);
      return { ok: false, notice: { code: "newcomer", text: `はいったばかりの人は、あと${Math.ceil(retryMs / 1000)}びょうで かけるよ（スタンプを1つ とっても OK）`, retryMs } };
    }
    const gap = now - (this.lastChat.get(sid) ?? 0);
    if (gap < CHAT_GAP_MS) return { ok: false, notice: { code: "fast", text: "ちょっと ゆっくり かいてね", retryMs: CHAT_GAP_MS - gap } };

    let t = cleanText(text, CHAT_MAX);
    if (!t) return { ok: false, notice: { code: "fast", text: "" } };

    // 連絡先・URL・SNS（子どもが参加するので、送らない）
    if (hasContact(t)) return this.block("block-contact", input, { code: "contact", text: "れんらくさきや URL は、かけないよ" }, 1, "連絡先・URL・SNS を含む書き込みを止めた", now);

    // 同じ文字の長い繰り返し
    if (/(.)\1{7,}/u.test(t)) return this.block("block-repeat", input, { code: "dup", text: "おなじ もじを くりかえすのは やめてね" }, 0, "同じ文字の繰り返しを止めた", now);

    // NG ワード: そのまま入っているものは伏字にして送る。すき間や記号で言い換えたものは、送らない（わざとなので、点を多く）
    const masked = maskNg(t);
    if (evasionHit(masked.text)) return this.block("block-badword", input, { code: "badword", text: "ことばづかいに きをつけてね" }, 2, "NGワードの言い換え（すき間・記号など）を止めた", now);
    t = masked.text;
    if (masked.hits > 0) {
      this.log("mask-badword", input.name, vid, "NGワードを伏字にして送った");
      const solid = Array.from(t).filter((c) => c === "＊").length;
      const strike = this.strike(vid, sid, ip, input.name, 1, "NGワードを含む書き込み", now);
      if (solid / Math.max(1, Array.from(t).length) > 0.5) {
        this.lastChat.set(sid, now);
        return { ok: false, notice: { code: "badword", text: "ことばづかいに きをつけてね" }, strike };
      }
      this.lastChat.set(sid, now);
      return this.dupOrOk(input, t, now, strike);
    }
    return this.dupOrOk(input, t, now);
  }

  /** 同じ文の連投・みんなで同じ文を流す荒らしを止める。通れば、受理 */
  private dupOrOk(input: VetInput, t: string, now: number, strike?: Strike): VetResult {
    const key = norm(t);
    const prev = this.lastText.get(input.sid);
    if (prev && prev.n === key && now - prev.t < 30000) return { ok: false, notice: { code: "dup", text: "おなじ ことばは つづけて かけないよ" }, strike };
    const group = this.recentTexts.get(key) ?? { t: now, vids: new Set<string>() };
    group.t = now;
    group.vids.add(input.vid || input.sid);
    this.recentTexts.set(key, group);
    // あいさつ（「こんにちは」）のような短い文が、何人かで重なるのはふつう。長い文を、たくさんの人が一斉に流すときだけ止める。違反の数には入れない（巻き添えで、全体の安全装置が働かないように）
    if (key.length >= 6 && group.vids.size >= 5) {
      this.log("block-flood", input.name, input.vid, "別々の人が、同じ長い文を一斉に流している（止めた）");
      return { ok: false, notice: { code: "dup", text: "おなじ ことばが たくさん ながれているよ" }, strike };
    }
    this.lastText.set(input.sid, { n: key, t: now });
    this.lastChat.set(input.sid, now);
    return { ok: true, text: t, strike };
  }

  /** 定型文チャット。止められている人は使えない。1人 2秒に1回まで */
  vetPhrase(input: Omit<VetInput, "text" | "phrasesOnly">, id: unknown, now = Date.now()): VetResult {
    const mute = this.muteInfo(input.vid, input.ip, input.sid, now);
    if (mute) return { ok: false, notice: { code: "muted", text: `いま チャットは おやすみ中です（あと${Math.ceil((mute.until - now) / 60000)}分）`, retryMs: mute.until - now } };
    const gap = now - (this.lastChat.get(input.sid) ?? 0);
    if (gap < 2000) return { ok: false, notice: { code: "fast", text: "ちょっと ゆっくり おしてね", retryMs: 2000 - gap } };
    const i = Number(id);
    if (!Number.isInteger(i) || i < 0 || i >= PHRASES.length) return { ok: false, notice: { code: "fast", text: "" } };
    this.lastChat.set(input.sid, now);
    return { ok: true, text: PHRASES[i] };
  }

  // ---------------------------------------------------------------- エモート
  allowEmote(sid: string, now = Date.now()): boolean {
    const last = this.lastEmote.get(sid) ?? 0;
    if (now - last < EMOTE_GAP_MS) return false;
    this.lastEmote.set(sid, now);
    return true;
  }

  // ---------------------------------------------------------------- 入室
  /** 入室を受けてよいか。だめなら、本人に見せる理由を返す */
  checkJoin(ip: string, vid: string, now = Date.now()): string | null {
    const c = Math.max(this.cool.get(`v:${vid}`) ?? 0, ip && !ipExempt(ip) ? (this.cool.get(`i:${ip}`) ?? 0) : 0);
    if (c > now) return `いったん 退室になったので、あと${Math.ceil((c - now) / 1000)}びょう まってから 入ってね`;
    if (ip && !ipExempt(ip)) {
      const list = (this.joins.get(ip) ?? []).filter((t) => now - t < 60000);
      if (list.length >= JOIN_PER_MIN) {
        this.log("join-rate", "", "", "同じ回線からの入室が多すぎるので、断った");
        this.note(now, `ip:${ip}`);
        return "この回線からの入室が はやすぎます。すこし まってから、もういちど ためしてね";
      }
    }
    return null;
  }

  noteJoin(ip: string, now = Date.now()): void {
    if (!ip || ipExempt(ip)) return;
    const list = (this.joins.get(ip) ?? []).filter((t) => now - t < 60000);
    list.push(now);
    this.joins.set(ip, list);
  }

  /** 退室させた人が、すぐ入り直せないように、短い待ち時間を付ける */
  coolDown(vid: string, ip: string, ms = KICK_COOLDOWN_MS, now = Date.now()): void {
    if (vid) this.cool.set(`v:${vid}`, now + ms);
    if (ip && !ipExempt(ip)) this.cool.set(`i:${ip}`, now + ms);
  }

  // ---------------------------------------------------------------- 通報
  /** 通報を受ける。別々の人から、一定数たまったら、自動でチャットを止める。結果は、通報した人にだけ（受け付けたか）返す */
  report(
    by: { sid: string; vid: string; joinedAt: number },
    target: { sid: string; vid: string; ip: string; name: string },
    now = Date.now(),
  ): { notice: ModNotice; muted: boolean } {
    if (by.sid === target.sid) return { muted: false, notice: { code: "report-ng", text: "じぶんは ほうこく できないよ" } };
    if (now - by.joinedAt < REPORTER_MIN_MS) return { muted: false, notice: { code: "report-ng", text: "はいったばかりの人は、すこし してから ほうこくできるよ" } };
    const mine = (this.reporterLog.get(by.sid) ?? []).filter((t) => now - t < 10 * 60 * 1000);
    if (mine.length >= REPORT_PER_USER) return { muted: false, notice: { code: "report-ng", text: "ほうこくは しばらく できないよ" } };
    mine.push(now);
    this.reporterLog.set(by.sid, mine);
    const key = target.vid || target.sid;
    const list = (this.reports.get(key) ?? []).filter((r) => now - r.t < REPORT_WINDOW_MS && r.by !== (by.vid || by.sid));
    list.push({ t: now, by: by.vid || by.sid });
    this.reports.set(key, list);
    const distinct = new Set(list.map((r) => r.by)).size;
    this.log("report", target.name, target.vid, `通報（${distinct}/${REPORT_NEEDED}人）`);
    if (distinct >= REPORT_NEEDED) {
      this.reports.delete(key);
      // 通報で、すぐにチャットを止める（点数の上限ぶんを足す）
      const s = this.strike(target.vid, target.sid, target.ip, target.name, STRIKE_LIMIT, `別々の${distinct}人から通報された`, now);
      return { muted: s.muted, notice: { code: "report-ok", text: "ほうこくを うけつけました。ありがとう" } };
    }
    return { muted: false, notice: { code: "report-ok", text: "ほうこくを うけつけました。ありがとう" } };
  }

  /** 退室した人の、軽い記録を片付ける */
  forget(sid: string): void {
    this.lastChat.delete(sid);
    this.lastText.delete(sid);
    this.lastEmote.delete(sid);
    this.reporterLog.delete(sid);
  }

  /** 管理ページに見せる、いまの状態 */
  status(now = Date.now()) {
    return {
      phrases: { active: this.phrasesActive(now), manual: this.manualPhrases, autoRemainingMs: this.breakerRemainingMs(now) },
      muted: this.mutedList(now),
      counters: Object.fromEntries(this.counters),
      events: this.events.slice(-120).reverse(),
      settings: { newcomerSec: NEWCOMER_MS / 1000, chatGapSec: CHAT_GAP_MS / 1000, strikeLimit: STRIKE_LIMIT, breakerThreshold: BREAKER_THRESHOLD, breakerSec: BREAKER_MS / 1000, joinPerMin: JOIN_PER_MIN, reportNeeded: REPORT_NEEDED },
    };
  }
}

export const moderation = new Moderation();
