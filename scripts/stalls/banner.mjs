/**
 * 島の北側（出店の列の上）に立てる大きな横断幕。絵は利用者が用意した絵をドット絵風にしたもの（scripts/gen-banner.ps1 → gen-banner.mjs）。
 * 区画ではなく島の北のはしの上に置く（build-stalls.mjs が `north` を見て、島の幅の中央・草地の上端の少し上に置く）。スタンプは置かない。
 */
export const meta = { id: "banner", label: "横断幕" };
/** 島の北に置く（区画 SLOTS は使わない）。plot の下端 = 草地の上端から 44px 上 */
export const north = { above: 44 };

export default function layout(k) {
  k.custom("banner_amp");
  k.custom("banner_post");
  const { put } = k;
  const HALF = 273; // 柱の位置（横断幕の幅 562 の左右のはし）
  // 柱（幕の下に隠れる側。下端は幕の下端の24px下。これより下に伸ばすと、すぐ下の出店の区画の判定に入ってしまう）
  put("banner_post", -HALF, 128 + 24, { by: 126 });
  put("banner_post", HALF, 128 + 24, { by: 126 });
  // 横断幕（下端が foot = 128）
  put("banner_amp", 0, 128, { by: 127 });
}
