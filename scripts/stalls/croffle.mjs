/** くろっふる屋。専用ドット絵は scripts/stalls/croffle.ps1（croffle_*.png） */
export const meta = { id: "croffle", label: "くろっふる屋" };

export default function layout(k) {
  for (const n of ["croffle_wall", "croffle_floor", "croffle_awning", "croffle_post", "croffle_counter", "croffle_tray", "croffle_bag", "croffle_rest", "croffle_jars", "croffle_menu", "croffle_rug"]) k.custom(n);
  k.custom("croffle_sign", undefined, undefined, { frames: 2, fps: 2 });
  k.custom("croffle_nobori", 1, 78);
  k.custom("croffle_iron", undefined, undefined, { frames: 6, fps: 2 });
  k.custom("croffle_steam", undefined, undefined, { frames: 6, fps: 6 });
  k.custom("croffle_sparkle", undefined, undefined, { frames: 4, fps: 4 });
  const TABLE = k.cropAt(808, 586); // 四角い木のテーブル
  const STOOL = k.cropAt(805, 543); // 小さな丸椅子
  const DAISY_A = k.cropAt(857, 520); // ひなぎくの鉢
  const DAISY_B = k.cropAt(872, 518);
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 床: お店の中のタイルと、カウンターの前の敷物
  put("croffle_floor", 0, 58, { sort: "floor" });
  put("croffle_rug", 0, 108, { sort: "floor" });

  // 奥の壁・柱・日よけ・看板
  put("croffle_wall", 0, 58, { by: 50 });
  put("croffle_post", -60, 78, { hit: [6, 6] });
  put("croffle_post", 60, 78, { hit: [6, 6] });
  put("croffle_awning", 0, 42, { by: 62 });
  put("croffle_sign", 0, 22, { by: 62 });
  // のぼり旗（両脇）
  put("croffle_nobori", -80, 76, { hit: [4, 4] });
  put("croffle_nobori", 80, 76, { hit: [4, 4] });

  // 部員（カウンターの奥）
  person("human_longhair_doing", -41, 56, {
    name: "ぶいん",
    lines: [
      "いらっしゃいませ！ くろっふるの おみせへ ようこそ。",
      "クロッフルは、クロワッサンの生地を、ワッフルの型でぎゅっと焼いたお菓子だよ。",
      "さくさくで、バターのいい香り。そして、ようく見ると 格子もようが かわいいでしょ？",
    ],
  });
  person("human_shorthair_doing", -10, 56, {
    name: "ぶいん",
    lines: [
      "ここは、生地を休ませておく場所。しばらく置いておくと、焼いたときにさくさくになるんだよ。",
      "仕上げに粉砂糖をふったり、好きなものをのせたり。自分らしい一皿に なるんだ。",
    ],
  });
  person("human_bowlhair_doing", 11, 56, {
    name: "ぶちょう",
    lines: [
      "うちの焼き機は、パカッと上下に開く型でね。生地をはさんで、じっくり焼くんだ。",
      "ふたを開けたら、ほかほかの湯気と、こんがりした焼き色が出ているよ。",
      "格子もようのおかげで、外はさくさく、中はふんわり。どうぞ ゆっくり あじわってね！",
    ],
  });
  put("expression_chat", -41, 33, { by: 90 });

  // カウンターと、その上: 休ませる生地のトレー・トッピングの容器・ワッフル焼き機（湯気つき）
  put("croffle_counter", 0, 80, { hit: [108, 10] });
  put("croffle_rest", -41, 65, { by: ON_COUNTER });
  put("croffle_jars", -10, 65, { by: ON_COUNTER });
  put("croffle_iron", 36, 66, { by: ON_COUNTER });
  put("croffle_steam", 36, 34, { by: ON_COUNTER + 1 });
  put("croffle_steam", 28, 37, { by: ON_COUNTER + 1, frame: 3 });

  // 前のお客さん
  person("human_curlyhair_idle", 24, 98, { name: "おきゃくさん", lines: ["ここのくろっふる、さくさくで おいしそう！", "こうしもようが かわいくて、写真に とりたくなるなあ。"] }, true);
  put("happiness_01", 24, 74, { by: 120 });
  person("human_mophair_idle", -28, 104, { name: "こども", lines: ["はやく食べたいなあ！", "あつあつを、ふーふーして食べるんだ。"] });

  // テーブル席: 焼きたてを紙のトレーに、紙袋、おちゃ
  put(TABLE, -66, 118, { hit: [18, 8] });
  put("croffle_tray", -68, 106, { by: 119 });
  put("spr_deco_mug_01", -57, 106, { by: 119 });
  put("croffle_sparkle", -70, 93, { by: 130 });
  put("croffle_bag", -88, 117, { by: 125 });
  put(STOOL, -88, 121, { hit: [8, 6] });
  person("human_spikeyhair_idle", -45, 124, { name: "おきゃくさん", lines: ["やきたては、かわが さくっとして、中は ふんわり。", "粉砂糖が ふわっと とけるのが、すきなんだ。"] }, true);

  // メニュー（右手前の黒板）と飾り
  put("croffle_menu", 68, 128, { hit: [46, 6] });
  put(DAISY_A, 90, 70);
  put(DAISY_B, -92, 90);
}
