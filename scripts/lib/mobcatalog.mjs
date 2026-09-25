// エディタで置けるモブの「カタログ」を map.json の sprites に足す。
// マップで実際に使っていない種類も登録しておく（catalog:true）。ゲーム側は使われていないカタログ項目を読み込まない。
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { PNG } from "pngjs";
import { buildGmSprite } from "./gm.mjs";

export const GOBLIN_ACTIONS = ["idle", "waiting", "walking", "run", "jump", "roll", "doing", "carry", "attack", "hurt", "death", "swimming", "axe", "mining", "hammering", "dig", "watering", "casting", "reeling", "caught"];
export const SKELETON_ACTIONS = ["idle", "walk", "attack", "jump", "hurt", "death"];
export const ANIMALS = ["cow", "sheep_01", "pig_01", "chicken_01", "duck_01", "bird_01"];
/** 人間NPCとして置ける動作（プレイヤーと同じ base+髪+tools の3枚重ねを1枚に合成する） */
export const HUMAN_ACTIONS = ["idle", "waiting", "walk", "carry", "doing"];
export const HAIRS = ["bowlhair", "curlyhair", "longhair", "mophair", "shorthair", "spikeyhair"];
export const SHADOW = "spr_deco_charactershadow";

/** 素材(kit)の人間レイヤーを重ねて1枚のシートにする。フレームサイズ 96x64、原点は体の中央(48,32) */
function buildHuman(hair, action, sprites) {
  const meta = sprites.characters.human.actions[action];
  const read = (layer) => PNG.sync.read(readFileSync(`client/public/assets/characters/human/${layer}/${action}.png`));
  const layers = ["base", hair, "tools"].map(read);
  const w = 96 * meta.frames, h = 64;
  const out = new PNG({ width: w, height: h });
  out.data.fill(0);
  for (const img of layers) {
    if (img.width !== w || img.height !== h) throw new Error(`human/${action}: 想定外のサイズ ${img.width}x${img.height} (期待 ${w}x${h})`);
    for (let i = 0; i < out.data.length; i += 4) {
      const a = img.data[i + 3] / 255;
      if (!a) continue;
      const ba = out.data[i + 3] / 255;
      const oa = a + ba * (1 - a);
      for (let k = 0; k < 3; k++) out.data[i + k] = (img.data[i + k] * a + out.data[i + k] * ba * (1 - a)) / oa;
      out.data[i + 3] = oa * 255;
    }
  }
  const name = `human_${hair}_${action}`;
  mkdirSync("client/public/assets/gm", { recursive: true });
  writeFileSync(`client/public/assets/gm/${name}.png`, PNG.sync.write(out));
  return [name, { file: `gm/${name}.png`, fw: 96, fh: 64, frames: meta.frames, fps: meta.frameRate, ox: 48, oy: 32 }];
}

/** map.sprites にカタログ項目を追加する（既にあるものは触らない）。追加した数を返す。 */
export function addMobCatalog(map, GM) {
  const sprites = JSON.parse(readFileSync("client/src/config/sprites.json", "utf8"));
  map.sprites ??= {};
  let added = 0;
  const add = (name, def) => {
    if (map.sprites[name]) return;
    map.sprites[name] = { ...def, catalog: true };
    added++;
  };
  const gm = (name) => add(name, buildGmSprite(GM, name));
  for (const a of GOBLIN_ACTIONS) gm(`spr_${a}`);
  for (const a of SKELETON_ACTIONS) gm(`skeleton_${a}`);
  for (const a of ANIMALS) gm(`spr_deco_${a}`);
  gm(SHADOW);
  for (const hair of HAIRS) for (const action of HUMAN_ACTIONS) {
    const [name, def] = buildHuman(hair, action, sprites);
    add(name, def);
  }
  return added;
}
