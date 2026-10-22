/** 大判焼き屋。専用ドット絵は scripts/stalls/obanyaki.ps1（obanyaki_*.png） */
export const meta = { id: "obanyaki", label: "大判焼き屋" };

export default function layout(k) {
  for (const n of ["obanyaki_lantern", "obanyaki_menu", "obanyaki_pile", "obanyaki_plate", "obanyaki_bag", "obanyaki_bowl", "obanyaki_ladle", "obanyaki_counter", "obanyaki_roof", "obanyaki_post", "obanyaki_mat"]) k.custom(n);
  k.custom("obanyaki_nobori", 1, 78);
  k.custom("obanyaki_sign", undefined, undefined, { frames: 2, fps: 2 }); // 電球がまたたく看板
  k.custom("obanyaki_grill", undefined, undefined, { frames: 4, fps: 2 }); // 生地を流す→焼ける→焼き上がる
  k.custom("obanyaki_flame", undefined, undefined, { frames: 4, fps: 8 });
  const TABLE = k.cropAt(808, 586); // 四角い木のテーブル
  const STOOL = k.cropAt(805, 543); // 小さな丸椅子
  const POT_A = k.cropAt(825, 519); // ひまわりの鉢
  const POT_B = k.cropAt(841, 519);
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く
  const GX = 22; // 焼き型の中心

  // 敷物（床）。カウンターの前の「ここに立つ」マット
  put("obanyaki_mat", 0, 108, { sort: "floor" });

  // 柱・日よけ・看板
  put("obanyaki_post", -64, 78, { hit: [6, 6] });
  put("obanyaki_post", 64, 78, { hit: [6, 6] });
  put("obanyaki_roof", 0, 42);
  put("obanyaki_sign", 0, 24);
  // 提灯（日よけの下）
  put("obanyaki_lantern", -54, 47, { by: 60 });
  put("obanyaki_lantern", 54, 47, { by: 60 });
  // のぼり旗（両脇）
  put("obanyaki_nobori", -80, 76, { hit: [4, 4] });
  put("obanyaki_nobori", 80, 76, { hit: [4, 4] });

  // 店主はカウンターの奥、左寄り
  person("human_bowlhair_doing", -26, 56, {
    name: "大判焼き屋さん",
    lines: [
      "いらっしゃい！ 大判焼き、やいていますよ。",
      "まるい型に生地を流して、じっくり焼いて、くるっとひっくり返すんだ。",
      "地方によって、今川焼きとか回転焼きとか、よび方がちがうんだって。",
      "やきたてのあつあつを、ぜひ食べていってね！",
    ],
  });
  put("expression_chat", -26, 33, { by: 90 });

  // 焼き型（カウンターの上）。丸い型が並び、生地を流す→焼ける→焼き上がるが順にめぐる。火口の炎と湯気も動く
  put("obanyaki_grill", GX, 65, { by: ON_COUNTER });
  put("obanyaki_flame", GX, 63, { by: ON_COUNTER + 1 });
  put("chimneysmoke_03", GX - 14, 40, { by: 82 });
  put("chimneysmoke_03", GX + 12, 41, { by: 82, frame: 12 });
  put("chimneysmoke_02", GX - 1, 38, { by: 82, frame: 6 });

  // カウンター（深緑の前掛け）と、その上の焼き上がりの山・生地のボウル・お玉
  put("obanyaki_counter", 0, 80, { hit: [120, 10] });
  put("obanyaki_pile", -48, 64, { by: ON_COUNTER });
  put("chimneysmoke_02", -48, 38, { by: 82, frame: 18 });
  put("obanyaki_bowl", -12, 64, { by: ON_COUNTER });
  put("obanyaki_ladle", 55, 68, { by: ON_COUNTER });

  // カウンターの左どなりで、できたてを渡す部員
  person("human_shorthair_doing", -74, 90, {
    name: "ばいてんの部員",
    lines: [
      "大判焼き、焼きたてですよー！",
      "生地は小麦粉と たまごと さとうを まぜて作るんだよ。ダマにならないように ていねいに まぜるのがコツ。",
      "型にあぶらをぬってから生地を流すと、きれいにまるく焼けるんだ。",
    ],
  });
  
  // 前のお客さん（大判焼きを持って食べている）
  person("human_curlyhair_idle", -2, 98, { name: "おきゃくさん", lines: ["ここの大判焼き、まるくて、ほかほか！", "ふちが すこし かりっとしていて、おいしいなあ。"] }, true);
  put("happiness_01", -2, 74, { by: 120 });
  person("human_mophair_idle", -40, 108, { name: "こども", lines: ["はやく食べたいなあ！", "あつあつだから、ふーふーして食べるんだ。"] });
  person("human_spikeyhair_idle", 22, 108, { name: "おきゃくさん", lines: ["まるい型で焼くから、どれもまんまるだね。", "おみやげに もって帰ろうかな。"] });
  put("obanyaki_bag", 10, 116, { by: 121 });

  // テーブル席: テーブルに焼きたてと紙袋、おちゃ。丸椅子
  put(TABLE, -62, 124, { hit: [18, 8] });
  put("obanyaki_plate", -68, 112, { by: 125 });
  put("obanyaki_plate", -54, 114, { by: 125 });
  put("spr_deco_mug_01", -61, 106, { by: 125 });
  put(STOOL, -86, 124, { hit: [8, 6] });
  put(STOOL, -40, 127, { hit: [8, 6] });

  // メニュー（右手前の黒板）と飾りのひまわり
  put("obanyaki_menu", 64, 128, { hit: [54, 6] });
  put(POT_A, 90, 70);
  put(POT_B, -92, 100);
}
