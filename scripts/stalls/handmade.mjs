/** クラゲファクトリー（id は handmade のまま）。専用ドット絵は scripts/stalls/handmade.ps1（handmade_*.png）。夜の海の底のような地面で、光るクラゲと手作り雑貨を作る工房 */
export const meta = { id: "handmade", label: "クラゲファクトリー" };

export default function layout(k) {
  // ---- アニメ（横一列のシート）
  k.custom("handmade_sparkle", undefined, undefined, { frames: 4, fps: 3 }); // 床のプランクトンのきらめき
  k.custom("handmade_sign", undefined, undefined, { frames: 8, fps: 6 }); // 看板（歯車・ネオン・光・触手）
  k.custom("handmade_garland", undefined, undefined, { frames: 4, fps: 3 }); // 豆電球のまたたき
  for (const c of ["c", "p", "v"]) k.custom(`handmade_hang_${c}`, undefined, undefined, { frames: 6, fps: 4 }); // 吊るしクラゲ
  for (const c of ["a", "b", "c"]) k.custom(`handmade_drift_${c}`, undefined, undefined, { frames: 8, fps: 5 }); // 浮かぶ大きなクラゲ
  k.custom("handmade_bubbles", undefined, undefined, { frames: 8, fps: 5 });
  for (const c of ["c", "v"]) k.custom(`handmade_lamp_${c}`, undefined, undefined, { frames: 4, fps: 3 });
  for (const c of ["p", "c"]) k.custom(`handmade_bottle_${c}`, undefined, undefined, { frames: 4, fps: 3 });
  k.custom("handmade_candle", undefined, undefined, { frames: 4, fps: 6 });
  k.custom("handmade_tank", undefined, undefined, { frames: 6, fps: 4 });
  k.custom("handmade_rack", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("handmade_tube", undefined, undefined, { frames: 8, fps: 5 }); // クラゲ培養管
  k.custom("handmade_flask", undefined, undefined, { frames: 4, fps: 5 });
  k.custom("handmade_lantern", undefined, undefined, { frames: 4, fps: 5 });
  // ---- 静止
  for (const n of ["handmade_floor", "handmade_pools", "handmade_awning", "handmade_wall", "handmade_counter", "handmade_beads", "handmade_shells", "handmade_gears", "handmade_hoop", "handmade_table"]) k.custom(n);
  k.custom("handmade_nobori", 13, 90);

  const { put, person } = k;
  const ON_COUNTER = 81; // カウンター(足元80)の上の物は手前に描く
  const ON_TABLE = 113; // 前のテーブル(足元112)の上の物

  // ---- 床: 暗い夜の海底 → 光だまり → きらめき（floor は置いた順に重なる）
  put("handmade_floor", 0, 128, { sort: "floor", by: 0 });
  put("handmade_pools", 0, 128, { sort: "floor", by: 1 });
  put("handmade_sparkle", 0, 128, { sort: "floor", by: 2 });

  // ---- 店の構え: 奥の壁（柱・カーテン・棚・三日月）→ 天幕 → 豆電球 → 看板
  put("handmade_wall", 0, 58, { by: 50, hit: [124, 6] });
  put("handmade_awning", 0, 34, { by: 60 });
  put("handmade_garland", 0, 41, { by: 61 });
  put("handmade_sign", 0, 28, { by: 62 }); // 板の上が草地の上端より約10pxはみ出す。下の触手が天幕に垂れる

  // ---- 天幕から吊るしたクラゲ（脈打つ）
  // 足元(foot)が絵の下端。天幕のふち(y=31)から糸を垂らす
  put("handmade_hang_c", -57, 59, { by: 95, frame: 0 });
  put("handmade_hang_p", -33, 59, { by: 95, frame: 2 });
  put("handmade_hang_v", 41, 59, { by: 95, frame: 4 });
  put("handmade_hang_c", 62, 59, { by: 95, frame: 3 });

  // ---- 店番
  person("human_longhair_doing", 12, 58, {
    name: "みなみ",
    lines: [
      "いらっしゃいませ！ ここは「クラゲファクトリー」。クラゲを つくる こうぼうの ような、てづくりの おみせだよ。",
      "クラゲは よるに ひかるんだよ。だから ここは、よるの うみの そこみたいに しているの。",
      "ひかる ランプや びんの クラゲ、きらきらの チャームも あるよ。ガラスかんの なかでも クラゲが およいでるでしょ？",
      "うえを ふわふわ およぐ クラゲも みてね。さわれないけど、かわいいでしょ？",
    ],
  });
  put("expression_chat", 12, 35, { by: 100 });

  // ---- カウンターと上の作品
  put("handmade_counter", 0, 80, { hit: [114, 10] });
  put("handmade_flask", -57, 62, { by: ON_COUNTER });
  put("handmade_lamp_c", -45, 62, { by: ON_COUNTER });
  put("handmade_bottle_p", -33, 62, { by: ON_COUNTER });
  put("handmade_beads", -20, 62, { by: ON_COUNTER });
  put("handmade_candle", -6, 62, { by: ON_COUNTER, frame: 3 });
  put("handmade_bottle_c", 28, 62, { by: ON_COUNTER, frame: 2 });
  put("handmade_gears", 41, 62, { by: ON_COUNTER });
  put("handmade_lamp_v", 54, 62, { by: ON_COUNTER, frame: 2 });
  put("handmade_flask", 66, 62, { by: ON_COUNTER, frame: 2 });

  // ---- 左: アクセサリー台と前のテーブル
  put("handmade_rack", -81, 128, { hit: [26, 6] });
  put("handmade_table", -48, 112, { hit: [48, 8] });
  put("handmade_bottle_c", -66, 97, { by: ON_TABLE, frame: 1 });
  put("handmade_lamp_v", -57, 97, { by: ON_TABLE, frame: 3 });
  put("handmade_hoop", -45, 97, { by: ON_TABLE });
  put("handmade_shells", -32, 97, { by: ON_TABLE });

  // ---- 右: 水槽と月の街灯
  put("handmade_tank", 56, 112, { hit: [30, 8] });
  put("handmade_tube", 84, 128, { hit: [14, 6], hxOff: -2 });

  // ---- 入口の提灯（道の両側）
  put("handmade_lantern", -22, 126, { hit: [6, 4] });
  put("handmade_lantern", 22, 126, { hit: [6, 4], frame: 2 });

  // ---- のぼり
  put("handmade_nobori", -83, 88, { hit: [4, 4], by: 61 });
  put("handmade_nobori", 83, 88, { hit: [4, 4], by: 61 });

  // ---- 客
  person("human_curlyhair_idle", -13, 110, {
    name: "おきゃくさん",
    lines: [
      "かんばんの ギアが くるくる まわって、かっこいいね。",
      "このクラゲの ランプ、ほんものみたいに ひかるの。よるに みると もっと きれいなんだって。",
    ],
  }, true);
  person("human_shorthair_idle", 30, 118, {
    name: "おきゃくさん",
    lines: [
      "みて、おおきな ガラスの くだの なかで クラゲが ういてる！ ぷくぷくの あわも きれいだね。",
      "ここは クラゲファクトリー。ほんとうに クラゲを つくっている みたいで わくわくするよ。",
    ],
  });
  person("human_mophair_idle", 4, 98, {
    name: "こども",
    lines: [
      "クラゲが あたまの うえを およいでる！",
      "ぼくも ひとつ、きらきらの チャームが ほしいなあ。",
    ],
  });
  put("expression_love", 4, 76, { by: 120 });

  // ---- 浮かぶ大きなクラゲ（人より手前にふわふわ。通れる）
  put("handmade_drift_a", 42, 126, { by: 300, frame: 0 });
  put("handmade_drift_b", -34, 104, { by: 300, frame: 3 });
  put("handmade_drift_c", -4, 126, { by: 300, frame: 5 });
  // ---- 泡
  put("handmade_bubbles", 38, 112, { by: 301 });
  put("handmade_bubbles", -84, 100, { by: 301, frame: 4 });
  put("handmade_bubbles", -8, 90, { by: 301, frame: 2 });
}
