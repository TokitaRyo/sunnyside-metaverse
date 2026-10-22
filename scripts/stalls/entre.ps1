# アントレ同好会「ロケットホイールシューター」の専用ドット絵。
#   モーターで回るホイール（車輪の形の円盤）を、ロケットのように飛ばして的をねらう射撃レーンの出店（宇宙っぽい紺×ネオンの配色）。
#   絵: 看板（光る球・回るホイール）、のぼり（ゆれる）、射撃カウンター、はっしゃき（モーターがふるえてホイールが回る）、
#       的の棚（ピン・カップ・風船・円盤の的・景品）、倒れるピン、ホイールの箱、安全ネット、レーン、黒板、景品の袋。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/entre.ps1   （リポジトリのルートで）
#   一部だけ作り直す: $env:ENTRE_ONLY='sign|launcher'  （ファイル名の正規表現。省略すると全部）
# 出力: client/public/brand/stall/entre_*.png（配置は scripts/stalls/entre.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（実在の玩具の名前・ロゴ・形は使わない）。文字は MS Gothic をドットにして貼る（Windows 専用）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Want($n) { return ((-not $env:ENTRE_ONLY) -or ($n -match $env:ENTRE_ONLY)) }

# ---------- 色（宇宙っぽい紺 × ネオン） ----------
$ink = C '#1b1534'
$navy = C '#2a2466'; $navy2 = C '#3b3390'; $navy3 = C '#5a52c8'
$cyan = C '#34d3e8'; $cyan2 = C '#1798b0'; $cyan3 = C '#b9f4fb'
$orange = C '#ff8a2a'; $orange2 = C '#d4601a'; $orange3 = C '#ffc27a'
$lime = C '#9be23a'; $lime2 = C '#5fa31f'; $lime3 = C '#d4f58f'
$pink = C '#ff5fa2'; $pink2 = C '#c93a7b'; $pink3 = C '#ffc0dc'
$yellow = C '#ffd93d'; $yellow2 = C '#d9a512'; $yellow3 = C '#fff4a8'
$gry = C '#aab0c8'; $gry2 = C '#6e7594'; $gry3 = C '#dfe3f2'
$tire = C '#2b2a3f'; $tire2 = C '#47466a'; $hole = C '#3a3f6e'
$none = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

function Ca($hex, $a) { $c0 = C $hex; return [System.Drawing.Color]::FromArgb($a, $c0.R, $c0.G, $c0.B) }
function Blob($b, $cx, $cy, $rx, $ry, $fill, $line) { Ellipse $b $cx $cy ($rx + 1) ($ry + 1) $line; Ellipse $b $cx $cy $rx $ry $fill }
# 絵を別の絵に重ねる（半透明も保つ）
function Put($dst, $src, $ox, $oy) { $g = [System.Drawing.Graphics]::FromImage($dst); $g.DrawImageUnscaled($src, [int]$ox, [int]$oy); $g.Dispose() }

# 縁取りつきの文字（TextPx を $scale 倍に拡大して貼る）
function BigText($b, $text, $x, $y, $px, $scale, $fill, $edge) {
  $tmp = NewBmp ($px * ($text.Length + 2)) ($px * 2)
  [void](TextPx $tmp $text 0 0 $px (C '#ffffff') $false)
  foreach ($d in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1), @(-1, -1), @(1, -1), @(-1, 1), @(1, 1))) {
    for ($j = 0; $j -lt $tmp.Height; $j++) { for ($i = 0; $i -lt $tmp.Width; $i++) {
      if ($tmp.GetPixel($i, $j).A -ge 128) { Rect $b ($x + $i * $scale + $d[0]) ($y + $j * $scale + $d[1]) $scale $scale $edge }
    } }
  }
  for ($j = 0; $j -lt $tmp.Height; $j++) { for ($i = 0; $i -lt $tmp.Width; $i++) {
    if ($tmp.GetPixel($i, $j).A -ge 128) { Rect $b ($x + $i * $scale) ($y + $j * $scale) $scale $scale $fill }
  } }
  $tmp.Dispose()
}

# 縦書き: 1文字ずつ $px ずつ下へ並べる
function VText($b, $text, $x, $y, $px, $col) {
  for ($i = 0; $i -lt $text.Length; $i++) { [void](TextPx $b ([string]$text[$i]) $x ($y + $i * $px) $px $col $false) }
}

# ホイール（車輪の形の円盤）: 外はタイヤ（黒いトレッド）、リム（色つき）、$n 本のスポーク、ハブ。$ang はラジアン
function Wheel($b, $cx, $cy, $r, $ang, $rim, $spoke, $n) {
  $step = 2 * [math]::PI / $n
  $hubR = [math]::Min(1.8, $r * 0.3)
  for ($y = [int][math]::Floor($cy - $r - 1); $y -le [int][math]::Ceiling($cy + $r + 1); $y++) {
    for ($x = [int][math]::Floor($cx - $r - 1); $x -le [int][math]::Ceiling($cx + $r + 1); $x++) {
      $dx = $x + 0.5 - $cx; $dy = $y + 0.5 - $cy; $d = [math]::Sqrt($dx * $dx + $dy * $dy)
      if ($d -gt $r) { continue }
      $a = [math]::Atan2($dy, $dx) - $ang
      if ($d -gt $r - 1.1) { Px $b $x $y $ink; continue }
      if ($d -lt $hubR) { Px $b $x $y $white; continue }
      if ($d -gt $r - 2.7) {
        $seg = [int][math]::Floor(($a + 8 * [math]::PI) / ($step / 2)) % 2
        if ($seg -eq 0) { Px $b $x $y $tire } else { Px $b $x $y $tire2 }
        continue
      }
      if ($d -gt $r - 3.9) { Px $b $x $y $rim; continue }
      $m = (($a % $step) + $step) % $step; $m = [math]::Min($m, $step - $m)
      if ($d * [math]::Sin($m) -lt 0.85) { Px $b $x $y $spoke } else { Px $b $x $y $hole }
    }
  }
}

# 回転（最近傍）。$px,$py が回転の中心で、元の絵の座標系のまま $dw x $dh に描く。$deg は時計まわり
function Rot($src, $dw, $dh, $px, $py, $deg) {
  $dst = NewBmp $dw $dh
  $t = $deg * [math]::PI / 180; $co = [math]::Cos($t); $si = [math]::Sin($t)
  for ($y = 0; $y -lt $dh; $y++) { for ($x = 0; $x -lt $dw; $x++) {
    $dx = $x + 0.5 - $px; $dy = $y + 0.5 - $py
    $sx = [int][math]::Floor($px + $dx * $co + $dy * $si); $sy = [int][math]::Floor($py - $dx * $si + $dy * $co)
    if ($sx -ge 0 -and $sy -ge 0 -and $sx -lt $src.Width -and $sy -lt $src.Height) {
      $col = $src.GetPixel($sx, $sy)
      if ($col.A -gt 0) { $dst.SetPixel($x, $y, $col) }
    }
  } }
  return $dst
}

# のぼりのゆれ: 元の絵（棒は左端2px）を、下ほど大きく横にゆらして横一列のシートにする。1コマの幅は 元の幅+4（元は+2ずらして置く）
function Sway($src, $frames, $amp) {
  $cw = $src.Width + 4
  $dst = NewBmp ($cw * $frames) $src.Height
  for ($f = 0; $f -lt $frames; $f++) {
    $ph = $f * 2 * [math]::PI / $frames
    for ($y = 0; $y -lt $src.Height; $y++) {
      $kk = $y / [double]$src.Height
      $sh = [int][math]::Round([math]::Sin($ph + $y / 12.0) * $amp * $kk)
      for ($x = 0; $x -lt $src.Width; $x++) {
        $col = $src.GetPixel($x, $y)
        if ($col.A -eq 0) { continue }
        $dxp = $sh; if ($x -lt 2) { $dxp = 0 }
        Px $dst ($f * $cw + 2 + $x + $dxp) $y $col
      }
    }
  }
  return $dst
}

# ピン 7x13（白に色の帯）
function PinAt($b, $x, $y, $stripe) {
  Ascii $b $x $y @(
    '..ooo..',
    '.owwgo.',
    '.owwgo.',
    '..oso..',
    '..owo..',
    '.owwgo.',
    'owwwwgo',
    'ossssso',
    'owwwwgo',
    'owwwwgo',
    'ossssso',
    'owwwwgo',
    '.ooooo.'
  ) @{ o = $ink; w = $white; g = $gry3; s = $stripe }
}
# 紙コップ 8x6（ふちが広い）
function CupAt($b, $x, $y, $col, $lite) {
  Ascii $b $x $y @(
    'oooooooo',
    'oLCCCCCo',
    '.oCCCCo.',
    '.oCCCCo.',
    '.owwwwo.',
    '..oooo..'
  ) @{ o = $ink; C = $col; L = $lite; w = $white }
}

# ---------- 看板 156x46 x4コマ。上は「アントレ同好会」（まわりの電球が走って光り、両わきのホイールが回る）、下は「ロケットホイールシューター」 ----------
if (Want 'sign') {
  $base = NewBmp 156 46
  Rect $base 20 0 116 29 $ink
  Rect $base 21 1 114 27 $orange
  Rect $base 22 2 112 25 $navy
  Frame $base 23 3 110 23 $cyan
  foreach ($p in @(@(27, 6), @(30, 21), @(131, 7), @(127, 22), @(41, 5), @(117, 23), @(25, 14), @(133, 15))) { Px $base $p[0] $p[1] $yellow3 }
  $t1 = 'アントレ同好会'
  $tw = TextWidth $t1 15
  BigText $base $t1 ([math]::Floor((156 - $tw) / 2)) 6 15 1 $yellow $ink
  Rect $base 38 29 3 2 $gry2; Rect $base 115 29 3 2 $gry2
  Rect $base 0 31 156 15 $ink
  Rect $base 1 32 154 13 (C '#0f3a5c')
  Rect $base 1 32 154 1 $cyan; Rect $base 1 44 154 1 $cyan
  $t2 = 'ロケットホイールシューター'
  $w2 = TextWidth $t2 11
  [void](TextPx $base $t2 ([math]::Floor((156 - $w2 - 1) / 2)) 33 11 $yellow3 $true)
  $sheet = NewBmp 624 46
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * 156
    Put $sheet $base $ox 0
    for ($i = 0; $i -lt 19; $i++) {
      $bx = $ox + 24 + $i * 6
      $c1 = $orange2; if ((($i + $f) % 3) -eq 0) { $c1 = $yellow3 }
      Px $sheet $bx 1 $c1; Px $sheet $bx 27 $c1
    }
    Wheel $sheet ($ox + 10) 14 9.5 ($f * 0.26) $orange $white 6
    Wheel $sheet ($ox + 146) 14 9.5 (-$f * 0.26) $cyan $white 6
  }
  $base.Dispose()
  Save $sheet 'entre_sign.png'
}

# ---------- のぼり 18x92 → ゆれる4コマ（22x92）。a: 紺に「アントレ同好会」 / b: オレンジにロケットと「ロケット」とホイール ----------
function NoboriFrame($bg, $edge) {
  $s = NewBmp 18 92
  Rect $s 0 0 2 92 $gry2; Rect $s 0 0 1 92 $gry3
  Rect $s 0 2 18 2 $gry3
  Rect $s 2 4 15 88 $ink
  Rect $s 3 4 13 87 $bg
  Rect $s 3 4 13 2 $edge; Rect $s 3 85 13 2 $edge
  for ($x = 2; $x -lt 17; $x++) {
    $depth = [math]::Abs((($x - 2) % 6) - 3)
    for ($y = [int](88 + $depth); $y -lt 92; $y++) { Px $s $x $y $none }
  }
  return $s
}
if (Want 'nobori_a') {
  $s = NoboriFrame $navy $orange
  VText $s 'アントレ同好会' 4 8 11 $yellow
  $sheet = Sway $s 4 2
  $s.Dispose()
  Save $sheet 'entre_nobori_a.png'
}
if (Want 'nobori_b') {
  $s = NoboriFrame $orange $navy
  Ascii $s 6 8 @(
    '...o...',
    '..oro..',
    '.orrro.',
    '.owwwo.',
    '.owbwo.',
    '.owwwo.',
    'ccowocc',
    'cc.o.cc',
    '...f...'
  ) @{ o = $ink; r = $red; w = $white; b = $cyan2; c = $cyan; f = $yellow }
  VText $s 'ロケット' 4 20 11 $navy
  Wheel $s 9.5 74 7 0.3 $cyan $white 6
  $sheet = Sway $s 4 2
  $s.Dispose()
  Save $sheet 'entre_nobori_b.png'
}

# ---------- 安全ネット 16x44（両わきのしま柱と、すきとおったあみ） ----------
if (Want 'net') {
  $b = NewBmp 16 44
  $mesh = Ca '#b9f4fb' 165
  for ($y = 3; $y -lt 42; $y++) { for ($x = 3; $x -lt 13; $x++) {
    if ((($x + $y) % 4) -eq 0 -or (($x - $y + 100) % 4) -eq 0) { Px $b $x $y $mesh }
  } }
  Rect $b 0 0 3 44 $ink; Rect $b 1 0 1 44 $orange
  Rect $b 13 0 3 44 $ink; Rect $b 14 0 1 44 $orange
  for ($y = 6; $y -lt 40; $y += 8) { Rect $b 1 $y 1 4 $white; Rect $b 14 $y 1 4 $white }
  Rect $b 0 0 16 3 $ink; Rect $b 1 1 14 1 $cyan
  Rect $b 0 41 16 3 $ink; Rect $b 1 42 14 1 $cyan2
  Save $b 'entre_net.png'
}

# ---------- 的の棚 116x42。紺の板に星、オレンジの柱、2段の板（上のへりはシアン） ----------
if (Want 'shelf') {
  $b = NewBmp 116 42
  Rect $b 0 0 116 42 $ink
  Rect $b 3 3 110 37 $navy
  for ($x = 3; $x -lt 113; $x += 11) { Rect $b $x 3 1 37 $navy2 }
  foreach ($p in @(@(9, 8), @(25, 14), @(41, 7), @(58, 12), @(74, 6), @(90, 13), @(106, 8), @(16, 28), @(48, 31), @(66, 27), @(84, 32), @(100, 26))) { Px $b $p[0] $p[1] $navy3 }
  Rect $b 0 0 116 3 $orange; Rect $b 0 0 116 1 $orange3; Rect $b 0 2 116 1 $orange2
  Rect $b 0 3 116 1 $cyan
  Rect $b 0 0 3 42 $orange; Rect $b 0 0 1 42 $orange3; Rect $b 2 0 1 42 $orange2
  Rect $b 113 0 3 42 $orange; Rect $b 113 0 1 42 $orange3; Rect $b 115 0 1 42 $orange2
  foreach ($fy in @(19, 36)) {
    Rect $b 0 $fy 116 3 $gry3; Rect $b 0 $fy 116 1 $white; Rect $b 0 ($fy + 2) 116 1 $gry2
    Rect $b 3 ($fy + 3) 110 1 (C '#1f1a4d')
  }
  Rect $b 0 39 116 3 $ink
  Rect $b 0 39 3 3 $orange2; Rect $b 113 39 3 3 $orange2
  Save $b 'entre_shelf.png'
}

# ---------- 的 ----------
if (Want 'pin') {
  $stripes = @(@('pin_red', $red), @('pin_cyan', $cyan), @('pin_orange', $orange))
  foreach ($e in $stripes) {
    $b = NewBmp 7 13
    PinAt $b 0 0 $e[1]
    Save $b ('entre_' + $e[0] + '.png')
  }
}
if (Want 'cups') {
  $b = NewBmp 24 18
  CupAt $b 0 12 $pink $pink3; CupAt $b 8 12 $cyan $cyan3; CupAt $b 16 12 $yellow $yellow3
  CupAt $b 4 6 $lime $lime3; CupAt $b 12 6 $orange $orange3
  CupAt $b 8 0 $pink $pink3
  Save $b 'entre_cups.png'
}
if (Want 'disc') {
  foreach ($e in @(@('disc_a', $cyan, $orange), @('disc_b', $pink, $yellow))) {
    $b = NewBmp 13 18
    Rect $b 6 12 2 6 $ink; Rect $b 6 12 1 5 $gry2; Rect $b 4 17 6 1 $ink
    Blob $b 6.5 6.5 5.5 5.5 $white $ink
    Ellipse $b 6.5 6.5 4.5 4.5 $e[1]
    Ellipse $b 6.5 6.5 3.1 3.1 $white
    Ellipse $b 6.5 6.5 1.7 1.7 $e[2]
    Save $b ('entre_' + $e[0] + '.png')
  }
}
# 風船の的 11x18 x4コマ（ふわふわ上下）
function BalloonSheet($col, $hi) {
  $b = NewBmp 44 18
  $oyy = @(1, 0, 1, 2); $swy = @(0, 1, 0, -1)
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * 11; $yy = $oyy[$f]
    Blob $b ($ox + 5.5) ($yy + 6) 4.4 5.2 $col $ink
    Rect $b ($ox + 3) ($yy + 3) 2 2 $hi; Px $b ($ox + 3) ($yy + 5) $hi
    Px $b ($ox + 6) ($yy + 6) $white; Px $b ($ox + 5) ($yy + 7) $white; Px $b ($ox + 6) ($yy + 7) $white; Px $b ($ox + 7) ($yy + 7) $white; Px $b ($ox + 6) ($yy + 8) $white
    Rect $b ($ox + 4) ($yy + 12) 3 1 $ink; Px $b ($ox + 5) ($yy + 13) $ink
    for ($y = $yy + 14; $y -lt 18; $y++) { Px $b ($ox + 5 + $swy[$f] * (($y - $yy - 12) % 2)) $y $gry }
  }
  return $b
}
if (Want 'balloon') {
  foreach ($e in @(@('red', $red, $red3), @('cyan', $cyan, $cyan3), @('yellow', $yellow, $yellow3), @('lime', $lime, $lime3), @('pink', $pink, $pink3))) {
    $b = BalloonSheet $e[1] $e[2]
    Save $b ('entre_balloon_' + $e[0] + '.png')
  }
}
# たおれるピン 26x18 x8コマ（右にぱたんと倒れて、また立つ）
if (Want 'topple') {
  $src = NewBmp 26 18
  PinAt $src 3 5 $cyan
  $sheet = NewBmp 208 18
  $angs = @(0, 0, 0, 6, 30, 62, 90, 90)
  for ($f = 0; $f -lt 8; $f++) {
    $r2 = Rot $src 26 18 10.0 18.0 $angs[$f]
    Put $sheet $r2 ($f * 26) 0
    $r2.Dispose()
  }
  $src.Dispose()
  Save $sheet 'entre_topple.png'
}
# たおれた的
if (Want 'pin_lying') {
  $src = NewBmp 13 13
  PinAt $src 3 0 $red
  $r2 = Rot $src 13 13 6.5 6.5 80
  $b = NewBmp 13 7
  Put $b $r2 0 (-3)
  $r2.Dispose(); $src.Dispose()
  Save $b 'entre_pin_lying.png'
}
if (Want 'cups_lying') {
  $src = NewBmp 8 8
  CupAt $src 0 1 $cyan $cyan3
  $r1 = Rot $src 8 8 4.0 4.0 80
  $src2 = NewBmp 8 8
  CupAt $src2 0 1 $orange $orange3
  $r2 = Rot $src2 8 8 4.0 4.0 112
  $b = NewBmp 17 10
  Put $b $r1 0 2; Put $b $r2 9 0
  $r1.Dispose(); $r2.Dispose(); $src.Dispose(); $src2.Dispose()
  Save $b 'entre_cups_lying.png'
}

# ---------- 景品 ----------
if (Want 'prize_rocket') {
  $b = NewBmp 7 9
  Ascii $b 0 0 @(
    '...o...',
    '..oro..',
    '.orrro.',
    '.owwwo.',
    '.owbwo.',
    '.owwwo.',
    'ccowocc',
    'cc.o.cc',
    '...f...'
  ) @{ o = $ink; r = $red; w = $white; b = $cyan2; c = $cyan; f = $yellow }
  Save $b 'entre_prize_rocket.png'
}
if (Want 'prize_capsule') {
  $b = NewBmp 9 9
  Blob $b 4.5 4.5 3.6 3.6 $cyan $ink
  for ($y = 4; $y -lt 9; $y++) { for ($x = 0; $x -lt 9; $x++) {
    $dx = $x + 0.5 - 4.5; $dy = $y + 0.5 - 4.5
    if ($dx * $dx + $dy * $dy -le 12.96) { Px $b $x $y $pink }
  } }
  Rect $b 1 4 7 1 $ink
  Px $b 3 2 $cyan3; Px $b 2 3 $cyan3
  Save $b 'entre_prize_capsule.png'
}
if (Want 'prize_wheel') {
  $b = NewBmp 12 12
  Wheel $b 6 6 5.6 0.2 $lime $white 5
  Save $b 'entre_prize_wheel.png'
}

# ---------- はっしゃき（置き型の発射器）26x26 x4コマ。モーターでふるえ、ホイールが回る。色ちがい3つ ----------
function LauncherSheet($body, $body2, $body3, $acc, $rim) {
  $sheet = NewBmp 104 26
  $shk = @(0, 1, 0, -1)
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * 26; $s = $shk[$f]
    # 台座と持ち手
    Rect $sheet ($ox + 3) 24 20 2 $ink; Rect $sheet ($ox + 4) 24 18 1 $gry2
    Rect $sheet ($ox + 9) 17 8 8 $ink; Rect $sheet ($ox + 10) 17 6 7 (C '#3b3a55')
    Rect $sheet ($ox + 10) 20 6 1 (C '#55547a'); Rect $sheet ($ox + 10) 22 6 1 (C '#55547a')
    # ホイールをはさむ腕
    Rect $sheet ($ox + 4 + $s) 3 2 10 $ink; Rect $sheet ($ox + 4 + $s) 4 1 8 $body
    Rect $sheet ($ox + 20 + $s) 3 2 10 $ink; Rect $sheet ($ox + 21 + $s) 4 1 8 $body
    # 本体（モーターのケース）
    Rect $sheet ($ox + 4 + $s) 11 18 9 $ink
    Rect $sheet ($ox + 5 + $s) 12 16 7 $body
    Rect $sheet ($ox + 5 + $s) 12 16 1 $body3
    Rect $sheet ($ox + 5 + $s) 18 16 1 $body2
    Rect $sheet ($ox + 5 + $s) 15 16 2 $acc
    Rect $sheet ($ox + 15 + $s) 13 4 1 $body2   # 通気口
    # ランプ（ふるえに合わせてちかちか）とスイッチ
    $lamp = $none
    if (($f % 2) -eq 0) { $lamp = $yellow3 } else { $lamp = $orange2 }
    Rect $sheet ($ox + 6 + $s) 13 2 2 $lamp
    Rect $sheet ($ox + 12 + $s) 17 3 2 $red
    # ホイール（15度ずつ回る）
    Wheel $sheet ($ox + 13 + $s) 8 7 ($f * 0.2618) $rim $white 6
    # モーターのふるえ線
    if (($f % 2) -eq 1) {
      Rect $sheet ($ox + 0) 7 2 1 $cyan3; Rect $sheet ($ox + 1) 10 1 1 $cyan3
      Rect $sheet ($ox + 24) 7 2 1 $cyan3; Rect $sheet ($ox + 24) 10 1 1 $cyan3
    } else {
      Rect $sheet ($ox + 1) 5 1 2 $cyan3; Rect $sheet ($ox + 24) 5 1 2 $cyan3
    }
  }
  return $sheet
}
if (Want 'launcher') {
  $b = LauncherSheet $orange $orange2 $orange3 $cyan $cyan
  Save $b 'entre_launcher_a.png'
  $b = LauncherSheet $cyan $cyan2 $cyan3 $yellow $orange
  Save $b 'entre_launcher_b.png'
  $b = LauncherSheet $pink $pink2 $pink3 $lime $yellow
  Save $b 'entre_launcher_c.png'
}

# ---------- 飛んでいくホイール 18x42 x4コマ（下から上へ。しっぽつき） ----------
if (Want 'fly') {
  $b = NewBmp 72 42
  $cys = @(34, 25, 16, 8)
  for ($f = 0; $f -lt 4; $f++) {
    $cx = $f * 18 + 9; $cy = $cys[$f]
    foreach ($t in @(-3, 0, 3)) {
      $len = 6; if ($t -eq 0) { $len = 11 }
      for ($j = 0; $j -lt $len; $j++) {
        $al = 210 - $j * 18; if ($al -lt 0) { $al = 0 }
        Px $b ($cx + $t) ($cy + 7 + $j) (Ca '#b9f4fb' $al)
      }
    }
    Wheel $b $cx $cy 6 ($f * 0.31) $orange $white 5
  }
  Save $b 'entre_fly.png'
}

# ---------- ホイールの箱 30x22（カラフルなホイールがたまっている） ----------
if (Want 'wheelbox') {
  $b = NewBmp 30 22
  Wheel $b 7 7 5.5 0.1 $cyan $white 5
  Wheel $b 15 5 5.5 0.5 $orange $white 5
  Wheel $b 23 7 5.5 0.9 $pink $white 5
  Wheel $b 11 9 5.5 0.3 $lime $white 5
  Wheel $b 20 10 5.5 0.7 $yellow $white 5
  Rect $b 0 11 30 11 $ink
  Rect $b 1 12 28 9 $navy2
  Rect $b 1 12 28 1 $navy3
  Rect $b 1 15 28 3 $cyan2; Rect $b 1 15 28 1 $cyan
  foreach ($x in @(5, 11, 17, 23)) { Px $b $x 16 $white }
  Rect $b 0 21 30 1 $ink
  Save $b 'entre_wheelbox.png'
}
# 床に転がったホイール 11x11 (2色)
if (Want 'wheel_floor') {
  $b = NewBmp 11 11; Wheel $b 5.5 5.5 5.4 0.2 $cyan $white 6; Save $b 'entre_wheel_a.png'
  $b = NewBmp 11 11; Wheel $b 5.5 5.5 5.4 0.7 $pink $white 6; Save $b 'entre_wheel_b.png'
}
# カウンターのホイール皿 18x9
if (Want 'tray') {
  $b = NewBmp 18 9
  Wheel $b 4.5 4.5 4.4 0.2 $lime $white 5
  Wheel $b 13.5 4.5 4.4 0.6 $yellow $white 5
  Rect $b 0 6 18 3 $ink; Rect $b 1 6 16 2 $gry3; Rect $b 1 6 16 1 $white
  Save $b 'entre_tray.png'
}

# ---------- 景品の袋 12x14 ----------
if (Want 'gift') {
  $b = NewBmp 12 14
  Rect $b 3 0 1 4 $ink; Rect $b 8 0 1 4 $ink; Rect $b 3 0 6 1 $ink
  Rect $b 1 4 10 10 $ink; Rect $b 2 5 8 8 $pink; Rect $b 2 5 8 1 $pink3
  Rect $b 2 9 8 2 $yellow
  Ellipse $b 6 8 2 2 $white; Px $b 5 7 $orange; Px $b 6 8 $orange
  Save $b 'entre_gift.png'
}

# ---------- カウンター 124x22。上は明るい面、前は紺にホイールの印とランプ ----------
if (Want 'counter') {
  $b = NewBmp 124 22
  Rect $b 0 0 124 22 $ink
  Rect $b 1 1 122 8 $gry3; Rect $b 1 1 122 1 $white; Rect $b 1 7 122 2 $gry
  Rect $b 1 9 122 2 $cyan; Rect $b 1 9 122 1 $cyan3
  Rect $b 1 11 122 10 $navy; Rect $b 1 11 122 1 $navy2
  foreach ($cx in @(20, 62, 104)) { Wheel $b $cx 16 4.6 0.2 $orange $white 6 }
  foreach ($cx in @(41, 83)) { Rect $b ($cx - 2) 15 5 2 $yellow; Px $b $cx 15 $yellow3 }
  foreach ($cx in @(6, 118)) { Rect $b ($cx - 1) 14 3 3 $cyan; Px $b $cx 14 $cyan3 }
  Rect $b 0 21 124 1 $ink
  foreach ($p in @(@(0, 0), @(123, 0))) { Px $b $p[0] $p[1] $none }
  Save $b 'entre_counter.png'
}

# ---------- レーン 120x30（3本のマット。矢印とたつ位置のわっか） ----------
if (Want 'lane') {
  $b = NewBmp 120 30
  foreach ($mx in @(2, 42, 82)) {
    Rect $b $mx 1 36 28 $ink
    Rect $b ($mx + 1) 2 34 26 (C '#383e8c')
    Rect $b ($mx + 2) 2 1 26 $cyan; Rect $b ($mx + 33) 2 1 26 $cyan
    Rect $b ($mx + 3) 2 1 26 $cyan2; Rect $b ($mx + 32) 2 1 26 $cyan2
    $cx = $mx + 18
    # 矢印（上向き）
    for ($i = 0; $i -lt 5; $i++) { Rect $b ($cx - 1 - $i) (5 + $i) (2 + $i * 2) 1 $orange }
    Rect $b ($cx - 1) 10 2 8 $orange
    Rect $b ($cx - 1) 5 2 1 $orange3
    # たつ位置のわっか
    Ellipse $b ($cx - 0.5) 23 4.5 2.5 $yellow
    Ellipse $b ($cx - 0.5) 23 3 1.5 (C '#383e8c')
    foreach ($p in @(@(0, 0), @(35, 0), @(0, 27), @(35, 27))) { Px $b ($mx + $p[0]) (1 + $p[1]) $none }
  }
  Save $b 'entre_lane.png'
}

# ---------- 立て札（黒板）52x36 ----------
if (Want 'board') {
  $b = NewBmp 52 36
  Rect $b 0 0 52 32 $ink; Rect $b 1 1 50 30 $orange2; Rect $b 2 2 48 28 $orange; Rect $b 3 3 46 26 $navy
  Rect $b 6 32 3 4 $gry2; Rect $b 43 32 3 4 $gry2
  Rect $b 6 32 1 4 $gry3; Rect $b 43 32 1 4 $gry3
  $lines = 'ぐるぐる', 'ぴゅーん'
  for ($i = 0; $i -lt 2; $i++) {
    $col = $white; if ($i -eq 1) { $col = $yellow }
    $w = TextWidth $lines[$i] 11
    [void](TextPx $b $lines[$i] ([math]::Floor((52 - $w) / 2)) (5 + 12 * $i) 11 $col $false)
  }
  Save $b 'entre_board.png'
}

# ---------- きらっと光る星 9x9 x4コマ ----------
if (Want 'twinkle') {
  $b = NewBmp 36 9
  $sp = $cyan3
  Px $b 4 4 $white
  Px $b (9 + 4) 3 $sp; Px $b (9 + 3) 4 $sp; Px $b (9 + 4) 4 $white; Px $b (9 + 5) 4 $sp; Px $b (9 + 4) 5 $sp
  for ($i = 0; $i -lt 9; $i++) { Px $b (18 + $i) 4 $sp; Px $b (18 + 4) $i $sp }
  Px $b (18 + 4) 4 $white; Px $b (18 + 3) 4 $white; Px $b (18 + 5) 4 $white; Px $b (18 + 4) 3 $white; Px $b (18 + 4) 5 $white
  Px $b (18 + 2) 2 $yellow3; Px $b (18 + 6) 2 $yellow3; Px $b (18 + 2) 6 $yellow3; Px $b (18 + 6) 6 $yellow3
  Px $b (27 + 4) 2 $sp; Px $b (27 + 2) 4 $sp; Px $b (27 + 4) 4 $white; Px $b (27 + 6) 4 $sp; Px $b (27 + 4) 6 $sp
  Px $b (27 + 4) 3 $white; Px $b (27 + 3) 4 $white; Px $b (27 + 5) 4 $white; Px $b (27 + 4) 5 $white
  Save $b 'entre_twinkle.png'
}
