// 検証用: タイル層だけを深度順に描いて、反転・回転の解釈(4通り)のどれが正しいか目で確かめる
//   node scripts/gm-tiles-test.mjs <Room1.yy> <rot-first|flip-first> <cw|ccw> <out.png>
import { readFileSync, writeFileSync } from "node:fs";
import { PNG } from "pngjs";
import { parseYY, decodeTiles, splitTile, makeExtendedTileset } from "./lib/gm.mjs";

const [yy, order, rotDir, outPath] = process.argv.slice(2);
const room = parseYY(yy);
const main = PNG.sync.read(readFileSync("client/public/assets/tilesets/sunnyside_16.png"));
const forest = PNG.sync.read(readFileSync("client/public/assets/tilesets/sunnyside_forest_32.png"));
const extMain = makeExtendedTileset(main, 16, 64, { order, rotDir });
const extForest = makeExtendedTileset(forest, 32, 10, { order, rotDir });

const W = 86, H = 48, S = 16;
const out = new PNG({ width: W * S, height: H * S });
out.data.fill(255);
const layers = room.layers.filter((l) => l.tiles).sort((a, b) => b.depth - a.depth); // 奥(depth大)から手前へ
const stats = {};
for (const l of layers) {
  if (l.name.startsWith("cloud")) continue; // 雲は今回は描かない
  const isForest = l.tilesetId.name === "tileset_forest";
  const ext = isForest ? extForest : extMain;
  const size = isForest ? 32 : 16;
  const { w, h, values } = decodeTiles(l);
  const ids = values.map((v) => ext.resolve(splitTile(v)));
  stats[l.name] = ids.filter((i) => i >= 0).length;
  l._ids = { w, h, ids, size, isForest };
}
const tsMain = extMain.build();
const tsForest = extForest.build();
for (const l of layers) {
  if (!l._ids) continue;
  const { w, h, ids, size, isForest } = l._ids;
  const ts = isForest ? tsForest : tsMain;
  const cols = isForest ? 10 : 64;
  for (let cy = 0; cy < h; cy++)
    for (let cx = 0; cx < w; cx++) {
      const id = ids[cy * w + cx];
      if (id < 0) continue;
      const tc = id % cols, tr = Math.floor(id / cols);
      for (let y = 0; y < size; y++)
        for (let x = 0; x < size; x++) {
          const si = ((tr * size + y) * ts.width + tc * size + x) * 4;
          const a = ts.data[si + 3] / 255;
          if (!a) continue;
          const di = ((cy * size + y) * out.width + cx * size + x) * 4;
          if (di + 3 >= out.data.length) continue;
          for (let k = 0; k < 3; k++) out.data[di + k] = ts.data[si + k] * a + out.data[di + k] * (1 - a);
        }
    }
}
writeFileSync(outPath, PNG.sync.write(out));
console.log("variants main:", extMain.count(), "forest:", extForest.count());
console.log("non-empty tiles per layer:", JSON.stringify(stats));
