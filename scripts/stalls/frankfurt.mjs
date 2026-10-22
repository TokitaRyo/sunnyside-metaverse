/** フランクフルト屋（串に刺した太いソーセージ）。青と白の屋台。専用ドット絵は scripts/stalls/frankfurt.ps1（frankfurt_*.png） */
export const meta = { id: "frankfurt", label: "フランクフルト屋" };

export default function layout(k) {
  for (const n of ["frankfurt_roof", "frankfurt_counter", "frankfurt_post", "frankfurt_trays", "frankfurt_menu", "frankfurt_mascot", "frankfurt_mat"]) k.custom(n);
  k.custom("frankfurt_nobori", 1, 96);
  k.custom("frankfurt_sign", undefined, undefined, { frames: 4, fps: 3 }); // ふちの電球がチカチカ点滅
  k.custom("frankfurt_grill", undefined, undefined, { frames: 6, fps: 6 }); // ローラーが回り、ソーセージの焼き色の帯が流れる
  k.custom("frankfurt_net", undefined, undefined, { frames: 3, fps: 4 }); // 網の下の炭火がゆらぐ
  k.custom("frankfurt_steam", undefined, undefined, { frames: 6, fps: 7 }); // ゆらゆら上る湯気
  k.custom("frankfurt_sauce", undefined, undefined, { frames: 9, fps: 3 }); // ソースの容器が動いて、ソーセージにぎざぎざの線を引く
  const { put, person } = k;
  const ON_COUNTER = 81; // カウンターの上に置く物は、カウンター(足元80)より手前に描く

  // 床のマット（カウンターの前の「ここで買う」場所）
  put("frankfurt_mat", 0, 110, { sort: "floor" });

  // 柱・日よけ・看板
  put("frankfurt_post", -58, 78, { hit: [6, 6] });
  put("frankfurt_post", 58, 78, { hit: [6, 6] });
  put("frankfurt_roof", 0, 30, { by: 41 });
  put("frankfurt_sign", 0, 12);
  // のぼり旗（両脇）
  put("frankfurt_nobori", -90, 76, { hit: [4, 4] });
  put("frankfurt_nobori", 80, 76, { hit: [4, 4] });

  // カウンターの上: ローラーロースター・ソース係・紙のトレイ
  put("frankfurt_grill", -30, 64, { by: ON_COUNTER });
  put("frankfurt_steam", -40, 28, { by: 90 });
  put("frankfurt_steam", -18, 28, { by: 90, frame: 3 });
  put("frankfurt_sauce", 14, 64, { by: ON_COUNTER });
  put("frankfurt_trays", 44, 64, { by: ON_COUNTER });

  // カウンターの奥: 部員2人
  person("human_shorthair_doing", 8, 56, {
    name: "フランクフルト屋さん",
    lines: [
      "いらっしゃい！ フランクフルト、やっています！",
      "ふといソーセージを串にさして、ころころ回しながら、じっくり焼くんだ。",
      "こんがり焼き色がついたら、できあがり。すきなソースで、ぎざぎざの線を引くよ。",
      "あつあつだから、ふーふーして食べてね！",
    ],
  }, true);
  put("expression_chat", 8, 33, { by: 90 });
  person("human_spikeyhair_doing", 40, 56, {
    name: "てんいんさん",
    lines: [
      "ローラーの上で、ソーセージがくるくる回っているでしょ？ まんべんなく焼けて、ぷりっとするんだ。",
      "できたら紙のトレイにのせて、はいどうぞ！ 串を持って、そのままかぶりついてね。",
    ],
  }, true);

  // カウンター（青い前掛け）
  put("frankfurt_counter", 0, 80, { hit: [104, 10] });

  // 右手前: 網焼きコンロ（串に刺したフランクフルト）と、焼き係
  put("frankfurt_net", 72, 114, { hit: [40, 10] });
  put("frankfurt_steam", 62, 80, { by: 120 });
  person("human_curlyhair_doing", 42, 101, {
    name: "あみ焼きさん",
    lines: [
      "網の上に、串に刺したフランクフルトを並べて焼いているよ。",
      "ときどきひっくり返して、きれいな焼き色をつけるのがコツ！",
      "けむりが出るから、あんまり近づきすぎないでね。",
    ],
  }, false);

  // 前のお客さん
  person("human_longhair_idle", -14, 98, { name: "おきゃくさん", lines: ["ここのフランクフルト、ぷりっとして おいしいんだよ。", "ソースで線を引いてもらうのが、たのしみなの！"] }, false);
  put("happiness_01", -14, 74, { by: 120 });
  person("human_bowlhair_idle", 14, 106, { name: "こども", lines: ["くるくる回ってるの、ずっと見ちゃう！", "串を持って、かぶりつくのが たのしいよね。"] }, true);
  person("human_mophair_idle", 2, 123, { name: "おきゃくさん", lines: ["あみ焼きの いいにおいに、つられて来ちゃった。", "紙のトレイにのせてくれるから、持ちやすいよ。"] }, false);

  // 左手前: メニューの立て看板。右手前: マスコット
  put("frankfurt_menu", -60, 127, { hit: [58, 6] });
  put("frankfurt_mascot", 36, 128, { hit: [16, 6] });
}
