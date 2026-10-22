# 出店を1つ追加するときの共通の指示（エージェントに頼むときに読ませる）

文化祭の出店を1つ追加する。1つの出店は `scripts/stalls/<id>.ps1`（オリジナルのドット絵を描く）と `scripts/stalls/<id>.mjs`（配置）の組。
先に **scripts/stalls/README.md を読む**（道具・落とし穴・守ること）。手本は、同じ種類の既存の出店（下の「手本」）。共有ライブラリは `scripts/lib/pixel.ps1`・`scripts/lib/stall-kit.mjs`。

## 作るもの（この2ファイルと、そこから出る PNG だけ）
- `scripts/stalls/<id>.ps1` → `client/public/brand/stall/<id>_*.png`（ファイル名は必ず `<id>_` で始める）。日本語を含むので **UTF-8 BOM 付き**で保存。リポジトリのルートで実行。名前の正規表現で一部だけ作り直せるように（環境変数 `<ID大文字>_ONLY` など）しておく。
- `scripts/stalls/<id>.mjs`: `export const meta = { id: "<id>", label: "<出店名>" }` と `export default function layout(k)`。meta に island は書かない。

## 品質の目安（他の出店と同じ密度で）
- 看板（出店名。太字・大きく読める。光る・点滅などのアニメがあるとよい）、のぼり、屋台やカウンター、商品・展示物の絵、小物、地面や壁の絵。
- アニメ（湯気・光・回る・揺れる・点滅など）を、無理のない範囲で付ける。
- 部員（店員）のNPC 2〜4人と、お客さんNPC 2〜3人（話しかけられる。`npc: { name?, lines[] }`。話はひらがな多めで、その出店の紹介・遊び方・作り方を一般的に。**値段・時間・場所・実在の作品名・ブランド名は書かない**。ただし、下の「出店の内容」に運営の説明として書かれた事実は、そのまま使ってよい）。人物は `*_idle` か `*_doing`。`*_waiting` と `*_carry` は使わない。
- 絵は**全部オリジナルのドット絵**（素材パックの絵を写さない）。実在のキャラクター・商標・ロゴは描かない。
- 区画は 192×128px に収める（看板・のぼりが上に少しはみ出すのは可）。入口と客の歩く所は空け、通れない物には `hit`（形のある大きな物は `k.blocker`）。
- 小さい文字は MS Gothic の太字、11px 未満は読みにくいので注意。台の上の物は `by` を台より大きく。

## 確認
`node scripts/preview-stall.mjs <id> --scale=4 --hit` で `reference/stall-previews/<id>.png` を作り、**Read で画像を見て**、はみ出し・重なり・読めない文字・通路の塞ぎを直す（プレビューはアニメの1コマ目だけ）。

## 触ってはいけないもの
`map.json`、`scripts/build-stalls.mjs`、`scripts/lib/*`、`client/src`、`server`、`shared`、`docs`、他の出店のファイル、git（commit/push しない）。開発サーバーは起動しない。島への組み立て（build-stalls / rebuild-festival）は実行しない（こちらで行う）。

## 報告（日本語で簡潔に）
作ったファイル、各素材の内容、配置、NPCの話の要約、気になる点。
