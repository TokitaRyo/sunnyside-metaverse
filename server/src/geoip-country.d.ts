declare module "geoip-country" {
  /** IPアドレス → 国コード（ISO 3166-1 alpha-2）。不明なら null */
  const geoip: { lookup(ip: string): { country: string } | null };
  export default geoip;
}
