import { CONSENT_VERSION, DATA_RETENTION_DAYS, OPERATOR_CONTACT, OPERATOR_EMAIL } from "@metaverse/shared";

/**
 * 利用規約・データの取り扱い（入室時に同意する文面）。
 * 文面を変えたら shared/constants.ts の CONSENT_VERSION を新しくする（全員がもう一度同意する）。
 * 学校行事向けのひな形なので、実際に使う前に、学校・主催者の確認を受けること。
 */
interface Section {
  h: string;
  p?: string[];
  ul?: string[];
}

const SECTIONS: Section[] = [
  {
    h: "1. このサービスについて",
    p: ["「AMPLIFIRE」は、文化祭の出店をオンラインで楽しむための、ブラウザで動く交流の場です。運営は、文化祭の運営係が行います。"],
  },
  {
    h: "2. 集める情報",
    ul: [
      "ニックネーム、えらんだ髪型",
      "チャットに書いた内容（日時・ニックネームつき）",
      "入室・退室の時刻、滞在した時間、どの出店のそばにどれくらい居たか、集めたスタンプの数、エモートの回数",
      "あなたのブラウザに保存する、ランダムな「訪問者ID」（同じ端末が再び来たことを数えるためのもの。名前などの個人は特定しません）",
      "端末の種類（パソコン か スマホ・タブレット）",
    ],
    p: [
      "集めないもの: 本名・住所・電話番号・メールアドレス・正確な位置情報・カメラやマイクの内容。IPアドレスは運営の記録には残しません（通信の仕組みとして、サーバーを預けている事業者の記録に一時的に残ることはありますが、運営はそれを利用しません）。",
      "📷 写真ボタンで撮った画像は、あなたの端末に保存されるだけで、運営には送られません。スタンプの記録・設定は、あなたのブラウザの中にだけ保存されます。",
    ],
  },
  {
    h: "3. 使う目的",
    ul: [
      "みんなが安全に楽しめるようにするため（いやがらせや不適切な書き込みの確認と対応）",
      "何人が参加したか、どの出店が人気だったかなどの集計（個人が特定されない形で見ます）",
      "今後の改善",
    ],
    p: ["この目的以外には使いません。集めた記録は、学校の中（運営係と、運営に関わる学校の関係者）だけで使う可能性があります。学校の外に公開したり、外部に渡したりしません。"],
  },
  {
    h: "4. 保存する期間",
    p: [`集めた記録は、最長で${DATA_RETENTION_DAYS}日間保存し、過ぎたものは自動で消します。運営の判断で、もっと早く消すこともあります。`],
  },
  {
    h: "5. 見られる人・外部への提供",
    ul: [
      "記録を見られるのは、運営の管理者だけです（パスワードで守っています）。",
      "集めた記録は、学内利用のみです。法令にもとづく場合を除き、学校の外の第三者には渡しません。",
      "サーバーは外部の事業者（Fly.io）のものを借りています。記録はそのサーバーに置かれます。",
    ],
  },
  {
    h: "5-2. チャットについて",
    p: ["チャットは、その場にいる参加者全員に見えます。本名・学校名・学年・クラス・電話番号・SNSのIDなど、個人が分かることは書かないでください。"],
  },
  {
    h: "6. 守ってほしいこと",
    ul: [
      "ほかの人を傷つける言葉、いやがらせ、なりすまし、おどしをしない。",
      "不適切な言葉は自動で ＊＊ に変わることがあります（完全ではありません）。",
      "ゲームを壊す・自動で操作するなどの不正をしない。",
      "守られない場合は、運営が退室や利用停止をすることがあります。",
    ],
  },
  {
    h: "7. 小さなお子さん・保護者の方へ",
    p: ["15歳未満の方は、保護者または先生の許可を得てから、同意してください。"],
  },
  {
    h: "8. 記録の確認・削除をお願いするとき",
    p: [`自分の記録の確認や削除を希望するときは、${OPERATOR_CONTACT}、またはメール（${OPERATOR_EMAIL}）に、下の「あなたの訪問者ID」を伝えてください。運営が確認して、対応します。`],
  },
  {
    h: "9. 問い合わせ先",
    p: [OPERATOR_CONTACT, `メール: ${OPERATOR_EMAIL}`],
  },
  {
    h: "10. 同意について",
    p: [
      "入室画面の「同意します」にチェックを入れる（またはこの画面の「同意する」を押す）と、この内容に同意したことになります。同意しない場合は、入室できません。",
      "同意をやめたいときは、ブラウザのタブを閉じて、8. の方法で削除を依頼してください。",
    ],
  },
  {
    h: "11. 素材・BGMのクレジット",
    p: [
      "BGM: ChillMindscapes「Free Chiptune Music Pack 4」（Creative Commons 表示 4.0 国際 / CC BY 4.0。配信のため、WAV を MP3 に変換して使用しています）。https://chillmindscapes.itch.io/free-chiptune-music-pack-4-chillmindscapes",
      "ドット絵素材: Sunnyside World Asset Pack（danieldiggle）。出店のドット絵・ロゴ: オリジナル。描画: Phaser、通信: Colyseus。この製品は MaxMind の GeoLite2 データを含みます（https://www.maxmind.com）。",
      "広場のキャラクター「ずんだもん」: 東北ずん子・ずんだもんプロジェクト（SSS合同会社）のキャラクターの、非営利の二次創作です（ドット絵は、この世界のためのオリジナル。公式の制作物ではありません）。ガイドライン: https://zunko.jp/guideline.html",
    ],
  },
];

/** 規約の本文を container に描く。visitorId は本人が削除を頼むときに見せる */
export function renderTerms(container: HTMLElement, visitorId: string): void {
  container.replaceChildren();
  for (const s of SECTIONS) {
    const h = document.createElement("h3");
    h.textContent = s.h;
    container.append(h);
    // 箇条書きを先に、そのあとに補足の文を出す
    if (s.ul) {
      const ul = document.createElement("ul");
      for (const t of s.ul) {
        const li = document.createElement("li");
        li.textContent = t;
        ul.append(li);
      }
      container.append(ul);
    }
    for (const t of s.p ?? []) {
      const p = document.createElement("p");
      p.textContent = t;
      container.append(p);
    }
  }
  const idBox = document.createElement("p");
  idBox.className = "terms-id";
  idBox.textContent = `あなたの訪問者ID: ${visitorId}`;
  const ver = document.createElement("p");
  ver.className = "terms-ver";
  ver.textContent = `この規約の版: ${CONSENT_VERSION}`;
  container.append(idBox, ver);
}
