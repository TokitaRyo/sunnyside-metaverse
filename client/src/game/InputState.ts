/**
 * キーボード＋バーチャルパッドの入力状態。
 * Phaser のキーボード機能は使わず window で直接拾う。
 * （Phaser の Key capture が DOM の入力欄での文字入力を preventDefault してしまうのを避けるため）
 */
export class InputState {
  private down = new Set<string>();
  /** バーチャルパッド由来 */
  private pad = { up: false, down: false, left: false, right: false, run: false };
  onEmoteKey?: (index: number) => void;
  onEnter?: () => void;
  /** E / Space（話す・会話を進める） */
  onAction?: () => void;
  onEscape?: () => void;

  constructor() {
    window.addEventListener("keydown", this.onKeyDown);
    window.addEventListener("keyup", this.onKeyUp);
    window.addEventListener("blur", this.clear);
    document.addEventListener("visibilitychange", this.clear);
  }

  /** テキスト入力にフォーカスがある間は移動キーを無効化する（SPEC Phase 4） */
  get typing(): boolean {
    const el = document.activeElement;
    return !!el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA");
  }

  setPad(key: keyof InputState["pad"], value: boolean): void {
    this.pad[key] = value;
  }

  clear = (): void => {
    this.down.clear();
    this.pad = { up: false, down: false, left: false, right: false, run: false };
  };

  private onKeyDown = (e: KeyboardEvent): void => {
    if (this.typing) return; // 入力欄側の keydown に任せる
    if (e.code === "Enter") {
      e.preventDefault();
      this.onEnter?.();
      return;
    }
    if (e.repeat) {
      if (this.isGameKey(e.code)) e.preventDefault();
      return;
    }
    if (e.code === "KeyE" || e.code === "Space") {
      e.preventDefault();
      this.onAction?.();
      return;
    }
    if (e.code === "Escape") {
      this.onEscape?.();
      return;
    }
    if (/^Digit[1-9]$/.test(e.code)) {
      this.onEmoteKey?.(Number(e.code.slice(5)) - 1);
      return;
    }
    if (this.isGameKey(e.code)) {
      e.preventDefault();
      this.down.add(e.code);
    }
  };

  private onKeyUp = (e: KeyboardEvent): void => {
    this.down.delete(e.code);
  };

  private isGameKey(code: string): boolean {
    return /^(Key[WASD]|Arrow(Up|Down|Left|Right)|Shift(Left|Right))$/.test(code);
  }

  private any(...codes: string[]): boolean {
    return codes.some((c) => this.down.has(c));
  }

  /** 移動ベクトル (-1〜1)。入力中は常に 0。 */
  get vector(): { x: number; y: number } {
    if (this.typing) return { x: 0, y: 0 };
    let x = 0;
    let y = 0;
    if (this.any("KeyA", "ArrowLeft") || this.pad.left) x -= 1;
    if (this.any("KeyD", "ArrowRight") || this.pad.right) x += 1;
    if (this.any("KeyW", "ArrowUp") || this.pad.up) y -= 1;
    if (this.any("KeyS", "ArrowDown") || this.pad.down) y += 1;
    return { x, y };
  }

  get run(): boolean {
    return !this.typing && (this.any("ShiftLeft", "ShiftRight") || this.pad.run);
  }
}
