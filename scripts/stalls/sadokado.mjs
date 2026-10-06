/** 茶華道部（茶道＋華道）。専用ドット絵は scripts/stalls/sadokado.ps1（sadokado_*.png） */
export const meta = { id: "sadokado", label: "茶華道部", island: "浮島 13" };

export default function layout(k) {
  for (const n of [
    "sadokado_sign", "sadokado_roof", "sadokado_room", "sadokado_tatami", "sadokado_post",
    "sadokado_kama", "sadokado_mizusashi", "sadokado_natsume", "sadokado_chawan", "sadokado_chasen", "sadokado_tray",
    "sadokado_nerikiri", "sadokado_dango", "sadokado_bench", "sadokado_umbrella",
    "sadokado_stand", "sadokado_ike_suiban", "sadokado_ike_tsubo", "sadokado_ike_take", "sadokado_ike_small",
    "sadokado_tag_kado", "sadokado_tag_nodate", "sadokado_slabs",
    "sadokado_lantern", "sadokado_fence", "sadokado_gravel", "sadokado_tsukubai",
  ]) k.custom(n);
  // アニメ: 竹のゆれ / のぼりのはためき / 湯気 / 舞う紅葉と花びら
  k.custom("sadokado_bamboo", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("sadokado_nobori_cha", 2, undefined, { frames: 4, fps: 4 });
  k.custom("sadokado_nobori_hana", 2, undefined, { frames: 4, fps: 4 });
  k.custom("sadokado_steam", undefined, undefined, { frames: 6, fps: 6 });
  k.custom("sadokado_petals", undefined, undefined, { frames: 12, fps: 6 });
  const { put, person, blocker } = k;

  // ---- 地面: 玉砂利と飛び石（入口）、展示台の下の石畳
  put("sadokado_gravel", 0, 128, { sort: "floor" });
  put("sadokado_slabs", 66, 110, { sort: "floor", by: 0 });

  // ---- 奥の竹垣と、垣の向こうの竹
  put("sadokado_fence", -72, 54, { by: 36, hit: [48, 6] });
  put("sadokado_fence", 72, 54, { by: 36, hit: [48, 6] });
  put("sadokado_bamboo", -66, 38, { by: 20 });
  put("sadokado_bamboo", 66, 38, { by: 20, flip: true, frame: 2 });

  // ---- 茶室（座敷）: 床・奥の壁・屋根・看板・柱
  put("sadokado_tatami", 0, 94, { sort: "floor", by: 1 });
  put("sadokado_room", 0, 70, { by: 50 });
  blocker(0, 70, 92, 6); // 奥の壁
  blocker(-47, 94, 6, 28); // 左の柱まわり
  blocker(47, 94, 6, 28); // 右の柱まわり
  blocker(0, 95, 92, 6); // 縁側（手前の縁）
  put("sadokado_roof", 0, 38, { by: 41 });
  put("sadokado_sign", 0, 16, { by: 42 });
  put("sadokado_post", -45, 94, { by: 97 });
  put("sadokado_post", 45, 94, { by: 97 });

  // 点前（お茶をたてる所）
  put("sadokado_kama", -24, 84, { by: 86 });
  put("sadokado_steam", -24, 64, { by: 95 });
  put("sadokado_mizusashi", 31, 80, { by: 83 });
  person("human_longhair_doing", 4, 80, {
    name: "ちゃどうぶのひと",
    lines: [
      "いらっしゃいませ。ちゃかどうぶの のだてへ ようこそ。",
      "おちゃを のむまえに、まず おかしを どうぞ。あまいものを たべてから のむと、おちゃが おいしいよ。",
      "ちゃわんは、いちばん きれいな ところ（しょうめん）を さけて、すこし まわしてから のむんだ。",
      "ちゃどうでは 「わ・けい・せい・じゃく」 という ことばを たいせつにするよ。ゆっくり していってね。",
    ],
  });
  put("expression_chat", 4, 62, { by: 99 });
  put("sadokado_tray", 6, 90, { by: 91 });
  put("sadokado_chawan", -2, 85, { by: 92 });
  put("sadokado_chasen", 11, 86, { by: 92 });
  put("sadokado_natsume", 20, 85, { by: 92 });
  put("sadokado_ike_take", 37, 84, { by: 86 }); // 茶花（竹の花入れ）

  // ---- 野点: 赤い野点傘と、緋毛氈をかけた縁台
  put("sadokado_umbrella", -72, 101, { by: 105, hit: [6, 4] });
  put("sadokado_bench", -70, 104, { by: 106, hit: [44, 6] });
  put("sadokado_dango", -68, 88, { by: 108 });
  put("sadokado_nerikiri", -54, 88, { by: 108 });
  person("human_curlyhair_idle", -84, 83, {
    name: "おきゃくさん",
    lines: ["あかいかさの したは ほっとするね。", "おだんご、もちもち！ おちゃは すこし にがいけど、おかしと いっしょなら ちょうどいいんだ。"],
  });
  person("human_bowlhair_idle", -24, 116, {
    name: "おきゃくさん",
    lines: ["おちゃって、ゆっくり のむと こころが おちつくね。", "ちゃせきの おかしは、めでも たのしめるんだよ。"],
  });

  // ---- 華道の展示台
  put("sadokado_stand", 71, 92, { by: 92, hit: [46, 8] });
  put("sadokado_ike_suiban", 59, 78, { by: 93 });
  put("sadokado_ike_small", 74, 66, { by: 91 });
  put("sadokado_ike_tsubo", 85, 78, { by: 93 });
  put("sadokado_tag_kado", 82, 127, { by: 126, hit: [10, 4] });
  person("human_mophair_idle", 60, 112, {
    name: "かどうぶのひと",
    lines: [
      "ここは かどうの てんじ。はなを いけるのが かどうだよ。",
      "けんざんに はなを さして、かたちを ととのえるんだ。みずを はった うつわには、うかべるように いけることも あるよ。",
      "ながい えだ・なかくらいの えだ・みじかい えだ。この3ぽんで 「てん・ち・じん」を あらわすこともあるんだ。",
      "はなを ふやすより、あえて すきまを のこして たのしむのも かどうの おもしろさだよ。",
    ],
  }, true);
  put("expression_chat", 60, 94, { by: 130 });
  person("human_spikeyhair_idle", 30, 120, {
    name: "おきゃくさん",
    lines: ["おなじ はなでも、いけかたで ぜんぜん ちがって みえるね。", "すすきと もみじ、あきの においが するなあ。"],
  });

  // ---- 庭の飾り
  put("sadokado_lantern", -44, 124, { hit: [8, 5] });
  put("sadokado_lantern", 44, 124, { hit: [8, 5] });
    put("sadokado_tag_nodate", -86, 127, { by: 126, hit: [10, 4] });
  put("sadokado_tsukubai", -62, 126, { by: 126, hit: [18, 6] });
  put("sadokado_nobori_cha", -92, 58, { by: 58, hit: [4, 3], hxOff: 0 });
  put("sadokado_nobori_hana", 92, 58, { by: 58, hit: [4, 3], flip: true });

  // ---- 舞う紅葉と花びら（上に重ねる）
  put("sadokado_petals", 70, 100, { by: 200 });
  put("sadokado_petals", -64, 112, { by: 200, frame: 6 });
}
