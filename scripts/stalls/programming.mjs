/** プログラミング部。専用ドット絵は scripts/stalls/programming.ps1（programming_*.png）。濃紺のUIにRGBのネオン。奥にビッグスクリーン・ホワイトボード・ポスター、作業机、手前に体験コーナー */
export const meta = { id: "programming", label: "プログラミング部", island: "浮島 8" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("programming_sign", undefined, undefined, { frames: 6, fps: 4 });
  k.custom("programming_bigscreen", undefined, undefined, { frames: 8, fps: 6 });
  k.custom("programming_mon_code", undefined, undefined, { frames: 8, fps: 5 });
  k.custom("programming_mon_hello", undefined, undefined, { frames: 8, fps: 3 });
  k.custom("programming_mon_game", undefined, undefined, { frames: 8, fps: 6 });
  k.custom("programming_mon_shoot", undefined, undefined, { frames: 6, fps: 4 });
  k.custom("programming_laptop", undefined, undefined, { frames: 8, fps: 5 });
  k.custom("programming_tower", undefined, undefined, { frames: 6, fps: 6 });
  k.custom("programming_kbd", undefined, undefined, { frames: 6, fps: 6 });
  k.custom("programming_rack", undefined, undefined, { frames: 6, fps: 8 });
  k.custom("programming_aframe", undefined, undefined, { frames: 2, fps: 2 });
  k.custom("programming_strip", undefined, undefined, { frames: 4, fps: 3 });
  // 静止
  for (const n of ["programming_floor", "programming_wall", "programming_desk", "programming_whiteboard", "programming_poster_game", "programming_poster_code", "programming_mouse", "programming_can_g", "programming_can_r", "programming_can_b", "programming_mug", "programming_cactus", "programming_cable"]) k.custom(n);

  const { put, person } = k;
  const ON = 90; // 机の上に置く物は、机(足元88)より手前に描く

  // ---- 床・奥の壁・看板
  put("programming_floor", 0, 128, { sort: "floor" });
  put("programming_cable", -52, 90, { sort: "floor" });
  put("programming_cable", 58, 96, { sort: "floor" });
  put("programming_wall", 0, 50, { by: 48, hit: [184, 6] });
  put("programming_sign", 0, 24, { by: 60 });

  // ---- 壁の飾り: ビッグスクリーン・ホワイトボード・ポスター
  put("programming_bigscreen", 0, 50, { by: 51 });
  put("programming_whiteboard", -70, 49, { by: 51 });
  put("programming_poster_game", 62, 49, { by: 51 });
  put("programming_poster_code", 85, 49, { by: 51 });

  // ---- 作業机（左）: コード画面・Hello World・ゲーミングPC
  put("programming_desk", -57, 88, { hit: [76, 14] });
  put("programming_mon_code", -82, 76, { by: ON });
  put("programming_kbd", -82, 80, { by: ON + 1 });
  put("programming_mouse", -68, 80, { by: ON + 1 });
  person("human_shorthair_doing", -62, 75, {
    name: "ぶいん",
    lines: [
      "ようこそ！ ここは プログラミングぶの てんじだよ。",
      "プログラムは、コンピューターへの めいれいを じゅんばんに ならべたものなんだ。",
      "うしろの おおきな がめんの ゲームも、めいれいが たくさん あつまって うごいているよ。",
    ],
  });
  put("programming_mug", -53, 80, { by: ON + 1 });
  put("programming_mon_hello", -44, 76, { by: ON, frame: 2 });
  put("programming_kbd", -44, 80, { by: ON + 1, frame: 3 });
  put("programming_tower", -23, 79, { by: ON + 2, frame: 1 });
  put("programming_can_g", -31, 80, { by: ON + 1 });

  // ---- 作業机（右）: インベーダー・ゲーミングPC・ゲーム画面
  put("programming_desk", 57, 88, { hit: [76, 14] });
  put("programming_tower", 25, 79, { by: ON + 2, frame: 4 });
  put("programming_mon_shoot", 46, 76, { by: ON, frame: 1 });
  put("programming_kbd", 46, 80, { by: ON + 1, frame: 2 });
  person("human_bowlhair_doing", 66, 75, {
    name: "ぶいん",
    lines: [
      "モニターを みてみて。コードが ながれているでしょ？ みどりや みずいろの もじが めいれいだよ。",
      "「Hello, World!」は、プログラミングを はじめるとき、さいしょに かく ていばんの ひょうじなんだ。",
      "ゲームを つくるときも、ちいさな ところから すこしずつ ならべていくんだよ。",
    ],
  });
  put("programming_mon_game", 82, 76, { by: ON, frame: 5 });
  put("programming_kbd", 82, 80, { by: ON + 1, frame: 0 });
  put("programming_can_r", 62, 80, { by: ON + 1 });
  put("programming_can_b", 70, 80, { by: ON + 1 });
  put("programming_strip", 20, 92, { sort: "floor" });

  // ---- 体験コーナー（手前）
  put("programming_desk", -57, 126, { hit: [76, 14] });
  put("programming_mon_game", -82, 114, { by: 128, frame: 2 });
  put("programming_kbd", -82, 118, { by: 129, frame: 1 });
  person("human_curlyhair_idle", -62, 112, {
    name: "おきゃくさん",
    lines: [
      "ゲームの キャラが うごくの、おもしろい！ どうやって つくるのかな？",
      "めいれいを ならべると、キャラが はしったり ジャンプしたり するんだって。",
    ],
  });
  put("programming_laptop", -42, 116, { by: 128, frame: 3 });
  put("programming_mouse", -32, 119, { by: 129 });
  put("programming_cactus", -21, 118, { by: 129 });
  person("human_mophair_idle", -28, 112, {
    name: "こども",
    lines: [
      "ぼくも プログラミング やってみたい！",
      "「Hello, World!」って がめんに でるの、すごいね。",
    ],
  }, true);

  put("programming_aframe", 50, 126, { hit: [40, 5] });
  put("programming_rack", 87, 126, { hit: [16, 6] });
  put("programming_strip", 28, 124, { sort: "floor" });

  // 通路の人
  person("human_spikeyhair_idle", 12, 104, {
    name: "ぶいん",
    lines: [
      "たいけんコーナーへ ようこそ。パソコンの ゲームを じゆうに あそんでみてね。",
      "あそんでいる ゲームも、だれかが プログラムで つくったものなんだ。",
      "つくってみたく なったら、ぶいんに きいてみてね！",
    ],
  });
  put("expression_chat", 12, 82, { by: 130 });
  person("human_longhair_idle", -4, 94, {
    name: "おきゃくさん",
    lines: [
      "ホワイトボードの ずは フローチャートって いうんだって。",
      "ぎもんで わかれる みちが あって、プログラムの ながれを あらわすんだよ。",
    ],
  });
}
