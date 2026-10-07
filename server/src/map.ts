import { readFileSync } from "node:fs";
import { FOOT_H, FOOT_W, TILE_SIZE } from "@metaverse/shared";

interface MapFile {
  tileSize: number;
  width: number;
  height: number;
  spawn: { x: number; y: number };
  layers: { collision: number[][] };
}

/** クライアントと同じ map.json を読む（配置データは1か所だけ）。 */
export function loadMap() {
  const url = new URL("../../client/src/config/map.json", import.meta.url);
  const raw = JSON.parse(readFileSync(url, "utf8")) as MapFile;
  const tile = raw.tileSize ?? TILE_SIZE;
  const collision = raw.layers.collision;
  return {
    pixelW: raw.width * tile,
    pixelH: raw.height * tile,
    /** スポーン地点（ピクセル・タイル中心） */
    spawn: { x: raw.spawn.x * tile + tile / 2, y: raw.spawn.y * tile + tile / 2 },
    isBlocked(px: number, py: number) {
      const c = Math.floor(px / tile);
      const r = Math.floor(py / tile);
      return collision[r]?.[c] === 1;
    },
    /** 足元(FOOT_W×FOOT_H)の矩形が、通れないタイルに1マスでも掛かるか。スポーン位置の判定に使う */
    isFootBlocked(px: number, py: number) {
      const l = px - FOOT_W / 2, r = px + FOOT_W / 2, t = py - FOOT_H, b = py;
      for (let row = Math.floor(t / tile); row <= Math.floor((b - 0.001) / tile); row++)
        for (let col = Math.floor(l / tile); col <= Math.floor((r - 0.001) / tile); col++) if (collision[row]?.[col] !== 0) return true;
      return false;
    },
    tile,
  };
}
export type GameMap = ReturnType<typeof loadMap>;
