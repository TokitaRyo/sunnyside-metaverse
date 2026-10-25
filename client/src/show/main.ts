import "./show.css";
import Phaser from "phaser";
import { HAIRS, decodeLook, encodeLook, type Look } from "@metaverse/shared";
import { AvatarPreview } from "../ui/AvatarPreview";
import { loadStampSheet, stampFrame, stampIconUrl } from "../game/stampIcons";
import { EV_LOAD_ERROR, EV_PROGRESS, EV_READY, PreloadScene } from "../scenes/PreloadScene";
import { EV_SPECTATE, SpectatorScene } from "./SpectatorScene";

/**
 * 管理者用のショー画面（大型ディスプレイ用）。
 *  - 主役（左）: 入室中の人の「ゲーム画面」。観客として部屋につなぎ、その人のキャラをカメラで追いかける（SpectatorScene）。
 *  - 右: いま追っている人の、名前・スタンプ数・滞在時間・おしゃべりの回数・いる場所。入室画面と同じ白いパステルのデザイン。
 *  - 下: 参加している人のキャラクター（入室すると上から弾んで出てくる）。クリックでその人に切り替え。
 * 人の情報は /admin/api/online から（管理ページと同じパスワードの内側）。
 */
interface Person {
  sid: string;
  name: string;
  look: string;
  stay: number;
  area: string;
  stamps: number;
  stampTotal: number;
  chats: number;
  /** この情報を受け取った時刻（滞在時間を、次の更新まで1秒ずつ進めて見せるため） */
  at: number;
}

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const KEY = { interval: "amplifire.show.interval2", shuffle: "amplifire.show.shuffle", strip: "amplifire.show.strip", bubbles: "amplifire.show.bubbles" };
/** 入室してから、この秒数がたった人だけを、大画面に映す（入ってすぐの荒らしが映らないように） */
const MIN_STAY_SEC = 30;
const INTERVALS = [8000, 12000, 15000, 20000, 30000, 60000];
const DEFAULT_INTERVAL = 15000;
const get = (k: string, d: string): string => {
  try {
    return localStorage.getItem(k) ?? d;
  } catch {
    return d;
  }
};
const set = (k: string, v: string): void => {
  try {
    localStorage.setItem(k, v);
  } catch {
    /* 保存できなくても動く */
  }
};

const api = <T,>(path: string): Promise<T> =>
  fetch(`/admin/api/${path}`, { cache: "no-store" }).then((r) => {
    if (!r.ok) throw new Error(`${path} ${r.status}`);
    return r.json() as Promise<T>;
  });

// ---------------------------------------------------------------- ゲーム画面（観客）
const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: "world",
  // ドット絵が滲まないように最近傍補間
  pixelArt: true,
  antialias: false,
  roundPixels: true,
  backgroundColor: "#1b2a1a",
  scale: { mode: Phaser.Scale.RESIZE, width: "100%", height: "100%" },
  audio: { noAudio: true },
  disableContextMenu: true,
  scene: [PreloadScene],
});
const spectator = new SpectatorScene();
game.scene.add("Spectate", spectator, false);
// 点検用（管理者の画面でだけ使う）
(window as unknown as { __show: unknown }).__show = { game, spectator };
let sceneReady = false;
game.events.on(EV_PROGRESS, (p: number) => {
  $("load-bar").style.width = `${Math.max(2, Math.round(p * 100))}%`;
});
game.events.on(EV_LOAD_ERROR, (failed: string[]) => {
  $("loading").querySelector("b")!.textContent = `素材の読み込みに失敗しました（${failed.length}件）`;
});
game.events.on(EV_READY, () => {
  sceneReady = true;
  $("loading").hidden = true;
  game.scene.start("Spectate");
  followCurrent();
});
game.events.on(EV_SPECTATE, (ok: boolean) => {
  $("offline").hidden = ok;
  if (ok) followCurrent();
});

/** いま映している人を、ゲーム画面で追う（人がいなければ、島ぜんたいを映す） */
function followCurrent(): void {
  if (!sceneReady) return;
  spectator.follow(people.some((p) => p.sid === currentSid) ? currentSid : null);
}

// ---------------------------------------------------------------- 状態
let people: Person[] = [];
let areaNames = new Map<string, string>();
let queue: string[] = [];
let currentSid = "";
let paused = false;
const savedInterval = Number(get(KEY.interval, String(DEFAULT_INTERVAL)));
let intervalMs = INTERVALS.includes(savedInterval) ? savedInterval : DEFAULT_INTERVAL;
let shuffle = get(KEY.shuffle, "1") === "1";
let showStrip = get(KEY.strip, "1") === "1";
/** 発言のふきだしを、ゲーム画面に出すか（既定は出さない） */
let showBubbles = get(KEY.bubbles, "0") === "1";
let timer = 0;
let demoIdx = 0;

const hero = new AvatarPreview($<HTMLCanvasElement>("hero"));
hero.start();
const lookOf = (s: string): Look => decodeLook(s) ?? { hair: HAIRS[0] };
const personOf = (sid: string): Person | undefined => people.find((p) => p.sid === sid);
/** 大画面に映してよい人（入室から MIN_STAY_SEC 秒たった人）。いないときは、島ぜんたいと見本のアバターを出す */
const elig = (): Person[] => people.filter((p) => stayOf(p) >= MIN_STAY_SEC);

// ---------------------------------------------------------------- 表示の部品
function areaLabel(p: Person): string {
  const a = p.area ? areaNames.get(p.area) : "";
  return a || "そとの みち";
}

/** 滞在時間: 42秒 / 12分34秒 / 1時間05分 */
function fmtStay(sec: number): string {
  const s = Math.max(0, Math.floor(sec));
  if (s < 60) return `${s}秒`;
  if (s < 3600) return `${Math.floor(s / 60)}分${String(s % 60).padStart(2, "0")}秒`;
  return `${Math.floor(s / 3600)}時間${String(Math.floor((s % 3600) / 60)).padStart(2, "0")}分`;
}
const stayOf = (p: Person): number => p.stay + (Date.now() - p.at) / 1000;

function fitName(el: HTMLElement, text: string): void {
  el.textContent = text;
  const n = Array.from(text).length;
  el.style.fontSize = `${n > 9 ? 3.4 : n > 6 ? 4.4 : 5.4}vh`;
}

/** かざり（あたま・て）を、アバターのまわりに回る小さな絵にする */
async function buildOrbit(look: Look): Promise<void> {
  const box = $("orbit");
  box.replaceChildren();
  await loadStampSheet();
  const ids = [look.head, look.hand].filter((x): x is NonNullable<typeof x> => !!x);
  ids.forEach((id, i) => {
    const f = stampFrame(id);
    const url = stampIconUrl(f, 4);
    if (!url) return;
    const wrap = document.createElement("div");
    wrap.className = "orb";
    wrap.style.animationDelay = `${-i * 4}s`;
    const img = new Image();
    img.src = url;
    img.alt = "";
    wrap.append(img);
    box.append(wrap);
  });
}

/** 右の情報（滞在時間など、時間で変わるものは毎秒ここで更新する） */
function renderStats(p: Person | null): void {
  if (!p) return;
  const total = p.stampTotal || 0;
  $("st-stamps").firstChild!.textContent = String(p.stamps);
  $("st-total").textContent = total ? `/ ${total}` : "";
  $("st-meter").style.width = total ? `${Math.round((p.stamps / total) * 100)}%` : "0%";
  $("st-stay").textContent = fmtStay(stayOf(p));
  $("st-chats").firstChild!.textContent = String(p.chats);
  $("st-area").textContent = areaLabel(p);
  $("sub").textContent = `📍 ${areaLabel(p)}`;
  $("cam-name").textContent = p.name;
}

function display(p: { name: string; look: string }, person: Person | null, burstAt = true): void {
  const stage = $("stage");
  stage.classList.remove("enter");
  void stage.offsetWidth; // アニメを最初からやり直す
  stage.classList.add("enter");
  const look = lookOf(p.look);
  hero.setLook(look);
  window.setTimeout(() => hero.wave(), 450);
  fitName($("name"), p.name);
  if (person) renderStats(person);
  else $("sub").textContent = "ようこそ！";
  const idx = person ? people.findIndex((x) => x.sid === person.sid) : -1;
  $("order").textContent = person ? `${idx + 1} / ${people.length} 人目` : "";
  void buildOrbit(look);
  restartBar();
  if (burstAt) {
    const r = $("hero-box").getBoundingClientRect();
    burst(r.left + r.width / 2, r.top + r.height / 2, 70);
  }
  markStrip();
}

function restartBar(): void {
  const bar = $("bar");
  bar.style.animation = "none";
  void bar.offsetWidth;
  bar.style.animation = paused ? "none" : `bar ${intervalMs}ms linear forwards`;
  bar.style.width = paused ? "100%" : "";
}

// ---------------------------------------------------------------- 順番
function refill(): void {
  const sids = elig().map((p) => p.sid);
  if (shuffle) {
    for (let i = sids.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [sids[i], sids[j]] = [sids[j], sids[i]];
    }
  }
  queue = sids;
}

/** この人を映す（ゲーム画面で追い、右の情報を出す） */
function show(p: Person): void {
  currentSid = p.sid;
  display(p, p);
  if (sceneReady) spectator.follow(p.sid);
}

/** 次の人を映す（いなくなった人は飛ばす）。だれもいなければ、島ぜんたいと見本のアバターを出す */
function next(step: 1 | -1 = 1): void {
  window.clearTimeout(timer);
  const pool = elig();
  $("wait").hidden = pool.length > 0;
  document.body.classList.toggle("empty", pool.length === 0);
  if (!pool.length) {
    currentSid = "";
    const hair = HAIRS[demoIdx++ % HAIRS.length];
    display({ name: "AMPLIFIRE", look: encodeLook({ hair }) }, null);
    if (sceneReady) spectator.follow(null);
    schedule();
    return;
  }
  let p: Person | undefined;
  if (step === -1) {
    const i = pool.findIndex((x) => x.sid === currentSid);
    p = pool[(i - 1 + pool.length) % pool.length];
  } else {
    for (let guard = 0; guard < 3 && !p; guard++) {
      if (!queue.length) refill();
      while (queue.length && !p) {
        const sid = queue.shift()!;
        p = elig().find((x) => x.sid === sid);
      }
    }
  }
  p ??= pool[0];
  show(p);
  schedule();
}

function schedule(): void {
  window.clearTimeout(timer);
  if (paused) return;
  timer = window.setTimeout(() => next(1), intervalMs);
}

// ---------------------------------------------------------------- 下のキャラクター一覧
let stripSig = "";
const known = new Set<string>();
function buildStrip(): void {
  const strip = $("strip");
  const sig = people.map((p) => `${p.sid}|${p.look}|${p.name}|${p.stamps}`).join(",");
  if (sig === stripSig) return;
  stripSig = sig;
  strip.replaceChildren();
  for (const p of people.slice(0, 40)) {
    const th = document.createElement("div");
    th.className = "thumb";
    th.dataset.sid = p.sid;
    // すでにいた人は、弾んで出る動きを付けない（一覧を作り直すたびに全員が動かないように）
    if (known.has(p.sid)) th.style.animation = "none";
    known.add(p.sid);
    const cv = document.createElement("canvas");
    const av = new AvatarPreview(cv);
    av.setLook(lookOf(p.look));
    const nm = document.createElement("span");
    nm.textContent = p.name;
    const st = document.createElement("em");
    st.textContent = p.stampTotal ? `⭐ ${p.stamps}` : "";
    th.append(cv, nm, st);
    th.addEventListener("click", () => {
      show(p);
      schedule();
    });
    strip.append(th);
  }
  markStrip();
}

function markStrip(): void {
  for (const el of document.querySelectorAll<HTMLElement>("#strip .thumb")) {
    const on = el.dataset.sid === currentSid;
    el.classList.toggle("on", on);
    if (on) el.scrollIntoView({ inline: "center", block: "nearest", behavior: "smooth" });
  }
}

// ---------------------------------------------------------------- データの取得
async function poll(): Promise<void> {
  try {
    const list = await api<Omit<Person, "at">[]>("online");
    const at = Date.now();
    const prevEmpty = elig().length === 0;
    people = list.map((x) => ({ ...x, at })).sort((a, b) => b.stay - a.stay);
    for (const sid of [...known]) if (!people.some((p) => p.sid === sid)) known.delete(sid);
    $("count").textContent = String(people.length);
    buildStrip();
    const cur = elig().find((x) => x.sid === currentSid);
    if (cur) renderStats(cur);
    const now = elig().length;
    if (prevEmpty && now) next(1); // 映してよい人（入室から30秒たった人）が出たら、すぐ映す
    else if (!now && !prevEmpty) next(1);
    else if (now && !cur) next(1); // 追っていた人が退室したら、次の人へ
  } catch (e) {
    console.warn("[show]", e);
  }
}

/** 会場限定モードのとき、入室用の QR を、右の情報の下に出す（コードが切り替わるときも、1分ごとに更新） */
async function loadVenue(): Promise<void> {
  try {
    const v = await api<{ enabled: boolean; svg?: string }>("venue");
    $("venue").hidden = !v.enabled || !v.svg;
    if (v.enabled && v.svg) $("venue-qr").innerHTML = v.svg;
  } catch {
    /* QR が出せなくても動く */
  }
}

async function loadAreas(): Promise<void> {
  try {
    const s = await api<{ stalls: { id: string; name: string }[] }>("summary");
    areaNames = new Map(s.stalls.map((x) => [x.id, x.name]));
  } catch {
    /* 場所の名前が無くても動く */
  }
}

// ---------------------------------------------------------------- かざり（パーティクル）
interface Spark {
  x: number; y: number; vx: number; vy: number; life: number; max: number; size: number; color: string; kind: 0 | 1 | 2; rot: number; vr: number;
}
const COLORS = ["#79d4ff", "#ffb0d6", "#c4b5ff", "#fff0a0", "#aeeed4", "#ffffff", "#ffd2a8"];
const sparks: Spark[] = [];
const fx = $<HTMLCanvasElement>("fx");
const g = fx.getContext("2d")!;
/** 描く範囲は、window の大きさではなく、canvas が実際に表示されている大きさ（CSS px）から決める。
 *  ブラウザの拡大率・画面の縮尺が変わっても、消し残し（下や右に色の筋が残る）が出ないようにするため。 */
let W = innerWidth;
let H = innerHeight;
let DPR = 1;
/** ゲーム画面の範囲（粒を、この上には描かない） */
let hole = { x: 0, y: 0, w: 0, h: 0 };
function resize(): void {
  const r = fx.getBoundingClientRect();
  W = Math.max(1, Math.round(r.width));
  H = Math.max(1, Math.round(r.height));
  DPR = Math.min(2, devicePixelRatio || 1);
  fx.width = Math.round(W * DPR);
  fx.height = Math.round(H * DPR);
  const w = $("world-wrap").getBoundingClientRect();
  hole = { x: w.left, y: w.top, w: w.width, h: w.height };
}
resize();
addEventListener("resize", resize);
new ResizeObserver(resize).observe(fx);
new ResizeObserver(resize).observe($("world-wrap"));

function burst(x: number, y: number, n: number): void {
  for (let i = 0; i < n; i++) {
    const a = Math.random() * Math.PI * 2;
    const sp = 120 + Math.random() * 520;
    sparks.push({
      x, y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp - 120, life: 0, max: 1.1 + Math.random() * 1.2,
      size: 3 + Math.random() * 7, color: COLORS[Math.floor(Math.random() * COLORS.length)], kind: (Math.floor(Math.random() * 3) as 0 | 1 | 2), rot: Math.random() * 6, vr: (Math.random() - 0.5) * 10,
    });
  }
}
function ambient(): void {
  if (sparks.length > 160) return;
  // 下から湧く。ゲーム画面の外（右の情報の側と、下の一覧の側）に出す
  const x = Math.random() < 0.5 ? hole.x + hole.w + Math.random() * (W - hole.x - hole.w) : Math.random() * W;
  sparks.push({
    x, y: H + 10, vx: (Math.random() - 0.5) * 30, vy: -(30 + Math.random() * 70), life: 0, max: 5 + Math.random() * 4,
    size: 2 + Math.random() * 5, color: COLORS[Math.floor(Math.random() * COLORS.length)], kind: 0, rot: Math.random() * 6, vr: (Math.random() - 0.5) * 2,
  });
}
function star(x: number, y: number, r: number, rot: number): void {
  g.beginPath();
  for (let i = 0; i < 4; i++) {
    const a = rot + (i * Math.PI) / 2;
    g.lineTo(x + Math.cos(a) * r, y + Math.sin(a) * r);
    g.lineTo(x + Math.cos(a + Math.PI / 4) * r * 0.28, y + Math.sin(a + Math.PI / 4) * r * 0.28);
  }
  g.closePath();
  g.fill();
}
let last = performance.now();
function frame(now: number): void {
  const dt = Math.min(0.05, (now - last) / 1000);
  last = now;
  // 毎フレーム、変換を戻して canvas 全体を消してから、CSS px の座標系で描く
  g.setTransform(1, 0, 0, 1, 0, 0);
  g.clearRect(0, 0, fx.width, fx.height);
  g.setTransform(DPR, 0, 0, DPR, 0, 0);
  // ゲーム画面の範囲は切り抜いて、その上には粒を出さない（ゲームの絵が見づらくならないように）
  g.save();
  g.beginPath();
  g.rect(0, 0, W, H);
  g.rect(hole.x, hole.y, hole.w, hole.h);
  g.clip("evenodd");
  if (Math.random() < 0.5) ambient();
  for (let i = sparks.length - 1; i >= 0; i--) {
    const s = sparks[i];
    s.life += dt;
    if (s.life >= s.max || s.y > H + 80 || s.x < -80 || s.x > W + 80) { sparks.splice(i, 1); continue; }
    s.vy += (s.kind === 1 ? 420 : 40) * dt;
    s.x += s.vx * dt; s.y += s.vy * dt; s.rot += s.vr * dt;
    s.vx *= 0.992;
    const t = s.life / s.max;
    g.globalAlpha = t < 0.15 ? t / 0.15 : 1 - Math.pow((t - 0.15) / 0.85, 1.5);
    g.fillStyle = s.color;
    if (s.kind === 0) star(s.x, s.y, s.size * 1.6, s.rot);
    else if (s.kind === 1) { g.save(); g.translate(s.x, s.y); g.rotate(s.rot); g.fillRect(-s.size / 2, -s.size / 4, s.size, s.size / 2); g.restore(); }
    else { g.beginPath(); g.arc(s.x, s.y, s.size / 2, 0, Math.PI * 2); g.fill(); }
  }
  g.globalAlpha = 1;
  g.restore();
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);

// ---------------------------------------------------------------- 操作
const sync = (): void => {
  $("c-pause").textContent = paused ? "▶" : "⏸";
  $("c-shuffle").classList.toggle("on", shuffle);
  $("c-names").classList.toggle("on", showStrip);
  $("c-bubbles").classList.toggle("on", showBubbles);
  spectator.setBubbles(showBubbles);
  document.body.classList.toggle("no-strip", !showStrip);
  ($("c-interval") as HTMLSelectElement).value = String(intervalMs);
};
$("c-prev").addEventListener("click", () => next(-1));
$("c-next").addEventListener("click", () => next(1));
$("c-pause").addEventListener("click", () => { paused = !paused; restartBar(); schedule(); sync(); });
$("c-shuffle").addEventListener("click", () => { shuffle = !shuffle; set(KEY.shuffle, shuffle ? "1" : "0"); queue = []; sync(); });
$("c-names").addEventListener("click", () => { showStrip = !showStrip; set(KEY.strip, showStrip ? "1" : "0"); sync(); });
$("c-bubbles").addEventListener("click", () => { showBubbles = !showBubbles; set(KEY.bubbles, showBubbles ? "1" : "0"); sync(); });
$("c-interval").addEventListener("change", (e) => { intervalMs = Number((e.target as HTMLSelectElement).value) || DEFAULT_INTERVAL; set(KEY.interval, String(intervalMs)); restartBar(); schedule(); });
const fs = (): void => { if (document.fullscreenElement) void document.exitFullscreen(); else void document.documentElement.requestFullscreen().catch(() => undefined); };
$("c-full").addEventListener("click", fs);
addEventListener("keydown", (e) => {
  if (e.key === "ArrowRight") next(1);
  else if (e.key === "ArrowLeft") next(-1);
  else if (e.key === " ") { e.preventDefault(); $("c-pause").click(); }
  else if (e.key === "f" || e.key === "F") fs();
  else if (e.key === "s" || e.key === "S") $("c-shuffle").click();
  else if (e.key === "t" || e.key === "T") $("c-names").click();
  else if (e.key === "b" || e.key === "B") $("c-bubbles").click();
});
// 操作パネルは、マウスを動かしたときだけ出す（大型ディスプレイで邪魔にならないように）
let idle = 0;
const wake = (): void => {
  document.body.classList.add("awake");
  window.clearTimeout(idle);
  idle = window.setTimeout(() => document.body.classList.remove("awake"), 3000);
};
addEventListener("mousemove", wake);
addEventListener("touchstart", wake);
wake();

sync();
void loadAreas();
void loadVenue();
window.setInterval(loadVenue, 60000);
void poll().then(() => next(1));
window.setInterval(poll, 3000);
window.setInterval(loadAreas, 60000);
// 滞在時間は、次の更新を待たず、1秒ごとに進めて見せる
window.setInterval(() => {
  const p = personOf(currentSid);
  if (p) $("st-stay").textContent = fmtStay(stayOf(p));
}, 1000);
