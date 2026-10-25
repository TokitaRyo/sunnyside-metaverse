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
  /** 管理者のショー画面が「観客」として入るための短命トークン（管理用 API が発行。あれば、プレイヤーとしては数えない） */
  spectator?: string;
  /** 会場限定モードのときの、入室コード（会場の QR コードの URL に入っている）。サーバーが確かめる */
  venue?: string;
}
/** 集めたスタンプの数（出店めぐりの達成度の集計用） */
export interface StampsSend {
  count: number;
  total: number;
}
export interface EmoteSend {
  id: EmoteId;
}
/** 定型文チャット（番号で送る。PHRASES の並び順）。自由な書き込みが止まっているときも使える */
export interface PhraseSend {
  id: number;
}
/** 他の参加者の通報（運営がいなくても、複数の人からの通報で自動的に対応する） */
export interface ReportSend {
  sessionId: string;
}

/** S→C */
export interface ChatBroadcast {
  /** 記録の番号（管理ページが、この発言を選んで消すときに使う） */
  id?: number;
  sessionId: string;
  name: string;
  text: string;
  at: number;
}
export interface EmoteBroadcast {
  sessionId: string;
  id: EmoteId;
}
/** チャットの停止中かどうか（運営が管理ページで切り替える）。入室時と、切り替わったときに全員へ */
export interface ChatState {
  locked: boolean;
  /** true のあいだは、自由な書き込みを止めて、定型文だけにする（荒らしが増えたとき自動で切り替わる。運営が手動で切り替えることもできる） */
  phrases?: boolean;
}
/** 自動の対応（書き込みが送れなかった・チャットを止めた など）を、本人にだけ知らせる */
export interface ModNotice {
  code: "newcomer" | "muted" | "contact" | "badword" | "dup" | "fast" | "phrases" | "report-ok" | "report-ng" | "emote";
  text: string;
  /** あと何ミリ秒で、また書き込めるか（わかるとき） */
  retryMs?: number;
}
/** 運営が消した発言（番号）。参加者の画面のチャット欄からも消す */
export interface ChatDelete {
  ids: number[];
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
  chatState: "chatState",
  chatDelete: "chatDelete",
  phrase: "phrase",
  report: "report",
  modNotice: "modNotice",
} as const;
