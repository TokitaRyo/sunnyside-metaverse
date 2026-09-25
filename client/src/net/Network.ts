import { Client, Callbacks, type Room } from "@colyseus/sdk";
import {
  MSG,
  ROOM_NAME,
  MainRoomState,
  type ChatBroadcast,
  type ChatSend,
  type CorrectMessage,
  type EmoteBroadcast,
  type EmoteId,
  type EmoteSend,
  type MoveMessage,
  type Player,
} from "@metaverse/shared";

/** VITE_SERVER_URL があればそれを、無ければ配信元ホストの 2567（開発）/ 同一オリジン（本番）を使う。 */
export function serverUrl(): string {
  const env = import.meta.env.VITE_SERVER_URL as string | undefined;
  if (env) return env;
  const secure = location.protocol === "https:";
  const proto = secure ? "wss" : "ws";
  if (import.meta.env.DEV) return `${proto}://${location.hostname}:2567`;
  return `${proto}://${location.host}`;
}

export type NetRoom = Room<any, MainRoomState>;

export interface NetHandlers {
  onPlayerAdd(player: Player, sessionId: string): void;
  onPlayerChange(player: Player, sessionId: string): void;
  onPlayerRemove(player: Player, sessionId: string): void;
  onChat(msg: ChatBroadcast): void;
  onEmote(msg: EmoteBroadcast): void;
  onCorrect(msg: CorrectMessage): void;
  /** 回線が途切れ、自動再接続を試みている */
  onDrop(): void;
  onReconnect(): void;
  /** 復帰できず切断が確定した */
  onLost(code: number): void;
}

export class Network {
  room!: NetRoom;

  async join(name: string, hair: string, h: NetHandlers): Promise<void> {
    const client = new Client(serverUrl());
    // 部屋はサーバーが起動時に1つだけ作る。join のみ使い、満員なら断られる
    let room: NetRoom;
    try {
      room = (await client.join(ROOM_NAME, { name, hair }, MainRoomState)) as NetRoom;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (/locked|full|no rooms/i.test(msg)) throw new Error("満員です。しばらくしてからもう一度お試しください");
      throw e;
    }
    this.room = room;

    const cb = Callbacks.get(room);
    cb.onAdd("players", (player, sessionId) => {
      h.onPlayerAdd(player, sessionId);
      cb.onChange(player, () => h.onPlayerChange(player, sessionId));
    });
    cb.onRemove("players", (player, sessionId) => h.onPlayerRemove(player, sessionId));

    room.onMessage(MSG.chat, (m: ChatBroadcast) => h.onChat(m));
    room.onMessage(MSG.emote, (m: EmoteBroadcast) => h.onEmote(m));
    room.onMessage(MSG.correct, (m: CorrectMessage) => h.onCorrect(m));

    room.onDrop(() => h.onDrop());
    room.onReconnect(() => h.onReconnect());
    room.onLeave((code) => h.onLost(code));
  }

  get sessionId(): string {
    return this.room.sessionId;
  }

  sendMove(m: MoveMessage): void {
    this.room.send(MSG.move, m);
  }
  sendChat(text: string): void {
    const m: ChatSend = { text };
    this.room.send(MSG.chat, m);
  }
  sendEmote(id: EmoteId): void {
    const m: EmoteSend = { id };
    this.room.send(MSG.emote, m);
  }
  leave(): void {
    void this.room?.leave();
  }
}
