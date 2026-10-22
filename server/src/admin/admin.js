"use strict";
/* 管理ページの画面。表示はすべて textContent / DOM で組み立てる（チャット本文の HTML は動かない）。 */
(function () {
  const $ = (id) => document.getElementById(id);
  const api = (path) => fetch("/admin/api/" + path, { cache: "no-store" }).then((r) => {
    if (!r.ok) throw new Error(path + " " + r.status);
    return r.json();
  });
  const post = (path, body) =>
    fetch("/admin/api/" + path, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Admin": "1" },
      body: JSON.stringify(body),
    }).then((r) => r.json().then((j) => ({ ok: r.ok, ...j })));

  const el = (tag, props, ...kids) => {
    const e = document.createElement(tag);
    if (props) for (const [k, v] of Object.entries(props)) {
      if (k === "class") e.className = v;
      else if (k === "text") e.textContent = v;
      else if (k.startsWith("on")) e.addEventListener(k.slice(2), v);
      else e.setAttribute(k, v);
    }
    for (const c of kids) if (c != null) e.append(c);
    return e;
  };
  const toast = (msg, err) => {
    const t = $("toast");
    t.textContent = msg;
    t.className = err ? "err" : "";
    t.hidden = false;
    clearTimeout(toast.t);
    toast.t = setTimeout(() => (t.hidden = true), 3200);
  };

  const pad = (n) => String(n).padStart(2, "0");
  const dur = (s) => {
    s = Math.round(s);
    if (s < 60) return s + "秒";
    if (s < 3600) return Math.floor(s / 60) + "分" + pad(s % 60) + "秒";
    return Math.floor(s / 3600) + "時間" + pad(Math.floor((s % 3600) / 60)) + "分";
  };
  const jst = (t) => {
    const d = new Date(t + 9 * 3600 * 1000);
    return d.toISOString().slice(5, 16).replace("T", " ").replace("-", "/");
  };
  const jstTime = (t) => new Date(t + 9 * 3600 * 1000).toISOString().slice(11, 16);
  const sid6 = (v) => (v || "").slice(0, 6);
  const deviceLabel = (d) => (d === "touch" ? "スマホ等" : "PC");

  const table = (t, head, rows) => {
    t.replaceChildren();
    t.append(el("thead", null, el("tr", null, ...head.map((h) => el("th", { class: h.n ? "n" : "", text: h.t })))));
    const body = el("tbody");
    if (!rows.length) body.append(el("tr", null, el("td", { colspan: String(head.length), text: "まだありません", class: "note" })));
    for (const r of rows) body.append(r);
    t.append(body);
  };
  const tr = (cells) => el("tr", null, ...cells.map((c) => (c instanceof Node ? c : el("td", { text: String(c) }))));
  const td = (text, n) => el("td", { class: n ? "n" : "", text: String(text) });

  // ---------------------------------------------------------------- グラフ（canvas）
  function setup(cv) {
    const dpr = window.devicePixelRatio || 1;
    const w = cv.clientWidth, h = cv.clientHeight;
    cv.width = Math.round(w * dpr);
    cv.height = Math.round(h * dpr);
    const g = cv.getContext("2d");
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.clearRect(0, 0, w, h);
    return { g, w, h };
  }
  function axisY(g, w, h, max, pl, pb) {
    g.strokeStyle = "#2f2a63";
    g.fillStyle = "#9d98c9";
    g.font = "11px sans-serif";
    g.textAlign = "right";
    for (let i = 0; i <= 2; i++) {
      const v = (max * i) / 2;
      const y = h - pb - ((h - pb - 8) * i) / 2;
      g.beginPath(); g.moveTo(pl, y); g.lineTo(w - 4, y); g.stroke();
      g.fillText(String(Math.round(v)), pl - 4, y + 4);
    }
  }
  function lineChart(cv, pts, tmin, tmax) {
    const { g, w, h } = setup(cv);
    const pl = 30, pb = 18;
    const max = Math.max(2, ...pts.map((p) => p.n));
    axisY(g, w, h, max, pl, pb);
    g.fillStyle = "#9d98c9"; g.textAlign = "center";
    for (let i = 0; i <= 4; i++) {
      const t = tmin + ((tmax - tmin) * i) / 4;
      g.fillText(jstTime(t), pl + ((w - pl - 6) * i) / 4, h - 4);
    }
    if (!pts.length) { g.fillText("まだ記録がありません", w / 2, h / 2); return; }
    g.strokeStyle = "#6fe8ff"; g.lineWidth = 2; g.beginPath();
    pts.forEach((p, i) => {
      const x = pl + ((p.t - tmin) / (tmax - tmin)) * (w - pl - 6);
      const y = h - pb - (p.n / max) * (h - pb - 8);
      if (i) g.lineTo(x, y); else g.moveTo(x, y);
    });
    g.stroke();
  }
  function barChart(cv, items) {
    const { g, w, h } = setup(cv);
    const pl = 30, pb = 18;
    const max = Math.max(2, ...items.map((i) => i.joins));
    axisY(g, w, h, max, pl, pb);
    if (!items.length) { g.fillStyle = "#9d98c9"; g.textAlign = "center"; g.fillText("まだ記録がありません", w / 2, h / 2); return; }
    const bw = (w - pl - 6) / items.length;
    items.forEach((it, i) => {
      const bh = (it.joins / max) * (h - pb - 8);
      g.fillStyle = "#ff5fa2";
      g.fillRect(pl + i * bw + 1, h - pb - bh, Math.max(1, bw - 2), bh);
      if (i % Math.ceil(items.length / 8) === 0) {
        g.fillStyle = "#9d98c9"; g.textAlign = "center"; g.font = "10px sans-serif";
        g.fillText(it.hour.slice(8, 10) + "時", pl + i * bw + bw / 2, h - 4);
      }
    });
  }
  const bars = (box, items, fmt) => {
    box.replaceChildren();
    const max = Math.max(1, ...items.map((i) => i.n));
    for (const it of items) {
      const fill = el("div", { class: "fill" });
      fill.style.width = (it.n / max) * 100 + "%";
      box.append(el("div", { class: "bar" }, el("span", { class: "lab", text: it.label }), el("div", { class: "track" }, fill), el("span", { class: "val", text: fmt ? fmt(it.n) : String(it.n) })));
    }
  };

  // ---------------------------------------------------------------- 概要
  let lastSummary = null;
  function renderSummary(s) {
    lastSummary = s;
    $("updated").textContent = "更新 " + jstTime(s.now) + "（サーバー起動から " + dur((s.now - s.startedAt) / 1000) + "）";
    const warn = $("warn");
    if (!s.storage.enabled) {
      warn.textContent = "記録を保存できません（保存先 " + s.storage.dir + "）。いまの記録はサーバーのメモリだけにあり、再起動で消えます。";
      warn.hidden = false;
    } else if (!s.storage.persistent) {
      warn.textContent = "記録の保存先（" + s.storage.dir + "）は、再起動やデプロイで消える一時的な場所の可能性があります。残したいときは、Fly.io の Volume を /data に付けてください（手順は docs/ADMIN.md）。";
      warn.hidden = false;
    } else warn.hidden = true;

    const t = s.totals;
    const k = (label, value, sub) => el("div", { class: "kpi" }, el("b", { text: String(value) }), el("span", { text: label }), sub ? el("i", { text: sub }) : null);
    $("kpis").replaceChildren(
      k("いま入室中", s.online + "人", "ピーク " + s.peak.n + "人" + (s.peak.at ? "（" + jst(s.peak.at) + "）" : "")),
      k("のべ入室数", t.sessions, "今日 " + t.todaySessions),
      k("参加した人数（端末）", t.visitors, "今日 " + t.todayVisitors + " ／ 再訪 " + t.returning),
      k("平均滞在", dur(t.avgStay), "中央値 " + dur(t.medianStay)),
      k("長く居た人（上位10%）", dur(t.p90Stay), "これ以上 居た人が10%"),
      k("スタンプ全部そろえた人", t.completed + "人", "端末ごと"),
      k("チャット数", t.chats),
      k("エモート数", t.emotes),
    );
    lineChart($("c-online"), s.online24h, s.now - 24 * 3600 * 1000, s.now);
    barChart($("c-hourly"), s.hourly);

    const stalls = [...s.stalls].sort((a, b) => b.seconds - a.seconds);
    const maxSec = Math.max(1, ...stalls.map((x) => x.seconds));
    table($("t-stalls"), [{ t: "出店" }, { t: "人数", n: 1 }, { t: "平均", n: 1 }, { t: "合計時間", n: 1 }, { t: "" }], stalls.map((x) => {
      const fill = el("div", { class: "fill" });
      fill.style.width = (x.seconds / maxSec) * 100 + "%";
      return tr([td(x.name), td(x.visitors, 1), td(dur(x.avg), 1), td(dur(x.seconds), 1), el("td", { style: "" }, el("div", { class: "track bar" }, fill))]);
    }));
    bars($("stay-dist"), s.stayBuckets.map((b) => ({ label: b.label, n: b.n })), (n) => n + "件");
    bars($("stamp-dist"), s.stampDist.map((b) => ({ label: b.stamps + "個", n: b.n })), (n) => n + "件");
    bars($("devices"), [{ label: "パソコン", n: s.devices.desktop }, { label: "スマホ等", n: s.devices.touch }], (n) => n + "件");
    table($("t-daily"), [{ t: "日付（日本時間）" }, { t: "入室数", n: 1 }, { t: "人数（端末）", n: 1 }], [...s.daily].reverse().map((d) => tr([td(d.date), td(d.sessions, 1), td(d.visitors, 1)])));
    $("about").replaceChildren(
      ...[
        "保存先: " + s.storage.dir + (s.storage.persistent ? "" : "（一時的な場所の可能性）"),
        "保存期間: " + s.storage.retentionDays + "日（過ぎた記録は自動で消えます）",
        "人数は「端末」で数えています。同じ端末・同じブラウザなら再訪も同じ人として数えます（別のブラウザやデータ消去で別の人になります）。",
        "滞在時間は、入室から退室まで。出店の滞在時間は、その出店の区画（通路を少し含む）にいた時間の合計です。",
        "スタンプの数は参加者の画面からの申告です（不正はできてしまいます。景品などにするなら、受付で画面を見せてもらってください）。",
        "利用停止にした端末: " + s.banned + "件",
      ].map((x) => el("li", { text: x })),
    );
  }

  // ---------------------------------------------------------------- オンライン
  async function loadOnline() {
    const list = await api("online");
    $("online-n").textContent = "（" + list.length + "人）";
    const areaName = (id) => (lastSummary?.stalls.find((s) => s.id === id)?.name) || (id ? id : "通路など");
    table($("t-online"), [{ t: "ニックネーム" }, { t: "訪問者ID" }, { t: "端末" }, { t: "滞在", n: 1 }, { t: "いる場所" }, { t: "スタンプ", n: 1 }, { t: "チャット", n: 1 }, { t: "操作" }],
      list.sort((a, b) => b.stay - a.stay).map((p) => tr([
        td(p.name), el("td", { class: "mono", text: sid6(p.vid), title: p.vid }), td(deviceLabel(p.device)), td(dur(p.stay), 1), td(areaName(p.area)),
        td(p.stamps + "/" + (p.stampTotal || "?"), 1), td(p.chats, 1),
        el("td", null,
          el("button", { class: "small", type: "button", text: "退室させる", onclick: () => kick(p, false) }), " ",
          el("button", { class: "small red", type: "button", text: "利用停止", onclick: () => kick(p, true) })),
      ])));
  }
  async function kick(p, ban) {
    const msg = ban ? "「" + p.name + "」を退室させ、この端末の利用を停止します。よろしいですか？" : "「" + p.name + "」を退室させます。よろしいですか？";
    if (!confirm(msg)) return;
    const r = await post("kick", { sid: p.sid, ban });
    toast(r.ok ? "実行しました" : "できませんでした（すでに退室？）", !r.ok);
    loadOnline();
  }

  // ---------------------------------------------------------------- チャット
  let chatOldest = null;
  const picked = new Set();
  const refreshSel = () => {
    $("sel-count").textContent = picked.size + "件 選択中";
    $("chat-del").disabled = picked.size === 0;
    const boxes = [...document.querySelectorAll("#chat-list input[type=checkbox]")];
    $("chat-all").checked = boxes.length > 0 && boxes.every((b) => b.checked);
  };
  const chatRow = (c) => {
    const row = el("div", { class: "msg" + (c.kind === "system" ? " system" : ""), "data-id": String(c.id) });
    const box = el("input", { type: "checkbox", "aria-label": "この発言を選ぶ" });
    box.checked = picked.has(c.id);
    row.classList.toggle("picked", box.checked);
    const toggle = (on) => { box.checked = on; row.classList.toggle("picked", on); if (on) picked.add(c.id); else picked.delete(c.id); refreshSel(); };
    box.addEventListener("click", (e) => { e.stopPropagation(); toggle(box.checked); });
    // 行のどこをタップしても選べる（スマホで押しやすいように）。名前のIDを押したときの絞り込みは、そのまま
    row.addEventListener("click", (e) => { if (e.target.closest(".id")) return; toggle(!box.checked); });
    row.append(box, ...chatCells(c));
    return row;
  };
  const chatCells = (c) => [
    el("span", { class: "t", text: new Date(c.t + 9 * 3600 * 1000).toISOString().slice(0, 19).replace("T", " ") }),
    el("span", { class: "nm", text: c.name, title: c.name }),
    el("span", { class: "id", text: sid6(c.vid), title: c.vid + "（クリックでこの人の発言だけ表示）", onclick: () => { if (c.vid) { $("qvid").value = c.vid; loadChat(true); } } }),
    el("span", { class: "tx", text: c.text })];
  async function loadChat(reset) {
    const q = $("q").value.trim(), vid = $("qvid").value.trim();
    const params = new URLSearchParams({ limit: "200" });
    if (q) params.set("q", q);
    if (vid) params.set("vid", vid);
    if (!reset && chatOldest != null) params.set("before", String(chatOldest));
    const list = await api("chat?" + params);
    const box = $("chat-list");
    if (reset) { box.replaceChildren(); chatOldest = null; picked.clear(); }
    for (const c of list) box.append(chatRow(c));
    if (list.length) chatOldest = list[list.length - 1].id;
    if (reset && !list.length) box.append(el("div", { class: "msg" }, el("span", { class: "tx note", text: "まだありません" })));
    $("chat-more").hidden = list.length < 200;
    refreshSel();
  }
  $("chat-all").addEventListener("change", () => {
    const on = $("chat-all").checked;
    for (const row of document.querySelectorAll("#chat-list .msg[data-id]")) {
      const id = Number(row.dataset.id);
      const box = row.querySelector("input[type=checkbox]");
      if (!box) continue;
      box.checked = on;
      row.classList.toggle("picked", on);
      if (on) picked.add(id); else picked.delete(id);
    }
    refreshSel();
  });
  $("chat-del").addEventListener("click", async () => {
    const ids = [...picked];
    if (!ids.length) return;
    if (!confirm("選んだ " + ids.length + " 件の発言を削除します。記録からも、いま入室中の人の画面からも消えます。元に戻せません。よろしいですか？")) return;
    const r = await post("chat/delete", { ids });
    toast(r.ok ? r.deleted + " 件 削除しました" : "削除できませんでした", !r.ok);
    if (r.ok) { picked.clear(); loadChat(true); }
  });

  // ---------------------------------------------------------------- 入退室の記録
  async function loadSessions() {
    const list = await api("sessions?limit=200");
    table($("t-sessions"), [{ t: "入室" }, { t: "退室" }, { t: "滞在", n: 1 }, { t: "ニックネーム" }, { t: "訪問者ID" }, { t: "端末" }, { t: "チャット", n: 1 }, { t: "エモート", n: 1 }, { t: "スタンプ", n: 1 }],
      list.map((s) => tr([td(jst(s.joinedAt)), td(jst(s.leftAt)), td(dur(s.stay), 1), td(s.name), el("td", { class: "mono", text: sid6(s.vid), title: s.vid }), td(deviceLabel(s.device)), td(s.chats, 1), td(s.emotes, 1), td(s.stamps + "/" + (s.stampTotal || "?"), 1)])));
  }

  // ---------------------------------------------------------------- 運営の操作
  async function loadBans() {
    const list = await api("bans");
    table($("t-bans"), [{ t: "ニックネーム（当時）" }, { t: "訪問者ID" }, { t: "日時" }, { t: "" }],
      list.map((b) => tr([td(b.name), el("td", { class: "mono", text: b.vid.slice(0, 12) }), td(jst(b.at)),
        el("td", null, el("button", { class: "small", type: "button", text: "解除", onclick: async () => { const r = await post("unban", { vid: b.vid }); toast(r.ok ? "解除しました" : "できませんでした", !r.ok); loadBans(); } }))])));
  }
  $("announce").addEventListener("submit", async (e) => {
    e.preventDefault();
    const text = $("ann-text").value.trim();
    if (!text || !confirm("次のおしらせを全員に流します:\n\n" + text)) return;
    const r = await post("announce", { text });
    toast(r.ok ? "流しました" : "できませんでした", !r.ok);
    if (r.ok) $("ann-text").value = "";
  });
  $("del-visitor").addEventListener("submit", async (e) => {
    e.preventDefault();
    const vid = $("del-vid").value.trim();
    if (!confirm("訪問者ID「" + vid + "」のチャット・入退室の記録を削除します。元に戻せません。よろしいですか？")) return;
    const r = await post("delete-visitor", { vid });
    toast(r.ok ? "削除しました（入退室 " + r.sessions + " 件、チャット " + r.chats + " 件）" : "できませんでした", !r.ok);
    if (r.ok) { $("del-vid").value = ""; refresh(); }
  });
  $("purge").addEventListener("submit", async (e) => {
    e.preventDefault();
    if ($("purge-confirm").value.trim() !== "DELETE ALL") return toast("「DELETE ALL」と入力してください", true);
    if (!confirm("すべての記録を削除します。元に戻せません。本当によろしいですか？")) return;
    const r = await post("purge", { confirm: "DELETE ALL" });
    toast(r.ok ? "すべて削除しました" : "できませんでした", !r.ok);
    $("purge-confirm").value = "";
    refresh();
  });

  // ---------------------------------------------------------------- チャットの停止・再開（ワンタッチ）
  let chatLocked = false;
  const showLock = (locked) => {
    chatLocked = locked;
    const b = $("lock-btn");
    b.classList.toggle("on", locked);
    b.textContent = locked ? "🔒 チャット: 停止中（押すと再開）" : "💬 チャット: 開放中（押すと停止）";
  };
  $("lock-btn").addEventListener("click", async () => {
    const next = !chatLocked;
    const r = await post("chat/lock", { locked: next });
    if (r.ok) { showLock(r.chatLocked); toast(r.chatLocked ? "チャットを停止しました（いま入室中の全員）" : "チャットを再開しました"); }
    else toast("切り替えられませんでした", true);
  });

  // ---------------------------------------------------------------- 画面の切り替えと更新
  let tab = "overview";
  $("tabs").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-tab]");
    if (!b) return;
    tab = b.dataset.tab;
    for (const x of document.querySelectorAll("#tabs button")) x.classList.toggle("on", x === b);
    for (const s of document.querySelectorAll(".tab")) s.hidden = s.id !== "tab-" + tab;
    refresh();
  });
  $("chat-search").addEventListener("submit", (e) => { e.preventDefault(); loadChat(true); });
  $("chat-more").addEventListener("click", () => loadChat(false));
  $("reload").addEventListener("click", () => refresh(true));

  async function refresh(force) {
    try {
      const s = await api("summary");
      renderSummary(s);
      showLock(!!s.chatLocked);
      if (tab === "overview") lineChart($("c-online"), s.online24h, s.now - 24 * 3600 * 1000, s.now);
      if (tab === "online") await loadOnline();
      if (tab === "sessions") await loadSessions();
      if (tab === "ops") await loadBans();
      if (tab === "chat" && (force || !$("chat-list").childElementCount)) await loadChat(true);
    } catch (e) {
      $("updated").textContent = "読み込めませんでした（" + e.message + "）";
    }
  }
  setInterval(() => { if ($("auto").checked && document.visibilityState === "visible" && tab !== "chat") refresh(); }, 10000);
  window.addEventListener("resize", () => { if (lastSummary && tab === "overview") renderSummary(lastSummary); });
  refresh();
})();
