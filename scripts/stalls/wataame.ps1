# わたあめ屋台の専用ドット絵を作る（看板・のぼり・屋根・柱・カウンター・わたあめ機(回る)・わたあめの台・袋入りわたあめの棚・ざらめの瓶・メニュー・マット・風船(ゆれる)・キラキラ）。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/wataame.ps1
# 出力: client/public/brand/stall/wataame_*.png（原点は各スプライトの足元。配置は scripts/stalls/wataame.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル。色や文字を変えたいときはここを直して作り直す。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（パステル: ピンク・水色・黄・むらさき）
$ol2 = C '#4a3560'; $ol3 = C '#6b5a95'
$wd1 = C '#f0cf9c'; $wd2 = C '#d19a5e'; $wd3 = C '#8c5a3a'
$lil = C '#c9a8f2'; $lilD = C '#9a78d0'; $lilL = C '#e6d4fb'
$sky = C '#7fcdf5'; $skyL = C '#a8e0fb'; $skyLL = C '#d9f1ff'; $skyD = C '#4ea6d8'
$pink = C '#ff8fb8'; $pinkD = C '#d9638f'; $pinkL = C '#ffc4dc'; $pinkLL = C '#ffe6f0'
$yel = C '#ffe36a'; $yelL = C '#fff6b0'; $yelD = C '#e0b035'
$mint = C '#8fe6c0'; $mintD = C '#58b894'
$white = C '#fffdf8'; $cream = C '#fff4dc'
$silv = C '#e4e9f6'; $silv2 = C '#b9c3de'; $silv3 = C '#8a96b8'
$tr = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# わたあめの色（base=ふつう hi=ひかり sh=かげ ol=ふち）
function Pal($b, $h, $s, $o) { @{ base = (C $b); hi = (C $h); sh = (C $s); ol = (C $o) } }
$pPink = Pal '#ffc4dc' '#fff2f8' '#f59cc2' '#c25a8e'
$pBlue = Pal '#b4e3ff' '#eefaff' '#7fbdf0' '#4a86c0'
$pYel = Pal '#fff0a0' '#fffbe0' '#f7cf55' '#c89a22'
$pPur = Pal '#dcc4ff' '#f5eeff' '#b392ee' '#7a58b8'
$pMint = Pal '#b9f3d8' '#effff7' '#7fd9ac' '#3f9d78'
$pWhite = Pal '#ffffff' '#ffffff' '#dfe6f7' '#9aa8d0'

# ---- 道具
# ふわふわの雲（丸を重ねる）。$circles = @(@(cx,cy,r),...) を奥→手前の順に。絵の左上が明るく右下が暗い。ふちは外側の1pxだけ
function Cloud($b, $ox, $oy, $circles, $pal) {
  $W = $b.Width; $H = $b.Height
  $L = New-Object 'System.Drawing.Color[,]' $W, $H
  foreach ($c in $circles) {
    $cx = $c[0] + $ox; $cy = $c[1] + $oy; $r = $c[2]
    for ($y = [int][math]::Floor($cy - $r - 1); $y -le [int][math]::Ceiling($cy + $r + 1); $y++) {
      for ($x = [int][math]::Floor($cx - $r - 1); $x -le [int][math]::Ceiling($cx + $r + 1); $x++) {
        if ($x -lt 0 -or $y -lt 0 -or $x -ge $W -or $y -ge $H) { continue }
        $dx = $x + 0.5 - $cx; $dy = $y + 0.5 - $cy; $d = [math]::Sqrt($dx * $dx + $dy * $dy)
        if ($d -le $r) {
          $t = ($dx + $dy) / ($r * 1.5)
          if ($t -lt -0.6) { $col = $pal.hi } elseif ($t -gt 0.55) { $col = $pal.sh } else { $col = $pal.base }
          # ふわふわの粒（やわらかい点描）
          if ($col -eq $pal.base -and $t -gt 0.3 -and (($x + $y) % 2) -eq 0) { $col = $pal.sh }
          if ($col -eq $pal.base -and $t -lt -0.3 -and (($x * 3 + $y * 5) % 7) -eq 0) { $col = $pal.hi }
          if ($d -gt $r - 1.0 -and ($dx + $dy) -gt 0) { $col = $pal.sh }
          $L[$x, $y] = $col
        }
      }
    }
  }
  for ($y = 0; $y -lt $H; $y++) {
    for ($x = 0; $x -lt $W; $x++) {
      if ($L[$x, $y].A -eq 0) { continue }
      $edge = ($x -eq 0) -or ($y -eq 0) -or ($x -eq $W - 1) -or ($y -eq $H - 1)
      if (-not $edge) { $edge = ($L[($x - 1), $y].A -eq 0) -or ($L[($x + 1), $y].A -eq 0) -or ($L[$x, ($y - 1)].A -eq 0) -or ($L[$x, ($y + 1)].A -eq 0) }
      if ($edge) { Px $b $x $y $pal.ol } else { Px $b $x $y $L[$x, $y] }
    }
  }
}
$shapeA = @(@(8, 3.4, 3.4), @(4, 6, 3.2), @(12, 6, 3.2), @(2.8, 10, 3), @(13.2, 10, 3), @(8, 8, 5), @(5, 12.6, 3.4), @(11, 12.6, 3.4), @(8, 13.4, 3))
$shapeB = @(@(5, 3.6, 3.4), @(11, 3.2, 3.4), @(2.8, 7.4, 2.9), @(13.2, 7.6, 2.9), @(3.4, 11.4, 3), @(12.6, 11.6, 3), @(8, 8, 5.4), @(6, 13.2, 3.2), @(10.6, 13.4, 3.2))
$shapeC = @(@(8, 3, 3.2), @(4.2, 5.4, 3.2), @(11.8, 5.2, 3.2), @(2.6, 9.4, 2.8), @(13.4, 9, 2.8), @(8, 7.6, 4.6), @(4.6, 12, 3.4), @(11.4, 12.2, 3.4), @(8, 12.8, 3.8))
function Shape($i) { switch ($i % 3) { 0 { return $shapeA } 1 { return $shapeB } default { return $shapeC } } }
function Scale($circles, $s) { $o = @(); foreach ($c in $circles) { $o += , @(($c[0] * $s), ($c[1] * $s), ($c[2] * $s)) }; return $o }

# 割り箸（わたあめの下の棒）。$x は左、2px幅
function Stick($b, $x, $y0, $y1) { for ($y = $y0; $y -le $y1; $y++) { Px $b $x $y $wd1; Px $b ($x + 1) $y $wd2 } }
# 割り箸に巻いたわたあめ1本（雲 16x17 + 棒）。$x,$y は雲の左上
function Candy($b, $x, $y, $pal, $shape, $stickLen) {
  Stick $b ($x + 7) ($y + 13) ($y + 13 + $stickLen)
  Cloud $b $x $y (Shape $shape) $pal
}

# 4つ角の透明
function Corners($b, $x, $y, $w, $h) { foreach ($p in @(@($x, $y), @(($x + $w - 1), $y), @($x, ($y + $h - 1)), @(($x + $w - 1), ($y + $h - 1)))) { Clear $b $p[0] $p[1] } }

# 星 5x5
$starRows = @('..y..', '.yyy.', 'yyyyy', '.yyy.', '.y.y.')
function Star($b, $x, $y, $col) { Ascii $b $x $y $starRows @{ y = $col } }

# ---- 看板 104x34。水色の板、上にもくもく雲、白い文字、両わきにわたあめ
$b = NewBmp 104 34
# 上の雲のぼこぼこ
$bump = @(@(6, 6.2, 6), @(18, 6, 6.2), @(30, 6.2, 6), @(41, 5.8, 6.4), @(52, 6, 6.6), @(63, 5.8, 6.4), @(74, 6.2, 6), @(86, 6, 6.2), @(98, 6.2, 6))
Cloud $b 0 0 $bump $pWhite
Rect $b 0 6 104 28 $ol2; Rect $b 1 7 102 26 $white; Rect $b 2 8 100 24 $sky
Rect $b 2 8 100 10 $skyL; Rect $b 2 28 100 4 $skyD
Frame $b 2 8 100 24 $white
Corners $b 0 6 104 28
Rect $b 2 9 100 1 $white
# わたあめ（左: ピンク / 右: 黄）。文字にかぶらないよう小さめ
$sm = Scale $shapeA 0.82
Stick $b 9 20 29
Cloud $b 3 11 $sm $pPink
$sm = Scale $shapeB 0.82
Stick $b 93 20 29
Cloud $b 87 11 $sm $pYel
# 文字（ふち取り）
$tw = TextWidth 'わたあめ' 16
$tx = [math]::Floor((104 - $tw) / 2) + 1; $ty = 11
foreach ($o in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1), @(-1, -1), @(1, -1), @(-1, 1), @(1, 1), @(2, 0), @(2, 1), @(2, -1))) { [void](TextPx $b 'わたあめ' ($tx + $o[0]) ($ty + $o[1]) 16 $ol2 $true) }
[void](TextPx $b 'わたあめ' $tx $ty 16 $white $true)
Star $b 22 25 $yel; Star $b 77 24 $yel
Save $b 'wataame_sign.png'

# ---- のぼり旗 16x82（左の棒の足元が原点）。水色版とピンク版。下は雲のふち
function Nobori($name, $cloth, $clothD, $clothL, $textCol, $shadow) {
  $b = NewBmp 16 82
  Rect $b 0 2 16 2 $wd3; Rect $b 0 2 2 80 $wd2; Rect $b 0 2 1 80 $wd3
  Rect $b 2 4 13 72 $cloth; Rect $b 2 4 1 72 $clothL; Rect $b 14 4 1 72 $clothD
  for ($x = 3; $x -lt 14; $x += 2) { Px $b $x 5 $clothL }
  # 下のふちを雲のぼこぼこに
  Rect $b 2 76 13 1 $clothD
  foreach ($bx in @(4, 8, 12)) { Ellipse $b $bx 76.5 2.6 2.6 $cloth; Px $b ($bx + 1) 78 $clothD }
  Rect $b 2 75 13 1 $cloth
  $chars = 'わ', 'た', 'あ', 'め'
  for ($i = 0; $i -lt 4; $i++) {
    [void](TextPx $b $chars[$i] 4 (10 + 15 * $i) 12 $shadow $false)
    [void](TextPx $b $chars[$i] 3 (9 + 15 * $i) 12 $textCol $false)
  }
  Star $b 5 70 $yel
  Save $b $name
}
Nobori 'wataame_nobori_blue.png' $sky $skyD $skyL $white $ol2
Nobori 'wataame_nobori_pink.png' $pink $pinkD $pinkL $white $ol2

# ---- 屋根の日よけ 108x24。むらさきと白のしま、手前は雲のようなまるいふち（4色）
$b = NewBmp 108 24
for ($y = 0; $y -lt 10; $y++) {
  $inset = [int](9 - $y)
  for ($x = $inset; $x -lt 108 - $inset; $x++) { $stripe = [math]::Floor($x / 9) % 2; Px $b $x $y $(if ($stripe -eq 0) { $lil } else { $white }) }
}
for ($x = 0; $x -lt 108; $x++) { if ((($x / 9) -as [int]) % 2 -eq 0) { Px $b $x 8 $lilD } }
for ($x = 0; $x -lt 108; $x++) { Px $b $x 9 $wd3; Px $b $x 10 $wd2 }
$pc = @($pink, $skyL, $yel, $mint)
$pcD = @($pinkD, $skyD, $yelD, $mintD)
for ($i = 0; $i -lt 12; $i++) {
  $col = $pc[$i % 4]; $cd = $pcD[$i % 4]
  $cx = $i * 9 + 4.5
  for ($dy = 0; $dy -lt 12; $dy++) {
    for ($x = 0; $x -lt 9; $x++) {
      $ddx = ($x + 0.5 - 4.5) / 4.5; $ddy = $dy / 11.0
      if ($ddx * $ddx + $ddy * $ddy -le 1.0) {
        $edge = ((($x - 0.0 + 0.5 - 4.5) / 4.5) * (($x + 0.5 - 4.5) / 4.5) + (($dy + 1) / 11.0) * (($dy + 1) / 11.0)) -gt 1.0
        if ($edge -or $dy -eq 11) { Px $b ($i * 9 + $x) (11 + $dy) $ol2 } else { Px $b ($i * 9 + $x) (11 + $dy) $col }
      }
    }
  }
  Px $b ($i * 9 + 2) 13 $white; Px $b ($i * 9 + 2) 14 $white
  Px $b ($i * 9 + 6) 17 $cd; Px $b ($i * 9 + 5) 18 $cd
}
Rect $b 0 11 108 1 $ol2
Save $b 'wataame_roof.png'

# ---- 柱 6x48（足元が原点）。水色と白のしま
$b = NewBmp 6 48
Rect $b 0 0 6 48 $ol2
for ($y = 0; $y -lt 47; $y++) { for ($x = 1; $x -le 4; $x++) { $s = [math]::Floor(($y + $x * 2) / 4) % 2; Px $b $x $y $(if ($s -eq 0) { $skyL } else { $white }) } }
Save $b 'wataame_post.png'

# ---- 店の奥の壁 96x26（足元が原点）。空色のうしろに白い雲と星
$b = NewBmp 96 26
Rect $b 0 0 96 26 $skyL
Rect $b 0 0 96 10 $skyLL
Rect $b 0 20 96 6 $lilL; Rect $b 0 20 96 1 $lil; Rect $b 0 25 96 1 $lil
Cloud $b 0 0 @(@(14, 12, 6), @(22, 11, 5), @(8, 13.5, 4)) $pWhite
Cloud $b 0 0 @(@(72, 10, 6), @(81, 12, 5), @(66, 12.5, 4), @(75, 13.5, 4.5)) $pWhite
Star $b 40 5 $yel; Star $b 50 13 $white; Star $b 30 15 $white; Star $b 58 4 $white; Star $b 90 4 $yel
Save $b 'wataame_back.png'

# ---- カウンター 104x24。白い天板と、水色の前板（白い雲のふち・星）
$b = NewBmp 104 24
Rect $b 0 0 104 24 $ol2
Rect $b 1 1 102 8 $cream; Rect $b 1 1 102 1 $white; Rect $b 1 8 102 1 $lil
Rect $b 1 9 102 14 $sky
Rect $b 1 9 102 4 $skyL
for ($x = 4; $x -lt 104; $x += 8) { Ellipse $b $x 10.5 4.2 3.2 $white; Px $b ($x + 1) 12 $skyL }
Rect $b 1 21 102 2 $skyD
$i = 0
for ($x = 6; $x -lt 100; $x += 14) { Star $b $x 14 $(if ($i % 2 -eq 0) { $yel } else { $pinkL }); $i++ }
Rect $b 0 23 104 1 $ol2
Corners $b 0 0 104 24
Save $b 'wataame_counter.png'

# ---- わたあめ機（回る）。横一列6コマ、1コマ34x44。足元中央が原点
$ms = NewBmp 204 44
$cloudCircles = @(@(17, 6, 6.2), @(10.5, 11.5, 6.5), @(23.5, 11.5, 6.5), @(17, 15, 8.5), @(9, 19, 5.5), @(25, 19, 5.5), @(17, 21.5, 6.5))
$armCols = @($white, (C '#d4f0ff'), (C '#fff6b8'))
$armColsS = @((C '#e8f0ff'), (C '#6cc0f2'), (C '#f5c43a'))
for ($f = 0; $f -lt 6; $f++) {
  $ox = $f * 34
  $ph = ($f / 6.0) * (2 * [math]::PI / 3)
  # 本体の箱（むらさき）
  Rect $ms ($ox + 4) 34 26 10 $ol2
  Rect $ms ($ox + 5) 35 24 8 $lil
  Rect $ms ($ox + 5) 35 24 1 $lilL; Rect $ms ($ox + 5) 42 24 1 $lilD
  Rect $ms ($ox + 5) 36 24 2 $silv; Rect $ms ($ox + 5) 36 24 1 $white; Rect $ms ($ox + 5) 37 24 1 $silv2
  Star $ms ($ox + 8) 38 $yel
  Ellipse $ms ($ox + 22) 40.2 2.4 2.4 $ol2; Ellipse $ms ($ox + 22) 40.2 1.6 1.6 $pink; Px $ms ($ox + 21) 39 $pinkLL
  Rect $ms ($ox + 25) 39 2 3 $silv2
  Corners $ms ($ox + 4) 34 26 10
  # ボウル（銀）
  Ellipse $ms ($ox + 17) 29.5 16.4 6.6 $ol2
  Ellipse $ms ($ox + 17) 29.5 15.4 5.6 $silv2
  Ellipse $ms ($ox + 17) 29 14.4 4.6 $silv
  Rect $ms ($ox + 4) 33 26 1 $ol2
  # ふち（リング）と内側
  Ellipse $ms ($ox + 17) 27 15.2 5.2 $ol2
  Ellipse $ms ($ox + 17) 27 14.2 4.4 $white
  Ellipse $ms ($ox + 17) 27.2 12.2 3.4 (C '#b3aad6')
  Ellipse $ms ($ox + 17) 27.2 12.2 3.4 (C '#b3aad6')
  # ボウルの中のわたあめの糸（回る）
  for ($k = 0; $k -lt 8; $k++) {
    $a = $ph * 3 + $k * [math]::PI / 4
    $px = $ox + 17 + [math]::Cos($a) * 11; $py = 27.2 + [math]::Sin($a) * 2.6
    $c = $armCols[$k % 3]
    Px $ms ([int][math]::Round($px)) ([int][math]::Round($py)) $c
  }
  # ふくらむわたあめの雲
  $cc = @()
  for ($i = 0; $i -lt $cloudCircles.Count; $i++) {
    $c = $cloudCircles[$i]; $pulse = [math]::Sin($f / 6.0 * 2 * [math]::PI + $i * 0.9) * 0.9
    $cc += , @($c[0], $c[1], ($c[2] + $pulse))
  }
  Cloud $ms $ox 0 $cc $pPink
  # 雲の中をまわる糸
  for ($arm = 0; $arm -lt 3; $arm++) {
    for ($t = 0.1; $t -le 1.0; $t += 0.05) {
      $a = $ph + $arm * 2.0944 + $t * 2.6; $rad = $t * 9.5
      $x = [int][math]::Round($ox + 17 + [math]::Cos($a) * $rad * 1.2); $y = [int][math]::Round(14.5 + [math]::Sin($a) * $rad * 0.85)
      $cur = $ms.GetPixel($x, $y)
      if ($cur.A -ne 0 -and ($cur.ToArgb() -ne ($pPink.ol).ToArgb())) { Px $ms $x $y $armColsS[$arm]; $c2 = $ms.GetPixel(($x + 1), $y); if ($c2.A -ne 0 -and ($c2.ToArgb() -ne ($pPink.ol).ToArgb())) { Px $ms ($x + 1) $y $armCols[$arm] } }
    }
  }
  # ボウルの手前のふち（雲より前）
  for ($y = 28; $y -le 33; $y++) {
    for ($x = 0; $x -lt 34; $x++) {
      $dx = ($x + 0.5 - 17) / 14.2; $dy = ($y + 0.5 - 27) / 4.4
      $dx2 = ($x + 0.5 - 17) / 15.2; $dy2 = ($y + 0.5 - 27) / 5.2
      if ($dx2 * $dx2 + $dy2 * $dy2 -le 1 -and $dx * $dx + $dy * $dy -gt 1.0 -and $y -ge 29) { Px $ms ($ox + $x) $y $white }
    }
  }
  # 飛びちる糸のかけら（上へ）
  foreach ($w in @(@(3, 0), @(31, 3), @(1, 8))) {
    $wy = 24 - (($f * 4 + $w[1] * 2) % 24)
    $wx = $w[0] + [int][math]::Round([math]::Sin(($f + $w[1]) * 1.2) * 1)
    if ($wy -gt 1) { Px $ms ($ox + $wx) $wy $armCols[($w[1]) % 3]; Px $ms ($ox + $wx) ($wy + 1) $pinkL }
  }
}
Save $ms 'wataame_machine.png'

# ---- わたあめの台 2本立て（木の台に割り箸を立てる）。27x37。足元中央が原点
function Rack($name, $pals, $shapes, $raise) {
  $n = $pals.Count; $W = 11 * $n + 5
  $b = NewBmp $W 37
  # 台
  Rect $b 0 29 $W 8 $ol2
  Rect $b 1 30 ($W - 2) 3 $wd1; Rect $b 1 30 ($W - 2) 1 $cream
  Rect $b 1 33 ($W - 2) 3 $wd2; Rect $b 1 35 ($W - 2) 1 $wd3
  for ($i = 0; $i -lt $n; $i++) { Rect $b (3 + 11 * $i + 5) 31 2 1 $wd3 }
  Corners $b 0 29 $W 8
  # 手前（中央）のものを最後に描く
  $order = 0..($n - 1)
  for ($j = 0; $j -lt $n; $j++) {
    $i = $order[$j]
    $x = 1 + 11 * $i; $y = $raise[$i]
    Candy $b $x $y $pals[$i] $shapes[$i] (29 - $y - 13)
  }
  Save $b $name
}
Rack 'wataame_rack_a.png' @($pBlue, $pYel) @(1, 2) @(2, 0)
Rack 'wataame_rack_b.png' @($pPur, $pMint) @(0, 1) @(0, 3)

# ---- ざらめ（砂糖）の瓶 9x12（2色）
function Jar($name, $lid, $lid2, $sug, $sugD, $sugL) {
  $b = NewBmp 9 13
  Rect $b 1 0 7 3 $ol2; Rect $b 2 0 5 2 $lid; Rect $b 2 0 5 1 $white; Rect $b 2 2 5 1 $lid2
  Rect $b 0 3 9 10 (C '#7f93b8'); Rect $b 1 4 7 8 (C '#f2f8ff')
  Rect $b 1 6 7 6 $sug                      # ざらめ（色つきの砂糖）
  Rect $b 1 6 7 1 $sugL; Rect $b 1 11 7 1 $sugD
  $i = 0
  foreach ($p in @(@(2, 7), @(5, 7), @(3, 8), @(6, 8), @(2, 9), @(4, 9), @(6, 9), @(3, 10), @(5, 10))) { Px $b $p[0] $p[1] $(if ($i % 2 -eq 0) { $sugL } else { $sugD }); $i++ }
  Rect $b 1 4 1 6 $white; Px $b 7 4 $white
  Corners $b 0 3 9 10
  Save $b $name
}
Jar 'wataame_jar_a.png' $pink $pinkD (C '#ffb0cf') (C '#e07aa5') (C '#ffe0ec')
Jar 'wataame_jar_b.png' $skyL $skyD (C '#a0d8f8') (C '#5fb0e0') (C '#e0f4ff')

# ---- 袋入りわたあめ（キャラクター柄）12x18。ねこ・くま・うさぎ
$faceCat = @('ww...ww', 'wwwwwww', 'wdwwwdw', 'wcwpwcw', '.wwwww.')
$faceBear = @('ww...ww', 'wwwwwww', 'wdwwwdw', 'wwmpmww', '.wwmww.')
$faceBun = @('.w...w.', '.w...w.', 'wwwwwww', 'wdwwwdw', 'wcwpwcw', '.wwwww.')
function Bag($b, $x, $y, $pal, $rib, $kind) {
  $widths = @(8, 10, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12)
  # ねじったくち + リボン
  Rect $b ($x + 4) $y 4 2 $ol3; Rect $b ($x + 5) $y 2 2 $rib
  Rect $b ($x + 2) ($y + 2) 8 1 $ol3; Rect $b ($x + 3) ($y + 2) 6 1 $rib
  for ($r = 0; $r -lt 15; $r++) {
    $w = $widths[$r]; $x0 = $x + 6 - [int]($w / 2); $yy = $y + 3 + $r
    for ($c = 0; $c -lt $w; $c++) {
      $edge = ($c -eq 0) -or ($c -eq $w - 1) -or ($r -eq 14)
      if ($edge) { Px $b ($x0 + $c) $yy $ol3 }
      else {
        $col = $pal.base
        if ($c -eq 1) { $col = $pal.hi } elseif ($c -eq $w - 2) { $col = $pal.sh } elseif ($r -eq 13) { $col = $pal.sh }
        Px $b ($x0 + $c) $yy $col
      }
    }
  }
  Clear $b $x ($y + 17); Clear $b ($x + 11) ($y + 17)
  # キャラクター
  switch ($kind) {
    0 { Ascii $b ($x + 3) ($y + 7) $faceCat @{ w = $white; d = $ol2; c = (C '#ffb0c8'); p = $pinkD } }
    1 { Ascii $b ($x + 3) ($y + 7) $faceBear @{ w = (C '#e6b886'); d = $ol2; m = (C '#fff0d8'); p = $ol2 } }
    default { Ascii $b ($x + 3) ($y + 6) $faceBun @{ w = $white; d = $ol2; c = (C '#ffb0c8'); p = $pinkD } }
  }
}

# ---- 袋入りわたあめの棚 48x52（足元中央が原点）。2段に6袋
$b = NewBmp 48 52
foreach ($p in @(0, 45)) { Rect $b $p 0 3 52 $ol2; Rect $b ($p + 1) 1 1 50 $wd1; Rect $b ($p + 2) 1 1 50 $wd2 }
Rect $b 0 0 48 1 $ol2; Rect $b 0 1 48 1 $wd3
foreach ($barY in @(3, 26)) { Rect $b 3 $barY 42 2 $ol2; Rect $b 3 $barY 42 1 $wd1 }
Rect $b 0 49 48 3 $ol2; Rect $b 1 49 46 2 $wd2; Rect $b 1 49 46 1 $wd1
$bp = @($pPink, $pBlue, $pYel, $pPur, $pMint, $pPink)
$rb = @($sky, $pink, $lil, $yel, $pink, $skyD)
for ($i = 0; $i -lt 6; $i++) {
  $col = $i % 3; $row = [math]::Floor($i / 3)
  $bx = 5 + 13 * $col; $by = 5 + 23 * $row
  Px $b ($bx + 6) ($by - 1) $ol2
  Bag $b $bx $by $bp[$i] $rb[$i] (($i + $row) % 3)
}
Corners $b 0 49 48 3
Save $b 'wataame_bagstand.png'

# ---- メニュー（立て看板）54x48。足元が原点
$b = NewBmp 54 48
Rect $b 0 0 54 42 $ol2; Rect $b 1 1 52 40 $skyL; Rect $b 3 3 48 36 $white
Rect $b 3 3 48 3 $pink
for ($x = 3; $x -lt 51; $x += 6) { Ellipse $b ($x + 3) 6 3 2 $pink }
Rect $b 8 42 3 6 $wd3; Rect $b 43 42 3 6 $wd3; Rect $b 8 42 1 6 $wd2; Rect $b 43 42 1 6 $wd2
$rows = @('ふわふわ', 'あまあま', 'くるくる')
$rcol = @($pinkD, $skyD, $lilD)
for ($i = 0; $i -lt 3; $i++) {
  $cy = 10 + 10 * $i
  [void](TextPx $b $rows[$i] 4 $cy 11 $rcol[$i] $false)
  Star $b 47 ($cy + 3) $yel
}
Corners $b 0 0 54 42
Save $b 'wataame_menu.png'

# ---- マット 44x24。水色の地に白い雲と星
$b = NewBmp 44 24
Rect $b 0 0 44 24 $lilD; Rect $b 1 1 42 22 $lilL; Rect $b 2 2 40 20 $skyL
Cloud $b 0 0 @(@(9, 9, 3.8), @(14, 8, 3.4), @(5, 10.5, 2.8)) $pWhite
Cloud $b 0 0 @(@(32, 16, 3.6), @(37, 15.5, 3), @(28, 17.5, 2.6)) $pWhite
Star $b 20 6 $yel; Star $b 22 15 $pinkL; Star $b 34 6 $white; Star $b 8 16 $white
Corners $b 0 0 44 24
Save $b 'wataame_mat.png'

# ---- 風船（ゆれる）。横一列4コマ、1コマ18x46。足元（ひもの先）が原点。2セット
function Balloons($name, $bal) {
  $bs = NewBmp 72 46
  $sway = @(-1, 0, 1, 0)
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * 18; $s = $sway[$f]
    foreach ($bl in $bal) { Line $bs ($ox + 9) 45 ($ox + [math]::Round($bl[0] + $s)) ($bl[1] + 7) (C '#f4efe6') }
    foreach ($bl in $bal) {
      $cx = $bl[0] + $s; $cy = $bl[1]
      Ellipse $bs ($ox + $cx) $cy 5.5 6.5 $ol2
      Ellipse $bs ($ox + $cx) $cy 4.5 5.5 $bl[2]
      Px $bs ($ox + $cx - 2) ($cy - 3) $bl[3]; Px $bs ($ox + $cx - 2) ($cy - 2) $bl[3]; Px $bs ($ox + $cx - 1) ($cy - 4) $bl[3]
      Px $bs ($ox + [math]::Round($cx)) ($cy + 7) $ol2
    }
  }
  Save $bs $name
}
Balloons 'wataame_balloon_a.png' @(@(5, 11, $lil, (C '#efe4ff')), @(13, 9, $pink, $pinkLL), @(9, 19, $skyL, (C '#e8f7ff')))
Balloons 'wataame_balloon_b.png' @(@(5, 9, $mint, (C '#e4fff3')), @(13, 11, $yel, $yelL), @(9, 19, $pink, $pinkLL))

# ---- キラキラ（星のきらめき）。横一列4コマ、1コマ9x9
$sp = NewBmp 36 9
$sz = @(0, 2, 4, 2)
for ($f = 0; $f -lt 4; $f++) {
  $ox = $f * 9; $r = $sz[$f]
  Px $sp ($ox + 4) 4 $white
  for ($d = 1; $d -le $r; $d++) { foreach ($q in @(@($d, 0), @(-$d, 0), @(0, $d), @(0, -$d))) { Px $sp ($ox + 4 + $q[0]) (4 + $q[1]) $(if ($d -le 1) { $white } else { $pinkL }) } }
  if ($r -ge 3) { foreach ($q in @(@(1, 1), @(-1, 1), @(1, -1), @(-1, -1))) { Px $sp ($ox + 4 + $q[0]) (4 + $q[1]) $yelL } }
}
Save $sp 'wataame_sparkle.png'
