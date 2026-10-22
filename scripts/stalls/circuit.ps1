# 電子回路基板屋の専用ドット絵（看板・基板の陳列棚・LED基板・はんだごて台・部品トレイ・ブレッドボード・オシロスコープ・回路図ポスターなど）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/circuit.ps1     （リポジトリのルートで）
# 出力: client/public/brand/stall/circuit_*.png （配置は scripts/stalls/circuit.mjs）
# 一部だけ作り直す: $env:CIRCUIT_ONLY='sign|shelf'  （ファイル名の正規表現）
# 配色は「緑の基板」「金のパッド」「銀のはんだ」「LEDの赤・黄・緑・青」。アニメは「フレームを横一列に並べたPNG」を k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function Al($col, $a) { [System.Drawing.Color]::FromArgb([int]$a, $col.R, $col.G, $col.B) }
function Cl($v, $lo, $hi) { if ($v -lt $lo) { return $lo } elseif ($v -gt $hi) { return $hi } else { return $v } }
# 決まった「でたらめ」（毎回同じ値）
function Hs($n) { return ((([int]$n * 73 + 19) * 31 + [int]$n * [int]$n * 7) % 97) }
# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  if ($env:CIRCUIT_ONLY -and ($name -notmatch $env:CIRCUIT_ONLY)) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}

# ---- 色
$k0 = C '#07120d'
$pg0 = C '#0c4a22'; $pg1 = C '#1a7f3a'; $pg2 = C '#2fa653'; $pg3 = C '#5fd283'
$pb0 = C '#1a2f66'; $pb1 = C '#2a52a8'; $pb2 = C '#4a7ee0'
$pr0 = C '#6a1620'; $pr1 = C '#b02a38'; $pr2 = C '#e05a66'
$pk0 = C '#101216'; $pk1 = C '#22262e'; $pk2 = C '#3c4250'
$au0 = C '#a8782a'; $au1 = C '#e9b93a'; $au2 = C '#fff0a0'
$sv0 = C '#5a6674'; $sv1 = C '#8a96a4'; $sv2 = C '#c8d0d8'; $sv3 = C '#eef2f6'
$wd0 = C '#6a4020'; $wd1 = C '#a8703c'; $wd2 = C '#d29a5c'; $wd3 = C '#eebf86'
$tl0 = C '#0f1f1a'; $tl1 = C '#18312b'; $tl2 = C '#234a3f'; $tl3 = C '#34705c'
$lr = C '#ff3b3b'; $ly = C '#ffe04a'; $lg = C '#4dff7a'; $lb = C '#4aa8ff'; $lw = C '#fff6d8'
$tan = C '#d8b87a'; $tan2 = C '#a8884a'
$palG = @($pg1, $pg2, $pg0); $palB = @($pb1, $pb2, $pb0); $palR = @($pr1, $pr2, $pr0)
$ledCols = @($lr, $ly, $lg, $lb)
$bandCols = @((C '#14141a'), (C '#7a3a14'), (C '#e03a2a'), (C '#f08a1a'), (C '#ffe04a'), (C '#2a9a3a'), (C '#2a4fd0'), (C '#8a3ad0'), (C '#8a8a8a'), (C '#f4f4f4'))

# ---- 3x5 の小さな文字（大文字だけ。ハッシュのキーは大文字小文字を区別しないので大文字で統一）
$f3 = @{
  'A' = @('.X.', 'X.X', 'XXX', 'X.X', 'X.X'); 'B' = @('XX.', 'X.X', 'XX.', 'X.X', 'XX.'); 'C' = @('.XX', 'X..', 'X..', 'X..', '.XX')
  'D' = @('XX.', 'X.X', 'X.X', 'X.X', 'XX.'); 'E' = @('XXX', 'X..', 'XX.', 'X..', 'XXX'); 'F' = @('XXX', 'X..', 'XX.', 'X..', 'X..')
  'G' = @('.XX', 'X..', 'X.X', 'X.X', '.XX'); 'H' = @('X.X', 'X.X', 'XXX', 'X.X', 'X.X'); 'I' = @('XXX', '.X.', '.X.', '.X.', 'XXX')
  'L' = @('X..', 'X..', 'X..', 'X..', 'XXX'); 'M' = @('X.X', 'XXX', 'XXX', 'X.X', 'X.X'); 'N' = @('XX.', 'X.X', 'X.X', 'X.X', 'X.X')
  'O' = @('.X.', 'X.X', 'X.X', 'X.X', '.X.'); 'P' = @('XX.', 'X.X', 'XX.', 'X..', 'X..'); 'R' = @('XX.', 'X.X', 'XX.', 'X.X', 'X.X')
  'S' = @('.XX', 'X..', '.X.', '..X', 'XX.'); 'T' = @('XXX', '.X.', '.X.', '.X.', '.X.'); 'U' = @('X.X', 'X.X', 'X.X', 'X.X', 'XXX')
  'V' = @('X.X', 'X.X', 'X.X', 'X.X', '.X.'); 'W' = @('X.X', 'X.X', 'XXX', 'XXX', 'X.X'); 'Y' = @('X.X', 'X.X', '.X.', '.X.', '.X.')
  'K' = @('X.X', 'X.X', 'XX.', 'X.X', 'X.X'); 'X' = @('X.X', 'X.X', '.X.', 'X.X', 'X.X'); 'Z' = @('XXX', '..X', '.X.', 'X..', 'XXX')
  '0' = @('XXX', 'X.X', 'X.X', 'X.X', 'XXX'); '1' = @('.X.', 'XX.', '.X.', '.X.', 'XXX'); '2' = @('XX.', '..X', '.X.', 'X..', 'XXX')
  '3' = @('XX.', '..X', '.X.', '..X', 'XX.'); '4' = @('X.X', 'X.X', 'XXX', '..X', '..X'); '5' = @('XXX', 'X..', 'XX.', '..X', 'XX.')
  '6' = @('.XX', 'X..', 'XXX', 'X.X', 'XXX'); '7' = @('XXX', '..X', '.X.', '.X.', '.X.'); '8' = @('XXX', 'X.X', 'XXX', 'X.X', 'XXX'); '9' = @('XXX', 'X.X', 'XXX', '..X', 'XX.')
  '!' = @('.X.', '.X.', '.X.', '...', '.X.'); '-' = @('...', '...', 'XXX', '...', '...'); '.' = @('...', '...', '...', '...', '.X.')
  '+' = @('...', '.X.', 'XXX', '.X.', '...'); ' ' = @('...', '...', '...', '...', '...')
}
# 小さな文字を貼る。幅(px)を返す（1文字 = 3px + 1px のすき間）
function T3($b, $text, $x, $y, $col) {
  $cx = $x
  foreach ($ch in $text.ToUpper().ToCharArray()) {
    $kk = [string]$ch
    if ($f3.ContainsKey($kk)) {
      $g = $f3[$kk]
      for ($rr = 0; $rr -lt 5; $rr++) { for ($cc = 0; $cc -lt 3; $cc++) { if ($g[$rr].Substring($cc, 1) -eq 'X') { Px $b ($cx + $cc) ($y + $rr) $col } } }
    }
    $cx += 4
  }
  return ($cx - $x - 1)
}

# ---- 部品（小さな絵）
function Chip($b, $x, $y, $w) {   # 黒いIC: 幅 $w × 高さ3、両側に足
  Rect $b $x $y $w 3 $pk1; Rect $b $x $y $w 1 $pk2; Px $b ($x + 1) ($y + 1) $pk0
  for ($i = 1; $i -lt $w; $i += 2) { Px $b ($x + $i) ($y - 1) $sv2; Px $b ($x + $i) ($y + 3) $sv2 }
}
function Cap($b, $x, $y, $col) { Rect $b $x $y 2 2 $col; Px $b $x $y $sv2 }
function Res($b, $x, $y, $b1, $b2) {  # 横向きの抵抗 4x1（色の帯つき）
  Rect $b $x $y 4 1 $tan; Px $b ($x + 1) $y $b1; Px $b ($x + 2) $y $b2
}
# 基板 1 枚（$pal = 基地・配線・ふち の色）。配線・金のパッド・チップ・コンデンサなど、$seed で毎回同じ模様
function Board($b, $x, $y, $w, $h, $seed, $pal) {
  $base = $pal[0]; $trc = $pal[1]; $dk = $pal[2]
  Rect $b $x $y $w $h $base
  Frame $b $x $y $w $h $dk
  Rect $b ($x + 1) ($y + 1) ($w - 2) 1 (Mix $base $trc 0.45)
  $nt = [int][math]::Min(9, [math]::Max(2, [math]::Floor($w * $h / 24)))
  for ($i = 0; $i -lt $nt; $i++) {
    $sx = $x + 2 + ((Hs ($seed * 13 + $i * 7)) % [math]::Max(1, ($w - 5)))
    $sy = $y + 2 + ((Hs ($seed * 17 + $i * 11)) % [math]::Max(1, ($h - 5)))
    $ln = 3 + ((Hs ($seed * 5 + $i * 3)) % 6)
    $dr = (Hs ($seed * 3 + $i * 19)) % 3
    $ex = $sx; $ey = $sy
    if ($dr -eq 0) { $ex = $sx + $ln } elseif ($dr -eq 1) { $ey = $sy + $ln } else { $ex = $sx + [int]($ln / 2); $ey = $sy + [int]($ln / 2) }
    $ex = Cl $ex ($x + 1) ($x + $w - 2); $ey = Cl $ey ($y + 1) ($y + $h - 2)
    Line $b ([int]$sx) ([int]$sy) ([int]$ex) ([int]$ey) $trc
    Px $b $ex $ey $au1
    Px $b $sx $sy $au1
  }
  if ($w -ge 10 -and $h -ge 8) {
    $cx0 = $x + 3 + ((Hs ($seed * 7 + 1)) % [math]::Max(1, ($w - 9)))
    $cy0 = $y + 3 + ((Hs ($seed * 7 + 2)) % [math]::Max(1, ($h - 7)))
    Chip $b $cx0 $cy0 5
  }
  if ($w -ge 9) {
    $qx = $x + 2 + ((Hs ($seed * 11 + 3)) % [math]::Max(1, ($w - 6)))
    $qy = $y + $h - 4
    if (($seed % 2) -eq 0) { Cap $b $qx $qy (C '#2e4a9a') } else { Res $b $qx ($qy + 1) $bandCols[2] $bandCols[4] }
  }
  if (($seed % 3) -eq 0 -and $h -ge 9) {   # 金のコネクタ（ふちの金の端子）
    for ($i = $x + 2; $i -lt $x + $w - 2; $i += 2) { Rect $b $i ($y + $h - 2) 1 2 $au1 }
  }
}
# LED（上から見た 3x3。点灯: 明るい芯と光のふち）
function Led($b, $x, $y, $col, $on, $base) {
  if ($on) {
    Rect $b ($x - 1) ($y - 1) 5 5 (Mix $col $base 0.55)
    Rect $b $x $y 3 3 $col
    Px $b ($x + 1) ($y + 1) $lw
  } else {
    Rect $b $x $y 3 3 (Mix $col $pk0 0.62)
    Px $b $x $y (Mix $col $pk0 0.4)
  }
}

# ---- 床 192x128（濃い緑灰のタイル。基板のような配線が埋め込まれ、真ん中の通路に光る矢印）
Sheet 'circuit_floor.png' 192 128 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 192 128 $tl1
  for ($y = 0; $y -lt 128; $y += 16) { Rect $b $ox $y 192 1 $tl0 }
  for ($x = 0; $x -lt 192; $x += 16) { Rect $b ($ox + $x) 0 1 128 $tl0 }
  for ($y = 0; $y -lt 128; $y += 16) { Rect $b $ox ($y + 1) 192 1 (Mix $tl1 $tl2 0.5) }
  for ($y = 8; $y -lt 128; $y += 16) { for ($x = 8; $x -lt 192; $x += 16) { if ((Hs ($x + $y * 3)) % 3 -eq 0) { Px $b ($ox + $x) $y $tl2 } } }
  # 床にうっすら配線とパッド
  foreach ($t in @(@(6, 100, 30, 100), @(30, 100, 40, 110), @(40, 110, 40, 124), @(140, 20, 170, 20), @(170, 20, 180, 30), @(150, 110, 186, 110), @(150, 110, 150, 98), @(12, 30, 12, 56), @(180, 60, 180, 90))) {
    Line $b ($ox + $t[0]) $t[1] ($ox + $t[2]) $t[3] $tl2
    Px $b ($ox + $t[2]) $t[3] $tl3; Px $b ($ox + $t[0]) $t[1] $tl3
  }
  # 真ん中の通路（幅 36px）
  Rect $b ($ox + 78) 0 36 128 (C '#143026')
  Rect $b ($ox + 78) 0 1 128 $tl3; Rect $b ($ox + 113) 0 1 128 $tl3
  for ($y = 0; $y -lt 128; $y += 16) { Rect $b ($ox + 79) $y 34 1 $tl1 }
  for ($y = 60; $y -lt 128; $y += 14) {
    $a = Mix $lg $tl1 (0.78 - ($y - 60) / 110.0)
    Line $b ($ox + 90) ($y + 4) ($ox + 96) $y $a; Line $b ($ox + 102) ($y + 4) ($ox + 96) $y $a
    Line $b ($ox + 91) ($y + 4) ($ox + 96) ($y + 1) $a; Line $b ($ox + 101) ($y + 4) ($ox + 96) ($y + 1) $a
  }
  Frame $b $ox 0 192 128 $tl0
}

# ---- 奥の壁 184x38（濃い緑のペグボード。穴の列と、下に金のライン）
Sheet 'circuit_wall.png' 184 38 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 184 38 $tl1
  Rect $b $ox 0 184 2 $tl3; Rect $b $ox 2 184 1 $tl0
  for ($y = 5; $y -lt 31; $y += 4) { for ($x = 3; $x -lt 182; $x += 4) { Px $b ($ox + $x) $y $tl0; Px $b ($ox + $x + 1) $y (Mix $tl1 $tl2 0.6) } }
  Rect $b $ox 33 184 5 $wd1; Rect $b $ox 33 184 1 $wd3; Rect $b $ox 34 184 1 $wd2; Rect $b $ox 37 184 1 $wd0
  for ($x = 0; $x -lt 184; $x++) { if (($x % 8) -lt 3) { Px $b ($ox + $x) 35 $wd0 } }
  Clear $b $ox 0; Clear $b ($ox + 183) 0
}

# ---- 看板 124x32（緑の基板に金の文字「電子回路基板」。配線を光が走り、文字がひとつずつ光る）6コマ
$signTxt = '電子回路基板'
Sheet 'circuit_sign.png' 124 32 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 124 32 $k0
  Rect $b ($ox + 1) 1 122 30 $pg1
  Rect $b ($ox + 1) 1 122 1 $pg2; Rect $b ($ox + 1) 30 122 1 $pg0
  Frame $b ($ox + 2) 2 120 28 $au1
  Frame $b ($ox + 3) 3 118 26 $pg0
  # ねじ穴（四すみ）
  foreach ($p in @(@(5, 5), @(118, 5), @(5, 26), @(118, 26))) { Rect $b ($ox + $p[0]) $p[1] 2 2 $au0; Px $b ($ox + $p[0]) $p[1] $au2 }
  # 左右の配線（光の点が外から文字へ走る）
  foreach ($row in 0, 1, 2, 3) {
    $yy = 8 + $row * 5
    $x0 = 9; $x1 = 22 - ($row % 2) * 2
    Line $b ($ox + $x0) $yy ($ox + $x1) $yy $pg3
    Px $b ($ox + $x0 - 1) $yy $au1; Px $b ($ox + $x0 - 2) $yy $au1; Px $b ($ox + $x0 - 1) ($yy + 1) $au1; Px $b ($ox + $x0 - 2) ($yy + 1) $au1
    Line $b ($ox + $x1) $yy ($ox + $x1 + 2) ($yy + 2) $pg3
    $lit = ($f * 2 + $row * 3) % 14
    for ($q = 0; $q -lt 3; $q++) { Px $b ($ox + $x0 + $lit - $q) $yy (Mix $lw $pg3 ($q * 0.3)) }
    Px $b ($ox + 123 - $x0) $yy $pg3
    Line $b ($ox + 123 - $x0) $yy ($ox + 123 - $x1) $yy $pg3
    Px $b ($ox + 123 - $x0 + 1) $yy $au1; Px $b ($ox + 123 - $x0 + 2) $yy $au1; Px $b ($ox + 123 - $x0 + 1) ($yy + 1) $au1; Px $b ($ox + 123 - $x0 + 2) ($yy + 1) $au1
    Line $b ($ox + 123 - $x1) $yy ($ox + 123 - $x1 - 2) ($yy + 2) $pg3
    for ($q = 0; $q -lt 3; $q++) { Px $b ($ox + 123 - ($x0 + $lit - $q)) $yy (Mix $lw $pg3 ($q * 0.3)) }
  }
  # 文字（12pxの太字。ひとつずつ明るく光る）
  for ($i = 0; $i -lt 6; $i++) {
    $ch = $signTxt.Substring($i, 1)
    $tx = $ox + 24 + $i * 13
    $col = $au1
    if ((($f + 6 - $i) % 6) -eq 0) { $col = $au2 }
    [void](TextPx $b $ch ($tx + 1) 7 12 $pg0 $true)
    [void](TextPx $b $ch $tx 6 12 $col $true)
  }
  # 下に小さな英語と、点滅するLED
  [void](T3 $b 'CIRCUIT BOARD' ($ox + 36) 23 (Mix $lw $pg3 0.35))
  Led $b ($ox + 26) 22 $lr ((($f) % 3) -eq 0) $pg1
  Led $b ($ox + 31) 22 $ly ((($f + 1) % 3) -eq 0) $pg1
  Led $b ($ox + 91) 22 $lg ((($f + 2) % 3) -eq 0) $pg1
  Led $b ($ox + 96) 22 $lb ((($f) % 3) -eq 0) $pg1
  foreach ($p in @(@(0, 0), @(123, 0), @(0, 31), @(123, 31))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ---- のぼり 18x80（緑の旗に「電子基板」と、下にパッドつきの配線。銀のポール）
Sheet 'circuit_nobori.png' 18 80 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 1) 0 2 80 $sv0; Rect $b ($ox + 1) 0 1 80 $sv2
  Rect $b $ox 0 18 3 $k0; Rect $b ($ox + 1) 0 16 2 $sv1; Rect $b ($ox + 1) 0 16 1 $sv2; Rect $b ($ox + 16) 0 2 4 $au1; Px $b ($ox + 17) 0 $au2
  Rect $b ($ox + 3) 3 14 72 $k0
  Rect $b ($ox + 4) 4 12 70 $pg1
  Rect $b ($ox + 4) 4 12 1 $pg2; Rect $b ($ox + 4) 4 1 70 $pg2; Rect $b ($ox + 15) 4 1 70 $pg0
  Rect $b ($ox + 5) 5 10 1 $au1; Rect $b ($ox + 5) 52 10 1 $au1
  for ($y = 69; $y -le 74; $y++) { $d = $y - 68; Rect $b ($ox + 10 - $d) $y (2 * $d) 1 ([System.Drawing.Color]::FromArgb(0, 0, 0, 0)) }
  $ys = 7
  foreach ($ch in @('電', '子', '基', '板')) { [void](TextPx $b $ch ($ox + 5) ($ys + 1) 11 $pg0 $true); [void](TextPx $b $ch ($ox + 4) $ys 11 $au2 $true); $ys += 11 }
  # 下に配線とパッド
  Line $b ($ox + 8) 54 ($ox + 8) 60 $pg3; Line $b ($ox + 8) 60 ($ox + 12) 64 $pg3; Line $b ($ox + 12) 64 ($ox + 12) 66 $pg3
  Line $b ($ox + 11) 54 ($ox + 11) 58 $pg3; Line $b ($ox + 6) 56 ($ox + 6) 62 $pg3
  foreach ($p in @(@(8, 54), @(11, 54), @(6, 56), @(12, 66), @(6, 62))) { Rect $b ($ox + $p[0] - 0) $p[1] 2 2 $au1; Px $b ($ox + $p[0]) $p[1] $au2 }
  Chip $b ($ox + 8) 68 5
  Clear $b $ox 0
}

# ---- 基板の陳列棚 90x42（緑の基板が3段にずらっと並ぶ。ところどころのLEDが点滅）4コマ
$tiers = @(
  @(@(5, 13, 11, 1, 'G'), @(19, 11, 10, 2, 'G'), @(31, 15, 11, 3, 'G'), @(47, 12, 9, 4, 'B'), @(60, 14, 11, 5, 'G'), @(75, 9, 10, 6, 'G')),
  @(@(5, 15, 11, 7, 'G'), @(21, 10, 9, 8, 'R'), @(32, 13, 11, 9, 'G'), @(46, 16, 10, 10, 'G'), @(63, 11, 11, 11, 'G'), @(75, 9, 9, 12, 'G')),
  @(@(5, 11, 10, 13, 'G'), @(17, 14, 11, 14, 'G'), @(32, 12, 9, 15, 'G'), @(45, 15, 11, 16, 'G'), @(61, 10, 10, 17, 'B'), @(72, 12, 11, 18, 'G'))
)
Sheet 'circuit_shelf.png' 90 42 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 90 42 $k0
  Rect $b ($ox + 1) 1 88 39 $tl1
  for ($y = 3; $y -lt 39; $y += 4) { for ($x = 6; $x -lt 86; $x += 4) { Px $b ($ox + $x) $y $tl0 } }
  $bots = @(12, 25, 38)
  for ($t = 0; $t -lt 3; $t++) {
    foreach ($bd in $tiers[$t]) {
      $pal = $palG
      if ($bd[4] -eq 'B') { $pal = $palB } elseif ($bd[4] -eq 'R') { $pal = $palR }
      $by0 = $bots[$t] - $bd[2] + 1
      Board $b ($ox + $bd[0]) $by0 $bd[1] $bd[2] $bd[3] $pal
      if (($bd[3] % 2) -eq 0) {
        $lc = $ledCols[$bd[3] % 4]
        $on = ((($f + $bd[3]) % 4) -lt 2)
        if ($on) { Px $b ($ox + $bd[0] + $bd[1] - 3) ($by0 + 2) $lc; Px $b ($ox + $bd[0] + $bd[1] - 3) ($by0 + 3) (Mix $lc $pg1 0.45); Px $b ($ox + $bd[0] + $bd[1] - 4) ($by0 + 2) (Mix $lc $pg1 0.45); Px $b ($ox + $bd[0] + $bd[1] - 2) ($by0 + 2) (Mix $lc $pg1 0.45) }
        else { Px $b ($ox + $bd[0] + $bd[1] - 3) ($by0 + 2) (Mix $lc $pk0 0.55) }
      }
    }
    $py = $bots[$t] + 1
    Rect $b ($ox + 1) $py 88 2 $wd1; Rect $b ($ox + 1) $py 88 1 $wd3; Rect $b ($ox + 1) ($py + 1) 88 1 $wd0
  }
  # 柱（左右）
  Rect $b ($ox + 1) 1 3 40 $wd1; Rect $b ($ox + 1) 1 1 40 $wd3; Rect $b ($ox + 3) 1 1 40 $wd0
  Rect $b ($ox + 86) 1 3 40 $wd1; Rect $b ($ox + 86) 1 1 40 $wd3; Rect $b ($ox + 88) 1 1 40 $wd0
  Rect $b ($ox + 1) 0 88 1 $wd2
  Clear $b $ox 0; Clear $b ($ox + 89) 0
}

# ---- 作業台 70x16（木の天板と、緑の前板に引き出し）
Sheet 'circuit_bench.png' 70 16 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 70 16 $k0
  Rect $b ($ox + 1) 1 68 6 $wd2; Rect $b ($ox + 1) 1 68 1 $wd3; Rect $b ($ox + 1) 6 68 1 $wd1
  for ($x = 4; $x -lt 68; $x += 11) { Px $b ($ox + $x) 3 $wd1; Px $b ($ox + $x + 3) 4 $wd1 }
  Rect $b ($ox + 1) 7 68 8 $tl2
  Rect $b ($ox + 1) 7 68 1 $tl0
  foreach ($dx in 4, 25, 46) {
    Rect $b ($ox + $dx) 8 20 5 $tl1; Frame $b ($ox + $dx) 8 20 5 $tl3
    Rect $b ($ox + $dx + 8) 10 4 1 $au1; Px $b ($ox + $dx + 8) 10 $au2
  }
  Rect $b ($ox + 1) 14 68 1 $tl0
  Clear $b $ox 0; Clear $b ($ox + 69) 0; Clear $b $ox 15; Clear $b ($ox + 69) 15
}

# ---- 展示テーブル 70x20（緑の布の上に基板が平らに並ぶ。前に飾りの緑の布）
Sheet 'circuit_display.png' 70 20 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 70 20 $k0
  Rect $b ($ox + 1) 1 68 9 $pg0
  Rect $b ($ox + 1) 1 68 1 $pg1
  $pls = @(@(3, 2, 12, 7, 21, 'G'), @(17, 3, 10, 6, 22, 'G'), @(29, 2, 13, 7, 23, 'B'), @(44, 3, 10, 6, 24, 'G'), @(56, 2, 12, 7, 25, 'G'))
  foreach ($pl in $pls) {
    $pal = $palG; if ($pl[5] -eq 'B') { $pal = $palB }
    Board $b ($ox + $pl[0]) $pl[1] $pl[2] $pl[3] $pl[4] $pal
  }
  # 前の布（ふちに金のライン、しま模様、すそがギザギザ）
  Rect $b ($ox + 1) 10 68 9 $tl2
  Rect $b ($ox + 1) 10 68 1 $au1
  for ($x = 2; $x -lt 69; $x += 4) { Rect $b ($ox + $x) 12 2 5 $tl3 }
  for ($x = 1; $x -lt 69; $x += 4) { Rect $b ($ox + $x) 17 3 2 $tl2; Px $b ($ox + $x + 1) 19 $k0 }
  Rect $b ($ox + 1) 11 68 1 $tl0
  Clear $b $ox 0; Clear $b ($ox + 69) 0; Clear $b $ox 19; Clear $b ($ox + 69) 19
}

# ---- オシロスコープ 32x28（波形がゆれながら流れる）8コマ
Sheet 'circuit_scope.png' 32 28 8 {
  param($b, $ox, $f)
  Rect $b ($ox + 9) 0 14 2 $sv0; Rect $b ($ox + 10) 0 12 1 $sv2
  Rect $b $ox 2 32 24 $k0
  Rect $b ($ox + 1) 3 30 22 $sv1
  Rect $b ($ox + 1) 3 30 1 $sv2; Rect $b ($ox + 1) 24 30 1 $sv0
  Rect $b ($ox + 3) 5 20 15 $k0
  Rect $b ($ox + 4) 6 18 13 (C '#04150c')
  for ($gx = 0; $gx -lt 18; $gx += 3) { for ($gy = 0; $gy -lt 13; $gy += 3) { Px $b ($ox + 4 + $gx) (6 + $gy) (C '#12522e') } }
  for ($x = 0; $x -lt 18; $x++) { Px $b ($ox + 4 + $x) 12 (C '#176a3a') }
  for ($x = 0; $x -lt 18; $x++) {
    $yy = 12 + [int][math]::Round(4 * [math]::Sin(2 * [math]::PI * ($x / 9.0 + $f / 8.0)))
    Px $b ($ox + 4 + $x) $yy (C '#58ffa0')
    Px $b ($ox + 4 + $x) ($yy + 1) (C '#1d9a58')
  }
  for ($x = 0; $x -lt 18; $x++) {
    $ph = ($x + $f * 3) % 12
    $yy = 8; if ($ph -ge 6) { $yy = 10 }
    Px $b ($ox + 4 + $x) $yy $ly
    if ($ph -eq 0 -or $ph -eq 6) { Px $b ($ox + 4 + $x) 9 $ly }
  }
  # つまみ・ランプ
  foreach ($kn in @(@(27, 8), @(27, 14))) {
    Ellipse $b ($ox + $kn[0]) $kn[1] 2.4 2.4 $k0
    Ellipse $b ($ox + $kn[0]) $kn[1] 1.6 1.6 $sv2
    Px $b ($ox + $kn[0] + [int]@(0, 1, 1, 1, 0, -1, -1, -1)[$f % 8]) ($kn[1] + [int]@(-1, -1, 0, 1, 1, 1, 0, -1)[$f % 8]) $k0
  }
  Px $b ($ox + 26) 20 $lg; Px $b ($ox + 28) 20 $(if ($f % 4 -lt 2) { $lr } else { (C '#6a1a1a') })
  foreach ($bx in 7, 12, 17) { Ellipse $b ($ox + $bx) 22 2 2 $k0; Ellipse $b ($ox + $bx) 22 1.3 1.3 $sv2; Px $b ($ox + $bx) 22 $k0 }
  Rect $b ($ox + 3) 26 3 2 $k0; Rect $b ($ox + 26) 26 3 2 $k0
  Clear $b $ox 2; Clear $b ($ox + 31) 2
}

# ---- はんだごて台と煙 30x38（ごての先が赤く、煙がゆらゆら上がる）8コマ
Sheet 'circuit_solder.png' 30 38 8 {
  param($b, $ox, $f)
  # 本体（左）
  Rect $b $ox 27 14 11 $k0
  Rect $b ($ox + 1) 28 12 9 (C '#2f6a5a')
  Rect $b ($ox + 1) 28 12 1 (C '#4a9a84'); Rect $b ($ox + 1) 36 12 1 (C '#1c4036')
  Rect $b ($ox + 2) 30 7 4 $k0
  for ($i = 0; $i -lt 3; $i++) { if (($f + $i) % 3 -ne 1) { Rect $b ($ox + 3 + $i * 2) 31 1 2 $lr } else { Rect $b ($ox + 3 + $i * 2) 31 1 2 (C '#6a1a1a') } }
  Ellipse $b ($ox + 11) 33 1.7 1.7 $sv2; Px $b ($ox + 11) 32 $k0
  # 台と、バネの受け
  Rect $b ($ox + 16) 35 14 3 $k0; Rect $b ($ox + 17) 35 12 2 $sv1; Rect $b ($ox + 17) 35 12 1 $sv2
  Rect $b ($ox + 17) 33 5 2 (C '#e8c03a'); Rect $b ($ox + 17) 33 5 1 (C '#fff08a'); Px $b ($ox + 19) 34 $tan2
  foreach ($zy in 24, 28) { Line $b ($ox + 23) $zy ($ox + 25) ($zy + 2) $sv1; Line $b ($ox + 25) ($zy + 2) ($ox + 23) ($zy + 4) $sv1 }
  Rect $b ($ox + 23) 30 1 5 $sv0; Rect $b ($ox + 25) 30 1 5 $sv0
  # ごて（先が左上、持ち手が右下）
  Line $b ($ox + 18) 21 ($ox + 22) 25 $sv2; Line $b ($ox + 18) 22 ($ox + 22) 26 $sv1; Line $b ($ox + 19) 21 ($ox + 23) 25 $sv0
  Px $b ($ox + 17) 20 (C '#ff8a3a'); Px $b ($ox + 16) 19 (C '#ff3b2a')
  for ($t = 0; $t -le 4; $t++) { Rect $b ($ox + 23 + $t) (25 + $t) 3 3 (C '#26262e'); Px $b ($ox + 23 + $t) (25 + $t) (C '#e87a1a') }
  Line $b ($ox + 27) 29 ($ox + 28) 33 $k0
  Line $b ($ox + 14) 36 ($ox + 17) 36 $k0
  # けむり（3つの小さなかたまりが、ゆれながら上がって消える）
  for ($q = 0; $q -lt 3; $q++) {
    $pos = ($f * 2 + $q * 5) % 16
    $sy = 18 - $pos
    $sx = 16 + [int][math]::Round(2.4 * [math]::Sin(2 * [math]::PI * ($f / 8.0 + $q / 3.0)))
    $al = [int](190 - $pos * 9)
    $sz = 1 + [int]($pos / 6)
    Rect $b ($ox + $sx - [int]($sz / 2)) $sy ($sz + 1) $sz (Al (C '#e8eef0') $al)
    if ($pos -gt 4) { Rect $b ($ox + $sx - 1) ($sy + 1) ($sz + 2) 1 (Al (C '#c8d0d8') ($al - 40)) }
  }
}

# ---- LED基板 28x20（4つのLEDが順番に光って往復する）8コマ
Sheet 'circuit_ledboard.png' 28 20 8 {
  param($b, $ox, $f)
  Rect $b ($ox + 3) 16 4 3 $sv1; Rect $b ($ox + 3) 16 4 1 $sv2; Rect $b ($ox + 21) 16 4 3 $sv1; Rect $b ($ox + 21) 16 4 1 $sv2
  Board $b ($ox + 2) 1 24 16 31 $palG
  # 配線は上書きして整える
  Rect $b ($ox + 3) 2 22 14 $pg1
  Rect $b ($ox + 3) 2 22 1 (Mix $pg1 $pg2 0.5)
  $seq = @(0, 1, 2, 3, 3, 2, 1, 0)[$f]
  for ($i = 0; $i -lt 4; $i++) {
    $lx = 5 + $i * 5
    Line $b ($ox + $lx + 1) 6 ($ox + $lx + 1) 9 $pg3
    Res $b ($ox + $lx - 1) 9 $bandCols[$i + 1] $bandCols[2]
    Rect $b ($ox + $lx + 1) 9 1 1 $tan
    Px $b ($ox + $lx - 1) 8 $au1; Px $b ($ox + $lx + 3) 8 $au1
    Led $b ($ox + $lx) 3 $ledCols[$i] ($i -eq $seq) $pg1
  }
  Line $b ($ox + 4) 11 ($ox + 4) 14 $pg3; Line $b ($ox + 23) 11 ($ox + 23) 14 $pg3
  Chip $b ($ox + 9) 12 7
  Rect $b ($ox + 19) 12 3 3 (C '#c8203a'); Px $b ($ox + 19) 12 $lr; Rect $b ($ox + 20) 13 1 1 $sv2
  Px $b ($ox + 4) 15 $au1; Px $b ($ox + 24) 15 $au1
  Clear $b $ox 19
}

# ---- ブレッドボード 38x18（LEDが点滅。ジャンパー線・抵抗・IC）4コマ
Sheet 'circuit_breadboard.png' 38 18 4 {
  param($b, $ox, $f)
  $bb = C '#e9e4d2'; $bd = C '#8d8672'; $hole = C '#5a553f'
  Rect $b $ox 0 38 18 $bd
  Rect $b ($ox + 1) 1 36 16 $bb
  Rect $b ($ox + 1) 1 36 1 (C '#f8f4e6')
  Rect $b ($ox + 2) 2 34 1 (C '#e03a3a'); Rect $b ($ox + 2) 15 34 1 (C '#3a5ae0')
  for ($i = 0; $i -lt 17; $i++) {
    if (($i % 6) -ne 5) { Px $b ($ox + 3 + $i * 2) 4 $hole; Px $b ($ox + 3 + $i * 2) 13 $hole }
    Px $b ($ox + 3 + $i * 2) 6 $hole; Px $b ($ox + 3 + $i * 2) 7 $hole; Px $b ($ox + 3 + $i * 2) 10 $hole; Px $b ($ox + 3 + $i * 2) 11 $hole
  }
  Rect $b ($ox + 2) 8 34 2 (C '#bfb9a2')
  # IC（真ん中のみぞをまたぐ）
  Rect $b ($ox + 21) 6 9 6 $pk1; Rect $b ($ox + 21) 6 9 1 $pk2; Px $b ($ox + 22) 7 $pk0
  foreach ($x in 22, 24, 26, 28) { Px $b ($ox + $x) 5 $sv2; Px $b ($ox + $x) 12 $sv2 }
  # 抵抗
  Rect $b ($ox + 12) 11 6 1 $tan; Px $b ($ox + 13) 11 $bandCols[2]; Px $b ($ox + 14) 11 $bandCols[4]; Px $b ($ox + 15) 11 $bandCols[2]
  Px $b ($ox + 11) 11 $sv1; Px $b ($ox + 18) 11 $sv1
  # LED（点滅）
  $on = ($f % 4) -lt 2
  $lc = $lr
  Rect $b ($ox + 7) 8 1 4 $sv1; Rect $b ($ox + 9) 8 1 4 $sv1
  if ($on) { Rect $b ($ox + 5) 3 7 5 (Mix $lc $bb 0.55); Ellipse $b ($ox + 8.5) 5 2.4 2.4 $lc; Px $b ($ox + 8) 4 $lw } else { Ellipse $b ($ox + 8.5) 5 2.4 2.4 (Mix $lc $pk0 0.6); Px $b ($ox + 8) 4 (Mix $lc $pk0 0.4) }
  # ジャンパー線
  Line $b ($ox + 4) 13 ($ox + 4) 14 (C '#2a8a2a'); Line $b ($ox + 4) 14 ($ox + 12) 14 (C '#2a8a2a')
  Line $b ($ox + 32) 10 ($ox + 32) 3 (C '#ffb02a'); Line $b ($ox + 32) 3 ($ox + 35) 3 (C '#ffb02a'); Line $b ($ox + 35) 3 ($ox + 35) 6 (C '#ffb02a')
  Line $b ($ox + 30) 13 ($ox + 30) 15 (C '#3a5ae0')
  Clear $b $ox 0; Clear $b ($ox + 37) 0; Clear $b $ox 17; Clear $b ($ox + 37) 17
}

# ---- 部品トレイ 28x11（小さな仕切りに部品が入っている）
function Tray($name, $codes) {
  Sheet $name 28 11 1 {
    param($b, $ox, $f)
    Rect $b $ox 0 28 11 (C '#4a5866')
    Rect $b ($ox + 1) 1 26 9 (C '#9fb0c0')
    Rect $b ($ox + 1) 1 26 1 (C '#d0dce6')
    for ($rw = 0; $rw -lt 2; $rw++) {
      for ($c = 0; $c -lt 4; $c++) {
        $px0 = $ox + 2 + $c * 6; $py0 = 2 + $rw * 4
        Rect $b $px0 $py0 5 3 (C '#46525e')
        switch ($codes[$rw * 4 + $c]) {
          'r' { Rect $b ($px0 + 1) ($py0 + 0) 3 1 $tan; Px $b ($px0 + 2) $py0 $bandCols[2]; Rect $b $px0 ($py0 + 2) 4 1 $tan; Px $b ($px0 + 1) ($py0 + 2) $bandCols[4] }
          'c' { Rect $b ($px0 + 0) ($py0 + 1) 2 2 (C '#2e4a9a'); Px $b $px0 ($py0 + 1) $sv2; Rect $b ($px0 + 3) ($py0 + 1) 2 2 (C '#e8a040') }
          'l' { Px $b ($px0 + 0) ($py0 + 1) $lr; Px $b ($px0 + 2) ($py0 + 1) $lg; Px $b ($px0 + 4) ($py0 + 1) $ly; Rect $b ($px0 + 1) ($py0 + 2) 3 1 (C '#8ab0c8') }
          'i' { Rect $b ($px0 + 0) ($py0 + 0) 4 2 $pk1; Px $b ($px0 + 4) ($py0 + 2) $pk1; Px $b ($px0 + 0) ($py0 + 2) $sv2; Px $b ($px0 + 2) ($py0 + 2) $sv2 }
          't' { Px $b ($px0 + 0) ($py0 + 1) $pk0; Rect $b ($px0 + 0) ($py0 + 1) 2 2 $pk0; Rect $b ($px0 + 3) ($py0 + 0) 2 2 $pk0; Px $b ($px0 + 3) ($py0 + 2) $sv2 }
          'g' { Px $b ($px0 + 0) ($py0 + 1) $au1; Px $b ($px0 + 2) ($py0 + 0) $au2; Px $b ($px0 + 3) ($py0 + 2) $au1; Px $b ($px0 + 1) ($py0 + 2) $au0; Px $b ($px0 + 4) ($py0 + 1) $au1 }
          'd' { Rect $b $px0 ($py0 + 0) 4 1 $pk1; Px $b ($px0 + 3) $py0 $sv2; Rect $b ($px0 + 1) ($py0 + 2) 4 1 $pk1; Px $b ($px0 + 4) ($py0 + 2) $sv2 }
          's' { Rect $b ($px0 + 0) ($py0 + 1) 2 2 $sv1; Px $b $px0 ($py0 + 1) $sv3; Rect $b ($px0 + 3) ($py0 + 0) 2 2 $sv1; Px $b ($px0 + 3) $py0 $sv3 }
          default { }
        }
      }
    }
    Rect $b ($ox + 1) 9 26 1 (C '#7c8c9c')
    Clear $b $ox 0; Clear $b ($ox + 27) 0; Clear $b $ox 10; Clear $b ($ox + 27) 10
  }
}
Tray 'circuit_tray_a.png' @('r', 'c', 'l', 'i', 't', 'g', 'd', 'r')
Tray 'circuit_tray_b.png' @('l', 'g', 's', 'r', 'i', 'c', 'l', 't')

# ---- 回路図のポスター 32x28（青い設計図。電池・スイッチ・抵抗・LED）
Sheet 'circuit_schem.png' 32 28 1 {
  param($b, $ox, $f)
  $bg = C '#1c3f8a'; $ln = C '#d8e8ff'; $dim = C '#5a82d0'
  Rect $b $ox 0 32 28 $k0
  Rect $b ($ox + 1) 1 30 26 $bg
  Frame $b ($ox + 2) 2 28 24 $dim
  for ($x = 4; $x -lt 29; $x += 4) { for ($y = 4; $y -lt 22; $y += 4) { Px $b ($ox + $x) $y (C '#2a56a8') } }
  # 電池（左）
  Line $b ($ox + 6) 6 ($ox + 6) 9 $ln; Rect $b ($ox + 4) 9 5 1 $ln; Rect $b ($ox + 5) 11 3 1 $ln; Rect $b ($ox + 4) 13 5 1 $ln; Rect $b ($ox + 5) 15 3 1 $ln; Line $b ($ox + 6) 16 ($ox + 6) 19 $ln
  Px $b ($ox + 10) 9 $lr; Px $b ($ox + 9) 9 $lr
  # 上の線 → スイッチ → 抵抗 → LED
  Line $b ($ox + 6) 6 ($ox + 12) 6 $ln
  Line $b ($ox + 12) 6 ($ox + 15) 3 $ln; Line $b ($ox + 15) 6 ($ox + 18) 6 $ln
  Px $b ($ox + 12) 6 $au1; Px $b ($ox + 15) 6 $au1
  Line $b ($ox + 18) 6 ($ox + 19) 6 $ln
  Line $b ($ox + 19) 6 ($ox + 20) 4 $ln; Line $b ($ox + 20) 4 ($ox + 21) 8 $ln; Line $b ($ox + 21) 8 ($ox + 22) 4 $ln; Line $b ($ox + 22) 4 ($ox + 23) 8 $ln; Line $b ($ox + 23) 8 ($ox + 24) 6 $ln
  Line $b ($ox + 24) 6 ($ox + 27) 6 $ln; Line $b ($ox + 27) 6 ($ox + 27) 10 $ln
  # LED（三角と横線と矢印）
  Line $b ($ox + 25) 10 ($ox + 29) 10 $ln; Line $b ($ox + 25) 10 ($ox + 27) 14 $ln; Line $b ($ox + 29) 10 ($ox + 27) 14 $ln; Line $b ($ox + 25) 14 ($ox + 29) 14 $ln
  Px $b ($ox + 30) 9 $ly; Px $b ($ox + 29) 8 $ly; Px $b ($ox + 30) 11 $ly; Px $b ($ox + 29) 12 $ly
  Line $b ($ox + 27) 14 ($ox + 27) 19 $ln
  Line $b ($ox + 6) 19 ($ox + 27) 19 $ln
  Px $b ($ox + 6) 19 $au1; Px $b ($ox + 27) 19 $au1
  [void](T3 $b 'CIRCUIT' ($ox + 3) 21 $lw)
  Clear $b $ox 0; Clear $b ($ox + 31) 0
}

# ---- 抵抗のカラーコード表のポスター 24x34
Sheet 'circuit_poster_code.png' 24 38 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 24 38 $k0
  Rect $b ($ox + 1) 1 22 36 (C '#efe6c8')
  Frame $b ($ox + 2) 2 20 34 (C '#b8a878')
  # 抵抗の絵
  Line $b ($ox + 3) 7 ($ox + 6) 7 $sv0; Line $b ($ox + 18) 7 ($ox + 21) 7 $sv0
  Rect $b ($ox + 6) 4 12 7 $tan2; Rect $b ($ox + 6) 4 12 1 (C '#e8d09a'); Rect $b ($ox + 7) 3 10 1 $tan2; Rect $b ($ox + 7) 11 10 1 $tan2
  Rect $b ($ox + 8) 4 1 7 $bandCols[2]; Rect $b ($ox + 10) 4 1 7 $bandCols[6]; Rect $b ($ox + 12) 4 1 7 $bandCols[3]; Rect $b ($ox + 15) 4 1 7 $au1
  # 色の見本 0..9
  for ($i = 0; $i -lt 10; $i++) {
    $cx = $ox + 4 + [int][math]::Floor($i / 5) * 8
    $cy = 14 + ($i % 5) * 3 + ($i % 5)
    Rect $b $cx $cy 7 4 $k0
    Rect $b ($cx + 1) ($cy + 1) 5 2 $bandCols[$i]
  }
  Rect $b ($ox + 4) 35 16 1 (C '#b8a878')
  Clear $b $ox 0; Clear $b ($ox + 23) 0
}

# ---- 保護メガネ 96x64（人物と同じ原点で重ねる。目の位置に透明なレンズと、頭にまわすバンド）
Sheet 'circuit_goggles.png' 96 64 1 {
  param($b, $ox, $f)
  $fr = C '#1fa9b8'; $fr2 = C '#0e6a78'; $ln2 = C '#d8f6ff'; $strap = C '#1a3a40'
  # バンド（こめかみ）
  Rect $b ($ox + 43) 30 3 2 $strap; Rect $b ($ox + 53) 30 1 2 $strap
  # 左レンズ (46..49) 右レンズ (50..53)
  foreach ($lx in 46, 50) {
    Rect $b ($ox + $lx) 29 4 1 $fr
    Rect $b ($ox + $lx) 30 1 3 $fr2; Rect $b ($ox + $lx + 3) 30 1 3 $fr2
    Rect $b ($ox + $lx + 1) 30 2 3 $ln2
    Rect $b ($ox + $lx) 33 4 1 $fr2
  }
  Px $b ($ox + 47) 30 $sv3
  Px $b ($ox + 51) 30 $sv3
  # 目（レンズの下に見える）
  Px $b ($ox + 48) 31 $pk0; Px $b ($ox + 51) 31 $pk0
}

# ---- 小物
# はんだの巻き（リール）12x10
Sheet 'circuit_spool.png' 12 10 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 5.5) 5 5.4 4.6 $k0
  Ellipse $b ($ox + 5.5) 5 4.6 3.8 (C '#c0263a')
  Ellipse $b ($ox + 5.5) 5 3.4 2.8 $sv2
  Ellipse $b ($ox + 5.5) 5 2.2 1.8 $sv1
  Ellipse $b ($ox + 5.5) 5 1.0 0.9 $k0
  Px $b ($ox + 3) 3 $sv3; Px $b ($ox + 4) 3 $sv3
  Line $b ($ox + 9) 8 ($ox + 11) 9 $sv1
}
# 基板の山 14x7
Sheet 'circuit_stack.png' 14 7 1 {
  param($b, $ox, $f)
  foreach ($i in 0, 1, 2) {
    $yy = 4 - $i * 2 + 2
    $xo = @(0, 1, -0)[$i]
    Rect $b ($ox + $xo) $yy 13 3 $k0
    Rect $b ($ox + $xo + 1) $yy 11 2 $pg1; Rect $b ($ox + $xo + 1) $yy 11 1 $pg2
    Px $b ($ox + $xo + 3) ($yy + 1) $au1; Px $b ($ox + $xo + 6) ($yy + 1) $au1; Px $b ($ox + $xo + 9) ($yy + 1) $au1
  }
  Rect $b ($ox + 2) 1 5 2 $pk1; Px $b ($ox + 3) 1 $pk2
  Clear $b $ox 6
}
# ルーペつきのライト 16x20
Sheet 'circuit_lamp.png' 16 20 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 4) 18 3.6 1.6 $k0; Ellipse $b ($ox + 4) 17.5 2.8 1.0 $sv1; Px $b ($ox + 3) 17 $sv3
  Line $b ($ox + 4) 17 ($ox + 7) 10 $k0; Line $b ($ox + 5) 17 ($ox + 8) 10 $sv1
  Line $b ($ox + 7) 10 ($ox + 10) 7 $k0; Line $b ($ox + 8) 10 ($ox + 11) 7 $sv1
  Ellipse $b ($ox + 11) 4 4.4 4.0 $k0
  Ellipse $b ($ox + 11) 4 3.6 3.2 $sv1
  Ellipse $b ($ox + 11) 4 2.8 2.4 (C '#c8f0ff')
  Px $b ($ox + 9) 3 $sv3; Px $b ($ox + 10) 2 $sv3; Px $b ($ox + 13) 5 (C '#8ad0e8')
}
# コイル状の配線（床に置く）40x8
Sheet 'circuit_wire.png' 40 8 1 {
  param($b, $ox, $f)
  $p = @(@(0, 5), @(6, 4), @(12, 3), @(18, 4), @(24, 5), @(30, 4), @(36, 2), @(39, 1))
  for ($i = 0; $i -lt $p.Count - 1; $i++) { Line $b ($ox + $p[$i][0]) $p[$i][1] ($ox + $p[$i + 1][0]) $p[$i + 1][1] $k0; Line $b ($ox + $p[$i][0]) ($p[$i][1] + 1) ($ox + $p[$i + 1][0]) ($p[$i + 1][1] + 1) $pb1 }
  Line $b $ox 3 ($ox + 12) 6 $k0; Line $b ($ox + 12) 6 ($ox + 26) 2 $k0; Line $b ($ox + 26) 2 ($ox + 38) 6 $k0
  Px $b ($ox + 12) 6 $lr; Px $b ($ox + 26) 2 $ly
}
