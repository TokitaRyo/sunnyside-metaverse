import { map, type MapSpriteDef } from "../config";
import type { Prefab } from "./prefabTypes";

/** 地形そのもののレイヤー（海・雲・地面）。パーツを物にするときは含めない（物の下に地面の四角が付いてきてしまうため） */
const TERRAIN_LAYERS = new Set(["sea", "clouds_02", "land"]);

/** パーツ(プレハブ)を「1つの物」として置くための絵の定義。タイルを下のレイヤーから順に貼り合わせる */
export function prefabSpriteDef(pf: Prefab): MapSpriteDef {
  const TS = map.tileSize;
  const layers = map.tileLayers ?? [];
  const order = (name: string) => layers.findIndex((l) => l.name === name);
  const parts: NonNullable<MapSpriteDef["tiles"]>["parts"] = [];
  const tiles = pf.tiles
    .filter((t) => {
      const l = layers[order(t.layer)];
      return l && l.mode !== "top" && !TERRAIN_LAYERS.has(l.name) && l.tileset && map.tilesets?.[l.tileset]?.tileSize === TS;
    })
    .sort((a, b) => order(a.layer) - order(b.layer));
  for (const t of tiles) parts.push({ tileset: layers[order(t.layer)].tileset, id: t.id, x: t.dx * TS, y: t.dy * TS });
  const fw = pf.w * TS, fh = pf.h * TS;
  const tiled: NonNullable<MapSpriteDef["tiles"]> = { parts, prefab: pf.id };
  if (pf.collision?.length) {
    const xs = pf.collision.map((c) => c.dx), ys = pf.collision.map((c) => c.dy);
    const x0 = Math.min(...xs), x1 = Math.max(...xs), y0 = Math.min(...ys);
    const w = (x1 - x0 + 1) * TS;
    // 足元(下端)を基準にした当たり判定。判定の最上段から足元までの高さにする
    tiled.hit = { w, h: (pf.h - y0) * TS, dx: x0 * TS + w / 2 - fw / 2 };
  }
  return { file: "", fw, fh, frames: 1, fps: 0, ox: fw / 2, oy: fh, catalog: true, tiles: tiled };
}

/** そのパーツが床に敷くだけのもの(花壇など)か。全部「キャラより下」のレイヤーなら true */
export function prefabIsFloorOnly(pf: Prefab): boolean {
  const layers = map.tileLayers ?? [];
  const used = pf.tiles.map((t) => layers.find((l) => l.name === t.layer)).filter((l) => l && l.mode !== "top" && !TERRAIN_LAYERS.has(l.name));
  return used.length > 0 && used.every((l) => l!.mode === "floor") && !pf.collision?.length;
}
