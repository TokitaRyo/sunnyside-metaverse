import type { EmoteId } from "./constants";

/** C→S */
export interface MoveMessage {
  x: number;
  y: number;
  flipX: boolean;
  action: string;
}
export interface ChatSend {
  text: string;
}
export interface EmoteSend {
  id: EmoteId;
}

/** S→C */
export interface ChatBroadcast {
  sessionId: string;
  name: string;
  text: string;
  at: number;
}
export interface EmoteBroadcast {
  sessionId: string;
  id: EmoteId;
}
/** 速度超過などで棄却した際、本人にだけ正しい座標を返す。 */
export interface CorrectMessage {
  x: number;
  y: number;
}

export const MSG = {
  move: "move",
  chat: "chat",
  emote: "emote",
  correct: "correct",
} as const;
