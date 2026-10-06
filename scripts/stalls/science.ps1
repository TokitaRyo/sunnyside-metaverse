# 科学部（ロボット展示）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/science.ps1
# 出力: client/public/brand/stall/science_*.png （配置は scripts/stalls/science.mjs）
# 配色: 金属グレー・水色（シアン）・オレンジ・白のサイエンスブルー。
# アニメは「フレームを横一列に並べたPNG」で、science.mjs の k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  # 確認用: 環境変数 SCI_ONLY（正規表現）に合う絵だけ作り直す（例: $env:SCI_ONLY='sign|panel'）
  if ($env:SCI_ONLY -and ($name -notmatch $env:SCI_ONLY)) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}
function P($b, $x, $y, $col) { Px $b ([int][math]::Round($x)) ([int][math]::Round($y)) $col }

# ---- 色 ----
# 金属（暗→明）
$k0 = C '#111a2a'; $k1 = C '#232f48'; $k2 = C '#3a4c6c'; $k3 = C '#5f77a0'; $k4 = C '#9db4d0'; $k5 = C '#d6e3f2'; $wh = C '#f7fbff'
# 水色（光）
$cy0 = C '#0a5f7a'; $cy1 = C '#17b3d6'; $cy2 = C '#4fe3ff'; $cy3 = C '#b6f7ff'
# オレンジ
$or0 = C '#8a3a0c'; $or1 = C '#e8721a'; $or2 = C '#ffa43a'; $or3 = C '#ffd27a'
# 実験液（緑）
$gr0 = C '#1d7a3c'; $gr1 = C '#3fd860'; $gr2 = C '#b2ffc4'
# 壁・床
$wl0 = C '#8fb0cc'; $wl1 = C '#b9d2e6'; $wl2 = C '#dbeaf5'; $wl3 = C '#6b8cab'
$fl0 = C '#c1d3e2'; $fl1 = C '#dfeaf4'; $fl2 = C '#d0dfec'
$bp0 = C '#1a4a96'; $bp1 = C '#2a68c4'; $bpl = C '#bfe0ff'

# ---- 描画の道具 ----
# 太さのある線（縁取りつき）
function Limb($b, $x0, $y0, $x1, $y1, $th, $line, $fill) {
  $n = [int][math]::Ceiling([math]::Max(1.0, [math]::Max([math]::Abs($x1 - $x0), [math]::Abs($y1 - $y0)) * 2.0))
  $h = [int][math]::Floor($th / 2.0)
  for ($pass = 0; $pass -lt 2; $pass++) {
    for ($i = 0; $i -le $n; $i++) {
      $t = $i / [double]$n
      $x = [int][math]::Round($x0 + ($x1 - $x0) * $t); $y = [int][math]::Round($y0 + ($y1 - $y0) * $t)
      if ($pass -eq 0) { Rect $b ($x - $h - 1) ($y - $h - 1) ($th + 2) ($th + 2) $line } else { Rect $b ($x - $h) ($y - $h) $th $th $fill }
    }
  }
}
# 歯車。ro=歯の先の半径, ri=歯の根元の半径, n=歯の数, ang=回転(度)。縁は線色、左上にハイライト、真ん中に穴
function Gear($b, $cx, $cy, $ro, $ri, $n, $ang, $fill, $hi, $line, $hole, $holeR) {
  $x0 = [int][math]::Floor($cx - $ro - 1); $y0 = [int][math]::Floor($cy - $ro - 1)
  $W = [int][math]::Ceiling($ro * 2 + 3); $H = $W
  $m = New-Object 'bool[,]' $W, $H
  $per = 360.0 / $n
  for ($j = 0; $j -lt $H; $j++) {
    for ($i = 0; $i -lt $W; $i++) {
      $dx = $x0 + $i + 0.5 - $cx; $dy = $y0 + $j + 0.5 - $cy
      $r = [math]::Sqrt($dx * $dx + $dy * $dy)
      if ($r -le $ri) { $m[$i, $j] = $true }
      elseif ($r -le $ro) {
        $th = [math]::Atan2($dy, $dx) * 180.0 / [math]::PI - $ang
        $fr = (($th % $per) + $per) % $per
        if ($fr -lt $per * 0.27 -or $fr -gt $per * 0.73) { $m[$i, $j] = $true }
      }
    }
  }
  for ($j = 0; $j -lt $H; $j++) {
    for ($i = 0; $i -lt $W; $i++) {
      if (-not $m[$i, $j]) { continue }
      $edge = $false
      foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $ni = $i + $d[0]; $nj = $j + $d[1]
        if ($ni -lt 0 -or $nj -lt 0 -or $ni -ge $W -or $nj -ge $H -or -not $m[$ni, $nj]) { $edge = $true }
      }
      $dx = $x0 + $i + 0.5 - $cx; $dy = $y0 + $j + 0.5 - $cy
      $r = [math]::Sqrt($dx * $dx + $dy * $dy)
      if ($edge) { $col = $line }
      elseif ($r -le $holeR) { $col = $hole }
      elseif ($dx + $dy -lt -$ri * 0.55) { $col = $hi }
      else { $col = $fill }
      Px $b ($x0 + $i) ($y0 + $j) $col
    }
  }
}

# ====================================================================
# 看板 136x38（上に「科学部」のオレンジの札、「ロボット展示」。両脇の歯車が回り、枠のLEDが流れる）4コマ
Sheet 'science_sign.png' 136 40 4 {
  param($b, $ox, $f)
  # 札
  Rect $b ($ox + 8) 0 44 16 $k0
  Rect $b ($ox + 9) 1 42 14 $or1
  Rect $b ($ox + 9) 1 42 1 $or3
  Rect $b ($ox + 9) 14 42 1 $or0
  [void](TextPx $b '科学部' ($ox + 12) 2 12 $k0 $false)
  Px $b ($ox + 10) 3 $or3; Px $b ($ox + 50) 3 $or3
  # 本体
  Rect $b $ox 14 136 26 $k0
  Rect $b ($ox + 1) 15 134 24 $cy1
  Rect $b ($ox + 2) 16 132 22 $k1
  Rect $b ($ox + 2) 16 132 1 $k2
  for ($x = 1; $x -lt 135; $x++) {
    $lit = ((($x + $f * 1) % 4) -eq 0)
    $c = if ($lit) { $cy3 } else { $cy1 }
    Px $b ($ox + $x) 15 $c; Px $b ($ox + $x) 38 $c
  }
  # 文字: 影 → 白
  [void](TextPx $b 'ロボット展示' ($ox + 21) 20 16 $k0 $true)
  [void](TextPx $b 'ロボット展示' ($ox + 20) 19 16 $wh $true)
  Rect $b ($ox + 20) 36 96 1 $or2
  # 歯車（左は時計回り・右は反対）
  Gear $b ($ox + 10.5) 27.5 7.5 5.2 8 ($f * 11.25) $or1 $or3 $k0 $k0 1.6
  Gear $b ($ox + 125.5) 27.5 7.5 5.2 8 (-$f * 11.25 + 22.5) $or1 $or3 $k0 $k0 1.6
  foreach ($p in @(@(0, 14), @(135, 14), @(0, 39), @(135, 39), @(8, 0), @(51, 0))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ====================================================================
# 床 176x66: 研究室のタイル。真ん中にシアンの案内線、手前に黄色い…ではなくオレンジの注意縞
Sheet 'science_floor.png' 176 66 1 {
  param($b, $ox, $f)
  for ($y = 0; $y -lt 66; $y++) {
    for ($x = 0; $x -lt 176; $x++) {
      $t = ((([int][math]::Floor($x / 11)) + ([int][math]::Floor($y / 11))) % 2) -eq 0
      Px $b ($ox + $x) $y $(if ($t) { $fl1 } else { $fl2 })
    }
  }
  for ($y = 0; $y -lt 66; $y += 11) { Rect $b $ox $y 176 1 $fl0 }
  for ($x = 0; $x -lt 176; $x += 11) { Rect $b ($ox + $x) 0 1 66 $fl0 }
  # 案内線（入口から舞台へ）
  for ($y = 2; $y -lt 56; $y += 6) { Rect $b ($ox + 87) $y 2 3 $cy1; Px $b ($ox + 87) $y $cy2 }
  # 縁: 手前にオレンジと黒の注意縞、左右に金属
  for ($x = 0; $x -lt 176; $x++) {
    $s = ((($x + 66) -shr 2) -band 1) -eq 0
    Px $b ($ox + $x) 62 $(if ($s) { $or1 } else { $k0 })
    Px $b ($ox + $x) 63 $(if ($s) { $or2 } else { $k1 })
  }
  Rect $b $ox 64 176 2 $k2; Rect $b $ox 65 176 1 $k0
  Rect $b $ox 0 2 62 $k3; Rect $b ($ox + 174) 0 2 62 $k3
  Rect $b $ox 0 1 62 $k4; Rect $b ($ox + 174) 0 1 62 $k4
  Rect $b $ox 0 176 1 $wl3
  foreach ($p in @(@(0, 0), @(175, 0), @(0, 65), @(175, 65))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ====================================================================
# 壁 172x44: 設計図ポスター・しくみのポスター・部品の棚・上の梁・足元の注意縞
$robotRows = @(
  '......XX......', '.....XXXX.....', '...XXXXXXXX...', '...X.X..X.X...', '...XXXXXXXX...', '.....XXXX.....', '..XXXXXXXXXX..',
  '.XX.X....X.XX.', 'XX..X.XX.X..XX', 'XX..X.XX.X..XX', 'XX..X....X..XX', '.X..XXXXXX..X.', '.X...X..X...X.', '.....X..X.....',
  '....XX..XX....', '....XX..XX....', '...XXX..XXX...')
Sheet 'science_wall.png' 172 44 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 172 44 $wl1
  for ($x = 43; $x -lt 172; $x += 43) { Rect $b ($ox + $x) 4 1 36 $wl0; Rect $b ($ox + $x + 1) 4 1 36 $wl2 }
  for ($y = 4; $y -lt 38; $y += 3) { for ($x = 0; $x -lt 172; $x += 6) { Px $b ($ox + $x + (($y / 3) % 2) * 3) $y $wl2 } }
  # 梁
  Rect $b $ox 0 172 4 $k2; Rect $b $ox 0 172 1 $k4; Rect $b $ox 3 172 1 $k1
  for ($x = 5; $x -lt 172; $x += 12) { Px $b ($ox + $x) 1 $k5; Px $b ($ox + $x) 2 $k1 }
  Rect $b $ox 4 172 1 $wl3
  # 足元の金属と注意縞
  Rect $b $ox 37 172 7 $k2; Rect $b $ox 37 172 1 $k4; Rect $b $ox 43 172 1 $k0
  for ($x = 0; $x -lt 172; $x++) { $s = ((($x + 38) -shr 2) -band 1) -eq 0; Px $b ($ox + $x) 40 $(if ($s) { $or1 } else { $k0 }); Px $b ($ox + $x) 41 $(if ($s) { $or2 } else { $k0 }) }
  # 設計図ポスター (4,7) 28x28
  Rect $b ($ox + 4) 7 28 28 $k0
  Rect $b ($ox + 5) 8 26 26 $bp0
  for ($i = 0; $i -lt 26; $i += 4) { Rect $b ($ox + 5) (8 + $i) 26 1 $bp1; Rect $b ($ox + 5 + $i) 8 1 26 $bp1 }
  Ascii $b ($ox + 12) 11 $robotRows @{ X = $bpl }
  Px $b ($ox + 15) 14 $wh; Px $b ($ox + 18) 14 $wh
  Line $b ($ox + 8) 12 ($ox + 8) 31 $bpl; Line $b ($ox + 7) 12 ($ox + 9) 12 $bpl; Line $b ($ox + 7) 31 ($ox + 9) 31 $bpl
  Rect $b ($ox + 26) 29 3 3 $or2
  foreach ($p in @(@(3, 6), @(30, 6), @(3, 34), @(30, 34))) { Rect $b ($ox + $p[0]) $p[1] 3 2 $k4 }
  # しくみポスター (138,5) 32x30
  Rect $b ($ox + 138) 5 32 30 $k0
  Rect $b ($ox + 139) 6 30 28 $wh
  Rect $b ($ox + 139) 6 30 1 $cy1; Rect $b ($ox + 139) 33 30 1 $cy1
  Rect $b ($ox + 139) 6 30 12 $cy3
  [void](TextPx $b 'しくみ' ($ox + 139) 7 10 $or0 $true)
  Rect $b ($ox + 139) 18 30 1 $cy1
  # 目 → チップ → 歯車
  Ellipse $b ($ox + 143.5) 25.5 3.6 2.6 $k0; Ellipse $b ($ox + 143.5) 25.5 2.7 1.8 $wh; Rect $b ($ox + 143) 25 2 2 $bp1; Px $b ($ox + 143) 25 $k0
  Line $b ($ox + 148) 26 ($ox + 150) 26 $or1; Px $b ($ox + 150) 25 $or1; Px $b ($ox + 150) 27 $or1
  Rect $b ($ox + 152) 22 7 7 $k0; Rect $b ($ox + 153) 23 5 5 $k2; Rect $b ($ox + 154) 24 3 3 $cy2
  foreach ($q in 153, 155, 157) { Px $b ($ox + $q) 21 $k4; Px $b ($ox + $q) 29 $k4 }
  foreach ($q in 23, 25, 27) { Px $b ($ox + 151) $q $k4; Px $b ($ox + 159) $q $k4 }
  Line $b ($ox + 160) 26 ($ox + 162) 26 $or1; Px $b ($ox + 162) 25 $or1; Px $b ($ox + 162) 27 $or1
  Gear $b ($ox + 166) 26 3.8 2.5 6 0 $or1 $or3 $k0 $k0 0.9
  Line $b ($ox + 143) 31 ($ox + 166) 31 $k4
  Rect $b ($ox + 137) 4 3 2 $k4; Rect $b ($ox + 168) 4 3 2 $k4
  # 部品の棚 (110,7) 24x30
  foreach ($py in 19, 33) { Rect $b ($ox + 110) $py 24 2 $k3; Rect $b ($ox + 110) $py 24 1 $k5; Rect $b ($ox + 110) ($py + 1) 24 1 $k1; Rect $b ($ox + 111) ($py + 2) 2 2 $k2; Rect $b ($ox + 131) ($py + 2) 2 2 $k2 }
  # 上段: 電球2個と基板
  foreach ($bx in 113, 120) {
    Ellipse $b ($ox + $bx + 2.5) 12.5 3 3.4 (C '#c8a64a')
    Ellipse $b ($ox + $bx + 2.5) 12.5 2.2 2.6 (C '#fff3b0')
    Px $b ($ox + $bx + 2) 12 $wh; Px $b ($ox + $bx + 3) 13 (C '#ffd24a')
    Rect $b ($ox + $bx + 1) 16 3 2 $k3; Px $b ($ox + $bx + 1) 17 $k1; Px $b ($ox + $bx + 3) 17 $k1
  }
  Px $b ($ox + 122) 12 $cy3; Px $b ($ox + 123) 11 $cy3
  Rect $b ($ox + 126) 13 8 5 (C '#1f7a45'); Frame $b ($ox + 126) 13 8 5 (C '#0f4a2a')
  Rect $b ($ox + 128) 14 3 2 $k0; foreach ($q in 127, 129, 131, 132) { Px $b ($ox + $q) 17 (C '#ffd24a') }; Px $b ($ox + 127) 14 $or2
  # 下段: ねじの瓶・歯車・チップ
  Rect $b ($ox + 112) 23 8 10 (C '#8aa4bd'); Rect $b ($ox + 113) 24 6 8 (C '#dff0ff'); Rect $b ($ox + 112) 22 8 2 $or1; Px $b ($ox + 112) 22 $or3
  foreach ($p in @(@(114, 29), @(116, 30), @(117, 28), @(115, 31), @(118, 30), @(114, 26), @(117, 26))) { Px $b ($ox + $p[0]) $p[1] $k3 }
  Gear $b ($ox + 125.5) 29 4 2.6 6 0 $or1 $or3 $k0 $k0 1.0
  Gear $b ($ox + 130.5) 30 3.4 2.2 6 25 $k4 $k5 $k0 $k0 0.8
}

# ====================================================================
# モニター 40x26（波形が流れる）6コマ
Sheet 'science_monitor.png' 40 26 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 40 24 $k0
  Rect $b ($ox + 1) 1 38 22 $k3
  Rect $b ($ox + 1) 1 38 1 $k5
  Rect $b ($ox + 2) 2 36 18 $k1
  Rect $b ($ox + 3) 3 34 16 (C '#06202b')
  for ($y = 3; $y -lt 19; $y += 5) { Rect $b ($ox + 3) $y 34 1 (C '#0e3a4a') }
  for ($x = 3; $x -lt 37; $x += 6) { Rect $b ($ox + $x) 3 1 16 (C '#0e3a4a') }
  Rect $b ($ox + 3) 11 34 1 (C '#145a70')
  $ph = $f * 2 * [math]::PI / 6
  for ($x = 0; $x -lt 34; $x++) {
    $y2 = 11 + [math]::Round(3 * [math]::Sin($x * 0.55 - $ph + 1.0))
    P $b ($ox + 3 + $x) $y2 (C '#ff9a3a')
    $y1 = 11 + [math]::Round(5 * [math]::Sin($x * 0.37 - $ph))
    P $b ($ox + 3 + $x) $y1 $cy2
    P $b ($ox + 3 + $x) ($y1 + 1) $cy0
  }
  Px $b ($ox + 33) 5 $(if ($f % 2 -eq 0) { C '#ff4a4a' } else { C '#7a1a1a' })
  Rect $b ($ox + 3) 5 4 1 $cy1; Rect $b ($ox + 3) 7 6 1 $cy0
  Px $b ($ox + 5) 21 $(if ($f % 3 -eq 0) { $or2 } else { $or0 }); Px $b ($ox + 8) 21 $gr1; Px $b ($ox + 11) 21 $cy1
  Rect $b ($ox + 15) 24 10 2 $k2; Rect $b ($ox + 15) 24 10 1 $k4
  Clear $b $ox 0; Clear $b ($ox + 39) 0
}

# ====================================================================
# 壁の歯車（かみ合って回る）26x20 4コマ
Sheet 'science_gears.png' 26 20 4 {
  param($b, $ox, $f)
  Gear $b ($ox + 9.5) 10 8.6 6.4 8 ($f * 11.25) $k3 $k5 $k0 $k0 2.0
  Gear $b ($ox + 21.5) 10 6.0 3.9 5 (-$f * 18.0) $or1 $or3 $k0 $k0 1.4
  Px $b ($ox + 9) 9 $k4; Px $b ($ox + 9) 10 $k0
}

# ====================================================================
# 台座（ロボットの舞台。前のふちのLEDが流れる）72x24 4コマ
Sheet 'science_stage.png' 72 24 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 72 12 $k0
  Rect $b ($ox + 1) 1 70 10 $k3
  for ($y = 2; $y -lt 11; $y += 2) { Rect $b ($ox + 1) $y 70 1 (Mix $k3 $k2 0.5) }
  Rect $b ($ox + 1) 1 70 1 $k5
  Ellipse $b ($ox + 36) 6.3 24 4.6 $k1
  Ellipse $b ($ox + 36) 6.3 23 3.8 $cy1
  Ellipse $b ($ox + 36) 6.3 21.8 3.1 $k2
  Ellipse $b ($ox + 36) 6.3 14 2.2 (Mix $k2 $k1 0.5)
  for ($i = 0; $i -lt 8; $i++) {
    $a = ($i / 8.0 + $f / 32.0) * 2 * [math]::PI
    P $b ($ox + 36 + 21.5 * [math]::Cos($a)) (6.3 + 3.4 * [math]::Sin($a)) $cy3
  }
  # 前面
  Rect $b $ox 12 72 8 $k0
  Rect $b ($ox + 1) 12 70 7 $k2
  Rect $b ($ox + 1) 12 70 1 $k5
  for ($x = 6; $x -lt 66; $x++) {
    $lit = ((([int][math]::Floor($x / 4)) + $f) % 4) -eq 0
    Px $b ($ox + $x) 15 $(if ($lit) { $cy3 } else { $cy0 }); Px $b ($ox + $x) 16 $(if ($lit) { $cy2 } else { $k1 })
  }
  for ($x = 1; $x -lt 6; $x++) { foreach ($xx in @($x, (71 - $x))) { $s = ((($xx + 12) -shr 1) -band 1) -eq 0; Px $b ($ox + $xx) 13 $(if ($s) { $or1 } else { $k0 }); Px $b ($ox + $xx) 14 $(if ($s) { $or1 } else { $k0 }); Px $b ($ox + $xx) 15 $(if ($s) { $or2 } else { $k0 }); Px $b ($ox + $xx) 16 $(if ($s) { $or2 } else { $k0 }); Px $b ($ox + $xx) 17 $(if ($s) { $or1 } else { $k0 }) } }
  Rect $b ($ox + 1) 18 70 1 $k1
  # 影
  Rect $b ($ox + 2) 20 68 2 (CA '#0d1b2a' 80); Rect $b ($ox + 4) 22 64 1 (CA '#0d1b2a' 45)
  Clear $b $ox 0; Clear $b ($ox + 71) 0
}

# ====================================================================
# 大きな人型ロボット 32x34（目がまばたき・胸の光が脈打ち・右手を振る・アンテナが点滅）8コマ
$handX = @(27, 29, 30, 29, 30, 27, 30, 29)
$handY = @(30, 26, 21, 15, 12, 12, 12, 20)
Sheet 'science_bigbot.png' 32 34 8 {
  param($b, $ox, $f)
  # 足
  foreach ($lx in 9, 18) {
    Rect $b ($ox + $lx) 29 5 3 $k0; Rect $b ($ox + $lx + 1) 29 3 2 $k3
    Rect $b ($ox + $lx - 1) 31 7 3 $k0; Rect $b ($ox + $lx) 32 5 1 $or1; Rect $b ($ox + $lx) 31 5 1 $or2
  }
  # 左うで（動かない）
  Rect $b ($ox + 2) 21 4 9 $k0; Rect $b ($ox + 3) 22 2 7 $k4; Rect $b ($ox + 3) 22 1 7 $k5
  Rect $b ($ox + 2) 30 4 3 $k0; Rect $b ($ox + 3) 30 2 2 $or2
  # 胴
  Rect $b ($ox + 7) 17 18 12 $k0
  Rect $b ($ox + 8) 18 16 10 $k5
  Rect $b ($ox + 8) 18 16 1 $wh; Rect $b ($ox + 8) 18 1 10 $wh
  Rect $b ($ox + 21) 19 3 9 $k4; Rect $b ($ox + 8) 27 16 1 $k4
  Rect $b ($ox + 11) 20 10 6 $k0; Rect $b ($ox + 12) 21 8 4 (C '#0b3a4d')
  $pulse = @($cy1, $cy2, $cy3, $cy2, $cy1, $cy0, $cy1, $cy2)[$f]
  Rect $b ($ox + 14) 22 4 2 $pulse
  Px $b ($ox + 13) 23 $pulse; Px $b ($ox + 18) 23 $pulse
  for ($i = 0; $i -lt 4; $i++) { $h = 1 + (($i * 2 + $f) % 3); Rect $b ($ox + 13 + $i * 2) (25 - $h) 1 $h $or2 }
  Rect $b ($ox + 8) 28 16 1 $or1; Rect $b ($ox + 14) 28 4 1 $or3
  # 首・頭
  Rect $b ($ox + 14) 15 4 2 $k2
  Rect $b ($ox + 7) 7 2 5 $k0; Rect $b ($ox + 7) 8 1 3 $or2; Rect $b ($ox + 8) 7 1 5 $or1
  Rect $b ($ox + 23) 7 2 5 $k0; Rect $b ($ox + 24) 8 1 3 $or1; Rect $b ($ox + 23) 7 1 5 $or1
  Rect $b ($ox + 9) 4 14 12 $k0
  Rect $b ($ox + 10) 5 12 10 $k5
  Rect $b ($ox + 10) 5 12 1 $wh; Rect $b ($ox + 10) 5 1 10 $wh; Rect $b ($ox + 21) 6 1 9 $k4
  Rect $b ($ox + 11) 7 10 6 $k0; Rect $b ($ox + 12) 8 8 4 $k1
  if ($f -eq 5) { Rect $b ($ox + 13) 10 2 1 $cy2; Rect $b ($ox + 17) 10 2 1 $cy2 }
  else { Rect $b ($ox + 13) 9 2 2 $cy2; Rect $b ($ox + 17) 9 2 2 $cy2; Px $b ($ox + 13) 9 $cy3; Px $b ($ox + 17) 9 $cy3 }
  Rect $b ($ox + 15) 12 2 1 $cy1
  # アンテナ
  Rect $b ($ox + 15) 2 2 3 $k3
  Rect $b ($ox + 14) 0 4 3 $k0
  $ac = if ($f -lt 4) { $or2 } else { $or0 }
  Rect $b ($ox + 15) 1 2 1 $ac; Px $b ($ox + 15) 0 (Mix $ac $k0 0.4); Px $b ($ox + 16) 0 (Mix $ac $k0 0.4)
  if ($f -lt 4) { Px $b ($ox + 13) 1 (CA '#ffa43a' 120); Px $b ($ox + 18) 1 (CA '#ffa43a' 120) }
  # 右うで（手をふる）
  Limb $b ($ox + 26) 20 ($ox + $handX[$f]) $handY[$f] 2 $k0 $k4
  Rect $b ($ox + 24) 18 4 5 $k0; Rect $b ($ox + 25) 19 2 3 $or1; Px $b ($ox + 25) 19 $or3
  $hxx = $ox + $handX[$f]; $hyy = $handY[$f]
  Rect $b ($hxx - 2) ($hyy - 1) 4 4 $k0; Rect $b ($hxx - 1) $hyy 2 2 $or2
}

# ====================================================================
# 台の上のロボットアーム 52x44（ブロックを つかんで はこぶ）10コマ
$alpha = @(-58, -42, -22, 0, 26, 46, 58, 52, 26, -20)
$beta = @(-170, -125, -80, -30, 30, 85, 165, 115, 40, -75)
Sheet 'science_arm.png' 52 44 10 {
  param($b, $ox, $f)
  $px0 = 26.0; $py0 = 30.0
  $a1 = $alpha[$f] * [math]::PI / 180; $a2 = $beta[$f] * [math]::PI / 180
  $ex = $px0 + 17 * [math]::Sin($a1); $ey = $py0 - 17 * [math]::Cos($a1)
  $hx = $ex + 15 * [math]::Sin($a2); $hy = $ey - 15 * [math]::Cos($a2)
  # 土台
  Rect $b ($ox + 14) 38 24 6 $k0; Rect $b ($ox + 15) 39 22 4 $or1; Rect $b ($ox + 15) 39 22 1 $or3; Rect $b ($ox + 15) 42 22 1 $or0
  foreach ($sx in 17, 34) { Px $b ($ox + $sx) 41 $k0 }
  Rect $b ($ox + 20) 31 12 7 $k0; Rect $b ($ox + 21) 32 10 5 $k3; Rect $b ($ox + 21) 32 10 1 $k5; Rect $b ($ox + 21) 36 10 1 $k2
  Rect $b ($ox + 23) 34 6 1 $cy2
  # うで（根元 → ひじ → 手首）
  Limb $b ($ox + $px0) $py0 ($ox + $ex) $ey 4 $k0 $k4
  Limb $b ($ox + $px0) $py0 ($ox + $ex) $ey 2 $k5 $k5
  Limb $b ($ox + $ex) $ey ($ox + $hx) $hy 4 $k0 $wh
  Ellipse $b ($ox + $px0 + 0.5) ($py0 + 0.5) 4.4 4.4 $k0; Ellipse $b ($ox + $px0 + 0.5) ($py0 + 0.5) 3.2 3.2 $or1; Ellipse $b ($ox + $px0) ($py0) 1.4 1.2 $or3
  Ellipse $b ($ox + $ex + 0.5) ($ey + 0.5) 3.8 3.8 $k0; Ellipse $b ($ox + $ex + 0.5) ($ey + 0.5) 2.7 2.7 $or2; Px $b ($ox + $ex) $ey $wh
  # グリッパー（開いて・閉じる）と、つかんだブロック
  $open = ($f -eq 0 -or $f -ge 7)
  $sp = if ($open) { 0.66 } else { 0.30 }
  foreach ($sg in -1, 1) {
    $ca = $a2 + $sg * $sp
    $cx1 = $hx + 5.5 * [math]::Sin($ca); $cy1_ = $hy - 5.5 * [math]::Cos($ca)
    Limb $b ($ox + $hx) $hy ($ox + $cx1) $cy1_ 1 $k0 $or2
  }
  Ellipse $b ($ox + $hx + 0.5) ($hy + 0.5) 2.6 2.6 $k0; Px $b ($ox + $hx) $hy $cy2
  if ($f -ge 1 -and $f -le 6) {
    $bxx = $hx + 4.2 * [math]::Sin($a2); $byy = $hy - 4.2 * [math]::Cos($a2)
    Rect $b ([int][math]::Round($ox + $bxx - 2)) ([int][math]::Round($byy - 2)) 5 5 $k0
    Rect $b ([int][math]::Round($ox + $bxx - 1)) ([int][math]::Round($byy - 1)) 3 3 $cy1
    Px $b ([int][math]::Round($ox + $bxx - 1)) ([int][math]::Round($byy - 1)) $cy3
  }
}

# ====================================================================
# アームの作業台 52x24（左にブロック、右に置き場）
Sheet 'science_table.png' 52 24 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 52 10 $k0
  Rect $b ($ox + 1) 1 50 8 $k5
  Rect $b ($ox + 1) 1 50 1 $wh
  Rect $b ($ox + 1) 8 50 1 $k4
  Rect $b $ox 10 52 12 $k0
  Rect $b ($ox + 1) 10 50 11 $k2
  Rect $b ($ox + 1) 10 50 1 $k4
  Rect $b ($ox + 3) 12 21 7 $k0; Rect $b ($ox + 4) 13 19 5 $k1; Rect $b ($ox + 12) 14 3 2 $k4
  Rect $b ($ox + 28) 12 21 7 $k0; Rect $b ($ox + 29) 13 19 5 $k1; Rect $b ($ox + 37) 14 3 2 $k4
  for ($x = 1; $x -lt 51; $x++) { $s = ((($x + 2) -shr 1) -band 1) -eq 0; Px $b ($ox + $x) 20 $(if ($s) { $or1 } else { $k0 }) }
  Rect $b ($ox + 3) 22 4 2 $k0; Rect $b ($ox + 45) 22 4 2 $k0
  # ブロック（左に3個、右に置き場の枠）
  Rect $b ($ox + 4) 4 5 5 $k0; Rect $b ($ox + 5) 5 3 3 $or1; Px $b ($ox + 5) 5 $or3
  Rect $b ($ox + 10) 4 5 5 $k0; Rect $b ($ox + 11) 5 3 3 $cy1; Px $b ($ox + 11) 5 $cy3
  Rect $b ($ox + 7) 0 5 5 $k0; Rect $b ($ox + 8) 1 3 3 $gr1; Px $b ($ox + 8) 1 $gr2
  for ($i = 0; $i -lt 8; $i += 2) { Px $b ($ox + 40 + $i) 3 $or1; Px $b ($ox + 40 + $i) 9 $or1 }
  foreach ($q in 4, 6, 8) { Px $b ($ox + 40) $q $or1; Px $b ($ox + 46) $q $or1 }
  Rect $b ($ox + 41) 4 5 4 (Mix $k5 $or2 0.15)
  Clear $b $ox 0; Clear $b ($ox + 51) 0
}

# ====================================================================
# 実験台 48x30（フラスコの光る液体が泡立ち、試験管の色が変わる）6コマ
Sheet 'science_bench.png' 48 30 6 {
  param($b, $ox, $f)
  # 光
  $al = [int](28 + 22 * [math]::Sin($f * 2 * [math]::PI / 6))
  Ellipse $b ($ox + 9.5) 11 11 9.5 (CA '#5dffa0' $al)
  Ellipse $b ($ox + 9.5) 12 7 6 (CA '#b2ffc4' ($al + 10))
  # フラスコ
  $cx = 9
  for ($r = 2; $r -le 6; $r++) { Px $b ($ox + $cx - 2) $r $k3; Px $b ($ox + $cx + 1) $r $k3; Rect $b ($ox + $cx - 1) $r 2 1 (CA '#dff4ff' 120) }
  Rect $b ($ox + $cx - 3) 1 6 1 $k4
  for ($r = 7; $r -le 15; $r++) {
    $hw = [int][math]::Round(2 + ($r - 6) * 0.62)
    Px $b ($ox + $cx - $hw) $r $k3; Px $b ($ox + $cx + $hw - 1) $r $k3
    for ($x = $cx - $hw + 1; $x -lt $cx + $hw - 1; $x++) {
      if ($r -ge 11) {
        $c = if ($r -eq 11) { $gr2 } elseif ($r -ge 14) { $gr0 } else { $gr1 }
        Px $b ($ox + $x) $r $c
      } else { Px $b ($ox + $x) $r (CA '#dff4ff' 120) }
    }
  }
  Rect $b ($ox + $cx - 6) 16 12 1 $k3
  Px $b ($ox + $cx - 2) 9 $wh; Px $b ($ox + $cx - 3) 12 $gr2
  # 泡
  for ($i = 0; $i -lt 3; $i++) {
    $by = 15 - (($f * 2 + $i * 2) % 6) - 1
    $bx = $cx - 2 + $i * 2 + (($f + $i) % 2)
    if ($by -ge 11) { Px $b ($ox + $bx) $by $gr2 }
  }
  $fy = 1 - ($f % 3)
  Px $b ($ox + $cx - 1 + ($f % 2)) $fy (CA '#b2ffc4' 160)
  # ビーカー（オレンジの液）
  Rect $b ($ox + 32) 9 8 8 (CA '#dff4ff' 120)
  Rect $b ($ox + 32) 9 1 8 $k3; Rect $b ($ox + 39) 9 1 8 $k3; Rect $b ($ox + 32) 16 8 1 $k3
  Rect $b ($ox + 33) 12 6 4 $or2; Rect $b ($ox + 33) 12 6 1 $or3; Rect $b ($ox + 33) 15 6 1 $or1
  Px $b ($ox + 31) 9 $k4; Px $b ($ox + 40) 9 $k4
  foreach ($q in 11, 13) { Px $b ($ox + 34) $q $k0 }
  Px $b ($ox + 36 + ($f % 2)) (14 - ($f % 3)) $or3
  # 試験管ラック
  Rect $b ($ox + 41) 15 7 2 $k2; Rect $b ($ox + 41) 15 7 1 $k4
  $tc = @((Mix $cy1 $cy3 (($f % 3) / 2.0)), (C '#ff6fae'), (C '#ffe45a'))
  $x = 41
  for ($t = 0; $t -lt 3; $t++) {
    $tx = $x + $t * 3 - 0
    if ($t -eq 2) { $tx = 46 }
    Rect $b ($ox + $tx) 8 2 7 (CA '#dff4ff' 140); Rect $b ($ox + $tx) 11 2 4 $tc[$t]; Px $b ($ox + $tx) 11 (Mix $tc[$t] $wh 0.5)
    Px $b ($ox + $tx - 1) 8 $k3; Px $b ($ox + $tx + 2) 8 $k3
  }
  # 台
  Rect $b $ox 17 48 13 $k0
  Rect $b ($ox + 1) 17 46 6 $k5; Rect $b ($ox + 1) 17 46 1 $wh; Rect $b ($ox + 1) 22 46 1 $k4
  Rect $b ($ox + 1) 23 46 6 $k2; Rect $b ($ox + 1) 23 46 1 $k4
  Rect $b ($ox + 3) 24 12 5 $k0; Rect $b ($ox + 4) 25 10 3 $k1
  # 注意マーク（三角に!）
  Rect $b ($ox + 6) 25 1 1 $or2; Rect $b ($ox + 7) 25 2 1 $or2; Rect $b ($ox + 8) 25 1 1 $or2
  Px $b ($ox + 7) 26 $or2
  Rect $b ($ox + 20) 24 24 5 $k0; Rect $b ($ox + 21) 25 22 3 $k1
  foreach ($q in 0..5) { Rect $b ($ox + 22 + $q * 4) 26 2 1 (Mix $cy1 $cy3 (($q + $f) % 3 / 2.0)) }
  Rect $b ($ox + 1) 28 46 1 $k0
  Rect $b ($ox + 2) 29 4 1 $k0; Rect $b ($ox + 42) 29 4 1 $k0
}

# ====================================================================
# ガラスの展示ケース 34x32（中に小さなロボット）
Sheet 'science_case.png' 34 32 1 {
  param($b, $ox, $f)
  # 台座
  Rect $b ($ox + 2) 20 30 12 $k0
  Rect $b ($ox + 3) 21 28 10 $k2
  Rect $b ($ox + 3) 21 28 1 $k4
  Rect $b ($ox + 7) 24 20 5 $k0; Rect $b ($ox + 8) 25 18 3 $k1
  Rect $b ($ox + 10) 26 3 1 $cy2; Rect $b ($ox + 15) 26 8 1 $k4; Rect $b ($ox + 25) 26 3 1 $or2
  # ガラス
  Rect $b ($ox + 3) 3 28 17 (CA '#cfe9ff' 70)
  Rect $b ($ox + 2) 2 1 18 $k3; Rect $b ($ox + 31) 2 1 18 $k3
  Rect $b ($ox + 1) 0 32 3 $k0; Rect $b ($ox + 2) 1 30 1 $k4; Rect $b ($ox + 2) 2 30 1 $k3
  # 小さなロボット
  Rect $b ($ox + 12) 8 10 7 $k0; Rect $b ($ox + 13) 9 8 5 $k5; Rect $b ($ox + 14) 10 6 3 $k1; Px $b ($ox + 15) 11 $cy2; Px $b ($ox + 18) 11 $cy2
  Px $b ($ox + 16) 6 $k3; Px $b ($ox + 16) 5 $or2; Px $b ($ox + 16) 7 $k3
  Rect $b ($ox + 13) 15 8 4 $k0; Rect $b ($ox + 14) 16 6 2 $or1
  Rect $b ($ox + 11) 15 2 3 $k3; Rect $b ($ox + 23) 15 2 3 $k3
  Rect $b ($ox + 13) 19 3 1 $k0; Rect $b ($ox + 19) 19 3 1 $k0
  # 反射
  foreach ($p in @(@(6, 15, 10, 8), @(9, 16, 12, 12))) { Line $b ($ox + $p[0]) $p[1] ($ox + $p[2]) $p[3] (CA '#ffffff' 140) }
  Line $b ($ox + 24) 6 ($ox + 28) 12 (CA '#ffffff' 90)
  Clear $b ($ox + 2) 20; Clear $b ($ox + 31) 20
}

# ====================================================================
# 四足ロボット 22x16（脚が歩く・しっぽのアンテナが点滅）4コマ
Sheet 'science_dog.png' 22 16 4 {
  param($b, $ox, $f)
  $bob = @(0, 1, 0, 1)[$f]
  $oA = @(-1, 0, 1, 0)[$f]; $oB = @(1, 0, -1, 0)[$f]
  $lA = @(0, 1, 0, 0)[$f]; $lB = @(0, 0, 0, 1)[$f]
  # 脚（奥の脚は少し暗く）
  foreach ($lg in @(@(5, $oA, $lA, $k2), @(15, $oB, $lB, $k2), @(8, $oB, $lB, $k1), @(12, $oA, $lA, $k1))) {
    $lx = $lg[0] + $lg[1]; $ht = 5 - $lg[2]
    Rect $b $lx (10 + $bob) 2 $ht $k0
    Px $b ($lx) (10 + $bob) $lg[3]; Px $b ($lx + 1) (10 + $bob) $lg[3]
    Rect $b ($lx - 1) (10 + $bob + $ht - 1) 3 1 $or1
  }
  # 体
  Rect $b 4 (4 + $bob) 13 7 $k0
  Rect $b 5 (5 + $bob) 11 5 $k5
  Rect $b 5 (5 + $bob) 11 1 $wh
  Rect $b 5 (8 + $bob) 11 1 $cy1
  Rect $b 6 (6 + $bob) 3 2 $or1
  # 頭
  Rect $b 16 (2 + $bob) 6 6 $k0
  Rect $b 17 (3 + $bob) 4 4 $k4
  Rect $b 17 (3 + $bob) 4 1 $k5
  Rect $b 19 (4 + $bob) 2 2 $cy2; Px $b 19 (4 + $bob) $cy3
  Px $b 17 (1 + $bob) $k0; Px $b 18 (1 + $bob) $k3
  # しっぽ
  Line $b 4 (5 + $bob) 2 (2 + $bob) $k3
  Px $b 2 (1 + $bob) $(if ($f -lt 2) { $or2 } else { $or0 })
  Clear $b 4 (4 + $bob)
}

# ====================================================================
# そうじロボット 14x8（ランプが交互に光る）2コマ
Sheet 'science_cleaner.png' 14 8 2 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 7) 6.3 7 2.3 (CA '#0d1b2a' 70)
  Ellipse $b ($ox + 7) 4.4 7 3.3 $k0
  Ellipse $b ($ox + 7) 4.1 6 2.7 $k5
  Ellipse $b ($ox + 7) 3.4 4.2 2 $wh
  Rect $b ($ox + 2) 5 10 1 $k3
  Px $b ($ox + 7) 2 $(if ($f -eq 0) { $or2 } else { $cy2 })
  Px $b ($ox + 3) 4 $(if ($f -eq 0) { $gr1 } else { $k4 }); Px $b ($ox + 11) 4 $(if ($f -eq 0) { $k4 } else { $gr1 })
  Px $b ($ox + 1) 6 $or1; Px $b ($ox + 12) 6 $or1
}

# ====================================================================
# 車輪ロボット 18x22（目が左右を見まわす・車輪が回る）4コマ
Sheet 'science_wheelbot.png' 18 22 4 {
  param($b, $ox, $f)
  $pup = @(0, 2, 4, 2)[$f]
  # 足まわり
  Rect $b ($ox + 3) 17 12 3 $k0; Rect $b ($ox + 4) 17 10 1 $k3
  foreach ($wx in 5, 13) {
    Ellipse $b ($ox + $wx) 19.2 3.2 2.8 $k0; Ellipse $b ($ox + $wx) 19.2 2.2 1.9 $k3
    $sp = @(@(-1, 0), @(0, -1), @(1, 0), @(0, 1))[$f]
    Px $b ($ox + $wx - 1 + $sp[0] + 1) (19 + $sp[1]) $or2
  }
  # 体
  Rect $b ($ox + 5) 10 8 8 $k0; Rect $b ($ox + 6) 11 6 6 $or1; Rect $b ($ox + 6) 11 6 1 $or3; Rect $b ($ox + 6) 16 6 1 $or0
  Rect $b ($ox + 8) 13 2 2 $cy2; Px $b ($ox + 8) 13 $cy3
  Rect $b ($ox + 2) 11 3 5 $k0; Rect $b ($ox + 3) 12 1 3 $k4; Rect $b ($ox + 13) 11 3 5 $k0; Rect $b ($ox + 14) 12 1 3 $k4
  # 頭
  Ellipse $b ($ox + 9) 5.8 6.4 4.8 $k0
  Ellipse $b ($ox + 9) 5.6 5.5 3.9 $k5
  Rect $b ($ox + 4) 4 10 4 $k0; Rect $b ($ox + 5) 5 8 2 $k1
  Rect $b ($ox + 5 + $pup) 5 3 2 $cy2; Px $b ($ox + 5 + $pup) 5 $cy3
  Px $b ($ox + 9) 0 $k3; Px $b ($ox + 9) 1 $k3; Px $b ($ox + 8) 0 $(if ($f % 2 -eq 0) { $or2 } else { $or0 }); Px $b ($ox + 10) 0 $(if ($f % 2 -eq 0) { $or2 } else { $or0 })
}

# ====================================================================
# 案内板「さわってみよう」 62x30
Sheet 'science_panel.png' 62 36 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 8) 30 3 6 $k2; Rect $b ($ox + 51) 30 3 6 $k2; Rect $b ($ox + 8) 30 1 6 $k4; Rect $b ($ox + 51) 30 1 6 $k4
  Rect $b $ox 0 62 31 $k0
  Rect $b ($ox + 1) 1 60 29 $cy1
  Rect $b ($ox + 2) 2 58 27 $k1
  Rect $b ($ox + 2) 2 58 1 $k2
  [void](TextPx $b 'さわって' ($ox + 4) 4 12 $wh $false)
  [void](TextPx $b 'みよう！' ($ox + 4) 16 12 $or3 $false)
  # 丸いボタン
  Ellipse $b ($ox + 56.5) 15.5 4.4 4.4 $k0; Ellipse $b ($ox + 56.5) 15.5 3.6 3.6 $or0; Ellipse $b ($ox + 56.5) 15 3 3 $or1; Ellipse $b ($ox + 56) 14.2 1.5 1.2 $or3
  Clear $b $ox 0; Clear $b ($ox + 61) 0
}

# ====================================================================
# 白衣（人物の胴にかぶせる）96x64。人物と同じ位置・同じ向きで重ねる
Sheet 'science_coat.png' 96 64 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 43) 36 10 1 $wh
  Rect $b ($ox + 43) 37 10 1 $k5
  Px $b ($ox + 47) 36 $k4; Px $b ($ox + 48) 36 $k4; Px $b ($ox + 47) 37 $k4; Px $b ($ox + 48) 37 $k4
  Px $b ($ox + 44) 36 $cy2; Px $b ($ox + 51) 37 $k4
}
