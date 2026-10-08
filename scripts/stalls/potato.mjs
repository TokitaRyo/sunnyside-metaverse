/** ポテト屋（フライドポテトの屋台）。専用ドット絵は scripts/stalls/potato.ps1（potato_*.png） */
export const meta = { id: "potato", label: "ポテト", island: "浮島 17" };

export default function layout(k) {
  for (const n of ["potato_sign", "potato_roof", "potato_counter", "potato_post", "potato_cups", "potato_shakers", "potato_basket_s", "potato_tornado", "potato_crate", "potato_sack", "potato_menu", "potato_mascot", "potato_mat"]) k.custom(n);
  k.custom("potato_nobori", 1, 78);
  k.custom("potato_fryer", undefined, undefined, { frames: 4, fps: 3 }); // 揚げかごが上がり下がりして、油の泡がはじける
  k.custom("potato_warmer", undefined, undefined, { frames: 3, fps: 4 }); // 保温ランプのオレンジの光がゆれる
  k.custom("potato_steam", undefined, undefined, { frames: 6, fps: 7 }); // ゆらゆら上る湯気
  const TABLE = k.cropAt(808, 586); // 四角い木のテーブル
  const STOOL = k.cropAt(805, 543); // 小さな丸椅子
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 床のマット（カウンターの前の「ここで買う」場所）
  put("potato_mat", 0, 110, { sort: "floor" });

  // 柱・日よけ・看板
  put("potato_post", -66, 78, { hit: [6, 6] });
  put("potato_post", 66, 78, { hit: [6, 6] });
  put("potato_roof", 0, 38, { by: 41 });
  put("potato_sign", 0, 20);
  // のぼり旗（両脇）
  put("potato_nobori", -92, 76, { hit: [4, 4] });
  put("potato_nobori", 80, 76, { hit: [4, 4] });

  // カウンターの上: フライヤー（かごが上下する）・調味料・保温ランプ・カップ
  put("potato_fryer", -38, 64, { by: ON_COUNTER });
  put("potato_steam", -50, 43, { by: 90 });
  put("potato_steam", -26, 43, { by: 90, frame: 3 });
  put("potato_warmer", 28, 64, { by: ON_COUNTER });
  put("potato_steam", 24, 35, { by: 90, frame: 2 });
  put("potato_cups", 51, 64, { by: ON_COUNTER });
  put("potato_shakers", 2, 64, { by: ON_COUNTER });

  // カウンターの奥: 店主
  person("human_shorthair_doing", 4, 56, {
    name: "ポテトやさん",
    lines: [
      "いらっしゃい！ ポテト、やっています！",
      "じゃがいもを切って、あつい油でからっと揚げるんだ。きつね色になったらできあがり！",
      "いいにおいがしてきたら、できたてのしるし。あつあつをどうぞ！",
      "揚げたては、ほくほくでおいしいよ。やけどに気をつけて、ふーふーしてね！",
    ],
  }, true);
  put("expression_chat", 4, 33, { by: 90 });

  // カウンター（赤い前掛け）
  put("potato_counter", 0, 80, { hit: [128, 10] });

  // 前のお客さん
  person("human_longhair_idle", 0, 98, { name: "おきゃくさん", lines: ["ここのポテト、外はかりっと、中はほくほくなんだよ。", "わたしは、あつあつをすぐ食べたい！"] }, false);
  put("happiness_01", 0, 74, { by: 120 });
  person("human_bowlhair_idle", 24, 104, { name: "こども", lines: ["いいにおい！ 見ているだけで、食べたくなるなあ。", "ぼくは、いっぱい食べたいなあ！"] }, true);

  // 右: じゃがいもの箱と麻袋、トルネードポテトの台
  put("potato_crate", 82, 102, { hit: [24, 8] });
  put("potato_sack", 71, 90, { hit: [10, 6] });
  put("potato_tornado", 47, 125, { hit: [28, 6] });

  // 左: メニューの立て看板、マスコット
  put("potato_menu", -64, 127, { hit: [58, 6] });
  put("potato_mascot", -18, 128, { hit: [16, 6] });

  // 右手前: 木のテーブルにバスケット、丸椅子
  put(TABLE, 84, 126, { hit: [18, 8] });
  put("potato_basket_s", 84, 115, { by: 127 });
  put(STOOL, 66, 128, { hit: [8, 6] });
}
