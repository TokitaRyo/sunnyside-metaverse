/**
 * 公式マップ(sunnyside_world_example)から建物をタイルごと切り出して、
 * マップエディタの「パーツ」1つぶんのデータ(client/src/editor/prefabs.generated.ts)を書き出す。
 *   node scripts/gen-prefabs.mjs
 *
 * 矩形は reference/crop_*.png で目視確認して実測したもの（建物ぴったりに絞ってある。
 * 隣接する川・崖・切り株ごと持ってくると継ぎ接ぎに見えるため）。
 */
import { readFileSync, writeFileSync } from "node:fs";

const SRC_MAP = "reference/map-backups/map.20260927-133146.pre-school-map.json";
const OUT = "client/src/editor/prefabs.generated.ts";

const src = JSON.parse(readFileSync(SRC_MAP, "utf8"));
const TS = 16;

const BUILDINGS = [
  { id: "house-blue", label: "家（青・大）", rect: { x: 39, y: 24, w: 7, h: 7 } },
  { id: "house-red", label: "家（赤・小）", rect: { x: 32, y: 19, w: 5, h: 6 } },
  { id: "house-purple", label: "家（紫・中）", rect: { x: 13, y: 26, w: 6, h: 6 } },
];

// 建物本体の矩形とは別に、その建物にひもづく配置物(煙突の煙など)を手動で対応づける。
// { sprite, at:[絶対px,絶対px] } で元マップ上の1個を厳密に特定する。
const LINKED_OBJECTS = {
  "house-red": [{ sprite: "chimneysmoke_04", at: [531, 308] }],
};

function extractBuilding({ id, label, rect }) {
  const tiles = [];
  for (const layer of src.tileLayers) {
    if (layer.mode === "top") continue; // 雲レイヤーは建物と無関係
    // forest(32px)など tileSize が違うレイヤーは dx/dy の単位(16pxマス)が合わないので対象外
    if (src.tilesets[layer.tileset].tileSize !== TS) continue;
    for (let ry = 0; ry < rect.h; ry++) {
      const row = layer.data[rect.y + ry];
      if (!row) continue;
      for (let rx = 0; rx < rect.w; rx++) {
        const v = row[rect.x + rx];
        if (v >= 0) tiles.push({ layer: layer.name, dx: rx, dy: ry, id: v });
      }
    }
  }
  const originPx = { x: rect.x * TS, y: rect.y * TS };
  const objects = (LINKED_OBJECTS[id] ?? []).flatMap(({ sprite, at }) => {
    const o = src.objects.find((x) => x.sprite === sprite && Math.abs(x.x - at[0]) < 1 && Math.abs(x.y - at[1]) < 1);
    if (!o) return [];
    const rec = {
      sprite: o.sprite,
      dx: o.x - originPx.x,
      dy: o.y - originPx.y,
      sort: o.sort,
      byOff: o.by - originPx.y,
    };
    if (o.sx !== undefined) rec.sx = o.sx;
    if (o.sy !== undefined) rec.sy = o.sy;
    if (o.angle !== undefined) rec.angle = o.angle;
    if (o.frame !== undefined) rec.frame = o.frame;
    if (o.speed !== undefined) rec.speed = o.speed;
    if (o.hit !== undefined) rec.hit = o.hit;
    if (o.hx !== undefined) rec.hxOff = o.hx - originPx.x;
    return [rec];
  });
  // 当たり判定: 建物は下2マス(入口の土間)だけ歩けるようにし、それ以外(壁・屋根)は塞ぐ。
  // 元データにタイルごとの正確な当たり判定は無いので簡易ルール（gen-school-map.mjs と同じ考え方）。
  const collision = [];
  for (let cy = 0; cy < rect.h - 2; cy++) for (let cx = 0; cx < rect.w; cx++) collision.push({ dx: cx, dy: cy });

  return { id, label, category: "building", w: rect.w, h: rect.h, tiles, collision, objects };
}

const prefabs = BUILDINGS.map(extractBuilding);

const body = JSON.stringify(prefabs, null, 2);
const out = `// 自動生成: node scripts/gen-prefabs.mjs で作り直せます。手で編集しないでください。
import type { Prefab } from "./prefabTypes";

export const BUILDING_PREFABS: Prefab[] = ${body};
`;
writeFileSync(OUT, out);
console.log(`wrote ${OUT}: ${prefabs.length} 件 (${prefabs.map((p) => `${p.id}:${p.tiles.length}tiles`).join(", ")})`);
