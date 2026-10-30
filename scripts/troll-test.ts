/**
 * 荒らし対策の確認（荒らしのふりをするボット）。サーバーを、試験用の環境変数つきで起動してから、段階ごとに実行する:
 *
 *  段階 main（機能の確認。安全装置は、この段階では働かないように、しきい値を高くしておく）:
 *    MOD_NEWCOMER_SEC=5 MOD_CHAT_GAP_SEC=1 MOD_REPORTER_MIN_SEC=3 MOD_BREAKER_THRESHOLD=100 を付けて起動
 *    URL=ws://localhost:2570 ADMIN_PW=… npx tsx scripts/troll-test.ts main
 *  段階 breaker（全体の安全装置・手動の定型文だけ・退室の待ち時間）:
 *    MOD_NEWCOMER_SEC=5 MOD_CHAT_GAP_SEC=1 MOD_BREAKER_THRESHOLD=6 MOD_BREAKER_SEC=8 を付けて起動 → … troll-test.ts breaker
 *  段階 join（入室のしすぎ・同じ回線の止め）:
 *    MOD_STRICT_LOCAL=1 MOD_JOIN_PER_MIN=5 を付けて起動 → … troll-test.ts join
 *  段階 gate（本番の「関係者だけ」の入り口。合言葉）:
 *    SITE_LOCK=1 を付けて起動（合言葉は ADMIN_PASSWORD）→ … troll-test.ts gate
 *  段階 venue（会場限定モード）:
 *    VENUE_CODE=venue-test-code を付けて起動 → … troll-test.ts venue
 *  段階 rta（スタンプRTA・ランキング。ずるが通らないこと・本物の走りが記録されること。約1分半）:
 *    試験用の設定なしで起動 → … troll-test.ts rta
 *
 * 全部 PASS なら、終了コード 0。
 */
import { readFileSync } from "node:fs";
import { Client, type Room } from "@colyseus/sdk";
import { CONSENT_VERSION, MSG, PHRASES, ROOM_NAME, MainRoomState, type ChatBroadcast, type ChatState, type ModNotice } from "@metaverse/shared";

const URL_ = process.env.URL ?? "ws://localhost:2567";
const HTTP = URL_.replace(/^ws/, "http");
const ADMIN_PW = process.env.ADMIN_PW ?? "local-test-admin-pass";
const phase = process.argv[2] ?? "main";
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

let pass = 0;
let fail = 0;
const check = (name: string, ok: boolean, detail = ""): void => {
  if (ok) pass++;
  else fail++;
  console.log(`${ok ? "PASS" : "FAIL"}  ${name}${detail ? "  — " + detail : ""}`);
};

interface Bot {
  room: Room<any, MainRoomState>;
  name: string;
  vid: string;
  chats: ChatBroadcast[];
  notices: ModNotice[];
  emotes: number;
  states: ChatState[];
  me: () => { name: string } | undefined;
  say: (text: string) => void;
  phrase: (id: number) => void;
  emote: () => void;
  report: (sid: string) => void;
}

let seq = 0;
const vidOf = (tag: string) => `troll-test-${tag}-${Date.now().toString(36)}-${seq++}-xxxxxxxx`;

async function join(name: string, opts: { vid?: string; venue?: string; spectator?: string; cookie?: string } = {}): Promise<Bot> {
  const vid = opts.vid ?? vidOf(name.slice(0, 4));
  const client = opts.cookie ? new Client(URL_, { headers: { Cookie: opts.cookie } }) : new Client(URL_);
  const room = (await client.join(ROOM_NAME, { name, hair: "mophair", consent: CONSENT_VERSION, vid, device: "desktop", venue: opts.venue }, MainRoomState)) as Room<any, MainRoomState>;
  const bot: Bot = {
    room,
    name,
    vid,
    chats: [],
    notices: [],
    emotes: 0,
    states: [],
    me: () => room.state.players.get(room.sessionId),
    say: (text) => room.send(MSG.chat, { text }),
    phrase: (id) => room.send(MSG.phrase, { id }),
    emote: () => room.send(MSG.emote, { id: "jump" }),
    report: (sessionId) => room.send(MSG.report, { sessionId }),
  };
  room.onMessage(MSG.chat, (m: ChatBroadcast) => bot.chats.push(m));
  room.onMessage(MSG.modNotice, (m: ModNotice) => bot.notices.push(m));
  room.onMessage(MSG.emote, () => bot.emotes++);
  room.onMessage(MSG.chatState, (m: ChatState) => bot.states.push(m));
  room.onMessage(MSG.chatDelete, () => undefined);
  room.onMessage(MSG.correct, () => undefined);
  await sleep(250);
  return bot;
}
const leave = (bots: Bot[]) => Promise.all(bots.map((b) => b.room.leave().catch(() => undefined)));
const got = (observer: Bot, from: Bot, text?: string) => observer.chats.some((c) => c.sessionId === from.room.sessionId && (text === undefined || c.text === text));
const noticeCodes = (b: Bot) => b.notices.map((n) => n.code);

async function adminPost(path: string, body: unknown): Promise<{ ok: boolean; status: number }> {
  const r = await fetch(`${HTTP}/admin/api/${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Admin": "1", Authorization: "Basic " + Buffer.from("x:" + ADMIN_PW).toString("base64") },
    body: JSON.stringify(body),
  });
  return { ok: r.ok, status: r.status };
}

// ------------------------------------------------------------------ 段階 main
async function main(): Promise<void> {
  const watcher = await join("みはりばん");

  // 1) なまえの検査
  const names = await Promise.all(["運営", "しね", "http://evil.example", "ＬＩＮＥ交換", "おしらせ", "たろう", "badminton", "ADMIN"].map((n) => join(n)));
  const shown = names.map((b) => b.me()?.name ?? "");
  check("名前: 「運営」は使えない（ゲスト+数字に置き換え）", /^ゲスト\d+$/.test(shown[0]), shown[0]);
  check("名前: 暴言の名前は使えない", /^ゲスト\d+$/.test(shown[1]), shown[1]);
  check("名前: URL の名前は使えない", /^ゲスト\d+$/.test(shown[2]), shown[2]);
  check("名前: 全角の「LINE交換」は使えない", /^ゲスト\d+$/.test(shown[3]), shown[3]);
  check("名前: 「おしらせ」は使えない", /^ゲスト\d+$/.test(shown[4]), shown[4]);
  check("名前: ふつうの名前は、そのまま", shown[5] === "たろう", shown[5]);
  check("名前: badminton のような、ふつうの英語は、巻き込まない", shown[6] === "badminton", shown[6]);
  check("名前: ADMIN（大文字）は使えない", /^ゲスト\d+$/.test(shown[7]), shown[7]);
  await leave(names);

  // 2) 新しい人は、すぐには書けない
  const fresh = await join("あたらしい");
  fresh.say("こんにちは");
  await sleep(400);
  check("新しい人: 入室直後は書けない（newcomer の知らせ）", noticeCodes(fresh).includes("newcomer") && !got(watcher, fresh), JSON.stringify(noticeCodes(fresh)));

  // 以降の試験用のボットを、まとめて入室させて、待つ（新しい人の待ち時間のぶん）
  const [c1, c2, c3, c4, c5, c6, c7, c8, c9] = await Promise.all(Array.from({ length: 9 }, (_, i) => join(`ボット${i + 1}`)));
  const tgt = await join("ひょうてき");
  const rep = await Promise.all([join("つうほう1"), join("つうほう2"), join("つうほう3")]);
  console.log("… 入室したばかりの人の待ち時間（5秒）を待ちます");
  await sleep(5600);

  fresh.say("もう かけるかな");
  await sleep(300);
  check("新しい人: 待ち時間のあとは書ける", got(watcher, fresh, "もう かけるかな"));

  // 3) 連絡先・URL・SNS
  c1.say("LINE交換しよう");
  c2.say("09012345678");
  c3.say("http://x.com/evil");
  c9.say("090 1234 5678 に でんわして");
  await sleep(500);
  check("連絡先: 「LINE交換」は送れない", noticeCodes(c1).includes("contact") && !got(watcher, c1));
  check("連絡先: 電話番号は送れない", noticeCodes(c2).includes("contact") && !got(watcher, c2));
  check("連絡先: URL は送れない", noticeCodes(c3).includes("contact") && !got(watcher, c3));
  check("連絡先: すき間を入れた電話番号も送れない", noticeCodes(c9).includes("contact") && !got(watcher, c9));
  c5.say("らいんの ID おしえて");
  await sleep(300);
  check("連絡先: ひらがなの「らいん」＋「おしえて」も送れない", noticeCodes(c5).includes("contact") && !got(watcher, c5));
  await sleep(1100);
  c5.say("ライン川は きれいだね");
  await sleep(300);
  check("連絡先: ふつうの文は、そのまま送れる（誤検出しない）", got(watcher, c5, "ライン川は きれいだね"));

  // 4) NG ワード
  c4.say("し ね");
  await sleep(300);
  check("NGワード: すき間を入れた言い換えは送れない", noticeCodes(c4).includes("badword") && !got(watcher, c4));
  await sleep(1100);
  c4.say("きみは しね");
  await sleep(300);
  check("NGワード: そのままのものは、伏字にして送る", got(watcher, c4, "きみは ＊＊"));
  await sleep(1100);
  c9.say("＊＊＊＊＊");
  c8.say("しね");
  await sleep(300);
  check("NGワード: 伏字だけになる書き込みは、送らない", !got(watcher, c8));

  // 5) 同じ文・連投・連打
  c6.say("おはよう");
  await sleep(1100);
  c6.say("おはよう");
  await sleep(300);
  check("連投: 同じ文は、続けて送れない", noticeCodes(c6).includes("dup") && watcher.chats.filter((c) => c.sessionId === c6.room.sessionId).length === 1);
  c7.say("あ1");
  c7.say("あ2");
  c7.say("あ3");
  await sleep(400);
  check("連投: 間隔をおかない書き込みは、最初の1通だけ", watcher.chats.filter((c) => c.sessionId === c7.room.sessionId).length === 1 && noticeCodes(c7).includes("fast"));
  c8.say("あああああああああああ");
  await sleep(300);
  check("連投: 同じ文字の長い繰り返しは送れない", !got(watcher, c8));
  const before = watcher.emotes;
  for (let i = 0; i < 12; i++) c8.emote();
  await sleep(500);
  check("エモート: 連打しても、周りに届くのは1回だけ", watcher.emotes - before === 1, `届いた数=${watcher.emotes - before}`);

  // 6) 違反の点数 → 自動でチャット停止
  const troll = await join("あらし");
  await sleep(5600);
  for (let i = 0; i < 3; i++) {
    troll.say("LINE交換しよう " + i);
    await sleep(1150);
  }
  check("点数: 違反が続くと、チャットを止める（muted の知らせ）", noticeCodes(troll).includes("muted"), JSON.stringify(noticeCodes(troll)));
  troll.say("ふつうの はなし");
  await sleep(300);
  check("点数: 止められたあとは、ふつうの書き込みも送れない", !got(watcher, troll));
  troll.phrase(0);
  await sleep(300);
  check("点数: 止められている人は、定型文も使えない", !got(watcher, troll, PHRASES[0]));

  // 7) 定型文
  c1.phrase(1);
  await sleep(300);
  check("定型文: 番号で送ると、決まった文が届く", got(watcher, c1, PHRASES[1]));

  // 8) 通報（別々の3人から → 自動でチャット停止）
  rep[0].report(tgt.room.sessionId);
  rep[1].report(tgt.room.sessionId);
  await sleep(300);
  tgt.say("まだ かける");
  await sleep(300);
  check("通報: 2人だけでは、止まらない", got(watcher, tgt, "まだ かける"));
  await sleep(1100);
  rep[2].report(tgt.room.sessionId);
  await sleep(400);
  tgt.say("止まったかな");
  await sleep(300);
  check("通報: 別々の3人から通報されると、自動でチャットが止まる", noticeCodes(tgt).includes("muted") && !got(watcher, tgt, "止まったかな"), JSON.stringify(noticeCodes(tgt)));
  check("通報: 通報した人には、受け付けた知らせが届く", noticeCodes(rep[0]).includes("report-ok"));
  rep[0].report(rep[0].room.sessionId);
  await sleep(200);
  check("通報: 自分は通報できない", noticeCodes(rep[0]).includes("report-ng"));

  await leave([watcher, fresh, c1, c2, c3, c4, c5, c6, c7, c8, c9, tgt, troll, ...rep]);
}

// ------------------------------------------------------------------ 段階 breaker
async function breakerPhase(): Promise<void> {
  const watcher = await join("みはりばん");
  const fresh = await join("ふつうの子");
  const mobs0 = await Promise.all(Array.from({ length: 8 }, (_, i) => join(`あらし${i + 1}`)));
  console.log("… 入室したばかりの人の待ち時間（5秒）を待ちます");
  await sleep(5600);
  const mobs = mobs0;
  // 9) 全体の安全装置（違反が急に増えたら、定型文だけ。時間がたつと自動で戻る）
  await Promise.all(mobs.map((m) => m.say("LINEの ID おしえて")));
  await sleep(600);
  check("安全装置: 違反が急に増えると、全員が「定型文だけ」になる", watcher.states.some((s) => s.phrases === true), JSON.stringify(watcher.states.slice(-2)));
  const clean = await join("ふつうの人");
  check("安全装置: あとから入った人にも、定型文だけの状態が伝わる", clean.states.some((s) => s.phrases === true));
  fresh.say("じゆうな ことば");
  await sleep(300);
  check("安全装置: 定型文だけの間は、自由な書き込みは送れない", noticeCodes(fresh).includes("phrases") && !got(watcher, fresh, "じゆうな ことば"));
  await sleep(1100);
  fresh.phrase(3);
  await sleep(300);
  check("安全装置: 定型文は、そのまま使える", got(watcher, fresh, PHRASES[3]));
  console.log("… 安全装置が自動で解けるのを待ちます（8秒）");
  await sleep(8500);
  check("安全装置: 時間がたつと、自動で、ふつうに戻る", watcher.states.at(-1)?.phrases === false, JSON.stringify(watcher.states.slice(-2)));
  await sleep(1100);
  fresh.say("もどった かな");
  await sleep(300);
  check("安全装置: 戻ったあとは、自由な書き込みが送れる", got(watcher, fresh, "もどった かな"));

  // 10) 運営が退室させた人は、すぐには入り直せない
  const victim = await join("たいしつ", {});
  const sid = victim.room.sessionId;
  const k = await adminPost("kick", { sid });
  await sleep(500);
  let reason = "";
  try {
    await join("たいしつ", { vid: victim.vid });
  } catch (e) {
    reason = e instanceof Error ? e.message : String(e);
  }
  check("退室: 運営が退室させた人は、すぐには入り直せない", k.ok && /退室|まって/.test(reason), `kick=${k.status} ${reason}`);

  // 11) 管理者の手動の「定型文だけ」
  const on = await adminPost("moderation/phrases", { on: true });
  await sleep(400);
  check("手動: 運営が「定型文だけ」にすると、全員に伝わる", on.ok && watcher.states.at(-1)?.phrases === true);
  await adminPost("moderation/phrases", { on: false });
  await sleep(400);
  check("手動: 解くと、元に戻る", watcher.states.at(-1)?.phrases === false);

  await leave([watcher, fresh, clean, ...mobs]);
}

// ------------------------------------------------------------------ 段階 join
async function joinPhase(): Promise<void> {
  const ok: Bot[] = [];
  let refused = "";
  for (let i = 0; i < 8; i++) {
    try {
      ok.push(await join(`いりぐち${i}`));
    } catch (e) {
      refused = e instanceof Error ? e.message : String(e);
      break;
    }
  }
  check("入室: 同じ回線から、1分に5回を超えると断る", ok.length === 5 && /はやすぎ/.test(refused), `入れた=${ok.length} ${refused}`);
  await leave(ok);
}

// ------------------------------------------------------------------ 段階 gate
async function gatePhase(): Promise<void> {
  const pw = ADMIN_PW;
  const html = { Accept: "text/html" };
  const r1 = await fetch(`${HTTP}/`, { headers: html });
  const body1 = await r1.text();
  check("入り口: 合言葉なしでは、ページが開けない（ログイン画面）", r1.status === 401 && body1.includes("合言葉") && !body1.includes('id="game"'), `status=${r1.status}`);
  const r2 = await fetch(`${HTTP}/atlas/manifest.json`);
  check("入り口: 素材（画像の目録）も開けない", r2.status === 401, `status=${r2.status}`);
  const r3 = await fetch(`${HTTP}/matchmake/joinOrCreate/main`, { method: "POST", headers: { "Content-Type": "application/json" }, body: "{}" });
  const b3 = await r3.text();
  check("入り口: 入室の予約（matchmake）も通らない（席をふさがれない）", r3.status === 403 && /関係者/.test(b3), `status=${r3.status} ${b3.slice(0, 80)}`);
  const r4 = await fetch(`${HTTP}/admin/api/online`);
  check("入り口: 管理ページは、独自の認証（Basic）が求められる", r4.status === 401 && !!r4.headers.get("www-authenticate"), `status=${r4.status}`);

  // PWA の部品は、入り口の外（ホーム画面に入れる・オフラインの画面のため）
  for (const p of ["/manifest.webmanifest", "/offline.html", "/icons/icon-192.png", "/sw.js"]) {
    const r = await fetch(`${HTTP}${p}`);
    check(`PWA: ${p} は、合言葉なしでも取れる`, r.status === 200, `status=${r.status}`);
  }
  const sw = await (await fetch(`${HTTP}/sw.js`)).text();
  check("PWA: sw.js に、ビルドの識別子が入っている（__BUILD_ID__ のままではない）", !sw.includes('"__BUILD_ID__"'), "");

  let noCookie = "";
  try {
    await join("もぐりこみ");
  } catch (e) {
    noCookie = e instanceof Error ? e.message : String(e);
  }
  check("入り口: Cookie なしの WebSocket 入室は、断られる", /関係者|アクセス|401|Unauthorized/.test(noCookie), noCookie);

  const bad = await fetch(`${HTTP}/__gate`, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: "pw=wrong-password-123", redirect: "manual" });
  const badBody = await bad.text();
  check("入り口: まちがった合言葉は、はじかれる", bad.status === 401 && badBody.includes("ちがいます") && !bad.headers.get("set-cookie"), `status=${bad.status}`);

  const ok = await fetch(`${HTTP}/__gate`, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: `pw=${encodeURIComponent(pw)}&next=%2F`, redirect: "manual" });
  const setCookie = ok.headers.get("set-cookie") ?? "";
  check("入り口: 正しい合言葉で、Cookie が付く（HttpOnly・SameSite）", ok.status === 303 && /amplifire_gate=/.test(setCookie) && /HttpOnly/i.test(setCookie) && /SameSite=Lax/i.test(setCookie), `status=${ok.status} ${setCookie.slice(0, 60)}`);
  const cookie = setCookie.split(";")[0];

  const r5 = await fetch(`${HTTP}/`, { headers: { ...html, Cookie: cookie } });
  const body5 = await r5.text();
  check("入り口: Cookie があれば、ページが開ける", r5.status === 200 && body5.includes('id="game"'), `status=${r5.status}`);
  const r6 = await fetch(`${HTTP}/atlas/manifest.json`, { headers: { Cookie: cookie } });
  check("入り口: Cookie があれば、素材も開ける", r6.status === 200, `status=${r6.status}`);
  const forged = await fetch(`${HTTP}/`, { headers: { ...html, Cookie: "amplifire_gate=9999999999999.forged" } });
  check("入り口: 偽の Cookie は通らない", forged.status === 401, `status=${forged.status}`);

  const good = await join("はいれる人", { cookie });
  check("入り口: Cookie があれば、WebSocket で入室できる", !!good.me());
  await leave([good]);

  const admin = await fetch(`${HTTP}/admin/api/online`, { headers: { Authorization: "Basic " + Buffer.from("x:" + pw).toString("base64") } });
  check("入り口: 管理者として認証できた人にも、Cookie が付く", admin.status === 200 && /amplifire_gate=/.test(admin.headers.get("set-cookie") ?? ""), `status=${admin.status}`);

  let last = 0;
  for (let i = 0; i < 10; i++) {
    const f = await fetch(`${HTTP}/__gate`, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: "pw=nope-nope-nope", redirect: "manual" });
    last = f.status;
  }
  check("入り口: まちがいが続くと、一時的に止められる（429）", last === 429, `last=${last}`);
}

// ------------------------------------------------------------------ 段階 venue
async function venuePhase(): Promise<void> {
  let reason = "";
  try {
    await join("なしの人");
  } catch (e) {
    reason = e instanceof Error ? e.message : String(e);
  }
  check("会場限定: コードなしでは入れない", /会場/.test(reason), reason);
  let reason2 = "";
  try {
    await join("ちがう人", { venue: "wrong-code" });
  } catch (e) {
    reason2 = e instanceof Error ? e.message : String(e);
  }
  check("会場限定: まちがったコードでは入れない", /会場/.test(reason2), reason2);
  const good = await join("ただしい人", { venue: process.env.VENUE_CODE ?? "venue-test-code" });
  check("会場限定: 正しいコードなら入れる", !!good.me());
  await leave([good]);
}

// ------------------------------------------------------------------ 段階 rta（スタンプRTA・ランキング）
async function rtaPhase(): Promise<void> {
  const map = JSON.parse(readFileSync(new URL("../client/src/config/map.json", import.meta.url), "utf8")) as {
    keyItems?: { id: string; x: number; y: number }[];
    areas?: { id: string; name: string; x: number; y: number; w: number; h: number }[];
  };
  const items = map.keyItems ?? [];
  check("試験の前提: マップにスタンプがある", items.length > 0, `${items.length}個`);
  if (!items.length) return;

  const watcher = await join("みはりばん");
  const cheat = await join("ずる");
  const runner = await join("はしる人");
  const rec = (b: Bot) => {
    const log = { start: 0, done: null as null | { ms: number; rank: number; best: boolean; bestMs: number }, ranking: null as null | Record<string, any>, corrected: 0 };
    b.room.onMessage(MSG.rtaStart, () => log.start++);
    b.room.onMessage(MSG.rtaDone, (m) => (log.done = m));
    b.room.onMessage(MSG.ranking, (m) => (log.ranking = m));
    b.room.onMessage(MSG.correct, () => log.corrected++);
    return log;
  };
  const cheatLog = rec(cheat);
  const runLog = rec(runner);
  const move = (b: Bot, x: number, y: number) => b.room.send(MSG.move, { x, y, flipX: false, action: "run" });

  // 1) ずる: 動かずに全部のスタンプを申告しても、記録にならない（そもそも動き出していない）
  for (const k of items) cheat.room.send(MSG.stampClaim, { id: k.id });
  await sleep(600);
  check("RTA: 動かずに申告しても、結果が出ない", cheatLog.done === null && cheatLog.start === 0);

  // 2) ずる: 少し動いてから、遠くのスタンプを申告しても、認められない（位置が近くない）
  const me0 = cheat.me()!;
  move(cheat, me0.x + 10, me0.y);
  await sleep(300);
  for (const k of items) cheat.room.send(MSG.stampClaim, { id: k.id });
  await sleep(600);
  check("RTA: 動き出すと、RTA が始まる", cheatLog.start === 1);
  check("RTA: 遠くのスタンプの申告は、認められない（結果が出ない）", cheatLog.done === null);

  // 3) ずる: 一気に遠くへ瞬間移動 → 速度の上限で、棄却される（位置が変わらない）
  const far = items[items.length - 1];
  const before = { x: cheat.me()!.x, y: cheat.me()!.y };
  move(cheat, far.x, far.y);
  await sleep(500);
  const after = { x: cheat.me()!.x, y: cheat.me()!.y };
  check("RTA: 瞬間移動は、速度の上限で棄却される", Math.hypot(after.x - before.x, after.y - before.y) < 1 && cheatLog.corrected > 0, `corrected=${cheatLog.corrected}`);
  cheat.room.send(MSG.stampClaim, { id: far.id });
  await sleep(400);
  check("RTA: 瞬間移動からの申告は、認められない", cheatLog.done === null);

  // 4) 本物の走り: 近い順に、速度の上限の内側で歩いて、全部のスタンプを申告する
  const startedAt = Date.now();
  let cx = runner.me()!.x;
  let cy = runner.me()!.y;
  const left = [...items];
  let travelled = 0;
  const STEP = 14; // 100msごとに14px = 140px/s（走る速さ112の1.25倍。許容の1.5倍の内側）
  while (left.length) {
    left.sort((a, b) => Math.hypot(a.x - cx, a.y - cy) - Math.hypot(b.x - cx, b.y - cy));
    const k = left.shift()!;
    while (Math.hypot(k.x - cx, k.y - cy) > 4) {
      const d = Math.hypot(k.x - cx, k.y - cy);
      const s = Math.min(STEP, d);
      cx += ((k.x - cx) / d) * s;
      cy += ((k.y - cy) / d) * s;
      travelled += s;
      move(runner, Math.round(cx * 10) / 10, Math.round(cy * 10) / 10);
      await sleep(100);
    }
    runner.room.send(MSG.stampClaim, { id: k.id });
    await sleep(30);
  }
  await sleep(700);
  const took = Date.now() - startedAt;
  check("RTA: 本物の走りで、全部集めると、結果が届く", runLog.done !== null, runLog.done ? `ms=${runLog.done.ms}` : "届かない");
  if (runLog.done) {
    check("RTA: 記録の時間が、実際にかかった時間に近い", Math.abs(runLog.done.ms - took) < 2500, `記録=${runLog.done.ms}ms 実測=${took}ms`);
    check("RTA: 歩いた距離から見て、あり得ない速さではない", runLog.done.ms >= (travelled / (112 * 1.5)) * 1000 * 0.9, `距離=${Math.round(travelled)}px`);
    check("RTA: 自己ベストで、1位", runLog.done.best && runLog.done.rank === 1);
  }
  check("RTA: 上位に入ると、全員のチャットに知らせが流れる", watcher.chats.some((c) => c.sessionId === "system" && /RTA/.test(c.text) && c.text.includes("はしる人")));
  check("RTA: ずるをした人には、知らせが流れない", !watcher.chats.some((c) => c.text.includes("ずる")));

  // 5) ランキングの取得（要求の返事）
  watcher.room.send(MSG.rankingReq, {});
  runner.room.send(MSG.rankingReq, {});
  await sleep(500);
  const wLog = (watcher as unknown as { __log?: unknown }).__log;
  void wLog;
  check("ランキング: 走った人の返事に、自分の行（me）がある", !!runLog.ranking && (runLog.ranking.rta as any[]).some((r) => r.me && r.name === "はしる人"));
  check("ランキング: 自分の自己ベストと順位が付く", runLog.ranking?.mine?.rtaRank === 1 && typeof runLog.ranking?.mine?.rtaMs === "number");
  check("ランキング: ずるをした人は載らない", !!runLog.ranking && !(runLog.ranking.rta as any[]).some((r) => r.name === "ずる"));
  // 要求のしすぎは、受け付けない（2秒に1回まで）
  runLog.ranking = null;
  runner.room.send(MSG.rankingReq, {});
  await sleep(300);
  check("ランキング: 要求を続けて送ると、2秒は返事がない", runLog.ranking === null);

  // 6) 同じ入室で、もう一度は記録されない（やり直すには、入り直す）
  runLog.done = null;
  for (const k of items) runner.room.send(MSG.stampClaim, { id: k.id });
  await sleep(400);
  check("RTA: 同じ入室では、2回目の結果は出ない", runLog.done === null);

  // 7) 今日の出店めぐり: 出店の区画に、しばらくいると、数えられる（サーバーが見ている位置から）
  const area = map.areas?.[0];
  if (area) {
    const tx = area.x + area.w / 2;
    const ty = area.y + area.h / 2;
    let px = runner.me()!.x;
    let py = runner.me()!.y;
    while (Math.hypot(tx - px, ty - py) > 4) {
      const d = Math.hypot(tx - px, ty - py);
      const s = Math.min(STEP, d);
      px += ((tx - px) / d) * s;
      py += ((ty - py) / d) * s;
      move(runner, Math.round(px * 10) / 10, Math.round(py * 10) / 10);
      await sleep(100);
    }
    await sleep(6000); // STALL_VISIT_SEC(4秒)より長くいる
    await sleep(2100);
    runner.room.send(MSG.rankingReq, {});
    await sleep(500);
    const tour = (runLog.ranking?.tour as any[] | undefined) ?? [];
    check("出店めぐり: 区画にいると、数えられる", tour.some((r) => r.name === "はしる人" && r.visited >= 1), JSON.stringify(tour.slice(0, 3)));
  }

  await leave([watcher, cheat, runner]);
}

console.log(`[troll-test] ${phase} -> ${URL_}`);
try {
  if (phase === "main") await main();
  else if (phase === "breaker") await breakerPhase();
  else if (phase === "join") await joinPhase();
  else if (phase === "gate") await gatePhase();
  else if (phase === "venue") await venuePhase();
  else if (phase === "rta") await rtaPhase();
  else throw new Error("phase は main / breaker / join / gate / venue / rta のどれか");
} catch (e) {
  fail++;
  console.log("FAIL  例外:", e instanceof Error ? e.stack : e);
}
console.log(`\n[troll-test] ${phase}: PASS ${pass} / FAIL ${fail}`);
process.exit(fail ? 1 : 0);
