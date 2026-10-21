# 吹奏楽・筝曲部（合併）の専用ドット絵（看板・楽譜の幕・段の舞台・管楽器・打楽器・譜面台・指揮台・指揮棒・パイプ椅子・受付・のぼり・音符・きらめき、
# 和楽器コーナー＝毛氈と畳・三味線・尺八・筝・音の波）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/suisougaku.ps1
# 一部だけ作り直す: $env:SUI_ONLY='sign|koto|shamisen'; （ファイル名の正規表現。省略すると全部）
# 出力: client/public/brand/stall/suisougaku_*.png （配置は scripts/stalls/suisougaku.mjs）
# 配色は金（金管）・赤紫のベルベット・赤茶の木・黒・白。アニメは「フレームを横一列に並べたPNG」。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  if ($env:SUI_ONLY -and $name -notmatch $env:SUI_ONLY) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}
$clr = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# 色: 金管 / 銀 / 銅 / ベルベット / 木 / 黒 / 白
$g0 = C '#5a3a0c'; $g1 = C '#a8741c'; $g2 = C '#e0a830'; $g3 = C '#ffd660'; $g4 = C '#fff3b0'
$s0 = C '#4a4a5a'; $s1 = C '#8a8a9c'; $s2 = C '#c4c4d4'; $s3 = C '#f2f2fa'
$c1 = C '#7a3a1c'; $c2 = C '#b8602e'; $c3 = C '#e08a4a'; $c4 = C '#f8c090'
$v0 = C '#3a0a22'; $v1 = C '#5e1230'; $v2 = C '#841a44'; $v3 = C '#a82a58'
$w0 = C '#3a2014'; $w1 = C '#6b3a22'; $w2 = C '#8c4a32'; $w3 = C '#b8764a'; $w4 = C '#d9a070'
$k0 = C '#14101a'; $k1 = C '#2c2630'; $k2 = C '#443c4c'; $k3 = C '#6a6070'
$wht = C '#f6f3ee'; $cream = C '#efe3c8'
# 和楽器コーナー: 毛氈（赤）/ 畳（いぐさ）/ 紫檀（三味線）/ 桐（筝）/ 竹（尺八）
$m0 = C '#5a0c18'; $m1 = C '#8e1424'; $m2 = C '#c0263a'; $m3 = C '#e0505c'
$t0 = C '#5c6636'; $t1 = C '#92a058'; $t2 = C '#b6c078'; $t3 = C '#d6dc9c'
$r0 = C '#24100c'; $r1 = C '#44180f'; $r2 = C '#7a3320'; $r3 = C '#a85a3a'
$p0 = C '#7a4c28'; $p1 = C '#b07a44'; $p2 = C '#d6a468'; $p3 = C '#f0cf98'
$b0 = C '#6a4a12'; $b1 = C '#a47c26'; $b2 = C '#d2ac4a'; $b3 = C '#f0d684'
$skin = C '#f3eedd'; $skin2 = C '#d4cbb0'

# ---- 看板「吹奏楽・筝曲部」128x32。金の文字・赤紫のベルベット・電球が追いかけて光り、きらめきが走る 6コマ
# （MS Gothic に「筝(U+7B1D)」の字が無いので、絵の中では同じ意味の「箏(U+7B8F)」を使う）
$signA = '吹奏楽'; $signB = '箏曲部'
Sheet 'suisougaku_sign.png' 128 32 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 128 32 $k0
  Rect $b ($ox + 1) 1 126 30 $g1
  Rect $b ($ox + 2) 2 124 28 $g3
  Rect $b ($ox + 3) 3 122 26 $g1
  Rect $b ($ox + 4) 4 120 24 $v1
  for ($x = 4; $x -lt 124; $x += 4) { Rect $b ($ox + $x) 4 1 24 $v2 }
  for ($x = 6; $x -lt 124; $x += 8) { Rect $b ($ox + $x) 4 1 24 $v0 }
  Rect $b ($ox + 4) 4 120 1 $v0; Rect $b ($ox + 4) 27 120 1 $v0
  for ($i = 0; $i -lt 20; $i++) {
    $x = 5 + $i * 6
    $col = if ((($i + $f) % 3) -eq 0) { $g4 } else { $g2 }
    Px $b ($ox + $x) 2 $col; Px $b ($ox + $x) 29 $col
  }
  foreach ($y in 8, 14, 20, 26) { $col = if (((($y / 6) + $f) % 3) -lt 1) { $g4 } else { $g2 }; Px $b ($ox + 2) $y $col; Px $b ($ox + 125) $y $col }
  # 「吹奏楽」・「箏曲部」（16px 太字）。あいだの「・」は 3x3 の金の点
  $tx = 10; $ty = 8
  [void](TextPx $b $signA ($ox + $tx + 1) ($ty + 1) 16 $v0 $true)
  [void](TextPx $b $signB ($ox + $tx + 60) ($ty + 1) 16 $v0 $true)
  Rect $b ($ox + 63) 16 3 3 $v0
  [void](TextPx $b $signA ($ox + $tx) $ty 16 $g3 $true)
  [void](TextPx $b $signB ($ox + $tx + 59) $ty 16 $g3 $true)
  Rect $b ($ox + 62) 15 3 3 $g3
  $gx = 12 + $f * 20; $gy = 9 + ($f % 2) * 11
  Px $b ($ox + $gx) $gy $wht; Px $b ($ox + $gx - 1) $gy $g4; Px $b ($ox + $gx + 1) $gy $g4; Px $b ($ox + $gx) ($gy - 1) $g4; Px $b ($ox + $gx) ($gy + 1) $g4
  foreach ($p in @(@(0, 0), @(127, 0), @(0, 31), @(127, 31))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ---- 背景の幕 140x36。赤紫のベルベットのカーテン・金のふさ・真ん中は楽譜
Sheet 'suisougaku_backdrop.png' 140 36 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 140 36 $v1
  $fold = @($v0, $v1, $v2, $v3, $v2, $v1)
  for ($x = 0; $x -lt 140; $x++) { Rect $b ($ox + $x) 6 1 27 $fold[$x % 6] }
  # 真ん中の楽譜の壁
  Rect $b ($ox + 30) 8 80 25 $g1; Rect $b ($ox + 31) 9 78 23 $g3; Rect $b ($ox + 32) 10 76 21 $cream
  foreach ($y in 15, 18, 21, 24, 27) { Rect $b ($ox + 35) $y 70 1 $k2 }
  Rect $b ($ox + 35) 15 1 13 $k0; Rect $b ($ox + 105) 15 1 13 $k0; Rect $b ($ox + 103) 15 1 13 $k0
  # 音部記号の代わりに金のかざり、音符（のぼっていく）
  Ellipse $b ($ox + 40) 21.5 3.2 3.2 $g2; Ellipse $b ($ox + 40) 21.5 1.6 1.6 $cream
  $ny = @(28.5, 27, 25.5, 24, 22.5, 21)
  for ($i = 0; $i -lt 6; $i++) {
    $x = 49 + $i * 9
    Ellipse $b ($ox + $x) $ny[$i] 2.4 1.7 $k0
    Rect $b ($ox + $x + 2) ($ny[$i] - 9) 1 9 $k0
  }
  Rect $b ($ox + 51) 13 19 2 $k0; Rect $b ($ox + 78) 11 10 2 $k0
  # 上のかざり（ふさ付きのスワッグ）
  Rect $b $ox 0 140 5 $v2
  for ($x = 0; $x -lt 140; $x += 14) { Ellipse $b ($ox + $x + 7) 4 7.2 3.4 $v2; Ellipse $b ($ox + $x + 7) 3 6.4 2.4 $v3 }
  for ($x = 0; $x -lt 140; $x += 14) { Rect $b ($ox + $x + 6) 5 2 1 $g2 }
  Rect $b $ox 0 140 1 $v0
  for ($x = 14; $x -lt 140; $x += 14) { Rect $b ($ox + $x - 1) 0 2 5 $v0 }
  foreach ($tx in 26, 113) {
    Rect $b ($ox + $tx) 8 1 6 $g1; Ellipse $b ($ox + $tx) 15 2 2 $g2
    Rect $b ($ox + $tx - 2) 17 5 7 $g3; Rect $b ($ox + $tx - 2) 17 1 7 $g2; for ($i = 0; $i -lt 5; $i += 2) { Px $b ($ox + $tx - 2 + $i) 24 $g1 }
  }
  Rect $b $ox 33 140 3 $k0
}

# ---- 段の舞台 144x44（3段・ふちに金・角に階段）。足元の線は舞台の手前のふち
Sheet 'suisougaku_risers.png' 144 44 1 {
  param($b, $ox, $f)
  $tiers = @(@(0, 12), @(14, 12), @(28, 12))
  foreach ($t in $tiers) {
    $y0 = $t[0]
    Rect $b $ox $y0 144 12 $w3
    for ($yy = $y0 + 3; $yy -lt $y0 + 12; $yy += 4) { Rect $b $ox $yy 144 1 $w2 }
    for ($yy = $y0; $yy -lt $y0 + 12; $yy += 4) { for ($x = (($yy / 4) % 2) * 17 + 5; $x -lt 144; $x += 34) { Px $b ($ox + $x) ($yy + 1) $w2; Px $b ($ox + $x) ($yy + 2) $w2 } }
    Rect $b $ox $y0 144 1 $w4
    Rect $b $ox ($y0 + 12) 144 2 $w1
    Rect $b $ox ($y0 + 12) 144 1 $g2
    Rect $b $ox ($y0 + 13) 144 1 $w0
  }
  Rect $b $ox 40 144 4 $w1; Rect $b $ox 40 144 1 $g2; Rect $b $ox 43 144 1 $k0
  for ($x = 0; $x -lt 144; $x += 12) { Rect $b ($ox + $x + 6) 41 1 2 $w0 }
  foreach ($sx in 0, 128) {
    Rect $b ($ox + $sx) 40 16 1 $w4; Rect $b ($ox + $sx) 41 16 1 $w3; Rect $b ($ox + $sx) 42 16 1 $w1; Rect $b ($ox + $sx) 43 16 1 $k0
  }
  Rect $b $ox 0 1 40 $w1; Rect $b ($ox + 143) 0 1 40 $w1
}

# ---- 客席の床（赤いじゅうたんの通路つき）150x34
Sheet 'suisougaku_floor.png' 150 34 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 150 34 (C '#c79a68')
  for ($y = 3; $y -lt 34; $y += 4) { Rect $b $ox $y 150 1 (C '#b08450') }
  for ($y = 0; $y -lt 34; $y += 4) { for ($x = (($y / 4) % 2) * 20 + 7; $x -lt 150; $x += 40) { Px $b ($ox + $x) ($y + 1) (C '#b08450'); Px $b ($ox + $x) ($y + 2) (C '#b08450') } }
  Rect $b ($ox + 59) 0 32 34 $v2
  Rect $b ($ox + 59) 0 2 34 $g2; Rect $b ($ox + 89) 0 2 34 $g2
  Rect $b ($ox + 61) 0 1 34 $v3; Rect $b ($ox + 88) 0 1 34 $v1
  for ($y = 3; $y -lt 34; $y += 8) { Px $b ($ox + 75) $y $g3; Px $b ($ox + 74) ($y + 1) $g3; Px $b ($ox + 76) ($y + 1) $g3; Px $b ($ox + 75) ($y + 2) $g3 }
  Rect $b $ox 33 150 1 $w1
  foreach ($p in @(@(0, 33), @(149, 33))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ---- トランペット 18x10
Sheet 'suisougaku_trumpet.png' 18 10 1 {
  param($b, $ox, $f)
  Rect $b $ox 4 2 2 $s1
  Rect $b ($ox + 2) 4 11 1 $g3; Rect $b ($ox + 2) 5 11 1 $g1
  Rect $b ($ox + 4) 6 8 1 $g2; Rect $b ($ox + 4) 7 8 1 $g1; Rect $b ($ox + 4) 6 1 2 $g1; Rect $b ($ox + 11) 6 1 2 $g1
  foreach ($x in 6, 8, 10) { Rect $b ($ox + $x) 1 1 3 $g2; Px $b ($ox + $x) 0 $s2 }
  for ($x = 12; $x -le 17; $x++) {
    $h = [int](1 + ($x - 12) * 0.9)
    Rect $b ($ox + $x) (5 - $h) 1 (2 * $h) $g2
    Px $b ($ox + $x) (5 - $h) $g3
    Px $b ($ox + $x) (4 + $h) $g1
  }
  Rect $b ($ox + 17) 0 1 10 $g4; Rect $b ($ox + 16) 2 1 6 $g0
}

# ---- トロンボーン 24x8（長いスライド）
Sheet 'suisougaku_trombone.png' 24 8 1 {
  param($b, $ox, $f)
  Rect $b $ox 3 2 2 $s1
  Rect $b ($ox + 2) 3 15 1 $g3; Rect $b ($ox + 2) 4 15 1 $g2; Rect $b ($ox + 2) 5 15 1 $g1
  Rect $b ($ox + 7) 1 11 1 $s2; Rect $b ($ox + 7) 6 11 1 $s2; Rect $b ($ox + 17) 1 1 6 $s3
  Px $b ($ox + 8) 2 $s1
  for ($x = 18; $x -le 23; $x++) {
    $h = [int](1 + ($x - 18) * 0.7)
    Rect $b ($ox + $x) (4 - $h) 1 (2 * $h) $g2
    Px $b ($ox + $x) (4 - $h) $g3; Px $b ($ox + $x) (3 + $h) $g1
  }
  Rect $b ($ox + 23) 0 1 8 $g4
}

# ---- チューバ 24x26（上に向かって大きなベル）
Sheet 'suisougaku_tuba.png' 24 26 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 9) 19 9 7 $g0
  Ellipse $b ($ox + 9) 19 8.2 6.2 $g1
  Ellipse $b ($ox + 9) 18.6 7.4 5.4 $g2
  Ellipse $b ($ox + 8) 18 5 3.2 $g3
  Ellipse $b ($ox + 9.5) 19.5 4.6 3.2 $clr
  for ($y = 3; $y -le 14; $y++) {
    $half = 1.5 + (14 - $y) * 0.5
    $x0 = [int][math]::Round(16 - $half); $x1 = [int][math]::Round(16 + $half)
    Rect $b ($ox + $x0) $y ($x1 - $x0 + 1) 1 $g2
    Px $b ($ox + $x0) $y $g1; Px $b ($ox + $x0 + 1) $y $g3; Px $b ($ox + $x1) $y $g1
  }
  Ellipse $b ($ox + 16) 3 7.4 2.4 $g3
  Ellipse $b ($ox + 16) 3.4 6 1.7 $g0
  Rect $b ($ox + 10) 2 5 1 $g4
  foreach ($x in 17, 19, 21) { Rect $b ($ox + $x) 14 1 7 $s1; Px $b ($ox + $x) 13 $s2 }
  Rect $b ($ox + 0) 9 4 2 $s1; Line $b ($ox + 3) 10 ($ox + 5) 14 $g1
}

# ---- ホルン 16x16（まるく巻いた管）
Sheet 'suisougaku_horn.png' 16 16 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 8) 8 7.6 7.6 $g0
  Ellipse $b ($ox + 8) 8 6.9 6.9 $g2
  Ellipse $b ($ox + 8) 8 5 5 $g1
  Ellipse $b ($ox + 8) 8 3.6 3.6 $g2
  Ellipse $b ($ox + 8) 8 2.2 2.2 $clr
  Ellipse $b ($ox + 6) 5 3 2 $g3
  Rect $b ($ox + 13) 1 3 6 $g3; Rect $b ($ox + 15) 0 1 8 $g4
  Rect $b ($ox + 0) 3 3 1 $s1
}

# ---- アルトサックス 14x22（J字のかたち）
Sheet 'suisougaku_sax.png' 14 22 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 0) 0 3 2 $k1
  Line $b ($ox + 3) 1 ($ox + 6) 3 $g2; Line $b ($ox + 3) 2 ($ox + 6) 4 $g1
  Rect $b ($ox + 6) 3 4 14 $g2; Rect $b ($ox + 6) 3 1 14 $g3; Rect $b ($ox + 9) 3 1 14 $g1
  foreach ($y in 5, 8, 11, 14) { Px $b ($ox + 8) $y $s2 }
  Ellipse $b ($ox + 9) 17.5 3.6 3 $g2
  Ellipse $b ($ox + 9) 17.5 1.8 1.5 $clr
  Rect $b ($ox + 10) 9 3 9 $g2; Rect $b ($ox + 10) 9 1 9 $g3
  Rect $b ($ox + 10) 7 4 2 $g3; Rect $b ($ox + 13) 6 1 4 $g4
}

# ---- クラリネット 6x20（黒い管と銀のキー）
Sheet 'suisougaku_clarinet.png' 6 20 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 2) 0 2 2 $k0
  Rect $b ($ox + 2) 2 2 14 $k1; Rect $b ($ox + 2) 2 1 14 $k2
  foreach ($y in 4, 7, 10, 13) { Px $b ($ox + 3) $y $s2; Px $b ($ox + 1) $y $s1 }
  Rect $b ($ox + 1) 16 4 3 $k1; Rect $b ($ox + 0) 18 6 2 $k0; Rect $b ($ox + 0) 18 6 1 $s1
}

# ---- フルート 16x3（銀の横笛）
Sheet 'suisougaku_flute.png' 16 3 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 16 2 $s2; Rect $b $ox 0 16 1 $s3; Rect $b $ox 2 16 1 $s1
  foreach ($x in 4, 7, 10, 13) { Px $b ($ox + $x) 1 $s0 }
  Rect $b $ox 0 2 3 $s0; Rect $b ($ox + 14) 0 2 3 $s1
}

# ---- スネアドラム 14x14（赤い胴・金のふち・スティック）
Sheet 'suisougaku_snare.png' 14 14 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 7) 4.5 6.9 3.5 $g1
  Ellipse $b ($ox + 7) 4.1 6.3 3.1 $wht
  Rect $b ($ox + 1) 5 12 5 $v2
  Rect $b ($ox + 1) 5 12 1 $g3; Rect $b ($ox + 1) 9 12 1 $g3
  for ($x = 3; $x -lt 12; $x += 3) { Rect $b ($ox + $x) 6 1 3 $g2 }
  Rect $b ($ox + 1) 10 12 1 $v0
  Line $b ($ox + 3) 11 ($ox + 3) 13 $k2; Line $b ($ox + 7) 11 ($ox + 7) 13 $k2; Line $b ($ox + 11) 11 ($ox + 11) 13 $k2
  Line $b ($ox + 2) 0 ($ox + 6) 3 $cream; Line $b ($ox + 11) 0 ($ox + 8) 3 $cream
  Px $b ($ox + 2) 0 $g4; Px $b ($ox + 11) 0 $g4
}

# ---- 大太鼓 26x26（胴は赤紫、皮に「吹」）
Sheet 'suisougaku_bassdrum.png' 26 26 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 13) 12.5 12.8 12.4 $k0
  Ellipse $b ($ox + 13) 12.5 12 11.6 $v2
  Ellipse $b ($ox + 13) 12.5 10.4 10 $g2
  Ellipse $b ($ox + 13) 12.5 9.8 9.4 $wht
  Ellipse $b ($ox + 11) 10 6 5 (C '#ffffff')
  for ($k = 0; $k -lt 8; $k++) {
    $a = $k * [math]::PI / 4
    Rect $b ([int]($ox + 12 + 11.2 * [math]::Cos($a))) ([int](11.5 + 10.8 * [math]::Sin($a))) 2 2 $g3
  }
  [void](TextPx $b '吹' ($ox + 6) 5 14 $v2 $false)
  Rect $b ($ox + 3) 24 4 2 $k1; Rect $b ($ox + 19) 24 4 2 $k1
}

# ---- ティンパニ 30x22（銅のかま2つ）
Sheet 'suisougaku_timpani.png' 30 22 1 {
  param($b, $ox, $f)
  foreach ($t in @(@(9, 8.6), @(22, 7.6))) {
    $cx = $t[0]; $r = $t[1]
    Ellipse $b ($ox + $cx) 13 $r 7.2 $c1
    Ellipse $b ($ox + $cx) 12.6 ($r - 1) 6.4 $c2
    Ellipse $b ($ox + $cx - 2) 12 ($r - 4) 4 $c3
    Px $b ($ox + $cx - 3) 11 $c4; Px $b ($ox + $cx - 4) 12 $c4
    Ellipse $b ($ox + $cx) 7 $r 3.6 $g2
    Ellipse $b ($ox + $cx) 7.2 ($r - 1) 3 $cream
    Ellipse $b ($ox + $cx - 1) 6.6 ($r - 4) 1.6 $wht
    Rect $b ($ox + $cx - 1) 19 2 3 $k1
  }
  Line $b ($ox + 13) 1 ($ox + 17) 5 $cream; Ellipse $b ($ox + 13) 1 1.3 1.3 $wht
}

# ---- シンバルのスタンド 20x28
Sheet 'suisougaku_cymbal.png' 20 28 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 9) 10 2 14 $k1
  Line $b ($ox + 10) 23 ($ox + 4) 27 $k1; Line $b ($ox + 10) 23 ($ox + 16) 27 $k1; Line $b ($ox + 10) 23 ($ox + 10) 27 $k1
  Ellipse $b ($ox + 10) 15 6.2 1.8 $g1; Ellipse $b ($ox + 10) 14.7 5.8 1.4 $g2
  Ellipse $b ($ox + 10) 8 9.4 2.4 $g1; Ellipse $b ($ox + 10) 7.6 8.8 2 $g2
  Ellipse $b ($ox + 10) 6.6 2.6 1.7 $g3
  Rect $b ($ox + 3) 7 5 1 $g3; Px $b ($ox + 8) 6 $g4
}

# ---- 譜面台と楽譜 10x15
Sheet 'suisougaku_stand.png' 10 15 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 10 9 $k2; Rect $b ($ox + 1) 1 8 7 $wht
  foreach ($y in 2, 4, 6) { Rect $b ($ox + 1) $y 8 1 $k3 }
  Px $b ($ox + 3) 3 $k0; Px $b ($ox + 3) 2 $k0; Px $b ($ox + 6) 5 $k0; Px $b ($ox + 6) 4 $k0; Px $b ($ox + 4) 3 $k0
  Rect $b ($ox + 0) 8 10 1 $s1
  Rect $b ($ox + 4) 9 2 4 $k2
  Line $b ($ox + 5) 12 ($ox + 1) 14 $k2; Line $b ($ox + 5) 12 ($ox + 8) 14 $k2
}

# ---- 指揮台 22x8
Sheet 'suisougaku_podium.png' 22 8 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 22 8 $k0
  Rect $b ($ox + 1) 1 20 3 $v2; Rect $b ($ox + 1) 1 20 1 $v3
  Rect $b ($ox + 1) 4 20 4 $w1; Rect $b ($ox + 1) 4 20 1 $g2; Rect $b ($ox + 1) 7 20 1 $w0
  Rect $b ($ox + 10) 5 2 2 $g3
  foreach ($p in @(@(0, 0), @(21, 0))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ---- 指揮棒 14x14（ふる）4コマ
Sheet 'suisougaku_baton.png' 14 14 4 {
  param($b, $ox, $f)
  $tip = @(@(12, 1), @(13, 6), @(10, 11), @(12, 6))[$f]
  $prev = @(@(12, 6), @(12, 1), @(13, 6), @(10, 11))[$f]
  Line $b ($ox + 2) 12 ($ox + $prev[0]) $prev[1] (Mix $cream $k0 0.55)
  Line $b ($ox + 2) 12 ($ox + $tip[0]) $tip[1] $wht
  Px $b ($ox + $tip[0]) $tip[1] $g4
  Rect $b ($ox + 1) 11 2 2 $g2
}

# ---- パイプ椅子（背もたれ / 座面と脚）
Sheet 'suisougaku_chairback.png' 14 14 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 1) 0 12 2 $s1; Rect $b ($ox + 1) 0 12 1 $s2
  Rect $b ($ox + 1) 2 12 9 $w2; Rect $b ($ox + 2) 3 10 7 $w3
  Rect $b ($ox + 0) 2 1 12 $s1; Rect $b ($ox + 13) 2 1 12 $s1
}
Sheet 'suisougaku_chairseat.png' 14 8 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 14 3 $w1; Rect $b $ox 0 14 1 $w3; Rect $b $ox 3 14 1 $w0
  Rect $b ($ox + 1) 4 2 4 $s1; Rect $b ($ox + 11) 4 2 4 $s1; Px $b ($ox + 1) 4 $s2; Px $b ($ox + 11) 4 $s2
}

# ---- 受付（プログラムを置いた机）44x28
Sheet 'suisougaku_booth.png' 44 28 1 {
  param($b, $ox, $f)
  Rect $b $ox 7 44 21 $k0
  Rect $b ($ox + 1) 8 42 5 $w3; Rect $b ($ox + 1) 8 42 1 $w4
  Rect $b ($ox + 1) 13 42 13 $w1; Rect $b ($ox + 1) 13 42 1 $g2
  Rect $b ($ox + 6) 14 22 12 $v1; Frame $b ($ox + 6) 14 22 12 $g2
  [void](TextPx $b '受付' ($ox + 8) 15 10 $g4 $false)
  Rect $b ($ox + 33) 15 8 8 $v2; Rect $b ($ox + 34) 16 6 6 $v1; Px $b ($ox + 36) 18 $g3; Px $b ($ox + 37) 19 $g3
  Rect $b ($ox + 31) 4 10 4 $wht; Rect $b ($ox + 31) 7 10 1 $v2; Rect $b ($ox + 32) 1 9 3 $cream; Rect $b ($ox + 32) 3 9 1 $v2; Px $b ($ox + 34) 2 $g2
  Rect $b ($ox + 6) 5 8 3 $wht; Rect $b ($ox + 6) 7 8 1 $v2
  Clear $b $ox 7; Clear $b ($ox + 43) 7
  Rect $b ($ox + 3) 26 4 2 $k0; Rect $b ($ox + 37) 26 4 2 $k0
}

# ---- のぼり旗（風でゆれる）。文字は縦書き。4コマ
function Nobori($name, $chars, $H, $fs = 11, $y0 = 6, $pitch = 11) {
  $tmp = NewBmp 16 $H
  Rect $tmp 0 2 16 2 $g1; Rect $tmp 0 2 16 1 $g3
  Rect $tmp 0 2 2 ($H - 2) $k2; Rect $tmp 0 2 1 ($H - 2) $k3
  $ch = $H - 8
  Rect $tmp 2 4 13 $ch $v1
  Rect $tmp 2 4 1 $ch $g3; Rect $tmp 14 4 1 $ch $g3; Rect $tmp 2 4 13 1 $g3
  for ($x = 4; $x -lt 14; $x += 3) { Rect $tmp $x 5 1 ($ch - 1) $v2 }
  for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Rect $tmp (2 + $i) (4 + $ch) 1 3 $v1; Px $tmp (2 + $i) (6 + $ch) $g2 } }
  for ($i = 0; $i -lt $chars.Count; $i++) { [void](TextPx $tmp $chars[$i] 3 ($y0 + $pitch * $i) $fs $wht $false) }
  Sheet $name 16 $H 4 {
    param($b, $ox, $f)
    for ($y = 0; $y -lt $H; $y++) {
      $sh = 0
      if ($y -ge 6) { $sh = [int][math]::Round(1.6 * [math]::Sin($f * [math]::PI / 2 - $y / 9.0) * (($y - 6) / ($H - 6.0))) }
      for ($x = 0; $x -lt 16; $x++) {
        $col = $tmp.GetPixel($x, $y)
        if ($col.A -gt 0) { if ($x -lt 2) { Px $b ($ox + $x) $y $col } else { Px $b ($ox + $x + $sh) $y $col } }
      }
    }
  }
  $tmp.Dispose()
}
Nobori 'suisougaku_nobori_a.png' @('吹', '奏', '楽', '部') 56
Nobori 'suisougaku_nobori_b.png' @('箏', '曲', '部') 52 12 6 13

# ---- 楽器のきらめき 9x9 4コマ
Sheet 'suisougaku_glint.png' 9 9 4 {
  param($b, $ox, $f)
  $cx = 4; $cy = 4
  switch ($f) {
    0 { Px $b ($ox + $cx) $cy $g4 }
    1 { Px $b ($ox + $cx) $cy $wht; foreach ($d in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1))) { Px $b ($ox + $cx + $d[0]) ($cy + $d[1]) $g4 } }
    2 {
      Px $b ($ox + $cx) $cy $wht
      foreach ($d in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1))) { Px $b ($ox + $cx + $d[0]) ($cy + $d[1]) $wht }
      foreach ($d in @(@(-2, 0), @(2, 0), @(0, -2), @(0, 2), @(-3, 0), @(3, 0), @(0, -3), @(0, 3))) { Px $b ($ox + $cx + $d[0]) ($cy + $d[1]) $g4 }
      foreach ($d in @(@(-1, -1), @(1, -1), @(-1, 1), @(1, 1))) { Px $b ($ox + $cx + $d[0]) ($cy + $d[1]) $g3 }
    }
    3 { Px $b ($ox + $cx) $cy $wht; foreach ($d in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1), @(-2, 0), @(2, 0), @(0, -2), @(0, 2))) { Px $b ($ox + $cx + $d[0]) ($cy + $d[1]) $g3 } }
  }
}

# ---- 浮かぶ音符 30x34 4コマ（ゆっくり上へ、だんだん消える）
$noteRows = @('....XX.', '....X.X', '....X..', '....X..', '....X..', '..XXX..', '.XXXX..', '..XX...')
Sheet 'suisougaku_notes.png' 30 34 4 {
  param($b, $ox, $f)
  $al = @(255, 255, 200, 110)[$f]
  $outline = CA '#3a0a22' $al
  $gold = CA '#ffd660' $al
  $white = CA '#f6f3ee' $al
  foreach ($d in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1))) {
    Ascii $b ($ox + 4 + $d[0]) (22 - $f * 5 + $d[1]) $noteRows @{ X = $outline }
    Ascii $b ($ox + 18 + $d[0]) (25 - $f * 5 + $d[1]) $noteRows @{ X = $outline }
  }
  Ascii $b ($ox + 4) (22 - $f * 5) $noteRows @{ X = $gold }
  Ascii $b ($ox + 18) (25 - $f * 5) $noteRows @{ X = $white }
}

# =====================================================================
# 和楽器コーナー（筝曲部）: 毛氈と畳の敷物・三味線・尺八・筝・音の波
# =====================================================================

# ---- 毛氈（赤）と畳の敷物 54x32（床に敷く）。畳のふちに黒いへり、真ん中に赤い毛氈
Sheet 'suisougaku_mosen.png' 54 32 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 54 32 $t1
  for ($y = 1; $y -lt 32; $y += 2) { Rect $b $ox $y 54 1 $t2 }
  for ($y = 0; $y -lt 32; $y += 4) { for ($x = (($y / 4) % 2) * 3; $x -lt 54; $x += 6) { Px $b ($ox + $x) $y $t3 } }
  Rect $b $ox 0 54 1 $k1; Rect $b $ox 31 54 1 $k1
  Rect $b $ox 1 54 1 $t0; Rect $b $ox 30 54 1 $t0
  Rect $b ($ox + 27) 2 1 28 $t0
  # 毛氈
  Rect $b ($ox + 4) 4 46 24 $k1
  Rect $b ($ox + 5) 5 44 22 $m2
  for ($y = 5; $y -lt 27; $y++) { for ($x = 5; $x -lt 49; $x++) { if ((($x + $y * 2) % 5) -eq 0) { Px $b ($ox + $x) $y $m1 } elseif ((($x * 2 + $y) % 11) -eq 0) { Px $b ($ox + $x) $y $m3 } } }
  Rect $b ($ox + 5) 5 44 1 $m3; Rect $b ($ox + 5) 26 44 1 $m1
  Frame $b ($ox + 6) 6 42 20 $g2
  Frame $b ($ox + 7) 7 40 18 $m1
  # 毛氈のふさ（左右のはし）
  foreach ($y in 8, 12, 16, 20, 24) { Px $b ($ox + 3) $y $g2; Px $b ($ox + 50) $y $g2 }
  foreach ($p in @(@(0, 0), @(53, 0), @(0, 31), @(53, 31))) { Px $b ($ox + $p[0]) $p[1] $clr }
}

# ---- 三味線 24x24 4コマ（胴・糸・さお・バチ。糸がふるえ、バチが皮を打つ）
Sheet 'suisougaku_shamisen.png' 24 24 4 {
  param($b, $ox, $f)
  # さお（紫檀）。左下の胴から右上の天神へ、幅3pxのまっすぐなさお
  for ($d = 0; $d -le 2; $d++) {
    $col = if ($d -eq 0) { $r2 } elseif ($d -eq 1) { $r1 } else { $r0 }
    Line $b ($ox + 8 + $d) 12 ($ox + 17 + $d) 1 $col
  }
  # 糸（ふるえるコマはまん中がずれて白く光る）
  $shift = @(0, 1, 0, (-1))[$f]
  for ($i = 0; $i -le 10; $i++) {
    $sh = 0
    if ($shift -ne 0 -and $i -ge 3 -and $i -le 8) { $sh = $shift }
    $col = if ($sh -ne 0) { $wht } else { $s2 }
    Px $b ($ox + 9 + $i + $sh) (12 - $i) $col
  }
  # 天神（先の糸巻き）
  Rect $b ($ox + 15) 0 7 3 $r0; Rect $b ($ox + 16) 0 5 2 $r1
  Px $b ($ox + 15) 1 $cream; Px $b ($ox + 21) 1 $cream; Px $b ($ox + 17) 3 $cream; Px $b ($ox + 22) 2 $cream
  # 胴（まわりは紫檀、皮は白）
  Rect $b ($ox + 1) 12 10 10 $r0
  Rect $b ($ox + 2) 13 8 8 $r3
  Rect $b ($ox + 3) 14 6 6 $skin
  Rect $b ($ox + 3) 19 6 1 $skin2
  Rect $b ($ox + 3) 13 6 1 $r2
  Px $b ($ox + 2) 13 $r2
  Rect $b ($ox + 4) 17 3 1 $r0; Px $b ($ox + 5) 16 $r0
  Line $b ($ox + 5) 16 ($ox + 8) 12 $s2
  Px $b ($ox + 1) 12 $clr; Px $b ($ox + 10) 21 $clr; Px $b ($ox + 1) 21 $clr
  # 糸かけ（赤い房）
  Rect $b ($ox + 5) 22 2 2 $m2; Px $b ($ox + 5) 23 $m1
  # バチ（象牙色の三角）。ふり上げる→ふり下ろして皮を打つ
  $tips = @(@(13, 15), @(8, 18), @(11, 17), @(8, 18))
  $tx = $tips[$f][0]; $ty = $tips[$f][1]
  $hx = $tx + 6; $hy = $ty + 5
  Line $b ($ox + $hx) ($hy + 1) ($ox + $tx) ($ty + 1) $r1
  Line $b ($ox + $hx) $hy ($ox + $tx) $ty $cream
  $blade = @(@(0, -2), @(1, -2), @(0, -1), @(1, -1), @(2, -1), @(-1, 0), @(0, 0), @(1, 0), @(2, 0), @(0, 1), @(1, 1), @(2, 1), @(0, 2), @(1, 2))
  foreach ($q in $blade) { foreach ($n in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1))) { Px $b ($ox + $tx + $q[0] + $n[0]) ($ty + $q[1] + $n[1]) $r0 } }
  foreach ($q in $blade) { Px $b ($ox + $tx + $q[0]) ($ty + $q[1]) $wht }
  foreach ($q in $blade) { if ($q[0] -ge 2) { Px $b ($ox + $tx + $q[0]) ($ty + $q[1]) $cream } }
}

# ---- 尺八 12x16 4コマ（竹の笛。吹くたびにゆれる）
Sheet 'suisougaku_shakuhachi.png' 12 16 4 {
  param($b, $ox, $f)
  $sway = @(0, 1, 0, (-1))[$f]
  $ex = 9 + $sway
  Line $b ($ox + 0) 0 ($ox + $ex) 14 $b0
  Line $b ($ox + 1) 0 ($ox + $ex + 1) 14 $b1
  Line $b ($ox + 2) 0 ($ox + $ex + 2) 14 $b2
  Line $b ($ox + 3) 0 ($ox + $ex + 3) 14 $b3
  Line $b ($ox + 3) 1 ($ox + $ex + 3) 15 $b2
  # 節（ふし）と指穴
  foreach ($t in 0.22, 0.5, 0.78) {
    $y = [int][math]::Round(14 * $t); $x = [int][math]::Round($ex * $t)
    Px $b ($ox + $x) $y $b0; Px $b ($ox + $x + 1) $y $b0; Px $b ($ox + $x + 2) $y $b1; Px $b ($ox + $x + 3) $y $b1
  }
  foreach ($t in 0.36, 0.44, 0.58, 0.66, 0.9) {
    $y = [int][math]::Round(14 * $t); $x = [int][math]::Round($ex * $t)
    Px $b ($ox + $x + 2) $y $k0
  }
  # 歌口（うたぐち）と下のはし
  Px $b ($ox + 0) 0 $k1; Px $b ($ox + 1) 0 $k1; Px $b ($ox + 1) 1 $cream
  Rect $b ($ox + $ex + 1) 14 3 2 $b0; Px $b ($ox + $ex + 2) 14 $k0; Px $b ($ox + $ex + 2) 15 $k0
}

# ---- 筝 42x14 4コマ（13本の弦・13個の柱（じ）・二つの台。弦がきらめいてふるえる）
Sheet 'suisougaku_koto.png' 42 14 4 {
  param($b, $ox, $f)
  # 胴（桐）。上の面→手前の面→台
  Rect $b ($ox + 2) 0 38 8 $p1
  Rect $b ($ox + 2) 0 38 1 $p3
  Rect $b ($ox + 2) 7 38 1 $p0
  Rect $b ($ox + 2) 8 38 3 $p0
  Rect $b ($ox + 2) 8 38 1 $p2
  Rect $b ($ox + 2) 10 38 1 $r1
  for ($x = 6; $x -lt 38; $x += 8) { Px $b ($ox + $x) 9 $p1 }
  # 両はし（黒漆と金のふち）
  foreach ($ex in 0, 39) {
    Rect $b ($ox + $ex) 1 3 10 $r0
    Rect $b ($ox + $ex) 1 1 10 $r1; Px $b ($ox + $ex + 1) 2 $r3; Px $b ($ox + $ex + 1) 3 $r2
    Rect $b ($ox + $ex + 1) 5 2 1 $g2; Rect $b ($ox + $ex + 1) 8 2 1 $g2
  }
  Clear $b ($ox + 0) 1; Clear $b ($ox + 41) 1; Clear $b ($ox + 0) 10; Clear $b ($ox + 41) 10
  # 弦（13本ぶんを細かい線で）。ふるえるコマは1段ずつずらして光る
  foreach ($y in 1, 3, 5) {
    $yy = $y + $(if ($f -eq 1) { 1 } elseif ($f -eq 3) { 0 } else { 0 })
    $col = if (($f % 2) -eq 1) { $wht } else { $cream }
    Rect $b ($ox + 3) $y 36 1 $col
    Rect $b ($ox + 3) ($y + 1) 36 1 $p2
  }
  for ($i = 0; $i -lt 3; $i++) { Px $b ($ox + 4 + (($f * 11 + $i * 13) % 34)) (1 + ((($f + $i) % 3) * 2)) $g4 }
  # 柱（じ）13個。ななめに並ぶ（手前から奥へ）
  for ($i = 0; $i -lt 13; $i++) {
    $x = [int][math]::Round(6 + $i * 2.5)
    $y = [int][math]::Round(5.5 - $i * 0.42)
    Rect $b ($ox + $x) $y 1 2 $r0
    Px $b ($ox + $x) ($y - 1) $wht; Px $b ($ox + $x + 1) $y $p0
  }
  # 台（2つ）
  foreach ($sx in 6, 31) {
    Rect $b ($ox + $sx) 11 5 3 $r1; Rect $b ($ox + $sx) 11 5 1 $r2; Rect $b ($ox + $sx) 13 5 1 $r0
    Px $b ($ox + $sx) 13 $clr; Px $b ($ox + $sx + 4) 13 $clr
  }
}

# ---- 音の波 14x20 4コマ（楽器から広がる弧。左の点がもと）
Sheet 'suisougaku_wave.png' 14 20 4 {
  param($b, $ox, $f)
  $rings = @(@(3, 255), @(3, 255, 6, 210), @(6, 210, 9, 160), @(9, 140, 12, 80))[$f]
  for ($k = 0; $k -lt $rings.Count; $k += 2) {
    $rad = $rings[$k]; $al = $rings[$k + 1]
    $c = CA '#fff3b0' $al
    $o = CA '#5e1230' ([int]($al * 0.7))
    for ($d = -52; $d -le 52; $d += 3) {
      $a = $d * [math]::PI / 180
      $x = [int][math]::Round(1 + $rad * [math]::Cos($a)); $y = [int][math]::Round(10 + $rad * 1.25 * [math]::Sin($a))
      Px $b ($ox + $x) ($y + 1) $o
    }
    for ($d = -52; $d -le 52; $d += 2) {
      $a = $d * [math]::PI / 180
      $x = [int][math]::Round(1 + $rad * [math]::Cos($a)); $y = [int][math]::Round(10 + $rad * 1.25 * [math]::Sin($a))
      Px $b ($ox + $x) $y $c
    }
  }
}
