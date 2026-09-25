/**
 * サーバー側検証の確認: テレポート移動が棄却され、本人に correct が返ることを確かめる。
 *   npm run cheat-test
 */
import { Client } from "@colyseus/sdk";
import { MSG, ROOM_NAME, MainRoomState } from "@metaverse/shared";

const room = await new Client(process.env.URL ?? "ws://localhost:2567").join(ROOM_NAME, { name: "cheater", hair: "mophair" }, MainRoomState);
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
let corrected: { x: number; y: number } | null = null;
room.onMessage(MSG.correct, (m: { x: number; y: number }) => (corrected = m));
await sleep(500);

const me = () => room.state.players.get(room.sessionId)!;
const start = { x: me().x, y: me().y };

// 1) 通常の歩き（受理されるべき）
room.send(MSG.move, { x: start.x + 4, y: start.y, flipX: false, action: "walk" });
await sleep(200);
const okMove = Math.abs(me().x - (start.x + 4)) < 0.01;

// 2) 300px のテレポート（棄却されるべき）
room.send(MSG.move, { x: start.x + 300, y: start.y, flipX: false, action: "run" });
await sleep(300);
const rejected = Math.abs(me().x - (start.x + 4)) < 0.01 && corrected !== null;

// 3) 不正なアクション名・NaN（無視されるべき）
room.send(MSG.move, { x: start.x + 5, y: start.y, flipX: false, action: "<script>" });
room.send(MSG.move, { x: NaN, y: 0, flipX: false, action: "walk" });
await sleep(200);
const garbageIgnored = me().action === "walk" && Math.abs(me().x - (start.x + 4)) < 0.01;

console.log(JSON.stringify({ okMove, rejected, corrected, garbageIgnored }));
await room.leave();
process.exit(okMove && rejected && garbageIgnored ? 0 : 1);
