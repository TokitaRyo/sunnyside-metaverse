/** 数理科学愛好会。専用ドット絵は scripts/stalls/suuri.ps1（suuri_*.png）。黒板の看板とのぼり、奥の壁に数式の黒板・図形のポスター・ペナント。3つのコーナー: 左=スライム作り（ボウル・色の素のボトル・瓶入りスライム。手前に体験テーブル）、真ん中=布の染色教室（洗濯ばさみで干した染め布・染め桶・エプロンと手袋）、右=トポロジの展示（回るメビウスの輪・ドーナツ・クラインの壺・結び目。手前に「同じかたち」のパネル） */
export const meta = { id: "suuri", label: "数理科学愛好会" };

export default function layout(k) {
  // ---- アニメ（横一列のシート）
  k.custom("suuri_sparkle", undefined, undefined, { frames: 4, fps: 3 }); // 床のきらめき
  k.custom("suuri_sign", undefined, undefined, { frames: 6, fps: 5 }); // 看板（電球が走る・π と ∞ が光る）
  k.custom("suuri_slime_bowl", undefined, undefined, { frames: 6, fps: 5 }); // スライムのボウルと混ぜる棒
  k.custom("suuri_slime_shelf", undefined, undefined, { frames: 4, fps: 3 }); // 色の素のボトルと瓶のスライム（ラメ）
  k.custom("suuri_dye_line", undefined, undefined, { frames: 4, fps: 3 }); // 洗濯ばさみで干した染め布（ゆれる）
  k.custom("suuri_dye_tubs", undefined, undefined, { frames: 4, fps: 4 }); // 染め桶（染め液がゆれる）
  k.custom("suuri_panel", undefined, undefined, { frames: 8, fps: 4 }); // 「おなじ かたち」（カップがドーナツに変わる）
  k.custom("suuri_mobius", undefined, undefined, { frames: 8, fps: 5 }); // 回るメビウスの輪
  k.custom("suuri_torus", undefined, undefined, { frames: 4, fps: 4 }); // トーラス（ドーナツ。スプリンクルがまわる）
  k.custom("suuri_knot", undefined, undefined, { frames: 8, fps: 5 }); // 回る結び目
  // ---- 静止
  for (const n of ["floor", "wall", "bench_slime", "bench_dye", "bench_topo", "slime_table", "dye_goods", "klein", "nobori"]) k.custom(`suuri_${n}`);
  k.custom("suuri_apron", 48, 32); // 人物(96x64)と同じ原点で重ねるエプロン

  const { put, person, blocker } = k;
  const ON_BENCH = 85; // 作業台(足元84)の上の物は手前に描く

  // エプロンの部員（人物の上にエプロンを重ねる）
  const apron = (sprite, dx, foot, npc, flip = false) => {
    const o = person(sprite, dx, foot, npc, flip);
    put("suuri_apron", dx, foot, { by: foot + 0.2, flip });
    return o;
  };

  // ---- 床・奥の壁・看板・のぼり
  put("suuri_floor", 0, 128, { sort: "floor", by: 0 });
  put("suuri_sparkle", 0, 128, { sort: "floor", by: 2 });
  put("suuri_wall", 0, 60, { by: 10 });
  blocker(0, 58, 176, 4); // 壁ぎわ（作業台のすき間から奥へ入れないように）
  put("suuri_sign", 0, 22, { by: 70 });
  put("suuri_nobori", -91, 66, { by: 30 });
  put("suuri_nobori", 91, 66, { by: 30 });

  // ---- 奥の列: 作業台3つ（左から スライム作り / 布の染色教室 / トポロジの展示）
  put("suuri_bench_slime", -65, 84, { hit: [54, 24] });
  put("suuri_bench_dye", -10, 84, { hit: [50, 24] });
  put("suuri_bench_topo", 54, 84, { hit: [72, 24] });
  blocker(-95, 84, 6, 30); // 作業台の端から奥へ回り込めないように
  blocker(94, 84, 6, 30);

  // ---- スライム作り（左）
  put("suuri_slime_bowl", -81, 54, { by: ON_BENCH });
  put("suuri_slime_shelf", -45, 54, { by: ON_BENCH });
  person("human_spikeyhair_doing", -62, 50, {
    name: "すうりぶ",
    lines: [
      "ようこそ！ ここは スライムづくりの コーナーだよ。ボウルに はいった スライムを、ぼうで ぐるぐる まぜて つくるんだ。",
      "スライムは、まぜると ねばねばして、だんだん かたまってくるよ。ちからを いれすぎずに、ゆっくり まぜるのが コツなんだ。",
      "いろの もとの ボトルを ぽとんと たらすと、パステルカラーに そまっていくよ。ピンクや みずいろ、きいろも あるんだ。",
      "できた スライムは、ちいさな びんに いれて ならべてあるよ。ぷにぷにして、さわるだけでも たのしいよ。",
      "となりの ぬのの せんしょくきょうしつと、みぎの トポロジの てんじも、ぜひ みていってね！",
    ],
  });

  // ---- 布の染色教室（真ん中）: 壁に洗濯ばさみで干した染め布、台の上にエプロン・手袋・絞り染めの見本
  put("suuri_dye_line", -12, 56, { by: 40 });
  put("suuri_dye_goods", 0, 54, { by: ON_BENCH });
  apron("human_longhair_doing", -24, 50, {
    name: "すうりぶ",
    lines: [
      "いらっしゃいませ！ ここは ぬのの せんしょくきょうしつ。せんりょうを とかした そめえきに ぬのを つけて、いろを つけるよ。",
      "そめた ぬのは、せんたくばさみで ひもに つるして かわかすんだ。かぜに ゆれて きれいでしょ？ いろとりどりの ぬのが ならんでいるよ。",
      "そめるときは、てぶくろと エプロンを つけてね。せんりょうは ふくに つくと おちにくいから、ここに じゅんびして あるよ。",
      "うえの ぬのも、したの しぼりぞめの みほんも、ゆっくり みていってね。",
    ],
  });

  // ---- トポロジの展示（右）: 展示台にメビウスの輪・トーラス・クラインの壺・結び目
  put("suuri_mobius", 28, 54, { by: ON_BENCH, frame: 2 });
  put("suuri_torus", 46, 54, { by: ON_BENCH });
  put("suuri_klein", 62, 54, { by: ON_BENCH });
  put("suuri_knot", 78, 54, { by: ON_BENCH });

  // ---- 手前の列: スライムの体験テーブル（左）・染め桶（左寄り）・「おなじ かたち」のパネル（右）。真ん中（入口）は空ける
  put("suuri_slime_table", -78, 126, { hit: [32, 6] });
  put("suuri_dye_tubs", -42, 126, { hit: [36, 8] });
  put("suuri_panel", 38, 126, { hit: [76, 5] });

  apron("human_shorthair_doing", -52, 98, {
    name: "すうりぶ",
    lines: [
      "そめぬのの コツを おしえるね。ぬのを ぎゅっと しぼって、ゴムで しばってから そめると、もようが でるんだよ。これが しぼりぞめ。",
      "うずまきや まるもようなど、しばりかたで ちがう もようが できるの。そめおわって ひらくときが、いちばん ワクワクするよ。",
      "そめえきに つけたら、みずで あらって、ゆっくり かわかしてね。ぬれた ぬのは おもいから、きをつけて！",
    ],
  });
  apron("human_curlyhair_doing", -34, 98, {
    name: "おきゃくさん",
    lines: [
      "ぬのを そめるの、はじめて！ ぎゅっと しぼって そめると、もようが でるんだって。ひらくとき、ドキドキするよ。",
      "あおと ピンクで そめてみたの。かわいたら、せんたくばさみで つるして もらえるんだって。たのしみ！",
    ],
  });

  person("human_mophair_doing", -78, 106, {
    name: "こども",
    lines: [
      "スライム、ぷにぷにで たのしい！ いろの もとを たらして ぐるぐる まぜたら、ピンクに なったよ。",
      "もっと まぜてたら、だんだん かたく なってきたの。ふしぎだなあ。",
    ],
  });

  person("human_bowlhair_idle", 88, 122, {
    name: "すうりぶ",
    lines: [
      "ここは トポロジの てんじコーナーだよ。トポロジは、のばしたり ちぢめたり しても かわらない かたちを しらべる がくもん なんだ。",
      "「コーヒーカップと ドーナツは おなじ かたち」って きいたこと ある？ どちらも あなが ひとつ だけ だから、ねんどで ぐにゃっと かえていくと、おなじに なるんだよ。パネルの えを みてね。",
      "くるくる まわっているのは メビウスの わ。かみの おびを ひとひねりして つなぐと、うらと おもてが つながって、ひとつの めんに なるんだ。",
      "ドーナツの かたちは トーラス、びんの かたちは クラインの つぼ、ひもの かたちは むすびめ。ぜんぶ ならべて あるから、ゆっくり みていってね。",
    ],
  }, true);
  person("human_mophair_idle", 86, 96, {
    name: "おきゃくさん",
    lines: [
      "メビウスの わって ふしぎ！ ゆびで なぞっていくと、ずーっと おなじ みちが つづいていくんだって。",
      "ドーナツと コーヒーカップが おなじ かたちなんて、びっくりしたな。かたちって おもしろいね。",
    ],
  }, true);
  put("expression_chat", 86, 78, { by: 140 });
}
