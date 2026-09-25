# 2Dメタバース 実装指示書（Sunnyside World 素材版）

> Claude Code に渡す実装指示書。リポジトリ直下に `SPEC.md` として置き、`CLAUDE.md` から参照すること。
> 第3章の素材仕様は**実物のPNGを解析して確定済み**。推測で上書きしないこと。

---

## 0. Claude Code への作業ルール（最初に必ず読むこと）

1. **フェーズ順に実装する。** 第6章のPhase 0から順に進め、各フェーズの「受け入れ基準」を満たしてから次へ進む。
2. **第3章の数値は実測値。勝手に変えない。** フレームサイズ96×64、タイル16px、原点0.625などは実物を解析して出した値。「たぶん32pxだろう」等で上書きしないこと。
3. **`config/*.json` が素材の真実。** `sprites.json` / `tileset.json` は `rebuild_assets.py` が生成したもの。フレーム数やファイルパスをコードにハードコードせず、必ずJSONから読む。
4. **ライブラリのAPIは推測で書かない。** `https://docs.colyseus.io` と `https://docs.phaser.io` を WebFetch で確認してから実装する。
5. **同種サービスの挙動を参考にする。** 同期や操作感で迷ったら Gather / ZEP / WorkAdventure（OSS）を調べ、判断理由を `docs/decisions.md` に1行残す。
6. **依存バージョンは第2章の指定どおりに固定する。** `^` や `latest` で入れない。
7. **動作確認は必ず実機で行う。** ブラウザ2窓＋ヘッドレスbotで同時接続して確認する（Phase 5）。
8. **不明点が残ったら実装を止めて質問する。**

---

## 1. プロジェクト概要

ブラウザで動く2Dのオンライン共有空間。URLを開くと自分のアバターが出てきて、同じマップにいる他の参加者がリアルタイムで動いているのが見え、チャットとエモートで交流できる。参照するのは ZEP / Gather の体験。

### 必須要件
| # | 要件 |
|---|---|
| R1 | 10人以上が同時に同じマップに接続し、リアルタイムで互いの移動が見える |
| R2 | テキストチャットで交流できる（頭上の吹き出し＋ログ） |
| R3 | エモート／リアクションを飛ばせる |
| R4 | マップは Sunnyside World のタイルセットを使い、`config/map.json` の配置データどおりに描画する |
| R5 | 主人公・モブも同素材を使い、`config/map.json` の配置データどおりに配置する |

### 想定規模
学内・イベント展示。**同時接続 最大50人／単一ルーム**を設計目標とする。複数ルーム・シャーディングはスコープ外（将来足せる構造にはする）。

### 非スコープ
ボイスチャット（WebRTC）、ログイン／アカウント管理、永続DB（メモリのみ・再起動でリセット可）、マップエディタUI。

---

## 2. 技術スタック（確定・バージョン固定）

```
[ブラウザ] Phaser 3 ──WebSocket──> [Node.js] Colyseus
```

| パッケージ | バージョン | 用途 |
|---|---|---|
| `phaser` | `3.90.0` | クライアント描画・入力 |
| `colyseus` | `0.18.6` | サーバー（ルーム・状態同期） |
| `@colyseus/sdk` | `0.18.2` | クライアントSDK |
| `@colyseus/schema` | `5.0.33` | 状態スキーマ（サーバー/クライアント共有） |
| `@colyseus/tools` | `0.18.3` | サーバー起動ユーティリティ |
| `@colyseus/playground` | `0.18.4` | 開発時のデバッグUI（dev依存） |
| `vite` | 最新安定 | クライアントのビルド・devサーバー |
| `typescript` | 最新安定 | 全体 |

**注意点**
- **Phaser は 3.90.0（4系は使わない）。** 4.2.1 が最新だが、Colyseus公式チュートリアルもサンプルも v3 前提。イベント展示なので情報量を優先する。
- **クライアントSDKは `@colyseus/sdk`。** 旧 `colyseus.js`（0.16系）は使わない。
- Schema定義は Schema Builder（`schema()` / `t.*`）かデコレータ（`@type`）の**どちらか一方に統一**。実装前に公式ドキュメントで0.18系の推奨を確認し、選択を `docs/decisions.md` に記録すること。

---

## 3. 素材仕様（Sunnyside World Asset Pack V2.1）

### 3.1 配置場所とライセンス

素材は整理済みで `kit/` に同梱されている。`kit/public/assets/` を `client/public/assets/` に、`kit/config/*.json` を `client/src/config/` にコピーして使う。

出典は [Sunnyside World Asset Pack（danieldiggle, itch.io）](https://danieldiggle.itch.io/sunnyside)。**無料・商用利用可、クレジット不要（歓迎）**。ただし**素材の再配布・再販売は禁止**なので、`client/public/assets/` を含むリポジトリを公開する場合は注意。README にライセンスと出典リンクを明記すること。

### 3.2 タイルセット

| 項目 | 値 |
|---|---|
| メイン画像 | `assets/tilesets/sunnyside_16.png`（1024×1024） |
| **タイルサイズ** | **16 × 16 px** |
| グリッド | 64列 × 64行 = 4096タイル |
| タイルID | `tileId = row * 64 + col`（0始まり・行優先）。**GameMakerプロジェクトと照合して検証済み** |
| 空タイル | `-1` |
| 予備 | `assets/tilesets/sunnyside_forest_32.png`（32px・森用・今回は未使用でよい） |

`config/tileset.json` に11個の **autotileGroups**（`Land` `Path 01〜03` `River` `Building 01/02` `Inner Walls` `Clouds 01/02` `Cloud Shadow`）が入っている。各グループの `fill` が「べた塗り用の中央タイル」で、`tiles`（16枚）が周囲の繋ぎ目バリエーション。ラフに塗るときは `fill` だけ使えばよい。

タイルIDを目視で選ぶときは `kit/reference/tile_picker.jpg`（行列番号入りの全タイル一覧）を見る。

### 3.3 キャラクター

**全キャラ共通で 1フレーム = 96 × 64 px。** ファイル名の `stripN` は信用しないこと（後述）。

| 項目 | 値 |
|---|---|
| フレームサイズ | **96 × 64 px** |
| 実際に絵がある範囲 | フレーム内の **x:43〜56, y:23〜40**（約13×17px）。周囲は道具を振る余白 |
| 原点 | `setOrigin(0.5, 0.625)` ＝ 足元。**これを必ず設定する**（しないと足が浮く） |
| 当たり判定 | 体は約13×17px。判定は足元 **12×8px** 程度に設定するのが自然 |
| 向き | **左右のみ。** 素材は右向きが初期状態。左を向くときは `flipX = true`。**上下移動でも見た目は変えない**（Forager / Atomicrops 方式） |

#### 人間は「重ね合わせ」方式 — これがアバター選択機能になる

人間キャラは3レイヤーを同じ座標に重ねて1人を構成する。

```
base（体・髪なし） + <hair>（髪） + tools（道具）
```

髪は6種類：`bowlhair` `curlyhair` `longhair` `mophair` `shorthair` `spikeyhair`

つまり**入室時に髪型を6つから選ばせるだけでアバター選択が成立する**。Phaser では同じ位置に3つの Sprite を重ね、`Phaser.GameObjects.Container` にまとめて1人として扱うこと。3レイヤーは常に同じ action / 同じフレームで再生する。

ファイルパス：`assets/characters/human/{layer}/{action}.png`
（例：`characters/human/longhair/walk.png`）

#### 使えるアクション（全20種）

`idle(9) waiting(9) walk(8) run(8) jump(9) roll(10) doing(8) carry(8) attack(10) hurt(8) death(13) swimming(12) axe(10) mining(10) hammering(23) dig(13) watering(5) casting(15) reeling(13) caught(10)`

メタバースで必要なのは `idle` `walk` `run` くらいだが、**残りはエモートに使える**（第6章 Phase 4 参照）。

#### モブ用キャラ

| 種類 | パス | アクション |
|---|---|---|
| Goblin | `assets/characters/goblin/{action}.png` | 人間と同じ20種（単一レイヤー） |
| Skeleton | `assets/characters/skeleton/{action}.png` | `attack idle walk jump hurt death` の6種 |

#### ⚠️ Goblin のフレーム数はファイル名が間違っている

Goblin の一部ファイルは、ファイル名の `stripN` と実際のフレーム数が食い違う。**`config/sprites.json` の `frames` の値が正しい**（画像の実サイズから算出済み）。

| ファイル名の主張 | 実際 |
|---|---|
| `spr_idle_strip9` | 8フレーム |
| `spr_attack_strip10` | 9フレーム |
| `spr_death_strip13` | 9フレーム |
| `spr_waiting_strip9` | 8フレーム |
| `spr_swimming_strip12` | 4フレーム |
| `spr_casting_strip15` | 20フレーム（2段組） |
| `spr_dig_strip13` | 20フレーム（2段組） |
| `spr_reeling_strip13` | 20フレーム（2段組） |
| `spr_hammering_strip23` | 30フレーム（3段組） |

2段組・3段組のシートも `frameWidth:96, frameHeight:64` で読めば Phaser が自動で折り返して読む。**ファイル名からフレーム数を計算するコードを書かないこと。**

### 3.4 装飾エレメント（105点）

`assets/elements/` 以下、`config/sprites.json` の `elements` にキーと寸法が入っている。

- `Plants/` — `tree_01` `tree_02` `mushroom_red_01〜03` `mushroom_blue_01〜03`（4フレームの揺れアニメ付き）
- `Animals/` — `cow` `sheep_01` `pig_01` `chicken_01` `duck_01` `bird_01`（4フレーム）
- `Crops/` — 野菜各種の成長段階（静止画）
- `VFX/` — `chimneysmoke_01〜05` `fire_01〜` `glint`
- `Other/` — `coracle` `crate_base` `crate_top` など

`frameWidth` があるものはアニメ、無いものは静止画。**この分岐をローダで処理すること。**

### 3.5 UI 素材

`assets/ui/` に102点。チャット枠には `9slice_box_white/` の9スライス素材（`*_tl` `*_tc` `*_tr` …）が使える。方向キーアイコン（`arrow_*`）はスマホ用バーチャルパッドに流用できる。

---

## 4. アーキテクチャ

### 4.1 同期方式：クライアント主導移動 ＋ サーバー検証

Gather / ZEP 系のソーシャル空間は、対戦ゲームのような厳密な権威サーバーにはしない。操作の体感が最優先で、チートの実害がほぼないため。本プロジェクトもこれを採用する。

```
[自分]     入力 → 即座に自分のContainerを動かす（遅延ゼロ）
             ↓ 15Hz で {x, y, flipX, action} を送信
[サーバー] 速度上限チェック → state.players[sessionId] を更新
             ↓ patchRate 50ms (20Hz) で差分を配信
[他の人]   受信座標を「目標値」として保持し、毎フレーム補間して描画
```

**サーバー側の検証（必須）:** 前回受理座標からの移動距離が `MAX_SPEED * 経過時間 * 1.5` を超えたら、その更新を**棄却して前回座標を維持**する。棄却時はサーバーログに残す。

### 4.2 他プレイヤーの補間（必須）

生の座標を代入するとカクつく。受信座標を `targetX/targetY` に入れ、毎フレーム近づける：

```ts
// Phaser の update(time, delta) 内
const t = 1 - Math.pow(0.001, delta / 1000); // フレームレート非依存
container.x += (container.targetX - container.x) * t;
container.y += (container.targetY - container.y) * t;
```
係数は実機で触って調整する前提。定数として切り出し、コメントを残すこと。

参考：Gabriel Gambetta "Fast-Paced Multiplayer"（Entity Interpolation）。実装前に一読すること。

### 4.3 レート設定
| 項目 | 値 | 定義場所 |
|---|---|---|
| クライアント→サーバー 送信 | 15Hz（約66ms間隔） | `shared/constants.ts` |
| サーバー patchRate | 50ms（20Hz） | Room の `patchRate` |
| サーバー simulationInterval | **使わない**（移動計算をサーバーで回さないため） | — |
| クライアント描画 | 60fps | — |

**送信は値が変化したときだけ。** 静止中に送り続けないこと。

### 4.4 描画順とスケール

- **ピクセルアートなので `pixelArt: true` を Phaser の config に必ず入れる。** 補間がかかるとドット絵が滲む
- タイル16pxに対して画面が小さいので、**カメラズームは2〜3倍**を基準に調整する
- 深度は **Y座標ベースでソート**（`container.setDepth(container.y)`）。手前のキャラ／木が奥のキャラを隠す
- `overhead` レイヤー（屋根・木の上部など）はキャラより手前に固定描画する

### 4.5 モブ（NPC）の扱い

モブは**動かない背景キャラ**として扱い、**サーバー同期しない**。`map.json` の `mobs[]` をクライアントが読んでローカルに描画するだけ。全クライアントが同じデータを読むので結果は一致する。`idle` / `waiting` のループアニメだけ再生させる。

> モブを歩かせたくなった場合のみサーバー管理に移す。今回はやらない。判断理由を `docs/decisions.md` に記録すること。

---

## 5. マップ配置データ

### 5.1 `config/map.json`

マップはこのファイル1つで決まる。**配置をコードに直書きしないこと。**

```jsonc
{
  "name": "demo_field",
  "tileset": "sunnyside_16",
  "tileSize": 16,
  "width": 60, "height": 40,
  "spawn": { "x": 30, "y": 25 },        // タイル座標

  "layers": {
    "ground":    [[193, 193, ...], ...],  // タイルIDの2次元配列
    "deco":      [[-1, 577, ...], ...],   // -1 = 空
    "overhead":  [[-1, -1, ...], ...],    // キャラより手前
    "collision": [[0, 1, ...], ...]       // 1 = 通れない
  },

  "props": [
    { "sprite": "tree_01", "x": 4, "y": 30, "collide": true }
  ],

  "mobs": [
    { "sprite": "goblin", "action": "idle", "x": 24, "y": 24, "flipX": false, "name": "ゴブリン" },
    { "sprite": "human",  "action": "waiting", "x": 31, "y": 19, "flipX": true,
      "name": "受付", "hair": "longhair" }
  ]
}
```

- `props[].sprite` / `mobs[].sprite` は `sprites.json` のキーを参照する
- `x` / `y` は**タイル座標**（ピクセルではない）。内部で `* tileSize` する
- `mobs[].sprite` が `"human"` のときだけ `hair` を見てレイヤー合成する

同梱の `map.json` は**仮マップ**（草原＋十字路＋池＋小屋＋木とモブ）。レンダリング結果が `kit/reference/demo_map_render.png` にあるので、実装した描画がこれと一致すれば正しい。

### 5.2 バリデーション

起動時に検証し、**コンソールに明確なエラーを出す**こと（無言で落ちない）：
- `layers` の配列サイズが `width`/`height` と不一致
- `sprites.json` に存在しないスプライト名を参照している
- タイルIDが 0〜4095 の範囲外
- `spawn` が `collision` の上にある

### 5.3 本番マップの作り方

仮マップを実装完了後、人間が本番マップを作る。手順：

1. `kit/reference/tile_picker.jpg` でタイルIDを確認する
2. `map.json` の `layers` を書き換える
3. リロードすれば反映される（コードは触らない）

**Claude Code は、Phase 1 完了時点で「本番マップの配置イメージをください」と人間に依頼すること。** 受け取ったら `map.json` だけを書き換える。

> 補助として、PNG画像の色から `ground`/`collision` を起こす変換スクリプト `scripts/image-to-map.ts` を作ってもよい（任意）。ただし本体実装を優先すること。

---

## 6. 実装フェーズ

### Phase 0 — プロジェクト基盤
npm workspaces のモノレポ：
```
/
├── package.json          # workspaces: ["shared", "server", "client"]
├── shared/
│   ├── schema.ts         # Colyseus Schema 定義
│   ├── messages.ts       # メッセージ型
│   └── constants.ts      # MAX_SPEED, SEND_RATE_HZ, TILE_SIZE など
├── server/src/{index.ts, rooms/MainRoom.ts}
├── client/
│   ├── public/assets/    # kit/public/assets をコピー
│   └── src/{main.ts, scenes/, config/, net/}
└── docs/decisions.md
```
`.env.example` に `PORT=2567`、クライアントに `VITE_SERVER_URL=ws://localhost:2567`。

**受け入れ基準:** ルートで `npm run dev` → サーバーとクライアントが同時起動。Colyseus Playground（`http://localhost:2567`）でルームが見える。

---

### Phase 1 — マップ描画（オフライン）
- `sprites.json` / `tileset.json` / `map.json` のローダとバリデータ
- タイルマップ描画（`ground` → `deco` → props/mobs → `overhead`）
- `pixelArt: true`、カメラズーム2〜3倍
- アニメ付きprops（木の揺れ等）とモブのidleループを再生
- Y座標ベースの深度ソート

**受け入れ基準:** `kit/reference/demo_map_render.png` とほぼ同じ絵が出る。`map.json` を変えると表示が変わる。

---

### Phase 2 — 自キャラの移動（オフライン）
- 入室画面：名前（最大12文字）＋髪型6種から選択
- base + hair + tools を Container で合成
- WASD / 矢印で8方向移動。`idle` ⇄ `walk` 切り替え、Shiftで `run`
- 左移動で `flipX = true`、右で `false`。**上下では変えない**
- `collision` と `props[].collide` による当たり判定（足元12×8px）
- カメラ追従＋マップ端クランプ
- スマホ用バーチャルパッド（`assets/ui/arrow_*.png` を流用）

**受け入れ基準:** キャラが滑らかに歩き、壁と木をすり抜けない。髪型を変えると見た目が変わる。足が地面に接地して見える。

---

### Phase 3 — リアルタイム同期

`shared/schema.ts`：
```
Player: name, hair, x, y, flipX, action   // action = "idle" | "walk" | "run" | エモート名
MainRoomState: players: MapSchema<Player>
```

メッセージ（`shared/messages.ts`）：

| 方向 | type | payload |
|---|---|---|
| C→S | `move` | `{ x, y, flipX, action }` |
| C→S | `chat` | `{ text }`（最大140文字） |
| C→S | `emote` | `{ id }` |
| S→C | `chat` | `{ sessionId, name, text, at }` |
| S→C | `emote` | `{ sessionId, id }` |

- 入室時に `joinOrCreate("main")`、`onJoin` で `spawn` に生成、`onLeave` で削除
- 4.1の速度上限チェックを実装
- 他プレイヤーのContainer生成／削除／**4.2の補間**
- 自分のスプライトはサーバー座標で上書きしない（ガタつきの原因）
- 頭上に名前ラベル
- `maxClients = 50`、`patchRate = 50`

**受け入れ基準:** ブラウザ2窓で片方を動かすともう片方で滑らかに追従。髪型の違いが相手側にも反映される。閉じるとキャラが消える。

---

### Phase 4 — チャットとエモート

**チャット**
- 画面下部に入力欄。Enterで送信／Enterでフォーカス／Escで解除
- **入力欄にフォーカスがある間は移動キーを無効化する**（よくあるバグ）
- 頭上に吹き出しで約4秒表示 ＋ 左下ログに最大50件
- 吹き出しの枠に `assets/ui/9slice_box_white/` の9スライスを使う
- サーバー側で文字数制限とレート制限（1人あたり毎秒2通まで）

**エモート — アイコンではなくキャラアニメを使う**

この素材パックには20種のアクションが揃っているので、エモートは**キャラ自身が動く**形にする。ZEPのアイコン表示より表現力が出る。

| エモート | 使うアクション | 備考 |
|---|---|---|
| ジャンプ | `jump` | |
| 転がる | `roll` | |
| 手を振る | `doing` | |
| 座る／待つ | `waiting` | ループ。再度押すまで継続 |
| 攻撃ポーズ | `attack` | |
| やられる | `hurt` | ネタ枠 |

実装：`emote` を受け取ったら該当アクションを1回再生し、終了後 `idle` に戻す。`waiting` だけはトグル。再生中は移動入力で即キャンセルして `walk` に戻す。

**受け入れ基準:** 2窓間でチャットとエモートが双方向に届く。エモート中のキャラが相手側でも正しいアニメで見える。移動中にチャットしても操作が壊れない。

---

### Phase 5 — 負荷確認とチューニング
- **ヘッドレスbot `scripts/load-test.ts`** を作る。`@colyseus/sdk` でN体接続しランダムウォーク＋定期チャット
- `npm run loadtest -- --clients 30` のように人数指定可
- bot 30体接続した状態で実ブラウザ1窓の体感を確認
- 確認項目：
  - [ ] FPSが50を下回らない（人間3レイヤー×30体＝90スプライトになるので要注意）
  - [ ] 他キャラの動きがカクつかない
  - [ ] サーバーメモリが接続数に線形で、切断後に解放される
  - [ ] 1クライアントあたりの受信帯域を計測して `docs/decisions.md` に記録
- 問題があればまず**送信レート**と**patchRate**を動かす。それでも重ければテクスチャアトラス化を検討

**受け入れ基準:** bot 30体＋実ブラウザで快適に動く。計測結果が記録されている。

---

### Phase 6 — デプロイ
- Colyseusサーバーは **Railway / Render / Fly.io** または学内の常時起動PC
- クライアントは Vercel / Netlify、もしくはColyseusサーバーから同時配信
- **WebSocketは `wss://` である必要がある。** クライアントが `https://` 配信なら `ws://` はブラウザにブロックされる。TLS終端の設定を必ず確認・文書化すること
- `README.md` に展示当日の手順（起動 → QRコード配布 → 落ちたときの再起動コマンド）とライセンス表記を書く

**受け入れ基準:** 別ネットワークの端末2台からURLで入って同時に遊べる。

---

## 7. 非機能要件

| 項目 | 目標 |
|---|---|
| 同時接続 | 単一ルーム50人で破綻しない |
| 体感遅延 | 同一LAN内で他プレイヤーの動きが100ms以内に反映 |
| クライアントFPS | 30体表示時に50fps以上 |
| 初回ロード | 3秒以内（素材は約4MB。プリロード＋進捗バーを出す） |
| 再接続 | 切れたら自動再接続を試み、失敗したら「接続が切れました／再読込」を画面に出す。無言で固まらない |
| 対応ブラウザ | 最新の Chrome / Safari（iOS Safari含む） |

---

## 8. 参考資料

- Colyseus 公式: https://docs.colyseus.io
- Colyseus × Phaser チュートリアル: https://docs.colyseus.io/learn/tutorial/phaser
- チュートリアルのリポジトリ: https://github.com/colyseus/tutorial-phaser
- Phaser 3 ドキュメント: https://docs.phaser.io
- Entity Interpolation の解説: https://www.gabrielgambetta.com/entity-interpolation.html
- WorkAdventure（同種サービスのOSS実装）: https://github.com/thecodingmachine/workadventure
- 素材出典: https://danieldiggle.itch.io/sunnyside

---

## 9. 人間に確認が必要な事項

1. **本番マップの配置イメージ** — 未提供。仮マップで進め、Phase 1 完了時に依頼すること
2. **アバターの髪型6種をユーザーに選ばせるか、ランダム割り当てにするか**
3. **展示会場のネットワーク環境**（Phase 6のホスティング選定に影響）

---

## 変更履歴
- 2026-09-19 初版
- 2026-09-19 Sunnyside World Asset Pack V2.1 を解析し、素材仕様（タイル16px・フレーム96×64・左右のみ・人間3レイヤー合成）を実測値で確定。map.json をタイルID方式に変更。エモートをキャラアニメ方式に変更。
