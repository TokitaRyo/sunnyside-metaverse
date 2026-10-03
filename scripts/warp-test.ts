/**
 * ワープタイルのサーバー側動作確認（ブラウザ不要）。
 *   npx tsx scripts/warp-test.ts
 * client/src/config/map.json の warps のうち、スポーンに一番近い1つへ、通常の歩行として近づいて、
 * サーバーが warp:true の補正（移動先の座標つき）を返すことを確かめる。
 */
import { readFileSync } from "node:fs";
import { Client } from "@colyseus/sdk";
import { MSG, ROOM_NAME, MainRoomState } from "@metaverse/shared";

const map = JSON.parse(readFileSync("client/src/config/map.json", "utf8")) as {
  tileSize: number;
  spawn: { x: number; y: number };
  warps?: { x: number; y: number; toX: number; toY: number }[];
};
const T = map.tileSize;
if (!map.warps?.length) {
  console.error("map.json に warps がありません");
  process.exit(1);
}

const room = await new Client(process.env.URL ?? "ws://localhost:2567").join(ROOM_NAME, { name: "warptest", hair: "mophair" }, MainRoomState);
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const corrections: { x: number; y: number; warp?: boolean }[] = [];
room.onMessage(MSG.correct, (m: { x: number; y: number; warp?: boolean }) => corrections.push(m));
await sleep(500);

const me = () => room.state.players.get(room.sessionId)!;
console.log("start", JSON.stringify({ x: me().x, y: me().y }));

// スポーンに一番近いワープ元マスを選ぶ
const sp = { x: map.spawn.x * T + T / 2, y: map.spawn.y * T + T / 2 };
const w = [...map.warps].sort((a, b) => Math.hypot(a.x * T - sp.x, a.y * T - sp.y) - Math.hypot(b.x * T - sp.x, b.y * T - sp.y))[0];
const targetX = w.x * T + T / 2, targetY = w.y * T + T / 2;
console.log("warp", JSON.stringify(w));

// 予算内の小刻みな移動で少しずつ近づく（通常の歩行として受理されるように）。ワープを受け取ったら止める
for (let i = 0; i < 200 && !corrections.some((c) => c.warp); i++) {
  const cur = me();
  const dx = targetX - cur.x, dy = targetY - cur.y;
  const dist = Math.hypot(dx, dy);
  if (dist < 1) break;
  const step = Math.min(6, dist);
  room.send(MSG.move, { x: cur.x + (dx / dist) * step, y: cur.y + (dy / dist) * step, flipX: false, action: "walk" });
  await sleep(80);
}
await sleep(200);

const warpCorrection = corrections.find((c) => c.warp);
console.log("corrections", JSON.stringify(corrections));
const ok = !!warpCorrection && Math.abs(warpCorrection.x - (w.toX * T + T / 2)) < 0.5 && Math.abs(warpCorrection.y - (w.toY * T + T / 2)) < 0.5;
console.log(JSON.stringify({ warpCorrection, ok }));
await room.leave();
process.exit(ok ? 0 : 1);
