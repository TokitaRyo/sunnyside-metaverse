/**
 * スマホで、操作のミスで画面が勝手に拡大されたり、長押しで文字選択やメニューが出たりしないようにする。
 *  - ピンチ拡大: iOS Safari は viewport の user-scalable=no を無視するので、gesture イベントを止める。Android は touch-action: none で止まる。
 *  - 2本指のはみ出し: 2本指の touchmove を止める（パッドと「走る」を同時に押す操作は、pointer イベントなので影響しない）。
 *  - ダブルタップ拡大: ボタン・リンク・入力欄以外の場所での素早い2回タップを止める（ボタンの連打は止めない）。
 *  - 長押しのメニュー: 入力欄以外では出さない。
 * touchstart は止めない（止めると、移動しながらの別ボタンの click が消えてしまうため）。
 */
const INTERACTIVE = "button, a, input, textarea, select, label, summary, [role=button]";

export function installTouchGuard(): void {
  const stop = (e: Event) => e.preventDefault();
  for (const t of ["gesturestart", "gesturechange", "gestureend"]) document.addEventListener(t, stop, { passive: false });
  document.addEventListener(
    "touchmove",
    (e) => {
      if (e.touches.length > 1) e.preventDefault();
    },
    { passive: false },
  );
  let lastEnd = 0;
  document.addEventListener(
    "touchend",
    (e) => {
      const now = Date.now();
      const target = e.target as Element | null;
      if (now - lastEnd < 350 && !target?.closest?.(INTERACTIVE)) e.preventDefault();
      lastEnd = now;
    },
    { passive: false },
  );
  document.addEventListener("contextmenu", (e) => {
    const target = e.target as Element | null;
    if (!target?.closest?.("input, textarea")) e.preventDefault();
  });
}
