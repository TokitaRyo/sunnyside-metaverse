/** 図書委員会。専用ドット絵は scripts/stalls/library.ps1（library_*.png）。奥は本棚の壁と窓、まんなかに貸出カウンター、左に低い本棚と読書スペース、手前におすすめの平積み台、右に返却ボックス・ブックトラック・脚立 */
export const meta = { id: "library", label: "図書委員会" };

export default function layout(k) {
  // 静止
  for (const n of ["floor", "wall", "sign", "counter", "reader", "stamp", "cards", "stand", "bookmarks", "lowshelf", "chair_back", "chair_front", "rug", "zabuton", "rtable", "lamp", "pile", "truck", "return", "ladder", "plant", "nobori"]) k.custom(`library_${n}`);
  // アニメ（横一列のシート）
  k.custom("library_cat", undefined, undefined, { frames: 4, fps: 2 });
  k.custom("library_book", undefined, undefined, { frames: 6, fps: 3 });
  k.custom("library_glow", 22, 22, { frames: 4, fps: 5 });
  k.custom("library_beam", undefined, undefined, { frames: 6, fps: 4 });
  const { put, person, blocker } = k;
  const ON_COUNTER = 85; // カウンター(足元84)の上に置く物は手前に描く

  // ---- 床・奥の壁・看板
  put("library_floor", 0, 128, { sort: "floor" });
  put("library_wall", 0, 56, { by: 50, hit: [176, 4] });
  put("library_sign", 0, 10, { by: 55 });
  put("library_nobori", -87, 62, { by: 62 });

  // ---- 貸出カウンターと図書委員
  put("library_counter", 0, 84, { hit: [90, 10] });
  person("human_longhair_doing", 4, 57, {
    name: "としょいいんかい",
    lines: [
      "いらっしゃい！ ここは としょいいんかいの ほんの コーナーだよ。",
      "かりたい ほんが きまったら、ここの カウンターへ もってきてね。",
      "まんなかの だいには、いいんの みんなが えらんだ「おすすめの いっさつ」が ならんでいるよ。ポップも てがきなんだ。",
      "ほんは そっと ひらこうね。よみおわったら へんきゃくボックスへ。また あそびにきてね！",
    ],
  });
  put("library_cat", -32, 64, { by: ON_COUNTER });
  put("library_stand", -14, 64, { by: ON_COUNTER });
  put("library_bookmarks", 14, 64, { by: ON_COUNTER });
  put("library_reader", 24, 64, { by: ON_COUNTER });
  put("library_stamp", 34, 64, { by: ON_COUNTER });
  put("library_cards", 42, 64, { by: ON_COUNTER });

  // ---- 左: 絵本の低い本棚
  put("library_lowshelf", -68, 86, { hit: [38, 8] });

  // ---- 左下: 読書スペース（ラグ・ひじかけ椅子・ランプ・丸テーブル・座布団）
  put("library_rug", -58, 126, { sort: "floor" });
  blocker(-70, 116, 22, 10);
  put("library_chair_back", -70, 116, { by: 112 });
  put("library_chair_front", -70, 116, { by: 114 });
  k.put("human_bowlhair_idle", -70, 112, {
    by: 113,
    hit: [12, 8],
    npc: {
      name: "どくしょちゅう",
      lines: [
        "しーっ…… いま、いいところなんだ。",
        "ふかふかの いすで よむと、じかんを わすれちゃうよ。",
        "ほんの なかでは、どこへでも いけるんだ。",
      ],
    },
  });
  put("expression_love", -70, 90, { by: 120 });
  put("library_lamp", -88, 106, { hit: [8, 4] });
  put("library_glow", -88, 62, { by: 300 });
  put("library_rtable", -38, 118, { hit: [16, 6] });
  put("library_book", -41, 105, { by: 119 });
  put("library_zabuton", -56, 127);
  put("library_zabuton", -24, 128);

  // ---- 手前: おすすめの平積み台
  put("library_pile", 16, 128, { hit: [58, 8] });

  // ---- 右: 返却ボックス・脚立・ブックトラック・植木
  put("library_plant", 87, 98, { hit: [14, 6] });
  put("library_return", 62, 88, { hit: [26, 8] });
  put("library_ladder", 86, 62, { by: 62 });
  put("library_truck", 74, 126, { hit: [30, 6] });

  // ---- 客
  person("human_mophair_idle", -47, 100, {
    name: "おきゃくさん",
    lines: [
      "どの ほんに しようかな。ひょうしの いろで えらぶのも たのしいよ。",
      "えほんも ずかんも ものがたりも、いろんな ほんが あるね。",
    ],
  });
  put("expression_chat", -47, 80, { by: 130 });
  person("human_spikeyhair_idle", 8, 128, {
    name: "おきゃくさん",
    lines: [
      "この おすすめポップ、いいんの ひとが かいたんだって。",
      "ポップを よむと、ほんが よみたくなるよ。",
    ],
  }, true);

  // ---- 光の筋とほこり（窓から差し込む）
  put("library_beam", 14, 107, { by: 400 });
}
