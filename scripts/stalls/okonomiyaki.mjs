/** お好み焼き屋。専用ドット絵は scripts/stalls/okonomiyaki.ps1（okonomi_*.png） */
export const meta = { id: "okonomiyaki", label: "お好み焼き屋", island: "浮島 27" };

export default function layout(k) {
  for (const n of ["okonomi_sign", "okonomi_lantern", "okonomi_menu", "okonomi_teppan", "okonomi_plate", "okonomi_counter", "okonomi_roof", "okonomi_post"]) k.custom(n);
  k.custom("okonomi_nobori", 1, 78);
  const TABLE = k.cropAt(808, 586); // 四角い木のテーブル
  const RUG = k.cropRect(644, 563, 41, 42); // 赤い敷物
  const POT_A = k.cropAt(825, 519); // ひまわりの鉢
  const POT_B = k.cropAt(841, 519);
  const STOOL = k.cropAt(805, 543); // 小さな丸椅子
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 敷物（床）。カウンターの前の「ここに立つ」マット
  put(RUG, 0, 108, { sort: "floor" });

  // 柱・日よけ・看板
  put("okonomi_post", -51, 78, { hit: [6, 6] });
  put("okonomi_post", 51, 78, { hit: [6, 6] });
  put("okonomi_roof", 0, 42);
  put("okonomi_sign", 0, 22);
  // 提灯（日よけの下）
  put("okonomi_lantern", -34, 64, { by: 60 });
  put("okonomi_lantern", 34, 64, { by: 60 });
  // のぼり旗（両脇）
  put("okonomi_nobori", -74, 76, { hit: [4, 4] });
  put("okonomi_nobori", 74, 76, { hit: [4, 4] });

  // カウンターの奥: 鉄板・店主・湯気
  put("okonomi_teppan", 16, 68);
  put("chimneysmoke_03", 8, 44, { by: 70 });
  put("chimneysmoke_03", 24, 44, { by: 70 });
  put("chimneysmoke_03", 16, 40, { by: 70 });
  person("human_shorthair_doing", -14, 56, {
    name: "お好み焼き屋さん",
    lines: [
      "いらっしゃい！ お好み焼き、やっています！",
      "キャベツたっぷりの生地を、鉄板でじゅーっと焼くよ。",
      "ソースの いいにおいが してきたら、もうすぐ できあがり。あつあつを どうぞ！",
      "ひっくり返すのが一番むずかしいんだ。コテさばきを見ていってね！",
    ],
  });
  put("expression_chat", -14, 33, { by: 90 });

  // カウンター（赤い前掛け）と、その上の食べ物・飲み物・調味料
  put("okonomi_counter", 0, 80, { hit: [100, 10] });
  put("kale_05", -42, 64, { by: ON_COUNTER });
  put("egg", -30, 64, { by: ON_COUNTER });
  put("egg", -22, 65, { by: ON_COUNTER });
  put("spr_deco_jar_01", -4, 64, { by: ON_COUNTER }); // ソース
  put("spr_deco_mug_02", 28, 63, { by: ON_COUNTER });
  put("okonomi_plate", 34, 63, { by: ON_COUNTER });
  put("okonomi_plate", 54, 63, { by: ON_COUNTER });

  // 前のお客さん
  person("human_curlyhair_idle", 30, 98, { name: "おきゃくさん", lines: ["ここのお好み焼き、ソースの香りがたまらない！", "ふわふわで、キャベツが甘いんだよ。"] }, true);
  put("happiness_01", 30, 74, { by: 120 });
  person("human_mophair_waiting", -44, 108, { name: "こども", lines: ["はやく食べたいなあ！", "あつあつだから、ふーふーして食べるんだ。"] });

  // テーブル席: テーブルに皿、丸椅子
  put(TABLE, -62, 118, { hit: [18, 8] });
  put("okonomi_plate", -66, 106, { by: 119 });
  put("okonomi_plate", -56, 108, { by: 119 });
  put("spr_deco_mug_01", -50, 106, { by: 119 });
  put(STOOL, -84, 120, { hit: [8, 6] });
  put(STOOL, -40, 124, { hit: [8, 6] });

  // メニュー（右手前の黒板）と飾りのひまわり
  put("okonomi_menu", 68, 128, { hit: [44, 6] });
  put(POT_A, 86, 126);
  put(POT_B, -90, 100);
}
