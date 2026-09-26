# Sunnyside World — 2D メタバース

ブラウザで動くオンライン共有空間。URL を開くと自分のアバターが現れ、同じマップにいる人がリアルタイムに動き、チャットとエモートで交流できます。
Phaser 3.90.0 ＋ Colyseus 0.18.6。実装仕様は [SPEC.md](./SPEC.md)、設計判断と計測結果は [docs/decisions.md](./docs/decisions.md)。

## 使い方（開発）

Node.js 20 以上が必要です。

```bash
npm install
npm run dev
```

- ゲーム: http://localhost:5173 （同一 LAN のスマホからは `http://<PCのIP>:5173`）
- Colyseus Playground: http://localhost:2567

操作: 移動 WASD / 矢印キー ・ 走る Shift ・ チャット Enter（送信 Enter / 解除 Esc）・ エモート 1〜6 またはボタン。
スマホはバーチャルパッド表示（PC で確認するときは `?pad=1` を付ける）。

| コマンド | 内容 |
|---|---|
| `npm run dev` | サーバーとクライアントを同時起動 |
| `npm run build` | クライアントを `client/dist` にビルド（＋サーバーの型チェック） |
| `npm start` | サーバー起動。`client/dist` があれば同じポートから配信 |
| `npm run loadtest -- --clients 30` | bot を N 体接続して負荷確認（`--duration 60` で自動終了） |
| `npm run cheat-test` | サーバー側の速度検証が効いているか確認 |

## マップを差し替える

`client/src/config/map.json` を書き換えてリロードするだけです（コードは触りません）。
タイル ID は `reference/tile_picker.jpg`（行列番号入り）で確認します（`tileId = row * 64 + col`）。
起動時に検証され、サイズ不一致・存在しないスプライト名・範囲外のタイル ID・衝突上のスポーンは、画面とコンソールに理由が表示されます。

### 標準マップ: 公式の全体マップ（Sunnyside World の例シーン）

標準の `map.json` は、元パック（`Sunnyside_World_ASSET_PACK_V2.1`）の GameMaker ルーム `Room1` を変換したものです（86×48 タイル。島・崖・川・橋・家・風車・鉱山・雲・ゴブリンまで）。元パックがあれば再生成できます。

```bash
node scripts/import-gm-room.mjs "<...>/Sunnyside_World_ASSET_PACK_V2.1"   # Assets と Gamemaker フォルダが並ぶ階層
```

`client/src/config/map.json`、`client/public/assets/gm/`（配置物のスプライトシート）、`client/public/assets/tilesets/*_ext.png`（反転・回転を焼き込んだタイルセット）が生成されます。衝突判定は元データに無いため、タイルの見た目から導出しています（規則は `docs/decisions.md`）。飛び地（左上の畑の台地・左下の鉱山など）には本島から歩いて行けません。

### マップエディタ（モブ配置・当たり判定・タイルの調整）

開発サーバー（`npm run dev`）で **http://localhost:5173/** を開き、画面右上の **「🛠 マップを編集」** ボタンでプレイ画面とエディタをいつでも行き来できます（本番ビルドには含まれません）。`?edit=1` を付けて開く（または保存後の自動リロード）と、最初からエディタが開きます。

- **編集内容は「保存」を押すまでファイルに書かれません**が、切り替え中もメモリ上には残るので、**プレイ画面に戻ると未保存の変更もそのまま見た目に反映されます**（試しにプレイしながら配置を確かめられます）。ただし**サーバー側の当たり判定は保存済みの `map.json` のまま**なので、衝突まわりを変えた直後のプレイでは見た目とサーバー判定がずれることがあります。気になる場合は保存してから試してください。
- エディタへ切り替えると、自分のキャラは部屋を退室します（他の人からは見えなくなります）。プレイ画面に戻ると入室画面が再度表示されるので、もう一度「入室する」を押してください。

| ツール（キー） | できること |
|---|---|
| 選択・移動（V） | 物（ゴブリン・動物・木・樽…）をクリックで選択、ドラッグで移動、矢印キーで1px（Shiftで8px）。右パネルで座標・アニメの開始フレーム/速度・前後の扱い・**当たり判定（幅×高さ・有無）**を数値編集。F=左右反転、N=複製、Delete=削除 |
| 物を置く（O） | **カテゴリ別の一覧（ゴブリン20種・スケルトン6種・人間30種・動物/鳥6種・その他の物）** からサムネイルで選び、マップをクリックして配置。ゴブリン・スケルトン・人間は**足元の影も一緒に**置かれる（「足元の影も一緒に置く」で切り替え）。足元Yと当たり判定の初期値は自動 |
| 衝突（C） | 16pxマスを左ドラッグで通行不可（赤）、右ドラッグで通行可に |
| タイル（T） | レイヤーを選び、パレットから（ドラッグで範囲も）選んだタイルを描く。右クリックで消す。透明タイルは貼らない設定あり |
| スポーン（P） | クリックしたマスを入室位置に（青枠） |

- 移動は WASD（Shiftで速く）または中ボタン/スペース＋ドラッグ、ズームはホイール。左のレイヤー一覧で表示のON/OFF。
- **Ctrl+Z / Ctrl+Y** で元に戻す・やり直し。**Ctrl+S（保存ボタン）** で `client/src/config/map.json` に書き戻します。上書き前のファイルは `reference/map-backups/map-<日時>.json` に退避されるので、いつでも戻せます。
- 保存するとサーバーが自動で再起動し（`map.json` を監視）、新しい衝突判定が反映されます。クライアント側も Vite が自動でページを再読み込みします（今いたモードへ `?edit=1` の有無で自動的に戻ります）。
- 保存の受け口（`/__editor/save`）は **localhost からのリクエストだけ**受け付けます（開発サーバーは LAN にも公開されるため）。別の端末から編集した場合は「書き出し」で `map.json` をダウンロードして置き換えてください。

**モブ（ゴブリン・スケルトン・人間・動物・鳥）の追加と削除**

- **追加:** 「物を置く」→ カテゴリ（ゴブリン／スケルトン／人間／動物・鳥）→ サムネイル → マップをクリック。ゴブリンは動作ごとに別の種類（立ち・待機・歩く・作業・運ぶ・泳ぐ・斧・採掘・釣り…）、人間は髪型6種×動作5種から選べます。
- **削除:** 「選択・移動」でモブをクリック → **Delete**（または「削除」ボタン）。
- **影:** ゴブリン・スケルトン・人間は、足元に影が**別の物**として置かれています。選択したモブを **動かす・複製・削除すると影も一緒に**扱われます（「影も一緒に 動かす・複製・削除」で切り替え）。影が無いモブには「影を追加」、影だけ消すには「影だけ削除」。どちらも Ctrl+Z で戻せます。
- **動物・鳥は影の物が不要**です（牛・羊・豚・鶏・アヒル・鳥は、絵の中に影が描かれているため）。
- 使っていない種類（ゴブリンの「やられ」、スケルトン、人間など）はカタログ項目で、**エディタで開いたときだけ読み込まれます**。通常のゲームでは、実際に置いたものしか読み込まないので、読み込み量は増えません。
- カタログを既存の `map.json` に足すには `node scripts/add-mob-catalog.mjs "<...>/Sunnyside_World_ASSET_PACK_V2.1"`。**編集済みの配置物・タイル・衝突には触れず**、`sprites` に項目を追加するだけです（実行前のファイルは `reference/map-backups/` に退避）。
- 素材にない新しい種類（別のキャラなど）を増やすときは、`scripts/lib/mobcatalog.mjs` に追加してください。

### 手組みの村マップ

`reference/map_village_generated.json` は、家を含まない小さめ(60×40)の村マップです。**`scripts/gen-map.mjs` で生成**しています。使うときは `client/src/config/map.json` に上書きしてください。配置を変えたいときは、このスクリプトの座標や部品を編集して再生成すると、道・池の縁取り（autotile）が自動で付きます。

```bash
node scripts/gen-map.mjs                                   # map.json を再生成
node scripts/render-map.mjs client/src/config/map.json reference/render.png --scale 2   # タイル層をPNGで確認（ブラウザ不要）
powershell -File scripts/crop-tiles.ps1 -Col 38 -Row 0 -Cols 8 -Rows 6 -Out reference/crop.png  # タイルセットの一部を拡大＋行列番号つきで見る
```

部品のタイルID・autotile の並びの規則は [docs/decisions.md](./docs/decisions.md) の「マップ制作」に記録しています。

## 本番環境（Fly.io）

**https://sunnyside-metaverse.fly.dev/** — スマホからもそのまま参加できます。

サーバーは 1 プロセスで、クライアントも同じポートから配信します。**WebSocket は `https://` 配信のとき必ず `wss://` になります**（`ws://` はブラウザにブロックされる）。ビルド済みクライアントは配信元と同じオリジンへ接続するので、TLS を終端する場所が 1 か所で済みます（Fly.io が自動で TLS 終端する）。

### 構成

- `Dockerfile` / `.dockerignore` / `fly.toml` — Fly.io 向け。マルチステージビルドで、クライアントは `vite build`、サーバーは（`tsx` でそのまま実行するので）型チェックのみ行う。
- 素材（`client/public/assets/`）と `map.json` は**再配布禁止ライセンス**のためこの公開リポジトリには含めていない（`.gitignore` 参照）。非公開の [TokitaRyo/sunnyside-metaverse-assets](https://github.com/TokitaRyo/sunnyside-metaverse-assets) に置き、ビルド直前にだけ取得する。
- `.github/workflows/deploy.yml` — **`main` への push で自動デプロイ**。読み取り専用の Deploy Key（`ASSETS_DEPLOY_KEY`）で素材リポジトリを取得し、`client/public/assets` と `map.json` を配置してから `flyctl deploy` する。Fly.io 側の認証は、このアプリだけに使える deploy トークン（`FLY_API_TOKEN`、`flyctl tokens create deploy` で発行）。どちらも GitHub の Secrets に設定済み。

### 手元から再デプロイする場合

```bash
flyctl deploy          # このフォルダに client/public/assets と map.json がある状態で実行する
```

### 運用メモ

- **落ちたとき**: Fly.io のダッシュボード、または `flyctl apps restart sunnyside-metaverse` で再起動。状態はメモリのみなので参加者は再読込すればよい。回線が一時的に切れた場合は 15 秒以内なら自動で同じキャラに復帰する。
- **満員（50 人）**: 51 人目は入室画面に「満員です」と表示される。
- **支払い方法未登録の場合**: Fly.io の組織に支払い方法が無いと high availability（機体冗長化）が自動で無効になり単一マシン構成になる。展示当日に安定させたいときはダッシュボードで支払い方法を追加する。
- **サーバーログ**: `flyctl logs`

### 他のホスティング先を使う場合

Railway / Render でも動く（TLS 自動・WebSocket 対応）。ビルド: `npm install && npm run build`、起動: `npm start`（`PORT` 環境変数で変更可）。別ホストにサーバーを置く場合は、クライアントのビルド時に `VITE_SERVER_URL=wss://<サーバー>` を指定する（`.env.example` 参照）。学内の常時起動 PC だけで使うなら `npm start` して `http://<PCのIP>:2567`（同一LAN限定）でも足りる。

## 構成

```
shared/   Schema・メッセージ型・定数（サーバー/クライアント共有）
server/   Colyseus サーバー（速度検証・チャットのレート制限）
client/   Phaser 3 クライアント（config/*.json が素材と配置の真実）
scripts/  負荷テスト bot・チート検証
docs/     decisions.md（設計判断・計測結果）
```

## ライセンス・クレジット

素材は [Sunnyside World Asset Pack（danieldiggle, itch.io）](https://danieldiggle.itch.io/sunnyside)（V2.1）。無料・商用利用可、クレジット不要（歓迎）ですが、**素材の再配布・再販売は禁止**です。`client/public/assets/`（`gm/` と `*_ext.png` を含む）と、元パックの配置データ由来の `client/src/config/map.json` を含むリポジトリを公開する場合は、`.gitignore` の該当行を有効にして素材を除外してください。
