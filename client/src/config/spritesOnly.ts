import spritesJson from "./sprites.json";
import type { SpritesJson } from "./types";

/**
 * 素材（sprites.json）だけ。マップ（map.json。大きい）まで読み込みたくない小さなページ（管理者用のショー画面）が使う。
 * 通常は ./index の `sprites` と同じもの。
 */
export const sprites = spritesJson as unknown as SpritesJson;
