import { Room, ServerError, type AuthContext, type Client } from "colyseus";
import {
  CONSENT_VERSION,
  EMOTES,
  HAIRS,
  MAX_CLIENTS,
  MAX_SPEED,
  MSG,
  NAME_MAX,
  PATCH_RATE_MS,
  PLAYER_ACTIONS,
  SPEED_BUDGET_SEC,
  SPEED_TOLERANCE,
  MainRoomState,
  Player,
  type ChatBroadcast,
  type ChatDelete,
  type ChatState,
  type ChatSend,
  type ModNotice,
  type PhraseSend,
  type ReportSend,
  type CorrectMessage,
  decodeLook,
  encodeLook,
  sanitizeLook,
  type EmoteBroadcast,
  type EmoteId,
  type EmoteSend,
  type JoinOptions,
  type MoveMessage,
  type StampsSend,
  type StampClaim,
  type RtaStart,
  RANKING_TOP,
} from "@metaverse/shared";
import { ranking, stallIdsOf } from "../ranking";
import { isTrustedIp } from "../trusted";
import { loadMap } from "../map";
import { isBanned, registerAdminHooks, verifySpectatorToken } from "../admin";
import { stats } from "../stats";
import { isBlockedIp } from "../geoblock";
import { cleanText, moderation as mod, vetName } from "../moderation";
import { verifyVenueCode, venueEnabled } from "../venue";
import { gateAllowsHeaders } from "../gate";

const RECONNECT_SECONDS = 15;
/** 同時に入れる人数の上限。環境変数 MAX_CLIENTS で変えられる（既定は shared/constants.ts） */
const CAPACITY = Math.max(1, Math.floor(Number(process.env.MAX_CLIENTS)) || MAX_CLIENTS);
/** 同じ回線（IP）から同時に入れる数。1つの回線で部屋を埋めつくされないため。学校の Wi-Fi など、同じ回線の人が多いときは、環境変数 MAX_PER_IP で増やす */
const MAX_PER_IP = Math.max(1, Math.floor(Number(process.env.MAX_PER_IP)) || 50);

/** 送信待ちがこれ(バイト)を超えた接続は、切り離す（1人あたりの通信は毎秒10〜20KB程度なので、4MBは、数分ぶんの詰まり） */
const SLOW_CLIENT_BYTES = 4 * 1024 * 1024;

/**
 * 人数に応じた、状態の配信間隔(ms)。人が増えると、1人が動くたびに全員へ届くので、配信は人数の2乗で増える。
 * 少ないうちは滑らかさを優先（20Hz）、増えたら間隔を広げて CPU と通信を抑える（受け取る側の補間でなめらかに見せる）。
 */
function patchRateFor(players: number): number {
  if (players <= 40) return PATCH_RATE_MS; // 20Hz
  if (players <= 80) return 70; // 約14Hz
  if (players <= 130) return 100; // 10Hz
  return 150; // 約7Hz
}

interface PeerMeta {
  /** 溜まっている「移動してよい距離」(px)。バースト受信でも誤棄却しないためのトークンバケット */
  budget: number;
  lastMoveAt: number;
  rejected: number;
  /** 訪問者ID（端末ごとのランダムな値。無ければ接続の ID）。自動の停止・通報の単位 */
  vid: string;
  ip: string;
  joinedAt: number;
  /** 集めたスタンプの数（参加者の申告）。1つでもあれば、入室直後でも書き込める */
  stamps: number;
  /** ランキングの要求を最後に受けた時刻（要求のしすぎを断る） */
  lastRankAt: number;
}

/** ミリ秒を「1:23.4」の形に */
function formatMs(ms: number): string {
  const s = ms / 1000;
  const m = Math.floor(s / 60);
  return `${m}:${(s - m * 60).toFixed(1).padStart(4, "0")}`;
}

export class MainRoom extends Room<{ state: MainRoomState }> {
  maxClients = CAPACITY;
  patchRate = PATCH_RATE_MS;
  /** 無人になっても部屋を残す（index.ts で起動時に1部屋だけ作るため） */
  autoDispose = false;

  private map = loadMap();
  private stallIds = stallIdsOf(this.map.areas);
  private peers = new Map<string, PeerMeta>();
  /** 入室中の人の接続元IP（同じ回線からの数を数えるため。ログや記録には残さない） */
  private ipOf = new Map<string, string>();
  private ipCount = new Map<string, number>();

  onCreate() {
    this.state = new MainRoomState();

    // 管理ページから、おしらせ・退室・出店一覧を使えるようにする
    registerAdminHooks({
      areas: () => this.map.areas,
      announce: (text) => {
        const id = stats.addChat("system", "おしらせ", text, "system");
        const out: ChatBroadcast = { id, sessionId: "system", name: "おしらせ", text, at: Date.now() };
        this.broadcast(MSG.chat, out);
      },
      setChatLocked: (locked) => {
        stats.setChatLocked(locked);
        this.broadcastChatState();
      },
      setPhrasesOnly: (on) => mod.setManualPhrases(on),
      unmute: (vid) => mod.unmute(vid),
      retractChat: (ids) => {
        const out: ChatDelete = { ids };
        this.broadcast(MSG.chatDelete, out);
      },
      kick: (sid, reason) => {
        const c = this.clients.find((x) => x.sessionId === sid);
        if (!c) return false;
        // 切断コード: 4801=運営が退室させた, 4802=利用停止（Colyseus が使う 4000番台の前半と重ならない値）
        const meta = this.peers.get(sid);
        if (meta) mod.coolDown(meta.vid, meta.ip); // すぐに入り直せないように、短い待ち時間を付ける
        c.leave(reason === "banned" ? 4802 : 4801);
        return true;
      },
    });

    // 荒らし対策: 定型文だけのモード（安全装置・運営の手動）が切り替わったら、全員に知らせる。1秒ごとに、時間切れの確認をする
    mod.watchPhrases(() => {
      this.broadcastChatState();
      if (mod.phrasesActive()) this.announceSystem("荒らしが増えているので、しばらく 定型文だけに なります。自由な書き込みは、あとで 自動で もどります");
      else this.announceSystem("チャットが、ふつうに もどりました");
    });
    this.clock.setInterval(() => mod.tick(), 1000);

    // 受け取りが極端に遅い接続（回線が詰まって、送ったものが溜まり続けている）は切り離す。放っておくと、サーバーのメモリが溜まり続けるため
    this.clock.setInterval(() => {
      for (const c of this.clients) {
        const buffered = (c as unknown as { ref?: { bufferedAmount?: number } }).ref?.bufferedAmount ?? 0;
        if (buffered > SLOW_CLIENT_BYTES) {
          console.warn(`[slow] ${c.sessionId} の送信待ちが ${Math.round(buffered / 1024)}KB。切断します`);
          c.leave(4803);
        }
      }
    }, 5000);

    // 人数に合わせて、配信の間隔を調整する（5秒ごとに見直す）
    this.clock.setInterval(() => {
      const ms = patchRateFor(this.state.players.size);
      if (ms !== this.patchRate) {
        this.setPatchRate(ms);
        console.log(`[room] 配信間隔 ${ms}ms（${this.state.players.size}人）`);
      }
    }, 5000);

    // 出店ごとの滞在時間のため、1秒ごとに全員の「いまいる区画」を記録する
    this.clock.setInterval(() => {
      const list: { sid: string; areaId: string }[] = [];
      this.state.players.forEach((p, sid) => list.push({ sid, areaId: this.map.areaAt(p.x, p.y) }));
      stats.tick(list);
    }, 1000);

    // 移動: クライアント主導。速度上限だけサーバーで検証する（SPEC 4.1）
    this.onMessage<MoveMessage>(MSG.move, (client, msg) => this.handleMove(client, msg));

    this.onMessage<ChatSend>(MSG.chat, (client, msg) => {
      const player = this.state.players.get(client.sessionId);
      const peer = this.peers.get(client.sessionId);
      if (!player || !peer) return;

      // 運営がチャットを停止している間は、受け付けない（本人には、停止中だと知らせる）
      if (stats.chatLocked) {
        client.send(MSG.chatState, this.chatState());
        return;
      }
      const res = mod.vetChat({
        sid: client.sessionId,
        vid: peer.vid,
        ip: peer.ip,
        name: player.name,
        text: typeof msg?.text === "string" ? msg.text : "",
        joinedAt: peer.joinedAt,
        stamps: peer.stamps,
        phrasesOnly: mod.phrasesActive(),
      });
      this.deliver(client, player, res);
    });

    // 定型文チャット（自由な書き込みが止まっているときも使える）
    this.onMessage<PhraseSend>(MSG.phrase, (client, msg) => {
      const player = this.state.players.get(client.sessionId);
      const peer = this.peers.get(client.sessionId);
      if (!player || !peer || stats.chatLocked) return;
      const res = mod.vetPhrase({ sid: client.sessionId, vid: peer.vid, ip: peer.ip, name: player.name, joinedAt: peer.joinedAt, stamps: peer.stamps }, msg?.id);
      this.deliver(client, player, res);
    });

    // 通報（別々の人から一定数たまると、自動で、その人のチャットを止める）
    this.onMessage<ReportSend>(MSG.report, (client, msg) => {
      const peer = this.peers.get(client.sessionId);
      const target = typeof msg?.sessionId === "string" ? this.state.players.get(msg.sessionId) : undefined;
      const tp = typeof msg?.sessionId === "string" ? this.peers.get(msg.sessionId) : undefined;
      if (!peer || !target || !tp) return;
      const r = mod.report({ sid: client.sessionId, vid: peer.vid, joinedAt: peer.joinedAt }, { sid: msg.sessionId, vid: tp.vid, ip: tp.ip, name: target.name });
      client.send(MSG.modNotice, r.notice);
      if (r.muted) this.notifyMuted(msg.sessionId);
    });

    this.onMessage<StampsSend>(MSG.stamps, (client, msg) => {
      const peer = this.peers.get(client.sessionId);
      if (!peer) return;
      stats.stamps(client.sessionId, Number(msg?.count), Number(msg?.total));
      const n = Math.floor(Number(msg?.count));
      if (Number.isFinite(n) && n >= 0) peer.stamps = Math.min(n, 200);
    });

    // スタンプを取ったことの申告。そのスタンプの近くにいたときだけ、RTA の記録に数える。全部そろったら、結果を返す
    this.onMessage<StampClaim>(MSG.stampClaim, (client, msg) => {
      const player = this.state.players.get(client.sessionId);
      if (!player) return;
      const res = ranking.claim(client.sessionId, msg?.id, player.x, player.y, this.map.keyItems);
      if (res.kind !== "done") return;
      client.send(MSG.rtaDone, res.done);
      if (res.announce) this.announceSystem(`🎉 ${res.name} さんが スタンプRTA ${formatMs(res.done.ms)} で コンプリート！（${res.done.rank}位）`);
      console.log(`[rta] "${res.name}" ${formatMs(res.done.ms)} rank=${res.done.rank}${res.done.best ? " (best)" : ""}`);
    });

    // ランキングの要求（開いているあいだ、画面が10秒ごとに聞いてくる。1人あたり2秒に1回まで）
    this.onMessage(MSG.rankingReq, (client) => {
      const peer = this.peers.get(client.sessionId);
      if (!peer) return;
      const now = Date.now();
      if (now - peer.lastRankAt < 2000) return;
      peer.lastRankAt = now;
      client.send(MSG.ranking, ranking.snapshot(this.stallIds, peer.vid, RANKING_TOP, now));
    });

    this.onMessage<EmoteSend>(MSG.emote, (client, msg) => {
      const player = this.state.players.get(client.sessionId);
      const id = msg?.id as EmoteId;
      if (!player || !(id in EMOTES)) return;
      if (!mod.allowEmote(client.sessionId)) return; // 連打は、受け付けない（周りの画面が埋まるため）
      player.action = id;
      stats.emote(client.sessionId);
      const out: EmoteBroadcast = { sessionId: client.sessionId, id };
      // 本人はローカルで即再生済みなので送り返さない
      this.broadcast(MSG.emote, out, { except: client });
    });
  }

  /** 同意した人だけ入室できる。利用停止の人も入れない。受け取るのは JoinOptions（信用せず、形を確かめる） */
  onAuth(_client: Client, options: Partial<JoinOptions> = {}, context?: AuthContext) {
    // 入室の予約（HTTP）は国別制限を通っているが、WebSocket 側でも念のため確かめる
    if (isBlockedIp(context?.headers?.get("fly-client-ip") ?? context?.ip)) throw new ServerError(4003, "このサービスは日本国内からのみ利用できます");
    // 管理者のショー画面（観客）: 管理用 API が出した短命トークンがあれば、同意なしで入れる（プレイヤーとしては数えない）
    if (options.spectator !== undefined) {
      if (!verifySpectatorToken(options.spectator)) throw new ServerError(4003, "利用できません");
      return true;
    }
    // 公開前の「関係者だけ」の入り口を通った人（合言葉の Cookie がある人）だけ
    if (!gateAllowsHeaders(context?.headers)) throw new ServerError(4003, "いまは 関係者だけが アクセスできます");
    if (options.consent !== CONSENT_VERSION) throw new ServerError(4001, "利用規約への同意が必要です");
    const vid = typeof options.vid === "string" ? options.vid.slice(0, 64) : "";
    if (vid && isBanned(vid)) throw new ServerError(4003, "利用できません");
    // 会場限定モード: 会場の QR コードの入室コードが要る
    if (venueEnabled && !verifyVenueCode(options.venue)) throw new ServerError(4003, "会場の QR コードから 入ってください（コードが ちがうか、古くなっています）");
    // 同じ回線から入っている数に上限（部屋を1か所の接続で埋めつくされないため）
    const ip = String(context?.headers?.get("fly-client-ip") ?? context?.ip ?? "");
    if (ip && !isTrustedIp(ip) && (this.ipCount.get(ip) ?? 0) >= MAX_PER_IP) throw new ServerError(4003, "この回線からの接続が多すぎます。しばらくしてからお試しください");
    // 短い時間の入室のしすぎ・退室させられた直後の入り直しを断る
    const why = mod.checkJoin(ip, vid);
    if (why) throw new ServerError(4003, why);
    mod.noteJoin(ip);
    return { ip };
  }

  onJoin(client: Client, options: Partial<JoinOptions> = {}) {
    // 観客は、プレイヤーとして部屋に出さない（見えない・数えない・記録しない）。部屋の状態とチャットを受け取るだけ
    if (options.spectator !== undefined) {
      console.log(`[spectator] ${client.sessionId}`);
      return;
    }
    const ip = (client.auth as { ip?: string } | undefined)?.ip;
    if (ip) {
      this.ipOf.set(client.sessionId, ip);
      this.ipCount.set(ip, (this.ipCount.get(ip) ?? 0) + 1);
    }
    const vid = typeof options.vid === "string" && options.vid.length >= 8 ? options.vid.slice(0, 64) : client.sessionId;
    const player = new Player();
    // なまえの検査: 暴言・連絡先・運営のなりすましは、「ゲスト＋数字」に置き換える
    const vetted = vetName(options.name, vid, NAME_MAX);
    player.name = vetted.name;
    if (vetted.replaced) mod.log("name-replaced", vetted.name, vid, "使えない名前だったので、置き換えた");
    // 見た目: 形の正しい項目だけを使う（色は #rrggbb、かざりは決まった一覧の中から）。不正なら髪型だけにする
    const look =
      decodeLook(typeof options.look === "string" ? options.look.slice(0, 120) : "") ??
      sanitizeLook({ hair: HAIRS.includes(options.hair as (typeof HAIRS)[number]) ? options.hair : HAIRS[Math.floor(Math.random() * HAIRS.length)] })!;
    player.hair = look.hair;
    player.look = encodeLook(look);
    const p = this.pickSpawn();
    player.x = p.x;
    player.y = p.y;
    player.flipX = false;
    player.action = "idle";
    this.state.players.set(client.sessionId, player);
    this.peers.set(client.sessionId, {
      budget: MAX_SPEED * SPEED_TOLERANCE * SPEED_BUDGET_SEC,
      lastMoveAt: Date.now(),
      rejected: 0,
      vid,
      ip: ip ?? "",
      joinedAt: Date.now(),
      stamps: 0,
      lastRankAt: 0,
    });
    ranking.join(client.sessionId, vid, player.name, player.x, player.y);
    client.send(MSG.chatState, this.chatState());
    stats.join(client.sessionId, {
      vid,
      name: player.name,
      hair: player.hair,
      look: player.look,
      device: options.device === "touch" ? "touch" : "desktop",
      consent: CONSENT_VERSION,
    });
    console.log(`[join] ${client.sessionId} "${player.name}" (${this.clients.length}/${CAPACITY})`);
  }

  /** 想定外の切断（回線落ち等）。短時間なら同じキャラのまま復帰させる */
  onDrop(client: Client) {
    this.allowReconnection(client, RECONNECT_SECONDS);
  }

  onLeave(client: Client) {
    const ip = this.ipOf.get(client.sessionId);
    if (ip) {
      this.ipOf.delete(client.sessionId);
      const left = (this.ipCount.get(ip) ?? 1) - 1;
      if (left > 0) this.ipCount.set(ip, left);
      else this.ipCount.delete(ip);
    }
    this.state.players.delete(client.sessionId);
    this.peers.delete(client.sessionId);
    ranking.leave(client.sessionId);
    mod.forget(client.sessionId);
    stats.leave(client.sessionId);
    console.log(`[leave] ${client.sessionId} (${this.clients.length}/${CAPACITY})`);
  }

  /** いまのチャットの状態（運営の停止・定型文だけ） */
  private chatState(): ChatState {
    return { locked: stats.chatLocked, phrases: mod.phrasesActive() };
  }

  private broadcastChatState(): void {
    this.broadcast(MSG.chatState, this.chatState());
  }

  /** 運営のおしらせと同じ形で、全員のチャットに1行流す（自動の切り替えの知らせ。記録にも残る） */
  private announceSystem(text: string): void {
    const id = stats.addChat("system", "おしらせ", text, "system");
    const out: ChatBroadcast = { id, sessionId: "system", name: "おしらせ", text, at: Date.now() };
    this.broadcast(MSG.chat, out);
  }

  /** 止められた人に、止めたことを知らせる */
  private notifyMuted(sid: string): void {
    const c = this.clients.find((x) => x.sessionId === sid);
    const peer = this.peers.get(sid);
    if (!c || !peer) return;
    const m = mod.muteInfo(peer.vid, peer.ip, sid);
    if (m) c.send(MSG.modNotice, { code: "muted", text: `ルールを まもらなかったので、チャットを おやすみします（あと${Math.ceil((m.until - Date.now()) / 60000)}分）`, retryMs: m.until - Date.now() } satisfies ModNotice);
  }

  /** 検査を通ったチャットを配る。通らなかったときは、本人にだけ理由を知らせる */
  private deliver(client: Client, player: Player, res: ReturnType<typeof mod.vetChat>): void {
    if (!res.ok) {
      if (res.notice.text) client.send(MSG.modNotice, res.notice);
      return;
    }
    const now = Date.now();
    const id = stats.addChat(client.sessionId, player.name, res.text);
    const out: ChatBroadcast = { id, sessionId: client.sessionId, name: player.name, text: res.text, at: now };
    this.broadcast(MSG.chat, out);
    if (res.strike?.muted) this.notifyMuted(client.sessionId);
  }

  private handleMove(client: Client, msg: MoveMessage) {
    const player = this.state.players.get(client.sessionId);
    const peer = this.peers.get(client.sessionId);
    if (!player || !peer || !msg) return;
    const { x, y, flipX, action } = msg;
    if (!Number.isFinite(x) || !Number.isFinite(y) || typeof action !== "string" || !PLAYER_ACTIONS.includes(action)) return;

    const now = Date.now();
    const dt = Math.min((now - peer.lastMoveAt) / 1000, SPEED_BUDGET_SEC);
    peer.lastMoveAt = now;
    const cap = MAX_SPEED * SPEED_TOLERANCE * SPEED_BUDGET_SEC;
    peer.budget = Math.min(cap, peer.budget + MAX_SPEED * SPEED_TOLERANCE * dt);

    const dist = Math.hypot(x - player.x, y - player.y);
    const outOfBounds = x < 0 || y < 0 || x > this.map.pixelW || y > this.map.pixelH;
    if (dist > peer.budget + 0.5 || outOfBounds) {
      // 棄却して前回座標を維持。本人にだけ正しい座標を返して同期し直す
      peer.rejected++;
      console.warn(
        `[reject] ${client.sessionId} "${player.name}" moved ${dist.toFixed(1)}px (budget ${peer.budget.toFixed(1)}px)${outOfBounds ? " out-of-bounds" : ""} #${peer.rejected}`,
      );
      const fix: CorrectMessage = { x: player.x, y: player.y };
      client.send(MSG.correct, fix);
      return;
    }
    peer.budget -= dist;

    // 値が変わったものだけ代入（Schemaは変化したフィールドだけ配信される）
    const moved = player.x !== x || player.y !== y;
    if (player.x !== x) player.x = x;
    if (player.y !== y) player.y = y;
    // スタンプRTA: 動き出した瞬間から数える（本人に、動き出しを知らせる）
    if (moved && ranking.moved(client.sessionId, x, y, now)) client.send(MSG.rtaStart, { total: this.map.keyItems.length } satisfies RtaStart);
    const flip = !!flipX;
    if (player.flipX !== flip) player.flipX = flip;
    if (player.action !== action) player.action = action;
  }

  /** スポーン地点の近くで、通れないタイルを避けてばらけさせる */
  private pickSpawn() {
    const { spawn, tile } = this.map;
    for (let i = 0; i < 12; i++) {
      // 隣の台地や飛び地に出ないよう、スポーン中心から 1.5 タイル以内に留める
      const x = spawn.x + (Math.random() * 2 - 1) * tile * 1.5;
      const y = spawn.y + (Math.random() * 2 - 1) * tile * 1.5;
      if (!this.map.isFootBlocked(x, y)) return { x, y };
    }
    return spawn;
  }
}
