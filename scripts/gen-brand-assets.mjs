/**
 * AMPLIFIRE のタイトル画面用ドット絵（PNG）を作る。
 *   node scripts/gen-brand-assets.mjs
 * 出力: client/public/brand/space-bg.png（宇宙の背景 480x270）, earth.png（惑星 192x192）
 * 乱数は固定シードなので、何度作っても同じ絵になる。素材パックの絵は使わない（すべて手続き生成のオリジナル）。
 * ロゴ(amplifire-logo.png)は利用者が用意したポスターから切り出したもので、このスクリプトでは作らない。
 */
import { mkdirSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";

const OUT = "client/public/brand";
mkdirSync(OUT, { recursive: true });

// ---------------------------------------------------------------- 道具
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const BAYER = [
  [0, 8, 2, 10],
  [12, 4, 14, 6],
  [3, 11, 1, 9],
  [15, 7, 13, 5],
];
/** 0..1 を Bayer 4x4 でディザ判定 */
const dither = (x, y, v) => v > (BAYER[y & 3][x & 3] + 0.5) / 16;
const hex = (s) => [parseInt(s.slice(1, 3), 16), parseInt(s.slice(3, 5), 16), parseInt(s.slice(5, 7), 16)];
const lerp = (a, b, t) => a + (b - a) * t;
const clamp01 = (v) => Math.max(0, Math.min(1, v));

function hash3(ix, iy, iz, seed) {
  let h = (ix * 374761393 + iy * 668265263 + iz * 2147483647 + seed * 1274126177) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
}
function vnoise(x, y, z, seed) {
  const ix = Math.floor(x), iy = Math.floor(y), iz = Math.floor(z);
  const fx = x - ix, fy = y - iy, fz = z - iz;
  const s = (t) => t * t * (3 - 2 * t);
  const u = s(fx), v = s(fy), w = s(fz);
  let r = 0;
  for (let dz = 0; dz <= 1; dz++)
    for (let dy = 0; dy <= 1; dy++)
      for (let dx = 0; dx <= 1; dx++) {
        r += hash3(ix + dx, iy + dy, iz + dz, seed) * (dx ? u : 1 - u) * (dy ? v : 1 - v) * (dz ? w : 1 - w);
      }
  return r;
}
function fbm(x, y, z, seed, oct = 4) {
  let a = 0.5, f = 1, sum = 0, norm = 0;
  for (let i = 0; i < oct; i++) {
    sum += a * vnoise(x * f, y * f, z * f, seed + i * 17);
    norm += a;
    a *= 0.5;
    f *= 2;
  }
  return sum / norm;
}

function savePng(name, png) {
  writeFileSync(`${OUT}/${name}`, PNG.sync.write(png));
  console.log(`wrote ${OUT}/${name} (${png.width}x${png.height})`);
}
function newPng(w, h) {
  const p = new PNG({ width: w, height: h });
  p.data.fill(0);
  return p;
}
function put(png, x, y, [r, g, b], a = 255) {
  if (x < 0 || y < 0 || x >= png.width || y >= png.height) return;
  const i = (y * png.width + x) * 4;
  png.data[i] = r;
  png.data[i + 1] = g;
  png.data[i + 2] = b;
  png.data[i + 3] = a;
}

// ---------------------------------------------------------------- 宇宙の背景
function spaceBg() {
  const W = 480, H = 270;
  const png = newPng(W, H);
  const rand = rng(20261005);
  const base = hex("#04020d"), deep = hex("#120a33");

  // 下地: すみは黒、中央のあたりがわずかに藍色（ディザで段をつける）
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const d = Math.hypot((x - W / 2) / (W / 2), (y - H / 2) / (H / 2));
      const v = clamp01(0.55 - d * 0.45);
      put(png, x, y, dither(x, y, v * 0.6) ? deep : base);
    }
  }

  // 天の川のような斜めの帯（左下→右上）。帯の中心からの距離と雑音で濃さを決め、3段階でディザ
  const bands = [
    { off: -70, w: 13, seed: 3 },
    { off: 12, w: 10, seed: 9 },
    { off: 92, w: 12, seed: 21 },
  ];
  const ang = -0.42; // 傾き
  const ca = Math.cos(ang), sa = Math.sin(ang);
  const nebula = [hex("#2b1766"), hex("#4b2a95"), hex("#7a45b8"), hex("#b06ad0")];
  for (const b of bands) {
    for (let y = 0; y < H; y++) {
      for (let x = 0; x < W; x++) {
        const px = x - W / 2, py = y - H / 2;
        const along = px * ca + py * sa;
        const across = -px * sa + py * ca - b.off + Math.sin(along / 70 + b.seed) * 16 + Math.sin(along / 23 + b.seed * 2) * 4;
        const falloff = Math.exp(-(across * across) / (2 * b.w * b.w));
        const n = fbm(along / 38, across / 14, b.seed, b.seed, 4);
        const v = falloff * (0.2 + n * 0.95);
        if (v < 0.22) continue;
        // 濃さに応じて色の段を変える。段の境目はディザでぼかす
        const level = v < 0.4 ? 0 : v < 0.58 ? 1 : v < 0.76 ? 2 : 3;
        const frac = (v - [0.22, 0.4, 0.58, 0.76][level]) / 0.18;
        if (!dither(x, y, clamp01(frac) * 0.9 + 0.1)) continue;
        put(png, x, y, nebula[level]);
      }
    }
  }

  // 星: 白・水色・薄紫の点
  const starCols = [hex("#ffffff"), hex("#cfe3ff"), hex("#b9a8ff"), hex("#ffe9b8")];
  for (let i = 0; i < 360; i++) {
    const x = Math.floor(rand() * W), y = Math.floor(rand() * H);
    const c = starCols[Math.floor(rand() * starCols.length)];
    put(png, x, y, rand() < 0.7 ? c.map((v) => Math.round(v * 0.7)) : c);
  }
  // RGBの十字の輝き（ロゴの虹色に合わせる）
  const rgb = [hex("#ff3b3b"), hex("#ff9a1f"), hex("#ffe14a"), hex("#3be05a"), hex("#33d6ff"), hex("#4a6bff"), hex("#c24bff"), hex("#ff4bd8")];
  for (let i = 0; i < 80; i++) {
    const x = 3 + Math.floor(rand() * (W - 6)), y = 3 + Math.floor(rand() * (H - 6));
    const c = rgb[Math.floor(rand() * rgb.length)];
    const dim = c.map((v) => Math.round(v * 0.45));
    put(png, x, y, c);
    if (rand() < 0.6) {
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) put(png, x + dx, y + dy, dim);
    }
    if (rand() < 0.18) {
      for (const [dx, dy] of [[2, 0], [-2, 0], [0, 2], [0, -2]]) put(png, x + dx, y + dy, dim.map((v) => Math.round(v * 0.6)));
    }
  }
  savePng("space-bg.png", png);
}

// ---------------------------------------------------------------- 惑星（衛星から見た地球風）
function earth() {
  const S = 192, R = 84, cx = S / 2, cy = S / 2;
  const png = newPng(S, S);
  const light = (() => {
    const v = [-0.55, -0.45, 0.7];
    const n = Math.hypot(...v);
    return v.map((t) => t / n);
  })();
  const rand = rng(77);
  const ocean = [hex("#071a52"), hex("#0c3a8c"), hex("#1763c8"), hex("#2e8ae6")];
  const land = [hex("#1c5a2e"), hex("#2f8a3e"), hex("#5db04a"), hex("#a9c75a")];
  const desert = hex("#b99650");
  const snow = hex("#eef6ff");
  const cloud = [hex("#8fa8d6"), hex("#cfe0f7"), hex("#ffffff")];

  for (let y = 0; y < S; y++) {
    for (let x = 0; x < S; x++) {
      const dx = (x + 0.5 - cx) / R, dy = (y + 0.5 - cy) / R;
      const d2 = dx * dx + dy * dy;
      if (d2 > 1) continue;
      const dz = Math.sqrt(1 - d2);
      // 地表の座標（少し回して見せる）
      const rot = 0.9;
      const px = dx * Math.cos(rot) + dz * Math.sin(rot), pz = -dx * Math.sin(rot) + dz * Math.cos(rot), py = dy;
      const h = fbm(px * 2.1 + 5, py * 2.1 + 9, pz * 2.1 + 3, 11, 5);
      const isLand = h > 0.53;
      const lat = Math.abs(py);
      const lit = clamp01(dx * light[0] + dy * light[1] + dz * light[2]);
      // 4段階の陰影（段のさかいはディザ）
      const shade = lit * 3.2;
      const lv = Math.max(0, Math.min(3, Math.floor(shade + (dither(x, y, shade % 1) ? 1 : 0) - 0.15)));
      let col;
      if (lat > 0.86) col = snow.map((v) => Math.round(v * (0.55 + lv * 0.15)));
      else if (isLand) {
        const dry = fbm(px * 3 + 1, py * 3 + 2, pz * 3 + 7, 29, 3) > 0.62;
        col = dry ? desert.map((v) => Math.round(v * (0.45 + lv * 0.18))) : land[lv];
      } else {
        const coast = h > 0.49 ? 1 : 0;
        col = ocean[Math.min(3, lv + coast)];
      }
      // 雲
      const c = fbm(px * 3.2 + 2, py * 5.5 + 4, pz * 3.2 + 8, 53, 4);
      if (c > 0.66) {
        const k = Math.min(2, Math.max(0, Math.floor(lv - 1 + (c - 0.66) * 6)));
        if (dither(x, y, 0.45 + (c - 0.66) * 2.5)) col = cloud[k];
      }
      // 夜側の街あかり（暗いところの陸地に、黄色い点）
      if (isLand && lv === 0 && lat < 0.8 && rand() < 0.035) col = hex("#ffd24a");
      put(png, x, y, col);
    }
  }
  // 大気のふち（明るい側だけ水色に光る）
  for (let y = 0; y < S; y++) {
    for (let x = 0; x < S; x++) {
      const dx = (x + 0.5 - cx) / R, dy = (y + 0.5 - cy) / R;
      const d = Math.hypot(dx, dy);
      if (d <= 1 || d > 1.09) continue;
      const lit = clamp01(0.55 + (dx * light[0] + dy * light[1]) * 0.9);
      const fall = 1 - (d - 1) / 0.09;
      if (dither(x, y, fall * lit)) put(png, x, y, fall > 0.55 ? hex("#7fe3ff") : hex("#2e8ae6"));
    }
  }
  savePng("earth.png", png);
}

spaceBg();
earth();


