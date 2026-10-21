/** バレーボール部（風船バレー・スパイクチャレンジ）。専用ドット絵は scripts/stalls/volleyball.ps1（volleyball_*.png）。奥の左に的の台とネット、右に3段の景品棚とカウンター、手前の左にスパイクのマット、右に「たおした かずで…」のマット。部員はメイド衣装 */
export const meta = { id: "volleyball", label: "バレーボール部" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("volleyball_sign", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("volleyball_nobori_a", 1, undefined, { frames: 4, fps: 3 });
  k.custom("volleyball_nobori_b", 1, undefined, { frames: 4, fps: 3 });
  const TOPPLE = k.custom("volleyball_topple", undefined, undefined, { frames: 8, fps: 2 });
  const ROLL = k.custom("volleyball_can_roll", undefined, undefined, { frames: 4, fps: 5 });
  const TWINKLE = k.custom("volleyball_twinkle", undefined, undefined, { frames: 4, fps: 5 });
  const BUNTING = k.custom("volleyball_bunting", undefined, undefined, { frames: 4, fps: 3 });
  const BAL = ["a", "b", "c", "d"].map((c) => k.custom(`volleyball_balloon_${c}`, undefined, undefined, { frames: 6, fps: 4 }));
  const BALL = k.custom("volleyball_ball", undefined, undefined, { frames: 6, fps: 5 });
  const BURST = k.custom("volleyball_burst", undefined, undefined, { frames: 4, fps: 5 });
  const FLIGHT = k.custom("volleyball_flight", undefined, undefined, { frames: 6, fps: 6 });
  // 静止
  for (const n of ["net", "table", "pin", "cans", "daruma", "cat", "pin_lying", "daruma_lying", "shelf", "prize_l", "prize_m", "prize_s", "counter", "bell", "tee", "court", "mat", "rug", "basket", "gift"]) k.custom(`volleyball_${n}`);
  // メイド衣装（人物 96x64 と同じ原点で重ねる）
  for (const n of ["short", "long", "mop", "bowl"]) k.custom(`volleyball_maid_${n}`, 48, 32);

  const { put, person, blocker } = k;

  // メイド衣装の部員（人物の上に衣装を重ねる）
  const maid = (sprite, style, dx, foot, npc, flip = false) => {
    const o = person(sprite, dx, foot, npc, flip);
    put(`volleyball_maid_${style}`, dx, foot, { by: foot + 0.2, flip });
    return o;
  };

  // ---- 床: コート・スパイクのマット・「たおした かずで」のマット
  put("volleyball_court", -40, 124, { sort: "floor" });
  put("volleyball_rug", 40, 128, { sort: "floor" });
  put("volleyball_mat", -40, 118, { sort: "floor", by: 119 });

  // ---- 看板・のぼり
  put("volleyball_sign", 0, 18, { by: 100 });
  put("volleyball_nobori_a", -85, 100, { hit: [4, 4] });
  put("volleyball_nobori_b", 90, 100, { hit: [4, 4] });

  put(BUNTING, -40, 36, { by: 30 });

  // ---- 奥の左: 的の台と的、ネット
  put("volleyball_table", -40, 66, { hit: [70, 8] });
  const ON = 67; // 台の上に置く物は、台より手前に描く
  const TF = 49; // 台の上の面に立つ足元
  put(TOPPLE, -66, TF, { by: ON });
  put("volleyball_pin", -50, TF, { by: ON });
  put("volleyball_cans", -36, TF + 1, { by: ON });
  put("volleyball_daruma", -18, TF, { by: ON });
  put("volleyball_cat", -8, TF, { by: ON });
  // たおれた的（台とネットのあいだ）
  put("volleyball_pin_lying", -70, 97, { by: 98 });
  put("volleyball_daruma_lying", -58, 99, { by: 100 });
  put(ROLL, -46, 96, { by: 97 });
  put("volleyball_net", -40, 90, { hit: [76, 4] });

  // 的の係（ネットのうしろ）
  maid("human_longhair_idle", "long", 6, 62, {
    name: "バレーぶ",
    lines: [
      "いらっしゃいませ！ バレーボールぶの ふうせんバレーへ ようこそ。",
      "ピン、かん、だるま、ぬいぐるみ。いろいろな まとが ならんでいるよ。",
      "たおれた まとは、わたしが たてなおすね。ふうせんは かるいから、おもいっきり スパイクしてね！",
    ],
  }, true);

  // ---- 奥の右: 3段の景品棚（上から ★★★ ★★ ★）とカウンター
  put("volleyball_shelf", 45, 70, { hit: [74, 6] });
  const SB = 71;
  put("volleyball_prize_l", 55, 38, { by: SB });
  put("volleyball_prize_m", 55, 55, { by: SB });
  put("volleyball_prize_s", 47, 68, { by: SB });
  put(TWINKLE, 40, 27, { by: 90, frame: 0 });
  put(TWINKLE, 57, 29, { by: 90, frame: 2 });
  put(TWINKLE, 73, 25, { by: 90, frame: 1 });
  put(TWINKLE, 66, 47, { by: 90, frame: 3 });
  put("volleyball_counter", 44, 90, { hit: [72, 8] });
  put("volleyball_bell", 20, 73, { by: 91 });
  maid("human_shorthair_idle", "short", 72, 74, {
    name: "バレーぶ",
    lines: [
      "いらっしゃいませ！ ここは しょうひんの たなだよ。",
      "たおした かずで、もらえる しょうひんが かわるんだ。ほしの ふだを みてね。",
      "ほしが すくない ところは ちいさな はこ、おおい ところは おおきな はこや ぬいぐるみ。",
      "なんかいでも あそんでね。つぎは もっと たおせるかも！",
    ],
  });

  // ---- 手前の左: スパイクのマット・ボールのスタンド・部員・お客さん
  put("volleyball_tee", -36, 112, { hit: [6, 4] });
  put(BALL, -36, 92, { by: 125, frame: 1 });
  put(BURST, -43, 81, { by: 126 });
  put(FLIGHT, -51, 82, { by: 127 });
  put("volleyball_basket", -84, 112, { hit: [20, 5] });

  // スパイクを打つお客さん
  person("human_spikeyhair_doing", -22, 110, {
    name: "おきゃくさん",
    lines: [
      "えいっ！ スパイク！ ふうせんだから かるくて、きもちいいよ。",
      "まとが たおれると、うれしいな！",
    ],
  }, true);
  // 悔しがるお客さん
  person("human_curlyhair_idle", -44, 126, {
    name: "こども",
    lines: [
      "あーっ、おしい！ ひとつ のこっちゃった…。",
      "もういっかい やる！ なんかいでも あそべるんだって。",
    ],
  });
  put("expression_stress", -44, 104, { by: 130 });
  // ボール係
  maid("human_mophair_idle", "mop", -6, 112, {
    name: "バレーぶ",
    lines: [
      "いらっしゃいませ！ ふうせんの ボールを わたすね。",
      "ここから スパイクして、むこうの まとを ねらってね。ジャンプして、うでを おおきく ふるのがコツだよ。",
      "ふうせんだから あんぜん。だれでも たのしめるよ！",
      "うまく あたると、まとが ころころ たおれるよ。",
    ],
  }, true);
  // 呼びこみ
  maid("human_bowlhair_idle", "bowl", -64, 126, {
    name: "バレーぶ",
    lines: [
      "いらっしゃいませ！ バレーボールぶの ふうせんバレーだよ！",
      "ふうせんの ボールを スパイクして、まとを たおす ゲームなんだ。",
      "バレーボールを したことが なくても、だいじょうぶ。なんかいでも あそんでね！",
    ],
  });

  // ---- 手前の右: 景品をもらって喜ぶお客さん
  person("human_shorthair_idle", 66, 126, {
    name: "おきゃくさん",
    lines: [
      "しょうひん、もらったよ！ たくさん たおせて うれしい！",
      "つぎは もっと たおして、おおきな はこを ねらうんだ。",
    ],
  });
  put("expression_love", 66, 104, { by: 130 });
  put("volleyball_gift", 74, 123, { by: 128 });

  // ---- 漂う風船
  put(BAL[0], -88, 16, { by: 131, frame: 0 });
  put(BAL[2], -4, 40, { by: 131, frame: 4 });
}
