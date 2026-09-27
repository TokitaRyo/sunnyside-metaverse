/** マップエディタの「パーツ」（複数タイル・複数レイヤー・配置物をまとめて1クリックで置ける単位）。 */

export interface PrefabTile {
  /** map.tileLayers[].name（レイヤーの並び順ではなく名前で対応づける） */
  layer: string;
  /** 置いた原点(左上マス)からのオフセット(マス) */
  dx: number;
  dy: number;
  id: number;
}

export interface PrefabCollision {
  dx: number;
  dy: number;
}

export interface PrefabObject {
  sprite: string;
  /** 原点(左上マスの左上px)からのオフセット(px) */
  dx: number;
  dy: number;
  sort: "floor" | "y";
  /** by(足元Yのオフセット, px) */
  byOff: number;
  sx?: number;
  sy?: number;
  angle?: number;
  frame?: number;
  speed?: number;
  hit?: [number, number];
  /** hx(当たり判定中心Xのオフセット, px) */
  hxOff?: number;
}

export interface Prefab {
  id: string;
  label: string;
  category: "building" | "nature" | "fence";
  /** フットプリント(マス) */
  w: number;
  h: number;
  tiles: PrefabTile[];
  collision?: PrefabCollision[];
  objects?: PrefabObject[];
}
