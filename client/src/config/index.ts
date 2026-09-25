import spritesJson from "./sprites.json";
import tilesetJson from "./tileset.json";
import mapJson from "./map.json";
import type { MapJson, SpritesJson, TilesetJson } from "./types";
import { validateMap } from "./validate";

// config/*.json が素材と配置の唯一の真実。コードに数値・パスを直書きしない。
export const sprites = spritesJson as unknown as SpritesJson;
export const tileset = tilesetJson as unknown as TilesetJson;
export const map = mapJson as unknown as MapJson;

export const mapErrors = validateMap(map, sprites, tileset);
if (mapErrors.length) {
  console.error(`[map.json] ${mapErrors.length} 件の問題があります:\n - ${mapErrors.join("\n - ")}`);
}

export * from "./types";
