/**
 * 信頼する接続元（環境変数 TRUSTED_IPS）。学内LANのプロキシのように、たくさんの人が「1つのIP」から来る回線のための設定。
 *  - 書き方: カンマ区切り。IPv4 のアドレス（133.104.5.41）か、範囲（133.104.0.0/16）。
 *  - 効果: 「回線ごと」の制限（同じ回線から同時に入れる数・入室の頻度・予約の頻度・退室させたあとの待ち・同じ回線のチャット停止）を、かけない。
 *    これらがないと、学校のプロキシ1つが、全員を「同じ人」と見なして、数十人で締め出してしまうため。
 *  - 「人ごと」の守り（名前の検査・連絡先やNGワードの検査・違反の点数・通報・利用停止）は、これまでどおり、かかる。
 *  - 国別制限（日本のみ）は、そのまま。学校の回線は日本のIPなので、通る。
 */
const toInt = (ip: string): number | null => {
  const m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(ip);
  if (!m) return null;
  const p = m.slice(1).map(Number);
  if (p.some((n) => n > 255)) return null;
  return ((p[0] << 24) >>> 0) + (p[1] << 16) + (p[2] << 8) + p[3];
};

interface Range {
  start: number;
  mask: number;
}

const ranges: Range[] = [];
/** IPv6 は、範囲には対応せず、アドレスそのもの（::1 など）だけ */
const exact = new Set<string>();
for (const raw of (process.env.TRUSTED_IPS ?? "").split(",")) {
  const s = raw.trim();
  if (!s) continue;
  if (s.includes(":") && !s.includes("/")) {
    exact.add(s.toLowerCase());
    continue;
  }
  const [addr, bits] = s.split("/");
  const base = toInt(addr);
  const len = bits === undefined ? 32 : Number(bits);
  if (base === null || !Number.isInteger(len) || len < 0 || len > 32) {
    console.warn(`[trusted] TRUSTED_IPS の「${s}」は、IPv4 のアドレスか範囲として読めないので、無視します`);
    continue;
  }
  const mask = len === 0 ? 0 : (0xffffffff << (32 - len)) >>> 0;
  ranges.push({ start: (base & mask) >>> 0, mask });
}
if (ranges.length || exact.size) console.log(`[trusted] 信頼する接続元: ${process.env.TRUSTED_IPS}`);

/** その接続元が、TRUSTED_IPS に入っているか */
export function isTrustedIp(rawIp: string | undefined | null): boolean {
  if ((!ranges.length && !exact.size) || !rawIp) return false;
  const first = rawIp.split(",")[0].trim().replace(/^\[|\]$/g, "");
  if (exact.has(first.toLowerCase())) return true;
  const ip = toInt(first.replace(/^::ffff:/i, ""));
  if (ip === null) return false;
  return ranges.some((r) => ((ip & r.mask) >>> 0) === r.start);
}
