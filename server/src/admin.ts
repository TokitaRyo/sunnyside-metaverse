import { createHash, timingSafeEqual } from "node:crypto";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import express, { type NextFunction, type Request, type Response, type Router } from "express";
import { stats, type Area } from "./stats";

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

export function adminRouter(): Router {
  const r = express.Router();
  r.use(auth);

  r.get("/", (_req, res) => res.type("html").send(page("admin.html")));
  r.get("/admin.js", (_req, res) => res.type("js").send(page("admin.js")));
  r.get("/admin.css", (_req, res) => res.type("css").send(page("admin.css")));

  r.get("/api/summary", (_req, res) => {
    res.json({ ...stats.summary(hooks?.areas() ?? []), banned: bans.size });
  });
  r.get("/api/online", (_req, res) => res.json(stats.onlineList()));
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
    res.json({ ok: true, ...stats.deleteVisitor(vid) });
  });
  r.post("/api/purge", mutating, json, (req, res) => {
    if (req.body?.confirm !== "DELETE ALL") return void res.status(400).json({ error: "confirm required" });
    console.log("[admin] purge all data");
    stats.purgeAll();
    res.json({ ok: true });
  });

  return r;
}
