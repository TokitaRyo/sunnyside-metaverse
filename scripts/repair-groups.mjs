/**
 * グループ(島・パーツ・スタンプ)の記録(map.groups)をもとに、欠けたタイルを復元する。
 *   node scripts/repair-groups.mjs [map.json] [--dry]
 *
 * 各グループは「どのレイヤーの、左上からどの相対位置に、どのタイルIDがあるか」を覚えている。
 * 実データでその位置が空(-1)になっているものだけを記録どおりに戻す。
 * 他のものが置かれている(空でない)マスは触らない。
 */
import { readFileSync, writeFileSync } from "node:fs";

const args = process.argv.slice(2);
const path = args.find((a) => !a.startsWith("--")) ?? "client/src/config/map.json";
const dry = args.includes("--dry");
const map = JSON.parse(readFileSync(path, "utf8"));

let restored = 0;
const perGroup = [];
for (const g of map.groups ?? []) {
  let n = 0;
  for (const t of g.tiles) {
    const layer = map.tileLayers.find((l) => l.name === t.layer);
    const x = g.x + t.dx, y = g.y + t.dy;
    if (!layer || !layer.data[y] || x < 0 || x >= layer.data[y].length) continue;
    if (layer.data[y][x] === -1) {
      layer.data[y][x] = t.id;
      n++;
    }
  }
  if (n) perGroup.push(`${g.label}: ${n}`);
  restored += n;
}
console.log(`復元 ${restored} マス${perGroup.length ? "（" + perGroup.join(", ") + "）" : ""}${dry ? "  [--dry: 書き込みません]" : ""}`);
if (!dry && restored) writeFileSync(path, JSON.stringify(map));
