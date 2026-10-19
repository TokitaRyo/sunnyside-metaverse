/** くらげファクトリー（id は handmade のまま）。専用ドット絵は scripts/stalls/handmade.ps1（handmade_*.png）。夜の海の底のような地面に、光るクラゲを飾って、5つの体験コーナー（ラテキャンドル作り・キャンドルすくい・ぷるぷる石鹸作り・オイルキーホルダー・スライムキーホルダー）を並べる */
export const meta = { id: "handmade", label: "くらげファクトリー" };

export default function layout(k) {
  // ---- アニメ（横一列のシート）
  k.custom("handmade_sparkle", undefined, undefined, { frames: 4, fps: 3 }); // 床のプランクトンのきらめき
  k.custom("handmade_sign", undefined, undefined, { frames: 8, fps: 6 }); // 看板（歯車・ネオン・光・触手）
  k.custom("handmade_garland", undefined, undefined, { frames: 4, fps: 3 }); // 豆電球のまたたき
  for (const c of ["c"]) k.custom(`handmade_drift_${c}`, undefined, undefined, { frames: 8, fps: 5 }); // 浮かぶクラゲ（飾り。主役は体験コーナー）
  k.custom("handmade_bubbles", undefined, undefined, { frames: 8, fps: 5 });
  k.custom("handmade_pool", undefined, undefined, { frames: 8, fps: 5 }); // キャンドルすくいのプール（水面がゆれて、キャンドルが浮かぶ）
  k.custom("handmade_latte_pot", undefined, undefined, { frames: 4, fps: 4 }); // ろうの鍋（ゆげ）とピック
  k.custom("handmade_soap_jelly", undefined, undefined, { frames: 4, fps: 5 }); // ぷるぷる揺れる石鹸
  k.custom("handmade_soap_bowl", undefined, undefined, { frames: 4, fps: 4 }); // 混ぜるボウル
  k.custom("handmade_slime_bowl", undefined, undefined, { frames: 6, fps: 5 }); // スライムのボウルと混ぜる棒
  k.custom("handmade_slime_shelf", undefined, undefined, { frames: 4, fps: 3 }); // 色の素のボトルと瓶のスライム
  k.custom("handmade_oil_display", undefined, undefined, { frames: 6, fps: 3 }); // オイルキーホルダーの展示（ラメ・星・ビーズがゆっくり動く）
  k.custom("handmade_oil_mats", undefined, undefined, { frames: 4, fps: 3 }); // 素材（オイル・ラメ・ビーズ）
  // ---- 静止
  for (const n of ["handmade_floor", "handmade_pools", "handmade_awning", "handmade_wall", "handmade_bench_latte", "handmade_bench_soap", "handmade_bench_slime", "handmade_bench_oil", "handmade_latte_mugs"]) k.custom(n);
  k.custom("handmade_nobori", 13, 90);

  const { put, person, blocker } = k;
  const ON_BENCH = 83; // 奥の作業台(足元82)の上の物は手前に描く
  const ON_FRONT = 129; // 手前右の作業台(足元128)の上の物

  // ---- 床: 暗い夜の海底 → 光だまり → きらめき（floor は置いた順に重なる）
  put("handmade_floor", 0, 128, { sort: "floor", by: 0 });
  put("handmade_pools", 0, 128, { sort: "floor", by: 1 });
  put("handmade_sparkle", 0, 128, { sort: "floor", by: 2 });

  // ---- 店の構え: 奥の壁（柱・カーテン・ペナント）→ 天幕 → 豆電球 → 看板
  put("handmade_wall", 0, 58, { by: 10 });
  put("handmade_awning", 0, 34, { by: 40 });
  put("handmade_garland", 0, 41, { by: 41 });
  put("handmade_sign", 0, 28, { by: 62 }); // 板の上が草地の上端より約10pxはみ出す。下の触手が天幕に垂れる

  // ---- のぼり（奥の作業台の後ろ。上にのびる）
  put("handmade_nobori", -91, 62, { by: 30 });
  put("handmade_nobori", 91, 62, { by: 30 });

  // ---- 奥の列: 作業台3つ（左から ぷるぷる石鹸作り / ラテキャンドル作り / スライムキーホルダー）
  put("handmade_bench_soap", -61, 82, { hit: [54, 26] });
  put("handmade_bench_latte", 0, 82, { hit: [64, 26] });
  put("handmade_bench_slime", 61, 82, { hit: [54, 26] });
  blocker(-93, 82, 8, 30); // 作業台の端から奥へ回り込めないように
  blocker(93, 82, 8, 30);

  // 石鹸
  put("handmade_soap_jelly", -76, 54, { by: ON_BENCH });
  put("handmade_soap_bowl", -56, 54, { by: ON_BENCH });
  person("human_shorthair_doing", -43, 50, {
    name: "あおい",
    lines: [
      "ようこそ！ ここは ぷるぷる せっけんづくりの コーナーだよ。",
      "かたに とうめいな ざいりょうを いれて かためると、ゼリーみたいに ぷるぷるの せっけんに なるの。",
      "クラゲや ほしや かいがらの かたが あって、みずいろ、ピンク、むらさきの いろから えらべるよ。",
      "ゆびで つつくと ぷるんって ゆれるでしょ？ ボウルで やさしく まぜるのが コツだよ。",
    ],
  });

  // ラテ
  put("handmade_latte_pot", -23, 54, { by: ON_BENCH });
  put("handmade_latte_mugs", 21, 54, { by: ON_BENCH });
  person("human_longhair_doing", -3, 50, {
    name: "みなみ",
    lines: [
      "いらっしゃいませ！ ここは「くらげファクトリー」。ラテキャンドルづくりの コーナーは ここだよ。",
      "ミルクいろと コーヒーいろの ろうを、マグカップに そそいで つくる キャンドルなの。",
      "ピックっていう ほそい ぼうで、ろうの うえに もようを かくんだよ。ハートや はっぱも かけるよ。",
      "ほんもののラテアートみたいでしょ？ できあがりの みほんも ならんでるから みてね。",
      "キャンドルすくい、ぷるぷる せっけん、オイルと スライムの キーホルダーも あるよ。ほかの たいけんも のぞいていってね！",
    ],
  });

  // スライム
  put("handmade_slime_bowl", 59, 54, { by: ON_BENCH });
  put("handmade_slime_shelf", 79, 54, { by: ON_BENCH });
  person("human_spikeyhair_doing", 43, 50, {
    name: "ゆうた",
    lines: [
      "ここは スライムキーホルダーの コーナーだよ！ ボウルの スライムを ぼうで ぐるぐる まぜるんだ。",
      "いろの もとの ボトルを ぽとんと たらすと、パステルカラーに そまっていくよ。",
      "ラメを まぜると きらきら するんだ。できた スライムは ちいさな びんに いれて キーホルダーに するよ。",
      "ぷるぷるで やわらかいから、さわるだけでも たのしいよ。",
    ],
  });

  // ---- 手前の列: キャンドルすくいのプール（左）とオイルキーホルダーの作業台（右）
  put("handmade_pool", -60, 128, { hit: [58, 30] });
  put("handmade_bench_oil", 52, 128, { hit: [54, 26] });
  put("handmade_oil_display", 38, 100, { by: ON_FRONT });
  put("handmade_oil_mats", 66, 100, { by: ON_FRONT });
  person("human_bowlhair_doing", 88, 122, {
    name: "ひなた",
    lines: [
      "ここは オイルキーホルダーの コーナーだよ。とうめいな アクリルの なかに、えきたいを いれて つくるの。",
      "なかには ラメや ほしや ビーズを いれられるよ。ふると ゆっくり きらきら うごくんだ。",
      "ざいりょうは、ラメ、ビーズ、オイルの ボトルが そろってるよ。すきな いろを えらんでね。",
      "くみたてだいで ふたを しめたら かんせい！ ならんでいる みほんも かわいいでしょ。",
    ],
  });

  // ---- 客（体験中）
  person("human_curlyhair_doing", -20, 114, {
    name: "おきゃくさん",
    lines: [
      "キャンドルすくい、むずかしい！ ポイで そっと ろうそくを すくうんだよ。",
      "みずの うえに ハートや ほしや クラゲの かたちの ろうそくが うかんでるの。すくえたら カップに いれるよ。",
      "ポイは ぬらすと やぶれやすいから、ゆっくり すくうのが コツなんだって。",
    ],
  }, true);
  person("human_shorthair_idle", 20, 102, {
    name: "おきゃくさん",
    lines: [
      "オイルキーホルダーが きれい！ ゆらすと なかの ラメが ゆっくり うごくんだ。",
      "ぜんぶの コーナーを まわって みようかな。ぷるぷる せっけんも ラテキャンドルも きになる！",
    ],
  });
  person("human_mophair_idle", 16, 121, {
    name: "こども",
    lines: [
      "スライム、ぷにぷにで たのしかった！ ちいさな びんに いれて キーホルダーに するんだって。",
      "つぎは キャンドルすくいに ちょうせんするんだ！",
    ],
  });
  put("expression_love", 20, 86, { by: 140 });

  // ---- 飾りのクラゲ（光る。主役は体験コーナー）と泡
  put("handmade_drift_c", -6, 127, { by: 300, frame: 5 });
  put("handmade_bubbles", -88, 104, { by: 301, frame: 4 });
  put("handmade_bubbles", 20, 96, { by: 301, frame: 2 });
}
