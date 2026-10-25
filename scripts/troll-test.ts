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
 *  段階 venue（会場限定モード）:
 *    VENUE_CODE=venue-test-code を付けて起動 → … troll-test.ts venue
 *
 * 全部 PASS なら、終了コード 0。
 */
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

async function join(name: string, opts: { vid?: string; venue?: string; spectator?: string } = {}): Promise<Bot> {
  const vid = opts.vid ?? vidOf(name.slice(0, 4));
  const room = (await new Client(URL_).join(ROOM_NAME, { name, hair: "mophair", consent: CONSENT_VERSION, vid, device: "desktop", venue: opts.venue }, MainRoomState)) as Room<any, MainRoomState>;
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

console.log(`[troll-test] ${phase} -> ${URL_}`);
try {
  if (phase === "main") await main();
  else if (phase === "breaker") await breakerPhase();
  else if (phase === "join") await joinPhase();
  else if (phase === "venue") await venuePhase();
  else throw new Error("phase は main / breaker / join / venue のどれか");
} catch (e) {
  fail++;
  console.log("FAIL  例外:", e instanceof Error ? e.stack : e);
}
console.log(`\n[troll-test] ${phase}: PASS ${pass} / FAIL ${fail}`);
process.exit(fail ? 1 : 0);
