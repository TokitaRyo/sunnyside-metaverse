import { Client, Callbacks, type Room } from "@colyseus/sdk";
import {
  MSG,
  ROOM_NAME,
  MainRoomState,
  type ChatBroadcast,
  type ChatDelete,
  type ChatState,
  type ChatSend,
  type CorrectMessage,
  type EmoteBroadcast,
  type EmoteId,
  type EmoteSend,
  type JoinOptions,
  type ModNotice,
  type MoveMessage,
  type PhraseSend,
  type ReportSend,
  type StampsSend,
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
  /** チャットの停止・再開（運営の操作）。入室時にも届く */
  onChatState(msg: ChatState): void;
  /** 運営が消した発言 */
  onChatDelete(msg: ChatDelete): void;
  /** 自動の対応（書き込みが送れなかった理由・通報の受付）。本人にだけ届く */
  onModNotice?(msg: ModNotice): void;
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

  async join(name: string, hair: string, extra: Pick<JoinOptions, "consent" | "vid" | "device" | "look" | "venue">, h: NetHandlers): Promise<void> {
    const client = new Client(serverUrl());
    // 部屋はサーバーが起動時に1つだけ作る。join のみ使い、満員なら断られる
    let room: NetRoom;
    try {
      room = (await client.join(ROOM_NAME, { name, hair, ...extra } satisfies JoinOptions, MainRoomState)) as NetRoom;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (/locked|full|no rooms/i.test(msg)) throw new Error("満員です。しばらくしてからもう一度お試しください");
      throw e;
    }
    this.attach(room, h);
  }

  /** 管理者のショー画面用: 観客として部屋につなぐ（プレイヤーとしては出ない）。token は /admin/api/spectator-token でもらう */
  async joinSpectator(token: string, h: NetHandlers): Promise<void> {
    const client = new Client(serverUrl());
    const room = (await client.join(ROOM_NAME, { spectator: token }, MainRoomState)) as NetRoom;
    this.attach(room, h);
  }

  private attach(room: NetRoom, h: NetHandlers): void {
    this.room = room;

    const cb = Callbacks.get(room);
    cb.onAdd("players", (player, sessionId) => {
      h.onPlayerAdd(player, sessionId);
      cb.onChange(player, () => h.onPlayerChange(player, sessionId));
    });
    cb.onRemove("players", (player, sessionId) => h.onPlayerRemove(player, sessionId));

    room.onMessage(MSG.chat, (m: ChatBroadcast) => h.onChat(m));
    room.onMessage(MSG.chatState, (m: ChatState) => h.onChatState(m));
    room.onMessage(MSG.chatDelete, (m: ChatDelete) => h.onChatDelete(m));
    room.onMessage(MSG.modNotice, (m: ModNotice) => h.onModNotice?.(m));
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
  /** 定型文チャット（PHRASES の番号） */
  sendPhrase(id: number): void {
    const m: PhraseSend = { id };
    this.room.send(MSG.phrase, m);
  }
  /** この人を通報する（別々の人から一定数たまると、自動でチャットが止まる） */
  sendReport(sessionId: string): void {
    const m: ReportSend = { sessionId };
    this.room.send(MSG.report, m);
  }
  sendEmote(id: EmoteId): void {
    const m: EmoteSend = { id };
    this.room.send(MSG.emote, m);
  }
  /** 集めたスタンプの数を、運営の集計用に知らせる */
  sendStamps(count: number, total: number): void {
    const m: StampsSend = { count, total };
    this.room.send(MSG.stamps, m);
  }
  leave(): void {
    void this.room?.leave();
  }
}
