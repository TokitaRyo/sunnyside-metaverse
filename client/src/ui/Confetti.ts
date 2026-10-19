/**
 * 紙吹雪（スタンプコンプリートのお祝い）。画面全体の canvas に、ドット絵っぽい四角を降らせて数秒で消える。
 * 動きの少ない設定（prefers-reduced-motion）の人には出さない。
 */
const COLORS = ["#ff5fa2", "#ffd36a", "#6fe8ff", "#8dff8a", "#b79bff", "#ffffff"];

export function confetti(durationMs = 4200): void {
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  const cv = document.createElement("canvas");
  cv.style.cssText = "position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:60;image-rendering:pixelated";
  const SCALE = 3; // 粗い解像度で描いて、ドットっぽく見せる
  cv.width = Math.ceil(innerWidth / SCALE);
  cv.height = Math.ceil(innerHeight / SCALE);
  document.body.append(cv);
  const g = cv.getContext("2d");
  if (!g) {
    cv.remove();
    return;
  }
  const parts = Array.from({ length: 140 }, () => ({
    x: Math.random() * cv.width,
    y: -Math.random() * cv.height * 0.6,
    vx: (Math.random() - 0.5) * 30,
    vy: 40 + Math.random() * 60,
    s: 2 + Math.floor(Math.random() * 2),
    c: COLORS[Math.floor(Math.random() * COLORS.length)],
    ph: Math.random() * 6.28,
  }));
  const t0 = performance.now();
  let last = t0;
  const frame = (now: number) => {
    const dt = Math.min((now - last) / 1000, 0.05);
    last = now;
    const age = now - t0;
    g.clearRect(0, 0, cv.width, cv.height);
    g.globalAlpha = age > durationMs - 800 ? Math.max(0, (durationMs - age) / 800) : 1;
    for (const p of parts) {
      p.x += (p.vx + Math.sin(now / 300 + p.ph) * 14) * dt;
      p.y += p.vy * dt;
      g.fillStyle = p.c;
      g.fillRect(Math.round(p.x), Math.round(p.y), p.s, p.s);
    }
    if (age < durationMs) requestAnimationFrame(frame);
    else cv.remove();
  };
  requestAnimationFrame(frame);
}
