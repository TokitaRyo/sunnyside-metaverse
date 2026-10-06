/** たこ焼き屋。専用ドット絵は scripts/stalls/takoyaki.ps1（takoyaki_*.png） */
export const meta = { id: "takoyaki", label: "たこ焼き屋", island: "浮島 19" };

export default function layout(k) {
  for (const n of ["takoyaki_sign", "takoyaki_lantern", "takoyaki_menu", "takoyaki_pan", "takoyaki_tray", "takoyaki_tray_s", "takoyaki_condi", "takoyaki_picks", "takoyaki_mascot", "takoyaki_mat", "takoyaki_counter", "takoyaki_roof", "takoyaki_post"]) k.custom(n);
  k.custom("takoyaki_nobori", 1, 78);
  k.custom("takoyaki_steam", 11, 28, { frames: 6, fps: 7 }); // ゆらゆら上る湯気
  k.custom("takoyaki_tray_a", undefined, undefined, { frames: 3, fps: 4 }); // かつお節がおどる舟皿
  const TABLE = k.cropRect(768, 538, 14, 13); // 白いクロスの丸いテーブル
  const BARREL = "spr_deco_barrel_closed"; // 樽の腰かけ
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 床のマット（カウンターの前の「ここで買う」場所）
  put("takoyaki_mat", 0, 110, { sort: "floor" });

  // 柱・のれん屋根・看板
  put("takoyaki_post", -58, 78, { hit: [6, 6] });
  put("takoyaki_post", 58, 78, { hit: [6, 6] });
  put("takoyaki_roof", 0, 42, { by: 41 });
  put("takoyaki_sign", 0, 20);
  // 提灯（屋根のすみから）
  put("takoyaki_lantern", -66, 58, { by: 80 });
  put("takoyaki_lantern", 66, 58, { by: 80 });
  // のぼり旗（両脇）
  put("takoyaki_nobori", -92, 76, { hit: [4, 4] });
  put("takoyaki_nobori", 80, 76, { hit: [4, 4] });

  // カウンターの奥: たこ焼き器（屋根より奥）・湯気・店主
  put("takoyaki_pan", -34, 70, { by: 40 });
  put("takoyaki_steam", -33, 53, { by: 70 });
  put("takoyaki_steam", -12, 52, { by: 70, frame: 3 });
  person("human_spikeyhair_doing", 4, 56, {
    name: "たこ焼き屋さん",
    lines: [
      "いらっしゃい！ たこ焼き、やっています！",
      "まるい穴にとろとろの生地を流して、たこをひとつぶずつ入れるんだ。",
      "ピックでくるっとひっくり返すと、まんまるになるよ。ここがうでの見せどころ！",
      "ソースとマヨネーズ、青のりとかつお節をかけて、あつあつをどうぞ！",
    ],
  }, true);
  put("expression_chat", 4, 33, { by: 90 });

  // カウンター（紺と白の市松の前掛け）と、その上の舟皿・ピック
  put("takoyaki_counter", 0, 80, { hit: [116, 10] });
  put("takoyaki_tray_a", 25, 64, { by: ON_COUNTER });
  put("takoyaki_condi", 49, 64, { by: ON_COUNTER });
  put("takoyaki_picks", -3, 64, { by: ON_COUNTER });

  // 前のお客さん
  person("human_longhair_idle", -14, 98, { name: "おきゃくさん", lines: ["ここのたこ焼き、外はかりっと、中はとろっとなんだよ。", "ふーふーしてから食べないと、やけどしちゃうよ！"] }, false);
  put("happiness_01", -14, 74, { by: 120 });
  person("human_bowlhair_idle", 22, 106, { name: "こども", lines: ["かつお節がゆらゆらおどるの、おもしろい！", "ぼくはマヨネーズ多めがすき！"] }, true);

  // テーブル席（右手前）: 丸いテーブルに舟皿と調味料、樽の腰かけ
  put(TABLE, 66, 116, { hit: [12, 7] });
  put("takoyaki_tray_s", 66, 106, { by: 117 });
  put("spr_deco_mug_01", 74, 110, { by: 117 });
  put("spr_deco_crate_01", 86, 98);
  put(BARREL, 50, 122, { hit: [10, 6] });
  put(BARREL, 84, 124, { hit: [10, 6] });

  // メニューの立て看板（左手前）とマスコット
  put("takoyaki_menu", -68, 127, { hit: [44, 6] });
  put("takoyaki_mascot", -36, 122, { hit: [16, 6] });
}
