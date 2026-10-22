/** 謎解き愛好会（謎解きの体験ブース）。専用ドット絵は scripts/stalls/nazotoki.ps1（nazotoki_*.png）。奥は青紫の壁（謎めいた扉・黒板・貼り紙）、まんなかに鍵の箱や砂時計を並べた長机、左に挑戦中のお客さんの丸テーブル、右に宝箱とヒントの立て看板 */
export const meta = { id: "nazotoki", label: "謎解き愛好会" };

export default function layout(k) {
  const P = "nazotoki_";
  // アニメ（横一列のシート）: 看板・扉・鍵の箱・砂時計・ランタン・明かり・？マーク・ひらめき・星
  k.custom(P + "sign", undefined, undefined, { frames: 4, fps: 4 });
  k.custom(P + "door", undefined, undefined, { frames: 4, fps: 3 });
  k.custom(P + "lockbox", undefined, undefined, { frames: 4, fps: 3 });
  k.custom(P + "hourglass", undefined, undefined, { frames: 8, fps: 2 });
  k.custom(P + "lantern", undefined, undefined, { frames: 4, fps: 4 });
  k.custom(P + "glow", undefined, undefined, { frames: 4, fps: 5 });
  k.custom(P + "qmark", undefined, undefined, { frames: 8, fps: 6 });
  k.custom(P + "idea", undefined, undefined, { frames: 4, fps: 4 });
  k.custom(P + "sparkle", undefined, undefined, { frames: 8, fps: 4 });
  // 静止
  for (const n of ["overlay", "rug", "wall", "board", "notice", "table", "padlock", "key", "envelope", "card", "magnifier", "hintbox", "glowfloor", "ptable", "trunk", "easel", "nobori"]) k.custom(P + n);
  // 人物(96x64)と同じ原点で重ねる帽子・メガネ
  for (const n of ["hat_fedora", "hat_beret", "hat_glasses"]) k.custom(P + n, 48, 32);

  const { put, person } = k;

  // 部員（人物の上に帽子などを重ねる）
  const staff = (sprite, hat, dx, foot, npc, flip = false) => {
    const o = person(sprite, dx, foot, npc, flip);
    put(P + hat, dx, foot, { by: foot + 0.2, flip });
    return o;
  };

  // ---- 床: 暗い覆い → 暗号のラグ
  put(P + "overlay", 0, 128, { sort: "floor", by: 0 });
  put(P + "rug", 0, 125, { sort: "floor", by: 1 });

  // ---- 奥の壁（通れない）・看板・のぼり
  put(P + "wall", 0, 58, { by: 50, hit: [176, 4] });
  put(P + "sign", 0, 20, { by: 75 });
  put(P + "nobori", -88, 70, { by: 71, hit: [4, 4] });
  put(P + "nobori", 88, 70, { by: 71, hit: [4, 4] });

  // ---- 壁の飾り: 謎めいた扉・黒板・貼り紙・ランタン
  put(P + "door", 0, 58, { by: 56 });
  put(P + "board", -57, 52, { by: 56 });
  put(P + "notice", 57, 52, { by: 56 });
  for (const dx of [-26, 26]) {
    put(P + "glowfloor", dx, 66, { sort: "floor", by: 2 });
    put(P + "lantern", dx, 52, { by: 60, frame: dx < 0 ? 0 : 2 });
    put(P + "glow", dx, 59, { by: 450, frame: dx < 0 ? 1 : 3 });
  }

  // ---- まんなか: 長机（通れない）と、机の上の品々
  put(P + "table", 0, 100, { hit: [104, 10] });
  put(P + "lockbox", -44, 80, { by: 101 });
  put(P + "padlock", -31, 81, { by: 101 });
  put(P + "key", -23, 83, { by: 101 });
  put(P + "envelope", -2, 83, { by: 101 });
  put(P + "hourglass", 13, 81, { by: 101 });
  put(P + "hintbox", 36, 82, { by: 101 });

  // 出題者（探偵の帽子）
  staff("human_shorthair_idle", "hat_fedora", -16, 69, {
    name: "しゅつだいがかり",
    lines: [
      "ようこそ！ ここは なぞときあいこうかいの ブースだよ。",
      "なぞを ときあかして みよう。しらべて、かんがえて、ひらめく。それが いちばん たのしいんだ。",
      "ヒントは まわりに かくれているよ。ふだや かべ、はこの まわりも よく みてみてね。",
      "ぜんぶ とけたときは、すっきり きもちいいよ。こまったら ヒントを つかって、もう いちど かんがえてみよう！",
    ],
  });
  put("expression_chat", -16, 50, { by: 110 });

  // ---- 右の奥: ヒント係
  staff("human_bowlhair_idle", "hat_beret", 64, 78, {
    name: "ヒントがかり",
    lines: [
      "ここは ヒントカードの おたすけコーナー。",
      "なやんだときに、カードで ちょっとだけ ヒントを おしえてあげるよ。",
      "ヒントを もらっても、さいごに ひらめくのは あなた。そうだんしながら とくのも おすすめだよ。",
    ],
  });
  put("expression_chat", 64, 59, { by: 110 });

  // ---- 手前: 案内役の部員（メガネ）
  staff("human_shorthair_idle", "hat_glasses", -34, 114, {
    name: "ぶいん",
    lines: [
      "くろいたの きごうは、ぜんぶ ここで つくった オリジナルだよ。",
      "あんごうは、ひとつ きまりを みつけると、するする ほどけていくんだ。",
      "かぎの かかった はこは、ひっぱっても あかないよ。まわりを よく さがしてみてね。",
      "むしめがねで ちいさな ところも よく みてみよう。",
    ],
  }, true);
  put("expression_chat", -34, 95, { by: 130 });

  // ---- 左前: 挑戦中のお客さんの丸テーブル（通れない）
  put(P + "ptable", -76, 124, { hit: [32, 8] });
  put(P + "card", -86, 108, { by: 125 });
  put(P + "magnifier", -67, 110, { by: 125 });
  // 考えこむ子と、ひらめく子（テーブルのうしろに立つ）
  person("human_mophair_idle", -84, 98, {
    name: "うーん",
    lines: [
      "うーん…… ぜんぜん わからないよう。",
      "でも、ヒントは まわりに かくれているんだよね。もういちど ぜんぶ みなおして みよう。",
      "ゆっくり かんがえるのも、なぞときの たのしさだよね。",
    ],
  });
  put(P + "qmark", -76, 82, { by: 140 });
  person("human_curlyhair_idle", -64, 98, {
    name: "ひらめいた！",
    lines: [
      "あっ！ そういうことか！ ひらめくと、あたまが ぱっと あかるく なるんだ。",
      "さっきまで ぜんぜん わからなかったのに、ふしぎだね。",
      "みんなで いっしょに かんがえると、ひらめきも ふえるよ！",
    ],
  }, true);
  put(P + "idea", -62, 82, { by: 140 });

  // ---- 右前: 鍵つきの宝箱と、ヒントの立て看板
  put(P + "trunk", 80, 108, { hit: [28, 6] });
  put(P + "easel", 52, 128, { hit: [24, 5] });
  person("human_spikeyhair_idle", 24, 116, {
    name: "さがすこ",
    lines: [
      "かべの はりがみ、よーく みると いろんな マークが あるよ。",
      "どれが ヒントかな？ ぜんぶ きになっちゃう！",
      "なぞときは、さがす ところから はじまるんだね。",
    ],
  });
  put("expression_chat", 24, 97, { by: 130 });

  // ---- ふわふわ浮かぶ？マークと、きらきらの星
  put(P + "qmark", -70, 10, { by: 140, frame: 2 });
  put(P + "qmark", 70, 6, { by: 140, frame: 6 });
  put(P + "sparkle", 0, 100, { by: 500 });
}
