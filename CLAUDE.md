# CLAUDE.md

このリポジトリの実装仕様は [SPEC.md](./SPEC.md)（素材仕様は実測値なので勝手に変えない）。設計判断と計測結果は [docs/decisions.md](./docs/decisions.md)。

- 素材と配置の真実は `client/src/config/*.json`（`sprites.json` / `tileset.json` / `map.json`）。フレーム数やパスをコードに直書きしない。
- 本番マップは `map.json` を書き換えるだけ（コードは触らない）。起動時に検証され、問題は画面とコンソールに出る。
- 依存バージョンは固定（`^` を使わない）。ライブラリ API は推測せず、`node_modules` の型定義か公式ドキュメントで確認する。
- 検証コマンド: `npm run dev` / `npm run loadtest -- --clients 30` / `npm run cheat-test` / `npm run build`
