/**
 * 出店（屋台）を島に組み立てるための道具。scripts/stalls/*.mjs の配置と、build-stalls.mjs / preview-stall.mjs が共有する。
 *
 * 座標のきまり（配置関数の中では全部これ）:
 *   dx   = 島の草地の中心Xからのずれ(px)。右が正。草地は 192px 幅なので -96..+96
 *   foot = 草地の上端Yからの「足元」の距離(px)。下が正。草地は 128px 高さなので 0..128
 *   by   = 前後の判定に使う足元Y（草地の上端からの距離）。省略すると foot と同じ。大きいほど手前に描かれる
 * 人物のスプライト(96x64)は体が約16px四方。足元が foot で、体は foot-16..foot の範囲に出る。
 */
import { readFileSync } from "node:fs";
import { PNG } from "pngjs";

export const T = 16;
const SHEET = "client/public/assets/tilesets/sunnyside_16_ext.png";

let sheetCache = null;
export function loadSheet() {
  return (sheetCache ??= PNG.sync.read(readFileSync(SHEET)));
}

let itemsCache = null;
/** タイルセット(main)に描かれている「1個の絵」の枠を自動で見つける（client/src/editor/tileItems.ts と同じ見つけ方） */
export function tileItems() {
  if (itemsCache) return itemsCache;
  const sheet = loadSheet();
  const W = sheet.width, H = sheet.height, d = sheet.data;
  const seen = new Uint8Array(W * H);
  const comps = [];
  const stack = [];
  for (let s = 0; s < W * H; s++) {
    if (seen[s] || d[s * 4 + 3] <= 8) continue;
    let x0 = W, y0 = H, x1 = -1, y1 = -1, px = 0;
    stack.push(s);
    seen[s] = 1;
    while (stack.length) {
      const p = stack.pop();
      const x = p % W, y = (p / W) | 0;
      px++;
      x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y);
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const nx = x + dx, ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
          const q = ny * W + nx;
          if (seen[q] || d[q * 4 + 3] <= 8) continue;
          seen[q] = 1;
          stack.push(q);
        }
      }
    }
    comps.push({ x0, y0, x1, y1, px });
  }
  let list = comps;
  for (let changed = true; changed;) {
    changed = false;
    const out = [];
    const used = new Array(list.length).fill(false);
    for (let i = 0; i < list.length; i++) {
      if (used[i]) continue;
      const a = { ...list[i] };
      for (let j = i + 1; j < list.length; j++) {
        if (used[j]) continue;
        const b = list[j];
        if (a.x0 <= b.x1 && b.x0 <= a.x1 && a.y0 <= b.y1 && b.y0 <= a.y1) {
          a.x0 = Math.min(a.x0, b.x0); a.y0 = Math.min(a.y0, b.y0); a.x1 = Math.max(a.x1, b.x1); a.y1 = Math.max(a.y1, b.y1); a.px += b.px;
          used[j] = true;
          changed = true;
        }
      }
      out.push(a);
    }
    list = out;
  }
  itemsCache = list
    .filter((c) => c.px >= 6 && c.x1 - c.x0 + 1 <= 80 && c.y1 - c.y0 + 1 <= 80)
    .map((c) => ({ x: c.x0, y: c.y0, w: c.x1 - c.x0 + 1, h: c.y1 - c.y0 + 1, px: c.px }))
    .sort((a, b) => Math.floor(a.y / 16) - Math.floor(b.y / 16) || a.x - b.x || a.y - b.y);
  return itemsCache;
}

/**
 * @param map  map.json の中身（sprites / objects を使う。objects に配置を足していく）
 * @param grass 草地 {x0,y0,w,h}（px）
 */
export function makeKit(map, grass) {
  map.objects ??= [];
  map.sprites ??= {};
  const CX = grass.x0 + grass.w / 2;
  const Y0 = grass.y0;

  const kit = {
    map,
    grass,
    /** 草地の大きさ(px)。配置はこの範囲(幅±96, 高さ0..128)に収める */
    W: grass.w,
    H: grass.h,

    /**
     * 専用ドット絵 client/public/brand/stall/<name>.png を使えるようにする。origin 省略時は足元中央。
     * アニメーションにするときは、フレームを横一列に並べた PNG を作り、anim = { frames, fps } を渡す
     * （1コマの幅 = PNG の幅 / frames。ゲームでは自動で繰り返し再生。エディタ・preview は1コマ目〔frame指定でそのコマ〕）。
     */
    custom(name, ox, oy, anim) {
      const png = PNG.sync.read(readFileSync(`client/public/brand/stall/${name}.png`));
      const frames = anim?.frames ?? 1;
      const fw = png.width / frames;
      if (!Number.isInteger(fw)) throw new Error(`${name}: 幅 ${png.width} が frames=${frames} で割り切れません`);
      map.sprites[name] = { file: `../brand/stall/${name}.png`, fw, fh: png.height, frames, fps: anim?.fps ?? 10, ox: ox ?? fw / 2, oy: oy ?? png.height, catalog: true };
      return name;
    },

    /** タイルセットの点(px,py)にある1個の絵を使えるようにする。名前を返す */
    cropAt(px, py) {
      const it = tileItems().find((i) => px >= i.x && px < i.x + i.w && py >= i.y && py < i.y + i.h);
      if (!it) throw new Error(`タイルセットの (${px},${py}) に絵が見つかりません`);
      return kit.cropRect(it.x, it.y, it.w, it.h);
    },
    /** タイルセットの枠(x,y,w,h)を直接指定して使えるようにする（自動検出では他の絵とつながってしまうものに） */
    cropRect(x, y, w, h) {
      const name = `crop:main:${x},${y},${w}x${h}`;
      map.sprites[name] ??= { file: "", fw: w, fh: h, frames: 1, fps: 0, ox: w / 2, oy: h, catalog: true, crop: { tileset: "main", x, y, w, h, px: w * h } };
      return name;
    },

    /**
     * 足元中央 (dx, foot) にスプライトを1個置く。
     * o: { by, sort:"y"|"floor", flip, hit:[w,h], hxOff, frame, speed, angle, npc:{name,lines[]} }
     * 人物(96x64)は足元がそのまま foot になる。
     */
    put(name, dx, foot, o = {}) {
      const d = map.sprites[name];
      if (!d) throw new Error(`スプライト「${name}」が map.sprites にありません（custom()/cropAt()/cropRect() で先に使えるようにする）`);
      const cx = CX + dx, fy = Y0 + foot;
      const isChar = d.fw === 96 && d.fh === 64;
      const x = isChar ? cx : cx + d.ox - d.fw / 2;
      const y = isChar ? fy - 8 : fy + d.oy - d.fh;
      const obj = { sprite: name, x: Math.round(x * 100) / 100, y: Math.round(y * 100) / 100, sort: o.sort ?? "y", by: o.by !== undefined ? Y0 + o.by : fy };
      if (o.flip) obj.sx = -1;
      if (o.angle) obj.angle = o.angle;
      if (o.hit) {
        obj.hit = o.hit;
        obj.hx = cx + (o.hxOff ?? 0);
      }
      if (o.frame !== undefined) obj.frame = o.frame;
      if (o.speed !== undefined) obj.speed = o.speed;
      if (o.npc) obj.npc = o.npc;
      map.objects.push(obj);
      return obj;
    },

    /** 人物（足元に影つき・当たり判定つき）。npc を渡すと話しかけられる。flip=true で左向き */
    person(name, dx, foot, npc, flip = false) {
      const o = kit.put(name, dx, foot, { hit: [12, 8], flip, npc });
      map.objects.push({ sprite: "spr_deco_charactershadow", x: o.x, y: o.by - 1, sort: "floor", by: o.by + 7 });
      return o;
    },
  };
  return kit;
}
