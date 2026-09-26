# syntax=docker/dockerfile:1
#
# Fly.io などへの本番デプロイ用。`flyctl deploy` はこのファイルを使って
# ローカルのファイル一式（.dockerignore で除外したものを除く）から直接イメージを作る。
# 素材(client/public/assets)と client/src/config/map.json は .gitignore では除外しているが、
# .dockerignore では除外していない（ローカルに実体があるので、ここで初めてイメージに入る）。
#
# サーバーは「ビルド済みクライアント(client/dist)があれば同じポートから配信する」設計
# （server/src/index.ts）。そのためコンテナ内では npm run build でクライアントだけビルドし、
# サーバー自体は開発時と同じく tsx でそのまま実行する（server の build スクリプトは型チェックのみ）。

FROM node:24-slim AS build
WORKDIR /app

# 依存関係だけ先にコピーしてレイヤーキャッシュを効かせる
COPY package.json package-lock.json ./
COPY shared/package.json shared/package.json
COPY server/package.json server/package.json
COPY client/package.json client/package.json
RUN npm ci

# ソース一式をコピーしてビルド（クライアントの静的ファイルと、サーバーの型チェック）
COPY . .
RUN npm run build -w client
RUN npm run build -w server

# ---- 実行用イメージ ----
FROM node:24-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/shared ./shared
COPY --from=build /app/server ./server
COPY --from=build /app/client/package.json ./client/package.json
COPY --from=build /app/client/dist ./client/dist
COPY --from=build /app/client/src/config ./client/src/config

# server/src/index.ts のデフォルト(2567)と合わせる。fly.toml の internal_port もこれに揃える
EXPOSE 2567
CMD ["npm", "start"]
