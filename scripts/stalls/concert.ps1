# コンサート会場の専用ドット絵（ステージ・幕・トラス・照明・スピーカー・ドラム・キーボード・アンプ・看板・ペンライト・PA卓・ゲートなど）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/concert.ps1
# 出力: client/public/brand/stall/concert_*.png （配置は scripts/stalls/concert.mjs）
# 配色は RGB（赤・緑・青・マゼンタ・シアン）のネオン。アニメは「フレームを横一列に並べたPNG」で、concert.mjs の k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}

# ネオン色（赤・緑・青・マゼンタ・シアン・黄）
$neon = @((C '#ff3b4f'), (C '#3dff7a'), (C '#3d7bff'), (C '#ff3df0'), (C '#3df5ff'), (C '#ffe94a'))
$neonHex = @('#ff3b4f', '#3dff7a', '#3d7bff', '#ff3df0', '#3df5ff', '#ffe94a')
$rgb5 = @($neon[0], $neon[1], $neon[2], $neon[3], $neon[4])
# 夜の紫
$n0 = C '#07051a'; $n1 = C '#120e32'; $n2 = C '#201850'; $n3 = C '#33287a'; $n4 = C '#4d3fa0'
# 機材の金属
$m0 = C '#15151d'; $m1 = C '#24242f'; $m2 = C '#3b3b4d'; $m3 = C '#5e5e78'; $m4 = C '#9494b0'; $m5 = C '#c8c8dc'
$wht = C '#f4f2ff'
$gold2 = C '#e8b23a'; $gold3 = C '#a8741c'

# ---- 看板 LIVE 96x32（ネオンが色を追いかけて点滅）6コマ
$glyph = @{
  L = @('X....', 'X....', 'X....', 'X....', 'X....', 'X....', 'XXXXX')
  I = @('XXXXX', '..X..', '..X..', '..X..', '..X..', '..X..', 'XXXXX')
  V = @('X...X', 'X...X', 'X...X', '.X.X.', '.X.X.', '.X.X.', '..X..')
  E = @('XXXXX', 'X....', 'X....', 'XXXX.', 'X....', 'X....', 'XXXXX')
}
function Glyph($b, $g, $x, $y, $s, $col) {
  for ($r = 0; $r -lt $g.Count; $r++) { for ($c = 0; $c -lt $g[$r].Length; $c++) { if ($g[$r].Substring($c, 1) -eq 'X') { Rect $b ($x + $c * $s) ($y + $r * $s) $s $s $col } } }
}
# V だけは斜めの線で描く（15x21。左右の太さ3pxの線が下で合わさる）
function VGlyph($b, $x, $y, $col) {
  for ($r = 0; $r -lt 21; $r++) {
    $x0 = [int][math]::Floor($r * 6 / 20.0)
    Rect $b ($x + $x0) ($y + $r) 3 1 $col
    Rect $b ($x + 12 - $x0) ($y + $r) 3 1 $col
  }
}
Sheet 'concert_sign.png' 96 32 6 {
  param($b, $ox, $f)
  $fc = $neon[$f % 6]
  Rect $b $ox 0 96 32 $n0
  Rect $b ($ox + 1) 1 94 30 $n1
  Frame $b ($ox + 2) 2 92 28 $fc
  Frame $b ($ox + 3) 3 90 26 (Mix $fc $n1 0.6)
  $i = 0
  foreach ($ch in 'L', 'I', 'V', 'E') {
    $x = 12 + $i * 19
    if ($ch -eq 'V') { VGlyph $b ($ox + $x + 1) 7 $n0; VGlyph $b ($ox + $x) 6 $neon[($f + $i) % 6] }
    else { Glyph $b $glyph[$ch] ($ox + $x + 1) 7 3 $n0; Glyph $b $glyph[$ch] ($ox + $x) 6 3 $neon[($f + $i) % 6] }
    Rect $b ($ox + $x) 6 15 1 (Mix $neon[($f + $i) % 6] $wht 0.5)
    $i++
  }
  $sp = $neon[($f + 3) % 6]
  foreach ($sx in 6, 90) { Px $b ($ox + $sx) 14 $sp; Px $b ($ox + $sx) 16 $sp; Px $b ($ox + $sx - 1) 15 $sp; Px $b ($ox + $sx + 1) 15 $sp; Px $b ($ox + $sx) 15 $wht }
  foreach ($p in @(@(0, 0), @(95, 0), @(0, 31), @(95, 31))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ---- トラス（照明の骨組み＋左右の柱＋吊り下げたライト5つ）150x58。ライトの色が回る 6コマ
$lightX = @(28, 52, 75, 98, 122)
Sheet 'concert_truss.png' 150 58 6 {
  param($b, $ox, $f)
  Rect $b $ox 6 150 1 $m4; Rect $b $ox 7 150 1 $m3; Rect $b $ox 15 150 1 $m3; Rect $b $ox 16 150 1 $m1
  for ($x = 2; $x -lt 146; $x += 6) { Line $b ($ox + $x) 8 ($ox + $x + 3) 14 $m2; Line $b ($ox + $x + 3) 14 ($ox + $x + 6) 8 $m2 }
  foreach ($lx in 8, 136) {
    Rect $b ($ox + $lx) 6 1 52 $m4; Rect $b ($ox + $lx + 5) 6 1 52 $m2; Rect $b ($ox + $lx + 1) 6 4 1 $m3
    for ($y = 8; $y -lt 54; $y += 6) { Line $b ($ox + $lx + 1) $y ($ox + $lx + 4) ($y + 3) $m3; Line $b ($ox + $lx + 4) ($y + 3) ($ox + $lx + 1) ($y + 6) $m3 }
    Rect $b ($ox + $lx - 1) 56 8 2 $m1; Rect $b ($ox + $lx - 1) 56 8 1 $m3
  }
  for ($i = 0; $i -lt 5; $i++) {
    $x = $lightX[$i]; $col = $neon[($f + $i) % 6]
    Rect $b ($ox + $x - 1) 17 2 2 $m3
    Rect $b ($ox + $x - 4) 19 8 4 $m0; Rect $b ($ox + $x - 4) 19 8 1 $m2
    Rect $b ($ox + $x - 3) 23 6 2 $col; Px $b ($ox + $x - 1) 23 $wht; Px $b ($ox + $x) 23 $wht
    Rect $b ($ox + $x - 4) 25 8 1 (Mix $col $n0 0.55)
  }
}

# ---- 光線（トラスのライトからステージへ。半透明）150x56。ゆっくり振れて色が回る 6コマ。トラスと同じコマ数・fpsで同期
Sheet 'concert_beams.png' 150 56 6 {
  param($b, $ox, $f)
  for ($i = 0; $i -lt 5; $i++) {
    $lx = $lightX[$i]; $col = $neon[($f + $i) % 6]
    $tx = $lx + 15 * [math]::Sin(($f / 6.0) * 2 * [math]::PI + $i * 1.3)
    $hex = $neonHex[($f + $i) % 6]
    for ($r = 0; $r -le 40; $r++) {
      $t = $r / 40.0
      $cx = $lx + ($tx - $lx) * $t
      $hw = 1 + 9 * $t
      $a = [int](62 - 34 * $t)
      for ($x = [math]::Floor($cx - $hw); $x -le [math]::Ceiling($cx + $hw); $x++) {
        $e = [math]::Abs($x + 0.5 - $cx) / $hw
        $al = [int][math]::Max(0, [math]::Min(255, $a * (1.15 - 0.6 * $e)))
        if ($al -gt 0) { Px $b ($ox + $x) (1 + $r) (CA $hex $al) }
      }
    }
    Ellipse $b ($ox + $tx) 41 12 3.6 (CA $hex 105)
    Ellipse $b ($ox + $tx) 41 6 1.8 (CA $hex 150)
  }
}

$screenTxt = 'コンサート会場'
$screenTw = TextWidth $screenTxt 10
# ---- 背景の幕（左右のカーテンと、真ん中のLEDスクリーンにイコライザー）124x36 4コマ
Sheet 'concert_backdrop.png' 124 36 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 124 36 $n1
  for ($x = 0; $x -lt 124; $x++) {
    $m = $x % 8
    if ($m -lt 2) { Rect $b ($ox + $x) 3 1 30 $n2 } elseif ($m -eq 4 -or $m -eq 5) { Rect $b ($ox + $x) 3 1 30 $n0 }
  }
  Rect $b $ox 0 124 3 (Mix $neon[3] $n1 0.55)
  for ($x = 0; $x -lt 124; $x += 8) { Ellipse $b ($ox + $x + 4) 3 4 2.4 (Mix $neon[3] $n1 0.55) }
  Rect $b ($ox + 19) 3 1 30 $neon[($f) % 6]; Rect $b ($ox + 104) 3 1 30 $neon[($f + 3) % 6]
  Rect $b ($ox + 20) 4 84 28 $m1; Frame $b ($ox + 20) 4 84 28 $m3
  Rect $b ($ox + 22) 6 80 24 (C '#05031a')
  $barCols = @($neon[0], $neon[5], $neon[1], $neon[4], $neon[2], $neon[3])
  for ($i = 0; $i -lt 16; $i++) {
    $h = 2 + [int](((([math]::Sin($i * 0.9 + $f * 1.9)) + 1) / 2) * 9)
    $col = $barCols[[int][math]::Floor($i * 6 / 16)]
    Rect $b ($ox + 22 + $i * 5 + 1) (30 - $h) 4 $h $col
    Rect $b ($ox + 22 + $i * 5 + 1) (30 - $h) 4 1 (Mix $col $wht 0.6)
  }
  $tc = @($neon[4], $wht, $neon[3], $wht)[$f]
  [void](TextPx $b $screenTxt ($ox + 22 + [math]::Floor((80 - $screenTw) / 2)) 6 10 $tc $false)
  Rect $b $ox 33 124 3 $n0
}

# ---- 舞台の床（ステップ付き）132x28 6コマ。前のふちのLEDが流れる
Sheet 'concert_deck.png' 132 28 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 132 18 (C '#2b2150')
  for ($y = 5; $y -lt 18; $y += 6) { Rect $b $ox $y 132 1 (C '#201845') }
  for ($y = 0; $y -lt 18; $y += 6) { for ($x = ($y / 6 % 2) * 11; $x -lt 132; $x += 22) { Px $b ($ox + $x) ($y + 3) (C '#3a2d68') } }
  foreach ($p in @(@(20, 9), @(66, 4), @(100, 11), @(46, 13))) { Px $b ($ox + $p[0]) $p[1] $m4; Px $b ($ox + $p[0] + 2) ($p[1] + 2) $m4; Px $b ($ox + $p[0] + 2) $p[1] $m4; Px $b ($ox + $p[0]) ($p[1] + 2) $m4; Px $b ($ox + $p[0] + 1) ($p[1] + 1) $m4 }
  Rect $b $ox 18 132 8 (C '#100c2a')
  for ($x = 11; $x -lt 132; $x += 12) { Rect $b ($ox + $x) 18 1 8 (C '#1a1440') }
  for ($x = 0; $x -lt 132; $x++) {
    $col = $neon[([int][math]::Floor($x / 6) + $f) % 6]
    Px $b ($ox + $x) 16 $col; Px $b ($ox + $x) 17 (Mix $col $n0 0.55)
  }
  $tread = C '#6a58b8'; $riser = C '#2a2054'
  Rect $b ($ox + 52) 18 28 3 $tread; Rect $b ($ox + 52) 20 28 1 $riser
  Rect $b ($ox + 51) 21 30 2 $tread; Rect $b ($ox + 51) 23 30 1 $riser
  Rect $b ($ox + 50) 24 32 2 $tread; Rect $b ($ox + 50) 26 32 1 $riser; Rect $b ($ox + 50) 27 32 1 $n0
  Rect $b ($ox + 52) 18 28 1 (C '#9a88ee')
  Rect $b $ox 26 50 1 $n0; Rect $b ($ox + 82) 26 50 1 $n0
  Rect $b $ox 0 1 26 (C '#100c2a'); Rect $b ($ox + 131) 0 1 26 (C '#100c2a')
}

# ---- スピーカーの山（左右）26x52。ウーファーが脈打って、ランプが色変わり 4コマ
function Woofer($b, $cx, $cy, $r, $p) {
  Ellipse $b $cx $cy $r $r $m0
  Ellipse $b $cx $cy ($r - 1) ($r - 1) $m3
  Ellipse $b $cx $cy ($r - 2) ($r - 2) $m1
  Ellipse $b $cx $cy ($r - 3.5 + $p * 0.4) ($r - 3.5 + $p * 0.4) $m2
  Ellipse $b $cx $cy (1.2 + $p) (1.2 + $p) $m4
  Ellipse $b $cx $cy (0.6 + $p * 0.5) (0.6 + $p * 0.5) $m0
  Px $b ($cx - $r + 2) ($cy - 2) $m4
}
function Cabinet($b, $ox, $x, $y, $w, $h) {
  Rect $b ($ox + $x) $y $w $h $m0
  Rect $b ($ox + $x + 1) ($y + 1) ($w - 2) ($h - 2) $m1
  Rect $b ($ox + $x + 1) ($y + 1) ($w - 2) 1 $m2
  Rect $b ($ox + $x + 1) ($y + 1) 1 ($h - 2) $m2
  Px $b ($ox + $x + 2) ($y + 2) $m0; Px $b ($ox + $x + $w - 3) ($y + 2) $m0; Px $b ($ox + $x + 2) ($y + $h - 3) $m0; Px $b ($ox + $x + $w - 3) ($y + $h - 3) $m0
}
Sheet 'concert_speaker.png' 26 52 4 {
  param($b, $ox, $f)
  $p = @(0, 1.2, 2, 1.2)[$f]
  Cabinet $b $ox 3 2 20 12
  Rect $b ($ox + 6) 5 14 6 $m0
  for ($x = 7; $x -lt 20; $x += 2) { Rect $b ($ox + $x) 5 1 6 $m3 }
  Px $b ($ox + 20) 4 $neon[$f % 6]; Px $b ($ox + 5) 4 $neon[($f + 3) % 6]
  Cabinet $b $ox 1 14 24 18
  Woofer $b ($ox + 13) 23 6.5 ($p * 0.6)
  Rect $b ($ox + 2) 14 22 1 $neon[3]
  Cabinet $b $ox 0 32 26 20
  Woofer $b ($ox + 13) 42 8.5 $p
  Rect $b ($ox + 1) 32 24 1 $neon[3]
  Rect $b ($ox + 3) 51 4 1 $m0; Rect $b ($ox + 19) 51 4 1 $m0
  foreach ($p2 in @(@(0, 2), @(25, 2), @(0, 14), @(24, 14), @(0, 32), @(25, 32))) { Clear $b ($ox + $p2[0]) $p2[1] }
  Rect $b $ox 51 26 1 $m0
}

# ---- ドラムセット（奥: シンバルとタム / 手前: バスドラ・スネア・フロアタム）
Sheet 'concert_drums_back.png' 34 22 1 {
  param($b, $ox, $f)
  Line $b ($ox + 7) 6 ($ox + 7) 21 $m3; Line $b ($ox + 27) 7 ($ox + 27) 21 $m3
  Ellipse $b ($ox + 7) 5 6.5 1.8 $gold3; Ellipse $b ($ox + 7) 4.6 6 1.4 $gold2; Px $b ($ox + 6) 4 (C '#fff0b0')
  Ellipse $b ($ox + 27) 6 6.5 1.8 $gold3; Ellipse $b ($ox + 27) 5.6 6 1.4 $gold2; Px $b ($ox + 26) 5 (C '#fff0b0')
  foreach ($tx in 10, 18) {
    Rect $b ($ox + $tx) 10 7 6 (C '#e8e8f4'); Rect $b ($ox + $tx) 10 7 1 $neon[4]; Rect $b ($ox + $tx) 15 7 1 $neon[3]
    Rect $b ($ox + $tx + 6) 11 1 4 (C '#b8b8cc'); Rect $b ($ox + $tx) 11 1 4 (C '#b8b8cc')
  }
}
Sheet 'concert_drums_front.png' 34 16 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 17) 8.5 8 7.5 $m0
  Ellipse $b ($ox + 17) 8.5 7 6.5 (C '#e8e8f4')
  Ellipse $b ($ox + 17) 8.5 5.8 5.4 (C '#1a1240')
  Ellipse $b ($ox + 17) 8.5 5 4.6 $neon[3]
  Ellipse $b ($ox + 17) 8.5 3.6 3.2 (C '#1a1240')
  Rect $b ($ox + 16) 7 3 3 $neon[4]; Px $b ($ox + 17) 6 $wht
  Ellipse $b ($ox + 5) 8 4.5 3 $m0; Ellipse $b ($ox + 5) 7.5 4 2.5 (C '#f4f4fc'); Rect $b ($ox + 3) 10 5 3 (C '#c8c8dc'); Rect $b ($ox + 3) 12 5 1 $m3
  Ellipse $b ($ox + 29) 9 4.5 3 $m0; Ellipse $b ($ox + 29) 8.5 4 2.5 (C '#f4f4fc'); Rect $b ($ox + 26) 11 6 3 (C '#c8c8dc'); Rect $b ($ox + 26) 13 6 1 $m3
  Px $b ($ox + 8) 15 $m3; Px $b ($ox + 26) 15 $m3
}

# ---- キーボード 28x12
Sheet 'concert_keys.png' 28 12 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 28 12 $m0
  Rect $b ($ox + 1) 1 26 3 $m1; Rect $b ($ox + 1) 1 26 1 $m2
  $i = 0
  foreach ($kx in 3, 7, 11, 15, 19) { Rect $b ($ox + $kx) 2 2 2 $neon[$i % 6]; $i++ }
  Rect $b ($ox + 22) 2 4 2 (C '#0a3a44'); Px $b ($ox + 23) 2 $neon[4]; Px $b ($ox + 25) 3 $neon[4]
  Rect $b ($ox + 1) 4 26 6 $m5
  for ($x = 1; $x -lt 27; $x += 2) { Rect $b ($ox + $x + 1) 4 1 6 $m4 }
  for ($k = 0; $k -lt 12; $k++) { if ($k % 7 -ne 2 -and $k % 7 -ne 6) { Rect $b ($ox + 2 + $k * 2) 4 2 4 $n0 } }
  Rect $b ($ox + 1) 10 26 1 $m2
}

# ---- マイクスタンド 8x22
Sheet 'concert_mic.png' 8 22 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 4) 20 3.5 1.4 $m0; Ellipse $b ($ox + 4) 19.6 3 1 $m2
  Rect $b ($ox + 3) 7 2 13 $m2; Rect $b ($ox + 3) 7 1 13 $m4
  Rect $b ($ox + 3) 5 2 3 $m0
  Ellipse $b ($ox + 4) 3 2.8 3 $m4; Ellipse $b ($ox + 4) 3 2.2 2.4 $m3
  Px $b ($ox + 3) 2 $m5; Rect $b ($ox + 3) 5 2 1 $neon[3]
}

# ---- エレキギター / ベース（体の前に持たせる）16x14
Sheet 'concert_guitar.png' 16 14 1 {
  param($b, $ox, $f)
  Line $b ($ox + 9) 7 ($ox + 15) 1 (C '#7a4a2a'); Line $b ($ox + 9) 8 ($ox + 15) 2 (C '#c97f4f')
  Rect $b ($ox + 14) 0 2 2 $m1
  Ellipse $b ($ox + 5) 9.5 5.2 4.4 (C '#4a0d1a'); Ellipse $b ($ox + 5) 9.5 4.4 3.7 $neon[0]
  Ellipse $b ($ox + 8) 7 2.6 2.2 $neon[0]
  Rect $b ($ox + 3) 9 4 2 $wht; Px $b ($ox + 3) 8 $m4; Px $b ($ox + 4) 12 (C '#ffb0b8')
}
Sheet 'concert_bass.png' 16 14 1 {
  param($b, $ox, $f)
  Line $b ($ox + 8) 8 ($ox + 15) 0 (C '#7a4a2a'); Line $b ($ox + 9) 8 ($ox + 15) 1 (C '#c97f4f')
  Rect $b ($ox + 14) 0 2 2 $m1
  Ellipse $b ($ox + 5) 9.5 5.2 4.4 (C '#0b3a5a'); Ellipse $b ($ox + 5) 9.5 4.4 3.7 $neon[4]
  Ellipse $b ($ox + 8) 7 2.6 2.2 $neon[4]
  Rect $b ($ox + 3) 9 4 2 (C '#103048'); Px $b ($ox + 3) 8 $m5
}

# ---- アンプ（ギター用・ベース用）
function Amp($name, $w, $h, $headH, $acc) {
  Sheet $name $w $h 1 {
    param($b, $ox, $f)
    Rect $b $ox 0 $w $h $m0
    Rect $b ($ox + 1) 1 ($w - 2) ($headH - 1) $m1; Rect $b ($ox + 1) 1 ($w - 2) 1 $m2
    for ($k = 0; $k -lt 5; $k++) { Px $b ($ox + 3 + $k * 2) 3 $m5 }
    Px $b ($ox + $w - 4) 3 $acc; Px $b ($ox + $w - 4) 4 (Mix $acc $n0 0.5)
    Rect $b ($ox + 1) ($headH + 1) ($w - 2) ($h - $headH - 2) (C '#2a2a38')
    for ($y = $headH + 1; $y -lt $h - 1; $y += 2) { for ($x = 1 + (($y / 2) % 2); $x -lt $w - 1; $x += 2) { Px $b ($ox + $x) $y $m2 } }
    $cy = ($headH + $h - 1) / 2.0
    Ellipse $b ($ox + $w / 2.0) $cy (($h - $headH) / 2.0 - 2) (($h - $headH) / 2.0 - 2) $m0
    Ellipse $b ($ox + $w / 2.0) $cy (($h - $headH) / 2.0 - 3) (($h - $headH) / 2.0 - 3) $m1
    Rect $b ($ox + 1) ($headH) ($w - 2) 1 $acc
    Rect $b $ox ($h - 1) $w 1 $m0
  }
}
Amp 'concert_amp.png' 18 20 6 $neon[0]
Amp 'concert_bassamp.png' 20 26 7 $neon[4]

# ---- ステージモニター（足元のスピーカー）16x8
Sheet 'concert_monitor.png' 16 8 1 {
  param($b, $ox, $f)
  for ($y = 0; $y -lt 8; $y++) { $in = [int](6 - $y * 0.75); Rect $b ($ox + 1 + $in / 2) $y (14 - $in) 1 $m1 }
  Rect $b ($ox + 1) 7 14 1 $m0
  Rect $b ($ox + 3) 2 10 3 $m0; for ($x = 4; $x -lt 13; $x += 2) { Px $b ($ox + $x) 3 $m3 }
  Px $b ($ox + 2) 6 $neon[2]; Px $b ($ox + 13) 6 $neon[2]
}

# ---- 足元のPARライト 12x12。色が回る 6コマ
Sheet 'concert_par.png' 12 12 6 {
  param($b, $ox, $f)
  $col = $neon[$f % 6]
  Ellipse $b ($ox + 6) 6 6 6 (Mix $col $n0 0.6)
  Ellipse $b ($ox + 6) 6 4.8 4.8 (Mix $col $n0 0.3)
  Ellipse $b ($ox + 6) 7.5 3.6 3 $m0
  Ellipse $b ($ox + 6) 7 3 2.4 $col
  Px $b ($ox + 5) 6 $wht; Px $b ($ox + 6) 6 $wht
  Rect $b ($ox + 3) 10 6 2 $m1
}

# ---- 客席のフェンス（柵）52x12
Sheet 'concert_barrier.png' 52 12 1 {
  param($b, $ox, $f)
  Rect $b $ox 2 52 1 $m5; Rect $b $ox 3 52 1 $m3
  Rect $b $ox 8 52 1 $m4; Rect $b $ox 9 52 1 $m2
  for ($x = 2; $x -lt 52; $x += 4) { Rect $b ($ox + $x) 4 1 4 $m3 }
  foreach ($x in 0, 48) { Rect $b ($ox + $x) 1 3 11 $m2; Rect $b ($ox + $x) 1 1 11 $m4; Rect $b ($ox + $x) 10 4 2 $m0 }
  Rect $b ($ox + 14) 10 4 2 $m0; Rect $b ($ox + 34) 10 4 2 $m0
  Rect $b ($ox + 15) 2 2 8 $m3; Rect $b ($ox + 35) 2 2 8 $m3
  Rect $b ($ox + 4) 5 8 2 $neon[3]; Rect $b ($ox + 38) 5 8 2 $neon[4]
}

# ---- 客席の床（赤いじゅうたんの通路つき）150x42
Sheet 'concert_floor.png' 150 42 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 150 42 (C '#161038')
  for ($y = 0; $y -lt 42; $y += 10) { Rect $b $ox $y 150 1 (C '#201850') }
  for ($x = 0; $x -lt 150; $x += 10) { Rect $b ($ox + $x) 0 1 42 (C '#201850') }
  for ($y = 5; $y -lt 42; $y += 10) { for ($x = 5; $x -lt 150; $x += 10) { if ((($x / 10) + ($y / 10)) % 3 -eq 0) { Px $b ($ox + $x) $y $n4 } } }
  Rect $b ($ox + 59) 0 32 42 (C '#7a1230')
  Rect $b ($ox + 59) 0 2 42 $gold2; Rect $b ($ox + 89) 0 2 42 $gold2
  for ($y = 3; $y -lt 42; $y += 8) { Px $b ($ox + 74) $y $gold2; Px $b ($ox + 73) ($y + 1) $gold2; Px $b ($ox + 75) ($y + 1) $gold2; Px $b ($ox + 74) ($y + 2) $gold2 }
  Rect $b ($ox + 61) 0 1 42 (C '#a01a40'); Rect $b ($ox + 88) 0 1 42 (C '#561020')
  Rect $b $ox 41 150 1 $n0
  foreach ($p in @(@(0, 0), @(149, 0), @(0, 41), @(149, 41))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ---- ペンライト 10x20（5色 × 4コマ。ゆれる）
$penCols = @(@('r', 0), @('g', 1), @('b', 2), @('m', 3), @('c', 4))
foreach ($pc in $penCols) {
  $col = $neon[$pc[1]]
  Sheet "concert_pen_$($pc[0]).png" 10 20 4 {
    param($b, $ox, $f)
    $off = @(0, 2, 0, -2)[$f]
    for ($y = 19; $y -ge 3; $y--) {
      $t = (19 - $y) / 16.0
      $cx = [int][math]::Round(5 + $off * $t)
      if ($t -lt 0.3) { Rect $b ($ox + $cx - 1) $y 2 1 (C '#c8c8e0') }
      else { Px $b ($ox + $cx - 1) $y (Mix $col $n0 0.35); Px $b ($ox + $cx) $y (Mix $col $wht 0.45); Px $b ($ox + $cx + 1) $y $col }
    }
    $tx = [int][math]::Round(5 + $off)
    Rect $b ($ox + $tx - 1) 2 3 2 $wht
    Px $b ($ox + $tx - 2) 3 (Mix $col $n0 0.3); Px $b ($ox + $tx + 2) 3 (Mix $col $n0 0.3); Px $b ($ox + $tx) 1 (Mix $col $n0 0.3)
  }
}

# ---- うちわ（ハート）14x22 2コマ
Sheet 'concert_uchiwa.png' 14 22 2 {
  param($b, $ox, $f)
  $sx = @(0, 1)[$f]
  Rect $b ($ox + 6 + $sx) 12 2 10 (C '#c97f4f'); Rect $b ($ox + 6 + $sx) 12 1 10 (C '#eab382')
  Ellipse $b ($ox + 7 + $sx) 6 6.4 6.2 (C '#7a0a5a')
  Ellipse $b ($ox + 7 + $sx) 6 5.6 5.4 $neon[3]
  Ascii $b ($ox + 3 + $sx) 3 @('.xx.xx.', 'xxxxxxx', 'xxxxxxx', '.xxxxx.', '..xxx..', '...x...') @{ x = $wht }
}

# ---- PA卓（ミキサー・ノートPC・VUメーターが動く）44x22 4コマ
Sheet 'concert_foh.png' 44 22 4 {
  param($b, $ox, $f)
  Rect $b ($ox + 3) 0 18 9 $m0; Rect $b ($ox + 4) 1 16 6 (C '#06222a')
  for ($x = 0; $x -lt 7; $x++) { $h = 1 + (($x * 3 + $f * 2) % 5); Rect $b ($ox + 5 + $x * 2) (6 - $h) 1 $h $neon[4] }
  Rect $b ($ox + 2) 8 20 2 $m2
  Rect $b $ox 10 44 8 $m0
  Rect $b ($ox + 1) 11 42 6 $m2; Rect $b ($ox + 1) 11 42 1 $m4
  for ($i = 0; $i -lt 10; $i++) {
    $x = 3 + $i * 3
    Rect $b ($ox + $x) 12 1 4 $m0
    Rect $b ($ox + $x - 1) (13 + ($i * 7 + $f) % 3) 3 1 $neon[$i % 5]
  }
  for ($i = 0; $i -lt 3; $i++) {
    $h = 1 + (($i * 2 + $f * 3) % 5)
    Rect $b ($ox + 34 + $i * 3) (16 - $h) 2 $h $(if ($h -ge 4) { $neon[0] } elseif ($h -ge 3) { $neon[5] } else { $neon[1] })
  }
  Rect $b ($ox + 1) 18 42 3 $m1; Rect $b ($ox + 3) 21 3 1 $m0; Rect $b ($ox + 38) 21 3 1 $m0
  Rect $b ($ox + 24) 2 3 3 (C '#c8c8dc'); Px $b ($ox + 25) 3 $neon[2]
}

# ---- 受付カウンター 44x24（「受付」の札、チケット）
Sheet 'concert_booth.png' 44 24 1 {
  param($b, $ox, $f)
  Rect $b $ox 6 44 18 $n0
  Rect $b ($ox + 1) 7 42 5 (C '#6a58b8'); Rect $b ($ox + 1) 7 42 1 (C '#9a88ee')
  Rect $b ($ox + 1) 12 42 11 $n2
  Rect $b ($ox + 1) 12 42 1 $n0
  Rect $b ($ox + 1) 13 42 1 $neon[3]
  Rect $b ($ox + 6) 15 22 8 $n0; Frame $b ($ox + 6) 15 22 8 $neon[4]
  [void](TextPx $b '受付' ($ox + 8) 15 10 $wht $false)
  Rect $b ($ox + 32) 16 8 4 (C '#7a1230'); Px $b ($ox + 34) 17 $gold2; Px $b ($ox + 37) 18 $gold2
  foreach ($p in @(@(5, 2, 0), @(9, 3, 5), @(33, 1, 1), @(37, 2, 4))) { Rect $b ($ox + $p[0]) $p[1] 5 4 $neon[$p[2]]; Rect $b ($ox + $p[0]) $p[1] 5 1 $wht }
  Clear $b $ox 6; Clear $b ($ox + 43) 6
  Rect $b ($ox + 3) 22 4 2 $m0; Rect $b ($ox + 37) 22 4 2 $m0
}

# ---- 入場ゲートの柱 12x36（ランプが色変わり）4コマ
Sheet 'concert_gate.png' 12 36 4 {
  param($b, $ox, $f)
  $col = $neon[($f * 2 + 1) % 6]
  Rect $b $ox 5 12 31 $n0
  Rect $b ($ox + 1) 6 10 29 $n2; Rect $b ($ox + 1) 6 1 29 $n3; Rect $b ($ox + 10) 6 1 29 $n0
  Ellipse $b ($ox + 6) 3.5 4.2 3.6 (Mix $col $n0 0.7)
  Ellipse $b ($ox + 6) 3.5 3.2 2.8 $col
  Px $b ($ox + 5) 2 $wht
  [void](TextPx $b '入' ($ox + 1) 8 10 $wht $false)
  [void](TextPx $b '場' ($ox + 1) 18 10 $wht $false)
  for ($y = 29; $y -lt 35; $y++) { for ($x = 1; $x -lt 11; $x++) { if (((($x + $y) / 3) -as [int]) % 2 -eq 0) { Px $b ($ox + $x) $y $neon[5] } else { Px $b ($ox + $x) $y $n0 } } }
  Clear $b $ox 5; Clear $b ($ox + 11) 5
}

# ---- のぼり旗「ライブ」16x46
Sheet 'concert_nobori.png' 16 46 1 {
  param($b, $ox, $f)
  Rect $b $ox 2 16 2 $m2; Rect $b $ox 2 2 44 $m3; Rect $b $ox 2 1 44 $m4
  Rect $b ($ox + 2) 4 13 38 $n2; Rect $b ($ox + 2) 4 13 1 $neon[3]; Rect $b ($ox + 2) 4 1 38 $neon[3]; Rect $b ($ox + 14) 4 1 38 $neon[4]
  for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Rect $b ($ox + 2 + $i) 42 1 2 $n2 } }
  $chars = 'ラ', 'イ', 'ブ'
  for ($i = 0; $i -lt 3; $i++) { [void](TextPx $b $chars[$i] ($ox + 3) (6 + 11 * $i) 11 $wht $false) }
}

# ---- 浮かぶ音符 24x30 4コマ（ゆっくり上へ）
$noteRows = @('....XX.', '....X.X', '....X..', '....X..', '....X..', '..XXX..', '.XXXX..', '..XX...')
Sheet 'concert_notes.png' 24 30 4 {
  param($b, $ox, $f)
  Ascii $b ($ox + 3) (20 - $f * 5) $noteRows @{ X = $neon[($f * 2 + 3) % 6] }
  Ascii $b ($ox + 14) (21 - $f * 5 - ($f % 2) * 2) $noteRows @{ X = $neon[($f * 2 + 4) % 6] }
}
