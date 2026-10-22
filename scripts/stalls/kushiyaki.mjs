/** 串焼き屋（牛串・焼き鳥・たこ唐揚げ）。専用ドット絵は scripts/stalls/kushiyaki.ps1（kushiyaki_*.png） */
export const meta = { id: "kushiyaki", label: "串焼き屋" };

export default function layout(k) {
  for (const n of ["kushiyaki_roof", "kushiyaki_counter", "kushiyaki_post", "kushiyaki_bat", "kushiyaki_cups", "kushiyaki_plate", "kushiyaki_kushitate", "kushiyaki_menu", "kushiyaki_mascot", "kushiyaki_sumi", "kushiyaki_mat"]) k.custom(n);
  k.custom("kushiyaki_nobori", 1, 78);
  k.custom("kushiyaki_sign", undefined, undefined, { frames: 4, fps: 3 }); // 電球がまわる看板
  k.custom("kushiyaki_lantern", undefined, undefined, { frames: 3, fps: 5 }); // 赤提灯の明かりがゆれる
  k.custom("kushiyaki_grill", undefined, undefined, { frames: 4, fps: 6 }); // 炭火がちらつく焼き台
  k.custom("kushiyaki_smoke", 12, 34, { frames: 6, fps: 7 }); // 炭の煙・揚げ鍋の湯気
  k.custom("kushiyaki_fryer", undefined, undefined, { frames: 4, fps: 4 }); // かごが上下して油の泡がはじける揚げ鍋
  const TABLE = k.cropAt(808, 586); // 四角い木のテーブル
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 床のマット（カウンターの前の「ここで買う」場所）
  put("kushiyaki_mat", 26, 110, { sort: "floor" });

  // 柱・日よけ・看板（看板の下の札は日よけの上に重ねる）
  put("kushiyaki_post", -74, 78, { hit: [6, 6] });
  put("kushiyaki_post", 74, 78, { hit: [6, 6] });
  put("kushiyaki_roof", 0, 42, { by: 41 });
  put("kushiyaki_sign", 0, 38, { by: 45 });
  // 赤提灯（日よけのすみから）
  put("kushiyaki_lantern", -74, 62, { by: 82 });
  put("kushiyaki_lantern", 74, 62, { by: 82 });
  // のぼり旗（両脇）
  put("kushiyaki_nobori", -88, 76, { hit: [4, 4] });
  put("kushiyaki_nobori", 88, 76, { hit: [4, 4] });

  // カウンターの上: 炭火の焼き台（左）・揚げ鍋（右）・バット。煙と湯気
  put("kushiyaki_grill", -38, 64, { by: ON_COUNTER });
  put("kushiyaki_smoke", -56, 42, { by: 70 });
  put("kushiyaki_smoke", -36, 42, { by: 70, frame: 3 });
  put("kushiyaki_smoke", -20, 44, { by: 70, frame: 1 });
  put("kushiyaki_fryer", 37, 64, { by: ON_COUNTER });
  put("kushiyaki_bat", 63, 64, { by: ON_COUNTER });

  // カウンターの奥: 焼き台の係と、揚げ物の係
  person("human_spikeyhair_doing", -3, 56, {
    name: "焼き台がかり",
    lines: [
      "いらっしゃい！ 串焼き、やっています！",
      "ぎゅうぐしは、ほっかいどうさんの ぎゅうにくだけを つかっているんだ。",
      "すみびで、じっくり やくよ。うちわで ぱたぱた あおぐと、ひが つよくなるんだ。",
      "やきとりは、たれを つけながら ころころ ひっくり返すと、こうばしく やけるよ。",
    ],
  }, true);
  put("expression_chat", -3, 33, { by: 90 });
  person("human_curlyhair_doing", 13, 56, {
    name: "揚げ物がかり",
    lines: [
      "たこの からあげも あるよ！",
      "たこも、えらびぬいた ものだけを つかう よていなんだ。",
      "あつい あぶらで からっと あげて、かみの いれものに いれて わたすよ。",
      "あげたては あつあつ！ ふーふーして たべてね。",
    ],
  });
  put("expression_chat", 13, 33, { by: 90 });

  // カウンター（炭色の前掛け）
  put("kushiyaki_counter", 0, 80, { hit: [140, 10] });

  // 前のお客さん
  person("human_longhair_idle", 18, 96, { name: "おきゃくさん", lines: ["ここの ぎゅうぐし、にくが ぶあつくて ジューシーなんだよ。", "ほっかいどうさんの ぎゅうにくだけ なんだって！ たのしみ！"] }, false);
  put("happiness_01", 18, 72, { by: 120 });
  person("human_bowlhair_idle", 40, 100, { name: "こども", lines: ["たこの からあげ、さくさくで おいしそう！", "くしを もったまま はしらないように しなきゃね。"] }, true);

  // 店員（呼び込み）
  person("human_mophair_idle", 66, 96, { name: "てんいん", lines: ["くしやきの いいにおいが するでしょ？ すみびで やいているんだよ。", "くしの さきに きをつけて、すわって ゆっくり たべてね。"] }, true);

  // 右手前: テーブル席（串の皿とたこ唐揚げ）
  person("human_shorthair_idle", 62, 118, { name: "おきゃくさん", lines: ["やきとりは、たれも しおも どっちも すき！", "たこの からあげは、あつあつを ふーふーして たべるのが いいよね。"] }, false);
  put(TABLE, 79, 126, { hit: [18, 8] });
  put("kushiyaki_plate", 73, 115, { by: 127 });
  put("kushiyaki_cups", 83, 116, { by: 127 });

  // 左手前: 炭の箱とうちわ、品書き
  put("kushiyaki_menu", -26, 128, { hit: [76, 6] });
  put("kushiyaki_sumi", -80, 104, { hit: [26, 8] });

  // マスコット（牛）と串立て
  put("kushiyaki_mascot", 30, 128, { hit: [16, 6] });
  put("kushiyaki_kushitate", 48, 128, { hit: [12, 6] });
}
