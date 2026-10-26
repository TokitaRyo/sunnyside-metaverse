/* AMPLIFIRE のサービスワーカー（PWA）。ビルドのときに、__BUILD_ID__ を入れて、dist/sw.js として出す（client/vite.config.ts）。
 *
 * 役目: ①ホーム画面に入れる（インストール）できるようにする ②2回目からの読み込みを速くする（画像・JS・CSS を端末に覚える）
 *       ③通信できないときに、「オフラインです」の画面を出す。
 * ゲームそのもの（入室・チャット・移動）は、サーバーとの常時接続が要るので、オフラインでは遊べない。
 *
 * 守ること:
 *  - 入室の予約（/matchmake）・管理ページ（/admin）・合言葉の入り口（/__gate）・Playground・WebSocket・POST などは、何もせず、通常どおり通す。
 *  - 音楽（mp3 など）は触らない（Range 要求があり、ブラウザに任せたほうが確実）。
 *  - 成功した応答（200）だけを覚える。合言葉のログイン画面（401）などを、覚えない。
 */
"use strict";

const BUILD = "__BUILD_ID__";
/** ビルドごとの入れ物（オフライン用のページなど、小さいもの） */
const STATIC_CACHE = `amplifire-static-${BUILD}`;
/** 画像・JS・CSS など（ビルドをまたいで使う。新しい版は、裏で取り直す） */
const RUNTIME_CACHE = "amplifire-runtime-v1";
const OFFLINE_URL = "/offline.html";
/** 覚える数の上限（超えたら、古いものから消す） */
const MAX_RUNTIME_ENTRIES = 600;

const HASHED = /^\/assets\/.+-[A-Za-z0-9_-]{8}\.(?:js|css)$/;
const STATIC_FILE = /\.(?:png|jpg|jpeg|webp|gif|svg|ico|json|webmanifest|woff2?|ttf)$/i;
const PASS_THROUGH = /^\/(?:admin|matchmake|__gate|playground|show\.html)(?:\/|$)/;
const MEDIA = /\.(?:mp3|ogg|wav|m4a)$/i;

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(STATIC_CACHE)
      .then((c) => c.addAll([OFFLINE_URL, "/icons/icon-192.png"]))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      // 古いビルドの入れ物を消す
      for (const k of await caches.keys()) if (k.startsWith("amplifire-static-") && k !== STATIC_CACHE) await caches.delete(k);
      await self.clients.claim();
    })(),
  );
});

/** 入れ物が大きくなりすぎたら、古いものから消す */
async function trim(cache) {
  const keys = await cache.keys();
  for (let i = 0; i < keys.length - MAX_RUNTIME_ENTRIES; i++) await cache.delete(keys[i]);
}

async function put(cache, request, response) {
  if (response && response.status === 200 && response.type === "basic") {
    await cache.put(request, response.clone());
    void trim(cache);
  }
  return response;
}

/** 覚えているものを先に返し、裏で最新を取り直す（stale-while-revalidate） */
async function staleWhileRevalidate(event) {
  const cache = await caches.open(RUNTIME_CACHE);
  const cached = await cache.match(event.request);
  const refresh = fetch(event.request).then((r) => put(cache, event.request, r)).catch(() => undefined);
  if (cached) {
    event.waitUntil(refresh);
    return cached;
  }
  return (await refresh) ?? Response.error();
}

/** 名前に中身の識別子（ハッシュ）が入っているもの。覚えていれば、そのまま返す（変わらないので） */
async function cacheFirst(request) {
  const cache = await caches.open(RUNTIME_CACHE);
  const cached = await cache.match(request);
  if (cached) return cached;
  return put(cache, request, await fetch(request));
}

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  const path = url.pathname;
  if (PASS_THROUGH.test(path) || path === "/sw.js" || MEDIA.test(path) || req.headers.has("range")) return;

  // ページ本体: いつも最新を取る。通信できないときだけ、オフラインの画面
  if (req.mode === "navigate") {
    event.respondWith(
      fetch(req).catch(async () => (await caches.match(OFFLINE_URL)) ?? new Response("オフラインです", { status: 503, headers: { "content-type": "text/plain; charset=utf-8" } })),
    );
    return;
  }
  if (HASHED.test(path)) {
    event.respondWith(cacheFirst(req));
    return;
  }
  if (STATIC_FILE.test(path)) {
    event.respondWith(staleWhileRevalidate(event));
  }
});
