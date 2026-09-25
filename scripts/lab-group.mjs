// 実験用: 指定グループの16枚を、地面A(上段)と草(下段)の上に1枚ずつ重ねて見る
//   node scripts/lab-group.mjs "River" 470   → reference/lab_map.json
import { readFileSync, writeFileSync } from "node:fs";
import { Grid, makeMap, tid } from "./lib/tilekit.mjs";

const tsj = JSON.parse(readFileSync("client/src/config/tileset.json", "utf8"));
const group = process.argv[2] ?? "River";
const under = Number(process.argv[3] ?? tsj.autotileGroups[group].fill);
const g = tsj.autotileGroups[group];
const W = 34, H = 11;
const ground = new Grid(W, H, tid(1, 3));
const deco = new Grid(W, H);
ground.fillRect(0, 0, W, 5, under);
g.tiles.forEach((id, i) => {
  deco.set(i * 2, 2, id);
  deco.set(i * 2, 8, id);
});
console.log(group, "index→id:", g.tiles.map((id, i) => `${i}:${id}`).join(" "));
writeFileSync("reference/lab_map.json", JSON.stringify(makeMap({ name: "lab", width: W, height: H, spawn: { x: 2, y: 2 }, layers: { ground, deco, overhead: new Grid(W, H), collision: new Grid(W, H, 0) } })));
