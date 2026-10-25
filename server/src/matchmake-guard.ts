import { matchMaker, ServerError } from "colyseus";
import { isBlockedIp } from "./geoblock";
import { gateAllowsHeaders } from "./gate";
import { moderation } from "./moderation";
import { verifySpectatorToken } from "./admin";

/**
 * 入室の予約（POST /matchmake/…）の入口を守る。
 * Colyseus は、この予約の URL を Express より先に処理するため、国別制限（geoblock）・合言葉の入り口（gate）の Express 側の守りを、素通りしてしまう。
 * 予約は、15秒のあいだ、部屋の席を1つふさぐので、外から大量に予約されると、本物の人が入れなくなる。そこで、予約を受ける関数（invokeMethod）を包んで、
 *   ① 国（日本以外は断る）② 合言葉の入り口（Cookie。管理者のショー画面は観客トークン）③ 同じ回線からの予約の頻度
 * を、席をふさぐ前に確かめる。入室そのもの（onAuth）の検査は、これまでどおり、別に行う。
 */
export function installMatchmakeGuard(): void {
  const controller = matchMaker.controller as unknown as {
    invokeMethod: (this: unknown, method: string, roomName: string, clientOptions?: Record<string, unknown>, authContext?: { headers?: Headers; ip?: string }) => Promise<unknown>;
  };
  const original = controller.invokeMethod;
  controller.invokeMethod = async function (this: unknown, method, roomName, clientOptions, authContext) {
    const ip = String(authContext?.headers?.get("fly-client-ip") ?? authContext?.ip ?? "");
    if (isBlockedIp(ip)) throw new ServerError(403, "このサービスは日本国内からのみ利用できます");
    const spectator = clientOptions?.spectator !== undefined && verifySpectatorToken(clientOptions.spectator);
    if (!spectator && !gateAllowsHeaders(authContext?.headers)) throw new ServerError(403, "いまは 関係者だけが アクセスできます");
    const why = moderation.checkReserve(ip);
    if (why) throw new ServerError(429, why);
    return original.call(this, method, roomName, clientOptions, authContext);
  };
}
