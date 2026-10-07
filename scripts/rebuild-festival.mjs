/**
 * 文化祭のマップを白紙から作り直す（空の背景＋大きな島1つ＋出店17＋広場＋スタンプ）。
 *   node scripts/rebuild-festival.mjs [--w 115] [--h 77] [--dry]
 *
 *  1. gen-blank-canvas.mjs : 空っぽのキャンバス（タイルセット・スプライト定義はそのまま流用）
 *  2. gen-sky.mjs --single 84x32 --label 文化祭島 : 空・雲・大きな島（草の面 86x34 マス）
 *  3. build-stalls.mjs : 島を 6x3 の区画に分けて、出店とスタンプを置く。広場をスポーン地点にする
 * 今の map.json は、reference/map-backups/ に退避してから作り直す（--dry なら何もしない）。
 * 前提: reference/map-backups/map.20260927-133146.pre-school-map.json がある（gen-blank-canvas.mjs が使う）。
 */
import { copyFileSync, mkdirSync, existsSync } from "node:fs";
import { spawnSync } from "node:child_process";

const args = process.argv.slice(2);
const opt = (k, d) => (args.includes(`--${k}`) ? args[args.indexOf(`--${k}`) + 1] : d);
const W = opt("w", 115), H = opt("h", 77);
const MAP = "client/src/config/map.json";
const run = (script, ...a) => {
  console.log(`\n$ node ${script} ${a.join(" ")}`);
  const r = spawnSync(process.execPath, [script, ...a], { stdio: "inherit" });
  if (r.status !== 0) {
    console.error(`${script} が失敗しました（終了コード ${r.status}）`);
    process.exit(r.status ?? 1);
  }
};

if (args.includes("--dry")) {
  console.log(`--dry: ${W}x${H} で作り直す予定（何も書きません）`);
  process.exit(0);
}
if (existsSync(MAP)) {
  mkdirSync("reference/map-backups", { recursive: true });
  const backup = `reference/map-backups/map.before-rebuild-${Date.now()}.json`;
  copyFileSync(MAP, backup);
  console.log(`今のマップを退避: ${backup}`);
}
run("scripts/gen-blank-canvas.mjs", "--w", String(W), "--h", String(H));
run("scripts/gen-sky.mjs", MAP, "--single", "84x32", "--label", "文化祭島");
run("scripts/build-stalls.mjs");
run("--import=tsx", "scripts/check-map.mts");
