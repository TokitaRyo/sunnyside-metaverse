import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import express from "express";
import config, { listen } from "@colyseus/tools";
import { defineRoom, matchMaker } from "colyseus";
import { playground } from "@colyseus/playground";
import { ROOM_NAME } from "@metaverse/shared";
import { MainRoom } from "./rooms/MainRoom";

// ビルド済みクライアント(client/dist)があれば同じサーバーから配信する。
// ws:// と https:// の混在を避けられ、TLS終端が1か所で済む（README参照）。
const clientDist = fileURLToPath(new URL("../../client/dist", import.meta.url));
const serveClient = existsSync(clientDist) && process.env.SERVE_CLIENT !== "0";

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
    if (serveClient) {
      expressApp.use("/playground", playground());
      expressApp.use(express.static(clientDist));
    } else {
      // 開発時は http://localhost:2567 で Playground が開く
      expressApp.use("/", playground());
    }
  },
});

listen(app).then(() => {
  console.log(serveClient ? "[server] serving client/dist at /" : "[server] dev mode: Playground at /");
});
