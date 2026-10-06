/** コンサート会場（ライブステージ）。専用ドット絵は scripts/stalls/concert.ps1（concert_*.png）。島の奥に舞台、手前に客席・PA卓・ゲート・受付 */
export const meta = { id: "concert", label: "コンサート会場", island: "浮島 30" };

export default function layout(k) {
  // アニメ（横一列のシート）: 看板・トラスのライト・光線・幕のイコライザー・舞台のふち・スピーカー・PAライト・ペンライトなど
  k.custom("concert_sign", undefined, undefined, { frames: 6, fps: 4 });
  k.custom("concert_truss", undefined, undefined, { frames: 6, fps: 3 });
  k.custom("concert_beams", undefined, undefined, { frames: 6, fps: 3 });
  k.custom("concert_backdrop", undefined, undefined, { frames: 4, fps: 5 });
  k.custom("concert_deck", undefined, undefined, { frames: 6, fps: 6 });
  k.custom("concert_speaker", undefined, undefined, { frames: 4, fps: 6 });
  k.custom("concert_par", undefined, undefined, { frames: 6, fps: 3 });
  for (const c of ["r", "g", "b", "m", "c"]) k.custom(`concert_pen_${c}`, undefined, undefined, { frames: 4, fps: 5 });
  k.custom("concert_uchiwa", undefined, undefined, { frames: 2, fps: 3 });
  k.custom("concert_foh", undefined, undefined, { frames: 4, fps: 5 });
  k.custom("concert_gate", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("concert_notes", undefined, undefined, { frames: 4, fps: 3 });
  // 静止
  for (const n of ["concert_drums_back", "concert_drums_front", "concert_keys", "concert_mic", "concert_guitar", "concert_bass", "concert_amp", "concert_bassamp", "concert_monitor", "concert_barrier", "concert_floor", "concert_booth"]) k.custom(n);
  k.custom("concert_nobori", 1, 46);

  const { put, person } = k;

  // ---- 床: 客席の床（赤い通路つき）→ 舞台の床（ステップ付き）
  put("concert_floor", 0, 128, { sort: "floor" });
  // 舞台の前面は通れない。真ん中の階段(幅28)だけあける。同じ絵を2個重ねて、左右それぞれに当たり判定を付ける
  put("concert_deck", 0, 86, { sort: "floor", by: 84, hit: [52, 6], hxOff: -40 });
  put("concert_deck", 0, 86, { sort: "floor", by: 84, hit: [52, 6], hxOff: 40 });

  // ---- 背景: 幕（LEDスクリーン）・トラス・看板
  put("concert_backdrop", 0, 58, { hit: [124, 3] });
  put("concert_truss", 0, 62, { hit: [6, 4], hxOff: -64 });
  put("concert_truss", 0, 62, { hit: [6, 4], hxOff: 64 }); // 同じ絵をもう1個重ねて、右の柱の当たり判定にする
  put("concert_sign", 0, 22, { by: 63 });

  // ---- スピーカーの山（左右）
  put("concert_speaker", -82, 72, { hit: [24, 8], frame: 0 });
  put("concert_speaker", 82, 72, { hit: [24, 8], frame: 2 });

  // ---- 舞台の上: アンプ・ドラム・キーボード・バンド
  put("concert_amp", -20, 62);
  put("concert_bassamp", 48, 62);
  put("concert_drums_back", 16, 62, { by: 61 });
  person("human_mophair_doing", 16, 62, {
    name: "ドラム",
    lines: [
      "ドラムは バンドの しんぞうだよ！ ドン、タン、ドン、タン！",
      "リズムを きざんで、みんなを もりあげるんだ。",
      "ステージの うしろから、みんなの ペンライトが よく みえるよ！",
    ],
  });
  put("concert_drums_front", 16, 70, { by: 70, hit: [30, 5] });

  person("human_shorthair_doing", -48, 64, {
    name: "キーボード",
    lines: [
      "キーボードたんとうです。きらきらした おとで、うたを いろどるよ。",
      "あかや あおの ライトが きれいでしょ？ ステージの うえから みると もっと すごいよ！",
    ],
  });
  put("concert_keys", -48, 68, { by: 68, hit: [26, 4] });

  person("human_spikeyhair_idle", -30, 75, {
    name: "ギター",
    lines: [
      "ギターたんとうだよ。アンプから でる おおきな おとが だいすきなんだ。",
      "ネオンの ひかりの なかで ひくの、さいこうに きもちいい！",
    ],
  });
  put("concert_guitar", -39, 75, { by: 76, flip: true });

  person("human_longhair_idle", -6, 74, {
    name: "ボーカル",
    lines: [
      "みんな、きてくれて ありがとう！",
      "ここは コンサートかいじょう。ステージでは バンドが えんそうしているよ。",
      "ひかりと おとが まざる ライブの ふんいきを たのしんでいってね！",
      "ペンライトを ふって、いっしょに もりあがろう！",
    ],
  });
  put("concert_mic", -6, 75, { by: 76 });
  put("expression_chat", -6, 57, { by: 90 });

  person("human_bowlhair_idle", 40, 75, {
    name: "ベース",
    lines: [
      "ベースは、ひくい おとで バンドを ささえる やくめ。",
      "ドラムと いきを あわせるのが いちばん だいじなんだ。",
    ],
  });
  put("concert_bass", 53, 75, { by: 76 });

  // ---- 舞台のふち: モニター・足元のライト
  put("concert_monitor", -16, 76, { by: 77 });
  put("concert_monitor", 16, 76, { by: 77 });
  put("concert_par", -60, 76, { by: 77 });
  put("concert_par", 60, 76, { by: 77, frame: 3 });

  // ---- 光線と浮かぶ音符（舞台の人より手前、客席より奥）
  put("concert_beams", 0, 84, { by: 59 }); // バンドや機材の後ろ、幕の手前
  put("concert_notes", -34, 54, { by: 90 });
  put("concert_notes", 32, 54, { by: 90, frame: 2 });

  // ---- 客席のフェンス（真ん中は階段へ続く通路をあける）
  put("concert_barrier", -40, 92, { hit: [52, 4] });
  put("concert_barrier", 40, 92, { hit: [52, 4] });

  // ---- 客席の観客
  person("human_curlyhair_idle", -54, 100, { name: "おきゃくさん", lines: ["ライブ、まってました！ ペンライトの ひかり、きれいでしょ？", "まえの ほうで みると、おとが おなかに ひびくんだよ。"] });
  put("concert_pen_m", -46, 95, { by: 101, frame: 0 });
  person("human_longhair_idle", -30, 106, { name: "おきゃくさん", lines: ["うちわを つくってきたんだ！", "ステージの みんなに みえるかな？ ハートが めじるし！"] }, true);
  put("concert_uchiwa", -42, 100, { by: 107 });
  person("human_bowlhair_idle", 22, 98, { name: "おきゃくさん", lines: ["あおも あかも みどりも、ライトが ぜんぶ きれい！", "みんなで ペンライトを ふると、うみみたいに みえるよ。"] });
  put("concert_pen_g", 30, 93, { by: 99, frame: 1 });
  person("human_spikeyhair_idle", 44, 104, { name: "おきゃくさん", lines: ["いちばん まえの れつは、フェンスの まえだよ。", "うしろからでも、おおきな スクリーンが みえるから だいじょうぶ！"] }, true);
  put("concert_pen_b", 36, 99, { by: 105, frame: 2 });
  person("human_mophair_idle", 68, 98, { name: "こども", lines: ["ぼくも ペンライト もってきたよ！", "おとが おおきいから、みみを ちょっと おさえるんだ。"] }, true);
  put("concert_pen_r", 60, 93, { by: 99, frame: 3 });

  // ---- PA卓（客席のうしろ）
  put("concert_foh", -60, 128, { hit: [44, 8] });
  person("human_shorthair_idle", -60, 109, {
    name: "PAさん",
    lines: [
      "ここは PAせき。ステージの おとを ととのえているよ。",
      "ミキサーの フェーダーを うごかして、おとの おおきさを そうさするんだ。",
      "ステージ ぜんたいが みわたせるから、ここは とくとうせき！",
    ],
  });

  // ---- 入場ゲートと受付
  put("concert_gate", -24, 126, { hit: [8, 4] });
  put("concert_gate", 24, 126, { hit: [8, 4], frame: 2 });
  put("concert_booth", 54, 128, { hit: [44, 8] });
  person("human_longhair_idle", 54, 114, {
    name: "うけつけ",
    lines: [
      "ライブかいじょうへ ようこそ！ ここは うけつけだよ。",
      "あかい じゅうたんの つうろを まっすぐ すすむと、ステージに つくよ。",
      "ステージの まえで、ゆっくり たのしんでいってね。",
    ],
  });
  put("expression_chat", 54, 97, { by: 120 });

  // ---- のぼり旗（左右）
  put("concert_nobori", -92, 118, { hit: [4, 4] });
  put("concert_nobori", 76, 118, { hit: [4, 4] });
}
