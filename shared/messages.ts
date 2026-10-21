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
/** 入室時にクライアントが送る情報（Colyseus の join options） */
export interface JoinOptions {
  name: string;
  hair: string;
  /** 同意した規約の版（CONSENT_VERSION と同じでないと入室できない） */
  consent: string;
  /** ブラウザに保存したランダムな訪問者ID（再訪を数えるため。個人は特定しない） */
  vid: string;
  /** 見た目。encodeLook() の文字列（サーバーが形を確かめる）。無ければ髪型だけ */
  look?: string;
  /** touch=スマホ・タブレット, desktop=パソコン */
  device: "touch" | "desktop";
}
/** 集めたスタンプの数（出店めぐりの達成度の集計用） */
export interface StampsSend {
  count: number;
  total: number;
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
  stamps: "stamps",
} as const;
