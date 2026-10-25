// クライアント／サーバー共通の定数。数値の根拠は SPEC.md 第3・4章を参照。

export const TILE_SIZE = 16;

/** 素材のフレームサイズ（全キャラ共通・実測値） */
export const FRAME_W = 96;
export const FRAME_H = 64;
/** 足元を原点にするための origin（実測値） */
export const CHAR_ORIGIN_X = 0.5;
export const CHAR_ORIGIN_Y = 0.625;
/** 足元の当たり判定サイズ */
export const FOOT_W = 12;
export const FOOT_H = 8;

/** 移動速度 (px/s) */
export const WALK_SPEED = 64;
export const RUN_SPEED = 112;
export const MAX_SPEED = RUN_SPEED;

/** クライアント→サーバー 送信レート */
export const SEND_RATE_HZ = 15;
export const SEND_INTERVAL_MS = 1000 / SEND_RATE_HZ;
/** サーバー patchRate (ms) = 20Hz */
export const PATCH_RATE_MS = 50;

/** 同時に入れる人数。150人まで試験済み（docs/decisions.md）。環境変数 MAX_CLIENTS で変えられる */
export const MAX_CLIENTS = 150;
export const ROOM_NAME = "main";

export const NAME_MAX = 12;
export const CHAT_MAX = 140;
/** 1人あたり毎秒2通まで */
export const CHAT_RATE_PER_SEC = 2;
export const CHAT_BUBBLE_MS = 4000;
export const CHAT_LOG_MAX = 50;

/** 定型文チャット（荒らしが増えて自由な書き込みを止めているときも使える。番号で送る。並び順を変えない・足すときは末尾に） */
export const PHRASES: readonly string[] = [
  "こんにちは！",
  "ありがとう！",
  "すごい！",
  "たのしいね！",
  "いっしょにあそぼう！",
  "おなかすいた～",
  "おめでとう！",
  "ここ どこかな？",
  "いいね！",
  "またね！",
];

/** 速度チェックの許容係数（SPEC 4.1） */
export const SPEED_TOLERANCE = 1.5;
/** 溜められる移動量（バースト対策）の上限を何秒分にするか */
export const SPEED_BUDGET_SEC = 0.5;

export const HAIRS = ["bowlhair", "curlyhair", "longhair", "mophair", "shorthair", "spikeyhair"] as const;
export type Hair = (typeof HAIRS)[number];

export const LOCOMOTION = ["idle", "walk", "run"] as const;

/** エモートID → 再生するキャラアクション。waiting のみトグル(ループ)。キーボードの 1〜6 は、この並び順 */
export const EMOTES = {
  jump: { action: "jump", label: "ジャンプ", loop: false },
  roll: { action: "roll", label: "転がる", loop: false },
  wave: { action: "doing", label: "手を振る", loop: false },
  sword: { action: "attack", label: "剣", loop: false, bubble: "⚔️" },
  // 絵文字(bubble)が頭の上に出る前向きなエモート（学校行事の場なので、攻撃・やられるは入れない）
  heart: { action: "jump", label: "ハート", loop: false, bubble: "💖" },
  cheer: { action: "doing", label: "やったー", loop: false, bubble: "🎉" },
} as const;
export type EmoteId = keyof typeof EMOTES;
/** そのエモートで頭の上に出す絵文字（無ければ undefined） */
export const emoteBubble = (id: EmoteId): string | undefined => (EMOTES[id] as { bubble?: string }).bubble;
export const EMOTE_IDS = Object.keys(EMOTES) as EmoteId[];

/** Player.action に入りうる値 */
export type PlayerAction = (typeof LOCOMOTION)[number] | EmoteId;
export const PLAYER_ACTIONS: readonly string[] = [...LOCOMOTION, ...EMOTE_IDS];

/**
 * 利用規約・データの取り扱いの版。文面（client/src/ui/terms.ts）を変えたら、この日付を新しくする。
 * サーバーは、この版に同意した人だけ入室させる（変えると全員がもう一度同意する）。
 */
export const CONSENT_VERSION = "2026-10-20-2";
/** 集めたデータ（チャット・滞在記録）を残す日数。過ぎたものはサーバーが自動で消す */
export const DATA_RETENTION_DAYS = 30;
/** 規約に書く問い合わせ先。運営の実際の連絡先に直す */
export const OPERATOR_CONTACT = "文化祭の運営係（会場の受付、または担当の先生）";
/** 規約に書くメールアドレス（問い合わせ・記録の確認や削除の依頼） */
export const OPERATOR_EMAIL = "s2301088@sendai-nct.jp";