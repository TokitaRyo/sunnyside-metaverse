import Phaser from "phaser";
import { EMOTES, LOCOMOTION } from "@metaverse/shared";
import { map, sprites } from "../config";
import { queueStampIcons } from "./stampIcons";

export const ASSET_BASE = `${import.meta.env.BASE_URL}assets/`;
export const TILES_KEY = "tiles";

const { frameWidth: FW, frameHeight: FH } = sprites.meta;

/** テクスチャ／アニメ共通キー */
export function charKey(kind: string, layer: string | null, action: string): string {
  return layer ? `${kind}/${layer}/${action}` : `${kind}/${action}`;
}
export const elementKey = (name: string) => `el/${name}`;
/** map.tilesets / map.sprites 由来のキー */
export const tilesetKey = (name: string) => `ts/${name}`;
export const objectKey = (name: string) => `obj/${name}`;

/** 人間が重ねるレイヤー名（base → hair → tools） */
export function humanLayers(hair: string): string[] {
  const order = sprites.characters.human.layerOrder ?? ["base", "hair", "tools"];
  return order.map((l) => (l === "hair" ? hair : l));
}

/** プレイヤー(人間)が使うアクション＝移動＋エモート */
export function playerActions(): string[] {
  const set = new Set<string>(LOCOMOTION);
  for (const e of Object.values(EMOTES)) set.add(e.action);
  return [...set];
}

function pathOf(kind: string, layer: string | null, action: string): string {
  return sprites.characters[kind].fileTemplate.replace("{layer}", layer ?? "").replace("{action}", action);
}

/** map.json とプレイヤー仕様から、実際に必要な素材だけを読み込む（フレーム数は必ず sprites.json から）。 */
export function queueAssets(load: Phaser.Loader.LoaderPlugin): void {
  load.setPath(ASSET_BASE);
  if (map.tileLayers) {
    // 任意枚数のタイル層を使うマップ: 使うタイルセットと配置物スプライトを map.json の定義どおりに読む
    for (const [name, ts] of Object.entries(map.tilesets ?? {})) load.image(tilesetKey(name), ts.image);
    // カタログ項目(エディタ用の見本)は、実際に配置されているものだけ読む。エディタ(?edit=1)では全部読む
    const used = new Set((map.objects ?? []).map((o) => o.sprite));
    const editing = import.meta.env.DEV && new URLSearchParams(location.search).has("edit");
    for (const [name, sp] of Object.entries(map.sprites ?? {})) {
      if (sp.crop) continue; // タイルセットの切り出しは、読み込み後に PreloadScene で作る
      if (sp.catalog && !used.has(name) && !editing) continue;
      load.spritesheet(objectKey(name), sp.file, { frameWidth: sp.fw, frameHeight: sp.fh });
    }
    // 出店ごとのスタンプの絵柄（1枚のシート）。キーアイテムが使うときだけ読む
    if ((map.keyItems ?? []).some((k) => k.icon)) queueStampIcons(load);
  } else {
    load.image(TILES_KEY, "tilesets/sunnyside_16.png");
  }

  // 人間: プレイヤー全アクション × 全レイヤー（髪6種）
  const human = sprites.characters.human;
  const allLayers = ["base", ...(human.hairOptions ?? []), "tools"];
  const playerActs = new Set(playerActions());
  const loadHuman = (layer: string, action: string) => {
    if (!human.actions[action]) return;
    load.spritesheet(charKey("human", layer, action), pathOf("human", layer, action), { frameWidth: FW, frameHeight: FH });
  };
  // プレイヤーが使う動作は、他の人が選びうる全髪型ぶん必要
  for (const layer of allLayers) for (const action of playerActs) loadHuman(layer, action);
  // モブだけが使う動作（釣り・水泳など）は、そのモブの髪型ぶんだけ読む（リクエスト数を減らす）
  const mobOnly = new Set<string>();
  for (const m of map.mobs) {
    if (m.sprite !== "human" || playerActs.has(m.action)) continue;
    for (const layer of ["base", m.hair ?? human.hairOptions![0], "tools"]) {
      const k = `${layer}/${m.action}`;
      if (mobOnly.has(k)) continue;
      mobOnly.add(k);
      loadHuman(layer, m.action);
    }
  }

  // モブ: map.json で使われる (種類, アクション) のみ
  const mobActions = new Map<string, Set<string>>();
  for (const m of map.mobs) {
    if (m.sprite === "human") continue;
    if (!mobActions.has(m.sprite)) mobActions.set(m.sprite, new Set());
    mobActions.get(m.sprite)!.add(m.action);
  }
  for (const [kind, actions] of mobActions) {
    for (const action of actions) {
      load.spritesheet(charKey(kind, null, action), pathOf(kind, null, action), { frameWidth: FW, frameHeight: FH });
    }
  }

  // 装飾: frameWidth があればアニメ、無ければ静止画
  for (const name of new Set(map.props.map((p) => p.sprite))) {
    const def = sprites.elements[name];
    if (def.frameWidth) {
      load.spritesheet(elementKey(name), def.file, { frameWidth: def.frameWidth, frameHeight: def.frameHeight! });
    } else {
      load.image(elementKey(name), def.file);
    }
  }
}

/** ロードされたテクスチャすべてにアニメを登録する。 */
export function createAnimations(scene: Phaser.Scene): void {
  const anims = scene.anims;
  const reg = (key: string, frames: number, frameRate: number, repeat: number) => {
    if (anims.exists(key) || !scene.textures.exists(key)) return;
    anims.create({
      key,
      frames: anims.generateFrameNumbers(key, { start: 0, end: frames - 1 }),
      frameRate,
      repeat,
    });
  };

  for (const [kind, def] of Object.entries(sprites.characters)) {
    const layers: (string | null)[] = def.layered ? ["base", ...(def.hairOptions ?? []), "tools"] : [null];
    for (const layer of layers) {
      for (const [action, a] of Object.entries(def.actions)) {
        reg(charKey(kind, layer, action), a.frames, a.frameRate, a.repeat);
      }
    }
  }
  for (const [name, def] of Object.entries(sprites.elements)) {
    if (def.frameWidth && def.frames) reg(elementKey(name), def.frames, def.frameRate ?? 6, def.repeat ?? -1);
  }
  // 配置物（速度は個体ごとに play 時に上書きする）
  for (const [name, sp] of Object.entries(map.sprites ?? {})) {
    if (sp.frames > 1) reg(objectKey(name), sp.frames, sp.fps, -1);
  }
}
