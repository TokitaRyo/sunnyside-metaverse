# たこ焼き屋台の専用ドット絵（看板・のぼり・提灯・のれん屋根・たこ焼き器・たこ焼きの舟皿・メニュー・カウンター・マスコットなど）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/takoyaki.ps1   （リポジトリのルートで）
# 出力: client/public/brand/stall/takoyaki_*.png（原点は各スプライトの足元。配置は scripts/stalls/takoyaki.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（お好み焼き屋の赤・白とちがって、紺・青・黄・たこの朱色）
$navy0 = C '#18265a'; $navy1 = C '#233c80'; $navy2 = C '#2f55a8'; $navy3 = C '#5b86d6'
$yel = C '#f6c744'; $yel2 = C '#d9822b'
$tko = C '#ee5a3c'; $tko2 = C '#b8392a'; $tkoOl = C '#5e1a18'
$paper = C '#f6f0dc'; $paper2 = C '#d9ceb0'
$sauce = C '#6e2f14'; $sauce2 = C '#94451d'; $sauceHi = C '#c4743a'
$mayo = C '#fff3d2'; $nori = C '#3fae4a'; $flake = C '#f4dcb0'; $flake2 = C '#cfa56c'
$gold1 = C '#d38a2c'; $gold2 = C '#f0b858'; $gold3 = C '#a8601c'; $raw = C '#f1dcaa'
$cop0 = C '#6e3a1e'; $cop1 = C '#a8643a'; $cop2 = C '#d38c54'
$boat = C '#e9cf94'; $boat2 = C '#b88a50'; $boatIn = C '#7a4e28'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# ---- 小さな道具
function Blit($dst, $src, $x, $y) {
  for ($j = 0; $j -lt $src.Height; $j++) { for ($i = 0; $i -lt $src.Width; $i++) { $p = $src.GetPixel($i, $j); if ($p.A -gt 0) { Px $dst ($x + $i) ($y + $j) $p } } }
}
# まわりに1pxのふちを付けた新しい絵を返す
function OutlineBmp($src, $col) {
  $n = NewBmp ($src.Width + 2) ($src.Height + 2)
  $m = New-Object 'bool[,]' $src.Width, $src.Height
  for ($j = 0; $j -lt $src.Height; $j++) { for ($i = 0; $i -lt $src.Width; $i++) { $p = $src.GetPixel($i, $j); if ($p.A -gt 0) { $m[$i, $j] = $true; $n.SetPixel($i + 1, $j + 1, $p) } } }
  for ($j = -1; $j -le $src.Height; $j++) {
    for ($i = -1; $i -le $src.Width; $i++) {
      $inside = ($i -ge 0 -and $j -ge 0 -and $i -lt $src.Width -and $j -lt $src.Height -and $m[$i, $j])
      if ($inside) { continue }
      $near = $false
      foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $a = $i + $d[0]; $c = $j + $d[1]
        if ($a -ge 0 -and $c -ge 0 -and $a -lt $src.Width -and $c -lt $src.Height -and $m[$a, $c]) { $near = $true }
      }
      if ($near) { $n.SetPixel($i + 1, $j + 1, $col) }
    }
  }
  $src.Dispose()
  return $n
}

# ---- たこのキャラクター（はちまきをしめた朱色のたこ）
$octoPal = @{ r = $tko; s = $tko2; w = $white; b = $navy2; k = (C '#1b1b2b'); e = (C '#ffffff'); m = (C '#8a1f1f') }
function Octo16() {
  $b = NewBmp 16 16
  Ascii $b 0 0 @(
    '.....rrrrrr.....',
    '...rrrrrrrrrr...',
    '..rrrrrrrrrrrs..',
    '.rrrrrrrrrrrrrs.',
    '.wwwwwwwwwwwwww.',
    '.wwwwwwbbwwwwww.',
    '.rrrrrrrrrrrrrs.',
    '.rrekrrrrrekrrs.',
    '.rrkkrrrrrkkrrs.',
    '.rrrrrrrrrrrrrs.',
    '..rrrrrmmrrrrs..',
    '..rrrrrrrrrrss..',
    '.rrr.rrr.rrr.rrr',
    'rrr..rrr.rrr..rr',
    'rr..rrr..rrr..r.',
    'r...rr....rr...r') $octoPal
  return (OutlineBmp $b $tkoOl)
}
function Octo11() {
  $b = NewBmp 11 11
  Ascii $b 0 0 @(
    '...rrrrr...',
    '..rrrrrrr..',
    '.rrrrrrrrs.',
    'wwwwwwwwwww',
    'rrkrrrrkrrs',
    'rrkrrrrkrrs',
    '.rrrrrrrrs.',
    '.rrrrmrrrs.',
    '.rr.rrr.rr.',
    'rr..rrr..rr',
    'r...rr...r.') $octoPal
  return (OutlineBmp $b $tkoOl)
}

# ---- たこ焼き1個（ソース・マヨ・青のり）。cx,cy は中心、rx,ry は半径
function Ball($b, $cx, $cy, $rx, $ry) {
  Ellipse $b $cx $cy ($rx + 0.8) ($ry + 0.8) $ol
  Ellipse $b $cx $cy $rx $ry $sauce
  Ellipse $b ($cx - 0.5) ($cy - 0.6) ($rx * 0.72) ($ry * 0.68) $sauce2
  $n = [math]::Floor($rx * 0.6)
  for ($i = -$n; $i -le $n; $i++) { Px $b ($cx - 0.5 + $i) ($cy - 0.2 + ([math]::Abs($i) % 2) * 1.0) $mayo }
  Px $b ($cx - $rx * 0.5) ($cy - $ry * 0.55) $sauceHi
  Px $b ($cx + $rx * 0.35) ($cy + $ry * 0.35) $nori
  Px $b ($cx - $rx * 0.5) ($cy + $ry * 0.15) $nori
  if ($rx -gt 4) { Px $b ($cx + $rx * 0.1) ($cy - $ry * 0.6) $nori; Px $b ($cx + $rx * 0.6) ($cy - $ry * 0.1) $nori }
}
# 舟皿（竹の舟に、たこ焼きが cols x 2 個）。$f はかつお節のゆれるコマ(0..2)、$pick なら爪楊枝つき
function TrayDims($cols, $rx, $ry) {
  $sx = [math]::Floor(2 * $rx - 0.5)
  $w = $cols * $sx + 4
  $h = [int]($ry + 3 + 1.5 * $ry + $ry + 1.5) + 3
  return @($w, $h, $sx)
}
function Tray($b, $ox, $oy, $cols, $rx, $ry, $f, $pick) {
  $d = TrayDims $cols $rx $ry; $W = $d[0]; $sx = $d[2]
  $sy = $ry * 1.5
  $backY = $oy + $ry + 3; $frontY = $backY + $sy
  $yb = [int]($backY + $ry * 0.5); $yb2 = [int]($frontY + $ry + 1.5); $yf = [int]($frontY + $ry * 0.2)
  # 舟の中（奥の壁）
  for ($y = $yb; $y -le $yb2; $y++) {
    $t = ($y - $yb) / [math]::Max(1, ($yb2 - $yb)); $ins = [int][math]::Round(2.5 * $t)
    for ($x = $ins; $x -lt $W - $ins; $x++) {
      $col = $boatIn
      if ($x -eq $ins -or $x -eq $W - 1 - $ins) { $col = $ol }
      if ($y -eq $yb) { $col = $boat2 }
      Px $b ($ox + $x) $y $col
    }
  }
  # たこ焼き（奥の列→手前の列）と、かつお節
  foreach ($row in 0, 1) {
    $cy = $backY + $row * $sy
    for ($i = 0; $i -lt $cols; $i++) {
      $cx = $ox + 2 + $sx * ($i + 0.5)
      Ball $b $cx $cy $rx $ry
    }
  }
  $k = 0
  foreach ($row in 0, 1) {
    $cy = $backY + $row * $sy
    for ($i = 0; $i -lt $cols; $i++) {
      $cx = $ox + 2 + $sx * ($i + 0.5)
      $ph = ($k + $f) % 3; $k++
      $fx = [int]($cx - 1); $fy = [int]($cy - $ry + 1)
      if ($ph -eq 0) { Px $b $fx $fy $flake; Px $b ($fx + 1) ($fy - 1) $flake; Px $b ($fx + 2) $fy $flake2 }
      elseif ($ph -eq 1) { Px $b $fx ($fy - 1) $flake; Px $b ($fx + 1) ($fy - 2) $flake; Px $b ($fx + 1) $fy $flake2 }
      else { Px $b ($fx + 1) $fy $flake; Px $b $fx ($fy - 1) $flake2; Px $b ($fx + 2) ($fy - 1) $flake }
    }
  }
  if ($pick) {
    $cx = $ox + 2 + $sx * ($cols - 0.5); $cy = $backY + $sy
    Line $b ([int]($cx + 1)) ([int]($cy - $ry * 0.4)) ([int]($cx + 4)) ([int]($cy - $ry - 4)) (C '#e6c27a')
    Px $b ([int]($cx + 4)) ([int]($cy - $ry - 5)) (C '#b8873f')
  }
  # 手前の壁（竹）
  for ($y = $yf; $y -le $yb2; $y++) {
    $t = ($y - $yb) / [math]::Max(1, ($yb2 - $yb)); $ins = [int][math]::Round(2.5 * $t)
    for ($x = $ins; $x -lt $W - $ins; $x++) {
      $col = $boat
      if ($x -eq $ins -or $x -eq $W - 1 - $ins) { $col = $ol }
      elseif ($y -eq $yf) { $col = $boat2 }
      elseif ($y -eq $yb2) { $col = $ol }
      elseif ($y -gt $yf + 1 -and (($x + $y) % 5) -eq 0) { $col = $paper2 }
      Px $b ($ox + $x) $y $col
    }
  }
}

# =====================================================================
# ---- 看板（屋根の上に掲げる）96x30。黄色い板に紺のふち、たこのキャラと紺の大きな文字
$b = NewBmp 96 30
Rect $b 14 0 2 5 $w3; Rect $b 80 0 2 5 $w3
Rect $b 0 4 96 26 $navy0; Rect $b 1 5 94 24 $navy2; Rect $b 3 7 90 20 $yel
Frame $b 4 8 88 18 $yel2
foreach ($p in @(@(0, 4), @(95, 4), @(0, 29), @(95, 29))) { Clear $b $p[0] $p[1] }
Rect $b 3 7 90 1 (C '#ffe38a')
$o = Octo16
Blit $b $o 6 8
$o.Dispose()
[void](TextPx $b 'たこ焼き' 29 10 14 $navy0 $true)
Save $b 'takoyaki_sign.png'

# ---- のぼり旗 16x78（左の棒の足元が原点）。青い布に白い縦書きと、たこ
$b = NewBmp 16 78
Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 76 $w2; Rect $b 0 2 1 76 $w3
Rect $b 2 4 13 66 $navy2; Rect $b 2 4 1 66 $navy3; Rect $b 14 4 1 66 $navy1
Rect $b 2 4 13 1 $yel
for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 70 $navy2; Px $b (2 + $i) 71 $navy1 } }
$chars = 'た', 'こ', '焼'
for ($i = 0; $i -lt 3; $i++) { [void](TextPx $b $chars[$i] 3 (6 + 12 * $i) 11 $white $false) }
$o = Octo11
Blit $b $o 2 45
$o.Dispose()
Save $b 'takoyaki_nobori.png'

# ---- 提灯 14x24。白い紙にたこのしるし
$b = NewBmp 14 24
Rect $b 6 0 1 4 $ol
Rect $b 3 4 8 2 $navy0
Ellipse $b 7 12.5 6.5 7 $paper
Ellipse $b 7 12.5 6.5 7 $paper
Rect $b 2 9 10 1 $paper2; Rect $b 1 12 12 1 $paper2; Rect $b 2 15 10 1 $paper2
Rect $b 1 8 1 8 $paper2; Rect $b 12 8 1 8 $paper2
Ascii $b 3 8 @(
  '.rrrrr.',
  'rrrrrrr',
  'rkrrrkr',
  'rrrrrrr',
  '.rrrrr.',
  '.r.r.r.',
  'r.r.r.r') @{ r = $tko; k = (C '#1b1b2b') }
Rect $b 3 18 8 2 $navy0
Rect $b 6 20 2 4 $gold
Save $b 'takoyaki_lantern.png'

# ---- のれん屋根 124x26（手前の紺ののれんに「たこ焼き」）。足元が下のへり
$RW = 124
$b = NewBmp $RW 26
for ($y = 0; $y -lt 8; $y++) {
  $inset = 8 - $y
  for ($x = $inset; $x -lt $RW - $inset; $x++) {
    $col = $navy1
    if ($y -eq 0) { $col = $navy3 }
    elseif (($x % 8) -eq 3 -and ($y % 4) -eq 2) { $col = $navy2 }
    elseif (($x % 8) -eq 7 -and ($y % 4) -eq 0) { $col = $navy2 }
    Px $b $x $y $col
  }
}
for ($x = 0; $x -lt $RW; $x++) { Px $b $x 8 $paper; Px $b $x 9 $navy0 }
$tw = 31
$names = 'た', 'こ', '焼', 'き'
for ($p = 0; $p -lt 4; $p++) {
  $x0 = $tw * $p + 1
  for ($y = 10; $y -lt 25; $y++) {
    for ($x = $x0; $x -lt $x0 + $tw - 2; $x++) {
      $col = $navy2
      if ($x -eq $x0) { $col = $navy3 } elseif ($x -eq $x0 + $tw - 3) { $col = $navy1 }
      if ($y -ge 22 -and $y -le 23) { $col = $paper }
      if ($y -eq 24) { $col = $navy0 }
      Px $b $x $y $col
    }
  }
  [void](TextPx $b $names[$p] ($x0 + [int](($tw - 2 - 13) / 2)) 10 12 $white $true)
}
Save $b 'takoyaki_roof.png'

# ---- カウンター 120x24。上の面と、紺と白の市松の前掛け
$b = NewBmp 120 24
Rect $b 0 0 120 24 $ol
Rect $b 1 1 118 8 $w1; Rect $b 1 1 118 1 $cream; Rect $b 1 8 118 1 $w2
Rect $b 1 9 118 14 $w2
for ($x = 14; $x -lt 118; $x += 15) { Rect $b $x 9 1 3 $w3 }
Rect $b 3 11 114 11 $navy2
for ($y = 11; $y -lt 22; $y++) { for ($x = 3; $x -lt 117; $x++) { if ((([math]::Floor(($x - 3) / 4) + [math]::Floor(($y - 11) / 4)) % 2) -eq 0) { Px $b $x $y (C '#e6ecfa') } } }
Rect $b 3 11 114 1 $navy3
Rect $b 3 21 114 1 $navy0
Rect $b 0 23 120 1 $ol
foreach ($p in @(@(0, 0), @(119, 0))) { Clear $b $p[0] $p[1] }
Save $b 'takoyaki_counter.png'

# ---- 柱 6x48（足元が原点）。上に紺の布をまく
$b = NewBmp 6 48
Rect $b 0 0 6 48 $ol; Rect $b 1 0 4 47 $w2; Rect $b 1 0 1 47 $w1; Rect $b 4 0 1 47 $w3
Rect $b 1 12 4 5 $navy2; Rect $b 1 12 4 1 $navy3; Rect $b 1 16 4 1 $navy0
Save $b 'takoyaki_post.png'

# ---- たこ焼き器 50x38（銅の台に鉄板、丸い穴が2列。穴ごとに焼け具合がちがう）
$b = NewBmp 50 38
Rect $b 0 26 50 12 $cop1; Rect $b 0 26 50 2 $cop2; Rect $b 0 36 50 2 $cop0
Rect $b 6 30 5 4 $red; Rect $b 6 30 5 1 $red3
Rect $b 16 30 5 4 $red; Rect $b 16 30 5 1 $red3
for ($i = 0; $i -lt 3; $i++) { Rect $b (30 + $i * 6) 30 4 5 $cop0 }
Rect $b 0 3 50 24 $iron0; Rect $b 1 4 48 20 $iron2; Rect $b 1 4 48 1 $iron3
Rect $b 0 24 50 3 $iron3; Rect $b 0 26 50 1 $iron0
$states = @(@(3, 1, 3, 2, 3), @(1, 3, 0, 1, 3))
for ($r = 0; $r -lt 2; $r++) {
  $cy = 11 + 7.5 * $r
  for ($i = 0; $i -lt 5; $i++) {
    $cx = 5.5 + 9.7 * $i
    Ellipse $b $cx $cy 4.4 3.1 $iron0
    $s = $states[$r][$i]
    if ($s -eq 0) { Ellipse $b $cx ($cy + 0.4) 3.2 2 $iron1; Px $b ($cx - 1) ($cy + 0.4) $iron3; continue }
    if ($s -eq 2) { Ellipse $b $cx ($cy - 0.6) 3.7 3 $raw; Ellipse $b ($cx + 0.3) ($cy - 0.3) 2.6 2 (C '#e8c47c'); Px $b ($cx - 1.5) ($cy - 1.6) $white; Px $b ($cx + 1) $cy $gold1; continue }
    $base = if ($s -eq 1) { $gold2 } else { $gold1 }
    Ellipse $b $cx ($cy - 0.7) 3.9 3.2 $gold3
    Ellipse $b $cx ($cy - 1) 3.5 2.9 $base
    Px $b ($cx - 1.5) ($cy - 2) $raw; Px $b ($cx - 0.5) ($cy - 2.5) $raw
    Px $b ($cx + 1.5) ($cy) $gold3; Px $b ($cx + 0.5) ($cy + 0.5) $gold3
  }
}
Save $b 'takoyaki_pan.png'

# ---- 湯気（6コマのアニメ）22x28 を横に並べる
$FW = 22
$b = NewBmp ($FW * 6) 28
for ($f = 0; $f -lt 6; $f++) {
  for ($k = 0; $k -lt 3; $k++) {
    $phase = (($f * 4) + ($k * 8)) % 24
    $t = $phase / 24.0
    $y = 25 - $phase
    $x = 11 + [math]::Sin($t * 6.28 * 1.4 + $k * 2.1) * 4 + ($k - 1) * 3
    $r = 1.8 + $t * 3.2
    $a = [int](235 * (1 - $t))
    Ellipse $b ($f * $FW + $x) $y $r ($r * 0.85) ([System.Drawing.Color]::FromArgb($a, 255, 255, 255))
    Ellipse $b ($f * $FW + $x - $r * 0.25) ($y - $r * 0.25) ($r * 0.5) ($r * 0.4) ([System.Drawing.Color]::FromArgb([int]($a * 0.9), 235, 240, 255))
  }
}
Save $b 'takoyaki_steam.png'

# ---- たこ焼きの舟皿（カウンター用: かつお節がゆれる3コマのアニメ 28x? を横に並べる）と、止まった1コマ
$d = TrayDims 4 3.5 3.2
$TW = $d[0]; $TH = $d[1]
$b = NewBmp ($TW * 3) $TH
for ($f = 0; $f -lt 3; $f++) { Tray $b ($f * $TW) 0 4 3.5 3.2 $f $true }
Save $b 'takoyaki_tray_a.png'
$b = NewBmp $TW $TH
Tray $b 0 0 4 3.5 3.2 0 $false
Save $b 'takoyaki_tray.png'
Write-Host "tray frame: ${TW}x${TH}"
# 小さい1人前（3個）の皿
$d = TrayDims 3 3 2.8
$b = NewBmp $d[0] $d[1]
Tray $b 0 0 3 3 2.8 1 $false
Save $b 'takoyaki_tray_s.png'

# ---- メニュー（紺の立て看板）48x44。足元が原点。大きなたこ焼きの絵と「たこ焼き」
$b = NewBmp 48 44
Rect $b 0 0 48 38 $ol; Rect $b 1 1 46 36 $w2; Rect $b 3 3 42 32 $navy1
Rect $b 3 3 42 1 $navy3
Rect $b 6 38 3 6 $w3; Rect $b 39 38 3 6 $w3; Rect $b 6 38 1 6 $w2; Rect $b 39 38 1 6 $w2
$tw = TextWidth 'たこ焼き' 11
[void](TextPx $b 'たこ焼き' ([math]::Floor((48 - $tw) / 2)) 5 11 (C '#ffe38a') $false)
$d = TrayDims 4 4.2 3.6
Tray $b ([int]((48 - $d[0]) / 2)) 16 4 4.2 3.6 0 $false
Save $b 'takoyaki_menu.png'

# ---- 調味料セット（ソース・マヨネーズ・青のり）と、ピックを立てた缶
$b = NewBmp 24 14
# ソース
Ascii $b 0 1 @(
  '..k..',
  '.kkk.',
  '.bbb.',
  'bbbbb',
  'brrrb',
  'brwrb',
  'brrrb',
  'bbbbb',
  'bbbbb',
  'bbbbb') @{ k = (C '#1f1f27'); b = (C '#5a3018'); r = $red; w = $white }
# マヨネーズ
Ascii $b 6 2 @(
  '..y..',
  '.yyy.',
  '.ppp.',
  'ppppp',
  'ppnpp',
  'ppnpp',
  'ppppp',
  'ppppp',
  'ppppp') @{ y = (C '#e0b020'); p = (C '#fbf3d8'); n = $navy2 }
# 青のり（ふりかけ缶）
Ascii $b 12 5 @(
  'ssss',
  'gggg',
  'gnng',
  'gnng',
  'gggg',
  'gggg') @{ s = (C '#b8b8c4'); g = $nori; n = (C '#c8f0b0') }
$b2 = OutlineBmp $b $ol
Save $b2 'takoyaki_condi.png'

# ---- ピック(千枚通し)立て
$b = NewBmp 8 14
Rect $b 1 7 6 6 (C '#8d93a8'); Rect $b 1 7 6 1 (C '#d4d8e6'); Rect $b 1 12 6 1 (C '#5a5f74')
Line $b 2 7 1 2 (C '#e4e8f2'); Line $b 5 7 6 3 (C '#e4e8f2'); Line $b 3 7 3 3 (C '#e4e8f2')
Rect $b 1 0 1 3 (C '#c98a4a'); Rect $b 6 1 1 3 (C '#c98a4a'); Rect $b 3 0 1 3 (C '#c98a4a')
$b2 = OutlineBmp $b $ol
Save $b2 'takoyaki_picks.png'

# ---- たこのマスコット（台つき）20x26
$b = NewBmp 20 26
$o = Octo16
Blit $b $o 1 0
$o.Dispose()
Rect $b 1 18 18 8 $ol; Rect $b 2 19 16 6 $w2; Rect $b 2 19 16 1 $w1; Rect $b 2 24 16 1 $w3
Rect $b 4 21 12 3 $navy2; Rect $b 4 21 12 1 $navy3
Save $b 'takoyaki_mascot.png'

# ---- 床のマット 60x22（紺に白いふち）
$b = NewBmp 60 22
Rect $b 0 0 60 22 $navy0; Rect $b 2 2 56 18 $paper; Rect $b 4 4 52 14 $navy2
for ($y = 4; $y -lt 18; $y++) { for ($x = 4; $x -lt 56; $x++) { if ((($x + $y) % 8) -eq 0 -and ($y % 2) -eq 0) { Px $b $x $y $navy3 } } }
for ($i = 0; $i -lt 4; $i++) { Rect $b (10 + $i * 12) 9 5 1 $paper; Rect $b (12 + $i * 12) 7 1 5 $paper }
foreach ($p in @(@(0, 0), @(59, 0), @(0, 21), @(59, 21))) { Clear $b $p[0] $p[1] }
Save $b 'takoyaki_mat.png'
