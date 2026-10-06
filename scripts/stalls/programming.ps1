# プログラミング部の専用ドット絵（看板・パソコン・モニター・ゲーム画面・ホワイトボード・ポスター・サーバーラック・机など）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/programming.ps1
# 出力: client/public/brand/stall/programming_*.png （配置は scripts/stalls/programming.mjs）
# 配色はダークなUI（濃紺）にRGBのネオン（赤・緑・青・シアン・マゼンタ）。アニメは「フレームを横一列に並べたPNG」を k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}
# 決まった「でたらめ」（毎回同じ値）
function Hs($n) { return ((([int]$n * 73 + 19) * 31 + [int]$n * [int]$n * 7) % 97) }

# ---- 色
$neon = @((C '#ff3b4f'), (C '#3dff7a'), (C '#3d7bff'), (C '#ff3df0'), (C '#3df5ff'), (C '#ffe94a'))
$d0 = C '#04050e'; $d1 = C '#0a0f22'; $d2 = C '#121a38'; $d3 = C '#1c2850'; $d4 = C '#2c3c78'; $d5 = C '#4a5cae'
$s0 = C '#181b2a'; $s1 = C '#2a2f48'; $s2 = C '#4a5170'; $s3 = C '#8a92b8'; $s4 = C '#c6cce8'
$wht = C '#f4f6ff'
$cg = C '#39ff14'; $cgd = C '#16a82a'
$cy = $neon[4]; $mg = $neon[3]; $yl = $neon[5]; $rd = $neon[0]; $bl = $neon[2]; $gr = $neon[1]
$tokCols = @($cg, $cy, $mg, $yl, $wht, $cgd, $bl)

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
  '!' = @('.X.', '.X.', '.X.', '...', '.X.'); ',' = @('...', '...', '...', '.X.', 'X..'); '.' = @('...', '...', '...', '...', '.X.')
  '>' = @('X..', '.X.', '..X', '.X.', 'X..'); '<' = @('..X', '.X.', 'X..', '.X.', '..X'); '_' = @('...', '...', '...', '...', 'XXX')
  ':' = @('...', '.X.', '...', '.X.', '...'); '/' = @('..X', '..X', '.X.', 'X..', 'X..'); '=' = @('...', 'XXX', '...', 'XXX', '...')
  '(' = @('.X.', 'X..', 'X..', 'X..', '.X.'); ')' = @('.X.', '..X', '..X', '..X', '.X.'); '{' = @('.XX', '.X.', 'X..', '.X.', '.XX'); '}' = @('XX.', '.X.', '..X', '.X.', 'XX.')
  ';' = @('...', '.X.', '...', '.X.', 'X..'); '-' = @('...', '...', 'XXX', '...', '...'); '+' = @('...', '.X.', 'XXX', '.X.', '...'); '?' = @('XX.', '..X', '.X.', '...', '.X.'); '#' = @('X.X', 'XXX', 'X.X', 'XXX', 'X.X')
}
# 小さな文字を貼る。幅(px)を返す（1文字 = 3px + 1px のすき間）
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

# コードがならんだように見える行（w×h の画面に、行ごとに色つきの語を並べる）。$scroll でスクロール（8行で一周）
function CodeLines($b, $x, $y, $w, $h, $scroll, $cols) {
  $rows = [int][math]::Floor($h / 2)
  for ($r = 0; $r -lt $rows; $r++) {
    $L = ($r + $scroll) % 8
    $cx = $x + 1 + ((Hs ($L + 3)) % 3) * 2
    $k = 0
    while ($cx -lt $x + $w - 2) {
      $len = 2 + ((Hs ($L * 5 + $k)) % 6)
      $col = $cols[(Hs ($L * 11 + $k * 3)) % $cols.Count]
      if ($cx + $len -gt $x + $w - 1) { $len = $x + $w - 1 - $cx }
      if ($len -gt 0) { Rect $b $cx ($y + $r * 2) $len 1 $col }
      $cx += $len + 1; $k++
      if ((Hs ($L * 7 + $k)) % 5 -eq 0) { break }
    }
  }
}

# ---- 床 192x128（濃紺のタイル。真ん中の通路にシアンの光る矢印）
Sheet 'programming_floor.png' 192 128 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 192 128 $d1
  for ($y = 0; $y -lt 128; $y += 16) { Rect $b $ox $y 192 1 $d2 }
  for ($x = 0; $x -lt 192; $x += 16) { Rect $b ($ox + $x) 0 1 128 $d2 }
  for ($y = 8; $y -lt 128; $y += 16) { for ($x = 8; $x -lt 192; $x += 16) { if ((Hs ($x + $y * 3)) % 3 -eq 0) { Px $b ($ox + $x) $y $d4 } } }
  # 基板のような配線
  foreach ($t in @(@(8, 60, 30, 60), @(30, 60, 30, 72), @(150, 66, 182, 66), @(150, 66, 150, 54), @(14, 100, 14, 124), @(178, 96, 178, 124), @(40, 118, 66, 118), @(130, 118, 156, 118))) {
    Line $b ($ox + $t[0]) $t[1] ($ox + $t[2]) $t[3] $d3
    Px $b ($ox + $t[2]) $t[3] $d5
  }
  # 真ん中の通路（あいだ 36px）
  Rect $b ($ox + 78) 0 36 128 $d0
  Rect $b ($ox + 79) 0 34 128 (C '#0c1230')
  Rect $b ($ox + 78) 0 1 128 $d4; Rect $b ($ox + 113) 0 1 128 $d4
  Rect $b ($ox + 79) 0 1 128 (Mix $cy $d0 0.6); Rect $b ($ox + 112) 0 1 128 (Mix $mg $d0 0.6)
  for ($y = 60; $y -lt 128; $y += 14) {
    $a = Mix $cy $d1 (0.75 - ($y - 60) / 120.0)
    Line $b ($ox + 90) ($y + 4) ($ox + 96) $y $a; Line $b ($ox + 102) ($y + 4) ($ox + 96) $y $a
    Line $b ($ox + 91) ($y + 4) ($ox + 96) ($y + 1) $a; Line $b ($ox + 101) ($y + 4) ($ox + 96) ($y + 1) $a
  }
  Frame $b $ox 0 192 128 $d3
}

# ---- 奥の壁 184x38（濃紺のパネルに、うっすら 0 と 1 の数字。下にシアンのライン）
Sheet 'programming_wall.png' 184 38 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 184 38 (C '#0d1330')
  Rect $b $ox 0 184 2 $d4; Rect $b $ox 2 184 1 $d0
  for ($i = 0; $i -lt 8; $i++) {
    $px = $i * 23
    Rect $b ($ox + $px) 3 1 30 $d0; Rect $b ($ox + $px + 1) 3 1 30 $d2
    $s = ''
    for ($k = 0; $k -lt 5; $k++) { $s += [string]((Hs ($i * 9 + $k)) % 2) }
    [void](T3 $b $s ($ox + $px + 3) (6 + ((Hs $i) % 4) * 6) (C '#18224c'))
    [void](T3 $b $s ($ox + $px + 3) (12 + ((Hs ($i + 40)) % 3) * 6) (C '#141c3e'))
  }
  Rect $b $ox 33 184 5 $s1; Rect $b $ox 33 184 1 $s3; Rect $b $ox 37 184 1 $d0
  for ($x = 0; $x -lt 184; $x++) { if (($x % 8) -lt 5) { Px $b ($ox + $x) 35 (Mix $cy $s1 0.35) } }
  Clear $b $ox 0; Clear $b ($ox + 183) 0
}

# ---- 看板 124x30（{ プログラミング部 } 文字ごとにネオンが色変わり、枠が流れる）6コマ
$brL = @('..XX', '.XX.', '.XX.', '.XX.', '.XX.', 'XX..', 'XX..', '.XX.', '.XX.', '.XX.', '.XX.', '..XX')
$brR = @('XX..', '.XX.', '.XX.', '.XX.', '.XX.', '..XX', '..XX', '.XX.', '.XX.', '.XX.', '.XX.', 'XX..')
$signTxt = 'プログラミング部'
Sheet 'programming_sign.png' 124 30 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 124 30 $d0
  Rect $b ($ox + 3) 3 118 24 $d1
  for ($x = 2; $x -lt 122; $x++) {
    $c1 = $neon[([int][math]::Floor($x / 8) + $f) % 6]
    Px $b ($ox + $x) 2 $c1; Px $b ($ox + $x) 27 $neon[([int][math]::Floor($x / 8) + $f + 3) % 6]
    Px $b ($ox + $x) 3 (Mix $c1 $d1 0.65)
  }
  for ($y = 2; $y -lt 28; $y++) {
    Px $b ($ox + 2) $y $neon[([int][math]::Floor($y / 8) + $f + 2) % 6]; Px $b ($ox + 121) $y $neon[([int][math]::Floor($y / 8) + $f + 5) % 6]
  }
  Ascii $b ($ox + 7) 7 $brL @{ X = $neon[$f % 6] }
  Ascii $b ($ox + 113) 7 $brR @{ X = $neon[($f + 3) % 6] }
  for ($i = 0; $i -lt 8; $i++) {
    $ch = $signTxt.Substring($i, 1)
    [void](TextPx $b $ch ($ox + 14 + $i * 12 + 1) 6 12 $d0 $true)
    [void](TextPx $b $ch ($ox + 14 + $i * 12) 5 12 $neon[($f + $i) % 6] $true)
  }
  [void](T3 $b 'PROGRAMMING CLUB' ($ox + 30) 21 (Mix $cy $wht 0.25))
  Px $b ($ox + 25) 23 $mg; Px $b ($ox + 96) 23 $mg; Px $b ($ox + 97) 22 $mg; Px $b ($ox + 97) 24 $mg
  foreach ($p in @(@(0, 0), @(123, 0), @(0, 29), @(123, 29))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ---- 小さなキャラクター（ゲーム画面に出す）
function Hero($b, $x, $y, $leg) {
  $p = @{ c = $cy; w = $wht; m = $mg; k = $d0 }
  Ascii $b $x $y @('.cccc.', 'cwcwcc', 'cccccc', '.cmmc.') $p
  if ($leg -eq 0) { Ascii $b $x ($y + 4) @('.c..c.') $p } elseif ($leg -eq 1) { Ascii $b $x ($y + 4) @('..cc..') $p } else { Ascii $b $x ($y + 4) @('cc..cc') $p }
}
function Slime($b, $x, $y, $f) {
  $p = @{ r = $rd; w = $wht; k = $d0 }
  Ascii $b $x $y @('.rrrr.', 'rwrrwr', 'rrrrrr') $p
  if ($f % 2 -eq 0) { Ascii $b $x ($y + 3) @('r.rr.r') $p } else { Ascii $b $x ($y + 3) @('.r..r.') $p }
}
# モニターの枠（外側 w×h、スタンドは別に描く）
function Bezel($b, $x, $y, $w, $h) {
  Rect $b $x $y $w $h $d0
  Rect $b ($x + 1) ($y + 1) ($w - 2) ($h - 2) $s1
  Rect $b ($x + 1) ($y + 1) ($w - 2) 1 $s2
  Rect $b ($x + 1) ($y + $h - 2) ($w - 2) 1 $s0
  Rect $b ($x + 2) ($y + 2) ($w - 4) ($h - 5) $d0
}
function Stand($b, $cx, $y) {
  Rect $b ($cx - 2) $y 4 3 $s1; Rect $b ($cx - 2) $y 1 3 $s2
  Rect $b ($cx - 6) ($y + 3) 12 2 $s1; Rect $b ($cx - 6) ($y + 3) 12 1 $s2; Rect $b ($cx - 6) ($y + 5) 12 1 $d0
}

# ---- モニター A: コードが流れる（緑・シアン・マゼンタの文字）28x26 8コマ
Sheet 'programming_mon_code.png' 28 26 8 {
  param($b, $ox, $f)
  Bezel $b $ox 0 28 20
  Rect $b ($ox + 2) 2 24 15 (C '#03140c')
  Rect $b ($ox + 2) 2 24 2 $d3
  Px $b ($ox + 3) 2 $rd; Px $b ($ox + 5) 2 $yl; Px $b ($ox + 7) 2 $gr
  CodeLines $b ($ox + 2) 4 24 13 $f @($cg, $cg, $cy, $mg, $yl, $wht, $cgd)
  Px $b ($ox + 25) 18 $cg
  Stand $b ($ox + 14) 20
}

# ---- モニター B: Hello, World! が打たれていく（カーソルが点滅）28x26 8コマ
Sheet 'programming_mon_hello.png' 28 26 8 {
  param($b, $ox, $f)
  Bezel $b $ox 0 28 20
  Rect $b ($ox + 2) 2 24 15 (C '#020a14')
  Rect $b ($ox + 2) 2 24 2 $d3; Px $b ($ox + 3) 2 $cy; Px $b ($ox + 5) 2 $d5; Px $b ($ox + 7) 2 $d5
  $l1 = @('', 'HEL', 'HELLO,', 'HELLO,', 'HELLO,', 'HELLO,', 'HELLO,', 'HELLO,')[$f]
  $l2 = @('', '', '', '', 'WOR', 'WORLD!', 'WORLD!', 'WORLD!')[$f]
  if ($l1.Length -gt 0) { [void](T3 $b $l1 ($ox + 3) 5 $cg) }
  if ($l2.Length -gt 0) { [void](T3 $b $l2 ($ox + 3) 11 $cg) }
  if ($f % 2 -eq 0) {
    if ($l2.Length -gt 0 -and $l2.Length -lt 6) { Rect $b ($ox + 3 + $l2.Length * 4) 11 3 5 $cg }
    elseif ($l2.Length -eq 0 -and $l1.Length -eq 6) { Rect $b ($ox + 3) 11 3 5 $cg }
    elseif ($l1.Length -lt 6) { Rect $b ($ox + 3 + $l1.Length * 4) 5 3 5 $cg }
  }
  Px $b ($ox + 25) 18 $cy
  Stand $b ($ox + 14) 20
}

# ---- モニター C: ドット絵のアクションゲーム（ヒーローが走って、スライムをジャンプでよける）28x26 8コマ
Sheet 'programming_mon_game.png' 28 26 8 {
  param($b, $ox, $f)
  Bezel $b $ox 0 28 20
  # 空（上から濃い紫 → 青）と遠くの山
  for ($y = 0; $y -lt 15; $y++) { Rect $b ($ox + 2) (2 + $y) 24 1 (Mix (C '#1a1050') (C '#2c5ac8') ($y / 14.0)) }
  Ascii $b ($ox + 2) 8 @('........XX..........XXX...', '......XXXXXX......XXXXXXX..', '....XXXXXXXXXX..XXXXXXXXXX') @{ X = (C '#1c2a78') }
  foreach ($s in @(@(5, 3), @(14, 4), @(21, 3))) { if ((($f + $s[0]) % 4) -lt 3) { Px $b ($ox + $s[0] + 2) $s[1] $wht } }
  # 地面（レンガが左へ流れる）
  Rect $b ($ox + 2) 14 24 3 (C '#6a3a1c'); Rect $b ($ox + 2) 14 24 1 $gr
  for ($x = 0; $x -lt 24; $x++) { if ((($x + $f * 3) % 8) -eq 0) { Rect $b ($ox + 2 + $x) 15 1 2 (C '#3a1a0c') } }
  # スライム（左へ）・ヒーロー（ジャンプ）
  $sx = 27 - $f * 3
  if ($sx -gt 1 -and $sx -lt 24) { Slime $b ($ox + $sx) 10 $f }
  $lift = @(0, 0, 0, 0, 0, 0, 0, 0)[$f]
  $lift = @(0, 0, 0, 0, 3, 5, 3, 0)[$f]
  if ($f -ge 4 -and $f -le 6) { Hero $b ($ox + 6) (5 - $lift + 3) 2 } else { Hero $b ($ox + 6) 8 ($f % 2) }
  # コイン
  $cx = 22 - $f * 3; if ($cx -lt 3) { $cx += 24 }
  if (($f % 4) -lt 2) { Rect $b ($ox + $cx) 4 2 3 $yl } else { Rect $b ($ox + $cx) 4 1 3 $yl }
  foreach ($h in 0, 1, 2) { Ascii $b ($ox + 3 + $h * 4) 3 @('r.r', 'rrr', '.r.') @{ r = $rd } }
  Px $b ($ox + 25) 18 $mg
  Stand $b ($ox + 14) 20
}

# ---- モニター D: インベーダー風のシューティング 28x26 6コマ
Sheet 'programming_mon_shoot.png' 28 26 6 {
  param($b, $ox, $f)
  Bezel $b $ox 0 28 20
  Rect $b ($ox + 2) 2 24 15 (C '#04040e')
  foreach ($s in @(@(4, 12), @(20, 6), @(12, 15), @(8, 4), @(23, 13))) { Px $b ($ox + $s[0] + 2) ($s[1] + 2) (C '#3a4a98') }
  $sw = @(0, 1, 2, 2, 1, 0)[$f]
  for ($r = 0; $r -lt 2; $r++) {
    for ($c = 0; $c -lt 3; $c++) {
      $ax = 3 + $c * 7 + $sw; $ay = 4 + $r * 5
      $col = @($gr, $mg)[$r]
      if ($f % 2 -eq 0) { Ascii $b ($ox + $ax) $ay @('.X.X.', 'XXXXX', 'X.X.X') @{ X = $col } } else { Ascii $b ($ox + $ax) $ay @('.X.X.', 'XXXXX', '.X.X.') @{ X = $col } }
    }
  }
  $px = 9 + @(0, 2, 4, 6, 4, 2)[$f]
  Ascii $b ($ox + $px) 14 @('..c..', '.ccc.', 'ccccc') @{ c = $cy }
  $by = 13 - $f * 2
  if ($by -gt 4) { Rect $b ($ox + $px + 2) $by 1 2 $rd }
  if ($f -eq 4) { Px $b ($ox + 8) 6 $yl; Px $b ($ox + 10) 7 $yl; Px $b ($ox + 9) 5 $wht }
  Px $b ($ox + 25) 18 $gr
  Stand $b ($ox + 14) 20
}

# ---- ノートパソコン 22x13（画面にカラフルなコード、8コマ）
Sheet 'programming_laptop.png' 22 13 8 {
  param($b, $ox, $f)
  Rect $b ($ox + 2) 0 18 9 $d0
  Rect $b ($ox + 3) 1 16 7 $s1
  Rect $b ($ox + 4) 2 14 5 (C '#050816')
  CodeLines $b ($ox + 4) 2 14 5 $f @($cy, $mg, $yl, $gr, $wht, $cy, $rd)
  Px $b ($ox + 10) 8 $s3
  Rect $b $ox 9 22 3 $s2; Rect $b $ox 9 22 1 $s4; Rect $b $ox 11 22 1 $d0
  Rect $b ($ox + 3) 10 16 1 $d0
  for ($x = 4; $x -lt 18; $x += 2) { Px $b ($ox + $x) 10 $s3 }
  Rect $b ($ox + 9) 11 4 1 $s3
  Clear $b $ox 12; Clear $b ($ox + 21) 12
}

# ---- ゲーミングPC 14x24（ガラス窓の中で RGB のファンが回る）6コマ
Sheet 'programming_tower.png' 14 24 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 14 22 $d0
  Rect $b ($ox + 1) 1 12 20 $s0; Rect $b ($ox + 1) 1 12 1 $s2
  Rect $b ($ox + 2) 3 10 17 (C '#050816')
  Rect $b ($ox + 2) 3 1 17 (C '#0e1430')
  Rect $b ($ox + 3) 1 3 1 $s3
  Px $b ($ox + 11) 2 $neon[($f) % 6]
  foreach ($fy in 8, 15) {
    $col = $neon[($f + $fy) % 6]
    Ellipse $b ($ox + 7) $fy 4.2 4.2 (Mix $col $d0 0.62)
    Ellipse $b ($ox + 7) $fy 3.2 3.2 $d0
    if ($f % 2 -eq 0) { Line $b ($ox + 4) $fy ($ox + 10) $fy $col; Line $b ($ox + 7) ($fy - 3) ($ox + 7) ($fy + 3) $col }
    else { Line $b ($ox + 5) ($fy - 2) ($ox + 9) ($fy + 2) $col; Line $b ($ox + 9) ($fy - 2) ($ox + 5) ($fy + 2) $col }
    Px $b ($ox + 7) $fy $wht
  }
  Rect $b ($ox + 1) 20 12 1 $neon[($f + 3) % 6]
  Rect $b ($ox + 2) 22 3 2 $d0; Rect $b ($ox + 9) 22 3 2 $d0
  Clear $b $ox 0; Clear $b ($ox + 13) 0
}

# ---- キーボード 18x7（キーの光が波のように流れる）6コマ ＋ マウス 6x8
Sheet 'programming_kbd.png' 18 7 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 18 7 $d0
  Rect $b ($ox + 1) 1 16 5 $s1
  for ($r = 0; $r -lt 3; $r++) {
    for ($c = 0; $c -lt 7; $c++) {
      $col = $neon[([int]($c / 2) + $r + $f) % 6]
      Rect $b ($ox + 2 + $c * 2) (2 + $r * 1) 1 1 $col
      Px $b ($ox + 3 + $c * 2) (2 + $r) (Mix $col $s1 0.55)
    }
  }
  Rect $b ($ox + 2) 5 14 1 $s3
  Clear $b $ox 0; Clear $b ($ox + 17) 0; Clear $b $ox 6; Clear $b ($ox + 17) 6
}
Sheet 'programming_mouse.png' 6 8 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 3) 4.5 2.8 3.6 $d0
  Ellipse $b ($ox + 3) 4.5 2 2.8 $s2
  Rect $b ($ox + 3) 1 1 3 $d0
  Px $b ($ox + 3) 6 $cy
  Px $b ($ox + 1) 2 $s4
}

# ---- 机（長い作業机。下にシアン→マゼンタのネオン）78x16
Sheet 'programming_desk.png' 78 16 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 78 16 $d0
  Rect $b ($ox + 1) 1 76 6 (C '#3a4268'); Rect $b ($ox + 1) 1 76 1 $s3; Rect $b ($ox + 1) 6 76 1 $s1
  Rect $b ($ox + 1) 7 76 8 (C '#141830')
  foreach ($dx in 4, 28, 52) {
    Rect $b ($ox + $dx) 8 22 5 $d1; Frame $b ($ox + $dx) 8 22 5 $d3
    Rect $b ($ox + $dx + 9) 10 4 1 $s3
  }
  for ($x = 1; $x -lt 77; $x++) {
    $t = ($x - 1) / 75.0
    $col = if ($t -lt 0.5) { Mix $cy $mg ($t * 2) } else { Mix $mg $cy (($t - 0.5) * 2) }
    Px $b ($ox + $x) 14 $col
    Px $b ($ox + $x) 13 (Mix $col (C '#141830') 0.7)
  }
  Clear $b $ox 0; Clear $b ($ox + 77) 0; Clear $b $ox 15; Clear $b ($ox + 77) 15
}

# ---- サーバーラック 18x38（ランプが色々な速さで点滅）6コマ
Sheet 'programming_rack.png' 18 38 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 18 36 $d0
  Rect $b ($ox + 1) 1 16 34 $s0
  Rect $b ($ox + 1) 1 16 1 $s2
  for ($u = 0; $u -lt 4; $u++) {
    $y = 3 + $u * 8
    Rect $b ($ox + 2) $y 14 7 $s1; Rect $b ($ox + 2) $y 14 1 $s2; Rect $b ($ox + 2) ($y + 6) 14 1 $d0
    for ($v = 0; $v -lt 4; $v++) { Rect $b ($ox + 3 + $v * 2) ($y + 2) 1 3 $d0 }
    for ($l = 0; $l -lt 3; $l++) {
      $on = ((Hs ($u * 7 + $l * 3 + $f * (1 + $l % 2))) % 3) -ne 0
      $cols = @($gr, $cy, $yl, $mg)
      $c = $cols[($u + $l) % 4]
      if ($on) { Px $b ($ox + 12 + $l * 1 + $l) ($y + 3) $c } else { Px $b ($ox + 12 + $l * 2) ($y + 3) (Mix $c $d0 0.75) }
    }
    Px $b ($ox + 14) ($y + 5) $s3
  }
  Rect $b ($ox + 1) 35 16 1 $d0
  Rect $b ($ox + 1) 36 3 2 $d0; Rect $b ($ox + 14) 36 3 2 $d0
  Rect $b ($ox + 16) 1 1 34 (Mix $cy $s0 0.5)
  Clear $b $ox 0; Clear $b ($ox + 17) 0
}

# ---- ホワイトボード 52x32（フローチャートと付箋）
Sheet 'programming_whiteboard.png' 52 32 1 {
  param($b, $ox, $f)
  $ink = C '#2a2f55'
  Rect $b $ox 0 52 29 $d0
  Rect $b ($ox + 1) 1 50 27 $s3; Rect $b ($ox + 1) 1 50 1 $s4
  Rect $b ($ox + 2) 2 48 25 (C '#eef1f8')
  Rect $b ($ox + 2) 2 48 1 (C '#d4d9e8')
  # START
  Rect $b ($ox + 4) 4 20 7 $bl
  [void](T3 $b 'START' ($ox + 5) 5 $wht)
  Line $b ($ox + 14) 11 ($ox + 14) 14 $ink; Px $b ($ox + 13) 13 $ink; Px $b ($ox + 15) 13 $ink
  # ひし形（OK?）
  for ($y = 0; $y -le 12; $y++) {
    $hw = [int][math]::Round(10 - [math]::Abs($y - 6) * (10 / 6.0))
    Px $b ($ox + 14 - $hw) (14 + $y) $ink; Px $b ($ox + 14 + $hw) (14 + $y) $ink
  }
  Px $b ($ox + 14) 14 $ink; Px $b ($ox + 14) 26 $ink
  [void](T3 $b 'OK?' ($ox + 9) 18 $rd)
  # NO のループ
  Line $b ($ox + 24) 20 ($ox + 31) 20 $ink; Line $b ($ox + 31) 20 ($ox + 31) 7 $ink; Line $b ($ox + 31) 7 ($ox + 25) 7 $ink
  Px $b ($ox + 26) 6 $ink; Px $b ($ox + 26) 8 $ink
  [void](T3 $b 'NO' ($ox + 25) 13 $ink)
  # 付箋
  Rect $b ($ox + 35) 4 8 8 $yl; Rect $b ($ox + 35) 4 8 1 (C '#e8c820'); Rect $b ($ox + 36) 7 5 1 $ink; Rect $b ($ox + 36) 9 4 1 $ink
  Rect $b ($ox + 43) 6 7 8 (C '#ff8ad8'); Rect $b ($ox + 44) 9 4 1 $ink; Rect $b ($ox + 44) 11 5 1 $ink
  Rect $b ($ox + 37) 15 9 8 (C '#7ae8f4'); Rect $b ($ox + 38) 18 6 1 $ink; Rect $b ($ox + 38) 20 4 1 $ink; Px $b ($ox + 42) 16 $gr; Px $b ($ox + 43) 17 $gr
  Px $b ($ox + 39) 4 $rd; Px $b ($ox + 46) 6 $rd
  # ペン置き
  Rect $b ($ox + 6) 29 40 2 $s2; Rect $b ($ox + 6) 29 40 1 $s3
  Rect $b ($ox + 12) 28 4 1 $rd; Rect $b ($ox + 19) 28 4 1 $bl; Rect $b ($ox + 26) 28 4 1 $gr
  Clear $b $ox 0; Clear $b ($ox + 51) 0
}

# ---- ポスター「GAME」24x32
Sheet 'programming_poster_game.png' 24 32 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 24 32 $d0
  Frame $b ($ox + 1) 1 22 30 $mg
  for ($y = 2; $y -lt 30; $y++) { Rect $b ($ox + 2) $y 20 1 (Mix (C '#2a0f60') (C '#102a78') ($y / 28.0)) }
  Ellipse $b ($ox + 17) 8 3.4 3.4 $yl; Ellipse $b ($ox + 16) 7 2 2 (C '#fff6a0')
  foreach ($s in @(@(5, 5), @(9, 10), @(19, 14), @(4, 14))) { Px $b ($ox + $s[0]) $s[1] $wht }
  Rect $b ($ox + 2) 22 20 5 (C '#1a8a3a'); Rect $b ($ox + 2) 22 20 1 $gr
  Hero $b ($ox + 9) 14 2
  foreach ($hx in 4, 9, 14) { Ascii $b ($ox + $hx) 3 @('r.r', 'rrr', '.r.') @{ r = $rd } }
  [void](T3 $b 'GAME' ($ox + 5) 24 $d0)
  [void](T3 $b 'GAME' ($ox + 4) 23 $yl)
  Clear $b $ox 0; Clear $b ($ox + 23) 0
}

# ---- ポスター「</>」22x30
Sheet 'programming_poster_code.png' 22 30 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 22 30 $d0
  Frame $b ($ox + 1) 1 20 28 $cy
  Rect $b ($ox + 2) 2 18 26 (C '#050816')
  CodeLines $b ($ox + 3) 3 16 6 0 @($cgd, $cg, $d5, $d4)
  foreach ($o in 0, 1) {
    Line $b ($ox + 8 + $o) 11 ($ox + 4 + $o) 15 $cy; Line $b ($ox + 4 + $o) 15 ($ox + 8 + $o) 19 $cy
    Line $b ($ox + 13 + $o) 10 ($ox + 10 + $o) 20 $mg
    Line $b ($ox + 14 + $o) 11 ($ox + 18 + $o) 15 $gr; Line $b ($ox + 18 + $o) 15 ($ox + 14 + $o) 19 $gr
  }
  [void](T3 $b 'CODE' ($ox + 4) 22 $wht)
  Clear $b $ox 0; Clear $b ($ox + 21) 0
}

# ---- 体験コーナーの案内（置き看板。「PRESS START」が点滅）54x42 2コマ
Sheet 'programming_aframe.png' 54 40 2 {
  param($b, $ox, $f)
  foreach ($lx in 6, 46) {
    $dxl = if ($lx -lt 20) { -3 } else { 3 }
    Line $b ($ox + $lx) 34 ($ox + $lx + $dxl) 39 $s2; Line $b ($ox + $lx + 1) 34 ($ox + $lx + $dxl + 1) 39 $d0
  }
  Rect $b ($ox + 2) 0 50 36 $d0
  Rect $b ($ox + 3) 1 48 34 $d1
  Frame $b ($ox + 3) 1 48 34 $cy
  for ($x = 4; $x -lt 50; $x++) { if ((($x + 2) % 6) -lt 3) { Rect $b ($ox + $x) 2 1 3 $yl } else { Rect $b ($ox + $x) 2 1 3 $d0 } }
  [void](T3 $b '>' ($ox + 6) 9 $mg); [void](T3 $b '<' ($ox + 45) 9 $mg)
  [void](TextPx $b '体' ($ox + 16) 6 12 $d0 $true); [void](TextPx $b '体' ($ox + 15) 5 12 $wht $true)
  [void](TextPx $b '験' ($ox + 28) 6 12 $d0 $true); [void](TextPx $b '験' ($ox + 27) 5 12 $wht $true)
  $cols4 = @($cy, $mg, $yl, $gr)
  $tx = 'コーナー'
  for ($i = 0; $i -lt 4; $i++) { [void](TextPx $b $tx.Substring($i, 1) ($ox + 7 + $i * 10) 18 10 $cols4[$i] $false) }
  if ($f -eq 0) { [void](T3 $b 'PRESS START' ($ox + 6) 29 $gr) } else { [void](T3 $b 'PRESS START' ($ox + 6) 29 (Mix $gr $d1 0.7)) }
  Clear $b ($ox + 2) 0; Clear $b ($ox + 51) 0
}

# ---- 壁のビッグスクリーン 56x28（アクションゲームが流れる。枠のネオンが回る）8コマ
Sheet 'programming_bigscreen.png' 56 28 8 {
  param($b, $ox, $f)
  Rect $b $ox 0 56 28 $d0
  Rect $b ($ox + 1) 1 54 26 $s1
  for ($x = 1; $x -lt 55; $x++) { Px $b ($ox + $x) 1 $neon[([int][math]::Floor($x / 9) + $f) % 6]; Px $b ($ox + $x) 26 $neon[([int][math]::Floor($x / 9) + $f + 3) % 6] }
  for ($y = 1; $y -lt 27; $y++) { Px $b ($ox + 1) $y $neon[([int][math]::Floor($y / 9) + $f + 1) % 6]; Px $b ($ox + 54) $y $neon[([int][math]::Floor($y / 9) + $f + 4) % 6] }
  Rect $b ($ox + 3) 3 50 18 $d0
  for ($y = 0; $y -lt 18; $y++) { Rect $b ($ox + 3) (3 + $y) 50 1 (Mix (C '#1a1050') (C '#3a6ae0') ($y / 17.0)) }
  for ($x = 0; $x -lt 50; $x++) {
    $h = [int](5 + 4 * [math]::Abs([math]::Sin($x / 7.0)) + 3 * [math]::Abs([math]::Sin($x / 3.3 + 1)))
    Rect $b ($ox + 3 + $x) (16 - $h) 1 $h (C '#1c2a78')
  }
  foreach ($c0 in @(@(6, 6), @(22, 9))) {
    $cx = (($c0[0] - $f * 4) % 32 + 32) % 32
    foreach ($rep in 0, 32) { $x = $cx + $rep; if ($x -lt 44) { Rect $b ($ox + 3 + $x) ($c0[1]) 7 2 (C '#8aa8f0'); Rect $b ($ox + 4 + $x) ($c0[1] - 1) 4 1 (C '#8aa8f0') } }
  }
  Rect $b ($ox + 3) 16 50 5 (C '#6a3a1c'); Rect $b ($ox + 3) 16 50 1 $gr; Rect $b ($ox + 3) 17 50 1 (C '#1a8a3a')
  for ($x = 0; $x -lt 50; $x++) { if ((($x + $f * 4) % 8) -eq 0) { Rect $b ($ox + 3 + $x) 18 1 3 (C '#3a1a0c') } }
  Rect $b ($ox + 3) 19 50 1 (C '#3a1a0c')
  $cx = ((20 - 4 * $f) % 32 + 32) % 32
  foreach ($rep in 0, 32) {
    $x = $cx + $rep
    if ($x -lt 48) { if ($f % 2 -eq 0) { Rect $b ($ox + 3 + $x) 7 3 4 $yl; Px $b ($ox + 4 + $x) 8 (C '#fff6a0') } else { Rect $b ($ox + 4 + $x) 7 1 4 $yl } }
  }
  foreach ($k in 0, 1, 2) {
    $sx = 12 + 32 * $k - 4 * $f
    if ($sx -gt 2 -and $sx -lt 45) { Slime $b ($ox + 3 + $sx) 12 $f }
  }
  $lift = @(0, 0, 2, 4, 4, 2, 0, 0)[$f]
  if ($lift -gt 0) { Hero $b ($ox + 30) (11 - $lift) 2 } else { Hero $b ($ox + 30) 11 ($f % 2) }
  [void](T3 $b '00120' ($ox + 6) 5 $wht)
  foreach ($h in 0, 1, 2) { Ascii $b ($ox + 42 + $h * 4) 4 @('r.r', 'rrr', '.r.') @{ r = $rd } }
  Rect $b ($ox + 3) 21 50 5 $d1
  [void](T3 $b 'PLAY ME!' ($ox + 12) 21 $cy)
  Px $b ($ox + 6) 23 $neon[$f % 6]; Px $b ($ox + 49) 23 $neon[($f + 3) % 6]
  Clear $b $ox 0; Clear $b ($ox + 55) 0
}

# ---- 小物
function Can($name, $col) {
  Sheet $name 5 9 1 {
    param($b, $ox, $f)
    Rect $b $ox 1 5 8 $d0
    Rect $b ($ox + 1) 2 3 6 $col; Rect $b ($ox + 1) 2 1 6 (Mix $col $wht 0.5)
    Rect $b ($ox + 1) 4 3 1 $d0
    Rect $b ($ox + 1) 1 3 1 $s3
  }
}
Can 'programming_can_g.png' $neon[1]
Can 'programming_can_r.png' $neon[0]
Can 'programming_can_b.png' $neon[4]
Sheet 'programming_mug.png' 7 7 1 {
  param($b, $ox, $f)
  Rect $b $ox 1 5 6 $d0; Rect $b ($ox + 1) 2 3 4 $wht; Rect $b ($ox + 1) 2 3 1 (C '#5a3418')
  Rect $b ($ox + 5) 2 2 3 $d0; Px $b ($ox + 6) 3 $d0; Rect $b ($ox + 1) 5 3 1 $cy
}
Sheet 'programming_cactus.png' 10 14 1 {
  param($b, $ox, $f)
  $g1 = C '#2fa84a'; $g2 = C '#1c6a30'
  Rect $b ($ox + 4) 1 3 9 $g1; Rect $b ($ox + 4) 1 1 9 (C '#5ad86e'); Rect $b ($ox + 6) 1 1 9 $g2
  Rect $b ($ox + 1) 4 2 4 $g1; Rect $b ($ox + 1) 7 4 2 $g1; Rect $b ($ox + 7) 3 2 4 $g1; Rect $b ($ox + 6) 6 3 2 $g1
  Px $b ($ox + 5) 3 $mg; Px $b ($ox + 2) 5 $wht
  Rect $b ($ox + 2) 10 6 4 (C '#7a3a28'); Rect $b ($ox + 2) 10 6 1 (C '#a85a3c'); Rect $b ($ox + 3) 13 4 1 $d0
}
Sheet 'programming_strip.png' 14 5 4 {
  param($b, $ox, $f)
  Rect $b $ox 1 14 4 $d0; Rect $b ($ox + 1) 1 12 3 $s2; Rect $b ($ox + 1) 1 12 1 $s3
  foreach ($x in 3, 6, 9) { Rect $b ($ox + $x) 2 2 1 $d0 }
  if ($f % 2 -eq 0) { Px $b ($ox + 12) 2 $gr } else { Px $b ($ox + 12) 2 (Mix $gr $d0 0.6) }
  Px $b ($ox + 2) 0 $s1
}
Sheet 'programming_cable.png' 40 8 1 {
  param($b, $ox, $f)
  $p = @(@(0, 5), @(6, 4), @(12, 3), @(18, 4), @(24, 5), @(30, 4), @(36, 2), @(39, 1))
  for ($i = 0; $i -lt $p.Count - 1; $i++) { Line $b ($ox + $p[$i][0]) $p[$i][1] ($ox + $p[$i + 1][0]) $p[$i + 1][1] $d0; Line $b ($ox + $p[$i][0]) ($p[$i][1] + 1) ($ox + $p[$i + 1][0]) ($p[$i + 1][1] + 1) $s0 }
  Line $b $ox 3 ($ox + 12) 6 $d0; Line $b ($ox + 12) 6 ($ox + 26) 2 $d0; Line $b ($ox + 26) 2 ($ox + 38) 6 $d0
  Px $b ($ox + 12) 6 $cy; Px $b ($ox + 26) 2 $mg
}
