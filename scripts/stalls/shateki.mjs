/** 射的（しゃてき）。専用ドット絵は scripts/stalls/shateki.ps1（shateki_*.png） */
export const meta = { id: "shateki", label: "射的", island: "浮島 24" };

export default function layout(k) {
  for (const n of ["sign", "roof", "post", "lantern", "shelf", "bear", "bunny", "chick", "frog", "caramel", "snack_pink", "snack_green", "choco", "robot", "piggy", "ball", "ramune", "star", "tag", "gun", "corks", "cork_sign", "board", "mat", "counter"]) k.custom(`shateki_${n}`);
  k.custom("shateki_nobori", 1, 78);
  const SPARKLE = k.custom("shateki_sparkle", undefined, undefined, { frames: 4, fps: 5 });
  const PENDULUM = k.custom("shateki_pendulum", undefined, undefined, { frames: 4, fps: 3 });
  const SHOT = k.custom("shateki_shot", undefined, undefined, { frames: 4, fps: 4 });
  const WHEEL = k.custom("shateki_wheel", undefined, undefined, { frames: 4, fps: 6 });
  const CRATE = "spr_deco_crate_01";
  const { put, person } = k;

  const SHELF_BY = 70; // 棚(by 70)より手前に景品を描く
  const PRIZE = 71;
  const ON_COUNTER = 95; // カウンター(足元94)より手前

  // 床: ここから撃つマット
  put("shateki_mat", -14, 116, { sort: "floor" });

  // 柱・紅白の幕・看板
  put("shateki_post", -55, 94, { hit: [6, 6] });
  put("shateki_post", 55, 94, { hit: [6, 6] });
  put("shateki_roof", 0, 28, { by: 80 });
  put("shateki_sign", 0, 14);
  // 提灯（幕の両端）
  put("shateki_lantern", -62, 52, { by: 95 });
  put("shateki_lantern", 62, 52, { by: 95 });
  // のぼり旗（両脇）
  put("shateki_nobori", -80, 84, { hit: [4, 4] });
  put("shateki_nobori", 80, 84, { hit: [4, 4] });

  // 景品棚（3段）
  put("shateki_shelf", -14, 72, { by: SHELF_BY });
  const T1 = 43, T2 = 57, T3 = 70; // 各段の床（景品の足元）
  const p = (n, dx, foot) => put(`shateki_${n}`, dx, foot, { by: PRIZE });
  // 上段: ぬいぐるみ
  p("bear", -46, T1); p("bunny", -35, T1); p("chick", -25, T1); p("frog", -14, T1); p("bear", -3, T1); p("bunny", 8, T1); p("chick", 17, T1);
  // 中段: おもちゃ・おかし
  p("robot", -45, T2); p("snack_green", -35, T2); p("piggy", -23, T2); p("ball", -11, T2); p("ramune", -2, T2); p("star", 8, T2); p("robot", 18, T2);
  // 下段: おかしの箱
  p("caramel", -45, T3); p("caramel", -33, T3); p("snack_pink", -21, T3); p("choco", -10, T3); p("snack_pink", 1, T3); p("caramel", 10, T3);
  // 値段の書いてない札
  p("tag", -40, T1); p("tag", -19, T2); p("tag", 3, T3); p("tag", 13, T1);
  // きらっと光る景品
  put(SPARKLE, -45, T1 - 7, { by: 76, frame: 0 });
  put(SPARKLE, -12, T2 - 9, { by: 76, frame: 2 });
  put(SPARKLE, 10, T1 - 5, { by: 76, frame: 1 });
  put(SPARKLE, 8, T2 - 7, { by: 76, frame: 3 });

  // ぶらさがった的（ゆれる）
  put(PENDULUM, 33, 58, { by: 60 });

  // 店番
  person("human_shorthair_doing", 43, 63, {
    name: "しゃてきやさん",
    lines: [
      "いらっしゃい！ しゃてき、やっているよ！",
      "コルクのたまを、このじゅうでうって、たなのけいひんをねらうんだ。ぬいぐるみやおかしが、いっぱいあるよ。",
      "じゅうのさきにコルクをつめて、うでをのばして、まっすぐかまえるのがコツだよ。",
      "おおきなぬいぐるみはおもくて、なかなかおちない。ちいさいおかしのはこが、ねらいめかも！",
    ],
  });
  put("expression_chat", 43, 40, { by: 90 });

  // カウンター（青い前板に紅白のへり）と、その上の銃・コルク・札
  put("shateki_counter", 0, 94, { hit: [108, 10] });
  put("shateki_gun", -34, 76, { by: ON_COUNTER });
  put("shateki_corks", -8, 76, { by: ON_COUNTER });
  put("shateki_cork_sign", 36, 77, { by: ON_COUNTER });

  // 前のお客さん: マットに立って、コルクを撃つところ
  person("human_mophair_idle", 8, 112, {
    name: "こども",
    lines: ["ぼく、あのくまのぬいぐるみがほしいんだ！", "まんなかをねらって……ぽん！ あっ、おしい！ もういっかい！"],
  });
  put(SHOT, 22, 100, { by: 118 });
  person("human_longhair_idle", 28, 116, {
    name: "おきゃくさん",
    lines: ["えんにちみたいで、わくわくするね。", "どのけいひんにしようかな。まよっちゃう！"],
  }, true);

  // 景品の山（左前）と、まわる的・立て札（右前）
  put(CRATE, -85, 124, { hit: [14, 6] });
  put("shateki_bear", -85, 104, { by: 125 });
  put("shateki_bunny", -80, 108, { by: 126 });
  put(WHEEL, -64, 112, { hit: [8, 4] });
  put("shateki_board", 70, 128, { hit: [44, 6] });
}
