import type { MapJson, SpritesJson, TilesetJson } from "./types";

/** SPEC 5.2: 起動時にmap.jsonを検証し、問題を全部列挙して返す。 */
export function validateMap(map: MapJson, sprites: SpritesJson, tileset: TilesetJson): string[] {
  const errors: string[] = [];
  const { width, height } = map;

  if (map.tileSize !== tileset.tileSize) {
    errors.push(`tileSize が tileset.json (${tileset.tileSize}) と一致しません: ${map.tileSize}`);
  }

  for (const name of ["ground", "deco", "overhead", "collision"] as const) {
    const layer = map.layers[name];
    if (!Array.isArray(layer)) {
      errors.push(`layers.${name} がありません`);
      continue;
    }
    if (layer.length !== height) {
      errors.push(`layers.${name} の行数が height(${height}) と不一致: ${layer.length}`);
    }
    layer.forEach((row, r) => {
      if (!Array.isArray(row) || row.length !== width) {
        errors.push(`layers.${name}[${r}] の列数が width(${width}) と不一致: ${row?.length}`);
        return;
      }
      if (name === "collision") return;
      row.forEach((id, c) => {
        if (!Number.isInteger(id) || id < -1 || id >= tileset.tileCount) {
          errors.push(`layers.${name}[${r}][${c}] のタイルID ${id} が範囲外 (-1, 0〜${tileset.tileCount - 1})`);
        }
      });
    });
  }

  // 任意項目: tileLayers / sprites / objects
  const tsets = map.tilesets ?? {};
  (map.tileLayers ?? []).forEach((l, i) => {
    const ts = tsets[l.tileset];
    if (!ts) {
      errors.push(`tileLayers[${i}] "${l.name}" のタイルセット "${l.tileset}" が tilesets にありません`);
      return;
    }
    const cols = Math.ceil((width * map.tileSize) / ts.tileSize);
    const rows = Math.ceil((height * map.tileSize) / ts.tileSize);
    if (l.data.length !== rows) errors.push(`tileLayers[${i}] "${l.name}" の行数が ${rows} と不一致: ${l.data.length}`);
    l.data.forEach((row, r) => {
      if (row.length !== cols) errors.push(`tileLayers[${i}] "${l.name}"[${r}] の列数が ${cols} と不一致: ${row.length}`);
      row.forEach((id, c) => {
        if (!Number.isInteger(id) || id < -1 || id > 65535) errors.push(`tileLayers[${i}] "${l.name}"[${r}][${c}] のタイルID ${id} が不正`);
      });
    });
  });
  (map.objects ?? []).forEach((o, i) => {
    if (!map.sprites?.[o.sprite]) errors.push(`objects[${i}].sprite "${o.sprite}" は map.sprites にありません`);
  });

  map.props.forEach((p, i) => {
    if (!sprites.elements[p.sprite]) errors.push(`props[${i}].sprite "${p.sprite}" は sprites.json の elements にありません`);
    if (p.x < 0 || p.y < 0 || p.x > width || p.y > height) errors.push(`props[${i}] (${p.x},${p.y}) がマップ外です`);
  });

  map.mobs.forEach((m, i) => {
    const def = sprites.characters[m.sprite];
    if (!def) {
      errors.push(`mobs[${i}].sprite "${m.sprite}" は sprites.json の characters にありません`);
      return;
    }
    if (!def.actions[m.action]) errors.push(`mobs[${i}] ${m.sprite} に action "${m.action}" はありません`);
    if (m.sprite === "human" && m.hair && !def.hairOptions?.includes(m.hair)) {
      errors.push(`mobs[${i}].hair "${m.hair}" は不正です (${def.hairOptions?.join(", ")})`);
    }
    if (m.x < 0 || m.y < 0 || m.x > width || m.y > height) errors.push(`mobs[${i}] (${m.x},${m.y}) がマップ外です`);
  });

  const { x, y } = map.spawn;
  if (map.layers.collision[y]?.[x] === 1) {
    errors.push(`spawn (${x},${y}) が collision の上にあります`);
  }
  if (x < 0 || y < 0 || x >= width || y >= height) errors.push(`spawn (${x},${y}) がマップ外です`);

  return errors;
}
