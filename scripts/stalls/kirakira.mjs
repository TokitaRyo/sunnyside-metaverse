/** キラキラドリンク屋。専用ドット絵は scripts/stalls/kirakira.ps1（kirakira_*.png） */
export const meta = { id: "kirakira", label: "キラキラドリンク屋" };

export default function layout(k) {
  // ---- 静止
  for (const n of ["floor", "back", "roof", "post", "shaker", "straws", "board", "table"]) k.custom(`kirakira_${n}`);
  k.custom("kirakira_nobori_blue", 1, 82);
  k.custom("kirakira_nobori_pink", 1, 82);
  // ---- アニメ（横一列のシート）
  k.custom("kirakira_sign", undefined, undefined, { frames: 6, fps: 4 }); // ネオン看板（ふちが流れ、文字が点滅し、きらり）
  k.custom("kirakira_garland", undefined, undefined, { frames: 4, fps: 3 }); // 豆電球
  k.custom("kirakira_case", undefined, undefined, { frames: 8, fps: 6 }); // 氷のショーケース（グラデーションが流れる）
  k.custom("kirakira_bench", undefined, undefined, { frames: 4, fps: 4 }); // 作業台のLEDライン
  k.custom("kirakira_syrups", undefined, undefined, { frames: 4, fps: 3 }); // シロップのボトル
  for (const c of ["a", "b", "c"]) k.custom(`kirakira_cup_${c}`, undefined, undefined, { frames: 6, fps: 5 }); // ドリンク
  for (const c of ["a", "b"]) k.custom(`kirakira_cup_s_${c}`, undefined, undefined, { frames: 6, fps: 5 }); // 持つ用の小さいドリンク
  k.custom("kirakira_glitter", undefined, undefined, { frames: 8, fps: 5 }); // ラメの粒子
  k.custom("kirakira_spark", 4.5, 4.5, { frames: 4, fps: 5 });

  const { put, person } = k;
  const ON_BENCH = 81; // 作業台(足元80)の上に置く物は、台より手前に描く

  // ---- 床（パステルのタイルと光だまり）
  put("kirakira_floor", 0, 128, { sort: "floor", by: 0 });

  // ---- 店の構え: 奥の壁 → 屋根 → 豆電球 → ネオン看板 → 柱・のぼり
  put("kirakira_back", 0, 62, { by: 30 });
  put("kirakira_roof", 0, 42);
  put("kirakira_garland", 0, 50, { by: 91 });
  put("kirakira_sign", 0, 22, { by: 95 });
  put("kirakira_post", -74, 80, { hit: [6, 6] });
  put("kirakira_post", 74, 80, { hit: [6, 6] });
  put("kirakira_nobori_blue", -92, 74, { hit: [4, 4] });
  put("kirakira_nobori_pink", 80, 74, { hit: [4, 4] });

  // ---- 左: 氷のショーケース（ドリンクが並ぶ）
  put("kirakira_case", -44, 78, { hit: [56, 10] });

  // ---- 右: 作業台とその上
  put("kirakira_bench", 33, 80, { hit: [78, 10] });
  put("kirakira_syrups", 9, 66, { by: ON_BENCH });
  put("kirakira_shaker", 35, 66, { by: ON_BENCH });
  put("kirakira_straws", 51, 66, { by: ON_BENCH });
  put("kirakira_cup_b", 64, 66, { by: ON_BENCH, frame: 2 });

  // ---- 部員（作業台の奥とショーケースのとなり）
  person("human_longhair_doing", 14, 56, {
    name: "キラキラやさん",
    lines: [
      "いらっしゃいませ！ キラキラドリンクの おみせへ ようこそ。",
      "とうめいな カップに、あおから むらさき、ピンクへ と いろが かわっていく ドリンクを いれるんだよ。",
      "ゼリーや キラキラの つぶ、ふわふわの ホイップを のせて、ストローを さしたら できあがり！",
      "みているだけで わくわくする、はなやかな ドリンクを めざしているの。ゆっくり みていってね！",
    ],
  });
  put("expression_love", 14, 36, { by: 90 });
  person("human_shorthair_doing", 46, 56, {
    name: "てんいんさん",
    lines: [
      "ここは ドリンクを つくる さぎょうだいだよ。シロップの ボトルが ならんでいるでしょ？",
      "シロップを そーっと そそいで、いろを かさねていくの。まぜすぎないのが コツなんだ。",
      "シェイカーを ふって まぜることも あるよ。ストローは すきな いろを えらんでね。",
    ],
  });
  person("human_spikeyhair_doing", -8, 62, {
    name: "ショーケースがかり",
    lines: [
      "ショーケースの なかを みてみて！ こおりの うえで ドリンクが ひえひえに なってるよ。",
      "あかりが あたると、いろが ゆらゆら ながれて、キラキラ ひかるんだ。",
      "うえの かんばんも ネオンみたいで きれいでしょ？ ぴかぴか てんめつ するよ。",
    ],
  });

  // ---- 右手前: 立ち飲みテーブルとドリンク
  put("kirakira_table", 72, 118, { hit: [18, 6] });
  put("kirakira_cup_a", 72, 97, { by: 120 });

  // ---- 左手前: ドリンクの立て看板
  put("kirakira_board", -68, 126, { hit: [44, 6] });

  // ---- お客さん（ドリンクを持って喜ぶ）
  person("human_bowlhair_idle", 22, 102, { name: "おきゃくさん", lines: ["わあ、いろが グラデーションに なってる！ きれい〜。", "ゼリーが キラキラ して、みているだけで うれしくなっちゃう。"] }, true);
  put("kirakira_cup_s_a", 32, 100, { by: 104 });
  put("happiness_01", 22, 82, { by: 120 });
  person("human_curlyhair_idle", -22, 110, { name: "おきゃくさん", lines: ["ホイップの うえに ほしが のってる！ かわいい〜。", "しゃしん とりたく なっちゃうな。"] });
  put("kirakira_cup_s_b", -11, 108, { by: 112, frame: 3 });
  put("expression_love", -22, 90, { by: 140 });
  person("human_mophair_idle", 46, 120, { name: "こども", lines: ["ストローが ささってる！ くるくる すると いろが かわるかな？", "のむのが もったいないくらい きれいだよ。"] }, true);
  put("kirakira_cup_s_a", 56, 118, { by: 122, frame: 4 });
  put("happiness_03", 46, 100, { by: 140 });

  // ---- きらめき（看板・ショーケース・作業台のまわり）
  put("kirakira_spark", -66, 14, { by: 300, frame: 0 });
  put("kirakira_spark", 66, 10, { by: 300, frame: 2 });
  put("kirakira_spark", -24, 56, { by: 300, frame: 1 });
  put("kirakira_spark", 28, 44, { by: 300, frame: 3 });
  put("kirakira_spark", 84, 70, { by: 300, frame: 1 });

  // ---- ラメの粒子（草地全体に重ねる）
  put("kirakira_glitter", 0, 128, { by: 400 });
}
