import Phaser from "phaser";
import { map, sprites, tileset, type ObjectDef } from "../config";
import { validateMap } from "../config/validate";
import { objectKey, tilesetKey } from "../game/assets";
import { WorldScene, type ObjectEntry } from "../scenes/WorldScene";
import { EditorPanel } from "./EditorPanel";
import { makeObject } from "./objectDefaults";
import { SHADOW_OFFSET, SHADOW_SPRITE, categoryOf } from "./mobCatalog";
import { PREFABS } from "./prefabs";

export type Tool = "select" | "object" | "collision" | "tile" | "spawn" | "prefab";
/** タイルパレットで選んだ矩形（タイルセット上の座標） */
export interface Stamp {
  tileset: string;
  tx: number;
  ty: number;
  tw: number;
  th: number;
}
interface Cmd {
  label: string;
  undo(): void;
  redo(): void;
}
type Drag =
  | { kind: "pan"; sx: number; sy: number; cx: number; cy: number }
  | { kind: "obj"; main: ObjectEntry; group: ObjectEntry[]; dx: number; dy: number; befores: { e: ObjectEntry; before: ObjectDef }[] }
  | { kind: "paint"; erase: boolean; lx: number; ly: number };

const TS = map.tileSize;
const ZOOMS = [0.5, 1, 2, 3, 4, 6];
/** 左の操作パネルの幅(px)。style.css の #ed と合わせる */
const PANEL_W = 340;
const STORE = "sunnyside.editor";

/**
 * マップエディタ（開発サーバーで `?edit=1` を付けて開く）。
 * ゲームと同じ描画のまま、配置物の移動・追加・削除、衝突マスのペイント、タイルの張り替え、スポーン位置の設定ができる。
 * 変更はメモリ上の map に加わり、「保存」で client/src/config/map.json に書き戻す（元のファイルは reference/map-backups/ に退避）。
 */
export class EditorScene extends WorldScene {
  tool: Tool = "select";
  layerIndex = 0;
  stamp: Stamp | null = null;
  skipEmpty = true;
  placeSprite = "";
  /** 置くとき、ゴブリン等には足元の影も一緒に置く */
  placeShadow = true;
  /** 「パーツ」ツールで選択中のプレハブ */
  prefabId: string = PREFABS[0]?.id ?? "";
  /** 選択したモブを動かす・複製・削除するとき、足元の影も一緒に扱う */
  linkShadow = true;
  show = { collision: true, hitboxes: true, grid: false, objects: true };
  layerVisible: boolean[] = [];
  selected: ObjectEntry | null = null;
  panel!: EditorPanel;

  private center = { x: (map.width * TS) / 2, y: (map.height * TS) / 2 };
  private zoomIdx = 2;
  private gfx!: Phaser.GameObjects.Graphics;
  private ghost?: Phaser.GameObjects.Sprite;
  private ghostShadow?: Phaser.GameObjects.Sprite;
  private history: Cmd[] = [];
  private hi = 0;
  private drag: Drag | null = null;
  private keys = new Set<string>();
  /** 1回のドラッグで変えたマス（元に戻す用に、最初の値を覚える） */
  private tileStroke = new Map<string, { li: number; x: number; y: number; prev: number; next: number }>();
  private collStroke = new Map<string, { x: number; y: number; prev: number; next: number }>();
  private alphaCache = new Map<string, (id: number) => boolean>();
  private saveTimer = 0;
  /** 保存されていない変更があるか（元に戻す履歴はモード切り替えのたびにリセットするので、これとは別に持つ） */
  private hasUnsaved = false;
  /** window へのキー入力リスナーはページで1回だけ張る（プレイ画面との行き来で積み重ねない） */
  private windowKeysBound = false;

  constructor() {
    super("Editor");
  }

  init(): void {
    super.init();
  }

  /** ズームはエディタ側で管理する（ゲームの自動ズームは使わない） */
  protected applyZoom(): void {}
  /** サーバーには接続しない */
  protected async connect(): Promise<void> {}

  get zoom(): number {
    return ZOOMS[this.zoomIdx];
  }

  create(): void {
    super.create();
    const cam = this.cameras.main;
    cam.removeBounds();
    cam.setBackgroundColor("#101820");
    this.gfx = this.add.graphics().setDepth(300000);
    this.layerVisible = (map.tileLayers ?? []).map(() => true);
    this.placeSprite = map.sprites?.["spr_idle"] ? "spr_idle" : (Object.keys(map.sprites ?? {}).sort()[0] ?? "");
    // プレイ画面との行き来でスプライトは作り直される（Phaserがシーン停止時に古いものを破棄するため）ので、
    // それを指していた「選択中の物」「元に戻す履歴」「ゴースト」は引き継がない。
    // データ自体は map に残っているので見た目には反映され続ける。「未保存」表示は hasUnsaved で別管理している。
    this.history = [];
    this.hi = 0;
    this.selected = null;
    this.drag = null;
    this.ghost = undefined;
    this.ghostShadow = undefined;
    this.restore();
    this.panel = new EditorPanel(this);
    // プレイ画面へ切り替わってこのシーンが止まったら、パネルのDOMと専用リスナーを片付ける
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.panel.destroy());
    if (!this.windowKeysBound) {
      this.windowKeysBound = true;
      window.addEventListener("keydown", (e) => this.onKey(e));
      window.addEventListener("keyup", (e) => this.keys.delete(e.code));
      window.addEventListener("blur", () => this.keys.clear());
    }
    this.bindInput();
    this.panel.status("編集を始められます。変更は「保存」を押すまでファイルに書かれません。");
  }

  // ---------------------------------------------------------------- 入力
  private typing(): boolean {
    const el = document.activeElement;
    return !!el && ["INPUT", "SELECT", "TEXTAREA"].includes(el.tagName);
  }

  /** 画面上で「中心」が来る位置。左のパネルに隠れないよう、パネルを除いた領域の中央にする */
  private screenCenterX(): number {
    return PANEL_W + (this.scale.width - PANEL_W) / 2;
  }

  private world(p: { x: number; y: number }): { x: number; y: number } {
    return { x: this.center.x + (p.x - this.screenCenterX()) / this.zoom, y: this.center.y + (p.y - this.scale.height / 2) / this.zoom };
  }

  /**
   * Phaser側の入力（ポインタ）は毎回のcreate()で張り直す。シーン停止時にPhaser自身が
   * InputPlugin ごとリスナーを片付けるので、これは積み重ならない（window直付けのキー入力とは別）。
   */
  private bindInput(): void {
    this.input.mouse?.disableContextMenu();
    this.input.on("pointerdown", (p: Phaser.Input.Pointer) => this.onDown(p));
    this.input.on("pointermove", (p: Phaser.Input.Pointer) => this.onMove(p));
    this.input.on("pointerup", () => this.onUp());
    this.input.on("pointerupoutside", () => this.onUp());
    this.input.on("wheel", (p: Phaser.Input.Pointer, _o: unknown, _dx: number, dy: number) => this.onWheel(p, dy));
  }

  private onKey(e: KeyboardEvent): void {
    if (this.typing()) return;
    this.keys.add(e.code);
    const ctrl = e.ctrlKey || e.metaKey;
    if (ctrl && e.code === "KeyZ") {
      e.preventDefault();
      e.shiftKey ? this.redo() : this.undo();
    } else if (ctrl && e.code === "KeyY") {
      e.preventDefault();
      this.redo();
    } else if (ctrl && e.code === "KeyS") {
      e.preventDefault();
      void this.save();
    } else if (!ctrl) {
      const tools: Record<string, Tool> = { KeyV: "select", KeyO: "object", KeyC: "collision", KeyT: "tile", KeyP: "spawn", KeyG: "prefab" };
      if (tools[e.code]) this.setTool(tools[e.code]);
      else if (e.code === "Delete" || e.code === "Backspace") this.deleteSelected();
      else if (e.code === "KeyF") this.flipSelected();
      else if (e.code === "KeyN") this.duplicateSelected();
      else if (e.code.startsWith("Arrow") && this.selected && this.tool === "select") {
        e.preventDefault();
        const step = e.shiftKey ? 8 : 1;
        const dx = e.code === "ArrowLeft" ? -step : e.code === "ArrowRight" ? step : 0;
        const dy = e.code === "ArrowUp" ? -step : e.code === "ArrowDown" ? step : 0;
        this.nudgeSelected(dx, dy);
      }
    }
    if (e.code === "Space" || e.code.startsWith("Arrow")) e.preventDefault();
  }

  private onWheel(p: Phaser.Input.Pointer, dy: number): void {
    const before = this.world(p);
    this.zoomIdx = Phaser.Math.Clamp(this.zoomIdx + (dy > 0 ? -1 : 1), 0, ZOOMS.length - 1);
    // ポインタの下のワールド座標が動かないように中心をずらす
    this.center.x = before.x - (p.x - this.screenCenterX()) / this.zoom;
    this.center.y = before.y - (p.y - this.scale.height / 2) / this.zoom;
    this.persist();
  }

  private onDown(p: Phaser.Input.Pointer): void {
    const w = this.world(p);
    const right = p.rightButtonDown();
    if (p.middleButtonDown() || this.keys.has("Space") || (right && this.tool !== "collision" && this.tool !== "tile")) {
      this.drag = { kind: "pan", sx: p.x, sy: p.y, cx: this.center.x, cy: this.center.y };
      return;
    }
    switch (this.tool) {
      case "select": {
        const hit = this.pickObject(w.x, w.y);
        this.select(hit);
        if (hit) {
          // 影と連動する設定なら、影も一緒に動かす（ドラッグ開始時に対応を確定する）
          const group = this.groupOf(hit);
          this.drag = { kind: "obj", main: hit, group, dx: hit.o.x - w.x, dy: hit.o.y - w.y, befores: group.map((e) => ({ e, before: structuredClone(e.o) })) };
        }
        break;
      }
      case "object":
        this.placeObject(Math.round(w.x), Math.round(w.y));
        break;
      case "collision":
      case "tile":
        this.drag = { kind: "paint", erase: right, lx: w.x, ly: w.y };
        this.paintAt(w.x, w.y, right);
        break;
      case "spawn":
        this.setSpawn(Math.floor(w.x / TS), Math.floor(w.y / TS));
        break;
      case "prefab":
        this.placePrefab(w.x, w.y);
        break;
    }
  }

  private onMove(p: Phaser.Input.Pointer): void {
    const d = this.drag;
    if (!d) return;
    const w = this.world(p);
    if (d.kind === "pan") {
      this.center.x = d.cx - (p.x - d.sx) / this.zoom;
      this.center.y = d.cy - (p.y - d.sy) / this.zoom;
    } else if (d.kind === "obj") {
      const nx = Math.round(w.x + d.dx), ny = Math.round(w.y + d.dy);
      const ddx = nx - d.main.o.x, ddy = ny - d.main.o.y;
      if (ddx || ddy) d.group.forEach((e) => this.moveObjectBy(e, ddx, ddy));
      this.panel.refreshInspector();
    } else if (d.kind === "paint") {
      // 素早いドラッグでマスが飛ばないよう、前回位置から現在位置までを小刻みに塗る
      const dist = Math.hypot(w.x - d.lx, w.y - d.ly);
      const step = 4; // px。最小のマス(16px)より十分細かい
      const n = Math.max(1, Math.ceil(dist / step));
      for (let i = 1; i <= n; i++) this.paintAt(d.lx + ((w.x - d.lx) * i) / n, d.ly + ((w.y - d.ly) * i) / n, d.erase);
      d.lx = w.x;
      d.ly = w.y;
    }
  }

  private onUp(): void {
    const d = this.drag;
    this.drag = null;
    if (!d) return;
    if (d.kind === "obj") {
      this.pushObjectEdits(d.group.length > 1 ? "モブと影を移動" : "物を移動", d.befores);
    } else if (d.kind === "paint") {
      this.finishStroke();
    } else this.persist();
  }

  // ---------------------------------------------------------------- ツール・選択
  setTool(t: Tool): void {
    this.tool = t;
    if (t !== "select") this.select(null);
    this.panel.onToolChanged();
    this.persist();
  }

  setLayer(i: number): void {
    this.layerIndex = i;
    this.panel.onToolChanged();
    this.persist();
  }

  setLayerVisible(i: number, v: boolean): void {
    this.layerVisible[i] = v;
    this.tileLayerRuntime[i]?.layers.forEach((l) => l.setVisible(v));
  }

  setObjectsVisible(v: boolean): void {
    this.show.objects = v;
    this.objectEntries.forEach((e) => e.s.setVisible(v));
  }

  select(e: ObjectEntry | null): void {
    this.selected = e;
    this.panel.refreshInspector();
  }

  /** 見た目の透明部分は無視して、クリック位置に絵がある一番手前の物を選ぶ */
  private pickObject(wx: number, wy: number): ObjectEntry | null {
    const list = [...this.objectEntries].sort((a, b) => b.s.depth - a.s.depth);
    for (const e of list) {
      if (!e.s.visible) continue;
      const def = map.sprites![e.o.sprite];
      let dx = wx - e.o.x, dy = wy - e.o.y;
      if (e.o.angle) {
        const r = (-e.o.angle * Math.PI) / 180;
        [dx, dy] = [dx * Math.cos(r) - dy * Math.sin(r), dx * Math.sin(r) + dy * Math.cos(r)];
      }
      const lx = Math.floor(dx / (e.o.sx ?? 1) + def.ox), ly = Math.floor(dy / (e.o.sy ?? 1) + def.oy);
      if (lx < 0 || ly < 0 || lx >= def.fw || ly >= def.fh) continue;
      if (this.textures.getPixelAlpha(lx, ly, objectKey(e.o.sprite), e.s.frame.name) > 16) return e;
    }
    return null;
  }

  // ---------------------------------------------------------------- 配置物の編集
  /** データを画面のスプライトに反映（位置・拡大・回転・前後・アニメ） */
  syncSprite(e: ObjectEntry, replay = false): void {
    const o = e.o, def = map.sprites![o.sprite];
    e.s.setPosition(o.x, o.y).setScale(o.sx ?? 1, o.sy ?? 1).setAngle(o.angle ?? 0).setDepth(this.objectDepth(o));
    if (replay && def.frames > 1) {
      const start = (((o.frame ?? 0) % def.frames) + def.frames) % def.frames;
      e.s.play({ key: objectKey(o.sprite), frameRate: def.fps * (o.speed ?? 1), startFrame: start, repeat: -1 });
    }
  }

  /** 物を (dx,dy) だけ動かす。足元Yと当たり判定の中心も一緒にずらす */
  private moveObjectBy(e: ObjectEntry, dx: number, dy: number): void {
    const o = e.o;
    o.x += dx;
    o.y += dy;
    o.by = Math.round((o.by + dy) * 100) / 100;
    if (o.hx !== undefined) o.hx = Math.round((o.hx + dx) * 100) / 100;
    this.syncSprite(e);
  }

  /** 物のデータを丸ごと差し替える（元に戻す／やり直し用） */
  private setObjectData(e: ObjectEntry, data: ObjectDef): void {
    for (const k of Object.keys(e.o)) delete (e.o as unknown as Record<string, unknown>)[k];
    Object.assign(e.o, structuredClone(data));
    this.syncSprite(e, true);
    if (this.selected === e) this.panel.refreshInspector();
  }

  /** 複数の物の変更を、1回の「元に戻す」にまとめて履歴に積む（変わっていないものは除く） */
  pushObjectEdits(label: string, edits: { e: ObjectEntry; before: ObjectDef }[]): void {
    const list = edits.map((x) => ({ e: x.e, before: x.before, after: structuredClone(x.e.o) })).filter((x) => JSON.stringify(x.before) !== JSON.stringify(x.after));
    if (!list.length) return;
    this.push({
      label,
      undo: () => list.forEach((x) => this.setObjectData(x.e, x.before)),
      redo: () => list.forEach((x) => this.setObjectData(x.e, x.after)),
    });
  }

  /** インスペクタなどからの編集: 変更前を控えて fn で変更し、履歴に積む（対象は選択中の物だけ） */
  editSelected(label: string, fn: (o: ObjectDef) => void, replay = true): void {
    const e = this.selected;
    if (!e) return;
    const before = structuredClone(e.o);
    fn(e.o);
    this.syncSprite(e, replay);
    this.pushObjectEdits(label, [{ e, before }]);
    this.panel.refreshInspector();
  }

  /** 選択中の物を動かす。影と連動する設定なら影も同じだけ動く */
  moveSelectedBy(dx: number, dy: number, label = "物を動かす"): void {
    const e = this.selected;
    if (!e || (dx === 0 && dy === 0)) return;
    const group = this.groupOf(e);
    const edits = group.map((g) => ({ e: g, before: structuredClone(g.o) }));
    group.forEach((g) => this.moveObjectBy(g, dx, dy));
    this.pushObjectEdits(label, edits);
    this.panel.refreshInspector();
  }

  private nudgeSelected(dx: number, dy: number): void {
    this.moveSelectedBy(dx, dy);
  }

  // ---------------------------------------------------------------- モブと影の対応
  /** モブごとの影（影の物は別のオブジェクトなので、足元付近の影を種類ごとの標準位置との近さで対応づける） */
  private shadowPairs(): Map<ObjectEntry, ObjectEntry> {
    const shadows = this.objectEntries.filter((e) => e.o.sprite === SHADOW_SPRITE);
    const cands: { m: ObjectEntry; s: ObjectEntry; d: number }[] = [];
    for (const m of this.objectEntries) {
      const off = SHADOW_OFFSET[categoryOf(m.o.sprite, map.sprites![m.o.sprite])];
      if (!off) continue;
      for (const s of shadows) {
        const d = Math.hypot(s.o.x - (m.o.x + off[0]), s.o.y - (m.o.by + off[1]));
        if (d <= 12) cands.push({ m, s, d });
      }
    }
    cands.sort((a, b) => a.d - b.d);
    const pairs = new Map<ObjectEntry, ObjectEntry>();
    const used = new Set<ObjectEntry>();
    for (const c of cands) {
      if (pairs.has(c.m) || used.has(c.s)) continue;
      pairs.set(c.m, c.s);
      used.add(c.s);
    }
    return pairs;
  }

  shadowOf(e: ObjectEntry): ObjectEntry | null {
    return this.shadowPairs().get(e) ?? null;
  }

  /** 操作の対象: 影と連動する設定なら [モブ, 影]、そうでなければ [モブ] */
  private groupOf(e: ObjectEntry): ObjectEntry[] {
    if (!this.linkShadow) return [e];
    const s = this.shadowOf(e);
    return s ? [e, s] : [e];
  }

  categoryOfEntry(e: ObjectEntry) {
    return categoryOf(e.o.sprite, map.sprites![e.o.sprite]);
  }

  /** 影のデータを、モブ o の標準位置に作る */
  private makeShadowFor(o: ObjectDef): ObjectDef | null {
    const off = SHADOW_OFFSET[categoryOf(o.sprite, map.sprites![o.sprite])];
    const sdef = map.sprites?.[SHADOW_SPRITE];
    if (!off || !sdef) return null;
    return makeObject(SHADOW_SPRITE, sdef, Math.round(o.x + off[0]), Math.round(o.by + off[1]));
  }

  addShadowToSelected(): void {
    const e = this.selected;
    if (!e || this.shadowOf(e)) return;
    const s = this.makeShadowFor(e.o);
    if (!s) return;
    this.addObjectsCmd("影を追加", [s]);
    this.panel.refreshInspector();
  }

  removeShadowOfSelected(): void {
    const e = this.selected;
    const s = e && this.shadowOf(e);
    if (!s) return;
    this.deleteEntries("影を削除", [s]);
    this.panel.refreshInspector();
  }

  flipSelected(): void {
    this.editSelected("左右反転", (o) => {
      o.sx = -(o.sx ?? 1);
      if (o.hx !== undefined) {
        const def = map.sprites![o.sprite];
        o.hx = Math.round((o.x + (def.fw / 2 - def.ox) * o.sx) * 100) / 100;
      }
    }, false);
  }

  /**
   * 物の「本体」(ObjectEntry と、その o データ)は作り直さず、絵(スプライト)だけを作り直す。
   * 削除→元に戻す をしても、それ以前の履歴が同じ本体を指し続けるため。
   */
  private attach(entry: ObjectEntry, index: number): void {
    entry.s = this.spawnObject(entry.o).s;
    entry.s.setVisible(this.show.objects);
    map.objects!.splice(index, 0, entry.o);
    this.objectEntries.splice(index, 0, entry);
  }

  private detach(entry: ObjectEntry): number {
    const i = this.objectEntries.indexOf(entry);
    this.objectEntries.splice(i, 1);
    map.objects!.splice(i, 1);
    entry.s.destroy();
    if (this.selected === entry) this.select(null);
    return i;
  }

  /** 物を末尾に追加する（複数まとめて1回の履歴）。追加した本体を返す */
  private addObjectsCmd(label: string, datas: ObjectDef[]): ObjectEntry[] {
    const entries: ObjectEntry[] = datas.map((o) => ({ o, s: undefined as unknown as Phaser.GameObjects.Sprite }));
    const start = this.objectEntries.length;
    entries.forEach((e, i) => this.attach(e, start + i));
    this.push({
      label,
      undo: () => [...entries].reverse().forEach((e) => this.detach(e)),
      redo: () => entries.forEach((e, i) => this.attach(e, start + i)),
    });
    return entries;
  }

  /** 物を削除する（複数まとめて1回の履歴）。元に戻すと元の並び位置に復元 */
  private deleteEntries(label: string, entries: ObjectEntry[]): void {
    const removed = entries.map((e) => ({ e, index: this.objectEntries.indexOf(e) })).sort((a, b) => a.index - b.index);
    [...removed].reverse().forEach((r) => this.detach(r.e));
    this.push({
      label,
      undo: () => removed.forEach((r) => this.attach(r.e, r.index)),
      redo: () => [...removed].reverse().forEach((r) => this.detach(r.e)),
    });
  }

  private placeObject(x: number, y: number): void {
    const def = map.sprites?.[this.placeSprite];
    if (!def) return;
    const main = makeObject(this.placeSprite, def, x, y);
    const datas = [main];
    // ゴブリン・スケルトン・人間は足元に影の物も一緒に置く（動物は絵に影が含まれるので不要）
    const shadow = this.placeShadow ? this.makeShadowFor(main) : null;
    if (shadow) datas.push(shadow);
    this.addObjectsCmd(`「${this.placeSprite}」を置く`, datas);
    this.panel.status(`置きました: ${this.placeSprite} (${x}, ${y})${shadow ? "（影つき）" : ""}`);
  }

  /**
   * 「パーツ」ツール: 複数タイル(複数レイヤー)・当たり判定・配置物をまとめて置く。
   * クリック位置のマスがパーツの左上になる（タイルツールのスタンプと同じ流儀）。
   * 変更は種類が違っても1回の「元に戻す」にまとめる。
   */
  private placePrefab(wx: number, wy: number): void {
    const pf = PREFABS.find((p) => p.id === this.prefabId);
    if (!pf) return;
    const ox = Math.floor(wx / TS), oy = Math.floor(wy / TS);
    const originPx = { x: ox * TS, y: oy * TS };

    const tileChanges: { li: number; x: number; y: number; prev: number; next: number }[] = [];
    for (const t of pf.tiles) {
      const li = map.tileLayers!.findIndex((l) => l.name === t.layer);
      if (li < 0) continue;
      const x = ox + t.dx, y = oy + t.dy;
      const row = map.tileLayers![li].data[y];
      if (!row || x < 0 || x >= row.length) continue;
      const prev = row[x];
      if (prev === t.id) continue;
      tileChanges.push({ li, x, y, prev, next: t.id });
    }

    const collChanges: { x: number; y: number; prev: number; next: number }[] = [];
    for (const c of pf.collision ?? []) {
      const x = ox + c.dx, y = oy + c.dy;
      const row = map.layers.collision[y];
      if (!row || x < 0 || x >= row.length || row[x] === 1) continue;
      collChanges.push({ x, y, prev: row[x], next: 1 });
    }

    const objectDatas: ObjectDef[] = (pf.objects ?? []).map((o) => {
      const data: ObjectDef = { sprite: o.sprite, x: originPx.x + o.dx, y: originPx.y + o.dy, sort: o.sort, by: originPx.y + o.byOff };
      if (o.sx !== undefined) data.sx = o.sx;
      if (o.sy !== undefined) data.sy = o.sy;
      if (o.angle !== undefined) data.angle = o.angle;
      if (o.frame !== undefined) data.frame = o.frame;
      if (o.speed !== undefined) data.speed = o.speed;
      if (o.hit !== undefined) data.hit = o.hit;
      if (o.hxOff !== undefined) data.hx = originPx.x + o.hxOff;
      return data;
    });

    if (!tileChanges.length && !collChanges.length && !objectDatas.length) {
      this.panel.status("ここには置けません（変化がありません）。", true);
      return;
    }

    const entries: ObjectEntry[] = objectDatas.map((o) => ({ o, s: undefined as unknown as Phaser.GameObjects.Sprite }));
    const start = this.objectEntries.length;
    tileChanges.forEach((c) => this.applyTile(c.li, c.x, c.y, c.next));
    collChanges.forEach((c) => (map.layers.collision[c.y][c.x] = c.next));
    entries.forEach((e, i) => this.attach(e, start + i));

    this.push({
      label: `パーツ「${pf.label}」を置く`,
      undo: () => {
        tileChanges.forEach((c) => this.applyTile(c.li, c.x, c.y, c.prev));
        collChanges.forEach((c) => (map.layers.collision[c.y][c.x] = c.prev));
        [...entries].reverse().forEach((e) => this.detach(e));
      },
      redo: () => {
        tileChanges.forEach((c) => this.applyTile(c.li, c.x, c.y, c.next));
        collChanges.forEach((c) => (map.layers.collision[c.y][c.x] = c.next));
        entries.forEach((e, i) => this.attach(e, start + i));
      },
    });
    this.panel.status(`置きました: ${pf.label}（タイル${tileChanges.length}・物${entries.length}）`);
  }

  deleteSelected(): void {
    const e = this.selected;
    if (!e) return;
    const group = this.groupOf(e);
    this.deleteEntries(group.length > 1 ? "モブと影を削除" : "物を削除", group);
    this.panel.status(group.length > 1 ? "モブと影を削除しました。" : "削除しました。");
  }

  duplicateSelected(): void {
    const e = this.selected;
    if (!e) return;
    const copies = this.groupOf(e).map((g) => {
      const c = structuredClone(g.o);
      c.x += 8;
      c.y += 8;
      c.by += 8;
      if (c.hx !== undefined) c.hx += 8;
      return c;
    });
    this.select(this.addObjectsCmd("物を複製", copies)[0]);
  }

  // ---------------------------------------------------------------- 衝突・タイルのペイント
  private paintAt(wx: number, wy: number, erase: boolean): void {
    if (this.tool === "collision") {
      const cx = Math.floor(wx / TS), cy = Math.floor(wy / TS);
      this.setCollision(cx, cy, erase ? 0 : 1);
      return;
    }
    const layer = map.tileLayers?.[this.layerIndex];
    const rt = this.tileLayerRuntime[this.layerIndex];
    if (!layer || !rt) return;
    const cx = Math.floor(wx / rt.size), cy = Math.floor(wy / rt.size);
    if (erase) {
      this.setTile(this.layerIndex, cx, cy, -1);
      return;
    }
    const st = this.stamp;
    if (!st) {
      this.panel.status("先にパレットからタイルを選んでください。");
      return;
    }
    if (st.tileset !== layer.tileset) {
      this.panel.status(`このレイヤーは「${layer.tileset}」のタイルセットです。パレットも同じものに切り替えてください。`);
      return;
    }
    const cols = map.tilesets![layer.tileset].columns;
    for (let j = 0; j < st.th; j++)
      for (let i = 0; i < st.tw; i++) {
        const id = (st.ty + j) * cols + (st.tx + i);
        if (this.skipEmpty && this.isEmptyTile(layer.tileset, id)) continue;
        this.setTile(this.layerIndex, cx + i, cy + j, id);
      }
  }

  private setCollision(x: number, y: number, v: number): void {
    const row = map.layers.collision[y];
    if (!row || x < 0 || x >= row.length) return;
    const prev = row[x];
    if (prev === v) return;
    row[x] = v;
    const key = `${x},${y}`;
    const first = this.collStroke.get(key);
    this.collStroke.set(key, { x, y, prev: first ? first.prev : prev, next: v });
  }

  private setTile(li: number, x: number, y: number, id: number): void {
    const layer = map.tileLayers![li];
    const row = layer.data[y];
    if (!row || x < 0 || x >= row.length) return;
    const prev = row[x];
    if (prev === id) return;
    this.applyTile(li, x, y, id);
    const key = `${li}:${x},${y}`;
    const first = this.tileStroke.get(key);
    this.tileStroke.set(key, { li, x, y, prev: first ? first.prev : prev, next: id });
  }

  /** データと画面の両方に1マスを反映する */
  private applyTile(li: number, x: number, y: number, id: number): void {
    const layer = map.tileLayers![li];
    layer.data[y][x] = id;
    const rt = this.tileLayerRuntime[li];
    if (rt.mode === "ysort") {
      let lyr = rt.layers.get(y);
      if (!lyr) {
        if (id < 0) return;
        lyr = rt.make([layer.data[y]], y * rt.size).setDepth((y + 1) * rt.size).setVisible(this.layerVisible[li]);
        rt.layers.set(y, lyr);
        return;
      }
      if (id < 0) lyr.removeTileAt(x, 0);
      else lyr.putTileAt(id, x, 0);
    } else {
      const lyr = rt.layers.get(0)!;
      if (id < 0) lyr.removeTileAt(x, y);
      else lyr.putTileAt(id, x, y);
    }
  }

  private finishStroke(): void {
    if (this.tileStroke.size) {
      const changes = [...this.tileStroke.values()];
      this.tileStroke.clear();
      this.push({
        label: `タイル ${changes.length} マス`,
        undo: () => changes.forEach((c) => this.applyTile(c.li, c.x, c.y, c.prev)),
        redo: () => changes.forEach((c) => this.applyTile(c.li, c.x, c.y, c.next)),
      });
    }
    if (this.collStroke.size) {
      const changes = [...this.collStroke.values()];
      this.collStroke.clear();
      const set = (c: { x: number; y: number }, v: number) => (map.layers.collision[c.y][c.x] = v);
      this.push({
        label: `衝突 ${changes.length} マス`,
        undo: () => changes.forEach((c) => set(c, c.prev)),
        redo: () => changes.forEach((c) => set(c, c.next)),
      });
    }
  }

  /** タイルセット上でそのタイルが完全に透明か（透明タイルは貼らない設定用） */
  private isEmptyTile(tsName: string, id: number): boolean {
    let fn = this.alphaCache.get(tsName);
    if (!fn) {
      const img = this.textures.get(tilesetKey(tsName)).getSourceImage() as HTMLImageElement;
      const s = map.tilesets![tsName].tileSize, cols = map.tilesets![tsName].columns;
      const cv = document.createElement("canvas");
      cv.width = img.width;
      cv.height = img.height;
      const ctx = cv.getContext("2d", { willReadFrequently: true })!;
      ctx.drawImage(img, 0, 0);
      fn = (tid: number) => {
        const d = ctx.getImageData((tid % cols) * s, Math.floor(tid / cols) * s, s, s).data;
        for (let i = 3; i < d.length; i += 4) if (d[i] > 0) return false;
        return true;
      };
      this.alphaCache.set(tsName, fn);
    }
    return fn(id);
  }

  private setSpawn(x: number, y: number): void {
    const before = { ...map.spawn };
    const after = { x, y };
    if (before.x === x && before.y === y) return;
    map.spawn = after;
    this.push({ label: "スポーン位置", undo: () => (map.spawn = { ...before }), redo: () => (map.spawn = { ...after }) });
    this.panel.status(`スポーンを (${x}, ${y}) にしました。`);
  }

  // ---------------------------------------------------------------- 履歴
  private push(c: Cmd): void {
    this.history.length = this.hi;
    this.history.push(c);
    this.hi = this.history.length;
    this.hasUnsaved = true;
    this.panel.refreshHistory();
  }

  undo(): void {
    if (this.hi === 0) return;
    const c = this.history[--this.hi];
    c.undo();
    this.panel.status(`元に戻す: ${c.label}`);
    this.panel.refreshHistory();
  }

  redo(): void {
    if (this.hi >= this.history.length) return;
    const c = this.history[this.hi++];
    c.redo();
    this.panel.status(`やり直し: ${c.label}`);
    this.panel.refreshHistory();
  }

  get canUndo(): boolean {
    return this.hi > 0;
  }
  get canRedo(): boolean {
    return this.hi < this.history.length;
  }
  /**
   * 最後に保存した時点から変更があるか。プレイ画面との行き来では元に戻す履歴をリセットするため
   * （スプライトが作り直され、履歴の中身が古い参照を指してしまうのを避けるため）、
   * 履歴の位置ではなく専用のフラグで判定する。
   */
  get dirty(): boolean {
    return this.hasUnsaved;
  }

  // ---------------------------------------------------------------- 保存
  async save(): Promise<void> {
    const errors = validateMap(map, sprites, tileset);
    if (errors.length) {
      this.panel.status(`保存しませんでした。map.json の検証エラー: ${errors[0]}（他 ${errors.length - 1} 件）`, true);
      return;
    }
    try {
      const res = await fetch("/__editor/save", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(map) });
      const text = await res.text();
      if (!res.ok) throw new Error(text);
      this.hasUnsaved = false;
      this.panel.refreshHistory();
      this.panel.status(`保存しました。${text}（ページが自動で再読み込みされます）`);
    } catch (e) {
      this.panel.status(`保存に失敗: ${e instanceof Error ? e.message : e}（「書き出し」で手動保存できます）`, true);
    }
  }

  /** ファイルとしてダウンロード（開発サーバー以外で編集したときなど） */
  download(): void {
    const blob = new Blob([JSON.stringify(map)], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "map.json";
    a.click();
    URL.revokeObjectURL(a.href);
  }

  // ---------------------------------------------------------------- 表示・毎フレーム
  update(time: number, delta: number): void {
    super.update(time, delta);
    const cam = this.cameras.main;
    if (!this.typing()) {
      const sp = ((this.keys.has("ShiftLeft") || this.keys.has("ShiftRight") ? 700 : 320) / this.zoom) * (delta / 1000);
      const arrows = !(this.selected && this.tool === "select");
      if (this.keys.has("KeyA") || (arrows && this.keys.has("ArrowLeft"))) this.center.x -= sp;
      if (this.keys.has("KeyD") || (arrows && this.keys.has("ArrowRight"))) this.center.x += sp;
      if (this.keys.has("KeyW") || (arrows && this.keys.has("ArrowUp"))) this.center.y -= sp;
      if (this.keys.has("KeyS") || (arrows && this.keys.has("ArrowDown"))) this.center.y += sp;
    }
    cam.setZoom(this.zoom);
    // カメラ中心は画面の真ん中なので、「表示中心」との差(パネル幅の半分)だけずらす
    cam.centerOn(this.center.x - (this.screenCenterX() - this.scale.width / 2) / this.zoom, this.center.y);
    this.drawOverlay();
    this.updateGhost();
    this.panel.tickCursor(this.world(this.input.activePointer));
  }

  private drawOverlay(): void {
    const g = this.gfx;
    g.clear();
    // 画面に映っているワールド範囲（パネルの下も含めて余裕を持って塗る）
    const wv = this.cameras.main.worldView;
    const x0 = wv.x - 16, y0 = wv.y - 16, x1 = wv.right + 16, y1 = wv.bottom + 16;
    const c0 = Math.max(0, Math.floor(x0 / TS)), c1 = Math.min(map.width - 1, Math.floor(x1 / TS));
    const r0 = Math.max(0, Math.floor(y0 / TS)), r1 = Math.min(map.height - 1, Math.floor(y1 / TS));
    const line = Math.max(1, 1 / this.zoom);

    if (this.show.collision || this.tool === "collision") {
      g.fillStyle(0xff3030, 0.38);
      for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) if (map.layers.collision[r][c] === 1) g.fillRect(c * TS, r * TS, TS, TS);
    }
    if (this.show.grid || this.tool === "collision") {
      g.lineStyle(line, 0xffffff, 0.18);
      for (let c = c0; c <= c1 + 1; c++) g.lineBetween(c * TS, r0 * TS, c * TS, (r1 + 1) * TS);
      for (let r = r0; r <= r1 + 1; r++) g.lineBetween(c0 * TS, r * TS, (c1 + 1) * TS, r * TS);
    }
    if (this.show.hitboxes) {
      g.lineStyle(line, 0xffd000, 0.95);
      for (const { o } of this.objectEntries) {
        if (!o.hit) continue;
        g.strokeRect((o.hx ?? o.x) - o.hit[0] / 2, o.by - o.hit[1], o.hit[0], o.hit[1]);
      }
    }
    if (this.tool === "prefab") {
      const pf = PREFABS.find((p) => p.id === this.prefabId);
      if (pf) {
        const w = this.world(this.input.activePointer);
        const cx = Math.floor(w.x / TS), cy = Math.floor(w.y / TS);
        g.lineStyle(line * 1.5, 0xffa030, 0.9);
        g.strokeRect(cx * TS, cy * TS, pf.w * TS, pf.h * TS);
      }
    }
    if (this.selected) {
      const b = this.selected.s.getBounds();
      g.lineStyle(line * 1.5, 0x30e0ff, 1);
      g.strokeRect(b.x, b.y, b.width, b.height);
      g.fillStyle(0x30e0ff, 1);
      g.fillCircle(this.selected.o.x, this.selected.o.y, 1.5 / Math.min(this.zoom, 3));
    }
    // スポーン位置
    g.lineStyle(line * 1.5, 0x4080ff, 1);
    g.strokeRect(map.spawn.x * TS, map.spawn.y * TS, TS, TS);
  }

  private updateGhost(): void {
    const show = this.tool === "object" && !!this.placeSprite && !!map.sprites?.[this.placeSprite];
    if (!show) {
      this.ghost?.setVisible(false);
      this.ghostShadow?.setVisible(false);
      return;
    }
    const def = map.sprites![this.placeSprite];
    if (!this.ghost) this.ghost = this.add.sprite(0, 0, objectKey(this.placeSprite)).setAlpha(0.6).setDepth(299999);
    if (this.ghost.texture.key !== objectKey(this.placeSprite)) this.ghost.setTexture(objectKey(this.placeSprite), 0);
    const w = this.world(this.input.activePointer);
    const gx = Math.round(w.x), gy = Math.round(w.y);
    this.ghost.setVisible(true).setOrigin(def.ox / def.fw, def.oy / def.fh).setPosition(gx, gy);

    // 影も置く設定なら、影の位置にも薄いプレビューを出す
    const main = makeObject(this.placeSprite, def, gx, gy);
    const shadow = this.placeShadow ? this.makeShadowFor(main) : null;
    const sdef = map.sprites?.[SHADOW_SPRITE];
    if (shadow && sdef) {
      if (!this.ghostShadow) this.ghostShadow = this.add.sprite(0, 0, objectKey(SHADOW_SPRITE)).setAlpha(0.5).setDepth(299998);
      this.ghostShadow.setVisible(true).setOrigin(sdef.ox / sdef.fw, sdef.oy / sdef.fh).setPosition(shadow.x, shadow.y);
    } else {
      this.ghostShadow?.setVisible(false);
    }
  }

  /** 選択中のタイルスタンプなど、カーソルの下のマスを枠で見せる */
  cursorCellRect(w: { x: number; y: number }): { x: number; y: number; w: number; h: number } | null {
    if (this.tool === "collision") return { x: Math.floor(w.x / TS) * TS, y: Math.floor(w.y / TS) * TS, w: TS, h: TS };
    if (this.tool === "tile") {
      const rt = this.tileLayerRuntime[this.layerIndex];
      if (!rt) return null;
      const st = this.stamp;
      const cw = (st && st.tileset === map.tileLayers![this.layerIndex].tileset ? st.tw : 1) * rt.size;
      const ch = (st && st.tileset === map.tileLayers![this.layerIndex].tileset ? st.th : 1) * rt.size;
      return { x: Math.floor(w.x / rt.size) * rt.size, y: Math.floor(w.y / rt.size) * rt.size, w: cw, h: ch };
    }
    return null;
  }

  // ---------------------------------------------------------------- 表示位置の記憶
  persist(): void {
    window.clearTimeout(this.saveTimer);
    this.saveTimer = window.setTimeout(() => {
      try {
        localStorage.setItem(STORE, JSON.stringify({ cx: this.center.x, cy: this.center.y, z: this.zoomIdx, tool: this.tool, layer: this.layerIndex, sprite: this.placeSprite }));
      } catch {
        /* 保存できなくても編集は続けられる */
      }
    }, 300);
  }

  private restore(): void {
    try {
      const s = JSON.parse(localStorage.getItem(STORE) ?? "null");
      if (!s) return;
      if (Number.isFinite(s.cx) && Number.isFinite(s.cy)) this.center = { x: s.cx, y: s.cy };
      if (Number.isInteger(s.z) && s.z >= 0 && s.z < ZOOMS.length) this.zoomIdx = s.z;
      if (Number.isInteger(s.layer) && s.layer >= 0 && s.layer < (map.tileLayers?.length ?? 0)) this.layerIndex = s.layer;
      if (typeof s.sprite === "string" && map.sprites?.[s.sprite]) this.placeSprite = s.sprite;
    } catch {
      /* 初回など */
    }
  }
}
