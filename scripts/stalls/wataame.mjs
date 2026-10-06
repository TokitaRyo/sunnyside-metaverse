/** わたあめ屋台。専用ドット絵は scripts/stalls/wataame.ps1（wataame_*.png） */
export const meta = { id: "wataame", label: "わたあめ", island: "浮島 16" };

export default function layout(k) {
  for (const n of ["back", "sign", "roof", "post", "counter", "rack_a", "rack_b", "jar_a", "jar_b", "bagstand", "menu", "mat"]) k.custom(`wataame_${n}`);
  k.custom("wataame_nobori_blue", 1, 82);
  k.custom("wataame_nobori_pink", 1, 82);
  k.custom("wataame_machine", undefined, undefined, { frames: 6, fps: 8 }); // 釜が回って綿がふくらむ
  k.custom("wataame_balloon_a", 9, 46, { frames: 4, fps: 3 });
  k.custom("wataame_balloon_b", 9, 46, { frames: 4, fps: 3 });
  k.custom("wataame_sparkle", 4.5, 4.5, { frames: 4, fps: 5 });
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 床のマット（カウンターの前の「ここに立つ」場所）
  put("wataame_mat", 0, 108, { sort: "floor" });

  // 柱・奥の壁・屋根・看板
  put("wataame_post", -51, 78, { hit: [6, 6] });
  put("wataame_post", 51, 78, { hit: [6, 6] });
  put("wataame_back", 0, 56, { by: 40 });
  put("wataame_roof", 0, 42);
  put("wataame_sign", 0, 22);
  // のぼり旗（左: 水色 / 右: ピンク）
  put("wataame_nobori_blue", -74, 78, { hit: [4, 4] });
  put("wataame_nobori_pink", 74, 78, { hit: [4, 4] });

  // カウンターの奥: 店主
  person("human_longhair_doing", 13, 56, {
    name: "わたあめやさん",
    lines: [
      "いらっしゃいませ！ わたあめのおみせへ ようこそ。",
      "このきかいに ざらめ（あらいおさとう）を いれると、あつくなってとけて、ほそーい いとになるんだよ。",
      "くるくるまわる きかいのまわりに できた いとを、わりばしで くるくる まきとっていくの。",
      "ふわふわの くもみたいに おおきくなると、うれしいなあ。ゆっくり みていってね！",
    ],
  });
  put("expression_love", 13, 36, { by: 90 });

  // カウンターと、その上: 左の台・わたあめ機・ざらめの瓶・右の台
  put("wataame_counter", 0, 80, { hit: [104, 10] });
  put("wataame_rack_a", -39, 67, { by: ON_COUNTER });
  put("wataame_machine", -10, 68, { by: ON_COUNTER + 1 });
  put("wataame_jar_a", 6, 66, { by: ON_COUNTER });
  put("wataame_jar_b", 17, 66, { by: ON_COUNTER });
  put("wataame_rack_b", 38, 67, { by: ON_COUNTER });
  // 星のきらめき（わたあめ機のまわり）
  put("wataame_sparkle", -29, 42, { by: 95, frame: 0 });
  put("wataame_sparkle", 7, 34, { by: 95, frame: 2 });
  put("wataame_sparkle", 52, 46, { by: 95, frame: 1 });
  put("wataame_sparkle", -50, 50, { by: 95, frame: 3 });

  // お客さん
  person("human_bowlhair_idle", 26, 102, { name: "おきゃくさん", lines: ["わあ、くもみたい！ ふわふわで あまいにおい。", "おおきいのを えらぼうかな。"] }, true);
  put("happiness_01", 26, 80, { by: 120 });
  person("human_spikeyhair_idle", -24, 112, { name: "こども", lines: ["ふくろのどうぶつ、かわいいね！", "くるくる まわるの、ずっと みていられるよ。"] });

  // 左: メニューの立て看板
  put("wataame_menu", -66, 128, { hit: [46, 6] });
  // 右: 袋入りわたあめの棚
  put("wataame_bagstand", 72, 127, { hit: [44, 6] });

  // 風船（ゆれる）
  put("wataame_balloon_a", -88, 96, { by: 101 });
  put("wataame_balloon_b", 88, 84, { by: 100, frame: 2 });
}
