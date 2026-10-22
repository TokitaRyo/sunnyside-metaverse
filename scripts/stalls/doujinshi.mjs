/** 同人誌。専用ドット絵は scripts/stalls/doujinshi.ps1（doujinshi_*.png）。奥はパーテーションの壁（表紙のポスターと吊るした見本）、真ん中に布をかけた長机（平積み・新刊POP・本のスタンド・めくれる見本誌・スペース札・ペン）と売り子、左前に見本誌ラック、右に段ボール箱とパイプ椅子と袋詰め、前に立て看板 */
export const meta = { id: "doujinshi", label: "同人誌" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("doujinshi_sign", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("doujinshi_sample", undefined, undefined, { frames: 6, fps: 3 });
  k.custom("doujinshi_sparkle", undefined, undefined, { frames: 4, fps: 4 });
  // 静止
  for (const n of ["floor", "wall", "table", "flat", "pop", "stand", "plate", "pens", "rack", "chair", "boxes", "bag", "nobori_a", "nobori_b", "easel"]) k.custom(`doujinshi_${n}`);

  const { put, person } = k;
  const ON_TABLE = 89; // 長机(足元88)の上に置く物は手前に描く
  const TOP = 65; // 机の上面に置く物の足元

  // ---- 床・奥の壁・看板・のぼり
  put("doujinshi_floor", 0, 128, { sort: "floor" });
  put("doujinshi_wall", 0, 56, { by: 50, hit: [176, 4] });
  put("doujinshi_sign", 0, 12, { by: 55 });
  put("doujinshi_nobori_a", -88, 62, { by: 62 });
  put("doujinshi_nobori_b", 88, 62, { by: 62 });

  // ---- 長机（会議用の机に布）
  put("doujinshi_table", -8, 88, { hit: [144, 10] });

  // ---- 机の上（左から）
  put("doujinshi_pens", -50, TOP, { by: ON_TABLE });
  put("doujinshi_plate", 44, 80, { by: ON_TABLE });
  put("doujinshi_pop", -30, TOP, { by: ON_TABLE });
  put("doujinshi_sparkle", -30, 62, { by: 400 });
  put("doujinshi_stand", 16, TOP, { by: ON_TABLE });
  put("doujinshi_flat", 46, TOP, { by: ON_TABLE });
  put("doujinshi_sample", 62, TOP, { by: ON_TABLE });

  // ---- 机の奥: 部員（本を作った人・売り子）
  person("human_longhair_doing", -68, 57, {
    name: "さくしゃ",
    lines: [
      "いらっしゃい！ ここに ならべているのは、ぶいんが じぶんで かいて つくった ほんだよ。",
      "おはなしも えも ぜんぶ じぶんたちで かいたんだ。コピーして、おって、ホチキスで とじる。ぜんぶ てしごとだよ。",
      "できあがった ときは うれしかったなあ。てに とって もらえると もっと うれしいな！",
    ],
  });
  person("human_shorthair_idle", -8, 57, {
    name: "うりこ",
    lines: [
      "いらっしゃい！ ここは どうじんしの コーナーだよ。てづくりの ほんを うっているよ。",
      "ひょうしの えは、ぶいんが ひとりずつ かいたの。ひとつずつ ちがうから、すきな えを さがしてみてね。",
      "「しんかん」の ポップが めじるし！ ひらいてある みほんは、じゆうに よんでいいよ。",
      "ほんを えらんだら、おしえてね。ふくろに いれて わたすよ。ありがとう！",
    ],
  });

  // ---- 左前: 見本誌ラックと立ち読みのお客さん
  put("doujinshi_rack", -78, 120, { hit: [34, 6] });
  person("human_mophair_idle", -54, 114, {
    name: "たちよみ",
    lines: [
      "ふむふむ…… この えの タッチ、すてきだな。",
      "ひょうしが どれも ちがって、えらべないよ。みほんを よめるのは うれしいね。",
    ],
  }, true);

  // ---- 机の前のお客さん
  person("human_curlyhair_idle", -12, 108, {
    name: "おきゃくさん",
    lines: [
      "てづくりの ほんって、あたたかい かんじが するね。",
      "ぼくも いつか じぶんの ほんを つくってみたいな。",
    ],
  });
  put("expression_chat", -12, 88, { by: 130 });

  // ---- 右: パイプ椅子と袋詰めの本、段ボール箱と袋詰めの部員
  put("doujinshi_chair", 80, 76, { hit: [14, 4] });
  put("doujinshi_bag", 80, 66, { by: 77 });
  put("doujinshi_boxes", 77, 124, { hit: [32, 8] });
  person("human_bowlhair_doing", 64, 94, {
    name: "ふくろがかり",
    lines: [
      "ほんを かって もらったら、ふくろに いれて わたすのが わたしの しごとだよ。",
      "この ダンボールの なかは、ぞうしの ざいこ。ぶいんで つみかさねて はこんで きたんだ。",
      "たいせつに よんでね。また あそびに きてね！",
    ],
  }, true);

  // ---- 前: 立て看板と、買って喜ぶお客さん
  put("doujinshi_easel", 34, 128, { hit: [26, 5] });
  person("human_spikeyhair_idle", -34, 126, {
    name: "おきゃくさん",
    lines: [
      "かっちゃった！ ふくろに いれてもらったよ。",
      "うちに かえって、ゆっくり よむんだ。たのしみ！",
    ],
  });
  put("expression_love", -34, 106, { by: 130 });
}
