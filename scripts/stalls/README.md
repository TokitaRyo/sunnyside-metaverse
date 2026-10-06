# 出店（屋台）の作り方

1 つの出店は次の 2 ファイルの組です（`<id>` は英小文字。例: `okonomiyaki`）。

| ファイル | 役目 |
|---|---|
| `scripts/stalls/<id>.ps1` | 専用ドット絵(PNG)を描く。出力は `client/public/brand/stall/<id>_*.png`（ファイル名は必ず `<id>_` で始める） |
| `scripts/stalls/<id>.mjs` | 配置。`export const meta = { id, label, island }` と `export default function layout(k)` |

## 道具

- 絵を描く: `scripts/lib/pixel.ps1`（`. "$PSScriptRoot\..\lib\pixel.ps1"` で読み込む）。`Rect` `Frame` `Ellipse` `Line` `Ascii` `TextPx`（日本語の文字をドットで貼る）`Save` など。**日本語を含む .ps1 は UTF-8 BOM 付きで保存する**（PowerShell 5.1 は BOM が無いと文字化けする）。リポジトリのルートで実行する。
- 配置する: `scripts/lib/stall-kit.mjs` の `k`（`layout(k)` の引数）。
  - `k.custom("<id>_xxx", ox?, oy?, { frames, fps }?)` 専用絵を使えるようにする（原点は省略すると足元中央）。アニメは「フレームを横一列に並べたPNG」＋ `{frames, fps}`（例: 点滅するライト、ゆらぐ湯気）。ゲームでは自動で繰り返し再生される。`k.put` の `frame` で開始コマを変えられる
  - `k.cropAt(px, py)` / `k.cropRect(x, y, w, h)` タイルセット(sunnyside_16_ext.png)の絵を使えるようにする（名前を返す）
  - `k.put(name, dx, foot, { by, sort, flip, hit:[w,h], hxOff, frame, npc })` 1個置く。`k.person(name, dx, foot, npc, flip)` 人物（影・当たり判定つき）
  - 座標: `dx` = 草地の中心Xからのずれ(-96..96)、`foot` = 草地の上端Yから足元までの距離(0..128)、`by` = 前後の判定（大きいほど手前）
- 確かめる（map.json に書かない）: `node scripts/preview-stall.mjs <id> --scale=4 [--hit] [--grid]` → `reference/stall-previews/<id>.png`
- 素材を調べる: `node scripts/stall-assets.mjs sprites "plate|mug"` / `items x0 y0 x1 y1` / `crop x y w h 6`
- 島に組み立てる: `node scripts/build-stalls.mjs --only=<id> [--replace] [--dry]`（map.json を書き換える。バックアップは reference/map-backups/）

## 守ること

- 島の草地は **192×128px**。物はその範囲に収める（看板・のぼりなど背の高い物が少し上にはみ出るのは可）。
- 人物のスプライトは 96×64 だが体は約 16px 四方で、体は `foot-16 .. foot` に出る。カウンターの奥に立たせるなら足元をカウンター上面の線に合わせる。
- 台の上に置く物は `by` を台より大きくして手前に描く。床に敷く物は `sort:"floor"`。
- 通れない物（カウンター・柱・大きな物）には `hit:[幅,高さ]` を付ける。入口や客が歩く所は空ける。
- 話しかけられる人物には `npc:{ name, lines[] }`（1要素が1ページ。名前は短く）。文言はひらがな多めで、団体を紹介する内容にする。値段や時間など、事実が分からないことは書かない。
- 素材パックの絵は組み合わせて使ってよいが、専用ドット絵はすべて自分で描いたオリジナルにする（素材パックの絵を写さない）。
