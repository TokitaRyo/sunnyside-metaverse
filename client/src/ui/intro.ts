/**
 * 入室の演出（宇宙 → 惑星 → 衛星からの映像 → ゲーム画面）の時間割。ms。入室画面(DOM)とゲーム画面(カメラ)で共有する。
 *
 *  0            : パネル・ロゴが消え、惑星に向かって降下を始める（Join.dive）
 *  DIVE_FADE_AT : 入室画面全体が消え始め、ゲーム画面全体を衛星映像のように見せる
 *  INTRO_HOLD   : カメラが降下（ズームイン）を始める（WorldScene）
 *  +INTRO_ZOOM  : 自分のキャラのところまで降りて、操作できるようになる
 */
export const DIVE_FADE_AT_MS = 1500;
export const INTRO_HOLD_MS = 1900;
export const INTRO_ZOOM_MS = 2800;
