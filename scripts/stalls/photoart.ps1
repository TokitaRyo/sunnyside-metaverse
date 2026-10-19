# 写真美術部（ギャラリー兼展示ブース）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/photoart.ps1   （リポジトリのルートで実行）
#   一部だけ作り直す: $env:PA_ONLY='sign|wall'; powershell ...（名前の正規表現）
# 出力: client/public/brand/stall/photoart_*.png （配置は scripts/stalls/photoart.mjs）
# 内容: 床(赤いカーペット) / 奥の壁(額縁の絵4枚+スポットライト) / 看板(電球が流れる) / 壁の光(photoart_glow) /
#       イーゼルと描きかけのキャンバス / 三脚つきカメラ(フラッシュ) / 台座と花瓶 / スポットライトとその光 /
#       ポラロイドを吊るしたワイヤー / パレットと筆の台 / 立てかけた額縁
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function Sheet($name, $w, $h, $n, $draw) {
  if ($env:PA_ONLY -and ($name -notmatch $env:PA_ONLY)) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}
function P($b, $x, $y, $col) { Px $b ([int][math]::Round($x)) ([int][math]::Round($y)) $col }
# 整数に丸めてから線を引く（Line に小数を渡すと止まらなくなるので）
function L($b, $x0, $y0, $x1, $y1, $col) { Line $b ([int][math]::Round($x0)) ([int][math]::Round($y0)) ([int][math]::Round($x1)) ([int][math]::Round($y1)) $col }

# ---- 色 ----
$ink = C '#1c1822'; $ink2 = C '#2d2838'
$wd0 = C '#e8c590'; $wd1 = C '#c9975c'; $wd2 = C '#9a6a3c'; $wd3 = C '#6a4426'; $wd4 = C '#45291a'   # 木（明→暗）
$gl0 = C '#fbe08a'; $gl1 = C '#e0ac3c'; $gl2 = C '#a8741c'                                           # 金
$cr0 = C '#fffaf0'; $cr1 = C '#f1e8d2'; $cr2 = C '#d6c9a8'; $cr3 = C '#a89c7c'                       # クリーム
$sv0 = C '#f2f4f8'; $sv1 = C '#c9ced8'; $sv2 = C '#8a8fa0'; $sv3 = C '#4a4a58'                       # 銀・鉄
$wl0 = C '#e6dfce'; $wl1 = C '#ddd5c3'; $wl2 = C '#cfc6b2'                                             # 壁
$navy0 = C '#2c4672'; $navy1 = C '#18284a'; $navy2 = C '#10192e'
$gr0 = C '#8ed17a'; $gr1 = C '#56ad5a'; $gr2 = C '#2f7a48'; $gr3 = C '#1d5436'                         # 緑
$yl = C '#ffd36a'; $yw = C '#fff6cf'
$pk = C '#f0508a'; $pk2 = C '#f7a0c0'; $rd = C '#d6403a'; $bl = C '#2f5fb8'; $bl2 = C '#79a6f0'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# 色の点（原点つき）と四角
function Q($b, $ox, $oy, $x, $y, $col) { Px $b ($ox + $x) ($oy + $y) $col }
function QR($b, $ox, $oy, $x, $y, $w, $h, $col) { Rect $b ($ox + $x) ($oy + $y) $w $h $col }

# ====================================================================
# 床 176x72: ギャラリーの木の床。真ん中に赤いカーペット、絵の具のしみ
Sheet 'photoart_floor.png' 176 72 1 {
  param($b, $ox, $f)
  $cols = @((C '#dcbc8c'), (C '#d2b080'), (C '#c8a674'), (C '#d6b684'))
  $seam = C '#a98150'; $seamL = C '#e6cc9e'
  for ($row = 0; $row -lt 9; $row++) {
    $y = $row * 8
    $off = ($row * 13) % 32
    for ($px = -$off; $px -lt 176; $px += 32) {
      $x0 = [math]::Max(0, $px); $x1 = [math]::Min(176, $px + 32)
      $ci = (($row * 3 + [int][math]::Floor(($px + 64) / 32)) % 4 + 4) % 4
      Rect $b ($ox + $x0) $y ($x1 - $x0) 8 $cols[$ci]
      Rect $b ($ox + $x0) $y ($x1 - $x0) 1 $seamL
      Rect $b ($ox + $x0) ($y + 7) ($x1 - $x0) 1 $seam
      if ($px -ge 0) { Rect $b ($ox + $px) $y 1 8 $seam }
      # 木目
      for ($g = 0; $g -lt 3; $g++) { $gx = $x0 + 5 + (($row * 7 + $g * 11 + $px) % 20); if ($gx -lt $x1 - 3) { Rect $b ($ox + $gx) ($y + 2 + $g * 2) 4 1 (Mix $cols[$ci] $seam 0.35) } }
    }
  }
  # カーペット（入口から奥へ）
  $cx0 = 76; $cw = 24
  $cb = C '#8f2a3a'; $cb2 = C '#6e1c2c'; $cb3 = C '#b04458'
  Rect $b ($ox + $cx0) 10 $cw 62 $cb
  Rect $b ($ox + $cx0) 10 1 62 $cb2; Rect $b ($ox + $cx0 + $cw - 1) 10 1 62 $cb2
  Rect $b ($ox + $cx0 + 2) 12 1 60 $gl1; Rect $b ($ox + $cx0 + $cw - 3) 12 1 60 $gl1
  Rect $b ($ox + $cx0 + 4) 12 1 60 $cb3; Rect $b ($ox + $cx0 + $cw - 5) 12 1 60 $cb3
  for ($y = 14; $y -lt 70; $y += 8) {
    # ひし形のもよう
    $mx = $cx0 + 12
    Px $b ($ox + $mx) ($y) $gl0; Px $b ($ox + $mx - 1) ($y + 1) $gl1; Px $b ($ox + $mx + 1) ($y + 1) $gl1
    Px $b ($ox + $mx - 2) ($y + 2) $gl1; Px $b ($ox + $mx + 2) ($y + 2) $gl1; Px $b ($ox + $mx) ($y + 2) $cb3
    Px $b ($ox + $mx - 1) ($y + 3) $gl1; Px $b ($ox + $mx + 1) ($y + 3) $gl1; Px $b ($ox + $mx) ($y + 4) $gl0
  }
  Rect $b ($ox + $cx0) 10 $cw 1 $cb2
  for ($x = $cx0; $x -lt $cx0 + $cw; $x += 2) { Px $b ($ox + $x) 8 $cr1; Px $b ($ox + $x) 9 $cr2 }
  # 壁ぎわの影
  for ($i = 0; $i -lt 4; $i++) { Rect $b $ox $i 176 1 (CA '#2a1a10' (60 - $i * 15)) }
  # 絵の具のしみ（イーゼルの足元）
  $splats = @(@(14, 40, '#2f5fb8'), @(18, 44, '#d6403a'), @(11, 47, '#ffd36a'), @(22, 38, '#56ad5a'), @(26, 46, '#2f5fb8'), @(9, 41, '#f0508a'))
  foreach ($s in $splats) { $c = C $s[2]; Rect $b ($ox + $s[0]) $s[1] 2 2 $c; Px $b ($ox + $s[0] + 2) ($s[1] + 1) $c; Px $b ($ox + $s[0] - 1) ($s[1] + 3) (Mix $c (C '#ffffff') 0.3) }
  # 縁
  Rect $b $ox 0 2 72 $wd3; Rect $b ($ox + 174) 0 2 72 $wd3; Rect $b $ox 0 1 72 $wd2; Rect $b ($ox + 174) 0 1 72 $wd2
  Rect $b $ox 69 176 3 $wd3; Rect $b $ox 69 176 1 $wd2
  foreach ($p in @(@(0, 0), @(175, 0), @(0, 71), @(175, 71))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ====================================================================
# 壁 176x52: 梁のトラックライト、額縁の絵 4 枚（風景・花・夜の街・海）、プレート、腰板
Sheet 'photoart_wall.png' 176 52 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 176 52 $wl1
  for ($x = 4; $x -lt 176; $x += 8) { Rect $b ($ox + $x) 6 1 40 $wl0 }
  for ($x = 8; $x -lt 176; $x += 8) { Rect $b ($ox + $x) 6 1 40 $wl2 }
  # 上の梁とトラック
  Rect $b $ox 0 176 4 $wd3; Rect $b $ox 0 176 1 $wd2; Rect $b $ox 3 176 1 $wd4
  Rect $b ($ox + 3) 4 170 2 $ink2; Rect $b ($ox + 3) 4 170 1 $sv3
  # 腰板
  Rect $b $ox 47 176 5 $wd2; Rect $b $ox 47 176 1 $wd1; Rect $b $ox 51 176 1 $wd4
  for ($x = 0; $x -lt 176; $x += 22) { Rect $b ($ox + $x) 48 1 3 $wd3 }
  Rect $b $ox 46 176 1 $wl2

  # --- 絵 A: 風景（金の額縁）x6 y15 42x28 → 中身 34x20 @ (10,19)
  Rect $b ($ox + 6) 15 42 28 $ink; Rect $b ($ox + 7) 16 40 26 $gl1
  Rect $b ($ox + 7) 16 40 1 $gl0; Rect $b ($ox + 7) 16 1 26 $gl0; Rect $b ($ox + 46) 16 1 26 $gl2; Rect $b ($ox + 7) 41 40 1 $gl2
  Rect $b ($ox + 9) 18 36 22 $wd4
  $ax = $ox + 10; $ay = 19
  for ($y = 0; $y -lt 13; $y++) { Rect $b $ax ($ay + $y) 34 1 (Mix (C '#6fb5e6') (C '#cfeaf4') ($y / 12.0)) }
  Ellipse $b ($ax + 28.5) ($ay + 4.5) 4.4 4.4 (CA '#fff1b0' 255); Ellipse $b ($ax + 28.5) ($ay + 4.5) 2.6 2.6 $yw
  # 遠い山
  foreach ($m in @(@(10, 4, 0, 22), @(25, 6, 14, 34))) {
    for ($x = $m[2]; $x -lt $m[3]; $x++) {
      $t = if ($x -le $m[0]) { ($x - $m[2]) / [math]::Max(1.0, $m[0] - $m[2]) } else { ($m[3] - $x) / [math]::Max(1.0, $m[3] - $m[0]) }
      $top = [int][math]::Round(13 - ($t * (13 - $m[1])))
      if ($top -lt 13) { QR $b $ax $ay $x $top 1 (13 - $top) (C '#8aa0c8'); if ($t -gt 0.7) { Q $b $ax $ay $x $top (C '#e8f0fa') } }
    }
  }
  # 丘
  for ($x = 0; $x -lt 34; $x++) {
    $top = 12 + [int][math]::Round(1.6 * [math]::Sin($x * 0.28 + 0.5))
    for ($y = $top; $y -lt 20; $y++) { $c = if ($y -lt $top + 3) { C '#8ad06a' } elseif ($y -lt 16) { C '#56ad5a' } else { C '#3d8a4c' }; Q $b $ax $ay $x $y $c }
  }
  # 小道
  for ($y = 14; $y -lt 20; $y++) { $px = 22 - ($y - 14) * 2; QR $b $ax $ay $px $y (3 + ($y - 14)) 1 (C '#e8d6a4') }
  # 木と家
  QR $b $ax $ay 7 12 2 5 (C '#6a4426'); Ellipse $b ($ax + 8) ($ay + 10) 4.4 3.6 (C '#2f7a48'); Ellipse $b ($ax + 7) ($ay + 9) 2.2 1.8 (C '#56ad5a'); Q $b $ax $ay 6 8 (C '#8ad06a')
  QR $b $ax $ay 24 11 6 4 (C '#f6f1e4'); QR $b $ax $ay 23 10 8 1 (C '#d6403a'); QR $b $ax $ay 24 9 6 1 (C '#d6403a'); QR $b $ax $ay 26 8 2 1 (C '#9d2a2a'); Q $b $ax $ay 26 13 (C '#8a5a34'); Q $b $ax $ay 28 12 (C '#6fb5e6')
  foreach ($p in @(@(3, 17), @(13, 18), @(30, 17), @(18, 16))) { Q $b $ax $ay $p[0] $p[1] (C '#ffd36a') }

  # --- 絵 B: 花（濃い木の額縁＋マット）x54 y12 26x32 → 中身 16x22 @ (59,17)
  Rect $b ($ox + 54) 12 26 32 $ink; Rect $b ($ox + 55) 13 24 30 $wd3; Rect $b ($ox + 55) 13 24 1 $wd2; Rect $b ($ox + 55) 13 1 30 $wd2
  Rect $b ($ox + 57) 15 20 26 $cr1; Rect $b ($ox + 57) 15 20 1 $cr2; Rect $b ($ox + 57) 15 1 26 $cr2
  $bx = $ox + 59; $by = 17
  for ($y = 0; $y -lt 22; $y++) { Rect $b $bx ($by + $y) 16 1 (Mix (C '#3a7482') (C '#1f4650') ($y / 21.0)) }
  QR $b $bx $by 0 18 16 4 (C '#8a5a34'); QR $b $bx $by 0 18 16 1 (C '#b07c4c')
  # 花瓶
  Ellipse $b ($bx + 8) ($by + 15.5) 3.6 3.2 $bl; Ellipse $b ($bx + 7) ($by + 14.5) 1.2 1.2 $bl2; QR $b $bx $by 7 11 2 3 $bl; QR $b $bx $by 6 11 4 1 (C '#1f3f80'); QR $b $bx $by 5 18 6 1 (C '#1f3f80')
  # 茎と葉
  L $b ($bx + 8) ($by + 12) ($bx + 4) ($by + 6) $gr1; L $b ($bx + 8) ($by + 12) ($bx + 12) ($by + 5) $gr1; L $b ($bx + 8) ($by + 12) ($bx + 8) ($by + 9) $gr1
  Q $b $bx $by 6 10 $gr0; Q $b $bx $by 10 9 $gr0; Q $b $bx $by 5 11 $gr0
  # 花
  Ellipse $b ($bx + 4.5) ($by + 5) 2.9 2.9 (C '#f2c230'); Ellipse $b ($bx + 4.5) ($by + 5) 1.3 1.3 (C '#6a3a1a')
  Ellipse $b ($bx + 11.5) ($by + 4) 2.6 2.6 $pk; Ellipse $b ($bx + 11.5) ($by + 4) 1.0 1.0 $pk2
  Ellipse $b ($bx + 8.5) ($by + 7.5) 2.1 2.1 (C '#f6f3ee'); Q $b $bx $by 8 7 $yl

  # --- 絵 C: 夜の街（白い額縁）x88 y15 48x28 → 中身 40x20 @ (92,19)
  Rect $b ($ox + 88) 15 48 28 $ink; Rect $b ($ox + 89) 16 46 26 (C '#f4f1ea')
  Rect $b ($ox + 89) 16 46 1 $sv0; Rect $b ($ox + 89) 41 46 1 $sv1; Rect $b ($ox + 134) 16 1 26 $sv1
  Rect $b ($ox + 91) 18 42 22 $cr2
  $cx = $ox + 92; $cy = 19
  for ($y = 0; $y -lt 20; $y++) {
    $t = $y / 19.0
    $c = if ($t -lt 0.45) { Mix (C '#2f2a63') (C '#7a3f8c') ($t / 0.45) } elseif ($t -lt 0.8) { Mix (C '#7a3f8c') (C '#e0647a') (($t - 0.45) / 0.35) } else { Mix (C '#e0647a') (C '#f6a24e') (($t - 0.8) / 0.2) }
    Rect $b $cx ($cy + $y) 40 1 $c
  }
  foreach ($p in @(@(14, 2), @(22, 4), @(31, 1), @(36, 5), @(3, 6), @(27, 6))) { Q $b $cx $cy $p[0] $p[1] (C '#ffe9c8') }
  Ellipse $b ($cx + 7) ($cy + 5) 2.6 2.6 (C '#fff1c4'); Ellipse $b ($cx + 8) ($cy + 4.4) 2.0 2.0 (C '#b8508a'); Ellipse $b ($cx + 7) ($cy + 5) 2.1 2.1 (C '#fff1c4')
  $far = C '#4a3a78'; $near = C '#1c1a38'
  foreach ($bd in @(@(3, 6, 12), @(14, 5, 11), @(21, 6, 13), @(31, 5, 10))) { QR $b $cx $cy $bd[0] (20 - $bd[2]) $bd[1] $bd[2] $far }
  foreach ($bd in @(@(0, 6, 9), @(6, 5, 13), @(11, 7, 8), @(18, 6, 15), @(24, 5, 10), @(29, 6, 12), @(35, 5, 7))) {
    QR $b $cx $cy $bd[0] (20 - $bd[2]) $bd[1] $bd[2] $near
    for ($wy = 20 - $bd[2] + 2; $wy -lt 19; $wy += 3) { for ($wx = $bd[0] + 1; $wx -lt $bd[0] + $bd[1] - 1; $wx += 2) { if ((($wx * 7 + $wy * 3) % 5) -ne 0) { Q $b $cx $cy $wx $wy $yl } } }
  }
  QR $b $cx $cy 20 3 1 3 $near; Q $b $cx $cy 20 2 (C '#ff5a4a')

  # --- 絵 D: 海（黒い細い額縁）x142 y17 28x24 → 中身 22x18 @ (145,20)
  Rect $b ($ox + 142) 17 28 24 $ink; Rect $b ($ox + 143) 18 26 22 (C '#2a2a30'); Rect $b ($ox + 143) 18 26 1 $sv2; Rect $b ($ox + 143) 18 1 22 $sv2
  Rect $b ($ox + 144) 19 24 20 $sv1
  $dx0 = $ox + 145; $dy0 = 20
  for ($y = 0; $y -lt 8; $y++) { Rect $b $dx0 ($dy0 + $y) 22 1 (Mix (C '#a8d8ee') (C '#f6e9c8') ($y / 7.0)) }
  for ($y = 8; $y -lt 18; $y++) { Rect $b $dx0 ($dy0 + $y) 22 1 (Mix (C '#3aa0b8') (C '#1f6a86') (($y - 8) / 9.0)) }
  for ($y = 9; $y -lt 18; $y += 2) { for ($x = ($y % 4); $x -lt 22; $x += 5) { Rect $b ($dx0 + $x) ($dy0 + $y) 2 1 (C '#d8f4fa') } }
  Ellipse $b ($dx0 + 19) ($dy0 + 7.5) 3.4 1.8 (C '#3a7a5a')
  QR $b $dx0 $dy0 9 11 7 2 $rd; QR $b $dx0 $dy0 10 13 5 1 (C '#8a2a2a'); QR $b $dx0 $dy0 12 3 1 8 $wd3
  for ($i = 0; $i -lt 7; $i++) { QR $b $dx0 $dy0 (13 + [int]($i / 1.2)) (4 + $i) 1 1 $sv0; if ($i -gt 0) { QR $b $dx0 $dy0 13 (4 + $i) ([int]($i / 1.2)) 1 $sv0 } }
  for ($i = 0; $i -lt 5; $i++) { QR $b $dx0 $dy0 (11 - [int]($i / 1.3)) (6 + $i) ([int]($i / 1.3) + 1) 1 (C '#f6f3ee') }
  foreach ($p in @(@(4, 3), @(5, 2), @(6, 3), @(8, 4), @(9, 3))) { Q $b $dx0 $dy0 $p[0] $p[1] (C '#fbfbfb') }

  # プレート
  foreach ($p in @(@(23, 45), @(61, 46), @(108, 45), @(152, 43))) { Rect $b ($ox + $p[0]) $p[1] 8 2 $gl1; Rect $b ($ox + $p[0]) $p[1] 8 1 $gl0; Rect $b ($ox + $p[0] + 2) ($p[1] + 1) 4 1 $wd4 }
  # スポットライト（トラックに4つ）
  foreach ($lx in 26, 66, 111, 155) {
    Rect $b ($ox + $lx - 1) 6 3 1 $sv3
    Rect $b ($ox + $lx - 3) 7 7 3 $ink; Rect $b ($ox + $lx - 2) 7 5 1 $sv2; Rect $b ($ox + $lx - 2) 9 5 1 $yw
    Px $b ($ox + $lx - 3) 9 $clear; Px $b ($ox + $lx + 3) 9 $clear
  }
}

# ====================================================================
# 壁の光 176x38: スポットライトの円すい形の光。4コマでゆらぐ（photoart_glow）
Sheet 'photoart_glow.png' 176 38 4 {
  param($b, $ox, $f)
  $mul = @(1.0, 1.18, 1.0, 0.84)[$f]
  $cones = @(@(26, 25), @(66, 17), @(111, 28), @(155, 17))
  foreach ($cn in $cones) {
    $cx = $cn[0]; $hwB = $cn[1]
    for ($y = 0; $y -lt 38; $y++) {
      $t = $y / 37.0
      $hw = 2 + ($hwB - 2) * $t
      $a0 = (100 - 68 * $t) * $mul
      for ($x = [int]($cx - $hw - 1); $x -le [int]($cx + $hw + 1); $x++) {
        if ($x -lt 0 -or $x -ge 176) { continue }
        $d = [math]::Abs($x - $cx) / $hw
        if ($d -gt 1) { continue }
        $a = [int]($a0 * (1.0 - 0.7 * $d * $d))
        if ($a -lt 4) { continue }
        # 下半分は市松で粗く（ドット絵らしく）
        if ($t -gt 0.55 -and ((($x + $y) % 2) -eq 0) -and $a -lt 22) { continue }
        Px $b ($ox + $x) $y (CA '#fff1b8' $a)
      }
    }
    Px $b ($ox + $cx) 1 (CA '#ffffff' 200); Px $b ($ox + $cx - 1) 1 (CA '#fff6cf' 120); Px $b ($ox + $cx + 1) 1 (CA '#fff6cf' 120)
  }
}

# ====================================================================
# 看板 128x26: 「写真美術部」。カメラとパレットのアイコン。電球が流れる 4コマ
Sheet 'photoart_sign.png' 128 26 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 128 26 $ink
  Rect $b ($ox + 1) 1 126 24 $gl1
  Rect $b ($ox + 1) 1 126 1 $gl0; Rect $b ($ox + 1) 24 126 1 $gl2
  Rect $b ($ox + 3) 3 122 20 $navy1
  Rect $b ($ox + 3) 3 122 1 $navy0; Rect $b ($ox + 3) 22 122 1 $navy2
  # 電球
  for ($i = 0; $i -lt 21; $i++) {
    $x = 4 + $i * 6
    $lit = ((($i + $f) % 3) -eq 0)
    $c = if ($lit) { $yw } else { C '#c98a28' }
    Rect $b ($ox + $x) 1 2 2 $c; Rect $b ($ox + $x) 23 2 2 $c
    if ($lit) { Px $b ($ox + $x - 1) 1 $gl0; Px $b ($ox + $x + 2) 1 $gl0; Px $b ($ox + $x - 1) 24 $gl0; Px $b ($ox + $x + 2) 24 $gl0 }
  }
  foreach ($y in 7, 13, 19) { $lit = ((($y / 6 + $f) % 3) -eq 0); $c = if ($lit) { $yw } else { C '#c98a28' }; Rect $b ($ox + 1) $y 2 2 $c; Rect $b ($ox + 125) $y 2 2 $c }
  # 文字: 影 → クリーム
  [void](TextPx $b '写真美術部' ($ox + 24) 6 16 $navy2 $true)
  [void](TextPx $b '写真美術部' ($ox + 23) 5 16 $cr0 $true)
  # カメラのアイコン
  Rect $b ($ox + 7) 10 15 10 $ink; Rect $b ($ox + 8) 11 13 8 $sv1; Rect $b ($ox + 8) 11 13 1 $sv0
  Rect $b ($ox + 10) 8 5 3 $ink; Rect $b ($ox + 11) 9 3 2 $sv1
  Ellipse $b ($ox + 14.5) 15 3.6 3.6 $ink; Ellipse $b ($ox + 14.5) 15 2.6 2.6 (C '#4a7ec8'); Px $b ($ox + 13) 14 $sv0
  Px $b ($ox + 19) 12 $(if ($f -eq 0) { $yw } else { $rd })
  # パレットのアイコン
  Ellipse $b ($ox + 114.5) 13.5 7.8 6.2 $ink; Ellipse $b ($ox + 114.5) 13.5 6.8 5.2 $wd1
  Ellipse $b ($ox + 114.5) 12.8 6.4 4.4 $wd0
  Ellipse $b ($ox + 118.5) 16 1.5 1.3 $ink
  Rect $b ($ox + 109) 10 2 2 $rd; Rect $b ($ox + 112) 8 2 2 $yl; Rect $b ($ox + 116) 8 2 2 $bl; Rect $b ($ox + 119) 10 2 2 $gr1; Rect $b ($ox + 109) 14 2 2 $pk
  foreach ($p in @(@(0, 0), @(127, 0), @(0, 25), @(127, 25))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ====================================================================
# イーゼル 30x42: H型の木のイーゼルに描きかけのキャンバス（左は塗れていて、右はえんぴつの下書き）
Sheet 'photoart_easel.png' 30 42 1 {
  param($b, $ox, $f)
  # 足（後ろの足と前の足）
  L $b ($ox + 4) 31 ($ox + 1) 41 $wd3; L $b ($ox + 5) 31 ($ox + 2) 41 $wd2
  L $b ($ox + 25) 31 ($ox + 28) 41 $wd3; L $b ($ox + 24) 31 ($ox + 27) 41 $wd2
  L $b ($ox + 15) 31 ($ox + 15) 41 $wd4; L $b ($ox + 16) 31 ($ox + 16) 41 $wd3
  # たて柱・上の横木・棚
  Rect $b ($ox + 3) 3 3 29 $ink; Rect $b ($ox + 4) 3 1 29 $wd1; Rect $b ($ox + 5) 3 1 29 $wd3
  Rect $b ($ox + 24) 3 3 29 $ink; Rect $b ($ox + 25) 3 1 29 $wd1; Rect $b ($ox + 26) 3 1 29 $wd3
  Rect $b ($ox + 3) 2 24 4 $ink; Rect $b ($ox + 3) 3 24 2 $wd1; Rect $b ($ox + 3) 3 24 1 $wd0
  Rect $b ($ox + 2) 29 26 3 $ink; Rect $b ($ox + 3) 30 24 1 $wd1; Rect $b ($ox + 3) 29 24 1 $wd0
  # キャンバス 18x22 @ (6,7)
  Rect $b ($ox + 5) 6 20 23 $ink
  Rect $b ($ox + 6) 7 18 22 (C '#f8f4e8')
  Rect $b ($ox + 24) 7 1 22 $cr2
  for ($y = 0; $y -lt 22; $y++) {
    $edge = 10 + [int][math]::Round(2.2 * [math]::Sin($y * 0.7) + 0.08 * $y)
    for ($x = 0; $x -lt 18; $x++) {
      if ($x -le $edge) {
        $mt = 6 + [int][math]::Round([math]::Abs($x - 5) * 1.6)
        if ($y -lt 11) { $c = Mix (C '#69b2e4') (C '#c4e4f2') ($y / 10.0) }
        else { $c = if ($y -lt 14) { C '#86cc68' } elseif ($y -lt 18) { C '#53a859' } else { C '#3c8a4c' } }
        if ($y -lt 14 -and $y -ge $mt -and [math]::Abs($x - 5) -lt 5) { $c = if ($y -le $mt + 1) { C '#e8f0fa' } else { C '#8aa0c8' } }
        Px $b ($ox + 6 + $x) (7 + $y) $c
      }
    }
  }
  # 絵の中: 太陽・木
  Ellipse $b ($ox + 13.5) 11.5 2.2 2.2 $yw
  QR $b ($ox + 6) 7 2 14 2 5 (C '#6a4426'); Ellipse $b ($ox + 9) 19.5 3 2.6 (C '#2f7a48'); Ellipse $b ($ox + 8) 18.6 1.3 1.1 (C '#56ad5a')
  # 右: えんぴつの下書き
  $pen = C '#9a9488'
  L $b ($ox + 18) 22 ($ox + 23) 19 $pen; L $b ($ox + 19) 17 ($ox + 23) 16 $pen
  Ellipse $b ($ox + 21) 11 2.2 2.2 (C '#f8f4e8'); Frame $b ($ox + 19) 9 5 5 $pen; Px $b ($ox + 19) 9 (C '#f8f4e8'); Px $b ($ox + 23) 9 (C '#f8f4e8'); Px $b ($ox + 19) 13 (C '#f8f4e8'); Px $b ($ox + 23) 13 (C '#f8f4e8')
  Rect $b ($ox + 20) 24 3 2 (CA '#e8721a' 255); Rect $b ($ox + 18) 26 2 2 (C '#e8c570')
  # 筆（棚の上）
  Rect $b ($ox + 6) 28 9 1 $wd3; Rect $b ($ox + 13) 28 3 1 $sv1; Rect $b ($ox + 16) 27 2 2 $bl; Px $b ($ox + 17) 27 $bl2
  Rect $b ($ox + 20) 27 3 2 $rd
  Clear $b $ox 41
}

# ====================================================================
# 三脚つきカメラ 30x44（フラッシュがたまに光る）8コマ。レンズは右向き
Sheet 'photoart_tripod.png' 30 44 8 {
  param($b, $ox, $f)
  # 脚
  L $b ($ox + 11) 25 ($ox + 3) 43 $ink; L $b ($ox + 12) 25 ($ox + 4) 43 $sv2
  L $b ($ox + 11) 25 ($ox + 19) 43 $ink; L $b ($ox + 12) 25 ($ox + 20) 43 $sv3
  L $b ($ox + 11) 25 ($ox + 14) 42 $ink2; L $b ($ox + 12) 25 ($ox + 15) 42 $ink2
  Rect $b ($ox + 2) 43 3 1 $ink; Rect $b ($ox + 18) 43 3 1 $ink; Rect $b ($ox + 13) 42 3 1 $ink
  Rect $b ($ox + 8) 22 7 3 $ink; Rect $b ($ox + 9) 22 5 1 $sv2; Px $b ($ox + 11) 24 $sv1
  # ストラップ
  L $b ($ox + 3) 14 ($ox + 1) 21 $rd; L $b ($ox + 1) 21 ($ox + 3) 26 $rd; L $b ($ox + 2) 14 ($ox + 0) 21 $rd
  # ボディ
  Rect $b ($ox + 3) 11 16 11 $ink; Rect $b ($ox + 4) 12 14 9 $ink2
  Rect $b ($ox + 4) 12 14 3 $sv1; Rect $b ($ox + 4) 12 14 1 $sv0
  Rect $b ($ox + 8) 8 6 4 $ink; Rect $b ($ox + 9) 9 4 3 $sv1; Px $b ($ox + 9) 9 $sv0
  Rect $b ($ox + 4) 16 3 5 $sv3; Px $b ($ox + 4) 16 $sv2
  Rect $b ($ox + 15) 10 2 2 $ink; Px $b ($ox + 15) 10 $rd
  Px $b ($ox + 16) 13 $(if ($f -eq 6 -or $f -eq 2) { C '#ff4a4a' } else { C '#7a1a1a' })
  Rect $b ($ox + 12) 14 4 1 $sv2
  # レンズ
  Rect $b ($ox + 19) 13 8 8 $ink; Rect $b ($ox + 19) 14 7 6 $sv3
  Rect $b ($ox + 21) 14 1 6 $sv2
  $glass = if ($f -ge 6) { C '#e8f6ff' } else { C '#2a4a7a' }
  Rect $b ($ox + 24) 15 2 4 $glass; Px $b ($ox + 25) 15 $(if ($f -ge 6) { $sv0 } else { C '#79a6f0' })
  Rect $b ($ox + 26) 12 1 10 $ink
  # フラッシュ（6,7コマ目）
  $fy = C '#fff1a0'
  if ($f -eq 6) {
    $fc = C '#ffffff'
    Rect $b ($ox + 26) 15 3 4 $fc
    foreach ($d in @(@(27, 13, 29, 11), @(27, 20, 29, 22), @(28, 17, 29, 17), @(26, 12, 27, 9), @(26, 21, 27, 24))) { L $b ($ox + $d[0]) $d[1] ($ox + $d[2]) $d[3] $fy }
    Px $b ($ox + 29) 15 $fc; Px $b ($ox + 29) 18 $fc
  }
  if ($f -eq 7) { Px $b ($ox + 27) 16 $fy; Px $b ($ox + 27) 17 (C '#fff1a0'); Px $b ($ox + 28) 17 (CA '#ffffff' 170) }
}

# ====================================================================
# 台座と花瓶 22x44（ひまわりと花のブーケ。台座に名札）
Sheet 'photoart_pedestal.png' 22 44 1 {
  param($b, $ox, $f)
  # 台座
  Rect $b ($ox + 3) 19 17 4 $ink; Rect $b ($ox + 4) 20 15 2 $sv0; Rect $b ($ox + 4) 22 15 1 $sv1
  Rect $b ($ox + 5) 23 13 20 $ink; Rect $b ($ox + 6) 23 11 20 $cr0
  Rect $b ($ox + 6) 23 3 20 $sv0; Rect $b ($ox + 14) 23 3 20 $cr1; Rect $b ($ox + 16) 23 1 20 $cr2
  Rect $b ($ox + 4) 42 15 2 $ink; Rect $b ($ox + 5) 42 13 1 $cr1
  Rect $b ($ox + 7) 33 7 3 $gl1; Rect $b ($ox + 7) 33 7 1 $gl0; Rect $b ($ox + 8) 35 4 1 $wd4
  # 花瓶
  Ellipse $b ($ox + 11) 15.3 3.8 3.9 $ink; Ellipse $b ($ox + 11) 15.3 3.0 3.1 $bl
  Rect $b ($ox + 10) 10 3 4 $ink; Rect $b ($ox + 10) 11 2 3 $bl; Px $b ($ox + 9) 15 $bl2; Px $b ($ox + 9) 14 $bl2; Px $b ($ox + 10) 13 $bl2
  Rect $b ($ox + 8) 18 6 1 $ink
  # 茎・葉
  L $b ($ox + 11) 10 ($ox + 6) 5 $gr2; L $b ($ox + 11) 10 ($ox + 16) 3 $gr2; L $b ($ox + 11) 10 ($ox + 11) 4 $gr2
  Px $b ($ox + 9) 8 $gr0; Px $b ($ox + 8) 8 $gr1; Px $b ($ox + 13) 7 $gr0; Px $b ($ox + 14) 7 $gr1
  # 花（ひまわり・ピンク・白）
  Ellipse $b ($ox + 6) 4 4.0 4.0 (C '#f2c230'); Ellipse $b ($ox + 6) 4 2.0 2.0 (C '#6a3a1a'); Px $b ($ox + 5) 3 (C '#a8741c')
  foreach ($p in @(@(1, 3), @(4, 0), @(9, 3), @(7, 7), @(2, 6))) { Px $b ($ox + $p[0]) $p[1] (C '#ffe27a') }
  Ellipse $b ($ox + 16) 2.5 3.0 2.7 $pk; Ellipse $b ($ox + 16) 2.5 1.2 1.2 $pk2
  Ellipse $b ($ox + 11) 3 2.8 2.6 (C '#f6f3ee'); Ellipse $b ($ox + 11) 3 1.0 1.0 $yl; Px $b ($ox + 9) 2 $sv1
  Clear $b $ox 0
}

# ====================================================================
# スポットライト 16x56（三脚に乗った撮影用ライト。ヘッドは左向き）
Sheet 'photoart_lamp.png' 16 56 1 {
  param($b, $ox, $f)
  # 三脚
  L $b ($ox + 8) 34 ($ox + 2) 55 $ink; L $b ($ox + 9) 34 ($ox + 3) 55 $sv3
  L $b ($ox + 8) 34 ($ox + 14) 55 $ink; L $b ($ox + 7) 34 ($ox + 13) 55 $sv3
  L $b ($ox + 8) 34 ($ox + 8) 55 $ink2
  Rect $b ($ox + 1) 55 3 1 $ink; Rect $b ($ox + 12) 55 3 1 $ink; Rect $b ($ox + 7) 55 3 1 $ink
  # ポール
  Rect $b ($ox + 7) 12 3 24 $ink; Rect $b ($ox + 8) 12 1 24 $sv1; Rect $b ($ox + 9) 12 1 24 $sv3
  Rect $b ($ox + 6) 28 5 2 $ink; Rect $b ($ox + 7) 28 3 1 $sv2
  # ヘッド（左向き）
  Rect $b ($ox + 2) 4 10 9 $ink; Rect $b ($ox + 3) 5 8 7 $sv3; Rect $b ($ox + 3) 5 8 1 $sv2; Rect $b ($ox + 5) 6 1 5 $ink2
  Rect $b ($ox + 1) 5 2 7 $yw; Rect $b ($ox + 1) 5 1 7 $ink
  Rect $b ($ox + 0) 3 2 1 $ink; Rect $b ($ox + 0) 13 2 1 $ink
  Rect $b ($ox + 12) 6 3 5 $ink; Rect $b ($ox + 12) 7 2 3 $sv3
  Px $b ($ox + 10) 7 $rd
  Clear $b ($ox + 0) 4
}

# ====================================================================
# スポットライトの光 36x32（ヘッドから左へ広がる円すい。4コマでゆらぐ）。名前に glow を含めて夕方も明るく
Sheet 'photoart_spot_glow.png' 36 32 4 {
  param($b, $ox, $f)
  $mul = @(1.0, 1.2, 1.0, 0.82)[$f]
  $hx = 35; $hy = 16
  for ($x = 0; $x -lt 36; $x++) {
    $t = ($hx - $x) / 35.0
    $hw = 1.5 + 14.0 * $t
    $a0 = (175 - 145 * $t) * $mul
    for ($y = [int]($hy - $hw - 1); $y -le [int]($hy + $hw + 1); $y++) {
      if ($y -lt 0 -or $y -ge 32) { continue }
      $d = [math]::Abs($y - $hy) / $hw
      if ($d -gt 1) { continue }
      $a = [int]($a0 * (1.0 - 0.75 * $d * $d))
      if ($a -lt 4) { continue }
      if ($t -gt 0.5 -and ((($x + $y) % 2) -eq 0) -and $a -lt 26) { continue }
      Px $b ($ox + $x) $y (CA '#fff1b8' $a)
    }
  }
  Px $b ($ox + 34) 16 (CA '#ffffff' 230); Px $b ($ox + 33) 16 (CA '#fff6cf' 160); Px $b ($ox + 34) 15 (CA '#fff6cf' 120); Px $b ($ox + 34) 17 (CA '#fff6cf' 120)
}

# ====================================================================
# ポラロイドを吊るしたワイヤー 104x24（豆電球がまたたき、写真がゆれる）4コマ。両端は小さな柱
function Pol($b, $x0, $y0, $kind) {
  Rect $b $x0 $y0 12 14 (C '#bdb6a2')
  Rect $b $x0 $y0 12 13 (C '#fbf9f1')
  $ix = $x0 + 1; $iy = $y0 + 1   # 絵 10x9
  switch ($kind) {
    0 { Rect $b $ix $iy 10 9 (C '#8ecdf0'); Rect $b $ix ($iy + 6) 10 3 (C '#56ad5a'); Rect $b $ix ($iy + 6) 10 1 (C '#8ad06a'); Rect $b ($ix + 7) ($iy + 1) 2 2 (C '#ffe27a'); Rect $b ($ix + 2) ($iy + 3) 1 3 (C '#6a4426'); Rect $b ($ix + 1) ($iy + 2) 3 2 (C '#2f7a48') }
    1 { Rect $b $ix $iy 10 9 (C '#f7d6e0'); L $b ($ix + 5) ($iy + 8) ($ix + 5) ($iy + 5) $gr1; Px $b ($ix + 4) ($iy + 7) $gr0; Px $b ($ix + 6) ($iy + 6) $gr0; Ellipse $b ($ix + 5) ($iy + 3.5) 2.6 2.4 $pk; Rect $b ($ix + 4) ($iy + 3) 2 1 $yl }
    2 { Rect $b $ix $iy 10 9 (C '#f0a860'); Rect $b $ix ($iy + 4) 3 5 (C '#3a3050'); Rect $b ($ix + 3) ($iy + 2) 3 7 (C '#2a2240'); Rect $b ($ix + 6) ($iy + 5) 4 4 (C '#3a3050'); Px $b ($ix + 4) ($iy + 4) $yl; Px $b ($ix + 4) ($iy + 6) $yl; Px $b ($ix + 8) ($iy + 7) $yl; Px $b ($ix + 1) ($iy + 6) $yl; Px $b ($ix + 7) ($iy + 1) $yw }
    3 { Rect $b $ix $iy 10 9 (C '#bfe5f4'); Rect $b $ix ($iy + 5) 10 4 (C '#2f8aa6'); Rect $b ($ix + 4) ($iy + 5) 3 1 $rd; Rect $b ($ix + 5) ($iy + 1) 1 4 $wd3; Rect $b ($ix + 6) ($iy + 2) 2 3 (C '#f6f3ee'); Px $b ($ix + 1) ($iy + 7) (C '#d8f4fa'); Px $b ($ix + 8) ($iy + 8) (C '#d8f4fa') }
    4 { Rect $b $ix $iy 10 9 (C '#cfe6c0'); Ellipse $b ($ix + 5) ($iy + 5.3) 3.5 2.9 (C '#e8943a'); Px $b ($ix + 2) ($iy + 2) (C '#e8943a'); Px $b ($ix + 2) ($iy + 3) (C '#e8943a'); Px $b ($ix + 8) ($iy + 2) (C '#e8943a'); Px $b ($ix + 8) ($iy + 3) (C '#e8943a'); Px $b ($ix + 3) ($iy + 5) $ink; Px $b ($ix + 7) ($iy + 5) $ink; Px $b ($ix + 5) ($iy + 6) $pk2; Rect $b ($ix + 4) ($iy + 7) 3 1 (C '#f6e0b0') }
    5 { Rect $b $ix $iy 10 9 (C '#1e2a5a'); Rect $b $ix ($iy + 7) 10 2 (C '#0e1530'); Px $b ($ix + 2) ($iy + 1) $sv0; Px $b ($ix + 5) ($iy + 3) $sv0; Px $b ($ix + 8) ($iy + 5) $sv0; Px $b ($ix + 3) ($iy + 5) (C '#ffe9c8'); Rect $b ($ix + 7) ($iy + 1) 2 2 (C '#fff1c4'); Px $b ($ix + 8) $iy (C '#1e2a5a'); Rect $b ($ix + 5) ($iy + 6) 1 2 (C '#0e1530'); Rect $b ($ix + 4) ($iy + 5) 3 2 (C '#0e1530') }
  }
  Rect $b ($x0 + 2) ($y0 + 11) 5 1 (C '#b0a99a')
  Px $b ($x0 + 8) ($y0 + 11) (C '#d6a0a8')
}
Sheet 'photoart_hang.png' 104 24 4 {
  param($b, $ox, $f)
  # 柱
  foreach ($px in 2, 99) {
    Rect $b ($ox + $px) 0 3 24 $ink; Rect $b ($ox + $px + 1) 1 1 23 $wd1; Rect $b ($ox + $px) 0 3 1 $wd0
    Rect $b ($ox + $px - 1) 22 5 2 $ink; Rect $b ($ox + $px) 22 3 1 $wd2
  }
  # ワイヤー（ゆるくたるむ）
  for ($x = 4; $x -le 99; $x++) { $wy = 2 + [int][math]::Round(3.2 * [math]::Sin([math]::PI * ($x - 4) / 95.0)); Px $b ($ox + $x) $wy $sv3; Px $b ($ox + $x) ($wy - 1) $sv1 }
  # 豆電球
  $bc = @((C '#ffd36a'), (C '#ff8aa8'), (C '#8ae0ff'), (C '#b6f58a'))
  for ($i = 0; $i -lt 6; $i++) {
    $bx = 22 + $i * 15 - 7
    $wy = 2 + [int][math]::Round(3.2 * [math]::Sin([math]::PI * ($bx - 4) / 95.0))
    $lit = ((($i + $f) % 2) -eq 0)
    $c = $bc[$i % 4]
    Px $b ($ox + $bx) ($wy + 1) $ink
    if ($lit) { Rect $b ($ox + $bx - 1) ($wy + 2) 3 2 $c; Px $b ($ox + $bx) ($wy + 2) $yw; Px $b ($ox + $bx - 2) ($wy + 2) (CA '#fff1b8' 110); Px $b ($ox + $bx + 2) ($wy + 2) (CA '#fff1b8' 110); Px $b ($ox + $bx) ($wy + 4) (CA '#fff1b8' 110) }
    else { Rect $b ($ox + $bx - 1) ($wy + 2) 3 2 (Mix $c $ink 0.55) }
  }
  # ポラロイド6枚（ゆれる）
  for ($i = 0; $i -lt 6; $i++) {
    $cx = 14 + $i * 15.4
    $sway = [int][math]::Round(1.0 * [math]::Sin($f * [math]::PI / 2 + $i * 1.3))
    $wy = 2 + [int][math]::Round(3.2 * [math]::Sin([math]::PI * ($cx - 4) / 95.0))
    $x0 = [int][math]::Round($cx - 6 + $sway)
    $y0 = $wy + 3
    Pol $b ($ox + $x0) $y0 $i
    Rect $b ($ox + [int][math]::Round($cx) - 1) ($wy) 2 4 $wd2; Px $b ($ox + [int][math]::Round($cx) - 1) ($wy) $wd0; Px $b ($ox + [int][math]::Round($cx)) ($wy + 3) $wd3
  }
}

# ====================================================================
# パレットと筆の台 24x22（木のパレット、絵の具、筆立て）
Sheet 'photoart_palette.png' 24 22 1 {
  param($b, $ox, $f)
  # 台
  Rect $b ($ox + 1) 8 22 3 $ink; Rect $b ($ox + 1) 8 22 2 $wd1; Rect $b ($ox + 1) 8 22 1 $wd0
  Rect $b ($ox + 2) 11 20 3 $wd2; Rect $b ($ox + 2) 11 20 1 $wd3
  foreach ($lx in 2, 19) { Rect $b ($ox + $lx) 14 3 8 $ink; Rect $b ($ox + $lx + 1) 14 1 7 $wd1; Rect $b ($ox + $lx + 2) 14 1 7 $wd3 }
  # パレット（上から見た形）
  Ellipse $b ($ox + 9) 6.2 7.0 3.0 $ink; Ellipse $b ($ox + 9) 6.0 6.2 2.4 $wd0
  Ellipse $b ($ox + 13) 6.8 1.2 0.8 $ink
  foreach ($d in @(@(4, 4, $rd), @(6, 3, $yl), @(9, 3, $bl), @(12, 4, $gr1), @(3, 6, $pk))) { Px $b ($ox + $d[0]) $d[1] $d[2]; Px $b ($ox + $d[0] + 1) $d[1] $d[2] }
  Px $b ($ox + 7) 6 $wd1; Px $b ($ox + 8) 7 $wd1
  # 絵の具のチューブ
  Rect $b ($ox + 2) 7 5 2 $ink
  # 筆立て（ガラスの瓶に筆）
  Rect $b ($ox + 16) 3 5 6 (CA '#d8f0ff' 190); Rect $b ($ox + 16) 3 1 6 $sv2; Rect $b ($ox + 20) 3 1 6 $sv2; Rect $b ($ox + 16) 8 5 1 $sv2
  Rect $b ($ox + 17) 6 3 2 (C '#7ad0e8')
  L $b ($ox + 17) 6 ($ox + 16) 0 $wd2; L $b ($ox + 18) 6 ($ox + 18) 0 $wd3; L $b ($ox + 19) 6 ($ox + 20) 1 $wd2
  Px $b ($ox + 16) 0 $rd; Px $b ($ox + 18) 0 $bl; Px $b ($ox + 20) 1 $yl
  Clear $b $ox 21
}

# ====================================================================
# 立てかけた額縁とキャンバス 26x24
Sheet 'photoart_frames.png' 26 24 1 {
  param($b, $ox, $f)
  # 奥: 裏向きのキャンバス（木枠が見える）
  Rect $b ($ox + 10) 1 13 22 $ink; Rect $b ($ox + 11) 2 11 20 $cr2
  Rect $b ($ox + 11) 2 11 1 $wd1; Rect $b ($ox + 11) 21 11 1 $wd1; Rect $b ($ox + 11) 2 1 20 $wd1; Rect $b ($ox + 21) 2 1 20 $wd1
  L $b ($ox + 12) 3 ($ox + 20) 20 $wd2
  # 左: 白いキャンバス
  Rect $b ($ox + 1) 4 10 19 $ink; Rect $b ($ox + 2) 5 8 17 (C '#f8f4e8'); Rect $b ($ox + 10) 5 1 17 $cr2
  Rect $b ($ox + 3) 7 4 3 (C '#e8c570'); Rect $b ($ox + 5) 9 3 2 (C '#69b2e4')
  # 手前: 額に入った絵（抽象）
  Rect $b ($ox + 6) 9 16 15 $ink; Rect $b ($ox + 7) 10 14 13 $gl1; Rect $b ($ox + 7) 10 14 1 $gl0; Rect $b ($ox + 7) 22 14 1 $gl2
  Rect $b ($ox + 9) 12 10 9 (C '#f06a50')
  Rect $b ($ox + 9) 17 10 4 (C '#2f5fb8'); Rect $b ($ox + 13) 12 6 3 (C '#ffd36a'); Rect $b ($ox + 9) 15 4 2 (C '#56ad5a')
  Px $b ($ox + 17) 18 $sv0; Px $b ($ox + 11) 13 $yw
  Clear $b $ox 23
}
