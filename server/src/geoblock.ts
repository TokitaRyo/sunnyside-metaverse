import type { Request, Response, NextFunction } from "express";
import geoip from "geoip-country";

/**
 * 海外からのアクセスを断る（国別IP制限）。
 * - 既定は日本（JP）だけ許可。`ALLOW_COUNTRIES=JP,US` のようにカンマ区切りで変えられる。`GEO_BLOCK=0` で無効。
 * - 本番（Fly.io）では、プロキシが付ける `Fly-Client-IP`（外から偽装できない）を使う。無ければ接続元のアドレス。
 * - 手元（localhost・社内LANなどのプライベートIP）は、いつでも通す。開発・テストを妨げないため。
 * - 国が分からないIPは、通す（日本の回線の取りこぼしで、日本の人を締め出さないため）。厳しくするなら `GEO_BLOCK_UNKNOWN=1`。
 * - IP→国の対応は、パッケージ(geoip-country)に入っている MaxMind GeoLite2 のデータ。VPN・プロキシ経由は見抜けない（完全な防御ではない）。
 */
export const geoBlockEnabled = process.env.GEO_BLOCK !== "0";
const allowed = new Set(
  (process.env.ALLOW_COUNTRIES ?? "JP")
    .split(",")
    .map((s) => s.trim().toUpperCase())
    .filter(Boolean),
);
const blockUnknown = process.env.GEO_BLOCK_UNKNOWN === "1";

/** localhost・プライベート・リンクローカルのアドレスか */
export function isLocalAddress(rawIp: string): boolean {
  const ip = rawIp.replace(/^::ffff:/i, "");
  if (ip === "::1" || ip === "127.0.0.1" || ip === "localhost") return true;
  if (/^(10\.|127\.|192\.168\.|169\.254\.)/.test(ip)) return true;
  if (/^172\.(1[6-9]|2\d|3[01])\./.test(ip)) return true;
  return /^(fe80:|fc|fd)/i.test(ip);
}

/** IPv4射影アドレス（::ffff:1.2.3.4）などを素のIPにそろえる */
function normalize(ip: string): string {
  const s = ip.trim().replace(/^\[|\]$/g, "");
  return s.toLowerCase().startsWith("::ffff:") ? s.slice(7) : s;
}

/** 接続元IPから、断るべきか（true なら断る） */
export function isBlockedIp(rawIp: string | undefined | null): boolean {
  if (!geoBlockEnabled || !rawIp) return false;
  // x-forwarded-for のように複数並ぶ場合は、先頭（もともとの接続元）を使う
  const ip = normalize(rawIp.split(",")[0]);
  if (!ip || isLocalAddress(ip)) return false;
  const country = geoip.lookup(ip)?.country;
  if (!country) return blockUnknown;
  return !allowed.has(country);
}

/** HTTP リクエストの接続元IP（Fly のヘッダ → ソケット） */
export function requestIp(req: Request): string | undefined {
  const h = req.headers["fly-client-ip"];
  return (Array.isArray(h) ? h[0] : h) ?? req.socket.remoteAddress ?? undefined;
}

const BLOCKED_HTML = `<!doctype html><html lang="ja"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>AMPLIFIRE</title>
<style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:#f6f4ff;color:#4b4a66;font:16px/1.8 system-ui,sans-serif;text-align:center;padding:24px}b{display:block;font-size:20px;margin-bottom:8px;letter-spacing:.1em}</style></head>
<body><div><b>AMPLIFIRE</b>このページは、日本国内からのみご利用いただけます。<br>This site is available only from within Japan.</div></body></html>`;

/** 最初に置く Express ミドルウェア。海外なら 403 を返して、以降の処理（配信・API・入室の予約）に進ませない */
export function geoBlockMiddleware(req: Request, res: Response, next: NextFunction): void {
  if (!isBlockedIp(requestIp(req))) return next();
  res.status(403).set({ "Cache-Control": "no-store", "X-Robots-Tag": "noindex" }).type("html").send(BLOCKED_HTML);
}

if (geoBlockEnabled) console.log(`[server] 国別IP制限: 有効（許可: ${[...allowed].join(",") || "なし"}${blockUnknown ? "、国不明も拒否" : ""}）`);
else console.log("[server] 国別IP制限: 無効（GEO_BLOCK=0）");
