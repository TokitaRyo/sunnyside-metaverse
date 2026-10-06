/** たい焼き屋。専用ドット絵は scripts/stalls/taiyaki.ps1（taiyaki_*.png） */
export const meta = { id: "taiyaki", label: "たい焼き屋", island: "浮島 26" };

export default function layout(k) {
  for (const n of ["taiyaki_sign", "taiyaki_lantern", "taiyaki_menu", "taiyaki_grill", "taiyaki_fish", "taiyaki_tray", "taiyaki_bag", "taiyaki_plate", "taiyaki_anko", "taiyaki_custard", "taiyaki_counter", "taiyaki_roof", "taiyaki_post", "taiyaki_mat"]) k.custom(n);
  k.custom("taiyaki_nobori", 1, 78);
  k.custom("taiyaki_flame", undefined, undefined, { frames: 4, fps: 8 });
  const TABLE = k.cropAt(808, 586); // 四角い木のテーブル
  const STOOL = k.cropAt(805, 543); // 小さな丸椅子
  const POT_A = k.cropAt(825, 519); // ひまわりの鉢
  const POT_B = k.cropAt(841, 519);
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く
  const GX = 26; // 焼き台の中心

  // 敷物（床）。カウンターの前の「ここに立つ」マット
  put("taiyaki_mat", 0, 108, { sort: "floor" });

  // 柱・日よけ・看板
  put("taiyaki_post", -51, 78, { hit: [6, 6] });
  put("taiyaki_post", 51, 78, { hit: [6, 6] });
  put("taiyaki_roof", 0, 42);
  put("taiyaki_sign", 0, 22);
  // 提灯（日よけの下）
  put("taiyaki_lantern", -46, 47, { by: 60 });
  put("taiyaki_lantern", 46, 47, { by: 60 });
  // のぼり旗（両脇）
  put("taiyaki_nobori", -74, 76, { hit: [4, 4] });
  put("taiyaki_nobori", 74, 76, { hit: [4, 4] });

  // 店主はカウンターの奥、左側
  person("human_bowlhair_doing", -8, 56, {
    name: "たい焼き屋さん",
    lines: [
      "いらっしゃい！ たい焼き、やいていますよ。",
      "さかなの形のかたに生地を流して、あんこをのせて、ひとつずつ丁寧にひっくり返すんだ。",
      "あんこと、とろとろのクリームと、チョコがあるよ。",
      "やきたてのあつあつを、ぜひ頭からでもしっぽからでも食べてね！",
    ],
  });
  put("expression_chat", -8, 33, { by: 90 });

  // 焼き台（カウンターの上、右側）。火口の炎は動く。湯気も出る
  put("taiyaki_grill", GX, 65, { by: ON_COUNTER });
  put("taiyaki_flame", GX, 63, { by: ON_COUNTER + 1 });
  put("chimneysmoke_03", GX - 12, 40, { by: 82 });
  put("chimneysmoke_03", GX + 10, 41, { by: 82, frame: 12 });
  put("chimneysmoke_02", GX + 1, 38, { by: 82, frame: 6 });

  // カウンター（藍の前掛け）と、その上の焼きたて・紙袋・あんこ
  put("taiyaki_counter", 0, 80, { hit: [100, 10] });
  put("taiyaki_tray", -34, 66, { by: ON_COUNTER });
  put("taiyaki_anko", -12, 64, { by: ON_COUNTER });
  put("taiyaki_custard", -3, 64, { by: ON_COUNTER });

  // 前のお客さん（たい焼きを持って食べている）
  person("human_curlyhair_idle", 14, 98, { name: "おきゃくさん", lines: ["ここのたい焼き、さくっとして、あんこがあまーい！", "しっぽまで、あんこがはいってるのがうれしいな。"] }, true);
  put("happiness_01", 14, 74, { by: 120 });
  person("human_mophair_waiting", -30, 104, { name: "こども", lines: ["ぼくは、クリームがいちばんすき！", "あつあつだから、ふーふーして食べるんだ。"] });

  // テーブル席: テーブルに焼きたてと紙袋、おちゃ。丸椅子
  put(TABLE, -62, 118, { hit: [18, 8] });
  put("taiyaki_plate", -66, 106, { by: 119 });
  put("taiyaki_plate", -55, 108, { by: 119 });
  put("spr_deco_mug_01", -60, 100, { by: 119 });
  put(STOOL, -84, 120, { hit: [8, 6] });
  put(STOOL, -40, 124, { hit: [8, 6] });

  // メニュー（右手前の黒板）と飾りのひまわり
  put("taiyaki_menu", 62, 128, { hit: [54, 6] });
  put(POT_A, 90, 70);
  put(POT_B, -90, 98);
}
