import { map } from "../config";
import type { AreaDef, KeyItemDef } from "../config/types";
import { sfx } from "../game/sfx";

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

const MAP_W = 200;
const STORE_KEY = "amplifire.minimap";
/** 区域に「入った」とみなす余白(px)。通路から出店の前に来たあたりで名前が出る */
const AREA_PAD_X = 10;
const AREA_PAD_Y = 14;
const BANNER_MS = 2600;
/** 近すぎるときは方位マーカーを出さない(px) */
const COMPASS_MIN = 40;

export interface Pt {
  x: number;
  y: number;
}

/**
 * 迷わないための道しるべ: ミニマップ（右上・Mキー）、場所の名前バナー、いちばん近い未取得スタンプへの方位マーカー、はじめてのヒント。
 * 区域は map.areas（出店の区画）。DOM で描く。Hud などと同じく、ボタンのリスナーはページで1回だけ張る。
 */
export class Navi {
  private static bound = false;
  private static current: Navi | null = null;

  private box = $("minimap");
  private cv = $<HTMLCanvasElement>("minimap-cv");
  private label = $("minimap-label");
  private compass = $("compass");
  private arrow = $("compass-arrow");
  private dist = $("compass-dist");
  private banner = $("area-banner");
  private tipEl = $("tip");
  private areas: AreaDef[] = map.areas ?? [];
  private bounds = { x: 0, y: 0, w: 1, h: 1 };
  private scale = 1;
  private cur = "";
  private bannerTimer = 0;
  private tipTimer = 0;
  private lastDraw = 0;

  constructor() {
    Navi.current = this;
    this.computeBounds();
    this.cv.width = MAP_W;
    this.cv.height = Math.max(40, Math.round(this.bounds.h * this.scale));
    this.cur = "";
    this.banner.hidden = true;
    this.tipEl.hidden = true;
    this.setOpen(this.restore());
    if (!Navi.bound) {
      Navi.bound = true;
      $("minimap-btn").addEventListener("click", () => Navi.current?.toggle());
      addEventListener("keydown", (e) => {
        if (e.key !== "m" && e.key !== "M") return;
        if ((e.target as HTMLElement | null)?.tagName === "INPUT") return;
        Navi.current?.toggle();
      });
    }
  }

  /** 島（グループ「文化祭島」）の外接矩形。無ければ区域の外接矩形。上に横断幕のぶんの余白を足す */
  private computeBounds(): void {
    const T = map.tileSize;
    const g = (map.groups ?? []).find((x) => x.label === "文化祭島");
    let x = 0, y = 0, w = map.width * T, h = map.height * T;
    if (g) {
      x = g.x * T; y = g.y * T; w = g.w * T; h = g.h * T;
    } else if (this.areas.length) {
      const x0 = Math.min(...this.areas.map((a) => a.x)), y0 = Math.min(...this.areas.map((a) => a.y));
      const x1 = Math.max(...this.areas.map((a) => a.x + a.w)), y1 = Math.max(...this.areas.map((a) => a.y + a.h));
      x = x0 - 16; y = y0 - 16; w = x1 - x0 + 32; h = y1 - y0 + 32;
    }
    const top = 40;
    this.bounds = { x, y: y - top, w, h: h + top };
    this.scale = MAP_W / w;
  }

  private restore(): boolean {
    try {
      return localStorage.getItem(STORE_KEY) !== "closed";
    } catch {
      return true;
    }
  }

  private setOpen(open: boolean): void {
    this.box.classList.toggle("closed", !open);
    try {
      localStorage.setItem(STORE_KEY, open ? "open" : "closed");
    } catch {
      /* 保存できなくても動く */
    }
  }

  toggle(): void {
    this.setOpen(this.box.classList.contains("closed"));
    this.lastDraw = 0;
  }

  /** 毎フレーム呼ぶ。描画は少し間引く */
  update(now: number, me: Pt, peers: Pt[], remaining: KeyItemDef[]): void {
    this.updateArea(me);
    this.updateCompass(me, remaining);
    if (this.box.classList.contains("closed") || now - this.lastDraw < 100) return;
    this.lastDraw = now;
    this.draw(now, me, peers, remaining);
  }

  private areaAt(p: Pt): AreaDef | null {
    return this.areas.find((a) => p.x >= a.x - AREA_PAD_X && p.x < a.x + a.w + AREA_PAD_X && p.y >= a.y - AREA_PAD_Y && p.y < a.y + a.h + AREA_PAD_Y) ?? null;
  }

  private updateArea(me: Pt): void {
    const a = this.areaAt(me);
    const id = a?.id ?? "";
    if (id === this.cur) return;
    this.cur = id;
    this.label.textContent = a ? `📍 ${a.name}` : "";
    if (!a) return;
    this.banner.textContent = a.name;
    this.banner.hidden = false;
    // アニメを最初からやり直す
    this.banner.classList.remove("show");
    void this.banner.offsetWidth;
    this.banner.classList.add("show");
    window.clearTimeout(this.bannerTimer);
    this.bannerTimer = window.setTimeout(() => (this.banner.hidden = true), BANNER_MS);
    sfx.area();
  }

  private updateCompass(me: Pt, remaining: KeyItemDef[]): void {
    let best: KeyItemDef | null = null;
    let bd = Infinity;
    for (const k of remaining) {
      const d = Math.hypot(k.x - me.x, k.y - me.y);
      if (d < bd) { bd = d; best = k; }
    }
    if (!best || bd < COMPASS_MIN) {
      this.compass.hidden = true;
      return;
    }
    this.compass.hidden = false;
    const ang = Math.atan2(best.y - me.y, best.x - me.x);
    this.arrow.style.transform = `rotate(${ang}rad)`;
    this.dist.textContent = `${best.name ?? "スタンプ"}  ${Math.round(bd / map.tileSize)}マス`;
  }

  private draw(now: number, me: Pt, peers: Pt[], remaining: KeyItemDef[]): void {
    const g = this.cv.getContext("2d");
    if (!g) return;
    const { x: bx, y: by } = this.bounds;
    const s = this.scale;
    const X = (v: number) => Math.round((v - bx) * s);
    const Y = (v: number) => Math.round((v - by) * s);
    g.clearRect(0, 0, this.cv.width, this.cv.height);
    // 島（出店の区画のまわりの草地）
    const isl = (map.groups ?? []).find((x) => x.label === "文化祭島");
    g.fillStyle = "rgba(76, 154, 63, 0.9)";
    if (isl) g.fillRect(X(isl.x * map.tileSize), Y(isl.y * map.tileSize), Math.round(isl.w * map.tileSize * s), Math.round(isl.h * map.tileSize * s));
    // 区画。いまいる所は明るく
    for (const a of this.areas) {
      g.fillStyle = a.id === this.cur ? "rgba(255, 224, 120, 0.95)" : "rgba(30, 60, 30, 0.55)";
      g.fillRect(X(a.x), Y(a.y), Math.max(2, Math.round(a.w * s)), Math.max(2, Math.round(a.h * s)));
    }
    // 未取得のスタンプ（点滅）
    if (Math.floor(now / 400) % 2 === 0) {
      g.fillStyle = "#ffd36a";
      for (const k of remaining) g.fillRect(X(k.x) - 1, Y(k.y) - 1, 3, 3);
    }
    // ほかの人
    g.fillStyle = "#ffffff";
    for (const p of peers) g.fillRect(X(p.x) - 1, Y(p.y) - 1, 2, 2);
    // 自分
    g.fillStyle = "#ff5f7a";
    g.fillRect(X(me.x) - 2, Y(me.y) - 2, 5, 5);
    g.strokeStyle = "#fff";
    g.strokeRect(X(me.x) - 2.5, Y(me.y) - 2.5, 6, 6);
  }

  // ---------------------------------------------------------------- はじめてのヒント
  /** 短い案内を順に出す（呼ぶ側が、初回だけにする） */
  showTips(lines: string[], each = 4600): void {
    window.clearTimeout(this.tipTimer);
    let i = 0;
    const next = () => {
      if (i >= lines.length) {
        this.tipEl.hidden = true;
        return;
      }
      this.tipEl.textContent = lines[i++];
      this.tipEl.hidden = false;
      this.tipTimer = window.setTimeout(next, each);
    };
    next();
  }

  hide(): void {
    window.clearTimeout(this.bannerTimer);
    window.clearTimeout(this.tipTimer);
    this.banner.hidden = true;
    this.tipEl.hidden = true;
    this.compass.hidden = true;
  }
}
