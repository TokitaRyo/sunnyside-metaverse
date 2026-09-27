/**
 * ワープタイルのサーバー側動作確認（ブラウザ不要）。
 *   npx tsx scripts/warp-test.ts
 * 前提: client/src/config/map.json に (33,22)→(40,22) のワープが1つ設定済みであること。
 */
import { Client } from "@colyseus/sdk";
import { MSG, ROOM_NAME, MainRoomState } from "@metaverse/shared";

const room = await new Client(process.env.URL ?? "ws://localhost:2567").join(ROOM_NAME, { name: "warptest", hair: "mophair" }, MainRoomState);
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const corrections: { x: number; y: number; warp?: boolean }[] = [];
room.onMessage(MSG.correct, (m: { x: number; y: number; warp?: boolean }) => corrections.push(m));
await sleep(500);

const me = () => room.state.players.get(room.sessionId)!;
console.log("start", JSON.stringify({ x: me().x, y: me().y }));

// ワープ元マス(33,22)の中心 px = 33*16+8, 22*16+8 = (536, 360)
const targetX = 536, targetY = 360;
// 予算内の小刻みな移動で少しずつ近づく（通常の歩行として受理されるように）。
// ワープすると位置が飛ぶので、ワープを受け取ったら以降は送らずに止める。
for (let i = 0; i < 40 && !corrections.some((c) => c.warp); i++) {
  const cur = me();
  const dx = targetX - cur.x, dy = targetY - cur.y;
  const dist = Math.hypot(dx, dy);
  if (dist < 1) break;
  const step = Math.min(6, dist);
  const nx = cur.x + (dx / dist) * step, ny = cur.y + (dy / dist) * step;
  room.send(MSG.move, { x: nx, y: ny, flipX: false, action: "walk" });
  await sleep(80);
}
await sleep(200);

const warpCorrection = corrections.find((c) => c.warp);
console.log("corrections", JSON.stringify(corrections));

// 移動先(40,22)の中心 px = 40*16+8, 22*16+8 = (648, 360)
const ok = !!warpCorrection && Math.abs(warpCorrection.x - 648) < 0.5 && Math.abs(warpCorrection.y - 360) < 0.5;
console.log(JSON.stringify({ warpCorrection, ok }));
await room.leave();
process.exit(ok ? 0 : 1);
