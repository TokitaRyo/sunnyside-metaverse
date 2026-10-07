/** 吹奏楽部の演奏会場。専用ドット絵は scripts/stalls/suisougaku.ps1（suisougaku_*.png）。奥に3段の舞台と部員の半円、手前に指揮台・客席・受付 */
export const meta = { id: "suisougaku", label: "吹奏楽部" };

export default function layout(k) {
  // アニメ
  k.custom("suisougaku_sign", undefined, undefined, { frames: 6, fps: 5 });
  k.custom("suisougaku_baton", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("suisougaku_glint", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("suisougaku_notes", undefined, undefined, { frames: 4, fps: 2 });
  k.custom("suisougaku_nobori_a", 1, 56, { frames: 4, fps: 3 });
  k.custom("suisougaku_nobori_b", 1, 46, { frames: 4, fps: 3 });
  // 静止
  for (const n of ["backdrop", "risers", "floor", "trumpet", "trombone", "tuba", "horn", "sax", "clarinet", "flute", "snare", "bassdrum", "timpani", "cymbal", "stand", "podium", "chairback", "chairseat", "booth"]) k.custom(`suisougaku_${n}`);

  const { put, person } = k;
  const glint = (dx, foot, frame) => put("suisougaku_glint", dx, foot, { by: 130, frame });

  // ---- 床: 客席の床（赤い通路）→ 3段の舞台
  put("suisougaku_floor", 0, 128, { sort: "floor" });
  put("suisougaku_risers", 0, 94, { sort: "floor", by: 92, hit: [112, 5] }); // 舞台の前面。左右の角の階段(幅16)はあける

  // ---- 背景: 楽譜の幕・看板
  put("suisougaku_backdrop", 0, 50, { hit: [140, 3] });
  put("suisougaku_sign", 0, 18, { by: 20 });

  // ---- 奥の段（打楽器）: ティンパニ・チューバ・大太鼓・シンバル・スネア
  person("human_shorthair_idle", -52, 59, {
    name: "ティンパニ",
    lines: [
      "ティンパニは、ペダルで おとの たかさを かえられる たいこだよ。",
      "ゴロゴロという ひくい ひびきで、きょくを もりあげるんだ。",
    ],
  });
  put("suisougaku_timpani", -52, 70, { by: 71, hit: [28, 5] });
  glint(-60, 62, 0);

  person("human_bowlhair_idle", -26, 60, {
    name: "チューバ",
    lines: [
      "チューバは、いちばん おおきくて ひくい おとが でる がっき。",
      "バンド ぜんたいを、ふかい おとで ささえているんだよ。",
    ],
  });
  put("suisougaku_tuba", -17, 63, { by: 61 });
  glint(-5, 40, 2);

  person("human_curlyhair_idle", -4, 60, {
    name: "おおだいこ",
    lines: [
      "おおだいこは、ドーン！ と ふかく ひびく おとが でるよ。",
      "ばちで たたく ちからかげんが、とっても むずかしいんだ。",
    ],
  });
  put("suisougaku_bassdrum", 16, 69, { by: 70, hit: [24, 5] });
  put("suisougaku_cymbal", 40, 66, { by: 67, hit: [6, 4] });
  glint(34, 56, 1);

  person("human_mophair_idle", 58, 59, {
    name: "スネア",
    lines: [
      "スネアドラムは、ほそい はりがねが ついていて、シャッ！ という かわいた おとが でるよ。",
      "こまかい リズムを きざむのが とくい！",
    ],
  });
  put("suisougaku_snare", 58, 63, { by: 60 });

  // ---- 真ん中の段: ホルン・サックス・トランペット・トロンボーン
  person("human_longhair_idle", -52, 75, {
    name: "ホルン",
    lines: [
      "ホルンは、まるく まいた ながい くだの がっき。",
      "あたたかくて やわらかい おとが すてきでしょ？",
    ],
  });
  put("suisougaku_horn", -52, 77, { by: 76 });
  glint(-52, 73, 1);

  person("human_spikeyhair_idle", -26, 76, {
    name: "サックス",
    lines: [
      "サクソフォーンは きんぞくの からだだけど、じつは もっかんがっきの なかま！",
      "リードという うすい ぶひんを ふるわせて、おとを だすんだよ。",
    ],
  });
  put("suisougaku_sax", -32, 82, { by: 77, flip: true });
  glint(-38, 67, 3);

  person("human_shorthair_idle", 26, 76, {
    name: "トランペット",
    lines: [
      "トランペットは、きんいろに ひかる きんかんがっき。くちびるを ふるわせて おとを だすんだ。",
      "たかくて よく ひびく おとで、メロディーを はなやかに するよ。",
    ],
  });
  put("suisougaku_trumpet", 35, 70, { by: 77 });
  glint(43, 66, 0);

  person("human_curlyhair_idle", 52, 75, {
    name: "トロンボーン",
    lines: [
      "トロンボーンは、スライドを のばしたり ちぢめたりして、おとの たかさを かえるよ。",
      "ゆっくり うごかして、やさしい おとも だせるんだ。",
    ],
  });
  put("suisougaku_trombone", 66, 67, { by: 76 });
  glint(77, 64, 2);

  // ---- 手前の段: フルート・クラリネット
  person("human_bowlhair_idle", -50, 87, {
    name: "フルート",
    lines: [
      "フルートは ぎんいろだけど、もっかんがっきの なかまだよ。",
      "うたぐちに いきを ふきかけて、おとを だすんだ。",
    ],
  });
  put("suisougaku_flute", -59, 77, { by: 88, flip: true });
  person("human_mophair_idle", -26, 89, {
    name: "クラリネット",
    lines: [
      "クラリネットは、くろい もくせいの かんがっき。",
      "やさしい おとから すきとおった おとまで、いろいろ だせるよ。",
    ],
  });
  put("suisougaku_clarinet", -21, 95, { by: 90 });
  person("human_longhair_idle", 26, 89, {
    name: "クラリネット",
    lines: ["わたしも クラリネット！ きょうは みんなで おとを あわせて えんそうするよ。", "ききにきてくれて ありがとう！"],
  });
  put("suisougaku_clarinet", 31, 95, { by: 90 });
  person("human_shorthair_idle", 50, 87, {
    name: "フルート",
    lines: ["フルートは、ほかの がっきと くらべて、とても かるいんだ。", "ぎんいろの からだが ひかって きれいでしょ？"],
  });
  put("suisougaku_flute", 59, 77, { by: 88 });

  // ---- 譜面台（部員のあいだ）
  put("suisougaku_stand", -38, 90, { by: 91 });
  put("suisougaku_stand", 38, 90, { by: 91 });

  // ---- 指揮台と指揮者
  put("suisougaku_podium", 0, 102, { by: 96, hit: [18, 4] });
  person("human_mophair_idle", 0, 98, {
    name: "指揮者",
    lines: [
      "みなさん、ようこそ！ ぼくが しきしゃだよ。",
      "しきぼうを ふって、みんなの おとを ひとつに あわせるのが しごとなんだ。",
      "ぶいんたちの えんそうを、ゆっくり きいていってね。",
    ],
  });
  put("suisougaku_baton", 11, 91, { by: 99 });
  put("suisougaku_stand", -15, 101, { by: 102 });

  // ---- 浮かぶ音符
  put("suisougaku_notes", -36, 60, { by: 130 });
  put("suisougaku_notes", 38, 64, { by: 130, frame: 2 });

  // ---- 客席（パイプ椅子）
  const seat = (dx, foot, hair, npc, flip = false) => {
    put("suisougaku_chairback", dx, foot - 1, { by: foot - 1 });
    person(hair, dx, foot, npc, flip);
    put("suisougaku_chairseat", dx, foot + 1, { by: foot + 1 });
  };
  seat(-28, 113, "human_bowlhair_idle", { name: "おきゃくさん", lines: ["ここは さいしょの れつ！ えんそうが とっても ちかくで きこえるよ。", "ぶいんの みなさん、きらきらしてる！"] });
  seat(28, 113, "human_curlyhair_idle", { name: "おきゃくさん", lines: ["ラッパの おとが きんいろに ひかって みえるみたい。", "いちばん すきなのは、たいこの ひびきかな。"] }, true);
  seat(50, 113, "human_spikeyhair_idle", null, true);
  seat(66, 113, "human_longhair_idle", null, true);
  seat(-28, 126, "human_shorthair_idle", null);
  seat(30, 126, "human_longhair_idle", { name: "こども", lines: ["ぼくも おおきくなったら、ふくがっきを やってみたいな！", "ピカピカの がっきが かっこいいんだ。"] }, true);
  seat(52, 126, "human_mophair_idle", null, true);

  // ---- 受付（プログラムを配る）
  put("suisougaku_booth", -56, 128, { hit: [44, 8] });
  person("human_curlyhair_idle", -56, 110, {
    name: "うけつけ",
    lines: [
      "ようこそ！ ここは うけつけだよ。プログラムを くばっているよ。",
      "あかい じゅうたんの つうろを すすむと、ぶいんの ステージに つくよ。",
      "すきな せきに すわって、ゆっくり えんそうを たのしんでね。",
    ],
  });
  put("expression_chat", -56, 93, { by: 120 });

  // ---- のぼり旗（左右）
  put("suisougaku_nobori_a", -86, 124, { hit: [4, 4] });
  put("suisougaku_nobori_b", 86, 124, { hit: [4, 4] });
}
