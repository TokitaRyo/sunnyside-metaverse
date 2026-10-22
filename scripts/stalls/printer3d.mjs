/** 3Dプリンタ屋。専用ドット絵は scripts/stalls/printer3d.ps1（printer3d_*.png）。オレンジ・白・灰色のラボ風。奥に展示棚・大きな3Dプリンタ・フィラメントのスプール、左に作業台、右に売り台、真ん中に回る造形物 */
export const meta = { id: "printer3d", label: "3Dプリンタ屋" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("printer3d_sign", undefined, undefined, { frames: 6, fps: 4 });
  k.custom("printer3d_printer", undefined, undefined, { frames: 14, fps: 5 });
  k.custom("printer3d_mini", undefined, undefined, { frames: 10, fps: 4 });
  k.custom("printer3d_rack", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("printer3d_keys", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("printer3d_turntable", undefined, undefined, { frames: 8, fps: 6 });
  // 静止
  for (const n of ["floor", "wall", "ped", "shelf", "bench", "sales", "sales_tag", "poster_a", "poster_b", "nobori_a", "nobori_b", "bin", "pile"]) k.custom(`printer3d_${n}`);
  k.custom("printer3d_apron", 48, 32, undefined); // 人物(96x64)と同じ原点で重ねるエプロン

  const { put, person } = k;

  // オレンジのエプロンの部員
  const staff = (sprite, dx, foot, npc, flip = false) => {
    const o = person(sprite, dx, foot, npc, flip);
    put("printer3d_apron", dx, foot, { by: foot + 0.2, flip });
    return o;
  };

  // ---- 床・奥の壁・看板・のぼり
  put("printer3d_floor", 0, 128, { sort: "floor" });
  put("printer3d_wall", 0, 60, { by: 56, hit: [184, 4] });
  put("printer3d_sign", 0, 22, { by: 62 });
  put("printer3d_nobori_a", -87, 46, { by: 57 });
  put("printer3d_nobori_b", 87, 46, { by: 57 });

  // ---- 壁のポスター（設計図）
  put("printer3d_poster_a", -58, 37, { by: 58 });
  put("printer3d_poster_b", 58, 37, { by: 58 });

  // ---- 真ん中の奥: 大きな3Dプリンタ（台つき）
  put("printer3d_ped", 0, 90, { hit: [60, 10] });
  put("printer3d_printer", 0, 80, { by: 91, frame: 9 }); // 途中まで積み上がった所から始める

  // ---- 左の奥: 展示棚（できあがった作品）
  put("printer3d_shelf", -58, 90, { hit: [58, 8] });

  // ---- 右の奥: フィラメントのスプールかけ
  put("printer3d_rack", 58, 82, { by: 70 });

  // ---- 左: 作業台（削り出しの道具）と小さなプリンタ、部員
  put("printer3d_bench", -56, 128, { hit: [56, 12] });
  put("printer3d_mini", -42, 108, { by: 129, frame: 5 });
  staff("human_shorthair_doing", -70, 106, {
    name: "しあげ",
    lines: [
      "いらっしゃい！ ここは 3Dプリンタの おみせだよ。",
      "3Dプリンタは、とけた ざいりょうを すこしずつ つみかさねて、かたちに する きかいなんだ。",
      "できあがったら、ヘラで そっと はがして、やすりで ひょうめんを なめらかに するよ。",
      "てさぎょうで しあげると、もっと きれいに なるんだ。",
    ],
  });

  // ---- 右: 売り台とキーホルダー
  put("printer3d_sales", 55, 128, { hit: [56, 12] });
  put("printer3d_sales_tag", 55, 125, { by: 129.5 });
  put("printer3d_keys", 41, 108, { by: 129 });
  staff("human_bowlhair_idle", 62, 106, {
    name: "てんいん",
    lines: [
      "いらっしゃいませ！ ここに ならんでいるのは ぜんぶ 3Dプリンタで つくった ものだよ。",
      "どうぶつや ロボット、キーホルダー… ぶいんが デザインした オリジナルなんだ。",
      "キーホルダーは ゆらゆら ゆれて かわいいでしょ。きにいったら きいてね。",
    ],
  });

  // ---- 通路: プリンタの説明をする部員・回る造形物・お客さん
  staff("human_spikeyhair_idle", 22, 96, {
    name: "ぶいん",
    lines: [
      "この きかいが 3Dプリンタ。うえから みていてね、ノズルが ひだりみぎに うごいているでしょ？",
      "ノズルから とけた フィラメントが でて、したから すこしずつ つみあがっていくよ。",
      "うすい かみを かさねるみたいに、1そうずつ かたちが できるんだ。",
      "フィラメントは、ほそい ひものような ざいりょう。いろも いろいろ あるよ！",
    ],
  });
  put("expression_chat", 22, 76, { by: 130 });

  put("printer3d_turntable", 0, 114, { hit: [16, 5] });
  person("human_curlyhair_idle", -16, 124, {
    name: "おきゃくさん",
    lines: [
      "くるくる まわってる！ この ねこ、3Dプリンタで つくったんだって。",
      "つみかさねて できているなんて、ふしぎ！ よこから みると、しましまの せんが あるよ。",
    ],
  });
  person("human_mophair_idle", 16, 122, {
    name: "こども",
    lines: [
      "ノズルが ゆっくり うごいて、かたちが どんどん おおきく なる！ ずっと みていたいな。",
      "ぼくも デザインして つくってみたいな。",
    ],
  }, true);
  person("human_longhair_idle", -22, 104, {
    name: "おきゃくさん",
    lines: [
      "せっけいずの ポスター、りっぽうたいの せんが きれい。",
      "まず パソコンで かたちを つくって、それを うすく スライスして プリンタに おくるんだって。",
    ],
  });

  // ---- 手前の角: 失敗作の箱とスプールの山
  put("printer3d_bin", -90, 126, { hit: [14, 4] });
  put("printer3d_pile", 87, 127, { hit: [20, 5] });
}
