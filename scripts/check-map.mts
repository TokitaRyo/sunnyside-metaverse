import { readFileSync } from "node:fs";
import { validateMap } from "../client/src/config/validate.ts";

const path = process.argv[2] ?? "client/src/config/map.json";
const map = JSON.parse(readFileSync(path, "utf8"));
const sprites = JSON.parse(readFileSync("client/src/config/sprites.json", "utf8"));
const tileset = JSON.parse(readFileSync("client/src/config/tileset.json", "utf8"));

const errors = validateMap(map, sprites, tileset);
if (errors.length) {
  console.error(`${path}: ${errors.length} 件の問題`);
  for (const e of errors) console.error(" - " + e);
  process.exit(1);
}
console.log(`${path}: OK`);
