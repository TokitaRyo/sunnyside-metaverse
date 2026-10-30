import { createHash, createHmac, timingSafeEqual } from "node:crypto";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import express, { type NextFunction, type Request, type Response, type Router } from "express";
import { stats, type Area } from "./stats";
import { moderation } from "./moderation";
import { ranking, stallIdsOf } from "./ranking";
import { issueGateCookie } from "./gate";
import { venueInfo, venueQrSvg, venueUrl } from "./venue";

/**
 * 管理ページ（/admin）。運営者だけが見られるように、環境変数 ADMIN_PASSWORD（10文字以上）を知っている人だけに見せる。
 *  - ADMIN_PASSWORD が未設定・短い → 管理ページは無効（404）。誰にも見えない。
 *  - 認証は Basic 認証（ユーザー名は何でもよい）。間違いが続くとその接続元を一時的に締め出す。
 *  - 変更を伴う操作（退室・利用停止・おしらせ・削除）は、専用ヘッダー X-Admin: 1 と JSON が必要（他サイトからの勝手な操作を防ぐ）。
 *  - 画面の JS/CSS は自分のサーバーのものだけ読み込む（CSP）。チャット本文は textContent で出すので、書かれた HTML は動かない。
 */

const MIN_PASSWORD = 10;
const FAIL_LIMIT = 8;
const FAIL_WINDOW_MS = 10 * 60 * 1000;

export interface AdminHooks {
  areas(): Area[];
  /** 全員のチャットにおしらせを流す */
  announce(text: string): void;
  /** その人を退室させる。退室させたら true */
  kick(sid: string, reason: string): boolean;
  /** チャットの停止・再開を全員に知らせる */
  setChatLocked(locked: boolean): void;
  /** 消した発言を、参加者の画面のチャット欄からも消す */
  retractChat(ids: number[]): void;
  /** 定型文だけのモードを、手動で入れる・解く */
  setPhrasesOnly(on: boolean): void;
  /** 自動で止められた人のチャット停止を、解く */
  unmute(vid: string): boolean;
}
let hooks: AdminHooks | null = null;
export function registerAdminHooks(h: AdminHooks): void {
  hooks = h;
}

// ---------------------------------------------------------------- 利用停止（訪問者IDで）
const banFile = () => join(stats.dir, "bans.json");
const bans = new Map<string, { name: string; at: number }>();
try {
  if (existsSync(banFile())) for (const [k, v] of Object.entries(JSON.parse(readFileSync(banFile(), "utf8")))) bans.set(k, v as { name: string; at: number });
} catch {
  /* 読めなければ空から始める */
}
function saveBans(): void {
  try {
    writeFileSync(banFile(), JSON.stringify(Object.fromEntries(bans)));
  } catch (e) {
    console.warn("[admin] bans.json を書けません:", e);
  }
}
export const isBanned = (vid: string): boolean => bans.has(vid);

// ---------------------------------------------------------------- 認証
const password = process.env.ADMIN_PASSWORD ?? "";
export const adminEnabled = password.length >= MIN_PASSWORD;
if (process.env.ADMIN_PASSWORD && !adminEnabled) console.warn(`[admin] ADMIN_PASSWORD が ${MIN_PASSWORD} 文字未満なので、管理ページは無効です`);
const digest = (s: string) => createHash("sha256").update(s).digest();
const passDigest = digest(password);

// ---------------------------------------------------------------- 観客トークン（ショー画面が、ゲームの部屋を「見るだけ」で開くための入場券）
// 管理ページの認証（Basic）は、部屋への接続（別のURL）には付かないため、認証済みの管理 API から短命のトークンをもらって使う。
// 中身は「期限.署名」で、署名は管理パスワード由来の鍵の HMAC。パスワードを知らない人は作れず、期限が切れれば使えない。
const SPECTATOR_TTL_MS = 5 * 60 * 1000;
const spectatorKey = createHash("sha256").update(`spectator:${password}`).digest();
const sign = (exp: string) => createHmac("sha256", spectatorKey).update(exp).digest("base64url");
export function issueSpectatorToken(): string {
  const exp = String(Date.now() + SPECTATOR_TTL_MS);
  return `${exp}.${sign(exp)}`;
}
export function verifySpectatorToken(token: unknown): boolean {
  if (!adminEnabled || typeof token !== "string" || token.length > 120) return false;
  const [exp, sig] = token.split(".");
  if (!exp || !sig || !/^\d{10,16}$/.test(exp) || Number(exp) < Date.now()) return false;
  const want = Buffer.from(sign(exp));
  const got = Buffer.from(sig);
  return want.length === got.length && timingSafeEqual(want, got);
}

const fails = new Map<string, { n: number; first: number }>();
const clientKey = (req: Request): string => String(req.headers["fly-client-ip"] ?? req.socket.remoteAddress ?? "?");

function auth(req: Request, res: Response, next: NextFunction): void {
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("X-Robots-Tag", "noindex, nofollow");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader(
    "Content-Security-Policy",
    "default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  );
  if (!adminEnabled) {
    res.status(404).type("text/plain").send("Not Found");
    return;
  }
  const key = clientKey(req);
  const f = fails.get(key);
  const now = Date.now();
  if (f && now - f.first > FAIL_WINDOW_MS) fails.delete(key);
  if ((fails.get(key)?.n ?? 0) >= FAIL_LIMIT) {
    res.status(429).type("text/plain").send("Too Many Requests");
    return;
  }
  const h = req.headers.authorization ?? "";
  let ok = false;
  if (h.startsWith("Basic ")) {
    const decoded = Buffer.from(h.slice(6), "base64").toString("utf8");
    const given = decoded.slice(decoded.indexOf(":") + 1);
    ok = timingSafeEqual(digest(given), passDigest);
  }
  if (!ok) {
    const cur = fails.get(key) ?? { n: 0, first: now };
    cur.n++;
    fails.set(key, cur);
    res.setHeader("WWW-Authenticate", 'Basic realm="AMPLIFIRE admin", charset="UTF-8"');
    res.status(401).type("text/plain").send("Unauthorized");
    return;
  }
  fails.delete(key);
  issueGateCookie(req, res); // 管理者として認証できた人は、サイト全体の入り口（合言葉）も通れるようにする（ショー画面が、画像や接続を使うため）
  next();
}

/** 変更を伴う操作の確認（CSRF対策） */
function mutating(req: Request, res: Response, next: NextFunction): void {
  if (req.headers["x-admin"] !== "1" || !req.is("application/json")) {
    res.status(400).json({ error: "bad request" });
    return;
  }
  next();
}

// ---------------------------------------------------------------- CSV
const csvCell = (v: unknown): string => {
  let s = String(v ?? "");
  if (/^[=+\-@\t\r]/.test(s)) s = "'" + s; // 表計算ソフトで式として動かない
  return `"${s.replace(/"/g, '""')}"`;
};
const csv = (rows: unknown[][]): string => "﻿" + rows.map((r) => r.map(csvCell).join(",")).join("\r\n") + "\r\n";
const iso = (t: number) => new Date(t + 9 * 3600 * 1000).toISOString().replace("T", " ").slice(0, 19);

const num = (v: unknown, d: number, min: number, max: number): number => {
  const n = Number(v);
  return Number.isFinite(n) ? Math.max(min, Math.min(max, Math.floor(n))) : d;
};

const PAGE_DIR = new URL("./admin/", import.meta.url);
const page = (name: string) => readFileSync(new URL(name, PAGE_DIR));

/** clientDist: ビルド済みクライアントの場所。ショー画面（管理者用の大型表示。client/show.html）を、パスワードの内側で配るために使う */
export function adminRouter(clientDist: string): Router {
  const r = express.Router();
  r.use(auth);

  r.get("/", (_req, res) => res.type("html").send(page("admin.html")));
  r.get("/admin.js", (_req, res) => res.type("js").send(page("admin.js")));
  // ショー画面: 入室中の人のアバターを、順番に大きく映す（大型ディスプレイ用）。中身の JS は公開の /assets/ にあるが、人の情報（API）はこのパスワードの内側にしかない
  r.get(["/show", "/show/"], (req, res) => {
    const file = join(clientDist, "show.html");
    if (!existsSync(file)) return void res.status(404).type("text/plain").send("show.html がありません（npm run build -w client で作ります）");
    // ショー画面はゲームの部屋にも（観客として）つなぐので、この画面だけ、自分のサーバーへの WebSocket と、素材の画像(blob)を許す
    const host = String(req.headers.host ?? "").replace(/[^A-Za-z0-9.:\-\[\]]/g, "");
    res.setHeader(
      "Content-Security-Policy",
      `default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' data: blob:; connect-src 'self' ws://${host} wss://${host}; base-uri 'none'; form-action 'none'; frame-ancestors 'none'`,
    );
    res.type("html").send(readFileSync(file));
  });
  r.get("/admin.css", (_req, res) => res.type("css").send(page("admin.css")));

  r.get("/api/summary", (_req, res) => {
    res.json({ ...stats.summary(hooks?.areas() ?? []), banned: bans.size });
  });
  r.get("/api/online", (_req, res) => res.json(stats.onlineList()));
  // ランキング（ショー画面が表示する。参加者に出すものと同じ中身）
  r.get("/api/ranking", (req, res) => res.json(ranking.snapshot(stallIdsOf(hooks?.areas() ?? []), undefined, num(req.query.top, 5, 1, 20))));
  r.get("/api/spectator-token", (_req, res) => res.json({ token: issueSpectatorToken() }));
  r.get("/api/sessions", (req, res) => res.json(stats.recentSessions(num(req.query.limit, 100, 1, 500))));
  r.get("/api/chat", (req, res) => {
    res.json(
      stats.chatLog({
        limit: num(req.query.limit, 200, 1, 1000),
        beforeId: req.query.before ? num(req.query.before, 0, 0, 1e12) : undefined,
        q: typeof req.query.q === "string" && req.query.q ? req.query.q.slice(0, 60) : undefined,
        vid: typeof req.query.vid === "string" && req.query.vid ? req.query.vid.slice(0, 64) : undefined,
      }),
    );
  });
  r.get("/api/settings", (_req, res) => res.json({ chatLocked: stats.chatLocked, phrasesOnly: moderation.phrasesActive() }));
  // 自動の荒らし対策の状況（止めた人・定型文だけのモード・最近の自動対応）
  r.get("/api/moderation", (_req, res) => res.json({ ...moderation.status(), venue: venueInfo() }));
  // 会場限定モード: 入室用の URL と QR（SVG）。ショー画面や、印刷用のページが使う
  const originOf = (req: Request): string => {
    const proto = String(req.headers["x-forwarded-proto"] ?? req.protocol).split(",")[0].trim() === "https" ? "https" : "http";
    const host = String(req.headers.host ?? "").replace(/[^A-Za-z0-9.:\-\[\]]/g, "");
    return `${proto}://${host}`;
  };
  r.get("/api/venue", (req, res) => {
    const info = venueInfo();
    if (!info.enabled) return void res.json({ enabled: false });
    const url = venueUrl(originOf(req));
    res.json({ ...info, url, svg: venueQrSvg(url) });
  });
  // 印刷用ページ（会場に貼る QR。固定コードのとき）
  r.get("/venue", (req, res) => {
    const info = venueInfo();
    if (!info.enabled) return void res.status(404).type("text/plain").send("会場限定モードは、無効です（環境変数 VENUE_CODE を設定すると有効になります）");
    const url = venueUrl(originOf(req));
    const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c] ?? c);
    res.type("html").send(
      `<!doctype html><html lang="ja"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>AMPLIFIRE 入室用 QR</title><link rel="stylesheet" href="/admin/admin.css"></head><body class="venue-page"><main class="venue-card"><h1>AMPLIFIRE</h1><p class="venue-lead">スマホで、この QR コードを 読みとって 入室してね</p><div class="venue-qr">${venueQrSvg(url)}</div><p class="venue-url">${esc(url)}</p>${info.rotateMin ? `<p class="venue-note">このコードは ${info.rotateMin} 分ごとに 変わります（ショー画面に出る QR を使ってください）</p>` : ""}<p class="venue-note">会場にいる人だけが 入れるようになっています</p></main></body></html>`,
    );
  });
  r.get("/api/bans", (_req, res) => res.json([...bans.entries()].map(([vid, b]) => ({ vid, ...b }))));

  r.get("/api/export/chat.csv", (_req, res) => {
    res.setHeader("Content-Disposition", 'attachment; filename="amplifire-chat.csv"');
    res.type("text/csv").send(
      csv([["id", "日時(JST)", "種類", "ニックネーム", "訪問者ID", "本文"], ...stats.allChat().map((c) => [c.id, iso(c.t), c.kind, c.name, c.vid, c.text])]),
    );
  });
  r.get("/api/export/sessions.csv", (_req, res) => {
    res.setHeader("Content-Disposition", 'attachment; filename="amplifire-sessions.csv"');
    res.type("text/csv").send(
      csv([
        ["入室(JST)", "退室(JST)", "滞在(秒)", "ニックネーム", "訪問者ID", "端末", "チャット数", "エモート数", "スタンプ", "スタンプ総数", "同意した版"],
        ...stats.allSessions().map((s) => [iso(s.joinedAt), iso(s.leftAt), s.stay, s.name, s.vid, s.device, s.chats, s.emotes, s.stamps, s.stampTotal, s.consent]),
      ]),
    );
  });

  // ---- 変更を伴う操作
  const json = express.json({ limit: "4kb" });
  r.post("/api/announce", mutating, json, (req, res) => {
    const text = typeof req.body?.text === "string" ? req.body.text.trim().slice(0, 140) : "";
    if (!text || !hooks) return void res.status(400).json({ error: "text required" });
    hooks.announce(text);
    res.json({ ok: true });
  });
  // チャットの停止・再開（ワンタッチ）
  r.post("/api/chat/lock", mutating, json, (req, res) => {
    const locked = req.body?.locked === true;
    if (!hooks) return void res.status(503).json({ error: "not ready" });
    hooks.setChatLocked(locked);
    console.log(`[admin] chat ${locked ? "LOCKED" : "unlocked"}`);
    res.json({ ok: true, chatLocked: stats.chatLocked });
  });
  // 選んだ発言を消す（記録からも、参加者の画面からも）
  r.post("/api/chat/delete", mutating, json, (req, res) => {
    const ids = Array.isArray(req.body?.ids) ? (req.body.ids as unknown[]).filter((v): v is number => Number.isInteger(v)).slice(0, 500) : [];
    if (!ids.length || !hooks) return void res.status(400).json({ error: "ids required" });
    const deleted = stats.deleteChat(ids);
    hooks.retractChat(ids);
    console.log(`[admin] delete chat x${deleted}`);
    res.json({ ok: true, deleted });
  });
  // 定型文だけのモード（手動）。荒らしが増えたときは、自動でも入る
  r.post("/api/moderation/phrases", mutating, json, (req, res) => {
    if (!hooks) return void res.status(503).json({ error: "not ready" });
    hooks.setPhrasesOnly(req.body?.on === true);
    console.log(`[admin] phrases-only ${req.body?.on === true ? "ON" : "off"}`);
    res.json({ ok: true, ...moderation.status().phrases });
  });
  // 自動で止められた人の、チャット停止を解く
  r.post("/api/moderation/unmute", mutating, json, (req, res) => {
    const vid = typeof req.body?.vid === "string" ? req.body.vid : "";
    if (!vid || !hooks) return void res.status(400).json({ error: "vid required" });
    res.json({ ok: hooks.unmute(vid) });
  });
  r.post("/api/kick", mutating, json, (req, res) => {
    const sid = typeof req.body?.sid === "string" ? req.body.sid : "";
    const ban = req.body?.ban === true;
    const target = stats.onlineList().find((p) => p.sid === sid);
    if (!target || !hooks) return void res.status(404).json({ error: "not online" });
    if (ban && target.vid) {
      bans.set(target.vid, { name: target.name, at: Date.now() });
      saveBans();
    }
    hooks.kick(sid, ban ? "banned" : "kicked");
    console.log(`[admin] ${ban ? "ban" : "kick"} ${sid} "${target.name}"`);
    res.json({ ok: true });
  });
  r.post("/api/unban", mutating, json, (req, res) => {
    const vid = typeof req.body?.vid === "string" ? req.body.vid : "";
    const had = bans.delete(vid);
    if (had) saveBans();
    res.json({ ok: had });
  });
  r.post("/api/delete-visitor", mutating, json, (req, res) => {
    const vid = typeof req.body?.vid === "string" ? req.body.vid.trim() : "";
    if (vid.length < 8) return void res.status(400).json({ error: "vid required" });
    console.log(`[admin] delete visitor ${vid.slice(0, 6)}…`);
    ranking.deleteVisitor(vid);
    res.json({ ok: true, ...stats.deleteVisitor(vid) });
  });
  // スタンプRTA の記録を、すべて消す（練習の記録を、本番の前に消すとき）
  r.post("/api/ranking/reset", mutating, json, (req, res) => {
    if (req.body?.confirm !== "RESET RANKING") return void res.status(400).json({ error: "confirm required" });
    const n = ranking.resetRta();
    console.log(`[admin] reset RTA ranking x${n}`);
    res.json({ ok: true, removed: n });
  });
  r.post("/api/purge", mutating, json, (req, res) => {
    if (req.body?.confirm !== "DELETE ALL") return void res.status(400).json({ error: "confirm required" });
    console.log("[admin] purge all data");
    ranking.resetRta();
    stats.purgeAll();
    res.json({ ok: true });
  });

  return r;
}
