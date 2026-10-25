/**
 * 検査の誤検出の確認（サーバーを起動しなくてよい）。ふつうの子どもの会話・名前が止まらず、連絡先・URL の例は止まることを確かめる。
 * 文を足したいときは、ここの ok / bad に足す。
 */
import { hasContact, norm, vetName } from "../server/src/moderation";
const ok = [
  "こんにちは！", "ありがとう", "たこやき おいしいね", "ライン川は きれいだね", "オンラインゲームが すき", "インスタントラーメン たべたい",
  "10じに あつまろう", "100円で かえるかな", "ここ どこかな？", "いっしょに あそぼう", "スタンプ あつめたよ", "おしえて くれて ありがとう",
  "はげましてくれて ありがとう", "かすてら おいしい", "ひとが おおいね", "きれいな ひかり", "わたあめ たべた", "ずんだもん かわいい", "それ いいね！",
  "nice to meet you", "online is fun", "timeline みた", "idea だね", "かわいい ねこ", "あした がっこう やすみ", "1000000 かい あそんだ", "しんかんせんに のった",
];
const bad = ["LINE交換しよう", "らいん おしえて", "instagram やってる？ id おしえて", "090-1234-5678", "http://a.b", "a@b.com", "www.example.jp", "@tarou_123", "ディスコードの ID 教えて"];
let fail = 0;
for (const s of ok) if (hasContact(s)) { console.log("FALSE POSITIVE:", s); fail++; }
for (const s of bad) if (!hasContact(s)) { console.log("MISSED:", s); fail++; }
for (const n of ["たろう", "ゆうき", "Nana", "かすみ", "はげます", "バドミントン部", "badminton", "ずんだもん", "ふうた"]) {
  const v = vetName(n, "seed", 12);
  if (v.replaced) { console.log("NAME FALSE POSITIVE:", n); fail++; }
}
console.log(fail ? `${fail} 件の問題` : `すべて期待どおり（普通の文 ${ok.length} 件は通り、連絡先の例 ${bad.length} 件は止まる）`, norm("し・ね"));
process.exit(fail ? 1 : 0);
