# アマチュア無線部（交信ブース）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/amateurradio.ps1
# 出力: client/public/brand/stall/amateurradio_*.png （配置は scripts/stalls/amateurradio.mjs）
# 配色: 深い緑の壁・木の床・金属グレー・アンバーの表示・空色の電波。コールサイン風の札はすべて架空の伏せ字（JA0XXX など）。
# アニメは「フレームを横一列に並べたPNG」で、amateurradio.mjs の k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
# 確認用: 環境変数 AR_ONLY（正規表現）に合う絵だけ作り直す（例: $env:AR_ONLY='sign|rig'）
. "$PSScriptRoot\..\lib\pixel.ps1"

function CAc($c, $a) { [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function Sheet($name, $w, $h, $n, $draw) {
  if ($env:AR_ONLY -and ($name -notmatch $env:AR_ONLY)) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}
function Hs($n) { return ((([int]$n * 73 + 19) * 31 + [int]$n * [int]$n * 7) % 97) }
# 小数の座標でも安全な線（Line は整数だけ）
function Ln($b, $x0, $y0, $x1, $y1, $col) {
  Line $b ([int][math]::Round($x0)) ([int][math]::Round($y0)) ([int][math]::Round($x1)) ([int][math]::Round($y1)) $col
}
# 円の輪（電波の波紋）。$minDx 以上の側だけ描く
function Ring($b, $cx, $cy, $rad, $col, $minDx) {
  $x0 = [int][math]::Floor($cx - $rad - 2); $x1 = [int][math]::Ceiling($cx + $rad + 2)
  $y0 = [int][math]::Floor($cy - $rad - 2); $y1 = [int][math]::Ceiling($cy + $rad + 2)
  for ($y = $y0; $y -le $y1; $y++) {
    for ($x = $x0; $x -le $x1; $x++) {
      $dx = $x + 0.5 - $cx; $dy = $y + 0.5 - $cy
      $d = [math]::Sqrt($dx * $dx + $dy * $dy)
      if ([math]::Abs($d - $rad) -lt 0.75 -and $dx -ge $minDx) { Px $b $x $y $col }
    }
  }
}

# ---- 色 ----
$m0 = C '#14181f'; $m1 = C '#262d3a'; $m2 = C '#3f4a5e'; $m3 = C '#6a778f'; $m4 = C '#a3b0c6'; $m5 = C '#dde5f0'; $wh = C '#fbfdff'
$g0 = C '#0e211d'; $g1 = C '#18362f'; $g2 = C '#27584a'; $g3 = C '#3f8a72'; $g4 = C '#7cc4a6'
$am0 = C '#7a3d0a'; $am1 = C '#e8861a'; $am2 = C '#ffb52e'; $am3 = C '#ffe49a'
$rd0 = C '#6e1220'; $rd1 = C '#dc3248'; $rd2 = C '#ff8a96'
$sk0 = C '#183f78'; $sk1 = C '#3279cc'; $sk2 = C '#86c8ff'; $sk3 = C '#d8f1ff'
$wd0 = C '#4a2f1c'; $wd1 = C '#7e5230'; $wd2 = C '#b07d4c'; $wd3 = C '#d9ad78'
$lcd0 = C '#0b2418'; $lcd1 = C '#7dff7a'; $lcd2 = C '#c6ffb0'
$oc0 = C '#102f5c'; $oc1 = C '#1d5a9e'; $oc2 = C '#3b8ad6'; $oc3 = C '#7ab8f0'
$ld0 = C '#2a6b34'; $ld1 = C '#46a244'; $ld2 = C '#8fd264'; $ld3 = C '#c5eb8a'
$cr = C '#f4ead0'; $cr2 = C '#c9b58a'

# ---- 3x5 の小さな文字（大文字だけ。ハッシュのキーは大文字小文字を区別しないので大文字で統一）
$f3 = @{
  'A' = @('.X.', 'X.X', 'XXX', 'X.X', 'X.X'); 'B' = @('XX.', 'X.X', 'XX.', 'X.X', 'XX.'); 'C' = @('.XX', 'X..', 'X..', 'X..', '.XX')
  'D' = @('XX.', 'X.X', 'X.X', 'X.X', 'XX.'); 'E' = @('XXX', 'X..', 'XX.', 'X..', 'XXX'); 'F' = @('XXX', 'X..', 'XX.', 'X..', 'X..')
  'G' = @('.XX', 'X..', 'X.X', 'X.X', '.XX'); 'H' = @('X.X', 'X.X', 'XXX', 'X.X', 'X.X'); 'I' = @('XXX', '.X.', '.X.', '.X.', 'XXX')
  'J' = @('..X', '..X', '..X', 'X.X', '.X.'); 'K' = @('X.X', 'X.X', 'XX.', 'X.X', 'X.X'); 'L' = @('X..', 'X..', 'X..', 'X..', 'XXX')
  'M' = @('X.X', 'XXX', 'XXX', 'X.X', 'X.X'); 'N' = @('XX.', 'X.X', 'X.X', 'X.X', 'X.X'); 'O' = @('.X.', 'X.X', 'X.X', 'X.X', '.X.')
  'P' = @('XX.', 'X.X', 'XX.', 'X..', 'X..'); 'Q' = @('XXX', 'X.X', 'X.X', 'XXX', '..X'); 'R' = @('XX.', 'X.X', 'XX.', 'X.X', 'X.X')
  'S' = @('.XX', 'X..', '.X.', '..X', 'XX.'); 'T' = @('XXX', '.X.', '.X.', '.X.', '.X.'); 'U' = @('X.X', 'X.X', 'X.X', 'X.X', 'XXX')
  'V' = @('X.X', 'X.X', 'X.X', 'X.X', '.X.'); 'W' = @('X.X', 'X.X', 'XXX', 'XXX', 'X.X'); 'X' = @('X.X', 'X.X', '.X.', 'X.X', 'X.X')
  'Y' = @('X.X', 'X.X', '.X.', '.X.', '.X.'); 'Z' = @('XXX', '..X', '.X.', 'X..', 'XXX')
  '0' = @('XXX', 'X.X', 'X.X', 'X.X', 'XXX'); '1' = @('.X.', 'XX.', '.X.', '.X.', 'XXX'); '2' = @('XX.', '..X', '.X.', 'X..', 'XXX')
  '3' = @('XX.', '..X', '.X.', '..X', 'XX.'); '4' = @('X.X', 'X.X', 'XXX', '..X', '..X'); '5' = @('XXX', 'X..', 'XX.', '..X', 'XX.')
  '7' = @('XXX', '..X', '.X.', '.X.', '.X.'); '.' = @('...', '...', '...', '...', '.X.'); '-' = @('...', '...', 'XXX', '...', '...')
}
function T3($b, $text, $x, $y, $col) {
  $cx = $x
  foreach ($ch in $text.ToUpper().ToCharArray()) {
    $k = [string]$ch
    if ($f3.ContainsKey($k)) {
      $g = $f3[$k]
      for ($r = 0; $r -lt 5; $r++) { for ($c = 0; $c -lt 3; $c++) { if ($g[$r].Substring($c, 1) -eq 'X') { Px $b ($cx + $c) ($y + $r) $col } } }
    }
    $cx += 4
  }
  return ($cx - $x - 1)
}

# ---- 世界地図の陸地マスク（72x36。左端が西経180度、上が北極）。多角形で描いた、ざっくりした架空寄りの形
function PolyFill($m, $pts) {
  $n = $pts.Count
  for ($py = 0; $py -lt 36; $py++) {
    for ($px = 0; $px -lt 72; $px++) {
      $cxp = $px + 0.5; $cyp = $py + 0.5
      $inside = $false
      $j = $n - 1
      for ($i = 0; $i -lt $n; $i++) {
        $xi = $pts[$i][0]; $yi = $pts[$i][1]; $xj = $pts[$j][0]; $yj = $pts[$j][1]
        if ((($yi -gt $cyp) -ne ($yj -gt $cyp)) -and ($cxp -lt ($xj - $xi) * ($cyp - $yi) / ($yj - $yi) + $xi)) { $inside = -not $inside }
        $j = $i
      }
      if ($inside) { $m[$px, $py] = $true }
    }
  }
}
$land = New-Object 'bool[,]' 72, 36
$polys = @(
  @(@(6, 5), @(14, 3), @(22, 4), @(26, 2), @(30, 3), @(27, 7), @(24, 10), @(22, 13), @(19, 14), @(17, 12), @(14, 12), @(11, 9), @(8, 8)),
  @(@(28, 1), @(34, 1), @(33, 4), @(29, 5)),
  @(@(20, 15), @(26, 15), @(30, 18), @(28, 24), @(25, 30), @(23, 32), @(22, 26), @(21, 20)),
  @(@(34, 5), @(40, 4), @(46, 5), @(45, 9), @(40, 11), @(36, 10)),
  @(@(36, 12), @(44, 11), @(48, 15), @(46, 22), @(43, 27), @(40, 26), @(38, 20), @(35, 16)),
  @(@(44, 5), @(52, 3), @(62, 3), @(70, 5), @(66, 9), @(62, 12), @(58, 16), @(54, 14), @(52, 18), @(50, 14), @(46, 10)),
  @(@(60, 24), @(67, 24), @(68, 28), @(63, 29), @(60, 27))
)
if (-not $env:AR_ONLY -or ('amateurradio_map_screen amateurradio_globe_lamp' -match $env:AR_ONLY)) {
  foreach ($pl in $polys) { PolyFill $land $pl }
}
# 交信した場所（ピン）。(u, v) は 72x36 の地図上
$pins = @(@(10, 9), @(40, 8), @(25, 22), @(66, 26), @(44, 20), @(52, 6), @(30, 4), @(61, 16))
$hmPin = @(64, 10)

# ====================================================================
# 看板 132x30（「アマチュア無線部」が点滅し、枠のLEDが流れ、両脇のアンテナから電波が広がる）4コマ
Sheet 'amateurradio_sign.png' 132 30 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 132 30 $g0
  Rect $b ($ox + 3) 3 126 24 $g1
  Rect $b ($ox + 3) 3 126 1 $g2
  for ($x = 2; $x -lt 130; $x++) {
    $lit = ((($x + $f * 2) % 8) -lt 3)
    $c = if ($lit) { $am3 } else { $am1 }
    Px $b ($ox + $x) 2 $c; Px $b ($ox + 131 - $x) 27 $c
  }
  for ($y = 2; $y -lt 28; $y++) {
    $lit = ((($y + $f * 2) % 8) -lt 3)
    $c = if ($lit) { $am3 } else { $am1 }
    Px $b ($ox + 2) $y $c; Px $b ($ox + 129) $y $c
  }
  $txt = 'アマチュア無線部'
  [void](TextPx $b $txt ($ox + 19) 6 12 $g0 $true)
  $tc = if ($f -lt 2) { $am3 } else { $am1 }
  [void](TextPx $b $txt ($ox + 18) 5 12 $tc $true)
  [void](T3 $b 'AMATEUR RADIO CLUB' ($ox + 30) 21 $g4)
  # 両脇のアンテナと電波
  foreach ($side in 0, 1) {
    for ($y = 8; $y -lt 24; $y++) {
      $xx = if ($side -eq 0) { 8 } else { 123 }
      Px $b ($ox + $xx) $y $m4
    }
    $sg = if ($side -eq 0) { 1 } else { -1 }
    $bx = if ($side -eq 0) { 8 } else { 123 }
    Px $b ($ox + $bx) 6 $am2; Px $b ($ox + $bx) 7 $am2
    Ln $b ($ox + $bx) 10 ($ox + $bx - 3 * $sg) 8 $m4; Ln $b ($ox + $bx) 10 ($ox + $bx + 3 * $sg) 8 $m4
    for ($k = 0; $k -lt 3; $k++) {
      if ((($f + 1) % 4) -gt $k) {
        $ax = $bx + (3 + $k * 2) * $sg
        $hl = 1 + $k
        for ($yy = 13 - $hl; $yy -le 13 + $hl; $yy++) { Px $b ($ox + $ax) $yy $am2 }
      }
    }
  }
  foreach ($p in @(@(0, 0), @(131, 0), @(0, 29), @(131, 29))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ====================================================================
# 床 192x128: 木の板張りに、真ん中は青い絨毯（入口から奥の地球儀へ）。ケーブルが足元を走る
Sheet 'amateurradio_floor.png' 192 128 1 {
  param($b, $ox, $f)
  $tones = @($wd3, (Mix $wd3 $wd2 0.3), (Mix $wd3 $wd2 0.12))
  $seam = Mix $wd3 $wd1 0.55
  $grain = Mix $wd3 $wd2 0.5
  for ($y = 0; $y -lt 128; $y++) {
    $row = [int][math]::Floor($y / 8)
    for ($x = 0; $x -lt 192; $x++) {
      $c = $tones[$row % 3]
      if (($y % 8) -eq 7) { $c = $seam }
      elseif ((($x + $row * 53) % 64) -eq 0) { $c = $seam }
      elseif ((Hs ($x * 3 + $y * 7)) % 17 -eq 0) { $c = $grain }
      Px $b ($ox + $x) $y $c
    }
  }
  # 絨毯
  Rect $b ($ox + 72) 54 48 74 $sk0
  Frame $b ($ox + 72) 54 48 74 $am2
  Frame $b ($ox + 74) 56 44 72 $sk1
  for ($yy = 64; $yy -lt 126; $yy += 12) {
    Px $b ($ox + 96) ($yy - 2) $sk2
    foreach ($d in @(@(-1, -1), @(0, -1), @(1, -1), @(-2, 0), @(-1, 0), @(0, 0), @(1, 0), @(2, 0), @(-1, 1), @(0, 1), @(1, 1), @(0, 2))) { Px $b ($ox + 96 + $d[0]) ($yy + $d[1]) $(if ($d[1] -eq 0) { $am2 } else { $sk2 }) }
  }
  for ($x = 72; $x -lt 120; $x += 2) { Px $b ($ox + $x) 53 $am1 }
  # ケーブル（アンテナの根元から机へ）
  foreach ($c in @(@(11, 60, 11, 72, 34, 80), @(181, 60, 181, 72, 158, 80))) {
    Ln $b ($ox + $c[0]) $c[1] ($ox + $c[2]) $c[3] $m1
    Ln $b ($ox + $c[2]) $c[3] ($ox + $c[4]) $c[5] $m1
    Ln $b ($ox + $c[0] + 1) $c[1] ($ox + $c[2] + 1) $c[3] $m3
  }
  Frame $b $ox 0 192 128 $wd1
}

# ====================================================================
# 奥の壁 184x38: 緑のパネルに穴あきボード。上に金属の梁、足元に木の幅木
Sheet 'amateurradio_wall.png' 184 38 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 184 38 $g2
  for ($x = 23; $x -lt 184; $x += 23) { Rect $b ($ox + $x) 4 1 29 $g1; Rect $b ($ox + $x + 1) 4 1 29 $g3 }
  for ($y = 6; $y -lt 32; $y += 4) { for ($x = 3; $x -lt 184; $x += 6) { Px $b ($ox + $x + (($y / 4) % 2) * 3) $y $g1 } }
  Rect $b $ox 0 184 4 $m2; Rect $b $ox 0 184 1 $m4; Rect $b $ox 3 184 1 $m1
  for ($x = 5; $x -lt 184; $x += 10) { Px $b ($ox + $x) 1 $m5; Px $b ($ox + $x) 2 $m1 }
  Rect $b $ox 33 184 5 $wd1; Rect $b $ox 33 184 1 $wd3; Rect $b $ox 37 184 1 $wd0
  for ($x = 0; $x -lt 184; $x += 14) { Px $b ($ox + $x) 35 $wd0 }
  Clear $b $ox 0; Clear $b ($ox + 183) 0
}

# ====================================================================
# QSLカード（交信証）の壁 84x31: 絵はがき風のカード6枚。コールサインはすべて架空の伏せ字
function Card($b, $x, $y, $kind, $txt, $tcol) {
  Rect $b $x $y 26 15 $cr
  Frame $b $x $y 26 15 $cr2
  $px = $x + 1; $py = $y + 1
  switch ($kind) {
    0 { # 空と丘とアンテナ
      Rect $b $px $py 24 6 $sk2
      Rect $b $px ($py + 4) 24 2 $ld1; Rect $b ($px + 6) ($py + 3) 12 1 $ld1; Rect $b ($px + 18) ($py + 3) 6 1 $ld0
      Rect $b ($px + 12) ($py + 1) 1 4 $m1; Px $b ($px + 11) ($py + 1) $m1; Px $b ($px + 13) ($py + 1) $m1; Px $b ($px + 12) $py $rd1
      Px $b ($px + 3) ($py + 1) $wh; Px $b ($px + 4) ($py + 1) $wh; Px $b ($px + 20) ($py + 2) $wh
    }
    1 { # 夕日の海
      Rect $b $px $py 24 3 $am2; Rect $b $px ($py + 2) 24 1 $am1
      Rect $b $px ($py + 3) 24 3 $sk0
      Ellipse $b ($px + 12) ($py + 3) 3.4 2.6 $rd1
      Rect $b ($px + 10) ($py + 4) 4 1 $am3; Rect $b ($px + 9) ($py + 5) 6 1 $am2
    }
    2 { # 夜の山
      Rect $b $px $py 24 6 $oc0
      foreach ($p in @(@(16, 0), @(17, 1), @(18, 2), @(19, 3), @(20, 4), @(15, 1), @(14, 2), @(13, 3), @(12, 4), @(11, 5), @(21, 5), @(10, 5), @(9, 5))) { Px $b ($px + $p[0] - 4) ($py + $p[1]) $m3 }
      Rect $b ($px + 5) ($py + 5) 14 1 $m2; Px $b ($px + 12) $py $wh; Px $b ($px + 12) ($py + 1) $m5
      Px $b ($px + 3) ($py + 1) $am3; Px $b ($px + 4) ($py + 1) $am3; Px $b ($px + 3) ($py + 2) $am3
      Px $b ($px + 20) ($py + 1) $wh; Px $b ($px + 7) $py $sk3
    }
    3 { # まちなみ
      Rect $b $px $py 24 6 $sk1
      $hs = @(3, 5, 4, 6, 3, 5, 4, 3)
      for ($i = 0; $i -lt 8; $i++) {
        Rect $b ($px + $i * 3) ($py + 6 - $hs[$i]) 3 $hs[$i] $m2
        Px $b ($px + $i * 3 + 1) ($py + 6 - $hs[$i] + 1) $am3
        if ($hs[$i] -gt 3) { Px $b ($px + $i * 3 + 1) ($py + 6 - $hs[$i] + 3) $am3 }
      }
    }
    4 { # 花畑
      Rect $b $px $py 24 6 $sk3
      Rect $b $px ($py + 3) 24 3 $ld1
      foreach ($p in @(@(3, 2, $rd1), @(8, 1, $am2), @(13, 2, $rd2), @(18, 1, $rd1), @(22, 2, $am2), @(6, 4, $rd2), @(15, 4, $am2), @(20, 4, $rd1))) { Px $b ($px + $p[0]) ($py + $p[1]) $p[2]; Px $b ($px + $p[0]) ($py + $p[1] + 1) $ld0 }
    }
    default { # 地球
      Rect $b $px $py 24 6 $m1
      Ellipse $b ($px + 12) ($py + 3) 5.4 2.9 $oc2
      Rect $b ($px + 9) ($py + 2) 3 2 $ld2; Rect $b ($px + 13) ($py + 3) 3 2 $ld2; Px $b ($px + 11) ($py + 1) $ld1
      Px $b ($px + 3) ($py + 1) $wh; Px $b ($px + 21) ($py + 4) $wh
    }
  }
  [void](T3 $b $txt ($x + 2) ($y + 8) $tcol)
  Px $b ($x + 12) $y $rd1; Px $b ($x + 13) $y $rd1
}
Sheet 'amateurradio_qsl.png' 84 31 1 {
  param($b, $ox, $f)
  $cs = @('JA0XXX', 'JH0XXX', 'JR0XXX', 'JE0XXX', 'JG0XXX', 'JA0XXX')
  $tcs = @($g1, $rd0, $sk0, $g1, $am0, $rd0)
  for ($i = 0; $i -lt 6; $i++) {
    $cx = $ox + ($i % 3) * 29; $cy = [int][math]::Floor($i / 3) * 16
    Card $b $cx $cy $i $cs[$i] $tcs[$i]
  }
  # 画びょうをつなぐ赤い糸
  for ($x = 26; $x -lt 29; $x++) { Px $b ($ox + $x) 7 $rd1 }
  for ($x = 55; $x -lt 58; $x++) { Px $b ($ox + $x) 7 $rd1 }
}

# ====================================================================
# 世界地図ボード 56x28（ピンの間を電波の光が行き来する）6コマ
Sheet 'amateurradio_map_screen.png' 56 28 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 56 28 $m0
  Rect $b ($ox + 1) 1 54 26 $m2
  Rect $b ($ox + 1) 1 54 1 $m4
  Rect $b ($ox + 2) 2 52 7 $g1
  [void](T3 $b 'DX MAP' ($ox + 4) 3 $am2)
  Rect $b ($ox + 43) 4 2 2 $(if ($f % 2 -eq 0) { $lcd1 } else { $g3 })
  Rect $b ($ox + 47) 4 2 2 $(if ($f % 3 -eq 0) { $rd1 } else { $rd0 })
  Rect $b ($ox + 2) 9 52 17 $oc0
  for ($yy = 0; $yy -lt 17; $yy++) {
    for ($xx = 0; $xx -lt 52; $xx++) {
      $u = [int][math]::Floor($xx * 72 / 52); $v = [int][math]::Floor($yy * 36 / 17)
      if ($v -gt 35) { $v = 35 }
      if ($land[$u, $v]) {
        $above = $false
        if ($yy -gt 0) { $v2 = [int][math]::Floor(($yy - 1) * 36 / 17); $above = -not $land[$u, $v2] }
        Px $b ($ox + 2 + $xx) (9 + $yy) $(if ($above) { $ld2 } else { $ld1 })
      }
      elseif (($xx % 13) -eq 0 -or ($yy % 6) -eq 0) { Px $b ($ox + 2 + $xx) (9 + $yy) $oc1 }
    }
  }
  $hx = 2 + [int][math]::Floor($hmPin[0] * 52 / 72); $hy = 9 + [int][math]::Floor($hmPin[1] * 17 / 36)
  $i = 0
  foreach ($p in $pins) {
    $tx = 2 + [int][math]::Floor($p[0] * 52 / 72); $ty = 9 + [int][math]::Floor($p[1] * 17 / 36)
    $n = 24
    for ($s = 0; $s -le $n; $s += 3) {
      Px $b ($ox + [int][math]::Round($hx + ($tx - $hx) * $s / $n)) ([int][math]::Round($hy + ($ty - $hy) * $s / $n)) $oc3
    }
    $t = (($f + $i) % 6) / 6.0
    $sx = [int][math]::Round($hx + ($tx - $hx) * $t); $sy = [int][math]::Round($hy + ($ty - $hy) * $t)
    Px $b ($ox + $sx) $sy $am3
    $pc = if ((($f + $i) % 3) -ne 0) { $rd1 } else { $rd0 }
    Rect $b ($ox + $tx) $ty 2 2 $pc
    $i++
  }
  $hc = if ($f % 2 -eq 0) { $am3 } else { $am1 }
  Rect $b ($ox + $hx - 1) ($hy - 1) 3 3 $m0
  Rect $b ($ox + $hx - 1) ($hy - 1) 2 2 $hc
  Clear $b $ox 0; Clear $b ($ox + 55) 0
}

# ====================================================================
# 地球儀（ランプで内側から光り、ゆっくり回る。交信した場所のピンが光る）8コマ
Sheet 'amateurradio_globe_lamp.png' 28 38 8 {
  param($b, $ox, $f)
  $cx = 14.0; $cy = 14.0; $rr = 11.5
  $rot = $f * 2.0 * [math]::PI / 8
  Ellipse $b ($ox + $cx) $cy 13.8 13.8 (CAc $sk2 60)
  $ocean = @((C '#0c2a55'), $oc0, $oc1, $oc2)
  $lands = @((C '#1e5226'), $ld0, $ld1, $ld2)
  for ($y = 0; $y -lt 28; $y++) {
    for ($x = 0; $x -lt 28; $x++) {
      $nx = ($x + 0.5 - $cx) / $rr; $ny = ($y + 0.5 - $cy) / $rr
      $s = $nx * $nx + $ny * $ny
      if ($s -gt 1) { continue }
      $nz = [math]::Sqrt(1 - $s)
      $lat = [math]::Asin(-$ny)
      $lon = [math]::Atan2($nx, $nz) + $rot
      $u = [int][math]::Floor((($lon / (2 * [math]::PI)) + 0.5) * 72); $u = (($u % 72) + 72) % 72
      $v = [int][math]::Floor((0.5 - $lat / [math]::PI) * 36); if ($v -lt 0) { $v = 0 }; if ($v -gt 35) { $v = 35 }
      $t = -0.42 * $nx - 0.5 * $ny + 0.75 * $nz
      $lv = if ($t -gt 0.62) { 3 } elseif ($t -gt 0.3) { 2 } elseif ($t -gt 0.0) { 1 } else { 0 }
      if ($s -gt 0.84) { $col = C '#0a1d3a' }
      elseif ($land[$u, $v]) { $col = $lands[$lv] }
      else { $col = $ocean[$lv] }
      Px $b ($ox + $x) $y $col
    }
  }
  # ふちのハイライト
  Px $b ($ox + 8) 5 $oc3; Px $b ($ox + 9) 4 $sk3; Px $b ($ox + 7) 6 $oc3
  # ピン
  $i = 0
  foreach ($p in $pins) {
    $lam = ($p[0] / 72.0 - 0.5) * 2 * [math]::PI
    $ph = $lam - $rot; $ph = [math]::Atan2([math]::Sin($ph), [math]::Cos($ph))
    $la = (0.5 - $p[1] / 36.0) * [math]::PI
    $vis = [math]::Cos($ph) * [math]::Cos($la)
    if ($vis -gt 0.25) {
      $pxx = $cx + $rr * [math]::Cos($la) * [math]::Sin($ph); $pyy = $cy - $rr * [math]::Sin($la)
      $pc = if ((($f + $i) % 2) -eq 0) { $rd2 } else { $rd1 }
      Px $b ($ox + [int][math]::Floor($pxx)) ([int][math]::Floor($pyy)) $pc
      Px $b ($ox + [int][math]::Floor($pxx)) ([int][math]::Floor($pyy) - 1) $wh
    }
    $i++
  }
  # 子午線の輪（左がわ）
  for ($y = 0; $y -lt 28; $y++) {
    for ($x = 0; $x -lt 28; $x++) {
      $dx = $x + 0.5 - $cx; $dy = $y + 0.5 - $cy
      $d = [math]::Sqrt($dx * $dx + $dy * $dy)
      if ([math]::Abs($d - 13.2) -lt 0.7 -and $dx -lt 1.5) { Px $b ($ox + $x) $y $(if ($dy -lt 0) { $m5 } else { $m3 }) }
    }
  }
  # 台
  Rect $b ($ox + 13) 25 2 7 $m3; Px $b ($ox + 13) 26 $m5
  Ellipse $b ($ox + $cx) 33.5 9.5 3.4 $m0
  Ellipse $b ($ox + $cx) 33 8.6 2.8 $m3
  Ellipse $b ($ox + $cx) 32.6 6.6 1.8 $m4
  Rect $b ($ox + 8) 34 12 3 $m1; Rect $b ($ox + 8) 34 12 1 $m2
  Px $b ($ox + 10) 35 $am2; Px $b ($ox + 17) 35 $(if ($f % 2 -eq 0) { $lcd1 } else { $g3 })
  Clear $b ($ox + 8) 36; Clear $b ($ox + 19) 36
}

# ====================================================================
# 床の波紋 100x44: 地球儀の足もとから電波の輪がひろがる 6コマ
Sheet 'amateurradio_glow.png' 100 44 6 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 50) 22 15 5.6 (CAc $am2 45)
  Ellipse $b ($ox + 50) 22 9 3.3 (CAc $am3 60)
  for ($k = 0; $k -lt 3; $k++) {
    $ph = ($f + $k * 2) % 6
    $rx = 9 + $ph * 7.0; $ry = $rx * 0.40
    $al = [int](185 - $ph * 29)
    $col = CAc $sk3 $al
    for ($y = 0; $y -lt 44; $y++) {
      for ($x = 0; $x -lt 100; $x++) {
        $dx = ($x + 0.5 - 50) / $rx; $dy = ($y + 0.5 - 22) / $ry
        $d = [math]::Sqrt($dx * $dx + $dy * $dy)
        if ([math]::Abs($d - 1) * [math]::Sqrt($rx * $ry) -lt 0.85) { Px $b ($ox + $x) $y $col }
      }
    }
  }
}

# ====================================================================
# アンテナ塔（格子のタワー）24x70 4コマ。左: 垂直アンテナ(GP)  右: ダイポール
function Lattice($b, $ox, $cx, $y0, $y1, $hw0, $hw1) {
  for ($y = $y0; $y -le $y1; $y++) {
    $hw = [int][math]::Round($hw0 + ($hw1 - $hw0) * ($y - $y0) / ($y1 - $y0))
    Px $b ($ox + $cx - $hw) $y $m4; Px $b ($ox + $cx - $hw + 1) $y $m3
    Px $b ($ox + $cx + $hw) $y $m1; Px $b ($ox + $cx + $hw - 1) $y $m2
  }
  for ($yy = $y0; $yy + 7 -le $y1; $yy += 7) {
    $ha = [int][math]::Round($hw0 + ($hw1 - $hw0) * ($yy - $y0) / ($y1 - $y0))
    $hb = [int][math]::Round($hw0 + ($hw1 - $hw0) * ($yy + 7 - $y0) / ($y1 - $y0))
    if ((($yy - $y0) / 7) % 2 -eq 0) { Ln $b ($ox + $cx - $ha + 1) $yy ($ox + $cx + $hb - 1) ($yy + 7) $m3 } else { Ln $b ($ox + $cx + $ha - 1) $yy ($ox + $cx - $hb + 1) ($yy + 7) $m3 }
    Ln $b ($ox + $cx - $ha + 1) $yy ($ox + $cx + $ha - 1) $yy $m2
  }
  # 土台
  Rect $b ($ox + 3) 66 18 4 $m0; Rect $b ($ox + 4) 66 16 2 $m3; Rect $b ($ox + 4) 66 16 1 $m5
  Rect $b ($ox + $cx - 3) 20 7 2 $m3; Rect $b ($ox + $cx - 3) 20 7 1 $m5
}
Sheet 'amateurradio_tower_gp.png' 24 70 4 {
  param($b, $ox, $f)
  Lattice $b $ox 12 22 66 2 7
  Rect $b ($ox + 11) 6 2 15 $m4; Rect $b ($ox + 12) 6 1 15 $m3
  Rect $b ($ox + 12) 3 1 4 $m5
  Ln $b ($ox + 12) 14 ($ox + 2) 20 $m5; Ln $b ($ox + 12) 14 ($ox + 22) 20 $m5
  Ln $b ($ox + 12) 15 ($ox + 5) 20 $m4; Ln $b ($ox + 12) 15 ($ox + 19) 20 $m4
  Px $b ($ox + 2) 21 $am2; Px $b ($ox + 22) 21 $am2
  # ビーコン
  if ($f % 2 -eq 0) {
    Rect $b ($ox + 11) 0 3 3 $rd1; Px $b ($ox + 11) 0 $rd2
    Px $b ($ox + 9) 1 (CAc $rd2 130); Px $b ($ox + 15) 1 (CAc $rd2 130); Px $b ($ox + 12) 0 $wh
  } else {
    Rect $b ($ox + 11) 0 3 3 $rd0
  }
}
Sheet 'amateurradio_tower_dipole.png' 24 70 4 {
  param($b, $ox, $f)
  Lattice $b $ox 12 22 66 2 7
  Rect $b ($ox + 11) 9 2 12 $m4; Rect $b ($ox + 12) 9 1 12 $m3; Rect $b ($ox + 12) 4 1 3 $m4
  # 逆Vのワイヤー
  Ln $b ($ox + 12) 7 ($ox + 1) 13 $m5; Ln $b ($ox + 12) 8 ($ox + 1) 14 $m3
  Ln $b ($ox + 12) 7 ($ox + 22) 13 $m5; Ln $b ($ox + 12) 8 ($ox + 22) 14 $m3
  Rect $b ($ox + 11) 6 3 3 $wh; Px $b ($ox + 12) 7 $sk1
  Rect $b ($ox + 0) 13 2 2 $sk2; Rect $b ($ox + 22) 13 2 2 $sk2
  # 旗（ワイヤーに下げた小さな三角旗がゆれる）
  $wv = @(0, 1, 0, -1)[$f]
  foreach ($pf in @(@(4, 11, $am2), @(8, 9, $rd1), @(16, 9, $am2), @(20, 11, $rd1))) {
    Px $b ($ox + $pf[0]) ($pf[1] + 2) $pf[2]; Px $b ($ox + $pf[0] + $wv) ($pf[1] + 3) $pf[2]; Px $b ($ox + $pf[0]) ($pf[1] + 3) $pf[2]; Px $b ($ox + $pf[0] + $wv) ($pf[1] + 4) $pf[2]
  }
  # ビーコン（左と交互）
  Rect $b ($ox + 11) 1 3 3 $(if ($f % 2 -eq 1) { $rd1 } else { $rd0 })
  if ($f % 2 -eq 1) { Px $b ($ox + 11) 1 $rd2; Px $b ($ox + 9) 2 (CAc $rd2 130); Px $b ($ox + 15) 2 (CAc $rd2 130) }
}

# ====================================================================
# アンテナの先から広がる電波 44x30 6コマ
Sheet 'amateurradio_beam.png' 44 30 6 {
  param($b, $ox, $f)
  for ($k = 0; $k -lt 2; $k++) {
    $ph = ($f + $k * 3) % 6
    $rad = 3 + $ph * 3
    $al = [int](210 - $ph * 32)
    Ring $b ($ox + 22) 15 $rad (CAc $sk3 $al) (-999)
  }
  Px $b ($ox + 22) 15 $wh
}

# ====================================================================
# 無線機（トランシーバー）38x25: 周波数表示が変わり、Sメーターの光が跳ね、つまみの針が回る 6コマ
Sheet 'amateurradio_rig_screen.png' 38 25 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 38 23 $m0
  Rect $b ($ox + 1) 1 36 21 $m2
  Rect $b ($ox + 1) 1 36 1 $m4
  Rect $b ($ox + 1) 21 36 1 $m1
  # 表示
  Rect $b ($ox + 3) 3 26 12 $m0
  Rect $b ($ox + 4) 4 24 10 $lcd0
  $fq = '14.2' + @('05', '10', '15', '20', '25', '30')[$f]
  [void](T3 $b $fq ($ox + 5) 5 $lcd1)
  $lev = @(3, 6, 8, 5, 9, 4)[$f]
  for ($s = 0; $s -lt 10; $s++) {
    $on = ($s -lt $lev)
    $c = if ($s -lt 6) { $(if ($on) { $lcd1 } else { C '#16402a' }) } elseif ($s -lt 8) { $(if ($on) { $am2 } else { C '#4a3a14' }) } else { $(if ($on) { $rd1 } else { C '#4a1a22' }) }
    Rect $b ($ox + 5 + $s * 2) 11 1 2 $c
  }
  # つまみ
  Ellipse $b ($ox + 33.5) 9.5 4.8 4.8 $m0
  Ellipse $b ($ox + 33.5) 9.5 3.8 3.8 $m3
  Px $b ($ox + 31) 7 $m5
  $a = $f * [math]::PI / 3
  Px $b ($ox + 33 + [int][math]::Round(2.5 * [math]::Sin($a))) (9 - [int][math]::Round(2.5 * [math]::Cos($a))) $am3
  Px $b ($ox + 33) 9 $m1
  # スピーカー・ランプ・ボタン
  foreach ($yy in 16, 18, 20) { Rect $b ($ox + 3) $yy 12 1 $m0 }
  Rect $b ($ox + 18) 17 3 3 $(if ($f % 2 -eq 0) { $rd1 } else { $rd0 })
  Rect $b ($ox + 23) 17 3 3 $lcd1
  Rect $b ($ox + 28) 17 3 3 $(if ($f % 3 -eq 0) { $am3 } else { $am0 })
  Rect $b ($ox + 33) 17 3 3 $m4; Px $b ($ox + 34) 18 $m1
  Rect $b ($ox + 3) 23 6 2 $m0; Rect $b ($ox + 29) 23 6 2 $m0
  Clear $b $ox 0; Clear $b ($ox + 37) 0
}

# ====================================================================
# 机の前のLEDメーター 22x5（光がはねる）4コマ
Sheet 'amateurradio_strip.png' 22 5 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 22 5 $m0
  $lev = @(4, 8, 6, 10)[$f]
  for ($s = 0; $s -lt 10; $s++) {
    $on = ($s -lt $lev)
    $c = if ($s -lt 6) { $(if ($on) { $lcd1 } else { $m1 }) } elseif ($s -lt 8) { $(if ($on) { $am2 } else { $m1 }) } else { $(if ($on) { $rd1 } else { $m1 }) }
    Rect $b ($ox + 1 + $s * 2) 1 1 3 $c
  }
}

# ====================================================================
# 机 68x16: 緑のデスクマットつきの木の机
Sheet 'amateurradio_desk.png' 68 16 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 68 6 $wd2
  Rect $b $ox 0 68 1 $wd3
  Rect $b ($ox + 2) 1 64 4 (C '#2e4a44')
  Rect $b ($ox + 2) 1 64 1 (C '#3f6a5e')
  Rect $b $ox 5 68 1 $wd1
  Rect $b $ox 6 68 10 $wd1
  Rect $b $ox 6 68 1 $wd0
  Rect $b ($ox + 1) 7 66 1 $wd2
  foreach ($dx in 4, 26, 48) { Rect $b ($ox + $dx) 9 16 5 $wd0; Rect $b ($ox + $dx + 1) 10 14 3 (Mix $wd1 $wd2 0.25); Rect $b ($ox + $dx + 6) 11 4 1 $am2 }
  Rect $b ($ox + 0) 14 4 2 $wd0; Rect $b ($ox + 64) 14 4 2 $wd0
  Clear $b $ox 0; Clear $b ($ox + 67) 0
}

# ====================================================================
# モールス電鍵 16x10（レバーを叩く）2コマ
Sheet 'amateurradio_key.png' 16 10 2 {
  param($b, $ox, $f)
  Rect $b ($ox + 1) 6 14 4 $wd0
  Rect $b ($ox + 2) 7 12 2 $wd1
  Rect $b ($ox + 2) 6 12 1 $wd2
  Rect $b ($ox + 2) 5 12 1 $m3
  Rect $b ($ox + 3) 3 2 3 $m4; Px $b ($ox + 3) 3 $m5
  $ky = if ($f -eq 0) { 2 } else { 3 }
  Ln $b ($ox + 4) 3 ($ox + 13) $ky $m5
  Ln $b ($ox + 4) 4 ($ox + 13) ($ky + 1) $m2
  Ellipse $b ($ox + 13.5) ($ky + 0.5) 2.4 2.0 $m0
  Ellipse $b ($ox + 13.5) ($ky + 0.3) 1.8 1.4 $rd1
  Px $b ($ox + 13) ($ky - 1) $rd2
  Px $b ($ox + 9) 5 $am2
  Clear $b ($ox + 1) 6; Clear $b ($ox + 14) 6
}

# ====================================================================
# スタンドマイク 8x16
Sheet 'amateurradio_mic.png' 8 16 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 4) 14.3 3.8 1.5 $m0
  Ellipse $b ($ox + 4) 14 3 1.1 $m3
  Rect $b ($ox + 3) 7 2 7 $m2; Px $b ($ox + 3) 8 $m4
  Ellipse $b ($ox + 4) 4 3.2 4 $m0
  Ellipse $b ($ox + 4) 4 2.4 3.2 $m3
  for ($yy = 2; $yy -lt 7; $yy += 2) { Rect $b ($ox + 2) $yy 4 1 $m1 }
  Px $b ($ox + 3) 2 $m5
  Px $b ($ox + 4) 11 $rd1
}

# ====================================================================
# ヘッドセット 14x12: スタンドにかけたヘッドホンとブームマイク
Sheet 'amateurradio_headset.png' 14 12 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 6) 9 2 2 $m2; Rect $b ($ox + 3) 11 8 1 $m0; Rect $b ($ox + 3) 11 8 1 $m1
  Rect $b ($ox + 4) 0 6 1 $m0
  foreach ($p in @(@(3, 1), @(10, 1), @(2, 2), @(11, 2), @(2, 3), @(11, 3), @(1, 4), @(12, 4))) { Px $b ($ox + $p[0]) $p[1] $m0 }
  Px $b ($ox + 5) 1 $m4; Px $b ($ox + 8) 1 $m4
  Rect $b ($ox + 0) 5 3 5 $m0; Rect $b ($ox + 1) 6 1 3 $rd1; Px $b ($ox + 1) 6 $rd2
  Rect $b ($ox + 11) 5 3 5 $m0; Rect $b ($ox + 12) 6 1 3 $rd1; Px $b ($ox + 12) 6 $rd2
  Ln $b ($ox + 1) 10 ($ox + 4) 11 $m3
  Px $b ($ox + 4) 11 $am2; Px $b ($ox + 5) 11 $am2
}

# ====================================================================
# コールサイン風の札 28x18（架空の伏せ字）
Sheet 'amateurradio_plate.png' 28 18 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 5) 13 2 5 $wd1; Rect $b ($ox + 21) 13 2 5 $wd1
  Rect $b $ox 0 28 14 $wd0
  Rect $b ($ox + 1) 1 26 12 $cr
  Rect $b ($ox + 1) 1 26 1 $wh
  Frame $b ($ox + 1) 1 26 12 $am1
  [void](T3 $b 'JA0XXX' ($ox + 3) 3 $g1)
  [void](T3 $b '73' ($ox + 3) 8 $rd1)
  Px $b ($ox + 15) 10 $sk1; Px $b ($ox + 17) 9 $sk1; Px $b ($ox + 19) 8 $sk1; Px $b ($ox + 21) 9 $sk1; Px $b ($ox + 23) 10 $sk1
  Clear $b $ox 0; Clear $b ($ox + 27) 0
}

# ====================================================================
# ハンディ機の展示台 52x36（3台のハンディ機の画面が順番に光り、右の充電台のランプが点滅する）4コマ
Sheet 'amateurradio_handy_screen.png' 52 36 4 {
  param($b, $ox, $f)
  $sc = @($lcd1, $am2, $sk2)
  $stripe = @($rd1, $sk1, $am1)
  for ($u = 0; $u -lt 3; $u++) {
    $x0 = 4 + $u * 14
    Rect $b ($ox + $x0 + 1) 1 2 5 $m0; Px $b ($ox + $x0 + 1) 1 $m2
    Rect $b ($ox + $x0) 5 9 12 $m0
    Rect $b ($ox + $x0 + 1) 6 7 10 $m1
    Rect $b ($ox + $x0 + 1) 6 7 1 $m3
    $on = ((($f + $u) % 2) -eq 0)
    Rect $b ($ox + $x0 + 2) 7 5 3 $(if ($on) { $sc[$u] } else { $lcd0 })
    if ($on) { Px $b ($ox + $x0 + 3) 8 $wh }
    foreach ($ry in 11, 13) { foreach ($rx in 2, 4, 6) { Px $b ($ox + $x0 + $rx) $ry $m4 } }
    Rect $b ($ox + $x0 + 8) 8 1 4 $stripe[$u]
    Rect $b ($ox + $x0 - 1) 16 11 1 $m2
  }
  # 充電台
  Rect $b ($ox + 44) 8 6 9 $m0; Rect $b ($ox + 45) 9 4 7 $m2; Rect $b ($ox + 45) 9 4 1 $m4
  Rect $b ($ox + 46) 11 2 2 $(if ($f % 2 -eq 0) { $lcd1 } else { $g3 }); Px $b ($ox + 46) 14 $rd1
  # 台
  Rect $b $ox 17 52 4 $wd2; Rect $b $ox 17 52 1 $wd3; Rect $b $ox 20 52 1 $wd1
  Rect $b $ox 21 52 15 $sk0
  Rect $b ($ox + 1) 21 50 14 $sk1
  for ($x = 6; $x -lt 52; $x += 8) { Rect $b ($ox + $x) 21 1 14 $sk0 }
  for ($x = 0; $x -lt 52; $x += 2) { Px $b ($ox + $x) 35 $sk0 }
  Rect $b ($ox + 2) 22 48 13 $cr; Frame $b ($ox + 2) 22 48 13 $am1
  [void](TextPx $b 'ハンディ' ($ox + 4) 23 11 $g1 $true)
  Clear $b $ox 35; Clear $b ($ox + 51) 35
}

# ====================================================================
# 八木アンテナの展示 66x46（三脚の上の八木アンテナから、前に電波が出る）4コマ
Sheet 'amateurradio_yagi_beam.png' 66 46 4 {
  param($b, $ox, $f)
  # 三脚
  Ln $b ($ox + 15) 28 ($ox + 5) 44 $m1; Ln $b ($ox + 16) 28 ($ox + 6) 44 $m3
  Ln $b ($ox + 15) 28 ($ox + 25) 44 $m1; Ln $b ($ox + 14) 28 ($ox + 24) 44 $m3
  Ln $b ($ox + 15) 28 ($ox + 15) 44 $m2
  Rect $b ($ox + 3) 44 5 2 $m0; Rect $b ($ox + 23) 44 5 2 $m0; Rect $b ($ox + 13) 44 5 2 $m0
  # マスト
  Rect $b ($ox + 14) 16 2 14 $m4; Rect $b ($ox + 15) 16 1 14 $m3
  Rect $b ($ox + 12) 27 6 2 $m2
  # ブーム
  Rect $b ($ox + 4) 14 47 3 $m1
  Rect $b ($ox + 4) 14 47 1 $m5; Rect $b ($ox + 4) 16 47 1 $m2
  # エレメント: x, 半分の長さ
  $els = @(@(6, 10), @(15, 9), @(24, 8), @(32, 7), @(39, 6), @(45, 5))
  $i = 0
  foreach ($e in $els) {
    Rect $b ($ox + $e[0]) (15 - $e[1]) 1 ($e[1] * 2 + 1) $m5
    Rect $b ($ox + $e[0] + 1) (15 - $e[1] + 1) 1 ($e[1] * 2) $m2
    Px $b ($ox + $e[0]) (15 - $e[1]) $wh
    Px $b ($ox + $e[0]) (15 + $e[1]) $m3
    $i++
  }
  Rect $b ($ox + 14) 13 3 5 $am1; Rect $b ($ox + 14) 13 3 1 $am3; Px $b ($ox + 15) 15 $am0
  # 前へ広がる電波
  for ($k = 0; $k -lt 3; $k++) {
    $rad = 3 + (($f + $k) % 4) * 3
    Ring $b ($ox + 50) 15 $rad (CAc $sk3 ([int](225 - $rad * 15))) 2
  }
}
