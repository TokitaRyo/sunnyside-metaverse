import { createHash, createHmac, timingSafeEqual } from "node:crypto";
import express, { type NextFunction, type Request, type Response } from "express";
import { requestIp } from "./geoblock";

/**
 * 公開前の「関係者だけ」の入り口（サイト全体の合言葉）。本番で、合言葉を知っている人だけが、ページも入室も使える。
 *  - 合言葉は、環境変数 SITE_PASSWORD（10文字以上）。無ければ ADMIN_PASSWORD を使う（管理者パスワードを知っている人＝運営者だけ）。
 *  - 本番（NODE_ENV=production）では、合言葉があれば、自動でこの入り口が有効になる。手元の開発・試験では、SITE_LOCK=1 のときだけ有効。
 *  - 文化祭の当日に、みんなに開くときは、SITE_LOCK=0 にする（flyctl secrets set SITE_LOCK=0）。もとに戻すときは、SITE_LOCK を消す（unset）か 1 にする。
 *  - 仕組み: 合言葉を入力すると、署名つきの Cookie（30日。HttpOnly）が付く。ページ・素材・入室の予約・WebSocket のすべてで、この Cookie を確かめる。
 *    管理ページ（/admin）は、独自の認証（Basic）を持つので、この入り口の外。管理者として認証できたら、この Cookie も一緒に付ける
 *    （管理ページ・ショー画面が、画像や接続のために、この入り口を通れるように）。
 *  - 管理者のショー画面（観客）の WebSocket は、観客トークンで入る（Cookie 不要）。
 */
const password = process.env.SITE_PASSWORD || process.env.ADMIN_PASSWORD || "";
const mode = process.env.SITE_LOCK; // "0": 無効（みんなに開く） / "1": 強制的に有効 / 未設定: 本番なら有効
const MIN_PASSWORD = 10;
export const gateEnabled = password.length >= MIN_PASSWORD && mode !== "0" && (mode === "1" || process.env.NODE_ENV === "production");

const COOKIE = "amplifire_gate";
const PUBLIC_PATHS = new Set(["/manifest.webmanifest", "/offline.html", "/sw.js", "/favicon.ico"]);
const MAX_AGE_S = 30 * 24 * 3600;
const key = createHash("sha256").update(`gate:${password}`).digest();
const sign = (exp: string) => createHmac("sha256", key).update(exp).digest("base64url");
const digest = (s: string) => createHash("sha256").update(s).digest();
const passDigest = digest(password);

function cookieValue(now = Date.now()): string {
  const exp = String(now + MAX_AGE_S * 1000);
  return `${exp}.${sign(exp)}`;
}

function parseCookie(header: string | null | undefined, name: string): string {
  for (const part of String(header ?? "").split(";")) {
    const i = part.indexOf("=");
    if (i > 0 && part.slice(0, i).trim() === name) return part.slice(i + 1).trim();
  }
  return "";
}

/** Cookie ヘッダーが有効か（署名と期限） */
export function validGate(cookieHeader: string | null | undefined, now = Date.now()): boolean {
  if (!gateEnabled) return true;
  const v = parseCookie(cookieHeader, COOKIE);
  const [exp, sig] = v.split(".");
  if (!exp || !sig || !/^\d{10,16}$/.test(exp) || Number(exp) < now) return false;
  const want = Buffer.from(sign(exp));
  const got = Buffer.from(sig);
  return want.length === got.length && timingSafeEqual(want, got);
}

/** WebSocket（入室）の認証で使う: Cookie があるか */
export function gateAllowsHeaders(headers: { get(name: string): string | null } | undefined): boolean {
  return validGate(headers?.get("cookie"));
}

const isHttps = (req: Request) => String(req.headers["x-forwarded-proto"] ?? req.protocol).split(",")[0].trim() === "https";

/** 合言葉の Cookie を付ける（ログイン成功時・管理者として認証できたとき） */
export function issueGateCookie(req: Request, res: Response): void {
  if (!gateEnabled) return;
  const flags = [`${COOKIE}=${cookieValue()}`, "Path=/", `Max-Age=${MAX_AGE_S}`, "HttpOnly", "SameSite=Lax"];
  if (isHttps(req)) flags.push("Secure");
  res.append("Set-Cookie", flags.join("; "));
}

function clearGateCookie(req: Request, res: Response): void {
  const flags = [`${COOKIE}=`, "Path=/", "Max-Age=0", "HttpOnly", "SameSite=Lax"];
  if (isHttps(req)) flags.push("Secure");
  res.append("Set-Cookie", flags.join("; "));
}

// ---------------------------------------------------------------- 入力の失敗が続いたら、その接続元を一時的に止める
const FAIL_LIMIT = 8;
const FAIL_WINDOW_MS = 10 * 60 * 1000;
const fails = new Map<string, { n: number; first: number }>();

const PAGE = (msg: string, next: string) => `<!doctype html>
<html lang="ja"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex, nofollow"><title>AMPLIFIRE</title>
<style>
  *{box-sizing:border-box} body{margin:0;min-height:100vh;display:grid;place-items:center;background:linear-gradient(160deg,#eef6ff,#f6efff);color:#34456b;font:16px/1.7 "Hiragino Sans","Noto Sans JP","Yu Gothic UI",Meiryo,system-ui,sans-serif;padding:20px}
  main{width:min(420px,100%);background:#fff;border-radius:20px;padding:28px 24px;box-shadow:0 12px 40px rgba(90,120,200,.25);text-align:center}
  h1{margin:0 0 4px;font-size:26px;letter-spacing:.3em;background:linear-gradient(120deg,#3f9bff,#8a63ff,#ff5fa2);-webkit-background-clip:text;background-clip:text;color:transparent}
  p{margin:8px 0 16px;color:#5b6b92;font-size:14px} .err{color:#c0392b;font-weight:700}
  input{width:100%;height:46px;border:2px solid #dbe6ff;border-radius:12px;padding:0 14px;font-size:16px;outline:none} input:focus{border-color:#79b4ff}
  button{margin-top:12px;width:100%;height:46px;border:0;border-radius:12px;background:linear-gradient(120deg,#79d4ff,#c4b5ff);color:#26314f;font-size:16px;font-weight:800;cursor:pointer}
</style></head><body><main>
<h1>AMPLIFIRE</h1>
<p>このページは、いまは 関係者だけが 開けます。<br>合言葉を 入れてください。</p>
${msg ? `<p class="err">${msg}</p>` : ""}
<form method="post" action="/__gate"><input type="hidden" name="next" value="${next}"><input type="password" name="pw" autocomplete="current-password" placeholder="合言葉" autofocus required><button type="submit">入る</button></form>
</main></body></html>`;

const safeNext = (v: unknown): string => (typeof v === "string" && /^\/(?!\/)[^\r\n\\]{0,200}$/.test(v) && !v.startsWith("/__gate") ? v : "/");
const escAttr = (s: string) => s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] ?? c);

function showLogin(req: Request, res: Response, status: number, msg = ""): void {
  res.status(status).set({ "Cache-Control": "no-store", "X-Robots-Tag": "noindex, nofollow", "X-Frame-Options": "DENY", "Referrer-Policy": "no-referrer" }).type("html").send(PAGE(msg, escAttr(safeNext(req.method === "GET" ? req.originalUrl : req.body?.next))));
}

/** 入り口の本体。Express の、国別制限のすぐ後に置く */
export function gateRouter(): express.Router {
  const r = express.Router();
  if (!gateEnabled) return r;

  const form = express.urlencoded({ extended: false, limit: "2kb" });
  r.post("/__gate", form, (req, res) => {
    const key = requestIp(req) ?? "?";
    const now = Date.now();
    const f = fails.get(key);
    if (f && now - f.first > FAIL_WINDOW_MS) fails.delete(key);
    if ((fails.get(key)?.n ?? 0) >= FAIL_LIMIT) return void res.status(429).type("text/plain").send("Too Many Requests");
    const given = typeof req.body?.pw === "string" ? req.body.pw.slice(0, 200) : "";
    if (!timingSafeEqual(digest(given), passDigest)) {
      const cur = fails.get(key) ?? { n: 0, first: now };
      cur.n++;
      fails.set(key, cur);
      return showLogin(req, res, 401, "合言葉が ちがいます");
    }
    fails.delete(key);
    issueGateCookie(req, res);
    res.redirect(303, safeNext(req.body?.next));
  });
  // ログアウト（Cookie を消す）
  r.get("/__gate/logout", (req, res) => {
    clearGateCookie(req, res);
    res.redirect(303, "/");
  });

  // それ以外は、すべて、Cookie が必要（管理ページ /admin は、独自の認証なので、ここでは通す）
  r.use((req: Request, res: Response, next: NextFunction) => {
    if (req.path === "/admin" || req.path.startsWith("/admin/")) return next();
    // PWA の部品（ホーム画面に入れるための目録・アイコン・オフラインの画面・サービスワーカー）は、中身が公開されても困らないので、入り口の外に置く
    if (PUBLIC_PATHS.has(req.path) || req.path.startsWith("/icons/")) return next();
    if (validGate(req.headers.cookie)) return next();
    if (req.method === "GET" && String(req.headers.accept ?? "").includes("text/html")) return showLogin(req, res, 401);
    res.status(401).set({ "Cache-Control": "no-store", "X-Robots-Tag": "noindex" }).type("text/plain").send("Unauthorized");
  });
  return r;
}

console.log(gateEnabled ? "[server] 入り口（合言葉）: 有効 — 合言葉を知っている人だけが開けます（みんなに開くときは SITE_LOCK=0）" : "[server] 入り口（合言葉）: 無効（だれでも開けます）");
if (mode === "1" && password.length < MIN_PASSWORD) console.warn(`[server] SITE_LOCK=1 ですが、合言葉（SITE_PASSWORD か ADMIN_PASSWORD）が ${MIN_PASSWORD} 文字未満なので、入り口は無効です`);
