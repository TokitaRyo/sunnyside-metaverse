/** チョコバナナ屋。専用ドット絵は scripts/stalls/chocobanana.ps1（chocobanana_*.png） */
export const meta = { id: "chocobanana", label: "チョコバナナ屋", island: "浮島 20" };

export default function layout(k) {
  for (const n of ["back", "sign", "roof", "post", "counter", "rack_a", "rack_b", "pot", "jar_a", "jar_b", "crate", "tray", "menu", "mat"]) k.custom(`chocobanana_${n}`);
  k.custom("chocobanana_nobori_pink", 1, 82);
  k.custom("chocobanana_nobori_yellow", 1, 82);
  k.custom("chocobanana_balloon", 9, 46, { frames: 4, fps: 3 });
  k.custom("chocobanana_sparkle", 4.5, 4.5, { frames: 4, fps: 5 });
  const TABLE = k.cropAt(808, 586); // 四角い木のテーブル
  const STOOL = k.cropAt(805, 543); // 小さな丸椅子
  const POT_A = k.cropAt(825, 519); // ひまわりの鉢
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // ピンクのマット（床）。カウンターの前の「ここに立つ」場所
  put("chocobanana_mat", 0, 108, { sort: "floor" });

  // 柱・日よけ・看板
  put("chocobanana_post", -51, 78, { hit: [6, 6] });
  put("chocobanana_post", 51, 78, { hit: [6, 6] });
  put("chocobanana_back", 0, 56, { by: 40 });
  put("chocobanana_roof", 0, 42);
  put("chocobanana_sign", 0, 22);
  // のぼり旗（両脇、ピンクと黄色）
  put("chocobanana_nobori_pink", -74, 78, { hit: [4, 4] });
  put("chocobanana_nobori_yellow", 74, 78, { hit: [4, 4] });

  // カウンターの奥: 店主
  person("human_shorthair_doing", -10, 56, {
    name: "チョコバナナ屋さん",
    lines: [
      "いらっしゃい！ チョコバナナ、やっています！",
      "バナナにチョコをとろ〜りかけて、カラースプレーやアラザンでかざるよ。",
      "かざりつけは、ひとつずつ ていねいに。カラフルで、見ているだけでたのしいでしょ？",
      "きらきらでかわいいのが、じまんなんだ。ぜひ見ていってね！",
    ],
  });
  put("expression_love", -10, 36, { by: 90 });

  // カウンター（水玉の前板）と、その上のスタンド・チョコ鍋・スプレー瓶
  put("chocobanana_counter", 0, 80, { hit: [100, 10] });
  put("chocobanana_rack_a", -35, 66, { by: ON_COUNTER });
  put("chocobanana_rack_b", 35, 66, { by: ON_COUNTER });
  put("chocobanana_pot", 8, 66, { by: ON_COUNTER });
  put("chocobanana_jar_a", -14, 66, { by: ON_COUNTER });
  put("chocobanana_jar_b", -5, 66, { by: ON_COUNTER });
  // アラザンのキラキラ（バナナの上でまたたく）
  put("chocobanana_sparkle", -44, 44, { by: 95, frame: 0 });
  put("chocobanana_sparkle", -26, 47, { by: 95, frame: 2 });
  put("chocobanana_sparkle", 26, 46, { by: 95, frame: 1 });
  put("chocobanana_sparkle", 44, 43, { by: 95, frame: 3 });

  // 前のお客さん
  person("human_curlyhair_idle", 20, 100, { name: "おきゃくさん", lines: ["チョコバナナ、かわいい！", "カラースプレーがきらきらしてるね。"] }, true);
  put("happiness_01", 20, 76, { by: 120 });
  person("human_mophair_waiting", -40, 108, { name: "こども", lines: ["はやく食べたいなあ。","きらきらを いっぱいのせてほしいなあ。"] });

  // テーブル席: テーブルにトレイ、丸椅子
  put(TABLE, -66, 118, { hit: [18, 8] });
  put("chocobanana_tray", -66, 107, { by: 119 });
  put(STOOL, -88, 120, { hit: [8, 6] });
  put(STOOL, -46, 126, { hit: [8, 6] });

  // バナナの箱（カウンターの左はしの外）、メニュー（右手前）、ひまわり
  put("chocobanana_crate", -82, 100, { hit: [22, 6] });
  put("chocobanana_menu", 64, 128, { hit: [46, 6] });
  put(POT_A, 90, 108);

  // 風船（ゆれる）
  put("chocobanana_balloon", -85, 90, { by: 101 });
  put("chocobanana_balloon", 88, 80, { by: 100, frame: 2 });
}
