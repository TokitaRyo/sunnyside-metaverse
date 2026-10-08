/** 油そば屋。専用ドット絵は scripts/stalls/aburasoba.ps1（aburasoba_*.png） */
export const meta = { id: "aburasoba", label: "油そば", island: "浮島 14" };

export default function layout(k) {
  for (const n of ["aburasoba_sign", "aburasoba_menu", "aburasoba_bowl", "aburasoba_bowl_s", "aburasoba_bowls", "aburasoba_prep", "aburasoba_ajitama", "aburasoba_condi", "aburasoba_bar", "aburasoba_stool", "aburasoba_ticket", "aburasoba_mat", "aburasoba_counter", "aburasoba_roof", "aburasoba_post", "aburasoba_pot", "aburasoba_wall"]) k.custom(n);
  k.custom("aburasoba_nobori", 1, 78);
  k.custom("aburasoba_steam", 15, 34, { frames: 6, fps: 7 }); // 寸胴からもくもく上る湯気
  k.custom("aburasoba_bowl_a", undefined, undefined, { frames: 4, fps: 5 }); // 湯気の立つどんぶり
  k.custom("aburasoba_lantern_a", undefined, undefined, { frames: 3, fps: 3 }); // ゆらぐ赤提灯
  const CRATE = "spr_deco_crate_01";
  const SUNFLOWER = k.cropAt(825, 519); // ひまわりの鉢
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 床のマット（カウンターの前の「ここで注文」場所）
  put("aburasoba_mat", 12, 116, { sort: "floor" });
  put("aburasoba_wall", 0, 56, { sort: "floor" }); // 店の奥の黒い壁

  // 柱・暖簾の屋根・看板
  put("aburasoba_post", -58, 78, { hit: [6, 6] });
  put("aburasoba_post", 58, 78, { hit: [6, 6] });
  put("aburasoba_roof", 0, 40, { by: 41 });
  put("aburasoba_sign", 0, 19);
  // 赤提灯（屋根のすみから）
  put("aburasoba_lantern_a", -68, 56, { by: 80 });
  put("aburasoba_lantern_a", 68, 56, { by: 80 });
  // のぼり旗（両脇）
  put("aburasoba_nobori", -92, 76, { hit: [4, 4] });
  put("aburasoba_nobori", 82, 76, { hit: [4, 4] });

  // カウンターの奥: 寸胴の鍋・湯気・店主
  put("aburasoba_pot", -34, 66, { by: 50 });
  put("aburasoba_steam", -33, 43, { by: 75 });
  person("human_mophair_doing", 2, 58, {
    name: "油そば屋さん",
    lines: [
      "いらっしゃい！ 油そば、やっています！",
      "油そばは、スープのない「汁なし」のめん料理だよ。ふといめんを、おおきな寸胴でぐらぐらゆでるんだ。",
      "どんぶりの底のたれと、あついめんを、下からよーくまぜてね。",
      "よくまぜてから食べると、おいしいよ。あつあつを、ずるずるっとどうぞ！",
    ],
  }, true);
  put("expression_chat", -12, 41, { by: 90 });

  // カウンター（赤い前板に雷文）と、その上: 具の仕込み・味玉・どんぶり・調味料
  put("aburasoba_counter", 0, 80, { hit: [116, 10] });
  put("aburasoba_prep", -42, 65, { by: ON_COUNTER });
  put("aburasoba_ajitama", -20, 64, { by: ON_COUNTER });
  put("aburasoba_bowl_a", 21, 66, { by: ON_COUNTER });
  put("aburasoba_bowl_a", 38, 65, { by: ON_COUNTER, frame: 2 });
  put("aburasoba_bowls", 52, 64, { by: ON_COUNTER });

  // 前のお客さん（マットのところで注文）
  person("human_shorthair_idle", 8, 104, { name: "おきゃくさん", lines: ["ここの油そば、いいにおい！", "よーくまぜて食べるのが、コツなんだって。"] }, false);
  put("happiness_01", 8, 80, { by: 120 });

  // カウンター席（右手前）: 長いバーに、どんぶりと卓上の調味料。赤い丸椅子が3つ
  put("aburasoba_bar", 56, 104, { hit: [62, 8] });
  put("aburasoba_bowl", 34, 91, { by: 105 });
  put("aburasoba_condi", 66, 92, { by: 105 });
  put("aburasoba_stool", 40, 122);
  put("aburasoba_stool", 58, 122);
  put("aburasoba_stool", 76, 122, { by: 117 }); // こどもが座る椅子（こどもを手前に描く）
  person("human_spikeyhair_idle", 76, 119, { name: "こども", lines: ["ぼくはね、よーくまぜるのがすき！", "ずるずるっていっぱい食べると、おなかいっぱいになるよ。"] }, true);

  // 左手前: 食券機と、メニューの黒板
  put("aburasoba_ticket", -87, 100, { hit: [16, 6] });
  put("aburasoba_menu", -42, 128, { hit: [54, 6] });
  put(CRATE, -88, 124, { hit: [14, 6] });
  put(SUNFLOWER, 90, 127);
}
