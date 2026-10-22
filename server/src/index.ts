import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import express from "express";
import config, { listen } from "@colyseus/tools";
import { defineRoom, matchMaker } from "colyseus";
import { ROOM_NAME } from "@metaverse/shared";
import { MainRoom } from "./rooms/MainRoom";
import { adminEnabled, adminRouter } from "./admin";
import { geoBlockMiddleware } from "./geoblock";
import { sampleHealth } from "./health";
import { stats } from "./stats";

// ビルド済みクライアント(client/dist)があれば同じサーバーから配信する。
// ws:// と https:// の混在を避けられ、TLS終端が1か所で済む（README参照）。
const clientDist = fileURLToPath(new URL("../../client/dist", import.meta.url));
const serveClient = existsSync(clientDist) && process.env.SERVE_CLIENT !== "0";

// Playground（開発用の道具）は、使うときだけ読み込む。本番では読み込まない（依存の @colyseus/auth など、使わないコードを動かさないため）
const playground = !serveClient || process.env.ENABLE_PLAYGROUND === "1" ? (await import("@colyseus/playground")).playground : null;

const app = config({
  rooms: {
    [ROOM_NAME]: defineRoom(MainRoom),
  },
  // 単一ルーム運用: 起動時に唯一の部屋を作る。クライアントは join のみ(joinOrCreate しない)なので、
  // 満員(50人)のとき別部屋が自動生成されて人が分断されることはなく、「満員です」で断られる。
  beforeListen: async () => {
    await matchMaker.createRoom(ROOM_NAME, {});
  },
  initializeExpress: (expressApp) => {
    // 海外からのアクセスは、何よりも先に断る（配信・管理ページ・入室の予約のすべてに効く）
    expressApp.use(geoBlockMiddleware);
    // 管理ページ（ADMIN_PASSWORD を知っている人だけ。未設定なら 404）。開発時・本番とも同じ
    expressApp.use("/admin", adminRouter(clientDist));
    // ショー画面の入口（show.html）は、管理ページの中（/admin/show）からだけ配る。外から直接は見せない
    expressApp.get("/show.html", (_req, res) => void res.status(404).type("text/plain").send("Not Found"));
    console.log(adminEnabled ? "[server] 管理ページ: 有効 (/admin)" : "[server] 管理ページ: 無効（ADMIN_PASSWORD 未設定）");
    if (serveClient) {
      // 本番では Playground を出さない（開発用の道具。外から部屋に自由に入れてしまうため）。確認したいときだけ ENABLE_PLAYGROUND=1
      if (playground) expressApp.use("/playground", playground());
      // 再訪を速くするキャッシュ設定。名前にハッシュが付く js/css は長く、画像などは10分、html は毎回確認（更新がすぐ届くように）
      expressApp.use(
        express.static(clientDist, {
          setHeaders: (res, filePath) => {
            if (filePath.endsWith(".html")) res.setHeader("Cache-Control", "no-cache");
            else if (/-[A-Za-z0-9_-]{8}\.(js|css)$/.test(filePath)) res.setHeader("Cache-Control", "public, max-age=31536000, immutable");
            else res.setHeader("Cache-Control", "public, max-age=600");
          },
        }),
      );
    } else {
      // 開発時は http://localhost:2567 で Playground が開く
      if (playground) expressApp.use("/", playground());
    }
  },
});

// 負荷の見張り: 人がいるあいだ、15秒ごとに CPU・イベントループの遅れ・メモリをログに出す（人が増えたときの様子を、あとから見られるように）
setInterval(() => {
  const n = stats.onlineList().length;
  const h = sampleHealth();
  if (n > 0) console.log(`[health] players=${n} cpu=${h.cpu}% lagP99=${h.lagP99}ms lagMax=${h.lagMax}ms rss=${h.rssMB}MB heap=${h.heapMB}MB`);
}, 15000).unref();

listen(app).then(() => {
  console.log(serveClient ? "[server] serving client/dist at /" : "[server] dev mode: Playground at /");
});
