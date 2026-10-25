/**
 * 荒らし対策の確認を、まとめて実行する（npm run troll-test）。段階ごとに、試験用の設定でサーバーを起動 → 荒らしボットを実行 → サーバーを止める。
 * 一時的なデータ置き場を使うので、本物の記録には触らない。1分半ほどかかる。
 */
import { spawn, spawnSync } from "node:child_process";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const PORT = 2570;
const PHASES = [
  { phase: "main", env: { MOD_NEWCOMER_SEC: "5", MOD_CHAT_GAP_SEC: "1", MOD_REPORTER_MIN_SEC: "3", MOD_BREAKER_THRESHOLD: "100" } },
  { phase: "breaker", env: { MOD_NEWCOMER_SEC: "5", MOD_CHAT_GAP_SEC: "1", MOD_BREAKER_THRESHOLD: "6", MOD_BREAKER_SEC: "8" } },
  { phase: "join", env: { MOD_STRICT_LOCAL: "1", MOD_JOIN_PER_MIN: "5" } },
  { phase: "venue", env: { VENUE_CODE: "venue-test-code" } },
];
const sh = process.platform === "win32";
const npx = sh ? "npx.cmd" : "npx";

function waitForListening(child) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("サーバーが起動しません")), 90000);
    const onData = (d) => {
      if (String(d).includes("Listening on")) {
        clearTimeout(timer);
        resolve();
      }
    };
    child.stdout.on("data", onData);
    child.stderr.on("data", onData);
    child.on("exit", () => reject(new Error("サーバーが止まりました")));
  });
}
function stop(child) {
  if (sh) spawnSync("taskkill", ["/pid", String(child.pid), "/T", "/F"]);
  else child.kill("SIGKILL");
}

let failed = 0;
// サーバー不要の、誤検出の確認を先に行う
if (spawnSync(npx, ["tsx", "scripts/moderation-corpus.ts"], { shell: sh, stdio: "inherit" }).status !== 0) failed++;
for (const { phase, env } of PHASES) {
  const dataDir = mkdtempSync(join(tmpdir(), "amplifire-troll-"));
  const server = spawn(npx, ["tsx", "server/src/index.ts"], {
    env: { ...process.env, PORT: String(PORT), DATA_DIR: dataDir, ADMIN_PASSWORD: "local-test-admin-pass", ...env },
    shell: sh,
    stdio: ["ignore", "pipe", "pipe"],
  });
  try {
    await waitForListening(server);
    const r = spawnSync(npx, ["tsx", "scripts/troll-test.ts", phase], {
      env: { ...process.env, URL: `ws://localhost:${PORT}`, ADMIN_PW: "local-test-admin-pass", ...env },
      shell: sh,
      stdio: "inherit",
    });
    if (r.status !== 0) failed++;
  } catch (e) {
    console.error(`[${phase}]`, e.message);
    failed++;
  } finally {
    stop(server);
    await new Promise((r) => setTimeout(r, 1500));
  }
}
console.log(failed ? `\n荒らし対策の確認: ${failed} 段階が失敗しました` : "\n荒らし対策の確認: すべての段階が成功しました");
process.exit(failed ? 1 : 0);
