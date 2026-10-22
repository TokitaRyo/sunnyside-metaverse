/** 電子回路基板屋。専用ドット絵は scripts/stalls/circuit.ps1（circuit_*.png）。緑の基板がずらっと並ぶ陳列棚、LEDが点滅する基板、はんだごて台と煙、部品トレイ、ブレッドボード、オシロスコープ、回路図のポスター */
export const meta = { id: "circuit", label: "電子回路基板屋" };

export default function layout(k) {
  // アニメ（横一列のシート）
  k.custom("circuit_sign", undefined, undefined, { frames: 6, fps: 4 });
  k.custom("circuit_shelf", undefined, undefined, { frames: 4, fps: 3 });
  k.custom("circuit_scope", undefined, undefined, { frames: 8, fps: 8 });
  k.custom("circuit_solder", undefined, undefined, { frames: 8, fps: 6 });
  k.custom("circuit_ledboard", undefined, undefined, { frames: 8, fps: 6 });
  k.custom("circuit_breadboard", undefined, undefined, { frames: 4, fps: 3 });
  // 静止
  for (const n of ["floor", "wall", "bench", "display", "tray_a", "tray_b", "schem", "poster_code", "spool", "stack", "lamp", "wire"]) k.custom(`circuit_${n}`);
  k.custom("circuit_nobori", 1, 80);
  k.custom("circuit_goggles", 48, 32); // 人物(96x64)と同じ原点で重ねる保護メガネ

  const { put, person } = k;
  const ON = 90; // 作業台の上に置く物は、台(足元88)より手前に描く

  // 保護メガネをかけた部員（人物の上にメガネを重ねる）
  const staff = (sprite, dx, foot, npc, flip = false) => {
    const o = person(sprite, dx, foot, npc, flip);
    put("circuit_goggles", dx, foot, { by: foot + 0.2, flip });
    return o;
  };

  // ---- 床・奥の壁・看板・のぼり
  put("circuit_floor", 0, 128, { sort: "floor" });
  put("circuit_wall", 0, 50, { by: 48, hit: [184, 6] });
  put("circuit_sign", 0, 24, { by: 60 });
  put("circuit_nobori", -94, 62, { by: 62, hit: [4, 4] });
  put("circuit_nobori", 80, 62, { by: 62, hit: [4, 4] });

  // ---- 壁の飾り: 回路図のポスターと、カラーコード表
  put("circuit_schem", -62, 49, { by: 51 });
  put("circuit_poster_code", 64, 49, { by: 51 });

  // ---- 奥の中央: 基板の陳列棚
  put("circuit_shelf", 0, 66, { by: 67, hit: [90, 8] });

  // ---- 左の作業台: オシロスコープとはんだごて台
  put("circuit_bench", -55, 88, { hit: [70, 14] });
  put("circuit_scope", -80, 78, { by: ON });
  staff("human_shorthair_idle", -56, 75, {
    name: "ぶいん",
    lines: [
      "いらっしゃい！ ここは でんしかいろの おみせだよ。きばんって しってる？",
      "きばんの うえには、ぶひんが ならんでいて、ぎんいろの はんだで くっつけてあるんだ。",
      "みどりの いろは、きばんを まもる ぬりぐすりの いろだよ。きんいろの まるは、ぶひんを つなぐ ところなんだ。",
    ],
  });
  put("circuit_solder", -33, 80, { by: ON });

  // ---- 右の作業台: LED基板とルーペ
  put("circuit_bench", 55, 88, { hit: [70, 14] });
  put("circuit_ledboard", 36, 79, { by: ON, frame: 2 });
  staff("human_longhair_idle", 60, 75, {
    name: "ぶいん",
    lines: [
      "この LEDきばんを みてみて。じゅんばんに ひかっているでしょ？ きばんの うえで でんきが ながれているからなんだ。",
      "でんきは、きんいろの ところや せんの なかを とおって、ぶひんから ぶひんへ はこばれるよ。",
      "ていこうは、でんきが ながれすぎないように ちょうせつする ぶひん。LEDを まもっているんだ。",
    ],
  });
  put("circuit_lamp", 72, 79, { by: ON + 1 });
  put("circuit_stack", 84, 80, { by: ON + 1 });

  // ---- 手前の展示テーブル（左）: ブレッドボードと部品トレイ
  put("circuit_display", -57, 124, { hit: [70, 12] });
  put("circuit_breadboard", -77, 114, { by: 126, frame: 1 });
  person("human_mophair_idle", -53, 110, {
    name: "こども",
    lines: [
      "きばんが いっぱい ならんでる！ みどりいろで きれいだね。",
      "ちいさな ぶひんが ついてるよ。ひとつずつ やくわりが あるのかな？",
    ],
  });
  put("circuit_tray_b", -32, 115, { by: 126 });

  // ---- 手前の展示テーブル（右）: 基板の山と部品トレイ
  put("circuit_display", 57, 124, { hit: [70, 12] });
  put("circuit_stack", 28, 115, { by: 126 });
  put("circuit_spool", 40, 115, { by: 126 });
  person("human_curlyhair_idle", 58, 110, {
    name: "おきゃくさん",
    lines: [
      "LEDが じゅんばんに ひかってる！ どうして ひかるのか ふしぎだな。",
      "ていこうの しましまの いろは、すうじを あらわしているんだって。",
    ],
  }, true);
  put("circuit_tray_a", 79, 115, { by: 126 });

  // ---- 通路: 部員とお客さん
  staff("human_spikeyhair_idle", 12, 104, {
    name: "ぶいん",
    lines: [
      "オシロスコープの がめんを みてみて。でんきの ようすが なみの かたちで うごいているよ。",
      "ブレッドボードは、はんだを つかわずに ぶひんを さして、かいろを ためせる ボードなんだ。",
      "かいろずも かいてみてね。きごうを ならべると、でんきの ながれが わかるよ！",
    ],
  });
  put("expression_chat", 12, 82, { by: 130 });
  person("human_bowlhair_idle", -8, 96, {
    name: "おきゃくさん",
    lines: [
      "スマホや ゲームきの なかにも、きばんが はいっているんだね。",
      "ぼくも じぶんで きばんを つくってみたいな。",
    ],
  });
  put("circuit_wire", -36, 101, { sort: "floor" });
  put("circuit_wire", 50, 100, { sort: "floor" });
}
