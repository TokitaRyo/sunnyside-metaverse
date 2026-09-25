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

export const MAX_CLIENTS = 50;
export const ROOM_NAME = "main";

export const NAME_MAX = 12;
export const CHAT_MAX = 140;
/** 1人あたり毎秒2通まで */
export const CHAT_RATE_PER_SEC = 2;
export const CHAT_BUBBLE_MS = 4000;
export const CHAT_LOG_MAX = 50;

/** 速度チェックの許容係数（SPEC 4.1） */
export const SPEED_TOLERANCE = 1.5;
/** 溜められる移動量（バースト対策）の上限を何秒分にするか */
export const SPEED_BUDGET_SEC = 0.5;

export const HAIRS = ["bowlhair", "curlyhair", "longhair", "mophair", "shorthair", "spikeyhair"] as const;
export type Hair = (typeof HAIRS)[number];

export const LOCOMOTION = ["idle", "walk", "run"] as const;

/** エモートID → 再生するキャラアクション。waiting のみトグル(ループ) */
export const EMOTES = {
  jump: { action: "jump", label: "ジャンプ", loop: false },
  roll: { action: "roll", label: "転がる", loop: false },
  wave: { action: "doing", label: "手を振る", loop: false },
  sit: { action: "waiting", label: "座る", loop: true },
  attack: { action: "attack", label: "攻撃", loop: false },
  hurt: { action: "hurt", label: "やられる", loop: false },
} as const;
export type EmoteId = keyof typeof EMOTES;
export const EMOTE_IDS = Object.keys(EMOTES) as EmoteId[];

/** Player.action に入りうる値 */
export type PlayerAction = (typeof LOCOMOTION)[number] | EmoteId;
export const PLAYER_ACTIONS: readonly string[] = [...LOCOMOTION, ...EMOTE_IDS];
