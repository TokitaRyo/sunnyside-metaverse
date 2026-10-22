import { monitorEventLoopDelay } from "node:perf_hooks";

/**
 * サーバーの負荷の見張り（人が増えたときに、どこが苦しいかを、ログと管理ページで分かるようにする）。
 *  - cpu: この1プロセスが使っている CPU の割合（1コア=100%。Node は基本1コアなので、100% に近いと限界）
 *  - lagP99 / lagMax: イベントループの遅れ(ms)。大きいと、移動の反映やチャットが遅れる（50ms を超えたら危険信号）
 *  - rss: メモリ(MB)
 */
const loop = monitorEventLoopDelay({ resolution: 10 });
loop.enable();

export interface HealthSnapshot {
  cpu: number;
  lagP99: number;
  lagMax: number;
  rssMB: number;
  heapMB: number;
  uptimeSec: number;
}

let lastCpu = process.cpuUsage();
let lastAt = Date.now();
let latest: HealthSnapshot = { cpu: 0, lagP99: 0, lagMax: 0, rssMB: 0, heapMB: 0, uptimeSec: 0 };

/** 直近の区間（前回の呼び出しから今まで）の値を取り出して、次の区間を始める */
export function sampleHealth(): HealthSnapshot {
  const now = Date.now();
  const c = process.cpuUsage(lastCpu);
  const wallMs = Math.max(1, now - lastAt);
  const mem = process.memoryUsage();
  latest = {
    cpu: Math.round(((c.user + c.system) / 1000 / wallMs) * 100),
    lagP99: Math.round(loop.percentile(99) / 1e4) / 100,
    lagMax: Math.round(loop.max / 1e4) / 100,
    rssMB: Math.round(mem.rss / 1048576),
    heapMB: Math.round(mem.heapUsed / 1048576),
    uptimeSec: Math.round(process.uptime()),
  };
  lastCpu = process.cpuUsage();
  lastAt = now;
  loop.reset();
  return latest;
}

export const lastHealth = (): HealthSnapshot => latest;
