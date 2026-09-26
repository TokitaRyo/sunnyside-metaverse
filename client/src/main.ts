import "./style.css";
import Phaser from "phaser";
import { bgm } from "./audio/Bgm";
import { mapErrors } from "./config";
import { InputState } from "./game/InputState";
import { EV_LOAD_ERROR, EV_PROGRESS, EV_READY, PreloadScene } from "./scenes/PreloadScene";
import { EV_CONN, EV_JOINED, EV_JOIN_FAILED, WorldScene } from "./scenes/WorldScene";
import { JoinScreen } from "./ui/Join";

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

function showFatal(title: string, lines: string[]): void {
  const el = $("fatal");
  el.hidden = false;
  el.replaceChildren();
  const h = document.createElement("h2");
  h.textContent = title;
  const pre = document.createElement("pre");
  pre.textContent = lines.map((l) => `・${l}`).join("\n");
  el.append(h, pre);
  $("join").hidden = true;
}

function setConn(kind: "ok" | "reconnecting" | "lost"): void {
  const root = $("conn");
  const text = $("conn-text");
  const reload = $<HTMLButtonElement>("conn-reload");
  if (kind === "ok") {
    root.hidden = true;
    return;
  }
  root.hidden = false;
  root.classList.toggle("soft", kind === "reconnecting");
  reload.hidden = kind === "reconnecting";
  text.textContent = kind === "reconnecting" ? "接続が切れました。再接続しています…" : "接続が切れました。ページを再読込してください。";
}

/**
 * 開発時のみ: 画面右上の切り替えボタンで、プレイ画面とマップエディタを行き来できるようにする。
 * `import.meta.env.DEV` の分岐ごとビルド時に消えるので、本番ビルドには含まれない。
 * 呼び出し元へ、`?edit=1` で開いたときにそのままエディタを開くための switchToEdit を返す。
 */
function setupDevToggle(game: Phaser.Game, join: JoinScreen, input: InputState): { switchToEdit: () => void } {
  let mode: "play" | "edit" = "play";
  // 切り替えを速くするため、起動時（素材の読み込みと並行）にエディタのコードを先読みしておく
  const editorReady: Promise<void> = import("./editor/EditorScene").then(({ EditorScene }) => {
    if (!game.scene.getScene("Editor")) game.scene.add("Editor", EditorScene, false);
  });

  const btn = document.createElement("button");
  btn.id = "mode-toggle";
  btn.type = "button";
  const setLabel = () => {
    btn.textContent = mode === "play" ? "🛠 マップを編集" : "▶ プレイ画面に戻る";
  };
  setLabel();
  document.body.append(btn);

  // 今のモードを URL に反映しておくと、保存後の自動リロードや手動リロードでも同じ画面に戻れる
  const syncUrl = () => {
    const url = new URL(location.href);
    if (mode === "edit") url.searchParams.set("edit", "1");
    else url.searchParams.delete("edit");
    history.replaceState(null, "", url);
  };

  function switchToEdit(): void {
    if (mode === "edit") return;
    mode = "edit";
    setLabel();
    syncUrl();
    input.clear();
    join.hide();
    const world = game.scene.getScene("World");
    if (world?.scene.isActive()) game.scene.stop("World");
    btn.disabled = true;
    void editorReady.then(() => {
      game.scene.start("Editor");
      btn.disabled = false;
    });
  }

  function switchToPlay(): void {
    if (mode === "play") return;
    mode = "play";
    setLabel();
    syncUrl();
    input.clear();
    const editor = game.scene.getScene("Editor");
    if (editor?.scene.isActive()) game.scene.stop("Editor");
    // 前回の入室でボタンが「接続中…」のまま残っていることがあるので、もう一度押せる状態に戻す
    join.reset();
  }

  btn.addEventListener("click", () => (mode === "play" ? switchToEdit() : switchToPlay()));

  return { switchToEdit };
}

function boot(): void {
  // 起動時に map.json を検証。問題があれば無言で落とさず画面とコンソールに出す（SPEC 5.2）
  if (mapErrors.length) {
    showFatal(`map.json に ${mapErrors.length} 件の問題があります`, mapErrors);
    return;
  }

  // ブラウザのズームや 125% 表示（例: 1366x768 → 1092.8x614.4 CSS px）で領域サイズが小数になると、
  // Phaser(RESIZE) が作る WebGL のフレームバッファが "Incomplete Attachment" で失敗し描画が止まる。
  // そこで Scale.NONE にして、整数化したサイズをこちらで渡し、window の resize で scale.resize() する。
  const size = () => ({ width: Math.max(1, Math.floor(window.innerWidth)), height: Math.max(1, Math.floor(window.innerHeight)) });

  const input = new InputState();
  const join = new JoinScreen();
  $("conn-reload").addEventListener("click", () => location.reload());

  const bgmBtn = $<HTMLButtonElement>("bgm-toggle");
  const syncBgmLabel = () => {
    bgmBtn.textContent = bgm.muted ? "🔇" : "🔈";
    bgmBtn.setAttribute("aria-pressed", String(!bgm.muted));
  };
  syncBgmLabel();
  bgmBtn.addEventListener("click", () => {
    bgm.toggleMute();
    syncBgmLabel();
  });

  const game = new Phaser.Game({
    type: Phaser.AUTO,
    parent: "game",
    // ドット絵が滲まないように最近傍補間（SPEC 4.4）
    pixelArt: true,
    antialias: false,
    roundPixels: true,
    backgroundColor: "#1b2a1a",
    scale: { mode: Phaser.Scale.NONE, ...size() },
    audio: { noAudio: true },
    disableContextMenu: true,
    scene: [PreloadScene],
  });
  game.scene.add("World", WorldScene, false);

  window.addEventListener("resize", () => {
    const { width, height } = size();
    if (width !== game.scale.width || height !== game.scale.height) game.scale.resize(width, height);
  });

  // マップエディタとの切り替えは開発時のみ（本番ビルドには含めない）
  const dev = import.meta.env.DEV;
  const devToggle = dev ? setupDevToggle(game, join, input) : null;

  game.events.on(EV_PROGRESS, (p: number) => join.setProgress(p));
  game.events.on(EV_READY, () => {
    join.setReady();
    // ?edit=1 で開いたときは、そのままエディタを開く（従来どおりの入り口）
    if (dev && new URLSearchParams(location.search).has("edit")) devToggle?.switchToEdit();
  });
  game.events.on(EV_LOAD_ERROR, (failed: string[]) => join.showError(`素材の読み込みに失敗しました: ${failed.length}件（コンソール参照）`));
  game.events.on(EV_JOINED, () => join.hide());
  game.events.on(EV_JOIN_FAILED, (msg: string) => join.showError(msg.includes("満員") ? msg : `サーバーに接続できません（${msg}）`));
  game.events.on(EV_CONN, (kind: "ok" | "reconnecting" | "lost") => setConn(kind));

  join.onSubmit = ({ name, hair }) => {
    bgm.start(); // クリック(ユーザー操作)のハンドラ内なので自動再生制限を通る
    game.scene.start("World", { name, hair, input });
  };

  // 開発時のデバッグ用
  (window as unknown as { __game: Phaser.Game }).__game = game;
}

boot();
