/**
 * 既存の map.json に、エディタで置けるモブのカタログ(ゴブリン全動作・スケルトン・人間・動物)を追記する。
 * 配置物・タイル・衝突など、あなたが編集した内容には一切触れない（sprites に項目を足すだけ）。
 *   node scripts/add-mob-catalog.mjs "<...>/Sunnyside_World_ASSET_PACK_V2.1"
 * 実行前の map.json は reference/map-backups/ に退避する。
 */
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { addMobCatalog } from "./lib/mobcatalog.mjs";

const PACK = process.argv[2];
if (!PACK) throw new Error('usage: node scripts/add-mob-catalog.mjs "<pack root>"');
const GM = join(PACK, "Sunnyside_World_Gamemaker");
const FILE = "client/src/config/map.json";

mkdirSync("reference/map-backups", { recursive: true });
const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
const backup = `reference/map-backups/map-${stamp}-before-catalog.json`;
copyFileSync(FILE, backup);

const map = JSON.parse(readFileSync(FILE, "utf8"));
const before = Object.keys(map.sprites).length;
const added = addMobCatalog(map, GM);
writeFileSync(FILE, JSON.stringify(map));
console.log(`sprites: ${before} -> ${Object.keys(map.sprites).length} (+${added})。元のファイルは ${backup} に退避しました。`);
