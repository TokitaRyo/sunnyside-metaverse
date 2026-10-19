# DTM部（パソコンで音楽を作る部活）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/dtm.ps1
#   一部だけ作り直す: $env:DTM_ONLY='sign|mixer'  （ファイル名の正規表現）
# 出力: client/public/brand/stall/dtm_*.png （配置は scripts/stalls/dtm.mjs）
# 配色は「夜のスタジオ」: 濃い紫のカーペットと吸音フォームの壁に、ピンク・シアン・黄色のネオン。
# アニメは「フレームを横一列に並べたPNG」を k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function Al($c0, $a) { [System.Drawing.Color]::FromArgb([int]$a, $c0.R, $c0.G, $c0.B) }
# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  if ($env:DTM_ONLY -and ($name -notmatch $env:DTM_ONLY)) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}
# 決まった「でたらめ」（毎回同じ値）
function Hs($n) { return ((([int]$n * 73 + 19) * 31 + [int]$n * [int]$n * 7) % 97) }

# ---- 色
$k0 = C '#07050f'
$p0 = C '#0b0814'; $p1 = C '#150f26'; $p2 = C '#211a3d'; $p3 = C '#322a58'; $p4 = C '#4a3f7e'; $p5 = C '#6a5cb0'
$s0 = C '#1c1a2a'; $s1 = C '#2e2b44'; $s2 = C '#4d4966'; $s3 = C '#8c88ae'; $s4 = C '#cbc8e6'
$wd0 = C '#3a2216'; $wd1 = C '#6b4226'; $wd2 = C '#8f5c36'; $wd3 = C '#b9814e'
$mg = C '#ff3fb4'; $cy = C '#3df5ff'; $yl = C '#ffd447'; $gr = C '#5dff9a'; $og = C '#ff8a3d'; $vi = C '#9a6bff'; $rd = C '#ff4a5e'
$wht = C '#fbf8ff'
$scr = C '#0d0b1f'
$nl = @($mg, $cy, $yl, $vi, $gr, $og)

# ---- 3x5 の小さな文字（大文字だけ）
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
  '!' = @('.X.', '.X.', '.X.', '...', '.X.'); '-' = @('...', '...', 'XXX', '...', '...'); '>' = @('X..', '.X.', '..X', '.X.', 'X..')
}
# 小さな文字を貼る。幅(px)を返す（1文字 = 3px + 1px のすき間）
function T3($b, $text, $x, $y, $col) {
  $cx = $x
  foreach ($ch in $text.ToUpper().ToCharArray()) {
    $kk = [string]$ch
    if ($f3.ContainsKey($kk)) {
      $g = $f3[$kk]
      for ($r = 0; $r -lt 5; $r++) { for ($c = 0; $c -lt 3; $c++) { if ($g[$r].Substring($c, 1) -eq 'X') { Px $b ($cx + $c) ($y + $r) $col } } }
    }
    $cx += 4
  }
  return ($cx - $x - 1)
}
# 小さな文字を $sc 倍にして貼る
function BigT3($b, $text, $x, $y, $sc, $col) {
  $cx = $x
  foreach ($ch in $text.ToUpper().ToCharArray()) {
    $kk = [string]$ch
    if ($f3.ContainsKey($kk)) {
      $g = $f3[$kk]
      for ($r = 0; $r -lt 5; $r++) { for ($c = 0; $c -lt 3; $c++) { if ($g[$r].Substring($c, 1) -eq 'X') { Rect $b ($cx + $c * $sc) ($y + $r * $sc) $sc $sc $col } } }
    }
    $cx += 4 * $sc
  }
  return ($cx - $x - $sc)
}

# ---- 音符の形（X が塗る所）
$noteEighth = @('...X..', '...XX.', '...X.X', '...X..', '...X..', '.XXX..', 'XXXX..', '.XX...')
$noteBeam = @('...XXXXX', '...XXXXX', '...X...X', '...X...X', '.XXX.XXX', 'XXXXXXXX', '.XX..XX.')

# ---- モニターの枠（外側 w×h、スタンドは別に描く）
function Bezel($b, $x, $y, $w, $h) {
  Rect $b $x $y $w $h $k0
  Rect $b ($x + 1) ($y + 1) ($w - 2) ($h - 2) $s1
  Rect $b ($x + 1) ($y + 1) ($w - 2) 1 $s2
  Rect $b ($x + 1) ($y + $h - 2) ($w - 2) 1 $s0
  Rect $b ($x + 2) ($y + 2) ($w - 4) ($h - 5) $k0
}
function Stand($b, $cx, $y) {
  Rect $b ($cx - 2) $y 4 3 $s1; Rect $b ($cx - 2) $y 1 3 $s2
  Rect $b ($cx - 6) ($y + 3) 12 2 $s1; Rect $b ($cx - 6) ($y + 3) 12 1 $s2; Rect $b ($cx - 6) ($y + 5) 12 1 $k0
}
# 吸音フォームのとげとげ（左上から光が当たる）。w×h の範囲に 5px ごとのピラミッドを並べる
function Foam($b, $x, $y, $w, $h, $tone) {
  if ($tone -eq 1) { $ft = C '#3a8a99'; $fl = C '#2a6676'; $fr = C '#1f4d5c'; $fb = C '#153844' }
  else { $ft = C '#4a4258'; $fl = C '#352f44'; $fr = C '#2a2536'; $fb = C '#1f1b2a' }
  for ($j = 0; $j -lt $h; $j++) {
    for ($i = 0; $i -lt $w; $i++) {
      $u = $i % 5; $v = $j % 5
      $m = [math]::Min($u, 4 - $u)
      if ($v -le $m) { $col = $ft } elseif ((4 - $v) -le $m) { $col = $fb } elseif ($u -lt 2) { $col = $fl } else { $col = $fr }
      Px $b ($x + $i) ($y + $j) $col
    }
  }
}

# ---- 床 192x128（濃い紫のカーペット）
Sheet 'dtm_floor.png' 192 128 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 192 128 $p1
  for ($y = 0; $y -lt 128; $y += 16) { for ($x = 0; $x -lt 192; $x += 16) { if ((($x + $y) / 16) % 2 -eq 0) { Rect $b ($ox + $x) $y 16 16 (C '#181029') } } }
  for ($i = 0; $i -lt 700; $i++) {
    $x = ((Hs ($i * 3 + 1)) * 2 + (Hs ($i + 7)) % 2) % 192
    $y = ((Hs ($i * 5 + 2)) + (Hs ($i * 7 + 3)) % 32) % 128
    if ($i % 3 -eq 0) { Px $b ($ox + $x) $y $p3 } else { Px $b ($ox + $x) $y $p0 }
  }
  Frame $b $ox 0 192 128 $p2
}

# ---- 奥の壁 184x40（吸音フォームのパネルが並ぶ。下にLEDの線）
Sheet 'dtm_wall.png' 184 40 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 184 40 $p0
  for ($i = 0; $i -lt 8; $i++) {
    $px0 = $i * 23
    $tone = if ($i % 3 -eq 1) { 1 } else { 0 }
    Foam $b ($ox + $px0 + 1) 3 22 30 $tone
    Rect $b ($ox + $px0) 3 1 30 $k0
    Rect $b ($ox + $px0 + 22) 3 1 30 $k0
  }
  Rect $b $ox 0 184 3 $p3; Rect $b $ox 0 184 1 $p4; Rect $b $ox 2 184 1 $k0
  Rect $b $ox 33 184 6 $s1; Rect $b $ox 33 184 1 $s3; Rect $b $ox 38 184 1 $k0
  for ($x = 0; $x -lt 184; $x++) { if (($x % 8) -lt 5) { Px $b ($ox + $x) 35 (Mix $mg $s1 (0.25 + 0.3 * [math]::Abs([math]::Sin($x / 20.0)))) } }
  Clear $b $ox 0; Clear $b ($ox + 183) 0
}

# ---- 看板 104x28（DTM部。ネオンが点滅し、枠が流れる。音の棒グラフが踊る）6コマ
Sheet 'dtm_sign.png' 104 28 6 {
  param($b, $ox, $f)
  Rect $b $ox 1 104 26 $k0
  Rect $b ($ox + 2) 2 100 24 $p1
  for ($x = 2; $x -lt 102; $x++) {
    $c1 = $nl[([int][math]::Floor($x / 8) + $f) % 6]; $c2 = $nl[([int][math]::Floor($x / 8) + $f + 3) % 6]
    Px $b ($ox + $x) 1 $c1; Px $b ($ox + $x) 26 $c2
    Px $b ($ox + $x) 2 (Mix $c1 $p1 0.65); Px $b ($ox + $x) 25 (Mix $c2 $p1 0.65)
  }
  for ($y = 1; $y -lt 27; $y++) {
    Px $b ($ox + 1) $y $nl[([int][math]::Floor($y / 8) + $f + 2) % 6]; Px $b ($ox + 102) $y $nl[([int][math]::Floor($y / 8) + $f + 5) % 6]
  }
  # 音符のアイコン
  Ascii $b ($ox + 7) 7 $noteBeam @{ X = $nl[($f + 1) % 6] }
  # DTM（フレームによって一文字ずつ暗くなる＝ネオンのちらつき）
  $dimD = ($f -eq 2); $dimT = ($f -eq 5); $dimM = ($f -eq 4)
  $cD = if ($dimD) { Mix $mg $p1 0.75 } else { $mg }
  $cT = if ($dimT) { Mix $cy $p1 0.75 } else { $cy }
  $cM = if ($dimM) { Mix $yl $p1 0.75 } else { $yl }
  [void](BigT3 $b 'D' ($ox + 20) 5 3 $k0); [void](BigT3 $b 'T' ($ox + 32) 5 3 $k0); [void](BigT3 $b 'M' ($ox + 44) 5 3 $k0)
  [void](BigT3 $b 'D' ($ox + 19) 4 3 $cD); [void](BigT3 $b 'T' ($ox + 31) 4 3 $cT); [void](BigT3 $b 'M' ($ox + 43) 4 3 $cM)
  [void](TextPx $b '部' ($ox + 58) 4 16 $k0 $true)
  [void](TextPx $b '部' ($ox + 57) 3 16 $wht $true)
  [void](T3 $b 'MAKE MUSIC!' ($ox + 19) 20 (Mix $cy $wht 0.3))
  # 棒グラフ
  for ($i = 0; $i -lt 6; $i++) {
    $h = 3 + (Hs ($i * 9 + $f * 7)) % 12
    Rect $b ($ox + 78 + $i * 4) (23 - $h) 3 $h $nl[($i + $f) % 6]
    Px $b ($ox + 78 + $i * 4) (23 - $h) $wht
  }
  foreach ($p in @(@(0, 0), @(103, 0), @(0, 27), @(103, 27))) { Clear $b ($ox + $p[0]) $p[1] }
  Clear $b ($ox + 1) 1; Clear $b ($ox + 102) 1; Clear $b ($ox + 1) 26; Clear $b ($ox + 102) 26
}

# ---- 壁のネオン: イコライザー 32x24 8コマ
Sheet 'dtm_neon_eq.png' 32 24 8 {
  param($b, $ox, $f)
  Rect $b $ox 0 32 24 $k0
  Rect $b ($ox + 1) 1 30 22 $p1
  Frame $b ($ox + 1) 1 30 22 $p4
  $segc = @($cy, $cy, $vi, $vi, $mg, $mg)
  for ($i = 0; $i -lt 7; $i++) {
    $lv = 1 + [int][math]::Round(2.5 + 2.5 * [math]::Sin($f * 0.9 + $i * 1.3 + (Hs $i) * 0.1))
    for ($s = 0; $s -lt 6; $s++) {
      $yy = 19 - $s * 3
      if ($s -lt $lv) { Rect $b ($ox + 3 + $i * 4) $yy 3 2 $segc[$s] } else { Rect $b ($ox + 3 + $i * 4) $yy 3 2 (Mix $segc[$s] $p1 0.85) }
    }
  }
  Clear $b $ox 0; Clear $b ($ox + 31) 0; Clear $b $ox 23; Clear $b ($ox + 31) 23
}

# ---- 壁のネオン: 音符のネオン管 20x26 4コマ（ふわっと点滅）
function NoteTube($b, $ox, $col) {
  Line $b ($ox + 6) 5 ($ox + 6) 18 $col; Line $b ($ox + 15) 3 ($ox + 15) 16 $col
  Line $b ($ox + 6) 5 ($ox + 15) 3 $col; Line $b ($ox + 6) 6 ($ox + 15) 4 $col
  Ellipse $b ($ox + 4) 19 3.5 2.5 $col; Ellipse $b ($ox + 13) 17 3.5 2.5 $col
}
Sheet 'dtm_neon_note.png' 20 26 4 {
  param($b, $ox, $f)
  $lv = @(1.0, 1.0, 0.35, 0.8)[$f]
  $glow = Mix $mg $k0 (0.65 + 0.3 * $lv)
  $core = Mix $mg $wht (0.25 * $lv)
  foreach ($o in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1))) { NoteTube $b ($ox + $o[0]) (Mix $glow $k0 0.45) }
  NoteTube $b $ox (Mix $core $k0 (1 - $lv))
  Px $b ($ox + 16) 6 (Mix $cy $k0 (1 - $lv)); Px $b ($ox + 3) 8 (Mix $cy $k0 (1 - $lv))
  foreach ($p in @(@(0, 0), @(19, 0), @(0, 25), @(19, 25))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ---- ポスター 20x28 ×2
Sheet 'dtm_poster_wave.png' 20 28 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 20 28 $k0
  Frame $b ($ox + 1) 1 18 26 $mg
  for ($y = 2; $y -lt 26; $y++) { Rect $b ($ox + 2) $y 16 1 (Mix (C '#2a0f60') (C '#ff6a9a') ($y / 25.0)) }
  Ellipse $b ($ox + 10) 11 5 5 $yl
  for ($y = 12; $y -lt 16; $y += 2) { Rect $b ($ox + 4) $y 12 1 (Mix (C '#8a1a8a') (C '#ff6a9a') (($y - 2) / 25.0)) }
  Rect $b ($ox + 2) 18 16 7 (C '#120a2a')
  for ($x = 0; $x -lt 16; $x++) { $h = 1 + [int](2.5 * [math]::Abs([math]::Sin($x / 1.7))); Rect $b ($ox + 2 + $x) (21 - $h) 1 ($h * 2) $cy }
  [void](T3 $b 'BEAT' ($ox + 3) 3 $wht)
  Clear $b $ox 0; Clear $b ($ox + 19) 0
}
Sheet 'dtm_poster_disc.png' 20 28 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 20 28 $k0
  Frame $b ($ox + 1) 1 18 26 $cy
  Rect $b ($ox + 2) 2 16 24 (C '#14102e')
  Ellipse $b ($ox + 10) 11 7.5 7.5 $k0
  Ellipse $b ($ox + 10) 11 6 6 (C '#262046')
  Ellipse $b ($ox + 10) 11 4.5 4.5 (C '#14102e')
  Ellipse $b ($ox + 10) 11 3 3 $mg
  Px $b ($ox + 10) 11 $k0
  Px $b ($ox + 6) 6 (C '#4a4278'); Px $b ($ox + 7) 5 (C '#4a4278')
  Rect $b ($ox + 3) 21 14 1 $p4
  [void](T3 $b 'MIX' ($ox + 5) 22 $yl)
  Clear $b $ox 0; Clear $b ($ox + 19) 0
}

# ---- モニター A: DAW（トラックの波形が並び、再生ヘッドが進む）36x32 8コマ
Sheet 'dtm_mon_daw.png' 36 32 8 {
  param($b, $ox, $f)
  Bezel $b $ox 0 36 26
  Rect $b ($ox + 2) 2 32 21 $scr
  Rect $b ($ox + 2) 2 32 3 $p3
  Rect $b ($ox + 4) 3 1 1 $gr; Rect $b ($ox + 5) 3 1 1 $gr
  Rect $b ($ox + 8) 3 2 1 $s3
  if ($f % 2 -eq 0) { Rect $b ($ox + 12) 3 2 1 $rd } else { Rect $b ($ox + 12) 3 2 1 (Mix $rd $p3 0.7) }
  for ($x = 6; $x -lt 34; $x += 4) { Px $b ($ox + $x) 4 $p5 }
  $cols = @($mg, $cy, $yl)
  $clips = @(@(@(6, 15), @(18, 33)), @(@(9, 22), @(25, 33)), @(@(6, 11), @(14, 27), @(29, 33)))
  for ($t = 0; $t -lt 3; $t++) {
    $ty = 6 + $t * 5; $col = $cols[$t]
    Rect $b ($ox + 3) $ty 2 4 $col
    foreach ($cl in $clips[$t]) {
      Rect $b ($ox + $cl[0]) $ty ($cl[1] - $cl[0] + 1) 4 (Mix $col $scr 0.75)
      for ($x = $cl[0]; $x -le $cl[1]; $x++) {
        $h = 1 + (Hs ($x * 3 + $t * 17)) % 3
        Rect $b ($ox + $x) ($ty + 2 - [int][math]::Floor($h / 2)) 1 $h $col
      }
    }
  }
  $phx = 6 + [int]($f * 3.5)
  Rect $b ($ox + $phx) 5 1 17 $wht
  Px $b ($ox + $phx - 1) 5 $wht; Px $b ($ox + $phx + 1) 5 $wht
  $len = 8 + (Hs ($f * 5 + 1)) % 16
  for ($x = 0; $x -lt $len; $x++) { $mc = if ($x -lt 14) { $gr } elseif ($x -lt 19) { $yl } else { $rd }; Px $b ($ox + 4 + $x) 22 $mc }
  Stand $b ($ox + 18) 26
}

# ---- モニター B: ピアノロール（音のブロックが流れてくる）24x28 8コマ
Sheet 'dtm_mon_roll.png' 24 28 8 {
  param($b, $ox, $f)
  Bezel $b $ox 0 24 22
  Rect $b ($ox + 2) 2 20 17 $scr
  for ($r = 0; $r -lt 8; $r++) {
    $blk = @(0, 1, 0, 1, 0, 0, 1, 0)[$r]
    $kc = if ($blk -eq 1) { $s1 } else { $s4 }
    Rect $b ($ox + 2) (2 + $r * 2) 3 2 $kc
    Rect $b ($ox + 5) (2 + $r * 2) 17 1 $p2
  }
  for ($x = 9; $x -lt 22; $x += 4) { Rect $b ($ox + $x) 2 1 16 $p2 }
  $cols = @($mg, $cy, $yl)
  $notes = @(@(0, 2, 5, 0), @(6, 5, 3, 1), @(10, 1, 6, 2), @(18, 6, 4, 0), @(23, 3, 5, 1), @(30, 0, 3, 2))
  foreach ($n in $notes) {
    $nx = (($n[0] - $f * 4) % 36 + 36) % 36
    foreach ($rep in 0, -36) {
      $x0 = $nx + $rep; $x1 = $x0 + $n[2]
      $a0 = [math]::Max(0, $x0); $a1 = [math]::Min(17, $x1)
      if ($a1 -gt $a0) {
        $col = if ($x0 -le 6 -and $x1 -gt 6) { $wht } else { $cols[$n[3]] }
        Rect $b ($ox + 5 + $a0) (2 + $n[1] * 2) ($a1 - $a0) 2 $col
        Rect $b ($ox + 5 + $a0) (3 + $n[1] * 2) ($a1 - $a0) 1 (Mix $col $k0 0.3)
      }
    }
  }
  Rect $b ($ox + 11) 2 1 17 $wht
  Stand $b ($ox + 12) 22
}

# ---- ノートパソコン 22x13（画面にスペクトラム、8コマ）
Sheet 'dtm_laptop.png' 22 13 8 {
  param($b, $ox, $f)
  Rect $b ($ox + 2) 0 18 9 $k0
  Rect $b ($ox + 3) 1 16 7 $s1
  Rect $b ($ox + 4) 2 14 5 $scr
  for ($i = 0; $i -lt 7; $i++) {
    $h = 1 + (Hs ($i * 5 + $f * 3)) % 5
    Rect $b ($ox + 4 + $i * 2) (7 - $h) 1 $h $nl[($i) % 3 + ($i % 2) * 1]
    Px $b ($ox + 5 + $i * 2) (7 - $h) (Mix $nl[($i) % 3] $scr 0.6)
  }
  Px $b ($ox + 10) 8 $s3
  Rect $b $ox 9 22 3 $s2; Rect $b $ox 9 22 1 $s4; Rect $b $ox 11 22 1 $k0
  Rect $b ($ox + 3) 10 16 1 $k0
  for ($x = 4; $x -lt 18; $x += 2) { Px $b ($ox + $x) 10 $s3 }
  Rect $b ($ox + 9) 11 4 1 $s3
  Clear $b $ox 12; Clear $b ($ox + 21) 12
}

# ---- MIDIキーボード 44x10（鍵盤が押されて光る。左にパッドとつまみ）6コマ
Sheet 'dtm_kbd_midi.png' 44 10 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 44 10 $k0
  Rect $b ($ox + 1) 1 42 8 (C '#2a2542')
  Rect $b ($ox + 1) 1 42 1 $s2
  foreach ($kx in 3, 6, 9, 12) { Rect $b ($ox + $kx) 2 2 1 $s3 }
  Px $b ($ox + 3) 2 $cy; Px $b ($ox + 9) 2 $yl
  for ($i = 0; $i -lt 4; $i++) {
    $lit = (($f + $i) % 3 -eq 0)
    $pc = $nl[($i + $f) % 6]
    if ($lit) { Rect $b ($ox + 3 + $i * 3) 5 2 3 $pc } else { Rect $b ($ox + 3 + $i * 3) 5 2 3 (Mix $pc (C '#2a2542') 0.75) }
  }
  Rect $b ($ox + 15) 2 28 1 $k0
  $pr = @(1, 4, 2, 6, 0, 5)[$f]; $pr2 = ($pr + 2) % 9
  for ($i = 0; $i -lt 9; $i++) {
    $wx = $ox + 15 + $i * 3
    $kc = $wht
    if ($i -eq $pr) { $kc = $mg } elseif ($i -eq $pr2 -and $f % 2 -eq 1) { $kc = $cy }
    Rect $b $wx 3 2 5 $kc
    Px $b $wx 8 (Mix $kc $s3 0.5); Px $b ($wx + 1) 8 (Mix $kc $s3 0.5)
    if ($kc -ne $wht) { Rect $b $wx 3 2 1 $wht }
  }
  foreach ($i in 0, 1, 3, 4, 5, 7) { Rect $b ($ox + 15 + ($i + 1) * 3 - 1) 3 2 3 $k0 }
  Clear $b $ox 0; Clear $b ($ox + 43) 0; Clear $b $ox 9; Clear $b ($ox + 43) 9
}

# ---- ミキサー 44x20（フェーダーが動き、LEDメーターが踊る）6コマ
Sheet 'dtm_mixer_strip.png' 44 20 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 44 20 $k0
  Rect $b ($ox + 2) 0 40 19 (C '#2a2542')
  Rect $b ($ox + 2) 0 40 1 $s3
  Rect $b $ox 1 2 18 $wd1; Rect $b $ox 1 1 18 $wd2; Rect $b ($ox + 42) 1 2 18 $wd1; Rect $b ($ox + 43) 1 1 18 $wd0
  for ($i = 0; $i -lt 7; $i++) {
    $x0 = $ox + 4 + $i * 5
    Rect $b $x0 2 2 2 (Mix $nl[$i % 6] $k0 0.1); Px $b $x0 2 $wht
    Rect $b $x0 5 2 1 $s3
    $lv = [int][math]::Round(3 + 3 * [math]::Sin($f * 1.1 + $i * 1.7))
    for ($s = 0; $s -lt 6; $s++) {
      $mc = if ($s -lt 3) { $gr } elseif ($s -lt 5) { $yl } else { $rd }
      $yy = 12 - $s
      if ($s -lt $lv) { Px $b ($x0 + 3) $yy $mc } else { Px $b ($x0 + 3) $yy (Mix $mc $k0 0.8) }
    }
    Rect $b ($x0 + 1) 13 1 5 $k0
    $pos = [int][math]::Round(2 + 2 * [math]::Sin($f * 0.9 + $i * 2.1))
    Rect $b $x0 (13 + $pos) 3 2 $s4; Rect $b $x0 (14 + $pos) 3 1 $s2
  }
  # マスター（太いメーター2本）
  for ($m = 0; $m -lt 2; $m++) {
    $lv = [int][math]::Round(5 + 4 * [math]::Sin($f * 1.3 + $m * 0.8))
    for ($s = 0; $s -lt 10; $s++) {
      $mc = if ($s -lt 6) { $gr } elseif ($s -lt 8) { $yl } else { $rd }
      $yy = 15 - $s
      if ($s -lt $lv) { Rect $b ($ox + 39 + $m * 2) $yy 1 1 $mc } else { Rect $b ($ox + 39 + $m * 2) $yy 1 1 (Mix $mc $k0 0.8) }
    }
  }
  Rect $b ($ox + 2) 19 40 1 $k0
  Clear $b $ox 0; Clear $b ($ox + 43) 0
}

# ---- ヘッドホン（机の上）12x8 と かぶっている用 12x6
Sheet 'dtm_headphones.png' 12 8 1 {
  param($b, $ox, $f)
  Ascii $b $ox 0 @('...ssssss...', '..s......s..', '.s........s.', '.s........s.', 'ccc......ccc', 'cmc......cmc', 'cmc......cmc', 'ccc......ccc') @{ s = $s3; c = $k0; m = $mg }
}
Sheet 'dtm_headphones_worn.png' 12 6 1 {
  param($b, $ox, $f)
  Ascii $b $ox 0 @('..kssssssk..', '.ks......sk.', 'ks........sk', 'ccc......ccc', 'cmc......cmc', 'ccc......ccc') @{ s = $s3; c = $k0; k = $k0; m = $mg }
}

# ---- スピーカー 12x24（ウーファーがドンドン動く）4コマ
Sheet 'dtm_speaker.png' 12 24 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 12 24 $k0
  Rect $b ($ox + 1) 1 10 22 (C '#231f35'); Rect $b ($ox + 1) 1 10 1 $s2; Rect $b ($ox + 1) 1 1 22 (C '#322d4c')
  Ellipse $b ($ox + 6) 6 2.3 2.3 $s1
  Ellipse $b ($ox + 6) 6 1.2 1.2 $s3
  $rw = @(3.8, 4.4, 5.0, 4.4)[$f]
  Ellipse $b ($ox + 6) 15 $rw $rw $s1
  Ellipse $b ($ox + 6) 15 ($rw - 1) ($rw - 1) $k0
  Ellipse $b ($ox + 6) 15 2 2 $s2
  Px $b ($ox + 6) 15 $s4
  if ($f -eq 2) { Px $b ($ox + 6) 21 $mg } else { Px $b ($ox + 6) 21 (Mix $gr $k0 0.3) }
  Clear $b $ox 0; Clear $b ($ox + 11) 0
}

# ---- マイクスタンドとポップガード 16x38
Sheet 'dtm_mic.png' 16 38 1 {
  param($b, $ox, $f)
  Line $b ($ox + 8) 31 ($ox + 2) 37 $s1; Line $b ($ox + 8) 31 ($ox + 14) 37 $s1; Line $b ($ox + 8) 31 ($ox + 8) 37 $s1
  Px $b ($ox + 2) 37 $k0; Px $b ($ox + 14) 37 $k0; Px $b ($ox + 8) 37 $k0
  Rect $b ($ox + 7) 17 2 15 $s2; Rect $b ($ox + 7) 17 1 15 $s3; Rect $b ($ox + 9) 17 1 15 $s0
  # マイク本体
  Ellipse $b ($ox + 8) 9 3 4.4 $k0
  Ellipse $b ($ox + 8) 9 2 3.4 (C '#3a3556')
  Rect $b ($ox + 7) 7 1 4 $s3
  # ポップガード（丸いあみ）
  Ellipse $b ($ox + 8) 9 6.6 6.6 (Al $s3 150)
  Ellipse $b ($ox + 8) 9 5.6 5.6 (Al $p3 100)
  for ($i = -5; $i -le 5; $i += 2) { Line $b ($ox + 8 + $i) 4 ($ox + 8 + $i) 14 (Al $s2 160) }
  for ($j = 5; $j -le 13; $j += 2) { Line $b ($ox + 3) $j ($ox + 13) $j (Al $s2 160) }
  Ellipse $b ($ox + 8) 9 0.6 0.6 (Al $s4 220)
  Px $b ($ox + 8) 16 $s4
  Rect $b ($ox + 6) 17 4 1 $k0
}

# ---- 防音シールド（3枚折りのフォーム）32x42
Sheet 'dtm_booth.png' 32 42 1 {
  param($b, $ox, $f)
  # 左右の羽根は少し低く、奥行きがあるように
  Rect $b ($ox + 0) 5 9 33 $k0; Foam $b ($ox + 1) 6 7 31 0
  Rect $b ($ox + 23) 5 9 33 $k0; Foam $b ($ox + 24) 6 7 31 0
  Rect $b ($ox + 8) 1 16 38 $k0; Foam $b ($ox + 9) 2 14 36 1
  Rect $b ($ox + 8) 1 16 1 $s2; Rect $b ($ox + 8) 38 16 1 $s1
  Rect $b ($ox + 8) 1 1 38 $s1; Rect $b ($ox + 23) 1 1 38 $s1
  Rect $b ($ox + 1) 38 5 3 $k0; Rect $b ($ox + 26) 38 5 3 $k0; Rect $b ($ox + 13) 39 6 3 $k0; Rect $b ($ox + 18) 39 4 3 $k0
  Clear $b $ox 5; Clear $b ($ox + 31) 5
}

# ---- 机 w×16（木の天板に、黒い本体。下にネオン色の線）
function Desk($name, $w) {
  Sheet $name $w 16 1 {
    param($b, $ox, $f)
    Rect $b $ox 0 $w 16 $k0
    Rect $b ($ox + 1) 1 ($w - 2) 6 $wd2; Rect $b ($ox + 1) 1 ($w - 2) 1 $wd3; Rect $b ($ox + 1) 5 ($w - 2) 1 $wd1; Rect $b ($ox + 1) 6 ($w - 2) 1 $wd0
    for ($x = 6; $x -lt $w - 4; $x += 11) { Px $b ($ox + $x) 3 $wd1; Px $b ($ox + $x + 1) 3 $wd1; Px $b ($ox + $x + 4) 2 $wd3 }
    Rect $b ($ox + 1) 7 ($w - 2) 8 (C '#1a1430')
    for ($dx = 4; $dx + 22 -lt $w; $dx += 26) {
      Rect $b ($ox + $dx) 8 22 5 $p1; Frame $b ($ox + $dx) 8 22 5 $p3
      Rect $b ($ox + $dx + 9) 10 4 1 $s3
    }
    for ($x = 1; $x -lt $w - 1; $x++) {
      $t = ($x - 1) / ($w - 3.0)
      $col = if ($t -lt 0.5) { Mix $mg $cy ($t * 2) } else { Mix $cy $mg (($t - 0.5) * 2) }
      Px $b ($ox + $x) 14 $col
      Px $b ($ox + $x) 13 (Mix $col (C '#1a1430') 0.75)
    }
    Clear $b $ox 0; Clear $b ($ox + $w - 1) 0; Clear $b $ox 15; Clear $b ($ox + $w - 1) 15
  }
}
Desk 'dtm_desk_l.png' 84
Desk 'dtm_desk_r.png' 56

# ---- ラグ 96x40（波形もようの敷物）
Sheet 'dtm_rug.png' 96 40 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 3) 0 90 40 (C '#6e1a52')
  Rect $b ($ox + 4) 1 88 38 (C '#8a2468')
  Rect $b ($ox + 6) 3 84 34 (C '#e9d6f2')
  Rect $b ($ox + 7) 4 82 32 (C '#2a1a58')
  for ($x = 0; $x -lt 82; $x++) {
    $y1 = [int](20 + 6 * [math]::Sin($x / 5.0)); $y2 = [int](20 + 3 * [math]::Sin($x / 2.5 + 1))
    Px $b ($ox + 7 + $x) $y1 $cy
    Px $b ($ox + 7 + $x) ($y2) (Mix $mg (C '#2a1a58') 0.35)
    if ($x % 6 -eq 0) { Px $b ($ox + 7 + $x) 5 (C '#5a3a98'); Px $b ($ox + 7 + $x) 34 (C '#5a3a98') }
  }
  for ($y = 2; $y -lt 38; $y += 2) { Rect $b $ox $y 3 1 (C '#d9c4e8'); Rect $b ($ox + 93) $y 3 1 (C '#d9c4e8') }
  Clear $b ($ox + 3) 0; Clear $b ($ox + 92) 0; Clear $b ($ox + 3) 39; Clear $b ($ox + 92) 39
}

# ---- 体験用のテーブル 48x16 と パッド 24x10（ぴかぴか光る）
Sheet 'dtm_table.png' 48 16 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 48 7 $k0
  Rect $b ($ox + 1) 1 46 5 $wd2; Rect $b ($ox + 1) 1 46 1 $wd3; Rect $b ($ox + 1) 5 46 1 $wd1
  Rect $b ($ox + 2) 7 44 3 (C '#1a1430')
  Rect $b ($ox + 2) 10 3 6 $k0; Rect $b ($ox + 3) 10 1 5 $wd1
  Rect $b ($ox + 43) 10 3 6 $k0; Rect $b ($ox + 44) 10 1 5 $wd1
  for ($x = 3; $x -lt 45; $x++) { Px $b ($ox + $x) 9 (Mix $vi $cy ($x / 48.0)) }
  Clear $b $ox 0; Clear $b ($ox + 47) 0
}
Sheet 'dtm_pads_glow.png' 24 10 8 {
  param($b, $ox, $f)
  Rect $b $ox 0 24 10 $k0
  Rect $b ($ox + 1) 1 22 8 (C '#2a2542')
  Rect $b ($ox + 1) 1 22 1 $s2
  for ($r = 0; $r -lt 2; $r++) {
    for ($c = 0; $c -lt 4; $c++) {
      $idx = $r * 4 + $c
      $col = $nl[$idx % 6]
      $lit = ($idx -eq ($f % 8)) -or ($idx -eq (($f * 3 + 2) % 8))
      if ($lit) { Rect $b ($ox + 2 + $c * 5) (2 + $r * 4) 4 3 $col; Px $b ($ox + 2 + $c * 5) (2 + $r * 4) $wht }
      else { Rect $b ($ox + 2 + $c * 5) (2 + $r * 4) 4 3 (Mix $col (C '#2a2542') 0.82) }
    }
  }
  Clear $b $ox 0; Clear $b ($ox + 23) 0; Clear $b $ox 9; Clear $b ($ox + 23) 9
}

# ---- キーボード用のX字スタンド 40x14
Sheet 'dtm_xstand.png' 40 14 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 40 2 $s2; Rect $b $ox 0 40 1 $s3
  Line $b ($ox + 4) 2 ($ox + 35) 12 $s2; Line $b ($ox + 5) 2 ($ox + 36) 12 $s1
  Line $b ($ox + 35) 2 ($ox + 4) 12 $s2; Line $b ($ox + 36) 2 ($ox + 5) 12 $s1
  Rect $b ($ox + 2) 12 6 2 $k0; Rect $b ($ox + 32) 12 6 2 $k0
}

# ---- ゲーミング風のイス 20x26（背もたれは人物の後ろ）
Sheet 'dtm_chair.png' 20 26 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 2) 0 16 14 $k0
  Rect $b ($ox + 3) 1 14 12 (C '#2f2552'); Rect $b ($ox + 3) 1 14 1 $p5
  Rect $b ($ox + 6) 2 8 3 (C '#42357a')
  Rect $b ($ox + 3) 5 2 7 (Mix $vi $k0 0.45); Rect $b ($ox + 15) 5 2 7 (Mix $vi $k0 0.45)
  Rect $b ($ox + 3) 14 14 4 $k0; Rect $b ($ox + 4) 14 12 3 (C '#2a2145')
  Rect $b ($ox + 9) 18 2 4 $s2
  Rect $b ($ox + 4) 22 12 1 $s2
  Rect $b ($ox + 3) 23 3 2 $k0; Rect $b ($ox + 8) 24 4 2 $k0; Rect $b ($ox + 14) 23 3 2 $k0
  Clear $b ($ox + 2) 0; Clear $b ($ox + 17) 0
}

# ---- ビーズクッション 28x14
Sheet 'dtm_beanbag.png' 28 14 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 14) 8 13.6 5.8 $k0
  Ellipse $b ($ox + 14) 8 12.6 4.8 (C '#5a3ca8')
  Ellipse $b ($ox + 14) 5.5 9 4.2 (C '#7c5ad6')
  Ellipse $b ($ox + 10) 4 3.5 1.6 (C '#a08af2')
  Line $b ($ox + 4) 9 ($ox + 12) 11 (C '#47308a'); Line $b ($ox + 16) 11 ($ox + 24) 9 (C '#47308a')
}

# ---- 置き看板「たいけん」 28x38 2コマ
Sheet 'dtm_aframe.png' 28 38 2 {
  param($b, $ox, $f)
  Line $b ($ox + 6) 32 ($ox + 3) 37 $s2; Line $b ($ox + 7) 32 ($ox + 4) 37 $k0
  Line $b ($ox + 21) 32 ($ox + 24) 37 $s2; Line $b ($ox + 22) 32 ($ox + 25) 37 $k0
  Rect $b ($ox + 2) 0 24 33 $k0
  Rect $b ($ox + 3) 1 22 31 $p1
  Frame $b ($ox + 3) 1 22 31 $cy
  for ($x = 4; $x -lt 24; $x++) { if ((($x + 2 * $f) % 4) -lt 2) { Rect $b ($ox + $x) 2 1 2 $yl } }
  [void](TextPx $b 'たい' ($ox + 5) 6 10 $k0 $true); [void](TextPx $b 'たい' ($ox + 4) 5 10 $wht $true)
  [void](TextPx $b 'けん' ($ox + 5) 17 10 $k0 $true); [void](TextPx $b 'けん' ($ox + 4) 16 10 $mg $true)
  if ($f -eq 0) { [void](T3 $b 'TRY!' ($ox + 6) 27 $gr) } else { [void](T3 $b 'TRY!' ($ox + 6) 27 (Mix $gr $p1 0.7)) }
  Clear $b ($ox + 2) 0; Clear $b ($ox + 25) 0
}

# ---- ただよう音符 40x48 8コマ（下から上へふわふわ昇って消える）
Sheet 'dtm_notes_drift.png' 40 48 8 {
  param($b, $ox, $f)
  $specs = @(@(0, 4, 0), @(16, 16, 1), @(32, 27, 0))
  $ccols = @($mg, $cy, $yl)
  for ($i = 0; $i -lt 3; $i++) {
    $ph = $specs[$i][0]
    $p = (($f * 6 + $ph) % 48) / 48.0
    $y = 38 - [int]($p * 38)
    $x = $specs[$i][1] + [int](3 * [math]::Sin($p * 12.5))
    $a = [int](255 * [math]::Sin([math]::PI * $p))
    if ($a -lt 60) { continue }
    $col = Al $ccols[$i] $a
    $shape = if ($specs[$i][2] -eq 1) { $noteBeam } else { $noteEighth }
    Ascii $b ($ox + $x) $y $shape @{ X = $col }
    Px $b ($ox + $x + 7) ($y + 3) (Al $wht ([int]($a / 2)))
  }
}

# ---- 床のLEDライン 28x4 4コマ（光が走る）
Sheet 'dtm_strip_floor.png' 28 4 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 28 4 $k0
  Rect $b ($ox + 1) 1 26 2 $s1
  for ($x = 0; $x -lt 26; $x++) {
    $t = (($x - $f * 6.5) % 26 + 26) % 26
    $v = if ($t -lt 7) { 1 - $t / 7.0 } else { 0 }
    Px $b ($ox + 1 + $x) 1 (Mix $s1 $cy (0.15 + 0.85 * $v))
    Px $b ($ox + 1 + $x) 2 (Mix $s0 $mg (0.1 + 0.6 * $v))
  }
  Clear $b $ox 0; Clear $b ($ox + 27) 0; Clear $b $ox 3; Clear $b ($ox + 27) 3
}

# ---- ケーブル 40x8（床をはう）
Sheet 'dtm_cable.png' 40 8 1 {
  param($b, $ox, $f)
  $pp = @(@(0, 5), @(6, 4), @(12, 3), @(18, 4), @(24, 5), @(30, 4), @(36, 2), @(39, 1))
  for ($i = 0; $i -lt $pp.Count - 1; $i++) {
    Line $b ($ox + $pp[$i][0]) $pp[$i][1] ($ox + $pp[$i + 1][0]) $pp[$i + 1][1] $k0
    Line $b ($ox + $pp[$i][0]) ($pp[$i][1] + 1) ($ox + $pp[$i + 1][0]) ($pp[$i + 1][1] + 1) $s0
  }
  Line $b $ox 3 ($ox + 12) 6 $k0; Line $b ($ox + 12) 6 ($ox + 26) 2 $k0; Line $b ($ox + 26) 2 ($ox + 38) 6 $k0
  Px $b ($ox + 12) 6 $cy; Px $b ($ox + 26) 2 $mg
}

# ---- 小物
Sheet 'dtm_mug.png' 7 7 1 {
  param($b, $ox, $f)
  Rect $b $ox 1 5 6 $k0; Rect $b ($ox + 1) 2 3 4 $wht; Rect $b ($ox + 1) 2 3 1 (C '#5a3418')
  Rect $b ($ox + 5) 2 2 3 $k0; Px $b ($ox + 6) 3 $k0; Rect $b ($ox + 1) 5 3 1 $mg
}
Sheet 'dtm_plant.png' 12 18 1 {
  param($b, $ox, $f)
  $g1 = C '#2fa84a'; $g2 = C '#1c6a30'; $g3 = C '#5ad86e'
  Ascii $b $ox 0 @('..g.....g...', '.ghg...ghg..', '.ghg.g.ghg..', '.ghghghgh...', '..ghghghg...', '...ghghgg...', '....ghgh....', '.....gg.....') @{ g = $g1; h = $g2 }
  Px $b ($ox + 3) 3 $g3; Px $b ($ox + 8) 2 $g3; Px $b ($ox + 6) 5 $g3
  Rect $b ($ox + 2) 8 8 1 $k0
  Rect $b ($ox + 2) 9 8 8 (C '#6a4ac0'); Rect $b ($ox + 2) 9 8 1 (C '#9a80f0'); Rect $b ($ox + 2) 9 1 8 (C '#8a6ae0'); Rect $b ($ox + 9) 9 1 8 (C '#47308a')
  Rect $b ($ox + 3) 17 6 1 $k0
  Rect $b ($ox + 3) 12 2 2 $mg
}
