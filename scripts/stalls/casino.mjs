/**
 * 模擬カジノ（文化祭）。専用ドット絵は scripts/stalls/casino.ps1（casino_*.png）。
 * ゲーム用のコインやチップだけで遊ぶ。お金は賭けない。島の奥に「CASINO」のネオンと壁・スロット、真ん中にルーレット台とカードテーブル、
 * 手前にダイス台とコインのカウンター、入口には赤い絨毯とベルベットロープ。
 */
export const meta = { id: "casino", label: "カジノ", island: "浮島 18" };

export default function layout(k) {
  // ---- アニメ（横一列のシート）
  k.custom("casino_sign", undefined, undefined, { frames: 6, fps: 3 });
  k.custom("casino_marquee", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("casino_vsign", undefined, undefined, { frames: 4, fps: 2 });
  k.custom("casino_slot_r", undefined, undefined, { frames: 4, fps: 8 });
  k.custom("casino_slot_g", undefined, undefined, { frames: 4, fps: 8 });
  k.custom("casino_wheel", undefined, undefined, { frames: 6, fps: 10 });
  k.custom("casino_dice", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("casino_sparkle", undefined, undefined, { frames: 4, fps: 5 });
  k.custom("casino_glow", undefined, undefined, { frames: 3, fps: 3 });
  // ---- 静止
  for (const n of ["floor", "wall", "plaque", "roulette_table", "card_table", "dice_table", "counter", "chips_a", "chips_b", "rope", "bowtie", "stool", "plant"]) k.custom(`casino_${n}`);

  const { put, person, blocker } = k;
  const SPARK = "casino_sparkle";

  // ---- 床（黒い市松に赤い絨毯）と、テーブルの光だまり
  put("casino_floor", 0, 128, { sort: "floor" });
  put("casino_glow", -48, 113, { sort: "floor", by: 129 });
  put("casino_glow", 48, 113, { sort: "floor", by: 129, frame: 1 });

  // ---- 奥の壁・電球・看板・札
  put("casino_wall", 0, 56, { by: 56, hit: [192, 8] });
  put("casino_marquee", 0, 24, { by: 57 });
  put("casino_sign", 0, 26, { by: 58 });
  put("casino_plaque", 0, 56, { by: 57 });

  // ---- たて型のネオン「カジノ」（左右）
  put("casino_vsign", -88, 100, { by: 61 });
  put("casino_vsign", 88, 100, { by: 61, frame: 2 });
  blocker(-88, 100, 8, 4);
  blocker(88, 100, 8, 4);

  // ---- スロットマシン（壁ぞいに左3台・右3台。リールの位置をずらす）
  const slotsX = [-88, -73, -58, 58, 73, 88];
  slotsX.forEach((dx, i) => {
    put(i % 2 === 0 ? "casino_slot_r" : "casino_slot_g", dx, 60, { by: 62, hit: [13, 6], frame: i % 4 });
  });
  for (const dx of [-88, -58, 73]) put("casino_stool", dx, 68, { by: 69 });
  put(SPARK, -73, 36, { by: 90, frame: 1 });
  put(SPARK, 88, 42, { by: 90, frame: 3 });

  // ---- ルーレット台（左）: ディーラーは台の奥。回転盤は台の左に重ねる
  person("human_shorthair_idle", -48, 76, {
    name: "ルーレットがかり",
    lines: [
      "いらっしゃいませ！ ここは コインで あそぶ、もぎカジノだよ。",
      "おかねは かけません。ゲームようの コインと チップで、たのしく あそぶだけ！",
      "ルーレットは、まわる ばんの うえに ボールを おとして、どこで とまるかを あてる ゲームなんだ。",
      "あかか くろか、すうじか…。どきどき するけど、ここでは あそびだから あんしんしてね。",
    ],
  });
  put("casino_bowtie", -48, 72, { by: 77 });
  put("casino_roulette_table", -48, 106, { by: 106, hit: [60, 28] });
  put("casino_wheel", -63, 94, { by: 107 });
  put("casino_chips_a", -29, 101, { by: 107 });
  put(SPARK, -35, 84, { by: 108, frame: 2 });

  // ---- カードテーブル（右）
  person("human_longhair_idle", 48, 76, {
    name: "ディーラー",
    lines: [
      "ようこそ！ わたしは カードテーブルの ディーラーだよ。",
      "ブラックジャックは ふつう、カードの かずを たして 21に ちかづける ゲームなんだ。",
      "ここで つかうのは ゲームの チップだけ。おかねは かけないから、きがるに あそんでね。",
    ],
  });
  put("casino_bowtie", 48, 72, { by: 77 });
  put("casino_card_table", 48, 106, { by: 106, hit: [58, 28] });
  put("casino_chips_b", 66, 96, { by: 107 });
  put(SPARK, 44, 89, { by: 108, frame: 0 });

  // ---- ダイス台（左手前）。ダイスがころがる
  put("casino_dice_table", -70, 128, { by: 128, hit: [44, 22] });
  put("casino_dice", -68, 117, { by: 129 });
  put("casino_chips_a", -82, 117, { by: 129 });

  // ---- コインのカウンター（右手前）。店員は奥
  person("human_bowlhair_idle", 60, 110, {
    name: "コインがかり",
    lines: [
      "ここは コインの カウンターだよ。ゲームで つかう コインの おせわを しているんだ。",
      "コインも チップも、このカジノの なかだけの もの。おかねは かけない、みんなで たのしむ カジノなんだ。",
      "あかい じゅうたんを とおって、すきな ゲームで あそんでいってね！",
    ],
  });
  put("casino_bowtie", 60, 106, { by: 111 });
  put("casino_counter", 68, 128, { by: 128, hit: [54, 14] });
  put(SPARK, 86, 107, { by: 140, frame: 2 });

  // ---- 入口のベルベットロープ（真ん中の通路はあける）
  put("casino_rope", -20, 126, { by: 126, hit: [20, 4] });
  put("casino_rope", 20, 126, { by: 126, hit: [20, 4] });

  // ---- お客さん
  person("human_curlyhair_idle", -70, 72, {
    name: "おきゃくさん",
    lines: ["スロットの リール、くるくる まわって きれい！ 7が そろうと いいなあ。", "コインだけで あそべるから、きがるだよ。"],
  }, true);
  person("human_longhair_idle", 68, 72, {
    name: "おきゃくさん",
    lines: ["ぴかぴかの ランプが ついたら、リールが とまる あいずかな？", "かてても まけても、ゲームの コインだから へいきだよ。"],
  });
  person("human_curlyhair_idle", -30, 112, {
    name: "おきゃくさん",
    lines: ["あかに する？ くろに する？ まよっちゃう！", "チップは ゲームの ものだから、はずれても へいき。また あそべるよ！"],
  }, true);
  person("human_spikeyhair_idle", -42, 126, {
    name: "おきゃくさん",
    lines: ["サイコロを ころがす しゅんかんが いちばん わくわく！", "でた めの かずを みんなで みるのも たのしいよ。"],
  });
  person("human_mophair_idle", 32, 112, {
    name: "こども",
    lines: ["トランプって、どきどき するね！", "21に ちかづけるの、むずかしいなあ。"],
  }, true);
  person("human_bowlhair_idle", -8, 92, {
    name: "おきゃくさん",
    lines: ["ネオンが ぴかぴか！ カジノって きらきら してるね。", "あの スロット、リールが くるくる まわって きれいだよ。"],
  });
  person("human_shorthair_idle", 10, 106, {
    name: "おきゃくさん",
    lines: ["あかい じゅうたんを あるくと、ちょっと えらく なった きぶん。", "かんばんに 「コインで あそぼう」って かいてあるでしょ？ おかねは かけないんだって。"],
  }, true);
}
