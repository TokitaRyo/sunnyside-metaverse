/** カフェ。専用ドット絵は scripts/stalls/cafe.ps1（cafe_*.png） */
export const meta = { id: "cafe", label: "カフェ", island: "浮島 25" };

export default function layout(k) {
  for (const n of ["cafe_sign", "cafe_awning", "cafe_wall", "cafe_counter", "cafe_machine", "cafe_dome", "cafe_cakeplate", "cafe_cup", "cafe_icecoffee", "cafe_parfait", "cafe_teapot", "cafe_table", "cafe_chair", "cafe_chair_back", "cafe_parasol_mint", "cafe_parasol_rose", "cafe_board", "cafe_plant", "cafe_deck"]) k.custom(n);
  k.custom("cafe_signpost", 7, 66);
  k.custom("cafe_steam", undefined, undefined, { frames: 6, fps: 6 });
  const BUSH = k.cropAt(800, 30); // まるい植え込み
  const DAISY_A = k.cropAt(857, 520); // ひなぎくの鉢
  const DAISY_B = k.cropAt(872, 518);
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // テラスの木のデッキ（床）
  put("cafe_deck", 0, 128, { sort: "floor" });

  // 店の構え: 奥の壁・オーニング・看板（壁はバリスタより奥、オーニングは壁より手前）
  put("cafe_wall", 0, 58, { by: 50, hit: [124, 6] });
  put("cafe_awning", 0, 34, { by: 60 });
  put("cafe_sign", 0, 16, { by: 55 });
  put("cafe_signpost", -92, 72, { hit: [5, 4] });

  // カウンターの奥: バリスタ
  person("human_shorthair_doing", -14, 58, {
    name: "カフェのてんいんさん",
    lines: [
      "いらっしゃいませ！ カフェへようこそ。",
      "コーヒーやこうちゃ、ケーキ、パフェを用意しているよ。",
      "ゆっくりすわって、ひとやすみしていってね。",
      "テラスのテーブルも、じゆうにつかってね！",
    ],
  });
  put("expression_chat", -14, 35, { by: 90 });

  // カウンターと上の品
  put("cafe_counter", 0, 80, { hit: [114, 10] });
  put("cafe_dome", -46, 62, { by: ON_COUNTER });
  put("cafe_cakeplate", -31, 62, { by: ON_COUNTER });
  put("cafe_cup", 0, 62, { by: ON_COUNTER });
  put("cafe_steam", 0, 55, { by: 90 });
  put("cafe_parfait", 12, 62, { by: ON_COUNTER });
  put("cafe_icecoffee", 22, 62, { by: ON_COUNTER });
  put("cafe_machine", 40, 62, { by: ON_COUNTER });
  put("cafe_steam", 36, 40, { by: 90 });
  put("cafe_teapot", 55, 62, { by: ON_COUNTER });
  put(DAISY_A, -55, 62, { by: ON_COUNTER });

  // 左の黒板メニュー（デッキの左はし）
  put("cafe_board", -66, 124, { hit: [44, 6] });

  // テラス席A（ミントのパラソル）
  put("cafe_chair", -30, 121);
  put("cafe_table", -8, 124, { hit: [22, 8] });
  put("cafe_chair_back", -8, 129);
  put("cafe_cakeplate", -13, 112, { by: 125 });
  put("cafe_cup", -2, 113, { by: 125 });
  put("cafe_steam", -2, 105, { by: 140 });
  put("cafe_parasol_mint", -8, 109, { by: 126 });

  // テラス席B（ローズのパラソル）
  put("cafe_table", 52, 122, { hit: [22, 8] });
  put("cafe_chair", 74, 121);
  put("cafe_chair_back", 52, 128);
  put("cafe_parfait", 47, 110, { by: 123 });
  put("cafe_icecoffee", 58, 111, { by: 123 });
  put("cafe_parasol_rose", 52, 107, { by: 124 });

  // 植物
  put("cafe_plant", 80, 80, { hit: [10, 6] });
  put(BUSH, 90, 100);
  put(DAISY_B, 90, 124);

  // 客
  person("human_curlyhair_idle", 20, 96, { name: "おきゃくさん", lines: ["ここのケーキ、ふわふわでおいしいの。", "コーヒーのいいにおいがするね。"] }, true);
  put("happiness_01", 20, 78, { by: 120 });
  person("human_bowlhair_idle", 22, 122, { name: "おきゃくさん", lines: ["テラスせきは、おひさまがきもちいいよ。", "パフェをのんびり食べるのが、すきなんだ。"] }, true);
  put("spr_deco_bird_01", -80, 130, { by: 129 }); // デッキを歩くはと
}
