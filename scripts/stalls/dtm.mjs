/** DTM部。専用ドット絵は scripts/stalls/dtm.ps1（dtm_*.png）。吸音フォームの壁と紫のカーペット、ネオンの看板。左に作曲デスク、右にミキサーとレコーディングブース、手前に体験コーナー */
export const meta = { id: "dtm", label: "DTM部" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("dtm_sign", undefined, undefined, { frames: 6, fps: 5 });
  k.custom("dtm_neon_eq", undefined, undefined, { frames: 8, fps: 7 });
  k.custom("dtm_neon_note", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("dtm_mon_daw", undefined, undefined, { frames: 8, fps: 3 });
  k.custom("dtm_mon_roll", undefined, undefined, { frames: 8, fps: 6 });
  k.custom("dtm_laptop", undefined, undefined, { frames: 8, fps: 8 });
  k.custom("dtm_kbd_midi", undefined, undefined, { frames: 6, fps: 5 });
  k.custom("dtm_mixer_strip", undefined, undefined, { frames: 6, fps: 7 });
  k.custom("dtm_speaker", undefined, undefined, { frames: 4, fps: 6 });
  k.custom("dtm_pads_glow", undefined, undefined, { frames: 8, fps: 6 });
  k.custom("dtm_aframe", undefined, undefined, { frames: 2, fps: 2 });
  k.custom("dtm_notes_drift", undefined, undefined, { frames: 8, fps: 4 });
  k.custom("dtm_strip_floor", undefined, undefined, { frames: 4, fps: 5 });
  // 静止
  for (const n of ["floor", "wall", "poster_wave", "poster_disc", "headphones", "headphones_worn", "mic", "booth", "desk_l", "desk_r", "rug", "table", "xstand", "chair", "beanbag", "cable", "mug", "plant"]) k.custom(`dtm_${n}`);

  const { put, person } = k;
  const ON = 90; // 机の上に置く物は、机(足元88)より手前に描く

  // ---- 床・奥の壁・看板
  put("dtm_floor", 0, 128, { sort: "floor" });
  put("dtm_rug", 0, 122, { sort: "floor" });
  put("dtm_cable", -30, 95, { sort: "floor" });
  put("dtm_cable", 40, 95, { sort: "floor", flip: true });
  put("dtm_strip_floor", -52, 92, { sort: "floor" });
  put("dtm_strip_floor", 38, 92, { sort: "floor" });
  put("dtm_wall", 0, 50, { by: 48, hit: [184, 6] });
  put("dtm_sign", 0, 22, { by: 60 });

  // ---- 壁の飾り: ポスター・イコライザーのネオン・音符のネオン
  put("dtm_poster_wave", -85, 42, { by: 51 });
  put("dtm_poster_disc", -62, 42, { by: 51 });
  put("dtm_neon_eq", 62, 47, { by: 51 });
  put("dtm_neon_note", 86, 46, { by: 51 });

  // ---- 作曲デスク（左）: スピーカー・DAW・ピアノロール・MIDIキーボード
  put("dtm_desk_l", -52, 88, { hit: [84, 14] });
  put("dtm_speaker", -88, 77, { by: ON });
  put("dtm_mon_daw", -64, 76, { by: ON });
  put("dtm_mon_roll", -34, 76, { by: ON, frame: 3 });
  put("dtm_speaker", -16, 77, { by: ON, frame: 2 });
  put("dtm_kbd_midi", -52, 82, { by: ON + 1, frame: 2 });
  put("dtm_mug", -24, 81, { by: ON + 1 });
  put("dtm_chair", -52, 108, { by: 103 });
  person("human_shorthair_doing", -52, 104, {
    name: "さっきょく",
    lines: [
      "ようこそ！ ここは ディーティーエムぶ。パソコンで きょくを つくる ぶかつだよ。",
      "がめんに おとを ならべて、メロディを つくっているところなんだ。",
      "ドラムや ベースを かさねていくと、きょくが どんどん にぎやかに なるよ。",
    ],
  });

  // ---- ミキサーのデスク（右）
  put("dtm_desk_r", 38, 88, { hit: [56, 14] });
  put("dtm_mixer_strip", 42, 80, { by: ON + 1, frame: 1 });
  put("dtm_headphones", 14, 79, { by: ON + 1 });
  person("human_bowlhair_doing", 28, 102, {
    name: "ミキサー",
    lines: [
      "この きかいは ミキサー。ひとつひとつの おとの おおきさを ちょうせつするよ。",
      "フェーダーを うえに あげると おおきく、さげると ちいさく なるんだ。",
      "ランプが ぴかぴか ひかるのは、いまの おとの おおきさを しめしているんだよ。",
    ],
  });

  // ---- レコーディングブース（右奥）: 防音シールド・マイクと歌い手
  put("dtm_booth", 80, 84, { by: 83 });
  person("human_longhair_idle", 80, 88, {
    name: "うたいて",
    lines: [
      "マイクの まえに ある まるい あみは、ポップガードって いうんだ。",
      "いきの かぜを ふせいで、きれいな こえを とるための ものだよ。",
      "かべの ふわふわは、おとが はねかえるのを おさえてくれるんだって。",
    ],
  });
  put("dtm_mic", 80, 100, { by: 100 });

  // ---- 通路の部員（机のあいだ）
  person("human_spikeyhair_idle", 0, 78, {
    name: "ぶいん",
    lines: [
      "ようこそ！ ディーティーエムぶへ。ディーティーエムは、パソコンで おんがくを つくる あそびだよ。",
      "ドラム、ベース、メロディを じゅんばんに かさねて、ひとつの きょくに するんだ。",
      "ひだりの キーボードや、みぎの パッドを じゆうに ならしてみてね。",
    ],
  });
  put("expression_chat", 0, 60, { by: 130 });

  // ---- 体験コーナー（手前）
  // 左: キーボードを弾いてみるお客さん
  put("dtm_xstand", -72, 128, { by: 129, hit: [40, 5] });
  put("dtm_kbd_midi", -72, 115, { by: 130, frame: 4 });
  person("human_curlyhair_idle", -72, 106, {
    name: "おきゃくさん",
    lines: [
      "キーを おすと おとが でた！ たのしいね。",
      "このキーボードは、パソコンに つないで つかうんだって。",
    ],
  });
  // 中央左: ヘッドホンで聴く部員
  put("dtm_beanbag", -28, 118, { by: 112 });
  person("human_mophair_idle", -28, 113, {
    name: "ききて",
    lines: [
      "ヘッドホンで、じぶんの つくった きょくを きいているところ。",
      "ほかの おとが きこえないから、こまかい おとまで よく わかるんだ。",
    ],
  });
  put("dtm_headphones_worn", -28, 104, { by: 200 });
  // 右: パッドを叩いてみるお客さん
  put("dtm_table", 46, 127, { by: 127, hit: [48, 8] });
  put("dtm_pads_glow", 36, 115, { by: 128 });
  put("dtm_laptop", 58, 115, { by: 128, frame: 3 });
  person("human_mophair_doing", 46, 108, {
    name: "おきゃくさん",
    lines: [
      "パッドを たたくと、ドン！ パン！ って おとが でるよ。",
      "じゅんばんに ならべると、リズムに なるんだって。",
    ],
  });
  person("human_shorthair_idle", 62, 98, {
    name: "こども",
    lines: [
      "ぼくも きょく つくってみたいな！",
      "かべの とげとげは、おとを すいとる ざいりょうなんだって。",
    ],
  }, true);
  put("dtm_aframe", 84, 128, { hit: [24, 5] });

  // ---- 小物・漂う音符
  put("dtm_plant", -47, 127, { by: 127, hit: [8, 4] });
  put("dtm_notes_drift", 4, 70, { by: 131 });
  put("dtm_notes_drift", 40, 66, { by: 131, frame: 4 });
}
