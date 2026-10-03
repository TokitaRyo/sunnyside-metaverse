import { map } from "../config";
import { objectKey, tilesetKey } from "../game/assets";
import { defaultHit } from "./objectDefaults";
import { CATEGORY_LABEL, CATEGORY_ORDER, categoryOf, hasShadow, isMobCategory, labelOf, sortNames, SHADOW_SPRITE, type Category } from "./mobCatalog";
import { PREFABS, PREFAB_CATEGORY_LABEL, PREFAB_CATEGORY_ORDER } from "./prefabs";
import type { Prefab } from "./prefabTypes";
import type { EditorScene, Tool } from "./EditorScene";

type Attrs = Record<string, string | number | boolean | ((e: Event) => void)>;

/** 小さなDOMヘルパー */
function h<K extends keyof HTMLElementTagNameMap>(tag: K, attrs: Attrs = {}, ...kids: (string | Node | null)[]): HTMLElementTagNameMap[K] {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (typeof v === "function") el.addEventListener(k.replace(/^on/, ""), v as EventListener);
    else if (k === "class") el.className = String(v);
    else if (typeof v === "boolean") (el as unknown as Record<string, unknown>)[k] = v;
    else el.setAttribute(k, String(v));
  }
  for (const kid of kids) if (kid !== null) el.append(kid);
  return el;
}

const TOOLS: [Tool, string, string][] = [
  ["select", "選択・移動", "V"],
  ["object", "物を置く", "O"],
  ["prefab", "パーツ", "G"],
  ["rect", "範囲選択", "B"],
  ["erase", "消す", "E"],
  ["warp", "ワープ", "R"],
  ["collision", "衝突", "C"],
  ["tile", "タイル", "T"],
  ["spawn", "スポーン", "P"],
];

/** エディタの操作パネル（画面左）。ゲーム側の状態は EditorScene が持ち、ここは表示と入力だけ。 */
export class EditorPanel {
  private root: HTMLDivElement;
  private statusEl: HTMLDivElement;
  private cursorEl: HTMLDivElement;
  private toolBtns = new Map<Tool, HTMLButtonElement>();
  private sections = new Map<Tool, HTMLDivElement>();
  private undoBtn!: HTMLButtonElement;
  private redoBtn!: HTMLButtonElement;
  private dirtyEl!: HTMLSpanElement;
  private inspector!: HTMLDivElement;
  private layerRows: HTMLInputElement[] = [];
  private layerSelect!: HTMLSelectElement;
  private palette!: HTMLCanvasElement;
  private paletteInfo!: HTMLDivElement;
  private palScale = 2;
  private palDrag: { tx: number; ty: number } | null = null;
  private lastCursor = "";
  private preview!: HTMLCanvasElement;
  private tabRow!: HTMLDivElement;
  private grid!: HTMLDivElement;
  private pickedLabel!: HTMLDivElement;
  private shadowBox!: HTMLDivElement;
  private catTabs = new Map<Category, HTMLButtonElement>();
  private thumbBtns = new Map<string, HTMLButtonElement>();
  private activeCat: Category = "goblin";
  private prefabTabRow!: HTMLDivElement;
  private prefabGrid!: HTMLDivElement;
  private rectInfo!: HTMLDivElement;
  private stampInfo!: HTMLDivElement;
  private prefabCatTabs = new Map<Prefab["category"], HTMLButtonElement>();
  private prefabThumbBtns = new Map<string, HTMLButtonElement>();
  private activePrefabCat: Prefab["category"] = "building";

  private onBeforeUnload = (e: BeforeUnloadEvent): void => {
    if (this.ed.dirty) e.preventDefault();
  };

  constructor(private ed: EditorScene) {
    document.body.classList.add("editing");
    ["join", "hud", "labels"].forEach((id) => {
      const el = document.getElementById(id);
      if (el) el.hidden = true;
    });
    this.statusEl = h("div", { class: "ed-status" });
    this.cursorEl = h("div", { class: "ed-cursor" });
    this.root = h("div", { id: "ed" });
    this.build();
    document.body.append(this.root);
    this.onToolChanged();
    this.refreshHistory();
    window.addEventListener("beforeunload", this.onBeforeUnload);
  }

  /** プレイ画面へ切り替えるときに呼ぶ。パネルのDOMと、ページに張ったリスナーを片付ける。 */
  destroy(): void {
    window.removeEventListener("beforeunload", this.onBeforeUnload);
    document.body.classList.remove("editing");
    // #hud は次に入室したとき Hud 側で、#join は main.ts 側で表示に戻す。
    // #labels（名前ラベルの入れ物）だけはここでしか隠していないので、ここで戻す。
    document.getElementById("labels")!.hidden = false;
    this.root.remove();
  }

  private build(): void {
    const ed = this.ed;
    this.undoBtn = h("button", { title: "Ctrl+Z", onclick: () => ed.undo() }, "元に戻す");
    this.redoBtn = h("button", { title: "Ctrl+Y", onclick: () => ed.redo() }, "やり直し");
    this.dirtyEl = h("span", { class: "ed-dirty" }, "");

    const head = h(
      "div",
      { class: "ed-head" },
      h("b", {}, "マップエディタ"),
      this.dirtyEl,
      h("div", { class: "ed-row" }, h("button", { class: "primary", title: "Ctrl+S", onclick: () => void ed.save() }, "保存"), h("button", { onclick: () => ed.download() }, "書き出し"), this.undoBtn, this.redoBtn),
    );

    const toolRow = h("div", { class: "ed-tools" });
    for (const [t, label, key] of TOOLS) {
      const b = h("button", { onclick: () => ed.setTool(t), title: `${label} (${key})` }, `${label} `, h("kbd", {}, key));
      this.toolBtns.set(t, b);
      toolRow.append(b);
    }

    const overlay = h(
      "div",
      { class: "ed-row ed-checks" },
      this.check("衝突を表示", ed.show.collision, (v) => (ed.show.collision = v)),
      this.check("判定枠", ed.show.hitboxes, (v) => (ed.show.hitboxes = v)),
      this.check("グリッド", ed.show.grid, (v) => (ed.show.grid = v)),
      this.check("物を表示", ed.show.objects, (v) => ed.setObjectsVisible(v)),
      this.check("プレイ画面の範囲(スマホ)", ed.show.viewport, (v) => (ed.show.viewport = v)),
    );

    // ---- ツール別の領域
    this.inspector = h("div", { class: "ed-inspector" });
    const sel = h("div", {}, this.inspector);
    this.sections.set("select", sel);

    this.preview = h("canvas", { class: "ed-preview" });
    this.tabRow = h("div", { class: "ed-cats" });
    this.grid = h("div", { class: "ed-mobgrid" });
    this.pickedLabel = h("div", { class: "ed-picked" });
    this.shadowBox = h("div", {});
    this.sections.set(
      "object",
      h(
        "div",
        {},
        this.tabRow,
        this.grid,
        h("div", { class: "ed-row" }, this.preview, this.pickedLabel),
        this.shadowBox,
        h("div", { class: "ed-hint" }, "一覧から選んで、マップをクリックすると置けます（続けて何個でも）。\n置いた後は「選択・移動」で位置を直せます。"),
      ),
    );
    this.buildCategoryTabs();

    this.prefabTabRow = h("div", { class: "ed-cats" });
    this.prefabGrid = h("div", { class: "ed-mobgrid" });
    this.sections.set(
      "prefab",
      h(
        "div",
        {},
        this.prefabTabRow,
        this.prefabGrid,
        h("div", { class: "ed-hint" }, "クリックした位置がパーツの左上になります（タイル・当たり判定・付属の物をまとめて1回で配置）。\n置いた後は動かせないので、位置を間違えたら元に戻す(Ctrl+Z)でやり直してください。"),
      ),
    );
    this.buildPrefabTabs();

    this.sections.set(
      "collision",
      h("div", {}, h("div", { class: "ed-hint" }, "左ドラッグ: 通れなくする（赤）\n右ドラッグ: 通れるようにする\n1マス = 16px。物の当たり判定（黄枠）は「選択・移動」で編集します。")),
    );

    this.sections.set(
      "erase",
      h(
        "div",
        {},
        h(
          "div",
          { class: "ed-hint" },
          "左ドラッグ: そのマスの全レイヤーのタイル・当たり判定・物(影も含む)をまとめて消します。\nパーツを置いた場所を丸ごと消したいときに使ってください。\n個別に1個だけ消したいときは「選択・移動」→Delete の方が安全です。",
        ),
      ),
    );

    const warpToX = h("input", { type: "number", value: ed.warpTo.x, min: 0, max: map.width - 1, onchange: (e: Event) => (ed.warpTo.x = Number((e.target as HTMLInputElement).value)) });
    const warpToY = h("input", { type: "number", value: ed.warpTo.y, min: 0, max: map.height - 1, onchange: (e: Event) => (ed.warpTo.y = Number((e.target as HTMLInputElement).value)) });
    this.sections.set(
      "warp",
      h(
        "div",
        {},
        h("label", {}, "移動先（マス座標）"),
        h("div", { class: "ed-grid" }, h("label", { class: "ed-field" }, h("span", {}, "先X"), warpToX), h("label", { class: "ed-field" }, h("span", {}, "先Y"), warpToY)),
        h(
          "div",
          { class: "ed-hint" },
          "左ドラッグ: 塗ったマスに、上の「移動先」でワープを設定します（紫＝ワープ元、水色＝今の移動先）。\n右ドラッグ: そのマスのワープを消します。\nそのマスに足元が乗ると、画面が一瞬暗転して移動先へ瞬間移動します。",
        ),
      ),
    );

    this.rectInfo = h("div", { class: "ed-hint" }, "ドラッグして範囲を選びます。");
    const rectButtons = h(
      "div",
      { class: "ed-row" },
      h("button", { class: "danger", onclick: () => ed.deleteSelection() }, "削除"),
      h("button", { onclick: () => ed.copySelection() }, "複製してスタンプ"),
    );
    this.sections.set(
      "rect",
      h(
        "div",
        {},
        this.rectInfo,
        rectButtons,
        h(
          "div",
          { class: "ed-hint" },
          "ドラッグ: 矩形の範囲を選びます（水色）。\n削除: 選んだ範囲の全レイヤーのタイル・当たり判定・物(影も含む)をまとめて消します。\n複製してスタンプ: 選んだ範囲をコピーして「スタンプ」ツールに切り替え、クリックした場所に何度でも置けます。",
        ),
      ),
    );

    this.stampInfo = h("div", { class: "ed-hint" }, "コピーした範囲がありません。「範囲選択」で選んでから複製してください。");
    this.sections.set(
      "stamp",
      h(
        "div",
        {},
        this.stampInfo,
        h("div", { class: "ed-row" }, h("button", { onclick: () => ed.setTool("rect") }, "選択に戻る (Esc)")),
        h("div", { class: "ed-hint" }, "クリックした位置が左上になるように、コピーした範囲を置きます。\n続けて何回でも置けます。"),
      ),
    );

    this.layerSelect = h("select", { onchange: (e: Event) => this.ed.setLayer(Number((e.target as HTMLSelectElement).value)) });
    (map.tileLayers ?? []).forEach((l, i) => this.layerSelect.append(h("option", { value: i }, `${l.name}（${l.tileset}・${l.mode}）`)));
    this.palette = h("canvas", { class: "ed-palette" });
    this.paletteInfo = h("div", { class: "ed-hint" }, "パレットをクリック（ドラッグで範囲）してタイルを選びます。");
    this.bindPalette();
    this.sections.set(
      "tile",
      h(
        "div",
        {},
        h("label", {}, "描くレイヤー"),
        this.layerSelect,
        this.check("透明なタイルは貼らない", ed.skipEmpty, (v) => (ed.skipEmpty = v)),
        h("div", { class: "ed-row" }, h("span", {}, "パレット倍率"), h("button", { onclick: () => this.setPalScale(1) }, "1x"), h("button", { onclick: () => this.setPalScale(2) }, "2x"), h("button", { onclick: () => this.setPalScale(3) }, "3x")),
        h("div", { class: "ed-palwrap" }, this.palette),
        this.paletteInfo,
        h("div", { class: "ed-hint" }, "左クリック/ドラッグ: 描く\n右クリック/ドラッグ: 消す"),
      ),
    );
    this.sections.set("spawn", h("div", { class: "ed-hint" }, "クリックしたマスを、入室時のスポーン位置にします（青枠）。\n本島の中央付近の、周りが歩ける場所にしてください。"));

    // ---- レイヤー一覧
    const layers = h("div", { class: "ed-layers" });
    (map.tileLayers ?? []).forEach((l, i) => {
      const box = h("input", { type: "checkbox", checked: true, title: "表示", onchange: (e: Event) => ed.setLayerVisible(i, (e.target as HTMLInputElement).checked) });
      this.layerRows.push(box);
      layers.append(h("label", { class: "ed-layer" }, box, h("span", {}, l.name), h("small", {}, l.mode)));
    });

    const help = h(
      "details",
      { class: "ed-help" },
      h("summary", {}, "操作"),
      h(
        "div",
        { class: "ed-hint" },
        "移動: WASD（Shiftで速く）／中ボタンやスペースを押しながらドラッグ\nズーム: マウスホイール\n選択中の物: 矢印キーで1px（Shiftで8px）、F=左右反転、N=複製、Delete=削除\nCtrl+Z / Ctrl+Y: 元に戻す / やり直し\nCtrl+S: 保存（元のファイルは reference/map-backups/ に退避）",
      ),
    );

    this.root.append(head, this.statusEl, toolRow, overlay, ...[...this.sections.values()], h("div", { class: "ed-title" }, "レイヤー"), layers, help, this.cursorEl);
    this.pickSprite(this.ed.placeSprite);
    this.layerSelect.value = String(this.ed.layerIndex);
  }

  private check(label: string, value: boolean, on: (v: boolean) => void): HTMLLabelElement {
    return h("label", { class: "ed-check" }, h("input", { type: "checkbox", checked: value, onchange: (e: Event) => on((e.target as HTMLInputElement).checked) }), label);
  }

  // ---------------------------------------------------------------- 外から呼ばれる
  status(msg: string, isError = false): void {
    this.statusEl.textContent = msg;
    this.statusEl.classList.toggle("err", isError);
  }

  onToolChanged(): void {
    for (const [t, b] of this.toolBtns) b.classList.toggle("on", t === this.ed.tool);
    for (const [t, s] of this.sections) s.hidden = t !== this.ed.tool;
    if (this.ed.tool === "tile") {
      this.layerSelect.value = String(this.ed.layerIndex);
      this.drawPalette();
    }
    if (this.ed.tool === "select") this.refreshInspector();
    if (this.ed.tool === "rect" || this.ed.tool === "stamp") this.onSelectionChanged();
  }

  /** 範囲選択・スタンプの表示更新（ドラッグ中・コピー後・削除後に呼ぶ） */
  onSelectionChanged(): void {
    const r = this.ed.selRect;
    this.rectInfo.textContent = r ? `選択中: ${r.w}×${r.h}マス（左上 ${r.x},${r.y}）` : "ドラッグして範囲を選びます。";
    const cb = this.ed.clipboard;
    this.stampInfo.textContent = cb ? `コピー済み: ${cb.w}×${cb.h}マス（タイル${cb.tiles.length}・物${cb.objects?.length ?? 0}）` : "コピーした範囲がありません。「範囲選択」で選んでから複製してください。";
  }

  refreshHistory(): void {
    this.undoBtn.disabled = !this.ed.canUndo;
    this.redoBtn.disabled = !this.ed.canRedo;
    this.dirtyEl.textContent = this.ed.dirty ? "● 未保存の変更あり" : "";
  }

  tickCursor(w: { x: number; y: number }): void {
    const cell = this.ed.cursorCellRect(w);
    const txt = `位置 ${Math.round(w.x)}, ${Math.round(w.y)} px ／ マス ${Math.floor(w.x / map.tileSize)}, ${Math.floor(w.y / map.tileSize)}${cell ? "" : ""}`;
    if (txt !== this.lastCursor) {
      this.lastCursor = txt;
      this.cursorEl.textContent = txt;
    }
  }

  // ---------------------------------------------------------------- インスペクタ（選択中の物）
  /** タイルで貼った物(グループ)を選んだときのインスペクタ */
  private groupInspector(g: import("../config").GroupDef): HTMLElement[] {
    const ed = this.ed;
    const num = (label: string, value: number, apply: (v: number) => void) =>
      h("label", { class: "ed-field" }, h("span", {}, label), h("input", { type: "number", value, step: 1, onchange: (ev: Event) => apply(Math.round(Number((ev.target as HTMLInputElement).value))) }));
    const mode = h(
      "select",
      { onchange: (ev: Event) => ed.setGroupCollision(g, (ev.target as HTMLSelectElement).value as "none" | "all" | "building") },
      h("option", { value: "" }, "（今のまま）"),
      h("option", { value: "none" }, "なし（通り抜けられる）"),
      h("option", { value: "all" }, "全面を塞ぐ"),
      h("option", { value: "building" }, "建物（下2行だけ通れる）"),
    );
    const blocked = g.collision.filter((c) => c.v === 1).length;
    return [
      h("div", { class: "ed-sel" }, h("b", {}, g.label), h("small", {}, `${g.w}×${g.h}マス ／ タイル${g.tiles.length}・判定${blocked}マス${g.warps?.length ? `・ワープ${g.warps.length}` : ""}`)),
      h("div", { class: "ed-grid" }, num("x", g.x, (v) => ed.moveGroupTo(g, v, g.y)), num("y", g.y, (v) => ed.moveGroupTo(g, g.x, v))),
      h("label", { class: "ed-field" }, h("span", {}, "当たり判定"), mode),
      h("div", { class: "ed-hint" }, "ドラッグ／矢印キー(Shiftで4マス)で、タイル・当たり判定・付属の物をまとめて動かせます。"),
      h("div", { class: "ed-row" }, h("button", { class: "danger", onclick: () => ed.deleteGroup(g) }, "削除 (Del)")),
    ];
  }

  refreshInspector(): void {
    const e = this.ed.selected;
    const box = this.inspector;
    box.replaceChildren();
    if (this.ed.selectedGroup) {
      box.append(...this.groupInspector(this.ed.selectedGroup));
      return;
    }
    if (!e) {
      box.append(h("div", { class: "ed-hint" }, "物をクリックして選びます。ドラッグで移動、矢印キーで微調整。\n何もない所をクリックすると選択解除。\nパーツや島などタイルで貼った物も、クリックするとまとめて選べます。"));
      return;
    }
    const o = e.o;
    const def = map.sprites![o.sprite];
    const num = (label: string, value: number, apply: (v: number) => void, step = 1) => {
      const input = h("input", { type: "number", value, step, onchange: (ev: Event) => apply(Number((ev.target as HTMLInputElement).value)) });
      return h("label", { class: "ed-field" }, h("span", {}, label), input);
    };
    const cat = this.ed.categoryOfEntry(e);
    box.append(
      h("div", { class: "ed-sel" }, h("b", {}, `${labelOf(o.sprite, cat)}`), h("small", {}, `${CATEGORY_LABEL[cat]} ／ ${o.sprite} ／ ${def.fw}×${def.fh}px・${def.frames}フレーム`)),
      this.shadowControls(e, cat),
      h(
        "div",
        { class: "ed-grid" },
        num("x", o.x, (v) => this.ed.moveSelectedBy(v - o.x, 0, "x を変更")),
        num("y", o.y, (v) => this.ed.moveSelectedBy(0, v - o.y, "y を変更")),
        num("開始フレーム", o.frame ?? 0, (v) => this.ed.editSelected("開始フレーム", (t) => (t.frame = Math.max(0, Math.floor(v))))),
        num("速度倍率", o.speed ?? 1, (v) => this.ed.editSelected("速度", (t) => (t.speed = v === 1 ? undefined : v)), 0.1),
      ),
      h(
        "label",
        { class: "ed-field" },
        h("span", {}, "前後の扱い"),
        (() => {
          const s = h("select", { onchange: (ev: Event) => this.ed.editSelected("前後の扱い", (t) => (t.sort = (ev.target as HTMLSelectElement).value as "y" | "floor"), false) }, h("option", { value: "y" }, "足元Yで前後判定"), h("option", { value: "floor" }, "常にキャラより下（影・床）"));
          s.value = o.sort;
          return s;
        })(),
      ),
      h("div", { class: "ed-title" }, "当たり判定（足元中央）"),
      h("label", { class: "ed-check" }, h("input", {
        type: "checkbox",
        checked: !!o.hit,
        onchange: (ev: Event) => {
          const on = (ev.target as HTMLInputElement).checked;
          this.ed.editSelected("当たり判定", (t) => {
            if (on) {
              t.hit = defaultHit(t.sprite, def) ?? [12, 8];
              t.hx = t.x + (def.fw / 2 - def.ox) * (t.sx ?? 1);
            } else {
              delete t.hit;
              delete t.hx;
            }
          }, false);
        },
      }), "この物は通れない"),
      o.hit
        ? h(
            "div",
            { class: "ed-grid" },
            num("幅 px", o.hit[0], (v) => this.ed.editSelected("判定の幅", (t) => (t.hit = [Math.max(1, v), t.hit![1]]), false)),
            num("高さ px", o.hit[1], (v) => this.ed.editSelected("判定の高さ", (t) => (t.hit = [t.hit![0], Math.max(1, v)]), false)),
            num("中心x", o.hx ?? o.x, (v) => this.ed.editSelected("判定の位置", (t) => (t.hx = v), false)),
            num("足元y", o.by, (v) => this.ed.editSelected("足元y", (t) => (t.by = v), false)),
          )
        : h("div", { class: "ed-hint" }, "（判定なし。歩いて通り抜けられます）"),
      h("div", { class: "ed-row" }, h("button", { onclick: () => this.ed.flipSelected() }, "左右反転 (F)"), h("button", { onclick: () => this.ed.duplicateSelected() }, "複製 (N)"), h("button", { class: "danger", onclick: () => this.ed.deleteSelected() }, "削除 (Del)")),
    );
  }

  /** 影まわりの操作（モブを選んだときだけ）。影そのものを選んだときは案内を出す */
  private shadowControls(e: import("../scenes/WorldScene").ObjectEntry, cat: Category): HTMLElement {
    if (e.o.sprite === SHADOW_SPRITE) {
      return h("div", { class: "ed-hint" }, "これは影です。モブと一緒に動かすには、モブ本体をクリックしてください。");
    }
    if (!hasShadow(cat)) {
      return h("div", { class: "ed-hint" }, isMobCategory(cat) ? "この種類は絵に影が含まれています（影の物は付きません）。" : "");
    }
    const shadow = this.ed.shadowOf(e);
    return h(
      "div",
      { class: "ed-shadowbox" },
      this.check("影も一緒に 動かす・複製・削除", this.ed.linkShadow, (v) => (this.ed.linkShadow = v)),
      h(
        "div",
        { class: "ed-row" },
        h("span", { class: shadow ? "ed-ok" : "ed-none" }, shadow ? `影: あり (${shadow.o.x}, ${shadow.o.y})` : "影: なし"),
        shadow ? h("button", { onclick: () => this.ed.removeShadowOfSelected() }, "影だけ削除") : h("button", { onclick: () => this.ed.addShadowToSelected() }, "影を追加"),
      ),
    );
  }

  // ---------------------------------------------------------------- 物・モブの一覧（カテゴリ別サムネイル）
  private categories(): Map<Category, string[]> {
    const by = new Map<Category, string[]>();
    for (const [name, def] of Object.entries(map.sprites ?? {})) {
      if (!this.ed.textures.exists(objectKey(name))) continue; // 読み込まれていない(エディタ外)ものは出さない
      const c = categoryOf(name, def);
      if (!by.has(c)) by.set(c, []);
      by.get(c)!.push(name);
    }
    for (const [c, names] of by) by.set(c, sortNames(names, c));
    return by;
  }

  private buildCategoryTabs(): void {
    const by = this.categories();
    this.tabRow.replaceChildren();
    this.catTabs.clear();
    for (const c of CATEGORY_ORDER) {
      const names = by.get(c);
      if (!names?.length) continue;
      const b = h("button", { onclick: () => this.setCategory(c) }, `${CATEGORY_LABEL[c]} `, h("small", {}, String(names.length)));
      this.catTabs.set(c, b);
      this.tabRow.append(b);
    }
    const cur = map.sprites?.[this.ed.placeSprite];
    this.setCategory(cur ? categoryOf(this.ed.placeSprite, cur) : "goblin");
  }

  private setCategory(c: Category): void {
    this.activeCat = c;
    for (const [k, b] of this.catTabs) b.classList.toggle("on", k === c);
    const names = this.categories().get(c) ?? [];
    this.grid.replaceChildren();
    this.thumbBtns.clear();
    for (const name of names) {
      const cv = h("canvas", { width: 44, height: 44 });
      this.drawThumb(cv, name);
      const b = h("button", { class: "ed-thumb", title: name, onclick: () => this.pickSprite(name) }, cv, h("span", {}, labelOf(name, c)));
      this.thumbBtns.set(name, b);
      this.grid.append(b);
    }
    for (const [n, b] of this.thumbBtns) b.classList.toggle("on", n === this.ed.placeSprite);
  }

  /** 1フレーム目を 44px の枠に収めて描く。96×64 のキャラは体のまわり(32×32)だけを切り出す */
  private drawThumb(cv: HTMLCanvasElement, name: string): void {
    const def = map.sprites![name];
    const ctx = cv.getContext("2d")!;
    ctx.imageSmoothingEnabled = false;
    ctx.clearRect(0, 0, 44, 44);
    const img = this.ed.textures.get(objectKey(name)).getSourceImage() as HTMLImageElement;
    if (def.fw === 96 && def.fh === 64) {
      ctx.drawImage(img, 32, 16, 32, 32, 0, 0, 44, 44);
    } else {
      const s = Math.min(44 / def.fw, 44 / def.fh, 3);
      const w = def.fw * s, hgt = def.fh * s;
      ctx.drawImage(img, 0, 0, def.fw, def.fh, (44 - w) / 2, (44 - hgt) / 2, w, hgt);
    }
  }

  private pickSprite(name: string): void {
    this.ed.placeSprite = name;
    this.ed.persist();
    const def = map.sprites?.[name];
    if (!def) return;
    const c = categoryOf(name, def);
    if (c !== this.activeCat) this.setCategory(c);
    for (const [n, b] of this.thumbBtns) b.classList.toggle("on", n === name);
    const cv = this.preview;
    const img = this.ed.textures.get(objectKey(name)).getSourceImage() as HTMLImageElement;
    const scale = Math.max(1, Math.floor(96 / Math.max(def.fw, def.fh)));
    cv.width = def.fw * scale;
    cv.height = def.fh * scale;
    const ctx = cv.getContext("2d")!;
    ctx.imageSmoothingEnabled = false;
    ctx.clearRect(0, 0, cv.width, cv.height);
    ctx.drawImage(img, 0, 0, def.fw, def.fh, 0, 0, cv.width, cv.height);
    this.pickedLabel.replaceChildren(h("b", {}, labelOf(name, c)), h("small", {}, `${CATEGORY_LABEL[c]} ／ ${name}`));
    // 影: ゴブリン・スケルトン・人間は別の物として置く。動物は絵に含まれるので不要
    this.shadowBox.replaceChildren(
      hasShadow(c)
        ? this.check("足元の影も一緒に置く", this.ed.placeShadow, (v) => (this.ed.placeShadow = v))
        : h("div", { class: "ed-hint" }, isMobCategory(c) ? "この種類は絵に影が含まれているので、影の追加は不要です。" : ""),
    );
  }

  // ---------------------------------------------------------------- パーツ（プレハブ）
  private buildPrefabTabs(): void {
    this.prefabTabRow.replaceChildren();
    this.prefabCatTabs.clear();
    for (const c of PREFAB_CATEGORY_ORDER) {
      const count = PREFABS.filter((p) => p.category === c).length;
      if (!count) continue;
      const b = h("button", { onclick: () => this.setPrefabCategory(c) }, `${PREFAB_CATEGORY_LABEL[c]} `, h("small", {}, String(count)));
      this.prefabCatTabs.set(c, b);
      this.prefabTabRow.append(b);
    }
    const cur = PREFABS.find((p) => p.id === this.ed.prefabId);
    this.setPrefabCategory(cur?.category ?? "building");
  }

  private setPrefabCategory(c: Prefab["category"]): void {
    this.activePrefabCat = c;
    for (const [k, b] of this.prefabCatTabs) b.classList.toggle("on", k === c);
    this.prefabGrid.replaceChildren();
    this.prefabThumbBtns.clear();
    for (const pf of PREFABS.filter((p) => p.category === c)) {
      const cv = h("canvas", { width: 56, height: 56 });
      this.drawPrefabThumb(cv, pf);
      const b = h("button", { class: "ed-thumb", title: `${pf.label}（${pf.w}×${pf.h}マス）`, onclick: () => this.pickPrefab(pf.id) }, cv, h("span", {}, pf.label));
      this.prefabThumbBtns.set(pf.id, b);
      this.prefabGrid.append(b);
    }
    for (const [id, b] of this.prefabThumbBtns) b.classList.toggle("on", id === this.ed.prefabId);
  }

  private pickPrefab(id: string): void {
    this.ed.prefabId = id;
    this.ed.persist();
    const pf = PREFABS.find((p) => p.id === id);
    if (pf && pf.category !== this.activePrefabCat) this.setPrefabCategory(pf.category);
    for (const [n, b] of this.prefabThumbBtns) b.classList.toggle("on", n === id);
  }

  /** パーツの中身(タイル+物)を縮小して描く。実際のタイルセット/スプライト画像から切り出すので見た目のズレがない。 */
  private drawPrefabThumb(cv: HTMLCanvasElement, pf: Prefab): void {
    const ctx = cv.getContext("2d")!;
    ctx.imageSmoothingEnabled = false;
    ctx.clearRect(0, 0, cv.width, cv.height);
    const cell = Math.max(2, Math.min(10, Math.floor(Math.min(cv.width / Math.max(pf.w, 1), cv.height / Math.max(pf.h, 1)))));
    const offX = (cv.width - pf.w * cell) / 2, offY = (cv.height - pf.h * cell) / 2;
    const tsCache = new Map<string, { img: HTMLImageElement; cols: number; size: number }>();
    const tsInfoFor = (layerName: string) => {
      const layer = map.tileLayers?.find((l) => l.name === layerName);
      if (!layer) return null;
      const key = layer.tileset;
      if (!tsCache.has(key)) {
        const def = map.tilesets![key];
        if (!this.ed.textures.exists(tilesetKey(key))) return null;
        tsCache.set(key, { img: this.ed.textures.get(tilesetKey(key)).getSourceImage() as HTMLImageElement, cols: def.columns, size: def.tileSize });
      }
      return tsCache.get(key) ?? null;
    };
    for (const t of pf.tiles) {
      const info = tsInfoFor(t.layer);
      if (!info) continue;
      const sx = (t.id % info.cols) * info.size, sy = Math.floor(t.id / info.cols) * info.size;
      ctx.drawImage(info.img, sx, sy, info.size, info.size, offX + t.dx * cell, offY + t.dy * cell, cell, cell);
    }
    const scale = cell / map.tileSize;
    for (const o of pf.objects ?? []) {
      const def = map.sprites?.[o.sprite];
      if (!def || !this.ed.textures.exists(objectKey(o.sprite))) continue;
      const img = this.ed.textures.get(objectKey(o.sprite)).getSourceImage() as HTMLImageElement;
      const frame = def.frames > 1 ? (((o.frame ?? 0) % def.frames) + def.frames) % def.frames : 0;
      const dw = def.fw * scale, dh = def.fh * scale;
      ctx.drawImage(img, frame * def.fw, 0, def.fw, def.fh, offX + o.dx * scale - def.ox * scale, offY + o.dy * scale - def.oy * scale, dw, dh);
    }
  }

  // ---------------------------------------------------------------- タイルパレット
  private tilesetName(): string {
    return map.tileLayers?.[this.ed.layerIndex]?.tileset ?? "main";
  }

  private setPalScale(n: number): void {
    this.palScale = n;
    this.drawPalette();
  }

  private drawPalette(): void {
    const name = this.tilesetName();
    const def = map.tilesets?.[name];
    if (!def) return;
    const img = this.ed.textures.get(tilesetKey(name)).getSourceImage() as HTMLImageElement;
    const sc = this.palScale;
    const cv = this.palette;
    cv.width = img.width * sc;
    cv.height = img.height * sc;
    const ctx = cv.getContext("2d")!;
    ctx.imageSmoothingEnabled = false;
    ctx.fillStyle = "#2a3340";
    ctx.fillRect(0, 0, cv.width, cv.height);
    ctx.drawImage(img, 0, 0, cv.width, cv.height);
    const cell = def.tileSize * sc;
    ctx.strokeStyle = "rgba(255,255,255,0.12)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let x = 0; x <= cv.width; x += cell) { ctx.moveTo(x + 0.5, 0); ctx.lineTo(x + 0.5, cv.height); }
    for (let y = 0; y <= cv.height; y += cell) { ctx.moveTo(0, y + 0.5); ctx.lineTo(cv.width, y + 0.5); }
    ctx.stroke();
    const st = this.ed.stamp;
    if (st && st.tileset === name) {
      ctx.strokeStyle = "#30e0ff";
      ctx.lineWidth = 2;
      ctx.strokeRect(st.tx * cell + 1, st.ty * cell + 1, st.tw * cell - 2, st.th * cell - 2);
    }
  }

  private bindPalette(): void {
    const cellAt = (e: PointerEvent) => {
      const def = map.tilesets![this.tilesetName()];
      const r = this.palette.getBoundingClientRect();
      const cell = def.tileSize * this.palScale;
      return { tx: Math.max(0, Math.floor((e.clientX - r.left) / cell)), ty: Math.max(0, Math.floor((e.clientY - r.top) / cell)) };
    };
    const apply = (a: { tx: number; ty: number }, b: { tx: number; ty: number }) => {
      const name = this.tilesetName();
      const cols = map.tilesets![name].columns;
      const tx = Math.min(a.tx, b.tx), ty = Math.min(a.ty, b.ty);
      this.ed.stamp = { tileset: name, tx, ty, tw: Math.abs(a.tx - b.tx) + 1, th: Math.abs(a.ty - b.ty) + 1 };
      const id = ty * cols + tx;
      this.paletteInfo.textContent = `選択: タイルID ${id}（${this.ed.stamp.tw}×${this.ed.stamp.th} マス）`;
      this.drawPalette();
    };
    this.palette.addEventListener("pointerdown", (e) => {
      this.palette.setPointerCapture(e.pointerId);
      this.palDrag = cellAt(e);
      apply(this.palDrag, this.palDrag);
    });
    this.palette.addEventListener("pointermove", (e) => {
      if (this.palDrag) apply(this.palDrag, cellAt(e));
    });
    this.palette.addEventListener("pointerup", () => (this.palDrag = null));
  }
}
