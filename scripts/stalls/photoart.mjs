/** 写真美術部。専用ドット絵は scripts/stalls/photoart.ps1（photoart_*.png）。奥の壁に額縁の絵4枚とスポットライトと看板、左にイーゼルと絵を描く部員とパレット、右に三脚つきカメラと撮影する部員と花瓶の台座とスポットライト、真ん中にポラロイドを吊るしたワイヤーと赤いカーペット */
export const meta = { id: "photoart", label: "写真美術部" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("photoart_sign", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("photoart_glow", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("photoart_tripod", undefined, undefined, { frames: 8, fps: 3 });
  k.custom("photoart_spot_glow", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("photoart_hang", undefined, undefined, { frames: 4, fps: 2 });
  // 静止
  for (const n of ["floor", "wall", "easel", "pedestal", "lamp", "palette", "frames"]) k.custom(`photoart_${n}`);

  const { put, person, blocker } = k;

  // ---- 床（カーペットが入口から奥へ）・奥の壁・看板・壁の光
  put("photoart_floor", 0, 128, { sort: "floor" });
  put("photoart_wall", 0, 68, { by: 66, hit: [176, 4] });
  put("photoart_sign", 0, 20, { by: 70 });
  put("photoart_glow", 0, 61, { by: 400 });

  // ---- 真ん中: ポラロイドを吊るしたワイヤー（両端の柱だけ通れない。まん中は歩ける）
  put("photoart_hang", 0, 92, { by: 92 });
  blocker(-48, 92, 8, 4);
  blocker(48, 92, 8, 4);

  // ---- 左: イーゼルと絵を描く部員、パレット台、立てかけた額縁
  put("photoart_easel", -80, 100, { hit: [20, 5] });
  person("human_longhair_doing", -58, 100, {
    name: "びじゅつぶ",
    lines: [
      "いらっしゃい！ ここは しゃしんびじゅつぶの てんじスペースだよ。",
      "わたしは いま、けしきの えを かいているところ。ひだりがわは もう ぬれたけど、みぎがわは まだ えんぴつの したがきなんだ。",
      "えのぐは まぜると いろが かわるよ。あおと きいろで みどりに なるの、おもしろいよね。",
      "おくの かべの えは、ぶいんが ひとりずつ かいたんだよ。すきな えを みつけてね。",
    ],
  }, true);
  put("photoart_palette", -84, 124, { hit: [20, 5] });
  put("photoart_frames", -54, 126, { hit: [24, 5] });

  // ---- 右: 三脚つきカメラと撮影する部員、花瓶の台座、スポットライト
  person("human_shorthair_doing", 24, 124, {
    name: "しゃしんぶ",
    lines: [
      "いらっしゃい！ しゃしんびじゅつぶの しゃしんがかりだよ。",
      "しゃしんは、ひかりを かんがえて とるのが こつなんだ。ライトの あたりかたで、おなじ おはなも ちがって みえるよ。",
      "あそこの ワイヤーに ぶらさがっているのは、ぶいんが とった ポラロイドふうの しゃしん。ひとつずつ みていってね。",
      "ひかった？ それは フラッシュだよ。びっくりさせて ごめんね！",
    ],
  });
  put("photoart_tripod", 42, 124, { hit: [10, 4] });
  put("photoart_pedestal", 66, 106, { hit: [14, 5] });
  put("photoart_lamp", 84, 122, { hit: [10, 4] });
  put("photoart_spot_glow", 60, 90, { by: 400 });

  // ---- 見学のお客さん（まん中の通路と入口は空ける）
  person("human_mophair_idle", -28, 114, {
    name: "おきゃくさん",
    lines: [
      "わあ、かべの えが きらきら ひかって みえる。",
      "こっちの よるの まちの えが すきだな。まどの あかりが ひとつずつ かいてあるよ。",
    ],
  });
  put("expression_love", -28, 94, { by: 130 });
  person("human_curlyhair_idle", 60, 128, {
    name: "おきゃくさん",
    lines: [
      "ポラロイドの しゃしん、ゆらゆら ゆれて かわいい。",
      "ぼくも しゃしんぶに はいって、カメラを つかってみたいな。",
    ],
  }, true);
  put("expression_chat", 60, 108, { by: 130 });
}
