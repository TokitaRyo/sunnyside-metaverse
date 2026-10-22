/** アントレ同好会「ロケットホイールシューター」（モーターで回るホイールを飛ばして的をねらう射的風の縁日）。専用ドット絵は scripts/stalls/entre.ps1（entre_*.png） */
export const meta = { id: "entre", label: "アントレ同好会" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("entre_sign", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("entre_nobori_a", 3, undefined, { frames: 4, fps: 3 });
  k.custom("entre_nobori_b", 3, undefined, { frames: 4, fps: 3 });
  const LAUNCH = ["a", "b", "c"].map((c) => k.custom(`entre_launcher_${c}`, undefined, undefined, { frames: 4, fps: 8 }));
  const FLY = k.custom("entre_fly", undefined, undefined, { frames: 4, fps: 4 });
  const TOPPLE = k.custom("entre_topple", 6.5, undefined, { frames: 8, fps: 2 });
  const BAL = Object.fromEntries(["red", "cyan", "yellow", "lime", "pink"].map((c) => [c, k.custom(`entre_balloon_${c}`, undefined, undefined, { frames: 4, fps: 3 })]));
  const TWINKLE = k.custom("entre_twinkle", undefined, undefined, { frames: 4, fps: 5 });
  // 静止
  for (const n of ["net", "shelf", "pin_red", "pin_cyan", "pin_orange", "cups", "disc_a", "disc_b", "pin_lying", "cups_lying", "prize_rocket", "prize_capsule", "prize_wheel", "wheelbox", "wheel_a", "wheel_b", "tray", "gift", "counter", "lane", "board"]) k.custom(`entre_${n}`);

  const { put, person } = k;

  // ---- 床: 3本のレーン
  put("entre_lane", 0, 124, { sort: "floor" });

  // ---- 看板（走る電球・回るホイール）とのぼり
  put("entre_sign", 0, 27, { by: 28 });
  put("entre_nobori_a", -96, 102, { hit: [4, 4] });
  put("entre_nobori_b", 79, 102, { hit: [4, 4] });

  // ---- 安全ネット（両わき）
  put("entre_net", -70, 74, { by: 66 });
  put("entre_net", 70, 74, { by: 66 });

  // ---- 的の棚（2段）と、段の上の的・景品
  put("entre_shelf", 0, 68, { by: 69 });
  const MID = 45, LOW = 62; // 各段の板の上（足元）
  const TOP_BY = 70; // 棚(by 69)より手前
  const on = (name, dx, foot, o = {}) => put(name, dx, foot, { by: TOP_BY, ...o });
  // 上段: 風船・円盤・景品
  on(BAL.red, -50, MID, { frame: 0 });
  on(BAL.cyan, -36, MID, { frame: 1 });
  on("entre_disc_a", -22, MID);
  on("entre_prize_rocket", -10, MID);
  on(BAL.yellow, 2, MID, { frame: 2 });
  on("entre_prize_capsule", 14, MID);
  on(BAL.lime, 26, MID, { frame: 3 });
  on("entre_disc_b", 40, MID);
  on(BAL.pink, 54, MID, { frame: 1 });
  // 下段: ピン・カップ・倒れるピン
  on("entre_pin_red", -50, LOW);
  on("entre_pin_orange", -41, LOW);
  on("entre_cups", -24, LOW);
  on(TOPPLE, -2, LOW);
  on("entre_cups", 36, LOW);
  on("entre_pin_cyan", 52, LOW);
  on("entre_prize_wheel", 18, LOW);
  // きらっと光る
  put(TWINKLE, -54, 40, { by: 90, frame: 0 });
  put(TWINKLE, -8, 36, { by: 90, frame: 2 });
  put(TWINKLE, 34, 38, { by: 90, frame: 1 });
  put(TWINKLE, 56, 58, { by: 90, frame: 3 });

  // ---- 倒れた的（カウンターのうしろの床）
  put("entre_pin_lying", -20, 70, { by: 71 });
  put("entre_cups_lying", 21, 70, { by: 71 });

  // ---- カウンター（射撃レーンの手前）と、その上のはっしゃき・ホイール皿
  put("entre_counter", 0, 94, { hit: [120, 10] });
  const ON = 95; // カウンター(足元94)より手前
  put(LAUNCH[0], -40, 81, { by: ON, frame: 0 });
  put(LAUNCH[1], 0, 81, { by: ON, frame: 2 });
  put(LAUNCH[2], 40, 81, { by: ON, frame: 1 });
  put("entre_tray", -20, 80, { by: ON });
  put("entre_tray", 20, 80, { by: ON });
  // 飛んでいくホイール（レーンの先へ）
  put(FLY, 40, 68, { by: 96, frame: 1 });
  put(FLY, -40, 68, { by: 96, frame: 3 });

  // ---- 部員（カウンターの奥）
  person("human_shorthair_doing", 62, 70, {
    name: "アントレぶ",
    lines: [
      "いらっしゃい！ アントレどうこうかいの ロケットホイールシューターへ ようこそ！",
      "モーターで ホイールが ぐるぐる まわって、ロケットみたいに とんでいくよ。",
      "まとを ねらって、うってみよう！ ピンや カップ、ふうせんが ならんでいるよ。",
      "あたって たおれた まとは、わたしが たてなおすね。なんかいでも あそんでね！",
    ],
  }, true);
  person("human_longhair_idle", -62, 70, {
    name: "アントレぶ",
    lines: [
      "ホイールを はっしゃきに セットして、スイッチを いれると、モーターが ぶいーんって まわりだすよ。",
      "ひとには むけないで、まとだけを ねらってね。ネットが あるから、ぴゅーんと とんでも あんしん！",
      "うでを のばして、まっすぐ かまえると あたりやすいよ。",
    ],
  });
  put("expression_chat", 62, 47, { by: 90 });

  // ---- ねらうお客さん（レーン1と3）
  person("human_spikeyhair_idle", -40, 110, {
    name: "おきゃくさん",
    lines: [
      "よーし、ねらって……ぴゅーん！ ホイールが ぐるぐる とんでいくよ！",
      "まんなかの ピンを たおしたいな。",
    ],
  });
  person("human_curlyhair_doing", 40, 110, {
    name: "こども",
    lines: [
      "モーターの おとが ぶいーんって するの、かっこいい！",
      "ふうせんを ねらうんだ。あたるかな？",
    ],
  }, true);

  // ---- 景品をもらって喜ぶお客さん
  person("human_mophair_idle", -2, 124, {
    name: "おきゃくさん",
    lines: [
      "やったあ！ まとを たおして、けいひんを もらったよ！",
      "ロケットみたいに とんでいって、すごかった！ もういっかい あそびたいな。",
    ],
  });
  put("expression_love", -2, 102, { by: 130 });
  put("entre_gift", 10, 126, { by: 128 });

  // ---- 手前の右: 黒板
  put("entre_board", 72, 128, { hit: [44, 6] });

  // ---- 手前の左: ホイールがたまった箱と、ホイールをひろう部員
  put("entre_wheelbox", -80, 126, { hit: [26, 6] });
  put("entre_wheel_a", -44, 128, { by: 128 });
  put("entre_wheel_b", -68, 112, { by: 112 });
  person("human_bowlhair_doing", -56, 124, {
    name: "アントレぶ",
    lines: [
      "とんでいった ホイールが、こんなに たまったよ。はこに あつめて、またつかうんだ。",
      "いろとりどりで、きれいでしょう？ ひろうのも ちょっと たのしいんだ。",
    ],
  }, true);
}
