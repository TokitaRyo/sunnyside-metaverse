/** アマチュア無線部（交信ブース）。専用ドット絵は scripts/stalls/amateurradio.ps1（amateurradio_*.png）。奥の壁に世界地図とQSLカード、両脇に高いアンテナ塔、真ん中に光る地球儀、左右の机に無線機とモールス電鍵、手前に八木アンテナの展示とハンディ機の展示台 */
export const meta = { id: "amateurradio", label: "アマチュア無線部" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("amateurradio_sign", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("amateurradio_map_screen", undefined, undefined, { frames: 6, fps: 5 });
  k.custom("amateurradio_globe_lamp", undefined, undefined, { frames: 8, fps: 3 });
  k.custom("amateurradio_glow", undefined, undefined, { frames: 6, fps: 4 });
  k.custom("amateurradio_tower_gp", undefined, undefined, { frames: 4, fps: 2 });
  k.custom("amateurradio_tower_dipole", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("amateurradio_beam", undefined, undefined, { frames: 6, fps: 5 });
  k.custom("amateurradio_rig_screen", undefined, undefined, { frames: 6, fps: 4 });
  k.custom("amateurradio_strip", undefined, undefined, { frames: 4, fps: 5 });
  k.custom("amateurradio_key", undefined, undefined, { frames: 2, fps: 4 });
  k.custom("amateurradio_handy_screen", undefined, undefined, { frames: 4, fps: 2 });
  k.custom("amateurradio_yagi_beam", undefined, undefined, { frames: 4, fps: 4 });
  // 静止
  for (const n of ["floor", "wall", "qsl", "desk", "mic", "headset", "plate"]) k.custom(`amateurradio_${n}`);

  const { put, person } = k;
  const ON = 90; // 机の上に置く物は、机(足元88)より手前に描く

  // ---- 床・波紋・奥の壁・看板
  put("amateurradio_floor", 0, 128, { sort: "floor" });
  put("amateurradio_glow", 0, 106, { sort: "floor" });
  put("amateurradio_wall", 0, 50, { by: 48, hit: [184, 6] });
  put("amateurradio_sign", 0, 18, { by: 60 });

  // ---- 壁の飾り: 世界地図ボード・QSLカード
  put("amateurradio_map_screen", -48, 49, { by: 51 });
  put("amateurradio_qsl", 31, 49, { by: 51 });

  // ---- 両脇のアンテナ塔（先から電波が広がる）
  put("amateurradio_tower_gp", -85, 58, { by: 58, hit: [14, 6] });
  put("amateurradio_beam", -85, 24, { by: 59 });
  put("amateurradio_tower_dipole", 85, 58, { by: 58, hit: [14, 6] });
  put("amateurradio_beam", 85, 22, { by: 59, frame: 3 });

  // ---- 真ん中: 地球儀
  put("amateurradio_globe_lamp", 0, 84, { by: 85, hit: [14, 6] });

  // ---- 左の机: 無線機・マイク・ヘッドセット（交信中の部員）
  put("amateurradio_desk", -62, 88, { hit: [68, 14] });
  put("amateurradio_rig_screen", -77, 78, { by: ON });
  person("human_shorthair_doing", -49, 75, {
    name: "ぶいん",
    lines: [
      "ようこそ！ ここは アマチュアむせんぶだよ。",
      "でんぱを つかって、とおくの ひとと おはなしする あそびなんだ。うみの むこうの ひとと つながることも あるんだよ。",
      "ほんとうに でんぱを だすには、めんきょが ひつようなんだ。ぶいんは べんきょうして とったんだよ。",
    ],
  });
  put("amateurradio_mic", -49, 79, { by: ON + 1 });
  put("amateurradio_headset", -35, 79, { by: ON + 1 });
  put("amateurradio_strip", -62, 87, { by: ON + 1 });

  // ---- 右の机: モールス電鍵・無線機
  put("amateurradio_desk", 62, 88, { hit: [68, 14] });
  put("amateurradio_rig_screen", 77, 78, { by: ON, frame: 3 });
  person("human_bowlhair_doing", 46, 75, {
    name: "ぶいん",
    lines: [
      "これは モールスしんごうを おくる でんけんだよ。みじかい「トン」と ながい「ツー」で もじを あらわすんだ。",
      "むかしの ふねや ひこうきも、これで れんらくを とっていたんだって。",
      "ことばが つうじなくても、モールスで なかよくなれることが あるよ。",
    ],
  });
  put("amateurradio_key", 46, 79, { by: ON + 1 });
  put("amateurradio_strip", 62, 87, { by: ON + 1, frame: 2 });

  // ---- 手前左: 八木アンテナの展示と、アンテナを調整する部員
  put("amateurradio_yagi_beam", -56, 127, { by: 128, hit: [20, 6], hxOff: -18 });
  person("human_longhair_doing", -30, 106, {
    name: "ぶいん",
    lines: [
      "これは やぎアンテナっていう アンテナだよ。ほねみたいな かたちを しているでしょ？",
      "むきを かえて、あいての いる ほうこうに むけると、でんぱが よく とどくんだ。いま ちょうせいしているところ！",
      "うえの たかい アンテナは、いろんな ほうこうの ひとと おはなしするための ものだよ。",
    ],
  }, true);

  // ---- 手前右: ハンディ機の展示台と案内の部員
  put("amateurradio_handy_screen", 70, 124, { by: 125, hit: [48, 8] });
  person("human_spikeyhair_idle", 32, 106, {
    name: "ぶいん",
    lines: [
      "ここは ハンディきの てんじだよ。てに もてる ちいさな むせんきなんだ。",
      "ちかくの ともだちと おはなししたり、さんぽの とちゅうで つかったりするよ。",
      "きょうみが あったら、ぶいんに きいてみてね！",
    ],
  });
  put("expression_chat", 32, 86, { by: 130 });

  // ---- 入口の両脇: コールサイン風の札（架空の伏せ字）
  put("amateurradio_plate", -29, 128, { by: 128, hit: [8, 3] });
  put("amateurradio_plate", 29, 128, { by: 128, hit: [8, 3] });

  // ---- 見学のお客さん
  person("human_mophair_idle", -10, 102, {
    name: "こども",
    lines: [
      "ちきゅうぎに ピンが ささってる！ ここの ひとと おはなししたのかな？",
      "ぼくも むせんで せかいの ひとと おともだちに なりたいな。",
    ],
  });
  person("human_curlyhair_idle", 10, 104, {
    name: "おきゃくさん",
    lines: [
      "かべの カードは、おはなしした あいてと こうかんする QSLカードっていうんだって。",
      "えはがきみたいで かわいいね。ばんごうの ところは ひみつの ふせじなんだ。",
    ],
  }, true);
}
