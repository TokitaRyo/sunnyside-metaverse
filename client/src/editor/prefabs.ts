import { BUILDING_PREFABS } from "./prefabs.generated";
import type { Prefab } from "./prefabTypes";

/** sunnyside_16 系タイルセット上の座標→タイルID（scripts/lib/tilekit.mjs の tid と同じ式）。 */
const tid = (col: number, row: number): number => row * 64 + col;

/**
 * 草木・柵などの手作りパーツ。建物(BUILDING_PREFABS)と違い、実測タイルIDを直接指定して組む。
 * 地面の装飾(花・茂み)は "decoration_01"（floor＝常にキャラより下）、
 * 通り抜け判定が要る門は "walls"（ysort＝足元Yで前後判定）に置く。
 */
const HAND_PREFABS: Prefab[] = [
  {
    id: "flower-patch",
    label: "花壇（小）",
    category: "nature",
    w: 3,
    h: 3,
    tiles: [
      { layer: "decoration_01", dx: 0, dy: 0, id: tid(31, 1) },
      { layer: "decoration_01", dx: 1, dy: 0, id: tid(34, 2) },
      { layer: "decoration_01", dx: 2, dy: 0, id: tid(31, 2) },
      { layer: "decoration_01", dx: 0, dy: 1, id: tid(34, 1) },
      { layer: "decoration_01", dx: 1, dy: 1, id: tid(31, 3) },
      { layer: "decoration_01", dx: 2, dy: 1, id: tid(34, 3) },
      { layer: "decoration_01", dx: 1, dy: 2, id: tid(34, 2) },
    ],
  },
  {
    id: "bush-cluster",
    label: "茂み（3株）",
    category: "nature",
    w: 3,
    h: 2,
    tiles: [
      { layer: "decoration_01", dx: 0, dy: 1, id: tid(27, 1) },
      { layer: "decoration_01", dx: 1, dy: 0, id: tid(28, 2) },
      { layer: "decoration_01", dx: 2, dy: 1, id: tid(29, 1) },
    ],
  },
  {
    id: "tree-cluster",
    label: "木立（3本）",
    category: "nature",
    w: 4,
    h: 3,
    tiles: [],
    objects: [
      { sprite: "spr_deco_tree_01", dx: 8, dy: 8, sort: "y", byOff: 34, hit: [12, 8], hxOff: 16, frame: 0 },
      { sprite: "spr_deco_tree_01", dx: 40, dy: 24, sort: "y", byOff: 34, hit: [12, 8], hxOff: 16, frame: 1 },
      { sprite: "spr_deco_tree_01", dx: 16, dy: 38, sort: "y", byOff: 34, hit: [12, 8], hxOff: 16, frame: 2 },
    ],
  },
  {
    id: "rock-cluster",
    label: "岩（2個）",
    category: "nature",
    w: 2,
    h: 1,
    tiles: [],
    objects: [
      { sprite: "rock", dx: 4, dy: 4, sort: "y", byOff: 10 },
      { sprite: "rock", dx: 18, dy: 4, sort: "y", byOff: 10 },
    ],
  },
  {
    id: "gate",
    label: "正門（石垣＋木戸）",
    category: "fence",
    w: 6,
    h: 1,
    tiles: [
      { layer: "walls", dx: 0, dy: 0, id: tid(44, 1) },
      { layer: "walls", dx: 1, dy: 0, id: tid(45, 1) },
      { layer: "walls", dx: 2, dy: 0, id: tid(45, 2) },
      { layer: "walls", dx: 3, dy: 0, id: tid(46, 2) },
      { layer: "walls", dx: 4, dy: 0, id: tid(46, 1) },
      { layer: "walls", dx: 5, dy: 0, id: tid(47, 1) },
    ],
    collision: [
      { dx: 0, dy: 0 },
      { dx: 1, dy: 0 },
      { dx: 4, dy: 0 },
      { dx: 5, dy: 0 },
    ],
  },
];

export const PREFABS: Prefab[] = [...BUILDING_PREFABS, ...HAND_PREFABS];
export const PREFAB_CATEGORY_LABEL: Record<Prefab["category"], string> = {
  building: "建物",
  nature: "自然物",
  fence: "柵・門",
};
export const PREFAB_CATEGORY_ORDER: Prefab["category"][] = ["building", "nature", "fence"];
