import "./show.css";
import { HAIRS, decodeLook, encodeLook, type Look } from "@metaverse/shared";
import { AvatarPreview } from "../ui/AvatarPreview";
import { STAMP_FRAME, loadStampSheet, stampFrame, stampIconUrl } from "../game/stampIcons";

/**
 * 管理者用のショー画面。入室中の人のアバターと名前を、一定の間隔で切り替えながら画面いっぱいに映す。
 * 見せ方は入室画面の「決定したあとの大きな表示」と同じ（白いパステル・ふちの輪・手をふる）で、飾りを増やしてある。
 * 人の情報は /admin/api/online から（管理ページと同じパスワードの内側）。
 */
interface Person {
  sid: string;
  name: string;
  look: string;
  stay: number;
  area: string;
}

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const KEY = { interval: "amplifire.show.interval", shuffle: "amplifire.show.shuffle", strip: "amplifire.show.strip" };
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

// ---------------------------------------------------------------- 状態
let people: Person[] = [];
let areaNames = new Map<string, string>();
let queue: string[] = [];
let currentSid = "";
let paused = false;
let intervalMs = Number(get(KEY.interval, "6000")) || 6000;
let shuffle = get(KEY.shuffle, "1") === "1";
let showStrip = get(KEY.strip, "1") === "1";
let timer = 0;
let demoIdx = 0;

const hero = new AvatarPreview($<HTMLCanvasElement>("hero"));
hero.start();
const lookOf = (s: string): Look => decodeLook(s) ?? { hair: HAIRS[0] };

// ---------------------------------------------------------------- 画面の更新
function areaLabel(p: Person): string {
  const a = p.area ? areaNames.get(p.area) : "";
  return a ? `📍 ${a}` : "📍 そとの みち";
}

function fitName(el: HTMLElement, text: string): void {
  el.textContent = text;
  const n = Array.from(text).length;
  el.style.fontSize = `${n > 9 ? 5.2 : n > 6 ? 6.6 : 8}vmin`;
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

function display(p: { name: string; look: string; sub: string }, burstAt = true): void {
  const stage = $("stage");
  stage.classList.remove("enter");
  void stage.offsetWidth; // アニメを最初からやり直す
  stage.classList.add("enter");
  const look = lookOf(p.look);
  hero.setLook(look);
  window.setTimeout(() => hero.wave(), 450);
  fitName($("name"), p.name);
  $("sub").textContent = p.sub;
  void buildOrbit(look);
  restartBar();
  if (burstAt) burst(W / 2, H * 0.46, 70);
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
  const sids = people.map((p) => p.sid);
  if (shuffle) {
    for (let i = sids.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [sids[i], sids[j]] = [sids[j], sids[i]];
    }
  }
  queue = sids;
}

/** 次の人を映す（いなくなった人は飛ばす）。だれもいなければ、見本のアバターを回す */
function next(step: 1 | -1 = 1): void {
  window.clearTimeout(timer);
  const wait = $("wait");
  wait.hidden = people.length > 0;
  document.body.classList.toggle("empty", people.length === 0);
  if (!people.length) {
    const hair = HAIRS[demoIdx++ % HAIRS.length];
    display({ name: "AMPLIFIRE", look: encodeLook({ hair }), sub: "ようこそ！" });
    schedule();
    return;
  }
  let p: Person | undefined;
  if (step === -1) {
    const i = people.findIndex((x) => x.sid === currentSid);
    p = people[(i - 1 + people.length) % people.length];
  } else {
    for (let guard = 0; guard < 3 && !p; guard++) {
      if (!queue.length) refill();
      while (queue.length && !p) {
        const sid = queue.shift()!;
        p = people.find((x) => x.sid === sid);
      }
    }
  }
  p ??= people[0];
  currentSid = p.sid;
  display({ name: p.name, look: p.look, sub: `${areaLabel(p)}${p.stay >= 60 ? `　・　入室 ${Math.floor(p.stay / 60)}分` : ""}` });
  schedule();
}

function schedule(): void {
  window.clearTimeout(timer);
  if (paused) return;
  timer = window.setTimeout(() => next(1), intervalMs);
}

// ---------------------------------------------------------------- 下の一覧
let stripSig = "";
function buildStrip(): void {
  const strip = $("strip");
  const sig = people.map((p) => p.sid + p.look).join("|");
  if (sig === stripSig) return;
  stripSig = sig;
  strip.replaceChildren();
  for (const p of people.slice(0, 40)) {
    const th = document.createElement("div");
    th.className = "thumb";
    th.dataset.sid = p.sid;
    const cv = document.createElement("canvas");
    const av = new AvatarPreview(cv);
    av.setLook(lookOf(p.look));
    const nm = document.createElement("span");
    nm.textContent = p.name;
    th.append(cv, nm);
    th.addEventListener("click", () => {
      currentSid = p.sid;
      display({ name: p.name, look: p.look, sub: `${areaLabel(p)}${p.stay >= 60 ? `　・　入室 ${Math.floor(p.stay / 60)}分` : ""}` });
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
    const list = await api<Person[]>("online");
    const prevEmpty = people.length === 0;
    people = list.sort((a, b) => b.stay - a.stay);
    $("count").textContent = String(people.length);
    buildStrip();
    if (prevEmpty && people.length) next(1); // だれかが入ったら、すぐ映す
    if (!people.length && !prevEmpty) next(1);
  } catch (e) {
    console.warn("[show]", e);
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
function resize(): void {
  const r = fx.getBoundingClientRect();
  W = Math.max(1, Math.round(r.width));
  H = Math.max(1, Math.round(r.height));
  DPR = Math.min(2, devicePixelRatio || 1);
  fx.width = Math.round(W * DPR);
  fx.height = Math.round(H * DPR);
}
resize();
addEventListener("resize", resize);
new ResizeObserver(resize).observe(fx);

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
  sparks.push({
    x: Math.random() * W, y: H + 10, vx: (Math.random() - 0.5) * 30, vy: -(30 + Math.random() * 70), life: 0, max: 5 + Math.random() * 4,
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
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);

// ---------------------------------------------------------------- 操作
const sync = (): void => {
  $("c-pause").textContent = paused ? "▶" : "⏸";
  $("c-shuffle").classList.toggle("on", shuffle);
  $("c-names").classList.toggle("on", showStrip);
  document.body.classList.toggle("no-strip", !showStrip);
  ($("c-interval") as HTMLSelectElement).value = String(intervalMs);
};
$("c-prev").addEventListener("click", () => next(-1));
$("c-next").addEventListener("click", () => next(1));
$("c-pause").addEventListener("click", () => { paused = !paused; restartBar(); schedule(); sync(); });
$("c-shuffle").addEventListener("click", () => { shuffle = !shuffle; set(KEY.shuffle, shuffle ? "1" : "0"); queue = []; sync(); });
$("c-names").addEventListener("click", () => { showStrip = !showStrip; set(KEY.strip, showStrip ? "1" : "0"); sync(); });
$("c-interval").addEventListener("change", (e) => { intervalMs = Number((e.target as HTMLSelectElement).value) || 6000; set(KEY.interval, String(intervalMs)); restartBar(); schedule(); });
const fs = (): void => { if (document.fullscreenElement) void document.exitFullscreen(); else void document.documentElement.requestFullscreen().catch(() => undefined); };
$("c-full").addEventListener("click", fs);
addEventListener("keydown", (e) => {
  if (e.key === "ArrowRight") next(1);
  else if (e.key === "ArrowLeft") next(-1);
  else if (e.key === " ") { e.preventDefault(); $("c-pause").click(); }
  else if (e.key === "f" || e.key === "F") fs();
  else if (e.key === "s" || e.key === "S") $("c-shuffle").click();
  else if (e.key === "t" || e.key === "T") $("c-names").click();
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
void poll().then(() => next(1));
window.setInterval(poll, 4000);
window.setInterval(loadAreas, 60000);
// 切り替えの間隔を待たずに、下の一覧の「入室 ◯分」などを新しくするため、人が変わったときは次の切り替えで反映される
void STAMP_FRAME;
