/** 広場（スポーン地点）。案内係のNPCと、花の鉢・ベンチだけの、何もない休憩の場所 */
export const meta = { id: "plaza", label: "広場" };
/** ここをスポーン地点にする（草地の区画の中心からのずれ dx、上端からの足元 foot） */
export const spawn = { dx: 0, foot: 84 };

export default function layout(k) {
  const POT_A = k.cropAt(825, 519); // ひまわりの鉢
  const POT_B = k.cropAt(841, 519);
  const TABLE = k.cropAt(808, 586); // 四角い木のテーブル
  const STOOL = k.cropAt(805, 543); // 小さな丸椅子
  const { put, person } = k;

  // 案内係
  person("human_curlyhair_idle", 0, 56, {
    name: "あんない",
    lines: [
      "ようこそ！ ここは文化祭の広場。まわりに、たくさんの出店があるよ。",
      "いちばん上の列は、おばけやしき・カジノ・吹奏楽・筝曲部・DTM部・プログラミング部・科学部・図書委員会。",
      "2列めは、くらげファクトリー・茶華道部・写真美術部・数理科学愛好会・謎解き愛好会・アマチュア無線部・同人誌。",
      "まん中の列は、バレーボール部・射的・アントレ同好会・（ここ）・電子回路基板屋・3Dプリンタ屋・カフェ。",
      "3列めは、たこ焼き・お好み焼き・油そば・たい焼き・大判焼き・わたあめ・ポテト。",
      "いちばん下の列は、チョコバナナ・串焼き・ホットドッグ・フランクフルト・くろっふる・たません・キラキラドリンク。",
      "あちこち歩いて、スタンプも あつめてね！ 星のアイテムの前に行くと押されるよ。",
    ],
  });
  put("expression_chat", 0, 33, { by: 90 });

  // 休憩のテーブルと椅子、飾りの鉢
  put(TABLE, -52, 100, { hit: [18, 8] });
  put(STOOL, -76, 104, { hit: [8, 6] });
  put(STOOL, -30, 106, { hit: [8, 6] });
  put(POT_A, -84, 66);
  put(POT_B, -72, 40);
  put(POT_A, -84, 122);
  put(POT_B, 14, 122);

  // 右前〜右奥: ずんだもんのコーナー（ずんだ餅のお皿・枝豆のかご・立て札。非商用のファンアート風。絵は plaza.ps1 の plaza_*.png）
  for (const n of ["plaza_mochi", "plaza_basket", "plaza_table", "plaza_sign"]) k.custom(n);
  k.custom("plaza_zunda", undefined, undefined, { frames: 6, fps: 6 }); // 軽くはずみ、枝豆の耳がぴょこぴょこ動く
  put("plaza_sign", 62, 66, { hit: [52, 6] });
  const z = put("plaza_zunda", 24, 92, {
    hit: [14, 8],
    npc: {
      name: "ずんだもん",
      lines: [
        "ボクは ずんだもんなのだ！ ずんだ餅の よう精なのだ。きょうは みんなと 文化祭を たのしむのだ！",
        "ずんだ餅は、えだ豆を すりつぶして つくる、東北の おもちなのだ。あまくて ほっこりするのだ。",
        "このえだ豆の みみは、ボクの じまんなのだ！ …でも ときどき スルーされちゃうのだ。ざんねんなのだ…。",
        "島の お店を ぜんぶ まわって、スタンプを あつめるのだ！",
        "ボクも おうえん するのだ！ みんな、たのしんでいくのだ！",
      ],
    },
  });
  k.map.objects.push({ sprite: "spr_deco_charactershadow", x: z.x, y: z.by - 1, sort: "floor", by: z.by + 7 });
  put("expression_chat", 24, 50, { by: 100 });
  put("plaza_table", 64, 118, { hit: [54, 22] });
  put("plaza_mochi", 51, 100, { by: 119 });
  put("plaza_basket", 79, 100, { by: 120 });
}
