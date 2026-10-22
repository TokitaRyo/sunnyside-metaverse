# 大判焼き屋台の専用ドット絵（光る看板・のぼり・提灯・黒板メニュー・丸い型の焼き型アニメ・炎アニメ・焼き上がりの山・お皿・紙袋・生地のボウル・お玉・カウンター・日よけ・柱・敷物）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/obanyaki.ps1   （リポジトリのルートで）
#   一部だけ作り直す: $env:OBANYAKI_ONLY='sign|grill'   （名前の正規表現。空なら全部）
# 出力: client/public/brand/stall/obanyaki_*.png（原点は足元。配置は scripts/stalls/obanyaki.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル。文字は MS Gothic を1bitでドットにして貼る。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Want($n) { return (-not $env:OBANYAKI_ONLY) -or ($n -match $env:OBANYAKI_ONLY) }

# 色（共通色に、大判焼き屋の深緑と焼き色を足す）
$gr0 = C '#16392a'; $gr1 = C '#25704a'; $gr2 = C '#3f9c68'; $gr3 = C '#9ad6a9'
$yk0 = C '#5c2e0e'; $yk3 = C '#a85f1d'; $yk1 = C '#d98a2b'; $yk2 = C '#f0b64e'; $ykL = C '#fbe3a0'
$batter = C '#f4dfa0'; $batter2 = C '#fff4c4'; $paleG = C '#e8c07a'
$kraft = C '#d9b27c'; $kraft2 = C '#b98d55'; $kraft3 = C '#f0d4a4'
$fl0 = C '#d6381f'; $fl1 = C '#f58a1f'; $fl2 = C '#ffd23f'; $fl3 = C '#fff4b0'
$board = C '#2f5a45'

# 別の絵を重ねる（透明は無視）
function Blit($dst, $src, $x, $y) {
  for ($j = 0; $j -lt $src.Height; $j++) { for ($i = 0; $i -lt $src.Width; $i++) { $c = $src.GetPixel($i, $j); if ($c.A -ge 128) { Px $dst ($x + $i) ($y + $j) $c } } }
}

# 大判焼き（丸くて厚みのある円盤）。($cx,$cy) が上面の中心、$th が厚み。$baked=$false なら生地の色
function Cake($b, $cx, $cy, $rx, $ry, $th, $baked) {
  $c1 = if ($baked) { $yk2 } else { $batter }
  $c2 = if ($baked) { $yk1 } else { C '#ecd088' }
  $c3 = if ($baked) { $yk3 } else { C '#cfae62' }
  for ($t = $th; $t -ge 0; $t--) { Ellipse $b $cx ($cy + $t) ($rx + 0.9) ($ry + 0.9) $yk0 }
  for ($t = $th; $t -ge 1; $t--) { Ellipse $b $cx ($cy + $t) $rx $ry $c3 }
  Ellipse $b $cx $cy $rx $ry $c2
  Ellipse $b $cx ($cy - 0.3) ($rx - 1.2) ($ry - 0.9) $c1
  if ($rx -ge 5) {
    Ellipse $b $cx ($cy + 0.2) ($rx * 0.38) ($ry * 0.38) $c2
    Px $b ($cx - $rx * 0.45) ($cy - $ry * 0.4) $ykL
    Px $b ($cx - $rx * 0.45 + 1) ($cy - $ry * 0.4) $ykL
  }
}

# ---- 看板（屋根の上に掲げる）120x34 を2コマ。金の電球が交互にまたたく
if (Want 'sign') {
  $sheet = NewBmp 240 34
  $tw = TextWidth '大判焼き' 16
  for ($fr = 0; $fr -lt 2; $fr++) {
    $ox = $fr * 120
    Rect $sheet ($ox + 18) 0 2 5 $w3; Rect $sheet ($ox + 100) 0 2 5 $w3
    Rect $sheet $ox 4 120 30 $ol; Rect $sheet ($ox + 1) 5 118 28 $w2; Rect $sheet ($ox + 3) 7 114 24 $gr1
    Frame $sheet ($ox + 4) 8 112 22 $gold
    foreach ($p in @(@(0, 4), @(119, 4), @(0, 33), @(119, 33))) { Clear $sheet ($ox + $p[0]) $p[1] }
    Rect $sheet ($ox + 3) 7 114 1 $gr2
    # 電球（金のふちの上）
    for ($i = 0; $i -lt 18; $i++) {
      $bx = $ox + 7 + $i * 6
      $lit = (($i + $fr) % 2 -eq 0)
      $col = if ($lit) { $fl3 } else { C '#a8842f' }
      Rect $sheet $bx 8 2 1 $col; Rect $sheet $bx 29 2 1 $col
      if ($lit) { Px $sheet $bx 7 $fl2; Px $sheet ($bx + 1) 30 $fl2 }
    }
    # 左右の大判焼き
    Cake $sheet ($ox + 16) 17 6 4.6 2 $true
    Cake $sheet ($ox + 104) 17 6 4.6 2 $true
    [void](TextPx $sheet '大判焼き' ($ox + [math]::Floor((120 - $tw) / 2)) 11 16 $white $true)
  }
  Save $sheet 'obanyaki_sign.png'
}

# ---- のぼり旗 16x78（左の棒の足元が原点）。緑の布に白い縦書きと大判焼き
if (Want 'nobori') {
  $b = NewBmp 16 78
  Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 76 $w2; Rect $b 0 2 1 76 $w3
  Rect $b 2 4 13 68 $gr1; Rect $b 2 4 1 68 $gr0; Rect $b 14 4 1 68 $gr0
  for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 72 $gr1; Px $b (2 + $i) 73 $gr0 } }
  $chars = '大', '判', '焼', 'き'
  for ($i = 0; $i -lt 4; $i++) { [void](TextPx $b $chars[$i] 3 (6 + 12 * $i) 11 $white $false) }
  Cake $b 8.5 61 5 3.8 2 $true
  Save $b 'obanyaki_nobori.png'
}

# ---- 提灯 12x22（山吹色）
if (Want 'lantern') {
  $b = NewBmp 12 22
  Rect $b 5 0 1 4 $ol
  Rect $b 3 4 6 2 $ol
  Ellipse $b 6 11.5 5.5 6 (C '#f2b02f')
  Rect $b 2 8 8 1 (C '#c27a14'); Rect $b 1 11 10 1 (C '#c27a14'); Rect $b 2 14 8 1 (C '#c27a14')
  Rect $b 3 7 2 6 (C '#ffe08a')
  Rect $b 3 17 6 2 $ol
  Rect $b 5 19 2 3 $gr2
  Save $b 'obanyaki_lantern.png'
}

# ---- メニュー（黒板の立て看板）64x50。足元が原点
if (Want 'menu') {
  $b = NewBmp 64 50
  Rect $b 0 0 64 44 $ol; Rect $b 1 1 62 42 $w2; Rect $b 3 3 58 38 $board
  Rect $b 8 44 3 6 $w3; Rect $b 53 44 3 6 $w3
  Rect $b 8 44 1 6 $w2; Rect $b 53 44 1 6 $w2
  # 品書きの中身(味・種類)は書かない。文字は「メニュー」だけ。何の店かは大きな大判焼きの絵で伝える
  $tw = TextWidth 'メニュー' 11
  [void](TextPx $b 'メニュー' ([math]::Floor((64 - $tw) / 2)) 4 11 (C '#ffe14a') $true)
  Cake $b 22 31 10 5.5 3 $true
  Cake $b 42 31 10 5.5 3 $true
  Cake $b 32 23 10 5.5 3 $true
  Save $b 'obanyaki_menu.png'
}

# ---- 焼き型の鉄板（丸い型が2列×6つ）56x32 を4コマ。生地を流す→焼ける→焼き上がる、が順にめぐる。足元が原点
function Mold($b, $cx, $cy, $s) {
  Ellipse $b $cx ($cy + 0.3) 4.7 2.9 $iron0
  Ellipse $b $cx $cy 4.3 2.6 $iron3
  switch ($s) {
    0 { Ellipse $b $cx ($cy + 0.2) 3.4 1.8 $iron0; Px $b ($cx - 1) ($cy - 1) $iron2; Px $b $cx ($cy - 1) $iron2 }
    1 {
      Ellipse $b $cx ($cy + 0.2) 3.4 1.8 $batter; Px $b ($cx - 1) ($cy - 1) $batter2
      Rect $b $cx ($cy - 5) 1 4 $batter; Px $b $cx ($cy - 6) $batter2
    }
    2 {
      Ellipse $b $cx ($cy - 0.6) 3.7 2.3 $paleG; Ellipse $b $cx ($cy - 1.1) 2.7 1.5 $batter; Px $b ($cx - 1) ($cy - 2) $batter2
    }
    3 {
      Ellipse $b $cx ($cy - 1.4) 4.2 3.0 $yk3; Ellipse $b $cx ($cy - 1.9) 3.6 2.4 $yk1; Ellipse $b $cx ($cy - 2.3) 2.6 1.6 $yk2
      Px $b ($cx - 1) ($cy - 3) $ykL; Px $b $cx ($cy - 3) $ykL
    }
  }
}
if (Want 'grill') {
  $sheet = NewBmp 224 32
  for ($fr = 0; $fr -lt 4; $fr++) {
    $ox = $fr * 56
    # 下の箱（火口）
    Rect $sheet $ox 20 56 12 $iron1; Rect $sheet $ox 20 56 1 $iron2; Rect $sheet $ox 30 56 2 $iron0
    Rect $sheet ($ox + 4) 24 48 6 $iron0; Frame $sheet ($ox + 3) 23 50 8 $iron2
    # 型の板
    Rect $sheet $ox 3 56 17 $iron0; Rect $sheet ($ox + 1) 4 54 15 $iron2; Rect $sheet ($ox + 1) 4 54 1 $iron3
    Rect $sheet ($ox + 1) 18 54 1 $iron1
    # 型（奥の列 → 手前の列の順に描く）
    for ($row = 0; $row -lt 2; $row++) {
      $cy = 9 + $row * 6
      for ($i = 0; $i -lt 6; $i++) {
        $s = ($i + 2 * $row + $fr) % 4
        Mold $sheet ($ox + 6 + $i * 9) $cy $s
      }
    }
  }
  Save $sheet 'obanyaki_grill.png'
}

# ---- 炎（4コマのアニメ。1コマ 48x8 を横に4つ。足元が原点）
if (Want 'flame') {
  $b = NewBmp 192 8
  $heights = @(@(5, 7, 4, 6, 5, 7), @(7, 5, 6, 4, 7, 5), @(4, 6, 7, 5, 4, 6), @(6, 4, 5, 7, 6, 4))
  for ($fr = 0; $fr -lt 4; $fr++) {
    for ($i = 0; $i -lt 6; $i++) {
      $h = $heights[$fr][$i]; $cx = $fr * 48 + 4 + $i * 8
      for ($j = 0; $j -lt $h; $j++) {
        $y = 7 - $j
        $half = [math]::Max(0.0, [math]::Round(3.2 * (1 - $j / $h)))
        Rect $b ($cx - $half) $y (2 * $half + 1) 1 $(if ($j -ge $h - 2) { $fl0 } else { $fl1 })
        if ($j -lt $h - 2) { $ih = [math]::Max(0.0, $half - 1); Rect $b ($cx - $ih) $y (2 * $ih + 1) 1 $(if ($j -lt 2) { $fl3 } else { $fl2 }) }
      }
    }
  }
  Save $b 'obanyaki_flame.png'
}

# ---- 焼き上がりの山（3段に積んだ大判焼き）28x25。足元が原点
if (Want 'pile') {
  $b = NewBmp 28 25
  Rect $b 1 21 26 3 $ol; Rect $b 2 21 24 2 $w1; Rect $b 2 23 24 1 $w2; Rect $b 1 24 26 1 $ol
  Cake $b 14 5.5 5.6 3.6 2 $true
  Cake $b 9 11.5 5.6 3.6 2 $true
  Cake $b 19 11.5 5.6 3.6 2 $true
  Cake $b 6 17 5.6 3.6 2 $true
  Cake $b 14 17.5 5.6 3.6 2 $true
  Cake $b 22 17 5.6 3.6 2 $true
  Save $b 'obanyaki_pile.png'
}

# ---- お皿にのせた大判焼き 16x10
if (Want 'plate') {
  $b = NewBmp 16 10
  Ellipse $b 8 6 8 4 (C '#aeb4c8'); Ellipse $b 8 5.5 8 3.8 $white
  Cake $b 8 4 4.6 2.8 1.5 $true
  Save $b 'obanyaki_plate.png'
}

# ---- 紙袋（大判焼きが顔を出す）14x17。足元が原点
if (Want 'bag') {
  $b = NewBmp 14 17
  Cake $b 7 4 5.2 3.2 2 $true
  Rect $b 0 6 14 11 $ol; Rect $b 1 7 12 9 $kraft; Rect $b 1 7 12 1 $kraft3; Rect $b 1 15 12 1 $kraft2
  Rect $b 1 7 1 9 $kraft3; Rect $b 12 7 1 9 $kraft2
  Rect $b 1 10 12 2 $gr1; Rect $b 1 10 12 1 $gr2
  foreach ($p in @(@(0, 6), @(13, 6), @(0, 16), @(13, 16))) { Clear $b $p[0] $p[1] }
  Save $b 'obanyaki_bag.png'
}

# ---- 生地のボウル（お玉つき）20x15。足元が原点
if (Want 'bowl') {
  $b = NewBmp 20 15
  Ellipse $b 9 9 8.8 5 (C '#5b6fae'); Ellipse $b 9 8.4 8.6 4.7 (C '#7d95cf')
  Rect $b 1 6 16 3 (C '#7d95cf')
  Ellipse $b 9 5.5 8.8 3.6 (C '#5b6fae'); Ellipse $b 9 5.2 8.2 3.1 $white
  Ellipse $b 9 5.6 7 2.4 $batter; Ellipse $b 8 5.2 3.5 1.2 $batter2
  Ellipse $b 9 13 5 1.5 (C '#4663a8')
  # お玉の柄
  Line $b 11 5 18 0 $w3
  Line $b 12 5 19 1 $w2
  Save $b 'obanyaki_bowl.png'
}

# ---- お玉（置いてある）16x8。足元が原点
if (Want 'ladle') {
  $b = NewBmp 16 8
  Ellipse $b 4 4 3.8 3 $iron0; Ellipse $b 4 4 3.2 2.5 $iron3; Ellipse $b 4 4 2.4 1.7 $batter
  Line $b 7 3 15 1 $iron1
  Line $b 7 4 15 2 $iron2
  Save $b 'obanyaki_ladle.png'
}

# ---- カウンター 124x24。上の面(明るい木)と、深緑の布の前掛け（丸もよう）
if (Want 'counter') {
  $b = NewBmp 124 24
  Rect $b 0 0 124 24 $ol
  Rect $b 1 1 122 8 $w1; Rect $b 1 1 122 1 $cream; Rect $b 1 8 122 1 $w2
  Rect $b 1 9 122 14 $w2
  for ($x = 13; $x -lt 122; $x += 13) { Rect $b $x 9 1 6 $w3 }
  Rect $b 3 12 118 9 $gr1
  Rect $b 3 12 118 1 $gr2
  for ($x = 7; $x -lt 120; $x += 8) {
    Ellipse $b $x 16.5 3.2 3.2 $gr3
    Ellipse $b $x 16.5 2.3 2.3 $gr1
    Px $b ($x - 1) 15 $gr3
  }
  Rect $b 3 21 118 1 $gr0
  Rect $b 0 23 124 1 $ol
  foreach ($p in @(@(0, 0), @(123, 0))) { Clear $b $p[0] $p[1] }
  Save $b 'obanyaki_counter.png'
}

# ---- 屋根の日よけ（緑と白のしま）136x24。手前のへりはぎざぎざ
if (Want 'roof') {
  $b = NewBmp 136 24
  for ($y = 0; $y -lt 10; $y++) {
    $inset = [int](9 - $y)
    for ($x = $inset; $x -lt 136 - $inset; $x++) { $stripe = [math]::Floor($x / 8) % 2; Px $b $x $y $(if ($stripe -eq 0) { $gr1 } else { $white }) }
  }
  for ($x = 0; $x -lt 136; $x++) { Px $b $x 9 $gr0 }
  for ($y = 10; $y -lt 22; $y++) {
    for ($x = 0; $x -lt 136; $x++) {
      $stripe = [math]::Floor($x / 8) % 2
      $col = if ($stripe -eq 0) { $gr1 } else { $white }
      $mid = ($x % 8) - 3.5
      if ($y -ge 17) {
        $dy = $y - 17; $lim = [math]::Sqrt([math]::Max(0.0, 20.25 - $mid * $mid))
        if ($dy -gt $lim) { continue }
      }
      Px $b $x $y $col
    }
  }
  for ($x = 0; $x -lt 136; $x++) { if ((([math]::Floor($x / 8)) % 2) -eq 0) { Px $b $x 10 $gr2 } }
  Rect $b 0 10 1 8 $gr0; Rect $b 135 10 1 8 $gr0
  Save $b 'obanyaki_roof.png'
}

# ---- 柱 6x48（足元が原点）
if (Want 'post') {
  $b = NewBmp 6 48
  Rect $b 0 0 6 48 $ol; Rect $b 1 0 4 47 $w2; Rect $b 1 0 1 47 $w1; Rect $b 4 0 1 47 $w3
  Save $b 'obanyaki_post.png'
}

# ---- 敷物（深緑に白ふち、中央に大判焼き）40x28
if (Want 'mat') {
  $b = NewBmp 40 28
  Rect $b 0 0 40 28 $gr0; Rect $b 1 1 38 26 $gr1; Frame $b 3 3 34 22 $gr3
  for ($x = 6; $x -lt 36; $x += 6) { Px $b $x 5 $gr2; Px $b $x 22 $gr2 }
  Cake $b 20 12 8 5.5 2.5 $true
  foreach ($p in @(@(0, 0), @(39, 0), @(0, 27), @(39, 27))) { Clear $b $p[0] $p[1] }
  Save $b 'obanyaki_mat.png'
}
