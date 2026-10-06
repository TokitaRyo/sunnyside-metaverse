/** おばけやしき（お化け屋敷）。専用ドット絵は scripts/stalls/obakeyashiki.ps1（obakeyashiki_*.png）。島の奥に古びたやしき、手前に行列ロープと受付、左に墓場と枯れ木 */
export const meta = { id: "obakeyashiki", label: "おばけやしき", island: "浮島 7" };

export default function layout(k) {
  const P = "obakeyashiki_";
  // アニメ（横一列のシート）: 窓の灯り・看板・おばけ・鬼火・コウモリ・かぼちゃ提灯・ちょうちんおばけ・大鍋・クモ・霧・驚かし役
  k.custom(P + "win", undefined, undefined, { frames: 4, fps: 5 });
  k.custom(P + "sign", undefined, undefined, { frames: 4, fps: 3 });
  for (const c of ["w", "b", "p"]) k.custom(`${P}ghost_${c}`, undefined, undefined, { frames: 8, fps: 6 });
  k.custom(P + "hitodama", undefined, undefined, { frames: 6, fps: 8 });
  k.custom(P + "bats", undefined, undefined, { frames: 8, fps: 8 });
  k.custom(P + "pumpkin", undefined, undefined, { frames: 3, fps: 6 });
  k.custom(P + "lamppost", undefined, undefined, { frames: 4, fps: 3 });
  k.custom(P + "cauldron", undefined, undefined, { frames: 4, fps: 6 });
  k.custom(P + "spider", undefined, undefined, { frames: 4, fps: 3 });
  k.custom(P + "fog", undefined, undefined, { frames: 16, fps: 4 });
  k.custom(P + "sheetman", undefined, undefined, { frames: 2, fps: 3 });
  // 静止
  for (const n of ["overlay", "path", "house", "tomb_a", "tomb_b", "tomb_c", "tree", "fence", "booth", "stanchion", "rope", "glow_o", "glow_b", "shadow"]) k.custom(P + n);
  k.custom(P + "nobori", 1, 80);
  const SKEL = "skeleton_idle";

  const { put, person, blocker } = k;

  // ---- 床: 暗い覆い（草地ぜんたい）→ 参道
  put(P + "overlay", 0, 128, { sort: "floor", by: 0 });
  put(P + "path", 0, 128, { sort: "floor", by: 1 });

  // ---- やしき本体（通れない）・看板・窓の灯り・足もとの霧
  put(P + "house", 0, 72);
  blocker(0, 72, 136, 10);
  put(P + "win", -56, 48, { by: 73 });
  put(P + "win", 56, 48, { by: 73, frame: 2 });
  put(P + "sign", 0, 51, { by: 80 });
  put(P + "fog", 0, 100, { by: 73 });

  // ---- 行列ロープ（支柱×3 を左右に。まん中が客の通る列）
  for (const side of [-1, 1]) {
    const dx = side * 17;
    for (const f of [86, 102, 118]) put(P + "stanchion", dx, f, { hit: [5, 4] });
    for (const f of [102, 118]) put(P + "rope", dx, f - 10, { by: f - 1 });
  }

  // ---- ちょうちんおばけの柱（左右。提灯が参道側を向く）と、足もとのかぼちゃ提灯（光だまり）
  put(P + "lamppost", -27, 94, { hit: [6, 4], hxOff: -7 });
  put(P + "lamppost", 27, 94, { hit: [6, 4], hxOff: 7, flip: true, frame: 2 });
  for (const dx of [-42, 42]) {
    put(P + "glow_o", dx, 96, { sort: "floor", by: 2 });
    put(P + "pumpkin", dx, 94, { by: 94, frame: dx < 0 ? 0 : 1 });
  }

  // ---- 左: 墓場と枯れ木
  put(P + "tree", -76, 92, { hit: [10, 5] });
  put(P + "spider", -88, 76, { by: 130 });
  put(P + "tomb_b", -88, 106, { hit: [10, 5] });
  put(P + "tomb_a", -66, 100, { hit: [10, 5] });
  put(P + "tomb_c", -46, 108, { hit: [8, 5] });
  put(P + "glow_o", -54, 118, { sort: "floor", by: 2 });
  put(P + "pumpkin", -54, 116, { by: 116, frame: 2 });
  put(P + "fence", -80, 128, { hit: [30, 4] });
  put(P + "fence", -48, 128, { hit: [30, 4] });
  person(SKEL, -72, 114, {
    name: "がいこつやく",
    lines: [
      "カタカタカタ……！ がいこつやくだよ。びっくりした？",
      "ほねだけど、こころは あたたかいんだ。",
      "おどろいたら、えがおで てを ふってね。",
    ],
  });
  put("expression_chat", -72, 94, { by: 125 });

  // ---- 右: 受付・大鍋・のぼり
  put(P + "booth", 60, 108, { hit: [44, 8] });
  person("human_longhair_idle", 60, 89, {
    name: "うけつけ",
    lines: [
      "いらっしゃいませ。ここは おばけやしきの うけつけです。",
      "こわがりさんも、こわいのが だいすきな ひとも、ようこそ。",
      "ひとりでも こわくないよ。ゆっくり すすんでね。",
      "おばけたちが、みんなの くるのを まっているよ。",
    ],
  });
  put("expression_chat", 60, 70, { by: 110 });
  put(P + "cauldron", 84, 124, { hit: [16, 5] });
  put(P + "nobori", 82, 82, { hit: [4, 4] });

  // ---- 入口の驚かし役
  person(P + "sheetman", -9, 82, {
    name: "おばけやく",
    lines: [
      "うらめしや〜……なんてね。おばけやくの わたしだよ。",
      "ほんとうは とっても やさしい おばけなんだ。",
      "びっくりしても だいじょうぶ。みんな ともだちだよ。",
    ],
  });

  // ---- 行列の客
  person("human_bowlhair_idle", -5, 96, {
    name: "ならぶひと",
    lines: ["どきどき するね。ならんで まっているところ。", "おばけが でてきたら、いっしょに さけぼう！"],
  });
  person("human_mophair_idle", 6, 110, {
    name: "こども",
    lines: ["ぼく、おばけ ちょっと こわいけど……たのしみ！", "ひとだまの あおい ひが きれいだね。"],
  });
  person("human_curlyhair_idle", -28, 114, {
    name: "こわがりさん",
    lines: ["ひゃー！ ……って なっちゃった。でも、わらっちゃった。", "こわいけど、かわいい おばけも いるんだね。"],
  }, true);

  // ---- ふわふわ浮かぶおばけ・鬼火（人より手前）
  const floatG = (name, dx, foot, frame) => {
    put(P + "shadow", dx, foot + 10, { sort: "floor", by: 3 });
    put(P + name, dx, foot, { by: 135, frame });
  };
  floatG("ghost_w", -40, 66, 0);
  floatG("ghost_b", 42, 64, 3);
  floatG("ghost_p", 30, 126, 6);
  for (const [dx, foot, fr] of [[-58, 90, 0], [70, 72, 3]]) {
    put(P + "glow_b", dx, foot + 8, { sort: "floor", by: 3 });
    put(P + "hitodama", dx, foot, { by: 136, frame: fr });
  }

  // ---- コウモリ（屋根のまわり）
  put(P + "bats", 0, 30, { by: 140 });
  put(P + "bats", -66, 40, { by: 140, frame: 4 });
}
