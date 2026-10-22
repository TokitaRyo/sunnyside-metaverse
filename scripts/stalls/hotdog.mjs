/** ホットドッグ屋（ソーセージをパンにはさんだ屋台）。専用ドット絵は scripts/stalls/hotdog.ps1（hotdog_*.png） */
export const meta = { id: "hotdog", label: "ホットドッグ屋" };

export default function layout(k) {
  for (const n of ["hotdog_roof", "hotdog_counter", "hotdog_post", "hotdog_buns", "hotdog_tray", "hotdog_wrap", "hotdog_trays", "hotdog_sauces", "hotdog_mascot", "hotdog_menu", "hotdog_mat"]) k.custom(n);
  k.custom("hotdog_nobori", 1, 84);
  k.custom("hotdog_sign", undefined, undefined, { frames: 2, fps: 2 }); // 看板のふちの電球が交互に点滅する
  k.custom("hotdog_grill", undefined, undefined, { frames: 4, fps: 3 }); // 炭火がちらつき、ソーセージがころがって焼き色が動く
  k.custom("hotdog_steam", undefined, undefined, { frames: 6, fps: 7 }); // ゆらゆら上る湯気
  const TABLE = k.cropAt(808, 586); // 四角い木のテーブル
  const STOOL = k.cropAt(805, 543); // 小さな丸椅子
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 床のマット（カウンターの前の「ここで買う」場所）
  put("hotdog_mat", 0, 110, { sort: "floor" });

  // 柱・日よけ・看板
  put("hotdog_post", -66, 78, { hit: [6, 6] });
  put("hotdog_post", 66, 78, { hit: [6, 6] });
  put("hotdog_roof", 0, 38, { by: 41 });
  put("hotdog_sign", 0, 20);
  // のぼり旗（両脇）
  put("hotdog_nobori", -92, 76, { hit: [4, 4] });
  put("hotdog_nobori", 82, 76, { hit: [4, 4] });

  // カウンターの上: グリル（湯気つき）・焼き上がりのトレイ・ケチャップとマスタード・包み
  put("hotdog_grill", -34, 64, { by: ON_COUNTER });
  put("hotdog_steam", -46, 42, { by: 90 });
  put("hotdog_steam", -24, 42, { by: 90, frame: 3 });
  put("hotdog_tray", 14, 64, { by: ON_COUNTER });
  put("hotdog_sauces", 38, 64, { by: ON_COUNTER });
  put("hotdog_wrap", 57, 64, { by: ON_COUNTER });

  // カウンターの奥: 店主（グリル係）と、パン係
  person("human_shorthair_doing", -3, 56, {
    name: "ホットドッグやさん",
    lines: [
      "いらっしゃい！ ホットドッグ、やっています！",
      "パンにソーセージをはさんだ食べものだよ。グリルでじゅーっと焼いて、こんがり焼き色をつけるんだ。",
      "焼けたソーセージを、あたたかいパンにはさんで、ケチャップとマスタードをぎざぎざっとかけるよ。",
      "あつあつだから、気をつけてね。いいにおいがしてきたら、できあがり！",
    ],
  }, true);
  put("expression_chat", -3, 33, { by: 90 });
  person("human_spikeyhair_doing", 46, 56, {
    name: "パンがかり",
    lines: [
      "わたしは、パンの係だよ。ふんわりしたパンに、切れ目を入れておくんだ。",
      "そこに、焼きたてのソーセージを すぽっとはさむよ。",
      "ケチャップとマスタードの線は、ぎざぎざにかけると、きれいなんだ！",
    ],
  }, false);

  // カウンター（赤い前掛けにホットドッグの柄）
  put("hotdog_counter", 0, 80, { hit: [128, 10] });

  // 前のお客さん
  person("human_longhair_idle", 0, 98, { name: "おきゃくさん", lines: ["ここのホットドッグ、焼きたてのいいにおい！", "ケチャップとマスタードの線が、きれいだなあ。"] }, false);
  put("happiness_01", 0, 74, { by: 120 });
  person("human_bowlhair_idle", 34, 102, { name: "こども", lines: ["グリルの上で、ソーセージがころころ動くんだよ。おもしろい！", "ぼくも、あつあつを食べたいなあ。"] }, true);

  // 左: パンのかごと、包み係
  person("human_curlyhair_doing", -72, 96, {
    name: "つつみがかり",
    lines: [
      "できあがったホットドッグは、紙のトレイにのせたり、紙でくるんでわたすんだ。",
      "手がよごれないように、くるっと包むのがコツだよ。",
      "パンは、かごにいっぱいつんであるよ。いつでもおいで！",
    ],
  }, true);
  put("hotdog_buns", -80, 128, { hit: [30, 8] });

  // 手前: メニューの立て看板、マスコット
  put("hotdog_menu", -38, 127, { hit: [50, 6] });
  put("hotdog_mascot", 18, 128, { hit: [18, 6] });

  // 右手前: 木のテーブルに包みと紙トレイ、丸椅子、休んでいるお客さん
  put(TABLE, 84, 126, { hit: [18, 8] });
  put("hotdog_wrap", 78, 115, { by: 127 });
  put("hotdog_trays", 88, 116, { by: 127 });
  put(STOOL, 66, 128, { hit: [8, 6] });
  person("human_mophair_idle", 56, 112, { name: "おきゃくさん", lines: ["テーブルで、ゆっくり食べるのがすきなんだ。", "紙につつんであると、持ち歩けて べんりだよ。"] }, true);
}
