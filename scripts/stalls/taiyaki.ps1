# たい焼き屋台の専用ドット絵（看板・のぼり・提灯・黒板メニュー・焼き台・炎アニメ・たい焼き・トレー・紙袋・あんこ鉢・カウンター・日よけ・柱・縁台・敷物）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/taiyaki.ps1   （リポジトリのルートで）
# 出力: client/public/brand/stall/taiyaki_*.png（原点は足元。配置は scripts/stalls/taiyaki.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル。文字は MS Gothic を1bitでドットにして貼る。
. "$PSScriptRoot\..\lib\pixel.ps1"

# 色（共通色に、たい焼き屋の藍色と焼き色を足す）
$navy0 = C '#1b2347'; $navy = C '#2b3a6b'; $navy2 = C '#4663a8'; $navy3 = C '#7d95cf'
$yaki0 = C '#6b3410'; $yaki = C '#d98a2b'; $yaki2 = C '#f0b64e'; $yaki3 = C '#a85f1d'; $yakiL = C '#f9d98a'
$batter = C '#f4dfa0'; $eye = C '#2a1408'
$anko = C '#5a1f33'; $anko2 = C '#8a3a52'; $cust = C '#f7d450'; $cust2 = C '#fff0a0'
$kraft = C '#d9b27c'; $kraft2 = C '#b98d55'; $kraft3 = C '#f0d4a4'
$fl0 = C '#d6381f'; $fl1 = C '#f58a1f'; $fl2 = C '#ffd23f'; $fl3 = C '#fff4b0'
$board = C '#2f5a45'; $chalk = C '#f4f2e8'

# 別の絵を重ねる（透明は無視）
function Blit($dst, $src, $x, $y) {
  for ($j = 0; $j -lt $src.Height; $j++) { for ($i = 0; $i -lt $src.Width; $i++) { $c = $src.GetPixel($i, $j); if ($c.A -ge 128) { Px $dst ($x + $i) ($y + $j) $c } } }
}

# たい焼き 18x10（頭が左、尾が右）。$b の ($x,$y) を左上にして描く。$baked=$false なら生地のまま（色が薄い）
function Fish($b, $x, $y, $baked) {
  $out = $yaki0
  $c1 = if ($baked) { $yaki2 } else { $batter }
  $c2 = if ($baked) { $yaki } else { C '#ecd088' }
  $c3 = if ($baked) { $yaki3 } else { C '#cfae62' }
  # 尾びれ（外形）
  for ($i = 0; $i -lt 5; $i++) {
    $h = [math]::Floor(1 + $i * 0.9)
    for ($j = 5 - $h - 1; $j -le 5 + $h; $j++) { Px $b ($x + 13 + $i) ($y + $j) $out }
  }
  Ellipse $b ($x + 7.5) ($y + 5) 7.9 4.9 $out
  # 内側
  for ($i = 0; $i -lt 5; $i++) {
    $h = [math]::Floor(1 + $i * 0.9)
    for ($j = 5 - $h; $j -le 5 + $h - 1; $j++) { Px $b ($x + 13 + $i) ($y + $j) $c2 }
  }
  Clear $b ($x + 17) ($y + 5); Clear $b ($x + 17) ($y + 4)
  Px $b ($x + 17) ($y + 3) $out; Px $b ($x + 17) ($y + 6) $out
  Ellipse $b ($x + 7.5) ($y + 5) 6.9 3.9 $c2
  Ellipse $b ($x + 7.2) ($y + 4.4) 6.2 3.0 $c1
  # 背びれ・腹の影
  for ($i = 5; $i -le 10; $i++) { Px $b ($x + $i) ($y + 8) $c3 }
  for ($i = 6; $i -le 9; $i++) { Px $b ($x + $i) ($y + 1) $c3 }
  # えら・うろこ
  foreach ($p in @(@(5, 3), @(5, 4), @(5, 5), @(5, 6))) { Px $b ($x + $p[0]) ($y + $p[1]) $c3 }
  foreach ($cx in @(8, 11)) { Px $b ($x + $cx) ($y + 3) $c3; Px $b ($x + $cx + 1) ($y + 4) $c3; Px $b ($x + $cx) ($y + 5) $c3 }
  # 目
  Px $b ($x + 3) ($y + 4) $eye; Px $b ($x + 3) ($y + 3) $c1
}

# ---- 看板（屋根の上に掲げる）108x30。藍の板に金のふち、白い大きな「たい焼き」と左右のたい焼き
$b = NewBmp 108 30
Rect $b 16 0 2 5 $w3; Rect $b 90 0 2 5 $w3
Rect $b 0 4 108 26 $ol; Rect $b 1 5 106 24 $w2; Rect $b 3 7 102 20 $navy
Frame $b 4 8 100 18 $gold
foreach ($p in @(@(0, 4), @(107, 4), @(0, 29), @(107, 29))) { Clear $b $p[0] $p[1] }
Rect $b 3 7 102 1 $navy2
$f = NewBmp 18 10; Fish $f 0 0 $true
Blit $b $f 9 12
$f.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
Blit $b $f 81 12
$f.Dispose()
$tw = TextWidth 'たい焼き' 13
[void](TextPx $b 'たい焼き' ([math]::Floor((108 - $tw) / 2)) 12 13 $white $true)
Save $b 'taiyaki_sign.png'

# ---- のぼり旗 16x78（左の棒の足元が原点）。藍の布に白い縦書きと、たい焼き
$b = NewBmp 16 78
Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 76 $w2; Rect $b 0 2 1 76 $w3
Rect $b 2 4 13 68 $navy; Rect $b 2 4 1 68 $navy0; Rect $b 14 4 1 68 $navy0
for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 72 $navy; Px $b (2 + $i) 73 $navy0 } }
$chars = 'た', 'い', '焼', 'き'
for ($i = 0; $i -lt 4; $i++) { [void](TextPx $b $chars[$i] 3 (6 + 12 * $i) 11 $white $false) }
$f = NewBmp 18 10; Fish $f 0 0 $true
$f.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone)
Blit $b $f 4 54
$f.Dispose()
Save $b 'taiyaki_nobori.png'

# ---- 提灯 12x22（橙色）
$b = NewBmp 12 22
Rect $b 5 0 1 4 $ol
Rect $b 3 4 6 2 $ol
Ellipse $b 6 11.5 5.5 6 (C '#f08a2c')
Rect $b 2 8 8 1 (C '#c25a14'); Rect $b 1 11 10 1 (C '#c25a14'); Rect $b 2 14 8 1 (C '#c25a14')
Rect $b 3 7 2 6 (C '#ffc766')
Rect $b 3 17 6 2 $ol
Rect $b 5 19 2 3 $navy2
Save $b 'taiyaki_lantern.png'

# ---- メニュー（黒板の立て看板）64x50。足元が原点
$b = NewBmp 64 50
Rect $b 0 0 64 44 $ol; Rect $b 1 1 62 42 $w2; Rect $b 3 3 58 38 $board
Rect $b 8 44 3 6 $w3; Rect $b 53 44 3 6 $w3
Rect $b 8 44 1 6 $w2; Rect $b 53 44 1 6 $w2
$items = 'あんこ', 'クリーム', 'チョコ'
for ($i = 0; $i -lt 3; $i++) {
  $col = if ($i -eq 0) { C '#ffe14a' } else { $chalk }
  $sz = 12
  $w = TextWidth $items[$i] $sz
  [void](TextPx $b $items[$i] ([math]::Floor((64 - $w) / 2)) (5 + 12 * $i) $sz $col $false)
}
Save $b 'taiyaki_menu.png'

# ---- 焼き台 52x24（たい焼き器。4つの型と木の持ち手、下は炎が見える火口）。足元が原点
$b = NewBmp 52 24
# 火口の箱
Rect $b 1 12 50 12 $iron1; Rect $b 1 12 50 1 $iron2; Rect $b 1 22 50 2 $iron0
Rect $b 5 14 42 8 $iron0; Frame $b 4 13 44 10 $iron2
Rect $b 48 15 3 3 $red; Rect $b 48 15 1 1 $red3
# 型の板
Rect $b 0 3 52 10 $iron0; Rect $b 1 4 50 8 $iron2; Rect $b 1 4 50 1 $iron3
foreach ($mx in @(2, 14, 26, 38)) {
  Rect $b $mx 0 2 5 $w2; Px $b $mx 0 $w1; Px $b ($mx + 1) 0 $w1       # 持ち手
  Rect $b ($mx + 1) 5 11 6 $iron0                                   # 型のへこみ
  Ellipse $b ($mx + 5.5) 8 4.6 2.8 $iron1
}
# 焼けたものと生地のもの
function MiniFish($b, $x, $y, $baked) {
  $c1 = if ($baked) { $yaki2 } else { $batter }
  $c2 = if ($baked) { $yaki } else { C '#ecd088' }
  Ellipse $b ($x + 4.5) ($y + 3) 4.6 2.8 $c2
  Ellipse $b ($x + 4.2) ($y + 2.5) 3.8 1.8 $c1
  Rect $b ($x + 9) ($y + 2) 1 2 $c2; Rect $b ($x + 10) ($y + 1) 1 4 $c2; Rect $b ($x + 11) ($y + 1) 1 1 $c2; Rect $b ($x + 11) ($y + 4) 1 1 $c2
  Px $b ($x + 1) ($y + 2) $eye
}
MiniFish $b 3 5 $true
MiniFish $b 15 5 $true
MiniFish $b 27 5 $false
MiniFish $b 39 5 $false
Save $b 'taiyaki_grill.png'

# ---- 炎（4コマのアニメ。1コマ 40x8 を横に4つ。足元が原点）
$b = NewBmp 160 8
$heights = @(@(5, 7, 4, 6, 5), @(7, 5, 6, 4, 7), @(4, 6, 7, 5, 4), @(6, 4, 5, 7, 6))
for ($fr = 0; $fr -lt 4; $fr++) {
  for ($i = 0; $i -lt 5; $i++) {
    $h = $heights[$fr][$i]; $cx = $fr * 40 + 4 + $i * 8
    for ($j = 0; $j -lt $h; $j++) {
      $y = 7 - $j
      $half = [math]::Max(0, [math]::Round(3.2 * (1 - $j / $h)))
      Rect $b ($cx - $half) $y (2 * $half + 1) 1 $(if ($j -ge $h - 2) { $fl0 } else { $fl1 })
      if ($j -lt $h - 2) { $ih = [math]::Max(0, $half - 1); Rect $b ($cx - $ih) $y (2 * $ih + 1) 1 $(if ($j -lt 2) { $fl3 } else { $fl2 }) }
    }
  }
}
Save $b 'taiyaki_flame.png'

# ---- たい焼き（皿に置く1匹）18x10
$b = NewBmp 18 10
Fish $b 0 0 $true
Save $b 'taiyaki_fish.png'

# ---- トレー（焼きたてを並べた木のトレー）40x18。足元が原点
$b = NewBmp 34 18
Fish $b 0 3 $true
Fish $b 8 1 $true
Fish $b 16 3 $true
Rect $b 0 10 34 8 $ol; Rect $b 1 11 32 6 $w2; Rect $b 1 11 32 1 $w1; Rect $b 1 16 32 1 $w3
Rect $b 0 9 34 1 $w3
foreach ($p in @(@(0, 17), @(33, 17))) { Clear $b $p[0] $p[1] }
Save $b 'taiyaki_tray.png'

# ---- 紙袋（たい焼きが顔を出す）14x17。足元が原点
$b = NewBmp 14 17
$f = NewBmp 12 6
Ellipse $f 4.5 3 4.8 2.9 $yaki
Ellipse $f 4.2 2.5 4 1.9 $yaki2
Rect $f 9 2 1 2 $yaki; Rect $f 10 1 1 4 $yaki; Rect $f 11 1 1 1 $yaki; Rect $f 11 4 1 1 $yaki
Px $f 1 2 $eye
$f.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone)
Blit $b $f 3 0
$f.Dispose()
Rect $b 0 6 14 11 $ol; Rect $b 1 7 12 9 $kraft; Rect $b 1 7 12 1 $kraft3; Rect $b 1 15 12 1 $kraft2
Rect $b 1 7 1 9 $kraft3; Rect $b 12 7 1 9 $kraft2
Rect $b 1 10 12 2 $navy; Rect $b 1 10 12 1 $navy2
foreach ($p in @(@(0, 6), @(13, 6), @(0, 16), @(13, 16))) { Clear $b $p[0] $p[1] }
Save $b 'taiyaki_bag.png'

# ---- あんこ鉢 10x9 とカスタード鉢 10x9
foreach ($v in @(@('anko', $anko, $anko2), @('custard', $cust, $cust2))) {
  $b = NewBmp 10 9
  Ellipse $b 5 5.5 5 3.4 (C '#aeb4c8'); Ellipse $b 5 5 5 3.2 $white
  Ellipse $b 5 4.3 3.8 2.2 $v[1]
  Px $b 3 3 $v[2]; Px $b 4 3 $v[2]; Px $b 6 4 $v[2]
  Save $b ("taiyaki_{0}.png" -f $v[0])
}

# ---- カウンター 104x24。上の面(明るい木)と、藍の布の前掛け（青海波もよう）
$b = NewBmp 104 24
Rect $b 0 0 104 24 $ol
Rect $b 1 1 102 8 $w1; Rect $b 1 1 102 1 $cream; Rect $b 1 8 102 1 $w2
Rect $b 1 9 102 14 $w2
for ($x = 13; $x -lt 102; $x += 13) { Rect $b $x 9 1 6 $w3 }
Rect $b 3 12 98 9 $navy
Rect $b 3 12 98 1 $navy2
for ($x = 3; $x -lt 101; $x++) {
  $col = ($x - 3) % 8
  foreach ($base in @(16, 20)) {
    $off = if ($base -eq 20) { 4 } else { 0 }
    $cc = (($x - 3 + $off) % 8)
    $d = [math]::Sqrt([math]::Max(0, 16 - ($cc - 3.5) * ($cc - 3.5)))
    $yy = $base - [math]::Round($d)
    if ($yy -ge 13 -and $yy -le 20) { Px $b $x $yy $navy3 }
  }
}
Rect $b 3 21 98 1 $navy0
Rect $b 0 23 104 1 $ol
foreach ($p in @(@(0, 0), @(103, 0))) { Clear $b $p[0] $p[1] }
Save $b 'taiyaki_counter.png'

# ---- 屋根の日よけ（藍と白のしま）108x24。手前のへりはぎざぎざ
$b = NewBmp 108 24
for ($y = 0; $y -lt 10; $y++) {
  $inset = [int](9 - $y)
  for ($x = $inset; $x -lt 108 - $inset; $x++) { $stripe = [math]::Floor($x / 9) % 2; Px $b $x $y $(if ($stripe -eq 0) { $navy } else { $white }) }
}
for ($x = 0; $x -lt 108; $x++) { Px $b $x 9 $navy0 }
for ($y = 10; $y -lt 22; $y++) {
  for ($x = 0; $x -lt 108; $x++) {
    $stripe = [math]::Floor($x / 9) % 2
    $col = if ($stripe -eq 0) { $navy } else { $white }
    $mid = ($x % 9) - 4
    if ($y -ge 17) {
      $dy = $y - 17; $lim = [math]::Sqrt([math]::Max(0, 25 - $mid * $mid))
      if ($dy -gt $lim) { continue }
    }
    Px $b $x $y $col
  }
}
for ($x = 0; $x -lt 108; $x++) { if ((($x / 9) -as [int]) % 2 -eq 0) { Px $b $x 10 $navy2 } }
Rect $b 0 10 1 8 $navy0; Rect $b 107 10 1 8 $navy0
Save $b 'taiyaki_roof.png'

# ---- 柱 6x48（足元が原点）
$b = NewBmp 6 48
Rect $b 0 0 6 48 $ol; Rect $b 1 0 4 47 $w2; Rect $b 1 0 1 47 $w1; Rect $b 4 0 1 47 $w3
Save $b 'taiyaki_post.png'

# ---- お皿にのせたたい焼き 16x10
$b = NewBmp 16 10
Ellipse $b 8 6 8 4 (C '#aeb4c8'); Ellipse $b 8 5.5 8 3.8 $white
MiniFish $b 2 2 $true
Save $b 'taiyaki_plate.png'

# ---- 敷物（藍に白ふち、中央にたい焼き）40x28
$b = NewBmp 40 28
Rect $b 0 0 40 28 $navy0; Rect $b 1 1 38 26 $navy; Frame $b 3 3 34 22 $navy3
for ($x = 6; $x -lt 36; $x += 6) { Px $b $x 5 $navy2; Px $b $x 22 $navy2 }
Fish $b 11 9 $true
foreach ($p in @(@(0, 0), @(39, 0), @(0, 27), @(39, 27))) { Clear $b $p[0] $p[1] }
Save $b 'taiyaki_mat.png'
