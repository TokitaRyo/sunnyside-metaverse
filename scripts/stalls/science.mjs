/** 科学部（ロボット展示）。専用ドット絵は scripts/stalls/science.ps1（science_*.png）。奥の壁にモニターと歯車、真ん中の舞台に大きなロボット、左にロボットアーム、右に実験台、手前に小さなロボットと案内板 */
export const meta = { id: "science", label: "科学部（ロボット展示）", island: "浮島 9" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("science_sign", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("science_monitor", undefined, undefined, { frames: 6, fps: 6 });
  k.custom("science_gears", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("science_stage", undefined, undefined, { frames: 4, fps: 4 });
  k.custom("science_bigbot", undefined, undefined, { frames: 8, fps: 5 });
  k.custom("science_arm", undefined, undefined, { frames: 10, fps: 5 });
  k.custom("science_bench", undefined, undefined, { frames: 6, fps: 5 });
  k.custom("science_dog", undefined, undefined, { frames: 4, fps: 6 });
  k.custom("science_cleaner", undefined, undefined, { frames: 2, fps: 2 });
  k.custom("science_wheelbot", undefined, undefined, { frames: 4, fps: 3 });
  // 静止
  for (const n of ["floor", "wall", "table", "case", "panel"]) k.custom(`science_${n}`);
  k.custom("science_coat", 48, 32, undefined); // 人物(96x64)と同じ原点で重ねる白衣

  const { put, person, blocker } = k;

  // 白衣の部員（人物の上に白衣を重ねる）
  const staff = (sprite, dx, foot, npc, flip = false) => {
    const o = person(sprite, dx, foot, npc, flip);
    put("science_coat", dx, foot, { by: foot + 0.2, flip });
    return o;
  };

  // ---- 床・壁・看板
  put("science_floor", 0, 124, { sort: "floor" });
  put("science_wall", 0, 62, { hit: [172, 4] });
  put("science_sign", 0, 24, { by: 70 });
  put("science_monitor", 0, 50, { by: 63 });
  put("science_gears", -40, 44, { by: 63 });

  // ---- 真ん中: 舞台と大きなロボット
  put("science_stage", 0, 94, { sort: "floor", hit: [72, 22] });
  put("science_bigbot", 0, 79, { by: 80 });

  // ---- 左: ロボットアームの台
  put("science_table", -62, 88, { hit: [52, 12] });
  put("science_arm", -62, 70, { by: 89 });

  // ---- 右: 実験台と部員
  staff("human_shorthair_idle", 62, 76, {
    name: "かがくぶ",
    lines: [
      "いらっしゃい！ ここは かがくぶの ロボットてんじだよ。",
      "ロボットは、センサーで まわりを しらべて、コンピューターで かんがえて、モーターで うごくんだ。",
      "あっちの ロボットアームは、ブロックを つかんで はこぶ しくみを しょうかいしているよ。",
      "じっけんだいの フラスコも みていってね。ふしぎだな、とおもったら きいてみて。かがくは ぎもんから はじまるよ！",
    ],
  });
  put("expression_chat", 62, 56, { by: 95 });
  put("science_bench", 62, 90, { hit: [48, 12] });

  // ---- 手前: 部員・小さなロボット・お客さん
  staff("human_longhair_idle", -38, 104, {
    name: "かがくぶ",
    lines: [
      "ロボットアームは、ひとの うでと にているよ。かんせつを まげたり のばしたりして うごくんだ。",
      "こうじょうでも、ものを はこんだり ねじを しめたりするのに つかわれているんだって。",
      "ちいさな ロボットも、おなじ しくみで うごいているよ。みくらべてみてね！",
    ],
  });
  put("science_wheelbot", -50, 110, { by: 111 });
  put("science_cleaner", -22, 118, { by: 118 });

  person("human_mophair_idle", -10, 108, {
    name: "こども",
    lines: ["ロボット、てを ふってる！ すごーい！", "ぼくも おおきくなったら ロボットを つくりたいな。"],
  });
  put("science_dog", 10, 117, { by: 117, hit: [18, 5] });
  person("human_curlyhair_idle", 24, 106, {
    name: "おきゃくさん",
    lines: ["この しそくの ロボット、ほんとうの いぬみたいに あるくんだね。", "あしを うごかす じゅんばんが ポイントなんだって。"],
  }, true);

  // ---- 左前: ガラスの展示ケース、右前: 案内板
  put("science_case", -76, 124, { hit: [30, 6] });
  put("science_panel", 64, 128, { hit: [58, 6] });
}
