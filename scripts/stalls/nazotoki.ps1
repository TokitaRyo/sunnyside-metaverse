# 謎解き愛好会（謎解きの体験ブース）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/nazotoki.ps1
#   一部だけ作り直す: $env:NAZOTOKI_ONLY='sign|door'
# 出力: client/public/brand/stall/nazotoki_*.png （配置は scripts/stalls/nazotoki.mjs）
# 配色は青紫の夜（紺・青紫）に、ランタンのオレンジと金、星・？マークの水色の光を差す。アニメは「フレームを横一列に並べたPNG」。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。暗号の記号は意味のないオリジナルの図形。
. "$PSScriptRoot\..\lib\pixel.ps1"

$only = $env:NAZOTOKI_ONLY
function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function Sheet($name, $sw, $sh, $n, $draw) {
  if ($only -and ($name -notmatch $only)) { return }
  $bm = NewBmp ($sw * $n) $sh
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $sw) $f }
  Save $bm $name
}
function Thick($b, $x0, $y0, $x1, $y1, $t, $col) {
  $o = [int][math]::Floor($t / 2)
  for ($i = 0; $i -lt $t; $i++) { Line $b ($x0 + $i - $o) $y0 ($x1 + $i - $o) $y1 $col }
}
# 絵の外側のふちどり（透明なマスで、となりに不透明な絵があるところを色でぬる）。1コマ分(ox..ox+sw, 0..sh)
function Outline($b, $ox, $sw, $sh, $col) {
  $list = New-Object System.Collections.ArrayList
  for ($y = 0; $y -lt $sh; $y++) {
    for ($x = 0; $x -lt $sw; $x++) {
      if ($b.GetPixel($ox + $x, $y).A -eq 0) {
        $adj = $false
        foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
          $nx = $x + $d[0]; $ny = $y + $d[1]
          if ($nx -ge 0 -and $nx -lt $sw -and $ny -ge 0 -and $ny -lt $sh) { if ($b.GetPixel($ox + $nx, $ny).A -gt 200) { $adj = $true } }
        }
        if ($adj) { [void]$list.Add(@($x, $y)) }
      }
    }
  }
  foreach ($p in $list) { Px $b ($ox + $p[0]) $p[1] $col }
}
# 4つ角の星（中心 + 腕の長さ r）
function Star4($b, $cx, $cy, $r, $col) {
  Px $b $cx $cy $col
  for ($i = 1; $i -le $r; $i++) { Px $b ($cx + $i) $cy $col; Px $b ($cx - $i) $cy $col; Px $b $cx ($cy + $i) $col; Px $b $cx ($cy - $i) $col }
}
# ASCII（'#'だけ1色で塗る）
function AsciiCol($b, $x, $y, $rows, $col) {
  for ($j = 0; $j -lt $rows.Count; $j++) {
    $row = $rows[$j]
    for ($i = 0; $i -lt $row.Length; $i++) { if ([string]$row[$i] -eq '#') { Px $b ($x + $i) ($y + $j) $col } }
  }
}
# 暗号の記号（意味のないオリジナルの図形 5x5 を10種類）
$glyphRows = @(
  @('.###.', '#...#', '#.#.#', '#...#', '.###.'),
  @('..#..', '.#.#.', '.#.#.', '#...#', '#####'),
  @('..#..', '.###.', '#####', '.###.', '..#..'),
  @('#.#.#', '.....', '#.#.#', '.....', '#.#.#'),
  @('#####', '....#', '###.#', '#...#', '#####'),
  @('#...#', '.#.#.', '..#..', '.#.#.', '#...#'),
  @('###..', '#.#..', '###.#', '..#.#', '..###'),
  @('..#..', '..#..', '#####', '..#..', '..#..'),
  @('#..#.', '##.##', '.#.#.', '##.##', '#..#.'),
  @('.#.#.', '#####', '.#.#.', '#####', '.#.#.')
)
function Glyph($b, $x, $y, $i, $col) { AsciiCol $b $x $y $glyphRows[$i % $glyphRows.Count] $col }
# ？マーク 7x9
$qRows = @('.#####.', '##...##', '##...##', '....##.', '...##..', '...##..', '.......', '...##..', '...##..')

# ---- パレット
$n0 = C '#070a1c'; $n1 = C '#0f1438'; $n2 = C '#1a2156'; $n3 = C '#283080'; $n4 = C '#3d49b0'; $n5 = C '#5d6ce0'; $n6 = C '#9aa6ff'
$v1 = C '#2b1654'; $v2 = C '#45287f'; $v3 = C '#6c42b0'; $v4 = C '#9c70e8'
$gd0 = C '#7a5418'; $gd1 = C '#c08a28'; $gd2 = C '#f0c040'; $gd3 = C '#ffe27a'; $gd4 = C '#fff6c0'
$cy1 = C '#2a9ab8'; $cy2 = C '#6ae6ff'; $cy3 = C '#c4f8ff'
$pp0 = C '#a89870'; $pp1 = C '#cfc09a'; $pp2 = C '#e8dcb8'; $pp3 = C '#f8f0d8'
$wd0 = C '#2a1a14'; $wd1 = C '#4a2e1e'; $wd2 = C '#6e4628'; $wd3 = C '#98643a'; $wd4 = C '#c08a52'
$or0 = C '#7a2e12'; $or1 = C '#c8581a'; $or2 = C '#ff9a2e'; $or3 = C '#ffcf5a'; $or4 = C '#fff2a0'
$ir0 = C '#1c1830'; $ir1 = C '#38344e'; $ir2 = C '#58546e'; $ir3 = C '#807c98'
$ink = C '#1a1330'
$rd1 = C '#8a1a30'; $rd2 = C '#d02a44'
$chalkW = C '#f0f4ff'; $chalkP = C '#ffb0d0'; $chalkY = C '#ffe27a'; $chalkC = C '#9af0ff'

# ---- 床の暗い覆い（草地ぜんたい 192x128、半透明）。石だたみのうす線と星のかけら。sort:floor で敷く
Sheet 'nazotoki_overlay.png' 192 128 1 {
  param($b, $ox, $f)
  $rng = New-Object System.Random 31
  $base = C '#0a1030'
  for ($y = 0; $y -lt 128; $y++) {
    for ($x = 0; $x -lt 192; $x++) {
      $dx = ($x - 96) / 96.0; $dy = ($y - 70) / 70.0
      $d = [math]::Sqrt($dx * $dx + $dy * $dy * 0.6)
      $a = [int](150 + 55 * [math]::Min(1.0, $d * 0.9))
      $row = [int][math]::Floor($y / 16)
      if (($y % 16) -eq 0 -or ((($x + ($row % 2) * 16) % 32) -eq 0)) { $a = [math]::Min(230, $a + 36) }
      Px $b $x $y ([System.Drawing.Color]::FromArgb($a, $base.R, $base.G, $base.B))
    }
  }
  for ($i = 0; $i -lt 70; $i++) { $x = $rng.Next(2, 190); $y = $rng.Next(2, 126); Px $b $x $y (CA '#8c98ff' 120) }
  for ($i = 0; $i -lt 26; $i++) { $x = $rng.Next(3, 189); $y = $rng.Next(3, 125); Px $b $x $y (CA '#d8e4ff' 200) }
  for ($i = 0; $i -lt 8; $i++) { $x = $rng.Next(4, 188); $y = $rng.Next(4, 124); Star4 $b $x $y 2 (CA '#b0c0ff' 150) }
}

# ---- 床のラグ（暗号の円）100x44
Sheet 'nazotoki_rug.png' 100 44 1 {
  param($b, $ox, $f)
  Ellipse $b 50 22 49.5 21.5 $wd0
  Ellipse $b 50 22 48 20.2 $n2
  Ellipse $b 50 22 46.3 18.6 $gd1
  Ellipse $b 50 22 45.3 17.6 $n1
  Ellipse $b 50 22 35 13 $gd0
  Ellipse $b 50 22 34 12.2 $v1
  Ellipse $b 50 22 30 10.6 $v2
  # 輪のまわりの記号
  for ($i = 0; $i -lt 12; $i++) {
    $a = $i * 2 * [math]::PI / 12
    $gx = [int][math]::Round(50 + 40.2 * [math]::Cos($a)); $gy = [int][math]::Round(22 + 15.2 * [math]::Sin($a))
    Glyph $b ($gx - 2) ($gy - 2) $i $gd2
  }
  # まん中の目と星
  Star4 $b 50 22 8 $gd1
  Line $b 44 16 56 28 $gd0; Line $b 56 16 44 28 $gd0
  Ellipse $b 50 22 6 3.4 $gd3
  Ellipse $b 50 22 4.6 2.6 $n1
  Ellipse $b 50 22 2.2 2.2 $cy2
  Px $b 49 21 $cy3
}

# ---- 奥の壁 176x60（青紫の壁紙・腰板・飾りぶち）
Sheet 'nazotoki_wall.png' 176 60 1 {
  param($b, $ox, $f)
  $rng = New-Object System.Random 41
  for ($y = 0; $y -lt 41; $y++) {
    for ($x = 0; $x -lt 176; $x++) {
      $c = $n2
      if (($x % 16) -eq 0) { $c = $n1 } elseif (($x % 16) -eq 1) { $c = (Mix $n2 $n3 0.5) }
      $px = ($x % 16) - 8; $py = ($y % 12) - 6
      if ([math]::Abs($px) + [math]::Abs($py) -le 2) { $c = $n3 }
      if ($px -eq 0 -and $py -eq 0) { $c = $n4 }
      Px $b $x $y $c
    }
  }
  for ($y = 5; $y -lt 9; $y++) { Rect $b 0 $y 176 1 (Mix $n2 $n0 (0.55 - ($y - 5) * 0.14)) }
  # 飾りぶち（上）
  Rect $b 0 0 176 3 $n0; Rect $b 0 3 176 1 $gd0; Rect $b 0 4 176 1 $gd1
  for ($x = 3; $x -lt 176; $x += 8) { Rect $b $x 1 3 1 $n3 }
  # 壁の星
  for ($i = 0; $i -lt 16; $i++) { $x = $rng.Next(4, 172); $y = $rng.Next(12, 36); Px $b $x $y $gd3 }
  # 腰板
  Rect $b 0 41 176 1 $n5; Rect $b 0 42 176 2 $n4; Rect $b 0 44 176 1 $n0
  for ($y = 45; $y -lt 56; $y++) { Rect $b 0 $y 176 1 $n1 }
  for ($px = 4; $px -lt 176; $px += 28) {
    Frame $b $px 46 24 9 $n3
    Rect $b ($px + 1) 47 22 7 (C '#121a4c')
    Rect $b ($px + 1) 47 22 1 $n2
  }
  Rect $b 0 56 176 4 $n0; Rect $b 0 56 176 1 $n3; Rect $b 0 59 176 1 (C '#03040c')
}

# ---- 謎めいた扉 32x44 4コマ（鎖と南京錠、鍵穴と足もとから光がもれる）
Sheet 'nazotoki_door.png' 32 44 4 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 16) 11 16 11 $wd2
  Rect $b $ox 11 32 33 $wd2
  Rect $b $ox 11 1 33 $wd3; Rect $b ($ox + 31) 11 1 33 $wd1
  Ellipse $b ($ox + 16) 12 12.5 10 $v2
  Rect $b ($ox + 3) 12 26 31 $v2
  # 板
  for ($y = 12; $y -lt 43; $y++) {
    for ($x = 3; $x -lt 29; $x++) {
      $m = ($x - 3) % 7
      if ($m -eq 0) { Px $b ($ox + $x) $y $v1 } elseif ($m -eq 1) { Px $b ($ox + $x) $y $v3 }
    }
  }
  Rect $b ($ox + 15) 3 1 9 $v1; Rect $b ($ox + 16) 3 1 9 $v3
  # 鉄の帯
  foreach ($by in 18, 33) {
    Rect $b ($ox + 3) $by 26 3 $ir1; Rect $b ($ox + 3) $by 26 1 $ir2; Rect $b ($ox + 3) ($by + 2) 26 1 $ir0
    foreach ($rx in 5, 26) { Px $b ($ox + $rx) ($by + 1) $gd2 }
  }
  # 鎖（ななめに交差）
  $nn = 22
  for ($i = 0; $i -le $nn; $i++) {
    $c = if ($i % 2 -eq 0) { $ir3 } else { $ir1 }
    $x1 = [int][math]::Round(5 + 21 * $i / $nn); $y1 = [int][math]::Round(15 + 22 * $i / $nn)
    Px $b ($ox + $x1) $y1 $c; Px $b ($ox + $x1 + 1) $y1 $c; Px $b ($ox + $x1) ($y1 + 1) $c
    $x2 = [int][math]::Round(26 - 21 * $i / $nn)
    Px $b ($ox + $x2) $y1 $c; Px $b ($ox + $x2 + 1) $y1 $c; Px $b ($ox + $x2 + 1) ($y1 + 1) $c
  }
  # 南京錠
  Rect $b ($ox + 13) 22 1 5 $ir3; Rect $b ($ox + 18) 22 1 5 $ir3; Rect $b ($ox + 14) 21 4 1 $ir3
  Rect $b ($ox + 12) 26 8 8 $gd1; Rect $b ($ox + 12) 26 8 1 $gd3; Rect $b ($ox + 12) 26 1 8 $gd2; Rect $b ($ox + 12) 33 8 1 $gd0; Rect $b ($ox + 19) 27 1 7 $gd0
  Px $b ($ox + 15) 29 $n0; Px $b ($ox + 16) 29 $n0; Rect $b ($ox + 15) 30 2 2 $n0
  if ($f -eq 1 -or $f -eq 2) { Px $b ($ox + 15) 29 $cy3; Px $b ($ox + 16) 29 $cy2; Rect $b ($ox + 15) 30 2 2 $cy2 }
  # 上の星
  Star4 $b ($ox + 16) 7 2 $gd3
  Px $b ($ox + 16) 7 $gd4
  # 足もとからもれる光
  $al = @(70, 150, 220, 150)[$f]
  Rect $b ($ox + 4) 41 24 2 (CA '#6ae6ff' $al)
  Rect $b ($ox + 8) 40 16 1 (CA '#6ae6ff' ([int]($al / 2)))
  Rect $b $ox 43 32 1 $wd0
}

# ---- 黒板 46x32（暗号とチョークの？）
Sheet 'nazotoki_board.png' 46 32 1 {
  param($b, $ox, $f)
  Rect $b 0 0 46 29 $wd2; Rect $b 0 0 46 1 $wd3; Rect $b 0 0 1 29 $wd3; Rect $b 45 0 1 29 $wd1; Rect $b 0 28 46 1 $wd1
  Rect $b 2 2 42 25 (C '#16283a'); Rect $b 2 2 42 1 (C '#0c1826'); Rect $b 2 2 1 25 (C '#0c1826')
  # 1行目: 暗号の記号
  $cols = @($chalkW, $chalkC, $chalkW, $chalkY, $chalkW)
  for ($i = 0; $i -lt 5; $i++) { Glyph $b (6 + 7 * $i) 5 (($i * 3 + 1) % 10) $cols[$i] }
  # 2行目: 矢印
  Line $b 7 13 16 13 $chalkP; Line $b 16 13 14 11 $chalkP; Line $b 16 13 14 15 $chalkP
  Glyph $b 19 11 4 $chalkC; Glyph $b 26 11 7 $chalkY
  Line $b 33 13 39 13 $chalkP; Line $b 39 13 37 11 $chalkP; Line $b 39 13 37 15 $chalkP
  # 3行目: ？ と 点線・星
  AsciiCol $b 7 18 @('.###.', '#...#', '...#.', '..#..', '.....', '..#..') $chalkW
  for ($x = 15; $x -lt 36; $x += 3) { Px $b $x 22 $chalkC }
  Star4 $b 39 21 2 $chalkY
  Px $b 12 25 (CA '#9aa6ff' 90); Px $b 24 24 (CA '#9aa6ff' 90); Px $b 31 25 (CA '#9aa6ff' 90)
  # チョーク受け
  Rect $b 1 29 44 2 $wd3; Rect $b 1 31 44 1 $wd0
  Rect $b 5 28 5 1 $chalkW; Rect $b 12 28 4 1 $chalkP; Rect $b 36 27 7 2 (C '#5a4a3a'); Rect $b 36 27 7 1 (C '#8a7a5a')
}

# ---- 壁の貼り紙（コルクボード）46x32
Sheet 'nazotoki_notice.png' 46 32 1 {
  param($b, $ox, $f)
  $rng = New-Object System.Random 51
  Rect $b 0 0 46 30 $wd2; Rect $b 0 0 46 1 $wd3; Rect $b 0 0 1 30 $wd3; Rect $b 45 0 1 30 $wd1; Rect $b 0 29 46 1 $wd1
  Rect $b 2 2 42 26 (C '#9c6e3e')
  for ($i = 0; $i -lt 60; $i++) { Px $b $rng.Next(2, 44) $rng.Next(2, 28) (C '#7c5430') }
  for ($i = 0; $i -lt 40; $i++) { Px $b $rng.Next(2, 44) $rng.Next(2, 28) (C '#b88850') }
  # 大きな貼り紙（謎）
  Rect $b 5 4 15 17 (C '#5a4028')
  Rect $b 4 3 15 17 $pp2; Frame $b 4 3 15 17 $pp0
  [void](TextPx $b '謎' 7 5 12 $ink $false)
  Glyph $b 6 17 1 $v3; Glyph $b 12 17 6 $v3
  Rect $b 4 19 15 1 $pp1
  # 小さな紙たち
  Rect $b 23 5 10 12 (C '#5a4028'); Rect $b 22 4 10 12 $pp1; Frame $b 22 4 10 12 $pp0
  Glyph $b 24 6 3 $ink; Glyph $b 24 12 8 $v2
  Rect $b 35 4 9 14 (C '#5a4028'); Rect $b 34 3 9 14 (C '#cfe0ff'); Frame $b 34 3 9 14 (C '#8a9ad0')
  AsciiCol $b 35 5 $qRows $n3
  Rect $b 22 19 12 9 (C '#5a4028'); Rect $b 21 18 12 9 $pp3; Frame $b 21 18 12 9 $pp0
  Line $b 23 21 30 21 $ink; Line $b 23 23 28 23 $ink; Star4 $b 30 24 1 $rd2
  Rect $b 36 20 8 8 (C '#5a4028'); Rect $b 35 19 8 8 (C '#ffc8d8'); Frame $b 35 19 8 8 (C '#d890a8')
  Line $b 37 23 41 23 $ink; Line $b 41 23 39 21 $ink; Line $b 41 23 39 25 $ink
  Rect $b 6 24 9 5 (C '#5a4028'); Rect $b 5 23 9 5 $chalkY; Glyph $b 7 23 9 $ink
  # ピン
  foreach ($p in @(@(11, 4), @(27, 5), @(38, 4), @(26, 19), @(39, 20), @(9, 23))) { Px $b $p[0] $p[1] $rd2; Px $b ($p[0] + 1) $p[1] $rd1 }
}

# ---- 看板「謎解き愛好会」116x40 4コマ（金の枠の電球が回る・文字がきらめく・星がまたたく）
$signTxt = '謎解き愛好会'
$signTw = TextWidth $signTxt 16
Sheet 'nazotoki_sign.png' 116 40 4 {
  param($b, $ox, $f)
  foreach ($cx in 16, 99) {
    for ($y = 0; $y -lt 9; $y++) { Px $b ($ox + $cx) $y $(if ($y % 3 -eq 2) { $ir1 } else { $ir3 }); Px $b ($ox + $cx + 1) $y $(if ($y % 3 -eq 2) { $ir0 } else { $ir2 }) }
  }
  Rect $b $ox 8 116 31 $n0
  Rect $b ($ox + 1) 9 114 29 $n2
  Frame $b ($ox + 1) 9 114 29 $gd1
  Frame $b ($ox + 2) 10 112 27 $gd0
  Rect $b ($ox + 4) 12 108 23 $n1
  Rect $b ($ox + 4) 12 108 1 $n3
  # 枠の電球（コマごとに点灯する場所が回る）
  for ($i = 0; $i * 6 + 6 -lt 112; $i++) {
    $x = $ox + 6 + $i * 6
    $lit = (($i + $f) % 4) -eq 0
    $c = if ($lit) { $gd4 } else { $gd1 }
    Px $b $x 9 $c; Px $b ($x + 1) 9 $c
    Px $b $x 37 $c; Px $b ($x + 1) 37 $c
    if ($lit) { Px $b $x 8 (CA '#ffe27a' 150); Px $b ($x + 1) 8 (CA '#ffe27a' 150); Px $b $x 38 (CA '#ffe27a' 150); Px $b ($x + 1) 38 (CA '#ffe27a' 150) }
  }
  foreach ($p in @(@(3, 10), @(112, 10), @(3, 36), @(112, 36))) { Px $b ($ox + $p[0]) $p[1] $gd3 }
  # 文字
  $tx = [int][math]::Floor((116 - $signTw) / 2) - 1
  $tc = @($gd3, $gd4, (C '#ffffff'), $gd4)[$f]
  [void](TextPx $b $signTxt ($tx + $ox + 1) 17 16 $n0 $true)
  [void](TextPx $b $signTxt ($tx + $ox) 16 16 $tc $true)
  # 左右の星・？
  $sr = @(1, 2, 3, 2)[$f]; $sr2 = @(3, 2, 1, 2)[$f]
  Star4 $b ($ox + 9) 24 $sr $cy2; Px $b ($ox + 9) 24 $cy3
  Star4 $b ($ox + 107) 24 $sr2 $cy2; Px $b ($ox + 107) 24 $cy3
  Px $b ($ox + 14) 14 $gd3; Px $b ($ox + 101) 33 $gd3
  if ($f -eq 2) { Px $b ($ox + 20) 14 $cy3; Px $b ($ox + 90) 34 $cy3 }
  if ($f -eq 0) { Px $b ($ox + 96) 14 $cy3; Px $b ($ox + 26) 34 $cy3 }
}

# ---- のぼり旗「謎解き愛好会」18x80
Sheet 'nazotoki_nobori.png' 18 80 1 {
  param($b, $ox, $f)
  Rect $b 0 1 18 2 $wd2; Rect $b 0 1 18 1 $wd3
  Rect $b 0 0 2 4 $gd2; Rect $b 16 0 2 4 $gd2; Px $b 0 0 $gd4
  Rect $b 2 3 14 73 $n3; Rect $b 2 3 14 1 $n5; Rect $b 2 3 1 73 $n5; Rect $b 15 3 1 73 $n1
  Frame $b 3 4 12 71 $gd1
  Rect $b 4 5 10 69 $n2
  $chars = '謎', '解', 'き', '愛', '好', '会'
  for ($i = 0; $i -lt 6; $i++) { [void](TextPx $b $chars[$i] 4 (8 + 11 * $i) 11 $n0 $false); [void](TextPx $b $chars[$i] 3 (7 + 11 * $i) 11 $gd3 $false) }
  Star4 $b 9 75 0 $gd3
  Rect $b 2 75 14 1 $gd1; Rect $b 2 76 14 1 $gd0
  foreach ($tx in 3, 8, 13) { Rect $b $tx 77 1 3 $gd2; Rect $b ($tx + 1) 77 1 2 $gd1 }
}

# ---- 長机 108x30（木の天板に紺のテーブルかけ、金のふち、まん中に目の紋章と暗号）
Sheet 'nazotoki_table.png' 108 30 1 {
  param($b, $ox, $f)
  Rect $b 0 0 108 13 $wd3
  for ($x = 0; $x -lt 108; $x += 1) { if (($x % 18) -eq 0) { Rect $b $x 0 1 13 $wd2 } }
  Rect $b 0 0 108 1 $wd4
  for ($y = 3; $y -lt 12; $y += 4) { Rect $b 0 $y 108 1 $wd2 }
  # ランナー（紺の細長い布）
  Rect $b 6 3 96 8 $n2; Rect $b 6 3 96 1 $gd1; Rect $b 6 10 96 1 $gd1
  for ($x = 9; $x -lt 100; $x += 8) { Px $b $x 6 $n4; Px $b ($x + 1) 6 $n4; Px $b $x 7 $n4 }
  Rect $b 0 13 108 2 $wd2; Rect $b 0 13 108 1 $wd3; Rect $b 0 14 108 1 $wd1
  # 前のテーブルかけ
  Rect $b 1 15 106 13 $n2
  for ($x = 1; $x -lt 107; $x += 9) { Rect $b $x 15 1 13 $n1; Rect $b ($x + 1) 15 1 13 $n3 }
  Rect $b 1 15 106 1 $gd1; Rect $b 1 16 106 1 $gd0
  for ($x = 1; $x -lt 107; $x++) { $d = if ((($x - 1) % 6) -lt 3) { 2 } else { 1 }; Rect $b $x 27 1 $d $gd1; Px $b $x (27 + $d) $gd0 }
  # 紋章
  Rect $b 50 17 9 9 $n0
  for ($i = 0; $i -lt 5; $i++) { Rect $b (54 - $i) (17 + $i) (1 + $i * 2) 1 $n1; Rect $b (54 - $i) (25 - $i) (1 + $i * 2) 1 $n1 }
  Ellipse $b 54.5 21.5 3.6 2.2 $gd2; Ellipse $b 54.5 21.5 2.6 1.6 $n0; Px $b 54 21 $cy2; Px $b 55 21 $cy3
  Star4 $b 54 18 1 $gd3; Star4 $b 54 25 0 $gd3
  for ($i = 0; $i -lt 4; $i++) { Glyph $b (11 + $i * 9) 18 ($i * 2) $gd1; Glyph $b (66 + $i * 9) 18 ($i * 2 + 1) $gd1 }
  Rect $b 2 28 3 2 $wd0; Rect $b 103 28 3 2 $wd0
  Clear $b 0 0; Clear $b 107 0
}

# ---- 鍵のかかった箱 20x18 4コマ（南京錠がきらり）
Sheet 'nazotoki_lockbox.png' 20 18 4 {
  param($b, $ox, $f)
  Rect $b ($ox + 1) 1 18 4 $wd3; Rect $b ($ox + 1) 1 18 1 $wd4; Rect $b ($ox + 2) 0 16 1 $wd3
  Rect $b ($ox + 1) 5 18 11 $wd2
  Rect $b ($ox + 1) 9 18 1 $wd1; Rect $b ($ox + 1) 13 18 1 $wd1
  Rect $b ($ox + 1) 5 18 1 $wd1
  foreach ($bx in 3, 15) { Rect $b ($ox + $bx) 1 2 15 $ir1; Rect $b ($ox + $bx) 1 1 15 $ir2; Px $b ($ox + $bx) 3 $gd2; Px $b ($ox + $bx) 13 $gd2 }
  Rect $b ($ox + 1) 15 18 1 $wd0
  # 南京錠
  Rect $b ($ox + 8) 6 1 3 $ir3; Rect $b ($ox + 11) 6 1 3 $ir3; Rect $b ($ox + 9) 5 2 1 $ir3
  Rect $b ($ox + 7) 8 6 5 $gd1; Rect $b ($ox + 7) 8 6 1 $gd3; Rect $b ($ox + 7) 8 1 5 $gd2; Rect $b ($ox + 7) 12 6 1 $gd0
  Px $b ($ox + 10) 10 $n0; Px $b ($ox + 10) 11 $n0
  Rect $b ($ox + 1) 16 18 1 (CA '#05030c' 140)
  Outline $b $ox 20 18 $ink
  if ($f -eq 1 -or $f -eq 3) { Star4 $b ($ox + 8) 9 1 $gd4 }
  if ($f -eq 2) { Star4 $b ($ox + 8) 9 2 (C '#ffffff') }
}

# ---- 南京錠 9x12
Sheet 'nazotoki_padlock.png' 9 12 1 {
  param($b, $ox, $f)
  Rect $b 1 2 1 4 $ir3; Rect $b 7 2 1 4 $ir3; Rect $b 2 1 5 1 $ir3; Rect $b 2 2 1 1 $ir2
  Rect $b 0 5 9 6 $gd1; Rect $b 0 5 9 1 $gd3; Rect $b 0 5 1 6 $gd2; Rect $b 0 10 9 1 $gd0; Rect $b 8 6 1 5 $gd0
  Rect $b 4 7 2 2 $n0; Px $b 4 9 $n0
  Px $b 2 6 $gd4
  Outline $b 0 9 12 $ink
}

# ---- 鍵 14x8
Sheet 'nazotoki_key.png' 14 8 1 {
  param($b, $ox, $f)
  Ellipse $b 3.5 3.5 3.2 3.2 $gd2
  Ellipse $b 3.5 3.5 1.6 1.6 $n1
  Rect $b 6 3 7 2 $gd2; Rect $b 6 3 7 1 $gd3; Rect $b 6 4 7 1 $gd1
  Rect $b 10 5 2 2 $gd1; Rect $b 12 5 1 1 $gd1
  Px $b 1 2 $gd4
  Outline $b 0 14 8 $ink
}

# ---- 封筒 16x11（星のろうふうじ）
Sheet 'nazotoki_envelope.png' 16 11 1 {
  param($b, $ox, $f)
  Rect $b 0 0 16 10 $pp2; Rect $b 0 9 16 1 $pp0
  Frame $b 0 0 16 10 $pp0
  Line $b 1 1 7 5 $pp0; Line $b 14 1 8 5 $pp0
  Line $b 1 8 5 5 $pp1; Line $b 14 8 10 5 $pp1
  Ellipse $b 8 5.5 2.6 2.6 $rd2; Ellipse $b 8 5.5 1.6 1.6 $rd1; Px $b 8 5 $gd3; Px $b 7 5 $rd2
  Outline $b 0 16 11 $ink
}

# ---- 暗号のカード 14x12
Sheet 'nazotoki_card.png' 14 12 1 {
  param($b, $ox, $f)
  Rect $b 0 0 14 11 $pp3; Frame $b 0 0 14 11 $pp0; Rect $b 1 10 12 1 $pp1
  Glyph $b 2 1 4 $v2; Glyph $b 8 1 9 $n3
  Glyph $b 2 6 6 $n3; Glyph $b 8 6 2 $rd1
  Outline $b 0 14 12 $ink
}

# ---- 虫眼鏡 18x18
Sheet 'nazotoki_magnifier.png' 18 18 1 {
  param($b, $ox, $f)
  Thick $b 11 11 16 16 3 $wd2
  Line $b 12 11 16 15 $wd4
  Rect $b 15 15 3 3 $wd1
  Ellipse $b 7 7 7 7 $gd1
  Ellipse $b 7 7 6 6 $gd3
  Ellipse $b 7 7 5.2 5.2 (C '#a8e0f0')
  Ellipse $b 7 7.5 3.4 3.4 (C '#c8f0ff')
  Glyph $b 5 5 2 (C '#3a4a8a')
  Px $b 4 3 (C '#ffffff'); Px $b 3 4 (C '#ffffff'); Px $b 5 3 (C '#e8ffff')
  Outline $b 0 18 18 $ink
}

# ---- ヒントカードの箱 36x24（ヒントのカードが顔を出す）
Sheet 'nazotoki_hintbox.png' 36 24 1 {
  param($b, $ox, $f)
  # カード
  Rect $b 3 1 9 9 $pp3; Frame $b 3 1 9 9 $pp0; Glyph $b 5 3 3 $v2
  Rect $b 14 0 10 10 (C '#cfe0ff'); Frame $b 14 0 10 10 (C '#8a9ad0'); AsciiCol $b 16 1 $qRows $n3
  Rect $b 26 2 8 8 (C '#ffe8b0'); Frame $b 26 2 8 8 $pp0; Glyph $b 27 3 5 $rd1
  # 箱
  Rect $b 0 9 36 14 $n2
  Rect $b 0 9 36 2 $gd1; Rect $b 0 9 36 1 $gd3
  Rect $b 0 21 36 2 $gd0
  Rect $b 0 11 1 10 $n3; Rect $b 35 11 1 10 $n1
  Rect $b 1 11 34 1 $n3
  # ラベル
  Rect $b 1 11 34 10 $pp2; Frame $b 1 11 34 10 $gd1
  [void](TextPx $b 'ヒント' 2 10 11 $ink $true)
  Px $b 2 12 $pp3
  Outline $b 0 36 24 $ink
}

# ---- 砂時計 12x18 8コマ（砂が落ちる）
Sheet 'nazotoki_hourglass.png' 12 18 8 {
  param($b, $ox, $f)
  $glass = CA '#cfe8ff' 120
  $edge = C '#e8f6ff'
  # ガラス（上のつぼ）
  for ($y = 2; $y -le 8; $y++) {
    $hw = [int][math]::Max(1, [math]::Round(4.6 - ($y - 2) * 0.62))
    Rect $b ($ox + 6 - $hw) $y (2 * $hw) 1 $glass
    Px $b ($ox + 6 - $hw) $y $edge; Px $b ($ox + 5 + $hw) $y $edge
  }
  for ($y = 9; $y -le 15; $y++) {
    $hw = [int][math]::Max(1, [math]::Round(1.0 + ($y - 9) * 0.62))
    Rect $b ($ox + 6 - $hw) $y (2 * $hw) 1 $glass
    Px $b ($ox + 6 - $hw) $y $edge; Px $b ($ox + 5 + $hw) $y $edge
  }
  $t = $f / 7.0
  $topN = [int][math]::Round(7 * (1 - $t)); $botN = [int][math]::Round(7 * $t)
  for ($i = 0; $i -lt $topN; $i++) {
    $y = 8 - $i
    $hw = [int][math]::Max(1, [math]::Round(4.6 - ($y - 2) * 0.62)) - 1
    if ($hw -lt 1) { $hw = 1 }
    Rect $b ($ox + 6 - $hw) $y (2 * $hw) 1 $gd2
  }
  for ($i = 0; $i -lt $botN; $i++) {
    $y = 15 - $i
    $hw = [int][math]::Max(1, [math]::Round(1.0 + ($y - 9) * 0.62)) - 1
    if ($hw -lt 1) { $hw = 1 }
    Rect $b ($ox + 6 - $hw) $y (2 * $hw) 1 $gd2
  }
  if ($f -lt 7) { for ($y = 8; $y -le (14 - $botN); $y++) { Px $b ($ox + 5) $y $gd3; Px $b ($ox + 6) $y $gd3 } }
  Rect $b ($ox + 0) 0 12 2 $wd3; Rect $b ($ox + 0) 0 12 1 $wd4; Rect $b ($ox + 0) 16 12 2 $wd3; Rect $b ($ox + 0) 17 12 1 $wd1
  Rect $b ($ox + 1) 2 1 14 $wd2; Rect $b ($ox + 10) 2 1 14 $wd1
  Outline $b $ox 12 18 $ink
}

# ---- つるすランタン 16x34 4コマ（炎がゆれて、ひもの房がゆれる）
Sheet 'nazotoki_lantern.png' 16 34 4 {
  param($b, $ox, $f)
  for ($y = 0; $y -lt 6; $y++) { Px $b ($ox + 8) $y $(if ($y % 2 -eq 0) { $ir3 } else { $ir1 }) }
  Rect $b ($ox + 5) 6 6 1 $ir1; Rect $b ($ox + 3) 7 10 2 $ir1; Rect $b ($ox + 3) 7 10 1 $ir2; Rect $b ($ox + 2) 9 12 0 $ir0; Rect $b ($ox + 2) 9 12 1 $ir0
  $gl = @($or2, $or3, $or2, $or1)[$f]
  Rect $b ($ox + 3) 10 10 15 $gl
  Ellipse $b ($ox + 8) 17 3.8 5.8 $or3
  $fh = @(3.2, 3.8, 3.4, 2.8)[$f]
  Ellipse $b ($ox + 8) 18 1.8 $fh $or4
  Rect $b ($ox + 3) 10 1 15 $ir1; Rect $b ($ox + 12) 10 1 15 $ir1; Rect $b ($ox + 7) 10 2 1 $ir1; Rect $b ($ox + 7) 24 2 1 $ir1
  Rect $b ($ox + 2) 25 12 1 $ir1; Rect $b ($ox + 4) 26 8 2 $ir1; Rect $b ($ox + 4) 26 8 1 $ir2; Rect $b ($ox + 6) 28 4 1 $ir0
  $sx = @(0, 1, 0, -1)[$f]
  Rect $b ($ox + 8 + $sx) 29 1 3 $rd2
  Rect $b ($ox + 7 + $sx) 31 3 3 $gd2; Rect $b ($ox + 8 + $sx) 31 1 3 $gd3
  Outline $b $ox 16 34 $ink
}

# ---- ランタンの明かり 48x48 4コマ（ゆらぐ半透明の光）
Sheet 'nazotoki_glow.png' 48 48 4 {
  param($b, $ox, $f)
  $sc = @(1.0, 0.93, 0.97, 0.89)[$f]
  $i = 0
  foreach ($r in @(1.0, 0.76, 0.54, 0.32)) { Ellipse $b ($ox + 24) 24 (24 * $r * $sc) (24 * $r * $sc) (CA '#ff9a2e' (12 + $i * 11)); $i++ }
}
# ---- 床に落ちる光だまり 44x22
Sheet 'nazotoki_glowfloor.png' 44 22 1 {
  param($b, $ox, $f)
  $i = 0
  foreach ($r in @(1.0, 0.78, 0.56, 0.34)) { Ellipse $b 22 11 (22 * $r) (11 * $r) (CA '#ff9a2e' (16 + $i * 14)); $i++ }
}

# ---- ふわふわ浮かぶ？マーク 14x20 8コマ（上下にゆれて、まわりが光る）
Sheet 'nazotoki_qmark.png' 14 20 8 {
  param($b, $ox, $f)
  $ph = 2 * [math]::PI * $f / 8
  $bob = [int][math]::Round(2 * [math]::Sin($ph))
  $cyy = 10 + $bob
  Ellipse $b ($ox + 7) $cyy 6.5 8 (CA '#6ae6ff' (26 + ($f % 4) * 9))
  foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1), @(1, 1), @(-1, -1))) { AsciiCol $b ($ox + 4 + $d[0]) (5 + $bob + $d[1]) $qRows $n1 }
  $fc = if (($f % 4) -lt 2) { $cy3 } else { (C '#ffffff') }
  AsciiCol $b ($ox + 4) (5 + $bob) $qRows $fc
  AsciiCol $b ($ox + 4) (5 + $bob) @('.##....', '#......') $cy2
  if (($f % 4) -eq 1) { Star4 $b ($ox + 12) (3 + $bob) 1 $gd4 }
  if (($f % 4) -eq 3) { Star4 $b ($ox + 2) (15 + $bob) 1 $gd4 }
}

# ---- ひらめき（電球）16x22 4コマ（ぱっと光る）
Sheet 'nazotoki_idea.png' 16 22 4 {
  param($b, $ox, $f)
  $lit = ($f -ge 1)
  $bc = if ($lit) { $gd3 } else { C '#a0a0b8' }
  if ($lit) { Ellipse $b ($ox + 8) 9 7 7.5 (CA '#ffe27a' 56) }
  Ellipse $b ($ox + 8) 9 4.8 5.4 $bc
  Rect $b ($ox + 6) 13 4 3 $bc
  if ($lit) { Ellipse $b ($ox + 7) 7 2 2.2 $gd4; Px $b ($ox + 6) 6 (C '#ffffff') }
  $fil = if ($lit) { $or2 } else { $ir2 }
  Line $b ($ox + 6) 9 ($ox + 7) 11 $fil; Line $b ($ox + 7) 11 ($ox + 8) 9 $fil; Line $b ($ox + 8) 9 ($ox + 9) 11 $fil
  Rect $b ($ox + 6) 16 4 1 $ir3; Rect $b ($ox + 6) 17 4 1 $ir2; Rect $b ($ox + 7) 18 2 1 $ir1
  Outline $b $ox 16 22 $ink
  $rc = $gd3
  if ($f -ge 1) {
    $l = @(0, 2, 3, 2)[$f]
    Line $b ($ox + 8) 0 ($ox + 8) (1 + 0) $rc
    Line $b ($ox + 1) 3 ($ox + 3 - ($l - 2)) 5 $rc; Line $b ($ox + 14) 3 ($ox + 12 + ($l - 2)) 5 $rc
    Line $b ($ox + 0) 9 ($ox + 1 + (3 - $l)) 9 $rc; Line $b ($ox + 15) 9 ($ox + 14 - (3 - $l)) 9 $rc
    if ($f -eq 2) { Line $b ($ox + 2) 14 ($ox + 4) 12 $rc; Line $b ($ox + 13) 14 ($ox + 11) 12 $rc }
  }
}

# ---- きらきらの星の層 192x100 8コマ（ところどころでまたたく）
Sheet 'nazotoki_sparkle.png' 192 100 8 {
  param($b, $ox, $f)
  $rng = New-Object System.Random 61
  $cols = @('#ffe27a', '#c4f8ff', '#ffffff')
  for ($i = 0; $i -lt 18; $i++) {
    $sx = $rng.Next(6, 186); $sy = $rng.Next(4, 96); $ph = $rng.Next(0, 8)
    $t = ($f + $ph) % 8
    $s = @(0, 1, 2, 3, 2, 1, 0, 0)[$t]
    $col = $cols[$i % 3]
    if ($s -eq 1) { Px $b ($ox + $sx) $sy (CA $col 150) }
    elseif ($s -eq 2) { Px $b ($ox + $sx) $sy (CA $col 230); foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) { Px $b ($ox + $sx + $d[0]) ($sy + $d[1]) (CA $col 120) } }
    elseif ($s -eq 3) { Star4 $b ($ox + $sx) $sy 2 (CA $col 220); Px $b ($ox + $sx) $sy (C '#ffffff') }
  }
}

# ---- 小さな丸テーブル 38x26（紫のテーブルかけ・金のふち）
Sheet 'nazotoki_ptable.png' 38 26 1 {
  param($b, $ox, $f)
  Ellipse $b 19 8 18.5 7 $gd1
  Ellipse $b 19 7.6 17.4 6.2 $v3
  Ellipse $b 19 7.6 15 5 $v2
  for ($y = 9; $y -lt 22; $y++) {
    $hw = if ($y -lt 14) { 18 } else { 18 - ($y - 14) * 0.15 }
    for ($x = [int][math]::Ceiling(19 - $hw); $x -le [int][math]::Floor(18 + $hw); $x++) {
      $c = if ((($x + 1) % 7) -eq 0) { $v1 } elseif ((($x + 1) % 7) -eq 1) { $v3 } else { $v2 }
      Px $b $x $y $c
    }
  }
  Ellipse $b 19 8 18.5 7 $gd1; Ellipse $b 19 7.6 17.4 6.2 $v3; Ellipse $b 19 7.6 15 5 $v2
  Rect $b 1 14 36 1 $gd1
  for ($x = 1; $x -lt 37; $x++) { $d = if ((($x - 1) % 5) -lt 3) { 2 } else { 1 }; Rect $b $x 20 1 $d $gd1; Px $b $x (20 + $d) $gd0 }
  Glyph $b 8 15 2 $gd2; Glyph $b 16 15 6 $gd2; Glyph $b 24 15 4 $gd2
  Outline $b 0 38 26 $ink
}

# ---- 大きな鍵つきの宝箱 32x26（鎖と南京錠）
Sheet 'nazotoki_trunk.png' 32 26 1 {
  param($b, $ox, $f)
  Ellipse $b 16 9 15 8 $wd3
  Rect $b 1 9 30 14 $wd2
  Rect $b 1 9 30 1 $wd1
  for ($y = 13; $y -lt 23; $y += 4) { Rect $b 1 $y 30 1 $wd1 }
  Rect $b 1 9 1 14 $wd3; Rect $b 30 9 1 14 $wd1
  Rect $b 4 2 24 1 $wd4
  foreach ($bx in 5, 23) { Rect $b $bx 2 4 21 $ir1; Rect $b $bx 2 1 21 $ir2; Rect $b ($bx + 3) 2 1 21 $ir0; Px $b ($bx + 1) 12 $gd2; Px $b ($bx + 1) 20 $gd2 }
  Rect $b 1 22 30 1 $wd0
  # 鎖
  $nn = 20
  for ($i = 0; $i -le $nn; $i++) {
    $c = if ($i % 2 -eq 0) { $ir3 } else { $ir1 }
    $x1 = [int][math]::Round(2 + 27 * $i / $nn); $y1 = [int][math]::Round(10 + 11 * $i / $nn)
    Px $b $x1 $y1 $c; Px $b ($x1 + 1) $y1 $c; Px $b $x1 ($y1 + 1) $c
    $x2 = [int][math]::Round(29 - 27 * $i / $nn)
    Px $b $x2 $y1 $c; Px $b ($x2 + 1) $y1 $c; Px $b ($x2 + 1) ($y1 + 1) $c
  }
  # 南京錠
  Rect $b 13 10 1 5 $ir3; Rect $b 18 10 1 5 $ir3; Rect $b 14 9 4 1 $ir3
  Rect $b 12 14 8 7 $gd1; Rect $b 12 14 8 1 $gd3; Rect $b 12 14 1 7 $gd2; Rect $b 12 20 8 1 $gd0; Rect $b 19 15 1 6 $gd0
  Rect $b 15 16 2 2 $n0; Px $b 15 18 $n0; Px $b 16 18 $n0
  Outline $b 0 32 26 $ink
}

# ---- ヒントの立て看板（イーゼル）30x46
Sheet 'nazotoki_easel.png' 30 46 1 {
  param($b, $ox, $f)
  Thick $b 15 8 4 45 2 $wd2; Thick $b 15 8 26 45 2 $wd1
  Line $b 15 10 15 44 $wd0
  Rect $b 2 3 26 30 $wd3; Rect $b 2 3 26 1 $wd4; Rect $b 27 3 1 30 $wd1; Rect $b 2 32 26 1 $wd1
  Rect $b 4 5 22 25 $n2; Frame $b 4 5 22 25 $gd1
  # 大きな？（2倍）
  for ($j = 0; $j -lt $qRows.Count; $j++) { for ($i = 0; $i -lt 7; $i++) { if ([string]$qRows[$j][$i] -eq '#') { Rect $b (8 + $i * 2) (7 + $j * 2) 2 2 $gd3 } } }
  Glyph $b 8 26 6 $cy2; Glyph $b 14 26 3 $cy2; Glyph $b 20 26 9 $cy2
  Rect $b 1 33 28 2 $wd2; Rect $b 1 33 28 1 $wd3
  Star4 $b 24 9 1 $cy3
  Outline $b 0 30 46 $ink
}

# ---- 人物の上に重ねる絵（96x64、人物と同じ原点）
$brC = C '#7a5a36'; $brD = C '#4a3420'; $brL = C '#a8844e'
Sheet 'nazotoki_hat_fedora.png' 96 64 1 {
  param($b, $ox, $f)
  # 中折れ帽（探偵）
  Rect $b 44 19 9 6 $brC
  Rect $b 45 18 7 1 $brL; Rect $b 44 19 1 5 $brL
  Rect $b 48 19 1 2 $brD; Rect $b 49 19 1 1 $brD
  Rect $b 44 23 9 2 $v1; Rect $b 44 23 9 1 $v2; Px $b 51 23 $gd3; Px $b 51 24 $gd2
  Rect $b 41 25 15 2 $brC; Rect $b 41 25 15 1 $brL
  Rect $b 40 26 2 1 $brC; Rect $b 55 26 2 1 $brC
  Px $b 41 27 $brD; Px $b 55 27 $brD
  Rect $b 43 27 11 1 $brD
  # トレンチコートの襟とネクタイ
  Rect $b 42 34 12 4 $brL
  Rect $b 42 34 2 4 $brC; Rect $b 52 34 2 4 $brC
  Rect $b 44 34 8 1 $brD
  Px $b 46 34 $brD; Px $b 50 34 $brD
  Rect $b 47 35 2 3 $rd1; Rect $b 47 35 2 1 $rd2
  Rect $b 46 35 1 3 $pp3; Rect $b 49 35 1 3 $pp3
}
Sheet 'nazotoki_hat_beret.png' 96 64 1 {
  param($b, $ox, $f)
  # ベレー帽とマフラー（ヒント係）
  $wn0 = C '#5a1a40'; $wn1 = C '#8a2a5a'; $wn2 = C '#b84a80'
  Ellipse $b 49 23 7.8 3.9 $wn1
  Ellipse $b 48 22 5.5 2.2 $wn2
  for ($x = 42; $x -le 56; $x++) { Px $b $x 26 $wn0 }
  Rect $b 41 25 2 1 $wn0; Rect $b 55 25 2 1 $wn0
  Rect $b 49 19 2 2 $wn0; Px $b 50 18 $wn0
  Star4 $b 45 24 1 $gd3
  # マフラー
  for ($x = 43; $x -le 53; $x++) { $c = if (($x % 4) -lt 2) { $cy1 } else { $cy3 }; Px $b $x 34 $c; Px $b $x 35 $c }
  Rect $b 52 36 3 4 $cy1; Rect $b 53 36 1 4 $cy3
  Px $b 52 40 $cy1; Px $b 54 40 $cy3; Px $b 53 40 $cy1
}
Sheet 'nazotoki_hat_glasses.png' 96 64 1 {
  param($b, $ox, $f)
  # まるメガネと蝶ネクタイ（部員）
  $fr = C '#d8dcf8'
  Rect $b 47 29 3 1 $fr; Rect $b 50 29 3 1 $fr
  Rect $b 47 32 3 1 $fr; Rect $b 50 32 3 1 $fr
  Rect $b 47 30 1 2 $fr; Rect $b 49 30 1 2 $fr; Rect $b 50 30 1 2 $fr; Rect $b 52 30 1 2 $fr
  Rect $b 45 30 2 1 $fr; Rect $b 53 30 2 1 $fr
  
  # 蝶ネクタイ
  Rect $b 45 34 2 2 $rd2; Rect $b 51 34 2 2 $rd2; Rect $b 47 34 4 2 $rd1; Px $b 48 34 $rd2; Px $b 49 35 $gd3
  Rect $b 46 36 6 1 (C '#f0f0ff')
}
