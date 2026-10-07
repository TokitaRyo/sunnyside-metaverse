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
      "上の列は、おばけやしき・カジノ・吹奏楽部・プログラミング部・科学部・図書委員会。",
      "まん中の列は、クラゲファクトリー・茶華道部・（ここ）・カフェ・射的・チョコバナナ。",
      "下の列は、たこ焼き・お好み焼き・油そば・たい焼き・わたあめ・ポテト。",
      "あちこち歩いて、スタンプも あつめてね！ 星のアイテムの前に行くと押されるよ。",
    ],
  });
  put("expression_chat", 0, 33, { by: 90 });

  // 休憩のテーブルと椅子、飾りの鉢
  put(TABLE, -52, 100, { hit: [18, 8] });
  put(STOOL, -76, 104, { hit: [8, 6] });
  put(STOOL, -30, 106, { hit: [8, 6] });
  put(POT_A, 64, 52);
  put(POT_B, -72, 40);
  put(POT_A, 76, 110);
  put(POT_B, 52, 118);
}
