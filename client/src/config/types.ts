export interface AnimDef {
  frameRate: number;
  repeat: number;
  frames: number;
}

export interface CharacterDef {
  dir: string;
  layered: boolean;
  layerOrder?: string[];
  hairOptions?: string[];
  fileTemplate: string;
  actions: Record<string, AnimDef>;
}

export interface ElementDef {
  file: string;
  /** frameWidth があればアニメ（スプライトシート）、無ければ静止画 */
  frameWidth?: number;
  frameHeight?: number;
  frames?: number;
  frameRate?: number;
  repeat?: number;
  width?: number;
  height?: number;
}

export interface SpritesJson {
  meta: {
    frameWidth: number;
    frameHeight: number;
    origin: { x: number; y: number };
    bodyBox: { x: number; y: number; w: number; h: number };
  };
  characters: Record<string, CharacterDef>;
  elements: Record<string, ElementDef>;
}

export interface TilesetJson {
  image: string;
  tileSize: number;
  columns: number;
  rows: number;
  tileCount: number;
  emptyTile: number;
  autotileGroups: Record<string, { fill: number; tiles: number[] }>;
}

export interface PropDef {
  sprite: string;
  x: number;
  y: number;
  collide?: boolean;
  /** 当たり判定の大きさ(px)。足元中央が基準。省略時は 12×8 */
  hitbox?: { w: number; h: number };
}

export interface MobDef {
  sprite: string;
  action: string;
  x: number;
  y: number;
  flipX?: boolean;
  name?: string;
  hair?: string;
}

/** 任意枚数のタイル層で使うタイルセット（反転・回転は拡張タイルセットに焼き込み済み） */
export interface MapTilesetDef {
  image: string;
  tileSize: number;
  columns: number;
}

/**
 * mode: floor = キャラより下 / ysort = 1行ごとに足元Yでキャラと前後判定 / top = 最前面(雲など)
 * data の行列数は width*tileSize / tileset.tileSize（森の32pxタイルなら半分）。空きは -1。
 */
export interface TileLayerDef {
  name: string;
  tileset: string;
  mode: "floor" | "ysort" | "top";
  data: number[][];
}

/** 配置物用のスプライトシート（フレームを横一列に並べたもの）。ox,oy はスプライトの原点(px) */
export interface MapSpriteDef {
  file: string;
  fw: number;
  fh: number;
  frames: number;
  fps: number;
  ox: number;
  oy: number;
  /** true = エディタで置くための見本(カタログ)。配置物で使われていない限り、ゲームは読み込まない */
  catalog?: boolean;
}

/** ピクセル座標に置く配置物。by=足元のY(前後判定用)。hit=当たり判定(幅,高さ px)、hx=その中心X */
/** 話しかけられる物（NPC）のセリフ。lines の1要素が1ページ */
export interface NpcDef {
  /** 会話ウィンドウに出す名前（省略可） */
  name?: string;
  lines: string[];
}

export interface ObjectDef {
  sprite: string;
  x: number;
  y: number;
  sort: "floor" | "y";
  by: number;
  sx?: number;
  sy?: number;
  angle?: number;
  frame?: number;
  speed?: number;
  hit?: [number, number];
  hx?: number;
  /** あれば、近づくと「話す」が選べる */
  npc?: NpcDef;
  /** 所属する GroupDef.id（グループの一部として、まとめて選択・移動・削除される） */
  group?: string;
}

/** このマス(x,y)に足元が乗ったら (toX,toY) へワープする（ブラックアウト演出つき） */
export interface WarpDef {
  x: number;
  y: number;
  toX: number;
  toY: number;
}

/**
 * タイルとして貼り付けたもの（家・島・コピーした範囲など）を「1つの物」として扱うための記録。
 * エディタ専用で、ゲーム本体は読まない。x,y は左上のマス。tiles/collision/warps は左上からの相対位置。
 * prev は「置く前の値」で、移動・削除のとき元に戻すのに使う。
 */
export interface GroupDef {
  id: string;
  label: string;
  x: number;
  y: number;
  w: number;
  h: number;
  tiles: { layer: string; dx: number; dy: number; id: number; prev: number }[];
  /** v=グループが入れる当たり判定の値(1=塞ぐ/0=歩ける)、prev=置く前の値 */
  collision: { dx: number; dy: number; v: number; prev: number }[];
  warps?: { dx: number; dy: number; toX: number; toY: number }[];
}

export interface MapJson {
  name: string;
  tileset: string;
  tileSize: number;
  width: number;
  height: number;
  spawn: { x: number; y: number };
  layers: {
    ground: number[][];
    deco: number[][];
    overhead: number[][];
    collision: number[][];
  };
  props: PropDef[];
  mobs: MobDef[];
  /** 以下は任意（GameMakerルーム由来の大きなマップ用）。あれば layers.ground/deco/overhead の代わりに描画する */
  tilesets?: Record<string, MapTilesetDef>;
  tileLayers?: TileLayerDef[];
  sprites?: Record<string, MapSpriteDef>;
  objects?: ObjectDef[];
  warps?: WarpDef[];
  groups?: GroupDef[];
}
