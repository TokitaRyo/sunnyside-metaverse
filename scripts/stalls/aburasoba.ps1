# 油そば屋の専用ドット絵（看板・のぼり・提灯・暖簾・カウンター・寸胴の鍋・どんぶり・調味料・食券機・黒板など）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/aburasoba.ps1   （リポジトリのルートで）
# 出力: client/public/brand/stall/aburasoba_*.png（原点は各スプライトの足元。配置は scripts/stalls/aburasoba.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（ラーメン屋の定番: 黒・赤・黄。ほかの屋台の赤白/紺とは違う、黒地に黄色い文字）
$k0 = C '#14141a'; $k1 = C '#23232d'; $k2 = C '#34343f'; $k3 = C '#4f4f5e'
$rd = C '#c8202a'; $rd2 = C '#8f1420'; $rd3 = C '#ee4a45'
$ye = C '#f5c518'; $ye2 = C '#c99510'; $ye3 = C '#ffe27a'
$bw = C '#f6f1e6'; $bw2 = C '#d2cabb'; $bw3 = C '#a39a88'
$nd = C '#ecc86e'; $nd2 = C '#c8963a'; $nd3 = C '#fae29a'
$sauce = C '#4e2410'; $sauce2 = C '#7a3a18'
$cs = C '#b25a3c'; $cs2 = C '#6e2e1e'; $fat = C '#f2cdb4'
$mm = C '#dba653'; $mm2 = C '#a9762c'
$ng = C '#5cc04c'; $ng2 = C '#2f8a35'
$nori = C '#1f3a2c'; $nori2 = C '#35604a'
$yk = C '#f2860c'; $yk2 = C '#ffbe3a'
$st = C '#b4bac8'; $st2 = C '#7f879b'; $st3 = C '#e4e9f2'; $st4 = C '#575e72'
$wd1 = C '#5a3a28'; $wd2 = C '#7a5238'; $wd3 = C '#a37250'; $wd4 = C '#3b2418'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# ---- 小さな道具
function Blit($dst, $src, $x, $y) {
  for ($j = 0; $j -lt $src.Height; $j++) { for ($i = 0; $i -lt $src.Width; $i++) { $p = $src.GetPixel($i, $j); if ($p.A -gt 0) { Px $dst ($x + $i) ($y + $j) $p } } }
}
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
# 雷文（ラーメンどんぶりの渦巻きの帯）。x0,y0 から幅 w、高さ 8。1px の線で描く
function Raimon($b, $x0, $y0, $w, $col) {
  for ($x = 0; $x -lt $w; $x++) { Px $b ($x0 + $x) ($y0 + 7) $col }
  for ($u = 0; $u * 10 + 8 -lt $w + 2; $u++) {
    $ux = $x0 + $u * 10
    Line $b $ux ($y0 + 7) $ux $y0 $col
    Line $b $ux $y0 ($ux + 7) $y0 $col
    Line $b ($ux + 7) $y0 ($ux + 7) ($y0 + 5) $col
    Line $b ($ux + 7) ($y0 + 5) ($ux + 2) ($y0 + 5) $col
    Line $b ($ux + 2) ($y0 + 5) ($ux + 2) ($y0 + 2) $col
    Line $b ($ux + 2) ($y0 + 2) ($ux + 4) ($y0 + 2) $col
  }
}
# 湯気。$b の (ox..ox+w, 0..h) の中に、下から上へ昇る白いふわふわを描く。f はコマ、nf は総コマ数
function Steam($b, $ox, $w, $h, $f, $nf, $count, $maxR) {
  for ($k = 0; $k -lt $count; $k++) {
    $phase = (($f * (24 / $nf)) + ($k * (24 / $count))) % 24
    $t = $phase / 24.0
    $y = ($h - 3) - $t * ($h - 4)
    $x = $w / 2 + [math]::Sin($t * 6.28 * 1.3 + $k * 2.3) * ($w * 0.22) + ($k - ($count - 1) / 2.0) * ($w * 0.22)
    $r = 1.4 + $t * $maxR
    $a = [int](245 * (1 - $t * $t))
    Ellipse $b ($ox + $x) $y $r ($r * 0.85) ([System.Drawing.Color]::FromArgb($a, 255, 255, 255))
    Ellipse $b ($ox + $x - $r * 0.25) ($y - $r * 0.25) ($r * 0.5) ($r * 0.4) ([System.Drawing.Color]::FromArgb([int]($a * 0.9), 240, 244, 255))
  }
}

# ---- 油そばのどんぶり（斜め上から。麺・チャーシュー・メンマ・ねぎ・卵黄・のり）。cx,cy は上のふち(だ円)の中心
function Bowl($b, $cx, $cy, $rx, $ry, $dep) {
  # ふち・胴・足のふち取り
  Ellipse $b $cx $cy ($rx + 1) ($ry + 1) $k0
  $y1 = [int][math]::Ceiling($cy + $dep + $ry + 1)
  for ($y = [int][math]::Floor($cy); $y -le $y1; $y++) {
    for ($x = [int][math]::Floor($cx - $rx - 1); $x -le [int][math]::Ceiling($cx + $rx + 1); $x++) {
      if ($y + 0.5 -lt $cy) { continue }
      $dx = ($x + 0.5 - $cx) / ($rx + 1); $dy = ($y + 0.5 - $cy) / ($ry + $dep + 1)
      if ($dx * $dx + $dy * $dy -le 1) { Px $b $x $y $k0 }
    }
  }
  $fy = [int][math]::Round($cy + $dep + $ry - 0.5)
  Rect $b ([int]($cx - $rx * 0.5)) $fy ([int]($rx)) 2 $bw3
  Rect $b ([int]($cx - $rx * 0.5 - 1)) ($fy + 2) ([int]($rx + 2)) 1 $k0
  # 胴（右側は影）。ふちの下に赤い帯
  for ($y = [int][math]::Floor($cy); $y -le [int][math]::Ceiling($cy + $dep + $ry); $y++) {
    for ($x = [int][math]::Floor($cx - $rx); $x -le [int][math]::Ceiling($cx + $rx); $x++) {
      if ($y + 0.5 -lt $cy) { continue }
      $dx = ($x + 0.5 - $cx) / $rx; $dy = ($y + 0.5 - $cy) / ($ry + $dep)
      if ($dx * $dx + $dy * $dy -le 1) {
        $col = $bw
        if ($dx -gt 0.45) { $col = $bw2 }
        if ($dx -gt 0.8) { $col = $bw3 }
        $band = $y - ($cy + $ry)
        if ($band -ge 0.5 -and $band -lt 2.5) { $col = $rd; if ($dx -gt 0.55) { $col = $rd2 } }
        elseif ($band -ge 2.5 -and $band -lt 3.5 -and ($x % 2) -eq 0) { $col = $rd2 }
        Px $b $x $y $col
      }
    }
  }
  # ふちと中（タレの海）
  Ellipse $b $cx $cy $rx $ry $bw
  Ellipse $b $cx $cy ($rx - 1.1) ($ry - 0.9) $sauce
  $ox = $rx - 1.1; $oy = $ry - 0.9
  Ellipse $b $cx ($cy - 0.6) ($ox - 0.8) ($oy - 0.9) $sauce2
  # 麺
  Ellipse $b $cx ($cy - 0.8) ($ox - 1.2) ($oy - 1.2) $nd
  for ($y = [int][math]::Floor($cy - $oy); $y -le [int][math]::Ceiling($cy + $oy); $y++) {
    for ($x = [int][math]::Floor($cx - $ox); $x -le [int][math]::Ceiling($cx + $ox); $x++) {
      $dx = ($x + 0.5 - $cx) / ($ox - 1.2); $dy = ($y + 0.5 - $cy + 0.8) / ($oy - 1.2)
      if ($dx * $dx + $dy * $dy -le 0.95) {
        if ((($x + $y * 2) % 5) -eq 0) { Px $b $x $y $nd2 }
        elseif ((($x * 2 + $y) % 7) -eq 0) { Px $b $x $y $nd3 }
      }
    }
  }
  # チャーシュー（2枚）
  Ellipse $b ($cx - $ox * 0.5) ($cy - $oy * 0.1) ($ox * 0.44 + 0.6) ($oy * 0.62 + 0.6) $cs2
  Ellipse $b ($cx - $ox * 0.5) ($cy - $oy * 0.1) ($ox * 0.44) ($oy * 0.62) $cs
  Ellipse $b ($cx - $ox * 0.5) ($cy - $oy * 0.1) ($ox * 0.24) ($oy * 0.32) $fat
  Px $b ($cx - $ox * 0.5) ($cy - $oy * 0.1) $cs
  Ellipse $b ($cx - $ox * 0.2) ($cy + $oy * 0.35) ($ox * 0.34 + 0.6) ($oy * 0.42 + 0.6) $cs2
  Ellipse $b ($cx - $ox * 0.2) ($cy + $oy * 0.35) ($ox * 0.34) ($oy * 0.42) $cs
  Px $b ($cx - $ox * 0.3) ($cy + $oy * 0.3) $fat; Px $b ($cx - $ox * 0.1) ($cy + $oy * 0.4) $fat
  # メンマ
  $mx = [int]($cx + $ox * 0.35); $my = [int]($cy + $oy * 0.45)
  Rect $b $mx $my 3 1 $mm; Rect $b ($mx + 1) ($my + 1) 3 1 $mm2; Rect $b ($mx - 1) ($my - 1) 2 1 $mm
  # 卵黄（白身のくぼみに黄身）
  $ex = $cx + $ox * 0.2; $ey = $cy - $oy * 0.15
  Ellipse $b $ex $ey ($ox * 0.3 + 0.5) ($oy * 0.5 + 0.4) $bw
  Ellipse $b $ex $ey ($ox * 0.2 + 0.2) ($oy * 0.34 + 0.2) $yk
  Px $b ([int]($ex - 0.8)) ([int]($ey - 0.8)) $yk2
  # ねぎ
  foreach ($p in @(@(-0.1, -0.7), @(0.5, -0.45), @(0.65, 0.05), @(-0.75, 0.35), @(0.0, 0.65), @(0.3, 0.8), @(-0.35, -0.55), @(0.75, -0.15))) {
    $nx = [int]($cx + $ox * $p[0]); $ny = [int]($cy + $oy * $p[1])
    Px $b $nx $ny $ng; if ($rx -gt 6) { Px $b ($nx + 1) $ny $ng2 }
  }
  # のり（ふちから立てかける）
  $nw = [int][math]::Max(3, [math]::Round($rx * 0.42)); $nh = [int][math]::Max(4, [math]::Round($ry * 1.0 + 1))
  $nx = [int]($cx + $rx * 0.2); $ny = [int]($cy - $ry - 1.5)
  Rect $b $nx $ny $nw $nh $nori
  Rect $b $nx $ny 1 $nh $nori2
  Rect $b ($nx - 1) $ny 1 $nh $k0; Rect $b ($nx + $nw) $ny 1 $nh $k0; Rect $b ($nx - 1) ($ny - 1) ($nw + 2) 1 $k0
}
# どんぶり1枚の絵（steamH があれば上に湯気、frames コマ）
function BowlSprite($rx, $ry, $dep, $steamH, $frames) {
  $W = [int](2 * ($rx + 2)); $cy = $steamH + $ry + 3; $H = [int]($cy + $dep + $ry + 4)
  $b = NewBmp ($W * $frames) $H
  for ($f = 0; $f -lt $frames; $f++) {
    Bowl $b ($f * $W + $W / 2) $cy $rx $ry $dep
    if ($steamH -gt 0) { Steam $b ($f * $W) $W ($steamH + $ry) $f $frames 3 2.0 }
  }
  return $b
}

# =====================================================================
# ---- 看板（屋根の上に掲げる）96x28。黒い板に赤と黄のふち、黄色い大きな文字とどんぶり
$b = NewBmp 96 28
Rect $b 14 0 2 4 $wd1; Rect $b 80 0 2 4 $wd1
Rect $b 0 3 96 25 $k0; Rect $b 1 4 94 23 $rd; Rect $b 3 6 90 19 $k1
Frame $b 4 7 88 17 $ye2
Rect $b 3 6 90 1 $k3
foreach ($p in @(@(0, 3), @(95, 3), @(0, 27), @(95, 27))) { Clear $b $p[0] $p[1] }
$bw1 = BowlSprite 7 4 5 0 1
Blit $b $bw1 7 6; Blit $b $bw1 70 6
$bw1.Dispose()
$tw = TextWidth '油そば' 15
[void](TextPx $b '油そば' ([int]((96 - $tw) / 2) + 1) 8 15 $rd $true)
[void](TextPx $b '油そば' ([int]((96 - $tw) / 2)) 7 15 $ye $true)
Save $b 'aburasoba_sign.png'

# ---- のぼり旗 16x78（左の棒の足元が原点）。黒い布に黄色い縦書き「油そば」とどんぶり
$b = NewBmp 16 78
Rect $b 0 2 16 2 $wd1; Rect $b 0 2 2 76 $wd2; Rect $b 0 2 1 76 $wd1
Rect $b 2 4 13 68 $k1; Rect $b 2 4 1 68 $k3; Rect $b 14 4 1 68 $k0
Rect $b 2 4 13 3 $rd; Rect $b 2 4 13 1 $rd3
Rect $b 2 69 13 3 $rd
for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 72 $k1; Px $b (2 + $i) 73 $k0 } }
$chars = '油', 'そ', 'ば'
for ($i = 0; $i -lt 3; $i++) { [void](TextPx $b $chars[$i] 3 (9 + 12 * $i) 11 $ye $true) }
$bw1 = BowlSprite 5 3 3 0 1
Blit $b $bw1 2 49
$bw1.Dispose()
Save $b 'aburasoba_nobori.png'

# ---- 赤提灯 14x26（3コマ: 灯りがゆらぐ）。赤い紙に黒いふち、黄色い「油」
$LW = 14
$b = NewBmp ($LW * 3) 26
for ($f = 0; $f -lt 3; $f++) {
  $x0 = $f * $LW
  Rect $b ($x0 + 6) 0 1 4 $k0
  Rect $b ($x0 + 3) 4 8 2 $k0
  $body = @($rd, $rd3, $rd)[$f]
  Ellipse $b ($x0 + 7) 14 6.6 7.6 $rd2
  Ellipse $b ($x0 + 7) 14 6 7 $body
  if ($f -eq 1) { Ellipse $b ($x0 + 7) 14 4.2 5.2 (C '#ff7a5c') }
  if ($f -eq 2) { Ellipse $b ($x0 + 7) 14 5.4 6.4 $rd2; Ellipse $b ($x0 + 7) 14 4.4 5.4 $rd }
  Rect $b ($x0 + 1) 9 12 1 $rd2; Rect $b ($x0 + 1) 18 12 1 $rd2
  Rect $b ($x0 + 3) 20 8 2 $k0
  Rect $b ($x0 + 6) 22 2 4 $ye
  [void](TextPx $b '油' ($x0 + 2) 10 10 $k0 $false)
}
Save $b 'aburasoba_lantern_a.png'

# ---- 暖簾つきの屋根 124x28（黒い瓦に赤と黄のふち。手前に黒い暖簾3枚「油」「そ」「ば」）。足元が下のへり
$RW = 124
$b = NewBmp $RW 25
for ($y = 0; $y -lt 6; $y++) {
  $inset = 6 - $y
  for ($x = $inset; $x -lt $RW - $inset; $x++) {
    $col = $k1
    if ($y -eq 0) { $col = $k3 }
    elseif (($x % 6) -eq 2 -and ($y % 3) -eq 1) { $col = $k2 }
    elseif (($x % 6) -eq 5 -and ($y % 3) -eq 2) { $col = $k2 }
    Px $b $x $y $col
  }
}
for ($x = 0; $x -lt $RW; $x++) { Px $b $x 6 $rd; Px $b $x 7 $ye; Px $b $x 8 $k0 }
$starts = 2, 43, 84
$names = '油', 'そ', 'ば'
for ($p = 0; $p -lt 3; $p++) {
  $x0 = $starts[$p]
  for ($y = 9; $y -lt 25; $y++) {
    for ($x = $x0; $x -lt $x0 + 38; $x++) {
      $col = $k1
      if ($x -eq $x0) { $col = $k3 } elseif ($x -eq $x0 + 37) { $col = $k0 }
      elseif (($x - $x0) % 9 -eq 0) { $col = $k2 }
      if ($y -ge 21 -and $y -le 22) { $col = $rd }
      if ($y -eq 23) { $col = $ye2 }
      if ($y -eq 24) { $col = $k0 }
      Px $b $x $y $col
    }
  }
  [void](TextPx $b $names[$p] ($x0 + 11) 9 14 $bw $true)
}
Save $b 'aburasoba_roof.png'

# ---- カウンター 120x24。黒い漆の天板と、赤い前板に黒い雷文
$b = NewBmp 120 24
Rect $b 0 0 120 24 $k0
Rect $b 1 1 118 8 $wd2; Rect $b 1 1 118 1 $wd3; Rect $b 1 8 118 1 $wd1
Rect $b 1 9 118 14 $rd; Rect $b 1 9 118 1 $rd3
Rect $b 1 10 118 1 $ye2
Raimon $b 5 12 110 $k0
Rect $b 1 22 118 1 $rd2
foreach ($p in @(@(0, 0), @(119, 0))) { Clear $b $p[0] $p[1] }
Save $b 'aburasoba_counter.png'

# ---- 柱 6x48（足元が原点）。黒い木に赤い布
$b = NewBmp 6 48
Rect $b 0 0 6 48 $k0; Rect $b 1 0 4 47 $k2; Rect $b 1 0 1 47 $k3; Rect $b 4 0 1 47 $k1
Rect $b 1 12 4 5 $rd; Rect $b 1 12 4 1 $rd3; Rect $b 1 16 4 1 $rd2
Save $b 'aburasoba_post.png'

# ---- 寸胴の鍋 36x34（ステンレス。湯がぐらぐら。てぼ(ゆで麺のざる)が立てかけてある）。足元が原点
$b = NewBmp 36 34
Rect $b 3 11 24 22 $k0
Rect $b 4 11 22 21 $st; Rect $b 4 11 3 21 $st3; Rect $b 22 11 4 21 $st2
Rect $b 4 31 22 1 $st4; Rect $b 8 22 1 8 $st3; Rect $b 21 22 1 8 $st2
Rect $b 0 13 4 3 $k0; Rect $b 1 14 3 1 $k3; Rect $b 26 13 4 3 $k0; Rect $b 26 14 3 1 $k3
Ellipse $b 15 11 13.2 4.6 $k0
Ellipse $b 15 11 12.4 4 $st3
Ellipse $b 15 11.3 11 3.2 $st4
Ellipse $b 15 11.6 10.2 2.7 (C '#a8c4cc')
Ellipse $b 15 11.8 8 1.9 (C '#c8dde2')
# ぐらぐらのあわ（白い小さな輪）
foreach ($p in @(@(9, 11), @(14, 12), @(19, 10), @(21, 12), @(12, 9))) { Px $b $p[0] $p[1] $bw; Px $b ($p[0] + 1) $p[1] (C '#e8f4f6') }
foreach ($p in @(@(11, 12), @(17, 11), @(7, 12))) { Px $b $p[0] $p[1] $nd }
# てぼ: ざるのかご + 長い柄
Ellipse $b 27 9 4.6 2.4 $k0
Ellipse $b 27 9 3.8 1.8 $st3
for ($i = 0; $i -lt 6; $i += 2) { Px $b (24 + $i) 9 $st4 }
Line $b 31 8 35 0 $k0; Line $b 32 8 35 1 $wd2; Line $b 31 7 34 0 $wd3
Save $b 'aburasoba_pot.png'

# ---- 寸胴の湯気（6コマ）30x34。大きな白い湯気がもくもく
$SW = 30
$b = NewBmp ($SW * 6) 34
for ($f = 0; $f -lt 6; $f++) { Steam $b ($f * $SW) $SW 34 $f 6 4 4.2 }
Save $b 'aburasoba_steam.png'

# ---- どんぶり（カウンター用: 湯気が立つ4コマ）と、止まった1枚と、小さい1枚
$b = BowlSprite 8 4 5 12 4
Save $b 'aburasoba_bowl_a.png'
$b = BowlSprite 8 4 5 0 1
Save $b 'aburasoba_bowl.png'
$b = BowlSprite 6 3 4 0 1
Save $b 'aburasoba_bowl_s.png'

# ---- 重ねたどんぶり 16x14（白い器に赤い帯）
$b = NewBmp 16 14
for ($i = 0; $i -lt 3; $i++) {
  $y = 8 - $i * 3
  Ellipse $b 8 ($y + 2) 7.6 3 $k0
  Ellipse $b 8 ($y + 2) 7 2.4 $bw
  Rect $b 2 ($y + 3) 12 2 $rd
  Rect $b 3 ($y + 5) 10 1 $bw3
}
Ellipse $b 8 3 7.6 3 $k0; Ellipse $b 8 3 7 2.4 $bw; Ellipse $b 8 3.2 5 1.4 $bw2
$b2 = $b
Save $b2 'aburasoba_bowls.png'

# ---- 具の仕込み台 34x14: まな板にチャーシュー、メンマとねぎの小鉢
$b = NewBmp 34 14
Rect $b 0 3 17 10 $k0; Rect $b 1 4 15 8 $wd3; Rect $b 1 4 15 1 (C '#c89a70'); Rect $b 1 11 15 1 $wd2
foreach ($p in @(@(4, 8), @(8, 7), @(12, 8))) {
  Ellipse $b $p[0] $p[1] 3.4 2.8 $cs2; Ellipse $b $p[0] $p[1] 2.8 2.2 $cs; Px $b ($p[0] - 1) ($p[1] - 1) $fat; Px $b $p[0] $p[1] $fat
}
Line $b 14 2 17 1 $st3
foreach ($o in @(@(18, 'm'), @(26, 'g'))) {
  $x0 = $o[0]
  Rect $b $x0 6 8 7 $k0; Rect $b ($x0 + 1) 7 6 5 $bw; Rect $b ($x0 + 1) 11 6 1 $bw3
  if ($o[1] -eq 'm') { foreach ($q in @(@(2, 5), @(3, 4), @(4, 5), @(5, 4), @(3, 6))) { Rect $b ($x0 + $q[0]) $q[1] 1 3 $mm }; Rect $b ($x0 + 2) 4 2 1 $mm2 }
  else { foreach ($q in @(@(2, 5), @(4, 4), @(3, 6), @(5, 5), @(1, 6), @(4, 7))) { Px $b ($x0 + $q[0]) $q[1] $ng; Px $b ($x0 + $q[0] + 1) $q[1] $ng2 }; Rect $b ($x0 + 1) 4 6 2 $ng }
}
Save $b 'aburasoba_prep.png'

# ---- 味玉の瓶 12x14（ガラスの瓶に、たれ色の味玉）
$b = NewBmp 12 14
Rect $b 3 0 6 2 $rd; Rect $b 3 0 6 1 $rd3
Rect $b 2 2 8 12 (C '#7d93a8'); Rect $b 3 3 6 10 (C '#d4e2ea'); Rect $b 3 3 1 10 $white
foreach ($p in @(@(6, 5), @(5, 8), @(7, 11))) {
  Ellipse $b $p[0] $p[1] 2.9 2.5 (C '#7c4020'); Ellipse $b ($p[0] - 0.2) ($p[1] - 0.2) 2.3 1.9 (C '#a8602a'); Px $b ($p[0] - 1) ($p[1] - 1) (C '#e0a050')
}
Rect $b 3 12 6 1 (C '#9a6a3a')
Save $b 'aburasoba_ajitama.png'

# ---- 卓上の調味料 34x16（酢・ラー油・おろしにんにく・七味・箸立て）
$b = NewBmp 34 16
$vin = @{ r = $rd; a = (C '#d9a02a'); h = (C '#f0cf6a'); w = $bw; o = $rd }
Ascii $b 0 3 @(
  '..rr..',
  '..rr..',
  '..aa..',
  '.ahaa.',
  'ahaaaa',
  'awwwwa',
  'awoowa',
  'awwwwa',
  'aaaaaa',
  'aaaaaa',
  'aaaaaa',
  'aaaaaa') @{ r = $rd; a = (C '#d9a02a'); h = (C '#f4d878'); w = $bw; o = (C '#b02a22') }
Ascii $b 7 3 @(
  '..kk..',
  '..kk..',
  '..dd..',
  '.dhdd.',
  'dhdddd',
  'dyyyyd',
  'dyddyd',
  'dyyyyd',
  'dddddd',
  'dddddd',
  'dddddd',
  'dddddd') @{ k = $k0; d = (C '#8f1a14'); h = (C '#e0502c'); y = $ye }
Ascii $b 14 7 @(
  '.mmmmm.',
  'ggggggg',
  'gccccct',
  'gcwwwct',
  'gccccct',
  'gccccct',
  'ggggggg') @{ m = $ye2; g = (C '#a8c0cc'); c = (C '#f4f0d8'); w = $white; t = (C '#8aa4b2') }
Ascii $b 22 5 @(
  '.bbb.',
  '.bkb.',
  'ooooo',
  'oyyyo',
  'oyyyo',
  'ooooo',
  'ooooo',
  'ooooo',
  'ooooo') @{ b = (C '#e0c898'); k = $wd1; o = (C '#d2461e'); y = $ye }
Ascii $b 28 7 @(
  '.sS.sS',
  '.sS.sS',
  '..sS.s',
  'kkkkkk',
  'kddddk',
  'kddddk',
  'kkkkkk') @{ s = (C '#e8c888'); p = $wd3; k = $k0; d = $rd2 }
$b2 = OutlineBmp $b $k0
Save $b2 'aburasoba_condi.png'

# ---- カウンター席（客用の長いバー）64x22。黒い天板に、赤い前板
$b = NewBmp 64 22
Rect $b 0 0 64 22 $k0
Rect $b 1 1 62 8 $wd2; Rect $b 1 1 62 1 $wd3; Rect $b 1 8 62 1 $wd1
Rect $b 1 9 62 12 $rd; Rect $b 1 9 62 1 $rd3; Rect $b 1 10 62 1 $ye2
Raimon $b 3 11 58 $k0
foreach ($p in @(@(0, 0), @(63, 0))) { Clear $b $p[0] $p[1] }
Save $b 'aburasoba_bar.png'

# ---- 丸椅子 12x15（赤い座面に銀の脚）。足元が原点
$b = NewBmp 12 15
Ellipse $b 6 4 5.9 3.4 $k0
Ellipse $b 6 4 5.2 2.8 $rd
Ellipse $b 5 3.4 3 1.3 $rd3
Rect $b 1 5 10 3 $k0; Rect $b 2 5 8 2 $rd2
Rect $b 3 8 1 6 $k0; Rect $b 8 8 1 6 $k0; Rect $b 5 8 2 5 $k0
Px $b 3 8 $st3; Px $b 8 8 $st; Line $b 4 8 4 13 $st; Line $b 7 8 7 13 $st2; Line $b 5 8 5 12 $st3
Rect $b 2 14 3 1 $k0; Rect $b 7 14 3 1 $k0
Save $b 'aburasoba_stool.png'

# ---- 食券機 18x26（赤い天面とボタンの列、食券の出口）。足元が原点
$b = NewBmp 18 26
Rect $b 0 0 18 26 $k0
Rect $b 1 1 16 6 $rd; Rect $b 1 1 16 1 $rd3
Rect $b 3 3 12 2 $k0; Rect $b 4 3 3 1 $ye
Rect $b 1 7 16 17 $k1; Rect $b 1 7 1 17 $k2
for ($r = 0; $r -lt 3; $r++) {
  for ($c = 0; $c -lt 3; $c++) {
    $col = @($bw, $ye, $rd3)[($r + $c) % 3]
    Rect $b (3 + $c * 4) (9 + $r * 3) 3 2 $col
  }
}
Rect $b 3 19 12 1 $k0; Rect $b 4 19 4 1 $ye3
Rect $b 4 21 10 3 $k0; Rect $b 6 21 6 2 $bw
Rect $b 1 24 16 1 $k2
Save $b 'aburasoba_ticket.png'

# ---- メニューの黒板 72x50（赤い枠）。黄色の見出しと白い文字。足元が原点
$b = NewBmp 60 52
Rect $b 0 0 60 46 $k0; Rect $b 1 1 58 44 $rd; Rect $b 1 1 58 1 $rd3; Rect $b 3 3 54 40 $k1
Rect $b 3 3 54 1 $k0
Rect $b 7 46 4 6 $wd1; Rect $b 49 46 4 6 $wd1; Rect $b 7 46 1 6 $wd2; Rect $b 49 46 1 6 $wd2
$t = TextWidth '油そば' 13
[void](TextPx $b '油そば' ([int]((60 - $t) / 2)) 5 13 $ye $true)
Rect $b 8 19 44 1 $ye2
$t = TextWidth 'まぜまぜ' 11
[void](TextPx $b 'まぜまぜ' ([int]((60 - $t) / 2)) 22 11 $white $true)
$t = TextWidth '酢ラー油' 11
[void](TextPx $b '酢ラー油' ([int]((60 - $t) / 2)) 32 11 (C '#ff9a82') $true)
Save $b 'aburasoba_menu.png'

# ---- 店の奥の壁 118x32（黒い板壁）。足元が原点
$b = NewBmp 118 32
Rect $b 0 0 118 32 $k1
for ($x = 0; $x -lt 118; $x += 7) { Rect $b $x 0 1 32 $k0 }
for ($x = 3; $x -lt 118; $x += 7) { Rect $b $x 0 1 32 $k2 }
Rect $b 0 0 118 2 $k0
Rect $b 0 29 118 3 $wd1; Rect $b 0 29 118 1 $wd2
Save $b 'aburasoba_wall.png'

# ---- 床のマット 56x20（黒いゴムに黄色いふち、赤い帯の雷文）
$b = NewBmp 56 20
Rect $b 0 0 56 20 $k0; Rect $b 2 2 52 16 $ye; Rect $b 3 3 50 14 $k1; Rect $b 4 4 48 12 $rd
Raimon $b 5 6 46 $k0
foreach ($p in @(@(0, 0), @(55, 0), @(0, 19), @(55, 19))) { Clear $b $p[0] $p[1] }
Save $b 'aburasoba_mat.png'
