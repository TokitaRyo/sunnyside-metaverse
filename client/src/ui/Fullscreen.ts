/**
 * スマホでブラウザのアドレスバー・タブを消して、全画面で遊べるようにする。
 *  - Android（Chrome など）: 入室ボタンを押した瞬間（ユーザー操作の中）に全画面にする。右上の ⛶ でも切り替えられる。
 *  - iPhone（Safari）: ページからは全画面にできない。「ホーム画面に追加」して開くと、アドレスバーなしの全画面になる（manifest と meta で対応済み）。入室画面に案内を出す。
 *  - すでに「ホーム画面から開いた」（standalone / fullscreen）ときは、何もしない。
 */
export const isTouchDevice = (): boolean => matchMedia("(pointer: coarse)").matches;

export function isStandalone(): boolean {
  return (navigator as unknown as { standalone?: boolean }).standalone === true || matchMedia("(display-mode: standalone)").matches || matchMedia("(display-mode: fullscreen)").matches;
}

/** iPhone / iPad の Safari（iPadOS は Mac を名乗るので、タッチの有無でも見分ける） */
export function isIOS(): boolean {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
}

/** ページから全画面にできる環境か（iPhone の Safari は false） */
export const canFullscreen = (): boolean => !!document.fullscreenEnabled && !isStandalone();

/** タッチ端末なら、全画面にする。ユーザー操作（タップ）のハンドラの中で呼ぶこと */
export function enterFullscreenOnTouch(): void {
  if (!isTouchDevice() || !canFullscreen() || document.fullscreenElement) return;
  void document.documentElement.requestFullscreen({ navigationUI: "hide" }).catch(() => {
    /* 断られても、そのまま遊べる */
  });
}

export function toggleFullscreen(): void {
  if (document.fullscreenElement) void document.exitFullscreen().catch(() => undefined);
  else void document.documentElement.requestFullscreen({ navigationUI: "hide" }).catch(() => undefined);
}
