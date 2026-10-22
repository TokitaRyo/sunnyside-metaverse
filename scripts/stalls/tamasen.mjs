/** たませんや（たません屋台）。専用ドット絵は scripts/stalls/tamasen.ps1（tamasen_*.png） */
export const meta = { id: "tamasen", label: "たませんや" };

export default function layout(k) {
  for (const n of ["tamasen_roof", "tamasen_post", "tamasen_floor", "tamasen_counter", "tamasen_pile", "tamasen_work", "tamasen_open", "tamasen_fold", "tamasen_wrap", "tamasen_sauce", "tamasen_eggs", "tamasen_tools", "tamasen_menu", "tamasen_mat"]) k.custom(n);
  k.custom("tamasen_nobori", 1, 78);
  k.custom("tamasen_sign", undefined, undefined, { frames: 2, fps: 2 }); // 電球がかわりばんこに光る看板
  k.custom("tamasen_lantern_a", undefined, undefined, { frames: 3, fps: 3 }); // ゆらぐ提灯
  k.custom("tamasen_griddle_a", undefined, undefined, { frames: 4, fps: 6 }); // ジュージュー焼ける丸い鉄板
  k.custom("tamasen_steam", 11, 28, { frames: 6, fps: 7 }); // 鉄板からゆらゆら上る湯気
  const SUNFLOWER = k.cropAt(825, 519); // ひまわりの鉢
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 床: 店の中は木の板、カウンターの前は「ここで買う」マット
  put("tamasen_floor", 0, 80, { sort: "floor" });
  put("tamasen_mat", -2, 112, { sort: "floor" });

  // 柱・日よけ・看板
  put("tamasen_post", -58, 78, { hit: [6, 6] });
  put("tamasen_post", 58, 78, { hit: [6, 6] });
  put("tamasen_roof", 0, 42, { by: 41 });
  put("tamasen_sign", 0, 22);
  // 提灯（日よけの下）
  put("tamasen_lantern_a", -66, 62, { by: 80 });
  put("tamasen_lantern_a", 66, 62, { by: 80, frame: 1 });
  // のぼり旗（両脇）
  put("tamasen_nobori", -90, 76, { hit: [4, 4] });
  put("tamasen_nobori", 82, 76, { hit: [4, 4] });

  // カウンターの奥: 丸い鉄板・湯気・店主
  put("tamasen_griddle_a", 36, 78, { by: 40 });
  put("tamasen_steam", 28, 50, { by: 70 });
  put("tamasen_steam", 46, 49, { by: 70, frame: 3 });
  person("human_shorthair_doing", 6, 56, {
    name: "たませんやさん",
    lines: [
      "いらっしゃい！ たません、やっています！",
      "まるい鉄板で、たまごを ジュージュー やくよ。",
      "やけたら、まるい えびせんべいで たまごを はさんで、ふたつに おるんだ。",
      "ソースを ぬって、かみに つつんで できあがり。あつあつを どうぞ！",
    ],
  }, true);
  put("expression_chat", 6, 33, { by: 90 });

  // カウンター（緑の前板）と、その上: 卵のカゴ・せんべいの山
  put("tamasen_counter", 0, 80, { hit: [116, 10] });
  put("tamasen_eggs", -46, 64, { by: ON_COUNTER });
  put("tamasen_pile", -24, 66, { by: ON_COUNTER });

  // 作業台（右手前）: せんべいに卵をのせて、ソースを塗り、はさんで二つ折りにする台。部員がもう1人
  put("tamasen_work", 62, 122, { hit: [56, 12] });
  person("human_bowlhair_doing", 66, 93, {
    name: "ぶいんさん",
    lines: [
      "ここは さぎょうだい。まるい せんべいに、やいた たまごを のせるよ。",
      "せんべいは われやすいから、そーっと ふたつに おるのが こつなんだ。",
      "かたちが きれいに できると、うれしいんだよ。",
    ],
  });
  put("tamasen_open", 41, 100, { by: 123 });
  put("tamasen_fold", 54, 99, { by: 123 });
  put("tamasen_sauce", 88, 106, { by: 123 });
  put("tamasen_wrap", 80, 99, { by: 123 });
  put("tamasen_tools", 68, 106, { by: 124 });

  // 前のお客さん
  person("human_longhair_idle", -14, 100, { name: "おきゃくさん", lines: ["たまごが ジュージュー やけるおと、いいにおい！", "せんべいが パリッとして、たまごが とろっとしているよ。"] }, false);
  put("happiness_01", -14, 76, { by: 120 });
  person("human_curlyhair_idle", 22, 106, { name: "おきゃくさん", lines: ["かみに つつんで くれるから、あるきながら たべられるんだ。", "はんぶんに おった かたちが かわいいよね！"] }, true);
  person("human_mophair_idle", 4, 124, { name: "こども", lines: ["たまごが やけるのを みてたら、おなか すいちゃった！", "せんべいを パリッと かじるの、すき！"] }, true);

  // メニューの黒板（左手前）と飾り
  put("tamasen_menu", -68, 128, { hit: [44, 6] });
  put(SUNFLOWER, 90, 128);
}
