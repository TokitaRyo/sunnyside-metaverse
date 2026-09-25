/**
 * ヘッドレス負荷テスト bot。
 *   npm run loadtest -- --clients 30
 *   npm run loadtest -- --clients 30 --duration 60 --url ws://localhost:2567
 * ランダムウォーク＋定期チャット＋たまにエモート。1体目で受信帯域を計測する。
 */
import { readFileSync } from "node:fs";
import { Client, type Room } from "@colyseus/sdk";
import {
  EMOTE_IDS,
  FOOT_H,
  FOOT_W,
  HAIRS,
  MSG,
  ROOM_NAME,
  SEND_INTERVAL_MS,
  WALK_SPEED,
  MainRoomState,
} from "@metaverse/shared";

const args = new Map<string, string>();
for (let i = 2; i < process.argv.length; i += 2) args.set(process.argv[i].replace(/^--/, ""), process.argv[i + 1]);
const N = Number(args.get("clients") ?? 10);
const URL_ = args.get("url") ?? "ws://localhost:2567";
const DURATION = Number(args.get("duration") ?? 0);
const CHAT_EVERY_MS = Number(args.get("chat-every") ?? 12000);

const map = JSON.parse(readFileSync(new URL("../client/src/config/map.json", import.meta.url), "utf8"));
const TS: number = map.tileSize;
const W = map.width * TS;
const H = map.height * TS;
const blocked = (cx: number, cy: number) => {
  const l = cx - FOOT_W / 2, r = cx + FOOT_W / 2, t = cy - FOOT_H, b = cy;
  if (l < 0 || t < 0 || r > W || b > H) return true;
  for (let row = Math.floor(t / TS); row <= Math.floor((b - 0.001) / TS); row++)
    for (let col = Math.floor(l / TS); col <= Math.floor((r - 0.001) / TS); col++)
      if (map.layers.collision[row]?.[col] === 1) return true;
  return false;
};

const SAYINGS = ["こんにちは！", "いい天気だね", "だれかいる？", "こっち来て〜", "テスト中です", "わーい", "おなかすいた", "ここ広いね"];
const rand = <T,>(a: readonly T[]) => a[Math.floor(Math.random() * a.length)];

let rxBytes = 0;
let connected = 0;
let failed = 0;
const rooms: Room[] = [];

async function spawnBot(i: number): Promise<void> {
  const client = new Client(URL_);
  const room = (await client.join(ROOM_NAME, { name: `bot${i}`, hair: rand(HAIRS) }, MainRoomState)) as Room<any, MainRoomState>;
  rooms.push(room);
  connected++;
  if (i === 0) {
    const ws = (room.connection.transport as unknown as { ws: WebSocket }).ws;
    ws.addEventListener("message", (ev: MessageEvent) => {
      const d = ev.data as ArrayBuffer | Blob | string;
      rxBytes += typeof d === "string" ? d.length : (d as ArrayBuffer).byteLength ?? 0;
    });
  }
  room.onMessage(MSG.chat, () => {});
  room.onMessage(MSG.emote, () => {});
  room.onMessage(MSG.correct, (m: { x: number; y: number }) => {
    x = m.x;
    y = m.y;
  });
  room.onLeave(() => connected--);

  // 自分の初期位置はstateから拾う
  await new Promise<void>((res) => {
    const check = () => {
      const p = room.state.players.get(room.sessionId);
      if (p) res();
      else setTimeout(check, 20);
    };
    check();
  });
  const me = room.state.players.get(room.sessionId)!;
  let x = me.x;
  let y = me.y;
  let dx = 0;
  let dy = 0;
  let flipX = false;
  let action = "idle";
  let turnAt = 0;

  const tick = setInterval(() => {
    const now = Date.now();
    if (now >= turnAt) {
      const a = Math.random() * Math.PI * 2;
      const still = Math.random() < 0.25;
      dx = still ? 0 : Math.cos(a);
      dy = still ? 0 : Math.sin(a);
      turnAt = now + 1000 + Math.random() * 2500;
    }
    const step = (WALK_SPEED * SEND_INTERVAL_MS) / 1000;
    const nx = x + dx * step;
    const ny = y + dy * step;
    if (dx !== 0 || dy !== 0) {
      if (!blocked(nx, y)) x = nx;
      else dx = -dx;
      if (!blocked(x, ny)) y = ny;
      else dy = -dy;
      if (dx < 0) flipX = true;
      else if (dx > 0) flipX = false;
      action = "walk";
    } else action = "idle";
    room.send(MSG.move, { x: Math.round(x * 10) / 10, y: Math.round(y * 10) / 10, flipX, action });
  }, SEND_INTERVAL_MS);

  setInterval(() => room.send(MSG.chat, { text: rand(SAYINGS) }), CHAT_EVERY_MS * (0.6 + Math.random() * 0.8));
  setInterval(() => Math.random() < 0.3 && room.send(MSG.emote, { id: rand(EMOTE_IDS) }), 9000);
  room.onLeave(() => clearInterval(tick));
}

console.log(`[loadtest] ${N} bots -> ${URL_}`);
const t0 = Date.now();
for (let i = 0; i < N; i++) {
  spawnBot(i).catch((e) => {
    failed++;
    console.error(`[bot${i}] failed:`, e?.message ?? e);
  });
  await new Promise((r) => setTimeout(r, 60)); // 一斉接続で詰まらないように少しずらす
}

let lastBytes = 0;
const report = setInterval(() => {
  const mem = process.memoryUsage().rss / 1048576;
  const kbps = ((rxBytes - lastBytes) / 5 / 1024).toFixed(2);
  lastBytes = rxBytes;
  console.log(`[loadtest] t=${Math.round((Date.now() - t0) / 1000)}s connected=${connected} failed=${failed} bot0-rx=${kbps}KB/s (total ${(rxBytes / 1024).toFixed(0)}KB) botproc-rss=${mem.toFixed(0)}MB`);
}, 5000);

const stop = async () => {
  clearInterval(report);
  await Promise.allSettled(rooms.map((r) => r.leave()));
  process.exit(0);
};
process.on("SIGINT", stop);
if (DURATION > 0) setTimeout(stop, DURATION * 1000);
