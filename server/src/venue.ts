import { createHmac, timingSafeEqual } from "node:crypto";
import qrcode from "qrcode-generator";

/**
 * 会場限定モード（任意）。環境変数 VENUE_CODE（6文字以上の合言葉）を設定すると、入室には、会場の QR コード（URL の ?k=… ）が要る。
 * ページを開くだけなら、だれでもできる（入室のときに、コードを確かめる）。会場にいる人だけが入れるので、遠くからの荒らしは、ほぼ入れない。
 *  - 固定コード: VENUE_CODE の値そのものを、QR に入れる（紙に印刷して貼れる）。
 *  - 切り替わるコード: VENUE_ROTATE_MIN（分）も設定すると、コードがその間隔で変わる（ショー画面などの、会場の画面に QR を出して使う。
 *    いまのコードと、ひとつ前のコードが有効なので、切り替わりの前後に入った人も、失敗しない）。
 */
const secret = process.env.VENUE_CODE ?? "";
export const venueEnabled = secret.length >= 6;
const rotateMs = Math.max(0, Math.floor(Number(process.env.VENUE_ROTATE_MIN) || 0)) * 60 * 1000;

const slotCode = (slot: number): string => createHmac("sha256", secret).update(`venue:${slot}`).digest("base64url").slice(0, 14);

/** いま有効なコード */
export function currentVenueCode(now = Date.now()): string {
  return rotateMs ? slotCode(Math.floor(now / rotateMs)) : secret;
}

/** 入室コードが有効か（切り替わるときは、いまと、ひとつ前） */
export function verifyVenueCode(code: unknown, now = Date.now()): boolean {
  if (!venueEnabled) return true;
  if (typeof code !== "string" || code.length > 80) return false;
  const ok = (want: string) => {
    const a = Buffer.from(want);
    const b = Buffer.from(code);
    return a.length === b.length && timingSafeEqual(a, b);
  };
  if (!rotateMs) return ok(secret);
  const slot = Math.floor(now / rotateMs);
  return ok(slotCode(slot)) || ok(slotCode(slot - 1));
}

/** 会場の QR に入れる URL（origin は、管理ページを開いているときのサーバーの URL） */
export function venueUrl(origin: string, now = Date.now()): string {
  return `${origin.replace(/\/$/, "")}/?k=${encodeURIComponent(currentVenueCode(now))}`;
}

/** QR コードの SVG（そのまま画面に出せる・印刷できる） */
export function venueQrSvg(url: string): string {
  const qr = qrcode(0, "M");
  qr.addData(url);
  qr.make();
  return qr.createSvgTag({ cellSize: 8, margin: 3, scalable: true });
}

export const venueInfo = () => ({ enabled: venueEnabled, rotateMin: rotateMs / 60000 });

if (venueEnabled) console.log(`[server] 会場限定モード: 有効（${rotateMs ? `コードは${rotateMs / 60000}分ごとに変わる` : "固定コード"}）`);
