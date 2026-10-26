import { isStandalone } from "./ui/Fullscreen";

/**
 * PWA（ホーム画面に入れて、アプリのように使う）。
 *  - サービスワーカー（/sw.js）を登録する（本番のゲーム画面だけ。開発中・マップエディタ・管理者のショー画面では、登録しない）。
 *  - 入室画面に「アプリとして入れる」ボタンを出す（Android・パソコンの Chrome / Edge。iPhone は、共有ボタンの案内を別に出している）。
 */

/** ビルドごとの識別子（client/vite.config.ts が入れる）。サービスワーカーと、素材の URL（古い絵が出ないように）で使う */
export const BUILD_ID: string = __BUILD_ID__;
/** 素材の URL に、ビルドの識別子を付ける（デプロイのたびに、別の URL になり、端末に覚えた古い版と混ざらない） */
export const withBuild = (url: string): string => `${url}${url.includes("?") ? "&" : "?"}v=${BUILD_ID}`;

interface InstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
}

let deferred: InstallPromptEvent | null = null;

export function setupPwa(): void {
  setupInstallButton();
  if (!import.meta.env.PROD || !("serviceWorker" in navigator) || new URLSearchParams(location.search).has("edit")) return;
  // ページの読み込みが終わってから登録する（最初の表示を遅らせないため）
  const start = () => {
    navigator.serviceWorker
      .register("/sw.js", { scope: "/" })
      .then((reg) => {
        // 新しい版が出ていないか、ときどき確かめる（長く開いたままの画面・ホーム画面から開き直した画面のため）
        let last = Date.now();
        document.addEventListener("visibilitychange", () => {
          if (document.visibilityState === "visible" && Date.now() - last > 30 * 60 * 1000) {
            last = Date.now();
            void reg.update().catch(() => undefined);
          }
        });
      })
      .catch((e) => console.warn("[pwa] サービスワーカーを登録できません:", e));
  };
  if (document.readyState === "complete") start();
  else addEventListener("load", start, { once: true });
}

function setupInstallButton(): void {
  const btn = document.getElementById("install-btn") as HTMLButtonElement | null;
  if (!btn) return;
  addEventListener("beforeinstallprompt", (e) => {
    e.preventDefault(); // ブラウザ任せの表示は出さず、入室画面のボタンで案内する
    deferred = e as InstallPromptEvent;
    if (!isStandalone()) btn.hidden = false;
  });
  addEventListener("appinstalled", () => {
    deferred = null;
    btn.hidden = true;
  });
  btn.addEventListener("click", async () => {
    if (!deferred) return;
    const ev = deferred;
    deferred = null;
    btn.hidden = true;
    try {
      await ev.prompt();
      await ev.userChoice;
    } catch {
      /* 断られても、そのまま遊べる */
    }
  });
}
