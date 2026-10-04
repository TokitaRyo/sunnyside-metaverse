import type { MapSpriteDef, ObjectDef } from "../config";

// scripts/import-gm-room.mjs と同じ規則（新しく置いた物が、取り込み済みの物と同じ扱いになるように）

/** 影・床に敷くものは「キャラより下」に描く */
const FLOOR_SPRITES = /shadow|charactershadow/;

/** 当たり判定の初期値（足元中央を基準にした 幅×高さ px）。無ければ null */
export function defaultHit(name: string, def: MapSpriteDef): [number, number] | null {
  if (def.tiles?.hit) return [def.tiles.hit.w, def.tiles.hit.h];
  if (name === "spr_deco_tree_01" || name === "spr_deco_tree_02") return [12, 8];
  if (/barrel|crate|chest|jar_0|well|anvil|firepit|campfire|minecart|sidetable|trough|chair/.test(name)) {
    return [Math.max(6, Math.min(def.fw - 2, 14)), 6];
  }
  return null;
}

/** 原点(x,y)に置く新しい配置物のデータを作る */
export function makeObject(name: string, def: MapSpriteDef, x: number, y: number): ObjectDef {
  // 足元Y: 原点から見た下端。キャラ(96x64)は原点が体の中央なので原点+8
  const isChar = def.fw === 96 && def.fh === 64;
  const by = isChar ? y + 8 : y + (def.fh - def.oy);
  const o: ObjectDef = { sprite: name, x, y, sort: FLOOR_SPRITES.test(name) ? "floor" : "y", by };
  const hit = defaultHit(name, def);
  if (hit) {
    o.hit = hit;
    o.hx = x + (def.tiles?.hit ? def.tiles.hit.dx : def.fw / 2 - def.ox);
  }
  return o;
}
