# ハンドメイド（夜のクラゲ）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/handmade.ps1
# 出力: client/public/brand/stall/handmade_*.png （配置は scripts/stalls/handmade.mjs）
# 夜の海の底のような濃紺・紫の地面に、青緑・水色・紫・ピンクの蛍光色のクラゲが光る手作り雑貨のお店。
# アニメは「フレームを横一列に並べたPNG」で、handmade.mjs の k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function CC($c, $a) { [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function AL($v, $am) { [int][math]::Min(255, [math]::Max(0, $v * $am)) }

# いま描いているフレームの範囲（PxO がこの外には描かない）
$script:CX0 = 0; $script:CX1 = 100000
# 半透明を重ねて描く（下に何かあれば混ぜる）
function PxO($b, $x, $y, $col) {
  $x = [int]$x; $y = [int]$y
  if ($x -lt $script:CX0 -or $x -gt $script:CX1 -or $y -lt 0 -or $x -ge $b.Width -or $y -ge $b.Height) { return }
  if ($col.A -le 0) { return }
  if ($col.A -ge 255) { $b.SetPixel($x, $y, $col); return }
  $e = $b.GetPixel($x, $y)
  if ($e.A -eq 0) { $b.SetPixel($x, $y, $col); return }
  $a = $col.A / 255.0; $ea = $e.A / 255.0; $oa = $a + $ea * (1 - $a)
  $r = [int](($col.R * $a + $e.R * $ea * (1 - $a)) / $oa)
  $g = [int](($col.G * $a + $e.G * $ea * (1 - $a)) / $oa)
  $bl = [int](($col.B * $a + $e.B * $ea * (1 - $a)) / $oa)
  $b.SetPixel($x, $y, [System.Drawing.Color]::FromArgb([int]($oa * 255), $r, $g, $bl))
}
function RectO($b, $x, $y, $w, $h, $col) { for ($j = 0; $j -lt $h; $j++) { for ($i = 0; $i -lt $w; $i++) { PxO $b ($x + $i) ($y + $j) $col } } }
function EllO($b, $cx, $cy, $rx, $ry, $col) {
  for ($y = [math]::Floor($cy - $ry); $y -le [math]::Ceiling($cy + $ry); $y++) {
    for ($x = [math]::Floor($cx - $rx); $x -le [math]::Ceiling($cx + $rx); $x++) {
      $dx = ($x + 0.5 - $cx) / $rx; $dy = ($y + 0.5 - $cy) / $ry
      if ($dx * $dx + $dy * $dy -le 1) { PxO $b $x $y $col }
    }
  }
}
# ぼんやりした光（3段の半透明を重ねる）
function Halo($b, $cx, $cy, $rx, $ry, $hex, $a) {
  EllO $b $cx $cy $rx $ry (CA $hex $a)
  EllO $b $cx $cy ($rx * 0.72) ($ry * 0.72) (CA $hex $a)
  EllO $b $cx $cy ($rx * 0.45) ($ry * 0.45) (CA $hex $a)
}

# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { $script:CX0 = $f * $w; $script:CX1 = $f * $w + $w - 1; & $draw $bm ($f * $w) $f }
  $script:CX0 = 0; $script:CX1 = 100000
  Save $bm $name
}

# ---- 色 ----
$n0 = C '#050818'; $n1 = C '#0a1033'; $n2 = C '#121a52'; $n3 = C '#1d2a7a'; $n4 = C '#2f3fa8'; $n5 = C '#5b74e0'
$v1 = C '#2a1860'; $v2 = C '#46308f'; $v3 = C '#6a4cc4'
$wd0 = C '#2a1c34'; $wd1 = C '#46304e'; $wd2 = C '#6a4a6e'; $wd3 = C '#8e6a8a'
$gld = C '#ffd36a'; $gld2 = C '#c8962c'; $warm = C '#ffb347'; $crm = C '#fff3d6'
$cy = C '#3df5ff'; $pk = C '#ff6fcf'; $vi = C '#a688ff'; $mt = C '#4dffc4'

# クラゲの色。rim=ふち hi=ハイライト body=体 mid=下側 deep=いちばん下
$PCy = @{ rim = '#a8fdff'; hi = '#dcfeff'; body = '#37e4ff'; mid = '#1fa8e8'; deep = '#2a5fd0'; glow = '#27d8ff' }
$PPk = @{ rim = '#ffc8ee'; hi = '#ffe8f8'; body = '#ff6fcf'; mid = '#d03fb8'; deep = '#8a2fb0'; glow = '#ff4fd0' }
$PVi = @{ rim = '#d6c8ff'; hi = '#f0eaff'; body = '#a688ff'; mid = '#7552e6'; deep = '#4a34b8'; glow = '#9a6bff' }
$PMt = @{ rim = '#b8ffe8'; hi = '#e8fff8'; body = '#4dffc4'; mid = '#22c4a0'; deep = '#1a7fb0'; glow = '#3dffc0' }

# ---- クラゲ本体 ----
# 傘の中心X=$cx、傘の上端Y=$ty、傘の幅$bw・高さ$bh、色$pal、濃さ$am(1=ふつう)、足の長さ$tl、足のゆれの位相$ph、ゆれ幅$sw
function Jelly($b, $cx, $ty, $bw, $bh, $pal, $am, $tl, $ph, $sw) {
  $rim = C $pal.rim; $hi = C $pal.hi; $body = C $pal.body; $mid = C $pal.mid
  $by = $ty + $bh
  # うでの長いひらひら（太い）
  foreach ($off in -0.14, 0.0, 0.14) {
    $x0 = $cx + [math]::Round($off * $bw)
    $L = [int]($tl * 0.85)
    for ($i = 0; $i -lt $L; $i++) {
      $t = $i / [double]$L
      $x = $x0 + [math]::Round($sw * $t * [math]::Sin($ph - $i * 0.42 + $off * 5))
      $a = AL (215 - 165 * $t) $am
      PxO $b $x ($by + $i) (CC $body $a)
      if ($i -lt $L * 0.55) { PxO $b ($x + 1) ($by + $i) (CC $mid ([int]($a * 0.8))) }
    }
  }
  # 細い触手
  $k = 0
  foreach ($off in -0.42, -0.26, 0.26, 0.42) {
    $x0 = $cx + [math]::Round($off * $bw)
    $L = [int]($tl * (0.62 + 0.09 * $k))
    for ($i = 0; $i -lt $L; $i++) {
      $t = $i / [double]$L
      $x = $x0 + [math]::Round($sw * 1.2 * $t * [math]::Sin($ph - $i * 0.5 + $k * 1.7))
      PxO $b $x ($by + $i - 1) (CC $rim (AL (220 - 190 * $t) $am))
    }
    $k++
  }
  # 傘（半だ円）
  $prev = 0.0
  for ($y = 0; $y -lt $bh; $y++) {
    $hw = ($bw / 2.0) * [math]::Sqrt([math]::Max(0.0, 1 - [math]::Pow(($bh - ($y + 0.5)) / $bh, 2)))
    $xl = [int][math]::Round($cx - $hw); $xr = [int][math]::Round($cx + $hw) - 1
    $t = $y / [double]$bh
    for ($x = $xl; $x -le $xr; $x++) {
      $edge = ($x -le $xl) -or ($x -ge $xr) -or ([math]::Abs($x + 0.5 - $cx) -gt $prev) -or ($y -eq $bh - 1)
      if ($edge) { $col = CC $rim (AL 255 $am) }
      elseif ($t -lt 0.28) { $col = CC $hi (AL 205 $am) }
      elseif ($t -lt 0.6) { $col = CC $body (AL 185 $am) }
      else { $col = CC $mid (AL 160 $am) }
      PxO $b $x ($ty + $y) $col
    }
    $prev = $hw
  }
  # すそのひだ（ふちが波うつ）
  $xl = [int][math]::Round($cx - $bw / 2.0)
  for ($x = $xl; $x -lt $xl + $bw; $x += 2) { PxO $b $x ($by) (CC $rim (AL 200 $am)) }
  # 中の4本のすじ（生殖腺）
  if ($bw -ge 10) {
    foreach ($off in -0.16, 0.0, 0.16) {
      $x = $cx + [math]::Round($off * $bw)
      for ($y = [int]($ty + $bh * 0.42); $y -lt $ty + $bh - 2; $y++) { PxO $b $x $y (CC $hi (AL 150 $am)) }
    }
  }
  # つや
  PxO $b ($cx - [math]::Round($bw * 0.26)) ($ty + 2) (CA '#ffffff' (AL 255 $am))
  PxO $b ($cx - [math]::Round($bw * 0.26) + 1) ($ty + 1) (CA '#ffffff' (AL 230 $am))
}

# =====================================================================
# 床: 夜の海の底。草地全体(192x128)を覆う暗い絵＋ゆらぐ波の筋＋まん中の道
# =====================================================================
$rnd = New-Object System.Random 7
$fl = NewBmp 192 128
for ($y = 0; $y -lt 128; $y++) {
  $t = $y / 127.0
  $row = Mix (C '#0c1244') (C '#150c40') $t
  for ($x = 0; $x -lt 192; $x++) { $fl.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(236, $row.R, $row.G, $row.B)) }
}
# 波の筋（光のゆらぎ）
for ($y0 = 5; $y0 -lt 128; $y0 += 9) {
  for ($x = 0; $x -lt 192; $x++) {
    if ((([int][math]::Floor($x / 7)) + $y0) % 3 -ne 0) {
      $yy = $y0 + [int][math]::Round(1.6 * [math]::Sin($x * 0.17 + $y0 * 0.9))
      Px $fl $x $yy (CA '#2a3ca0' 235)
      if (($x + $y0) % 5 -eq 0) { Px $fl $x ($yy - 1) (CA '#3e56c8' 235) }
    }
  }
}
# まん中の道（光るガラス石のタイル）
for ($y = 82; $y -lt 128; $y++) {
  for ($x = 80; $x -lt 112; $x++) {
    $edge = ($x -le 81) -or ($x -ge 110)
    Px $fl $x $y (CA $(if ($edge) { '#3a58d0' } else { '#16226e' }) 255)
    if (-not $edge -and (($x / 4) -as [int]) % 2 -eq (($y / 4) -as [int]) % 2) { Px $fl $x $y (CA '#1c2c88' 255) }
  }
}
for ($y = 84; $y -lt 128; $y += 8) {
  for ($x = 86; $x -lt 108; $x += 8) { Px $fl ($x + ($y / 8 % 2) * 3) $y (CA '#5ff0ff' 255); Px $fl ($x + ($y / 8 % 2) * 3 + 1) $y (CA '#2a9ad8' 255) }
}
# 小さな星・プランクトン
for ($i = 0; $i -lt 70; $i++) {
  $x = $rnd.Next(0, 192); $y = $rnd.Next(0, 128)
  $c = @('#8fb0ff', '#c8d8ff', '#6fe8ff', '#ffb8f0')[$rnd.Next(0, 4)]
  Px $fl $x $y (CA $c 255)
}
Save $fl 'handmade_floor.png'

# =====================================================================
# 光だまり（床の上に重ねる半透明の光）192x128。ランタン・水槽・カウンター・テーブルの下
# =====================================================================
$pl = NewBmp 192 128
Halo $pl 74 120 26 9 '#ff9a3d' 30
Halo $pl 118 120 26 9 '#ff9a3d' 30
Halo $pl 154 116 28 9 '#27d8ff' 30
Halo $pl 48 114 30 9 '#b070ff' 30
Halo $pl 96 84 66 9 '#4a6cff' 22
Halo $pl 96 108 22 14 '#3dd8ff' 14
Save $pl 'handmade_pools.png'

# 床で光る小さなきらめき（プランクトン）192x128 4コマ
$sp = @(@(14, 20, 0), @(40, 34, 2), @(70, 18, 1), @(150, 24, 3), @(176, 40, 1), @(22, 70, 3), @(60, 98, 0), @(130, 92, 2), @(174, 86, 0), @(12, 112, 1), @(100, 76, 3), @(120, 12, 0), @(52, 54, 2), @(168, 64, 3), @(86, 120, 2), @(140, 122, 1))
Sheet 'handmade_sparkle.png' 192 128 4 {
  param($b, $ox, $f)
  foreach ($p in $sp) {
    $st = ($f + $p[2]) % 4
    $x = $ox + $p[0]; $y = $p[1]
    if ($st -eq 0) {
      Px $b $x $y (CA '#e8fdff' 255)
      Px $b ($x - 1) $y (CA '#6fe8ff' 230); Px $b ($x + 1) $y (CA '#6fe8ff' 230); Px $b $x ($y - 1) (CA '#6fe8ff' 230); Px $b $x ($y + 1) (CA '#6fe8ff' 230)
    } elseif ($st -eq 1) { Px $b $x $y (CA '#8fe8ff' 200) }
  }
}

# =====================================================================
# 看板（ハンドメイド / 夜のクラゲ）128x28 4コマ。ふちのライトが色を追いかける
# =====================================================================
$neon4 = @((C '#3df5ff'), (C '#ff6fcf'), (C '#a688ff'), (C '#4dffc4'))
$w1 = TextWidth 'ハンドメイド' 12
$w2 = TextWidth '夜のクラゲ' 11
Sheet 'handmade_sign.png' 128 28 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 128 28 $n0
  Rect $b ($ox + 1) 1 126 26 (C '#0b1240')
  for ($y = 2; $y -lt 26; $y++) { Rect $b ($ox + 2) $y 124 1 (Mix (C '#0e1752') (C '#1a1068') (($y - 2) / 24.0)) }
  for ($x = 1; $x -lt 127; $x++) {
    $col = $neon4[([int][math]::Floor($x / 8) + $f) % 4]
    Px $b ($ox + $x) 1 $col; Px $b ($ox + $x) 26 $col
    Px $b ($ox + $x) 2 (Mix $col (C '#0b1240') 0.62); Px $b ($ox + $x) 25 (Mix $col (C '#0b1240') 0.62)
  }
  for ($y = 1; $y -lt 27; $y++) {
    $col = $neon4[([int][math]::Floor($y / 6) + $f + 1) % 4]
    Px $b ($ox + 1) $y $col; Px $b ($ox + 126) $y $col
    Px $b ($ox + 2) $y (Mix $col (C '#0b1240') 0.62); Px $b ($ox + 125) $y (Mix $col (C '#0b1240') 0.62)
  }
  # 左のクラゲ
  Halo $b ($ox + 15) 12 11 10 '#27d8ff' 22
  Jelly $b ($ox + 15) 5 14 9 $PCy 1.2 9 ($f * 1.57) 2.0
  # 文字（影つき）
  $x1 = 32 + [math]::Floor((92 - $w1) / 2); $x2 = 32 + [math]::Floor((92 - $w2) / 2)
  [void](TextPx $b 'ハンドメイド' ($ox + $x1 + 1) 4 12 $n0 $true)
  [void](TextPx $b 'ハンドメイド' ($ox + $x1) 3 12 $crm $true)
  [void](TextPx $b '夜のクラゲ' ($ox + $x2 + 1) 16 11 $n0 $true)
  [void](TextPx $b '夜のクラゲ' ($ox + $x2) 15 11 (@($cy, (C '#9ff8ff'), $cy, (C '#d0fcff'))[$f]) $true)
  # すみのきらり
  $s = $neon4[($f + 2) % 4]
  foreach ($px in 5, 122) { Px $b ($ox + $px) 22 $s; Px $b ($ox + $px - 1) 23 $s; Px $b ($ox + $px + 1) 23 $s; Px $b ($ox + $px) 24 $s }
  foreach ($p in @(@(0, 0), @(127, 0), @(0, 27), @(127, 27))) { Clear $b ($ox + $p[0]) $p[1] }
}

# =====================================================================
# 天幕（夜空の縞に星）140x26。ふちはほのかに光る
# =====================================================================
$aw = NewBmp 140 26
for ($i = 0; $i -lt 14; $i++) {
  $x0 = $i * 10
  $a = if ($i % 2 -eq 0) { C '#232d7a' } else { C '#4a2f98' }
  $al = if ($i % 2 -eq 0) { C '#3a4cb0' } else { C '#6a4cc4' }
  $ad = if ($i % 2 -eq 0) { C '#161e58' } else { C '#32206e' }
  for ($x = 0; $x -lt 10; $x++) {
    $dd = [math]::Abs($x - 4.5) / 5.0
    $h = 20 + [int][math]::Round(5 * [math]::Sqrt([math]::Max(0.0, 1 - $dd * $dd)))
    for ($y = 0; $y -lt $h; $y++) {
      $col = $a
      if ($y -lt 2) { $col = $al } elseif ($y -gt 14) { $col = $ad }
      if ($x -eq 0) { $col = $ad } elseif ($x -eq 9) { $col = $ad }
      Px $aw ($x0 + $x) $y $col
    }
    Px $aw ($x0 + $x) ($h - 1) (C '#6fe8ff')
    if ($h -gt 21) { Px $aw ($x0 + $x) ($h - 2) (Mix (C '#6fe8ff') $a 0.55) }
  }
  Px $aw ($x0 + 5) 8 (C '#ffe9a0'); Px $aw ($x0 + 4) 9 (C '#ffd36a'); Px $aw ($x0 + 6) 9 (C '#ffd36a'); Px $aw ($x0 + 5) 10 (C '#ffd36a')
  if ($i % 2 -eq 1) { Px $aw ($x0 + 3) 15 (C '#cfe0ff') } else { Px $aw ($x0 + 7) 14 (C '#cfe0ff') }
}
Rect $aw 0 0 140 1 $n0
Save $aw 'handmade_awning.png'

# 天幕のふちに吊るした豆電球 140x12 4コマ（またたく）
$bc = @('#ffd36a', '#3df5ff', '#ff6fcf', '#4dffc4')
Sheet 'handmade_garland.png' 140 12 4 {
  param($b, $ox, $f)
  for ($x = 0; $x -lt 140; $x++) {
    $yy = 2 + [int][math]::Round(2.4 * [math]::Sin(([math]::PI) * (($x % 20) / 20.0)))
    Px $b ($ox + $x) $yy (C '#3a2a50')
  }
  for ($i = 0; $i -lt 14; $i++) {
    $x = 5 + $i * 10
    $yy = 2 + [int][math]::Round(2.4 * [math]::Sin(([math]::PI) * (($x % 20) / 20.0)))
    $on = (($i + $f) % 4) -ne 0
    $hex = $bc[($i + 1) % 4]
    $c = CA $hex 255
    if ($on) {
      PxO $b ($x - 1) ($yy + 2) (CA $hex 90); PxO $b ($x + 1) ($yy + 2) (CA $hex 90); PxO $b $x ($yy + 4) (CA $hex 90); PxO $b ($x - 1) ($yy + 4) (CA $hex 50); PxO $b ($x + 1) ($yy + 4) (CA $hex 50)
      Px $b $x ($yy + 1) (C '#3a2a50'); Px $b $x ($yy + 2) $c; Px $b $x ($yy + 3) (Mix $c (C '#ffffff') 0.5)
    } else {
      Px $b $x ($yy + 1) (C '#3a2a50'); Px $b $x ($yy + 2) (Mix $c $n1 0.65); Px $b $x ($yy + 3) (Mix $c $n1 0.8)
    }
  }
}

# =====================================================================
# 奥の壁（カーテン・柱・棚の小瓶・三日月）136x50
# =====================================================================
$wl = NewBmp 136 50
Rect $wl 6 0 124 50 (C '#0c1244')
for ($x = 6; $x -lt 130; $x++) {
  $m = $x % 9
  if ($m -lt 2) { Rect $wl $x 0 1 49 (C '#141c5c') } elseif ($m -eq 5 -or $m -eq 6) { Rect $wl $x 0 1 49 (C '#080c30') }
}
Rect $wl 6 49 124 1 $n0
$rs = New-Object System.Random 11
for ($i = 0; $i -lt 26; $i++) {
  $x = $rs.Next(8, 128); $y = $rs.Next(27, 47)
  Px $wl $x $y (@((C '#cfe0ff'), (C '#ffd36a'), (C '#8fb0ff'))[$rs.Next(0, 3)])
}
# 柱
foreach ($px in 0, 130) {
  Rect $wl $px 0 6 50 (C '#5a3a50')
  Rect $wl ($px + 1) 0 1 50 (C '#8e6a8a'); Rect $wl ($px + 5) 0 1 50 $wd0; Rect $wl $px 0 1 50 $wd1
  for ($y = 30; $y -lt 36; $y += 2) { Rect $wl $px $y 6 1 (C '#d8c498'); Rect $wl ($px + 1) ($y + 1) 5 1 (C '#a89068') }
  Rect $wl ($px - 0) 49 6 1 $wd0
}
# 棚と小瓶（左右）
function Shelf($b, $x0, $w) {
  Rect $b $x0 41 $w 2 (C '#6a4a6e'); Rect $b $x0 41 $w 1 (C '#8e6a8a'); Rect $b $x0 43 $w 1 $wd0
  $cols = @('#27d8ff', '#ff6fcf', '#a688ff', '#4dffc4', '#ffd36a', '#27d8ff')
  $i = 0
  for ($x = $x0 + 2; $x -lt $x0 + $w - 4; $x += 6) {
    $h = 5 + ($i % 3)
    $c = C $cols[$i % 6]
    Rect $b $x (41 - $h) 4 $h (Mix $c $n1 0.45)
    Rect $b $x (41 - $h) 1 $h $c
    Rect $b ($x + 1) (41 - $h + 1) 2 2 (Mix $c (C '#ffffff') 0.55)
    Rect $b ($x + 1) (41 - $h - 1) 2 1 (C '#c8a070')
    $i++
  }
}
Shelf $wl 9 30
Shelf $wl 97 30
# 三日月（左寄り）
$mx = 55; $my = 36
EllO $wl $mx $my 11 11 (CA '#ffd36a' 28)
EllO $wl $mx $my 8 8 (CA '#ffd36a' 28)
for ($y = -7; $y -le 7; $y++) { for ($x = -7; $x -le 7; $x++) {
  $in1 = ($x * $x + $y * $y) -le 49
  $in2 = (($x - 3) * ($x - 3) + ($y + 1) * ($y + 1)) -le 40
  if ($in1 -and -not $in2) { Px $wl ($mx + $x) ($my + $y) (C '#ffe9a0') }
  elseif ($in1 -and $in2 -and (($x - 3) * ($x - 3) + ($y + 1) * ($y + 1)) -gt 33 -and $x -lt 0) { Px $wl ($mx + $x) ($my + $y) (C '#ffd36a') }
} }
Px $wl ($mx + 7) ($my - 6) (C '#ffffff'); Px $wl ($mx + 8) ($my - 5) (C '#ffe9a0'); Px $wl ($mx + 6) ($my - 5) (C '#ffe9a0'); Px $wl ($mx + 7) ($my - 4) (C '#ffe9a0')
Px $wl ($mx + 11) ($my + 4) (C '#ffffff')
# ペナント（小さな三角の旗）
for ($x = 10; $x -lt 128; $x++) { $yy = 28 + [int][math]::Round(2 * [math]::Sin(($x - 10) / 118.0 * [math]::PI)); Px $wl $x $yy (C '#3a2a50') }
$pc = @('#27d8ff', '#ff6fcf', '#a688ff', '#4dffc4', '#ffd36a')
for ($i = 0; $i -lt 10; $i++) {
  $x = 14 + $i * 11
  if ($x -gt 40 -and $x -lt 100) { continue }
  $yy = 28 + [int][math]::Round(2 * [math]::Sin(($x - 10) / 118.0 * [math]::PI))
  $c = C $pc[$i % 5]
  Rect $wl ($x - 2) ($yy + 1) 5 1 $c; Rect $wl ($x - 1) ($yy + 2) 3 1 $c; Px $wl $x ($yy + 3) $c
}
Save $wl 'handmade_wall.png'

# =====================================================================
# カウンター（紺のクロス・刺しゅうの帯・金のふさ）124x24
# =====================================================================
$ct = NewBmp 124 24
Rect $ct 0 0 124 9 (C '#2c3ca4')
Rect $ct 0 0 124 1 (C '#7a90f0'); Rect $ct 0 1 124 1 (C '#4a60d0')
for ($x = 0; $x -lt 124; $x += 6) { Px $ct $x 4 (C '#3a4ec0'); Px $ct ($x + 3) 6 (C '#243494') }
# レースのふち
for ($x = 0; $x -lt 124; $x++) { Px $ct $x 9 (C '#e8ecff'); if ($x % 4 -lt 2) { Px $ct $x 10 (C '#c0c8f0') } }
Rect $ct 0 11 124 11 (C '#1a2268')
for ($x = 0; $x -lt 124; $x++) {
  $m = $x % 12
  if ($m -lt 2) { Rect $ct $x 11 1 11 (C '#232e84') } elseif ($m -eq 8 -or $m -eq 9) { Rect $ct $x 11 1 11 (C '#101656') }
}
# 刺しゅうの帯: 星とクラゲ
Rect $ct 0 14 124 1 (C '#ffd36a')
Rect $ct 0 19 124 1 (C '#ffd36a')
for ($i = 0; $i -lt 10; $i++) {
  $x = 6 + $i * 12
  if ($i % 2 -eq 0) {
    Px $ct $x 16 (C '#ffe9a0'); Px $ct ($x - 1) 17 (C '#ffd36a'); Px $ct ($x + 1) 17 (C '#ffd36a'); Px $ct $x 17 (C '#ffe9a0'); Px $ct $x 18 (C '#ffd36a')
  } else {
    Rect $ct ($x - 2) 15 5 1 (C '#ff9ae0'); Rect $ct ($x - 2) 16 5 1 (C '#ff6fcf'); Px $ct ($x - 1) 17 (C '#ff9ae0'); Px $ct ($x + 1) 18 (C '#ff9ae0'); Px $ct ($x - 1) 18 (C '#ff9ae0'); Px $ct $x 17 (C '#ff9ae0')
  }
}
# 金のふさ
for ($x = 0; $x -lt 124; $x += 2) { Px $ct $x 20 (C '#c8962c'); Px $ct $x 21 (C '#ffd36a'); Px $ct $x 22 (C '#c8962c'); if ($x % 4 -eq 0) { Px $ct $x 23 (C '#8a6418') } }
foreach ($p in @(@(0, 0), @(123, 0), @(0, 23), @(123, 23))) { Clear $ct $p[0] $p[1] }
Save $ct 'handmade_counter.png'

# =====================================================================
# 吊るしクラゲ 20x34 6コマ（天幕から糸で吊る。脈打つ）3色
# =====================================================================
function HangJelly($name, $pal, $phase) {
  Sheet $name 20 28 6 {
    param($b, $ox, $f)
    $t = (($f + $phase) % 6) / 6.0 * 2 * [math]::PI
    $p = [math]::Sin($t)
    $bw = [int][math]::Round(12 * (1 - 0.13 * $p)); $bh = [int][math]::Round(7 * (1 + 0.2 * $p))
    $top = 5 + [int][math]::Round(0.8 * [math]::Sin($t + 1.2))
    Line $b ($ox + 10) 0 ($ox + 10) ($top) (C '#8a9ad8')
    Halo $b ($ox + 10) ($top + 4) 10 9 $pal.glow 16
    Jelly $b ($ox + 10) $top $bw $bh $pal 1.15 13 ($t * 1.0) 2.0
    Px $b ($ox + 10) 0 (C '#ffd36a')
  }
}
HangJelly 'handmade_hang_c.png' $PCy 0
HangJelly 'handmade_hang_p.png' $PPk 2
HangJelly 'handmade_hang_v.png' $PVi 4

# =====================================================================
# 浮かぶ大きなクラゲ（ふわふわ・脈打つ）8コマ 3色
# =====================================================================
function DriftJelly($name, $pal, $W, $H, $bw, $bh, $tl, $phase) {
  Sheet $name $W $H 8 {
    param($b, $ox, $f)
    $t = (($f + $phase) % 8) / 8.0 * 2 * [math]::PI
    $p = [math]::Sin($t)
    $w2 = [int][math]::Round($bw * (1 - 0.13 * $p)); $h2 = [int][math]::Round($bh * (1 + 0.17 * $p))
    $top = 4 + [int][math]::Round(2.0 * [math]::Sin($t - 0.9))
    $cx = $ox + [int]($W / 2) + [int][math]::Round(1.0 * [math]::Sin($t * 0.5))
    Halo $b $cx ($top + $h2 / 2) ($bw * 0.75) ($bh * 0.85) $pal.glow 14
    Jelly $b $cx $top $w2 $h2 $pal 0.92 $tl ($t * 1.0) ($bw * 0.16)
  }
}
DriftJelly 'handmade_drift_a.png' $PCy 36 44 20 13 20 0
DriftJelly 'handmade_drift_b.png' $PPk 28 36 16 10 16 3
DriftJelly 'handmade_drift_c.png' $PVi 22 30 12 8 13 6

# =====================================================================
# 泡 20x44 8コマ（ゆっくり上へ）
# =====================================================================
Sheet 'handmade_bubbles.png' 20 44 8 {
  param($b, $ox, $f)
  $bb = @(@(5, 0, 3), @(13, 14, 2), @(8, 26, 2), @(15, 36, 1))
  foreach ($q in $bb) {
    $y = [int][math]::Floor((($q[1] + 44 - $f * 5.5) % 44))
    $x = $ox + $q[0] + [int][math]::Round(1.6 * [math]::Sin($y * 0.25 + $q[0]))
    $r = $q[2]
    $fade = if ($y -lt 6) { 0.5 } else { 1.0 }
    $bp = @{ X = (CA '#c8f6ff' ([int](235 * $fade))); W = (CA '#ffffff' 255) }
    if ($r -ge 3) { Ascii $b ($x - 2) ($y - 2) @('.XXX.', 'XW..X', 'X...X', 'X...X', '.XXX.') $bp }
    elseif ($r -eq 2) { Ascii $b ($x - 1) ($y - 1) @('.XX.', 'XW.X', 'X..X', '.XX.') $bp }
    else { PxO $b $x $y (CA '#e8fbff' ([int](235 * $fade))); PxO $b $x ($y + 1) (CA '#9fe8ff' ([int](200 * $fade))) }
  }
}

# =====================================================================
# 作品: ガラスドームのクラゲランプ 14x22 4コマ（脈打つ）、小瓶のクラゲ 10x18、ろうそく 10x12
# =====================================================================
function DomeLamp($name, $pal, $phase) {
  Sheet $name 14 22 4 {
    param($b, $ox, $f)
    $t = (($f + $phase) % 4) / 4.0 * 2 * [math]::PI
    $p = [math]::Sin($t)
    Halo $b ($ox + 7) 10 8 9 $pal.glow 22
    # 木の台
    Rect $b ($ox + 2) 18 10 3 $wd2; Rect $b ($ox + 2) 18 10 1 $wd3; Rect $b ($ox + 2) 20 10 1 $wd0; Rect $b ($ox + 3) 21 8 1 $wd0
    # ガラスのドーム
    for ($y = 1; $y -lt 18; $y++) {
      $hw = 6.0
      if ($y -lt 7) { $hw = 6.0 * [math]::Sqrt([math]::Max(0.0, 1 - [math]::Pow((7 - $y - 0.5) / 7.0, 2))) }
      $xl = [int][math]::Round(7 - $hw); $xr = [int][math]::Round(7 + $hw) - 1
      for ($x = $xl; $x -le $xr; $x++) {
        $edge = ($x -le $xl) -or ($x -ge $xr) -or ($y -le 1)
        if ($edge) { PxO $b ($ox + $x) $y (CA '#a8e0ff' 230) } else { PxO $b ($ox + $x) $y (CA '#0a1a50' 200) }
      }
    }
    Rect $b ($ox + 3) 3 1 5 (C '#e8f6ff'); Px $b ($ox + 3) 9 (C '#bfe0ff')
    Jelly $b ($ox + 7) (5 + [int][math]::Round(0.6 * $p)) ([int][math]::Round(8 * (1 - 0.12 * $p))) 5 $pal 1.35 7 ($t * 1.0) 1.5
  }
}
DomeLamp 'handmade_lamp_c.png' $PCy 0
DomeLamp 'handmade_lamp_v.png' $PVi 2

function Bottle($name, $pal, $phase) {
  Sheet $name 10 18 4 {
    param($b, $ox, $f)
    $t = (($f + $phase) % 4) / 4.0 * 2 * [math]::PI
    Halo $b ($ox + 5) 11 6 7 $pal.glow 22
    Rect $b ($ox + 3) 0 4 3 (C '#a8744a'); Rect $b ($ox + 3) 0 4 1 (C '#d8a070'); Rect $b ($ox + 3) 2 4 1 (C '#7a4a2a')
    Rect $b ($ox + 3) 3 4 3 (CA '#a8e0ff' 190); Rect $b ($ox + 4) 3 2 3 (CA '#0a1a50' 220)
    Rect $b ($ox + 3) 4 4 1 (C '#ff6fcf')
    for ($y = 6; $y -lt 18; $y++) {
      $hw = 5.0
      if ($y -lt 9) { $hw = 3.0 + ($y - 6) * 0.7 }
      if ($y -ge 16) { $hw = 4.4 }
      $xl = [int][math]::Round(5 - $hw); $xr = [int][math]::Round(5 + $hw) - 1
      for ($x = $xl; $x -le $xr; $x++) {
        $edge = ($x -le $xl) -or ($x -ge $xr) -or ($y -ge 17)
        if ($edge) { PxO $b ($ox + $x) $y (CA '#a8e0ff' 235) } else { PxO $b ($ox + $x) $y (CA '#0a1a50' 215) }
      }
    }
    Rect $b ($ox + 2) 9 1 5 (C '#e8f6ff')
    Px $b ($ox + 4) 16 (C '#e8d8a0'); Px $b ($ox + 6) 16 (C '#c8b080'); Px $b ($ox + 5) 15 (C '#e8d8a0')
    Jelly $b ($ox + 5) (8 + [int][math]::Round(0.7 * [math]::Sin($t))) 6 4 $pal 1.4 5 ($t * 1.0) 1.2
  }
}
Bottle 'handmade_bottle_p.png' $PPk 0
Bottle 'handmade_bottle_c.png' $PMt 2

Sheet 'handmade_candle.png' 10 12 4 {
  param($b, $ox, $f)
  $fx = @(0, 1, 0, -1)[$f]; $fh = @(3, 4, 3, 4)[$f]
  Halo $b ($ox + 5) 4 7 7 '#ffb347' 26
  Rect $b ($ox + 1) 5 8 7 (CA '#c87a3a' 255); Rect $b ($ox + 1) 5 8 1 (C '#e8a860'); Rect $b ($ox + 2) 6 6 1 (C '#fff3d6')
  Rect $b ($ox + 1) 7 8 5 (CA '#6a3a2a' 255); Rect $b ($ox + 2) 8 1 3 (C '#b87850'); Rect $b ($ox + 1) 11 8 1 (C '#3a1c18')
  Rect $b ($ox + 2) 7 6 3 (C '#ffe0b0')
  Px $b ($ox + 5) 5 (C '#3a2a2a'); Px $b ($ox + 5) 4 (C '#3a2a2a')
  Px $b ($ox + 5 + $fx) (4 - $fh + 3) (C '#ff8a3d')
  Rect $b ($ox + 4 + $fx) (5 - $fh) 2 ($fh - 1) (C '#ffb347')
  Px $b ($ox + 5 + $fx) (5 - $fh + 1) (C '#fff0a0'); Px $b ($ox + 5 + $fx) (5 - $fh + 2) (C '#fff0a0')
}

# ガラス玉のお皿 16x9
$bd = NewBmp 16 9
Rect $bd 1 5 14 4 (C '#6a4a6e'); Rect $bd 0 4 16 2 (C '#8e6a8a'); Rect $bd 0 4 16 1 (C '#b8909e'); Rect $bd 2 8 12 1 $wd0
$bc2 = @('#27d8ff', '#ff6fcf', '#a688ff', '#4dffc4', '#ffd36a', '#27d8ff', '#ff6fcf', '#a688ff')
$pos = @(@(2, 3), @(5, 2), @(8, 3), @(11, 2), @(4, 1), @(7, 0), @(10, 1), @(13, 3), @(6, 3), @(9, 1))
$i = 0
foreach ($q in $pos) { $c = C $bc2[$i % 8]; Rect $bd $q[0] $q[1] 3 2 $c; Px $bd $q[0] $q[1] (Mix $c (C '#ffffff') 0.75); $i++ }
Save $bd 'handmade_beads.png'

# 貝・ヒトデ・星のチャームのトレイ 18x9
$sh = NewBmp 18 9
Rect $sh 0 5 18 4 $n3; Rect $sh 0 5 18 1 $n5; Rect $sh 0 8 18 1 $n1
# ホタテ
Ascii $sh 1 1 @('..ppp..', '.pqpqp.', 'pqpqpqp', '.ppppp.', '..ccc..') @{ p = (C '#ffb8d8'); q = (C '#ff8ac0'); c = (C '#e8d8c0') }
# 巻貝
Ascii $sh 8 2 @('..cc..', '.cdcc.', 'cccdcc', '.cdcc.', '..cc..') @{ c = (C '#f4e8d0'); d = (C '#c8a888') }
# ヒトデ
Ascii $sh 13 0 @('..o..', '..o..', 'ooooo', '.ooo.', '.o.o.') @{ o = (C '#ff9a4a') }
Px $sh 15 2 (C '#ffd0a0')
# 星チャーム
Px $sh 17 4 $gld
Save $sh 'handmade_shells.png'

# 刺しゅうのフープ（クラゲ）14x18
$hp = NewBmp 14 18
Line $hp 4 17 7 13 $wd2; Line $hp 10 17 7 13 $wd2; Rect $hp 3 17 8 1 $wd1
Ellipse $hp 7 7 7 7 (C '#8a5a3a')
Ellipse $hp 7 7 6 6 (C '#c8905a')
Ellipse $hp 7 7 5 5 (C '#1a2268')
Px $hp 3 3 (C '#e8b080')
# 刺しゅうのクラゲ
Rect $hp 5 3 5 1 (C '#ff9ae0'); Rect $hp 4 4 7 2 (C '#ff6fcf'); Px $hp 5 4 (C '#ffd0f0')
for ($y = 6; $y -lt 11; $y++) { Px $hp (5 + ($y % 2)) $y (C '#cfe0ff'); Px $hp 7 $y (C '#ff9ae0'); Px $hp (9 - ($y % 2)) $y (C '#cfe0ff') }
Px $hp 3 9 (C '#ffd36a'); Px $hp 11 5 (C '#ffd36a')
Save $hp 'handmade_hoop.png'

# =====================================================================
# 前のテーブル（紺のクロス）52x22
# =====================================================================
$tb = NewBmp 52 22
Rect $tb 0 0 52 8 (C '#34408c'); Rect $tb 0 0 52 1 (C '#7a90f0'); Rect $tb 0 1 52 1 (C '#5068d0')
for ($x = 0; $x -lt 52; $x += 5) { Px $tb $x 4 (C '#4658b8'); Px $tb ($x + 2) 6 (C '#2c3a80') }
for ($x = 0; $x -lt 52; $x++) { Px $tb $x 8 (C '#e8ecff'); if ($x % 4 -lt 2) { Px $tb $x 9 (C '#c0c8f0') } }
Rect $tb 0 10 52 10 (C '#1e2874')
for ($x = 0; $x -lt 52; $x++) { $m = $x % 10; if ($m -lt 2) { Rect $tb $x 10 1 10 (C '#28368c') } elseif ($m -eq 7 -or $m -eq 8) { Rect $tb $x 10 1 10 (C '#121a5a') } }
Rect $tb 0 12 52 1 $gld
for ($i = 0; $i -lt 8; $i++) { $x = 4 + $i * 6; Px $tb $x 15 (C '#ffe9a0'); Px $tb ($x - 1) 16 (C '#ffd36a'); Px $tb ($x + 1) 16 (C '#ffd36a'); Px $tb $x 17 (C '#ffd36a') }
for ($x = 0; $x -lt 52; $x += 2) { Px $tb $x 19 (C '#c8962c'); Px $tb $x 20 (C '#ffd36a') }
for ($x = 1; $x -lt 52; $x += 4) { Px $tb $x 21 (C '#8a6418') }
foreach ($p in @(@(0, 0), @(51, 0))) { Clear $tb $p[0] $p[1] }
Save $tb 'handmade_table.png'

# =====================================================================
# 水槽（クラゲが泳ぐ）36x44 6コマ
# =====================================================================
Sheet 'handmade_tank.png' 36 44 6 {
  param($b, $ox, $f)
  $t = $f / 6.0 * 2 * [math]::PI
  # 台
  Rect $b ($ox + 1) 30 34 14 $wd1; Rect $b ($ox + 1) 30 34 2 $wd3; Rect $b ($ox + 1) 32 34 1 $wd0
  Rect $b ($ox + 3) 34 14 8 $wd2; Rect $b ($ox + 3) 34 14 1 $wd3; Rect $b ($ox + 19) 34 14 8 $wd2; Rect $b ($ox + 19) 34 14 1 $wd3
  Px $b ($ox + 14) 38 $gld; Px $b ($ox + 19) 38 $gld
  Rect $b ($ox + 1) 43 34 1 $wd0
  # 水
  for ($y = 5; $y -lt 30; $y++) { Rect $b ($ox + 3) $y 30 1 (Mix (C '#0e5aa0') (C '#0a1860') (($y - 5) / 24.0)) }
  # 砂と貝
  Rect $b ($ox + 3) 26 30 4 (C '#c9b58a'); Rect $b ($ox + 3) 26 30 1 (C '#e8d8a8'); Rect $b ($ox + 3) 29 30 1 (C '#8a7448')
  foreach ($sx in 6, 15, 27) { Px $b ($ox + $sx) 26 (C '#ffb8d8'); Px $b ($ox + $sx + 1) 26 (C '#ff8ac0') }
  Px $b ($ox + 22) 25 (C '#fff3d6'); Px $b ($ox + 23) 25 (C '#fff3d6')
  # 水草の光る海藻
  for ($y = 18; $y -lt 26; $y++) { Px $b ($ox + 31 + [int][math]::Round([math]::Sin($y * 0.7 + $t))) $y (C '#2ad8a0') }
  # 光のすじ（ゆらぐ）
  for ($y = 5; $y -lt 24; $y++) { PxO $b ($ox + 8 + [int](($y * 0.45 + $f * 0.6) % 4)) $y (CA '#7ff0ff' 48) }
  # クラゲ2匹
  $y1 = 7 + [int][math]::Round(1.6 * [math]::Sin($t - 0.8))
  $p1 = [math]::Sin($t)
  Halo $b ($ox + 15) ($y1 + 5) 11 9 '#27d8ff' 20
  Jelly $b ($ox + 15) $y1 ([int][math]::Round(14 * (1 - 0.12 * $p1))) ([int][math]::Round(8 * (1 + 0.18 * $p1))) $PCy 1.1 9 ($t * 1.0) 2.4
  $y2 = 14 + [int][math]::Round(1.2 * [math]::Sin($t + 2.0))
  $p2 = [math]::Sin($t + 2.4)
  Jelly $b ($ox + 27) $y2 ([int][math]::Round(7 * (1 - 0.12 * $p2))) 4 $PPk 1.2 6 ($t * 1.0 + 1.0) 1.4
  # 泡
  foreach ($bq in @(@(7, 0), @(24, 3), @(19, 5))) {
    $by = 25 - (($f + $bq[1]) % 6) * 4
    if ($by -gt 5) { Px $b ($ox + $bq[0] + (($f + $bq[1]) % 2)) $by (CA '#cff6ff' 220) }
  }
  # ガラスの枠
  Rect $b ($ox + 2) 3 32 2 (C '#2a3a70'); Rect $b ($ox + 2) 3 32 1 (C '#8aa8e8')
  for ($x = 3; $x -lt 33; $x++) { Px $b ($ox + $x) 4 (CA '#d8f4ff' 255) }
  Rect $b ($ox + 2) 3 1 27 (C '#8aa8e8'); Rect $b ($ox + 33) 3 1 27 (C '#5a78c0')
  Rect $b ($ox + 2) 29 32 1 (C '#5a78c0')
  Rect $b ($ox + 4) 6 1 10 (CA '#ffffff' 150); Px $b ($ox + 4) 18 (CA '#ffffff' 120)
  # 照明のすじ（上）
  Rect $b ($ox + 4) 4 28 1 (@((C '#ffffff'), (C '#e8fcff'), (C '#d0f8ff'), (C '#e8fcff'), (C '#ffffff'), (C '#e8fcff'))[$f])
  foreach ($p in @(@(0, 30), @(35, 30))) { Clear $b ($ox + $p[0]) $p[1] }
}

# =====================================================================
# アクセサリー台（星・月・クラゲのチャーム）30x46 4コマ（きらり）
# =====================================================================
Sheet 'handmade_rack.png' 30 46 4 {
  param($b, $ox, $f)
  # 骨組み
  Rect $b ($ox + 3) 4 2 42 $wd2; Rect $b ($ox + 3) 4 1 42 $wd3; Rect $b ($ox + 24) 4 2 42 $wd2; Rect $b ($ox + 24) 4 1 42 $wd3
  Rect $b ($ox + 2) 3 26 2 $wd2; Rect $b ($ox + 2) 3 26 1 $wd3
  Rect $b ($ox + 2) 26 26 2 $wd2; Rect $b ($ox + 2) 26 26 1 $wd3
  Rect $b ($ox + 1) 45 6 1 $wd0; Rect $b ($ox + 23) 45 6 1 $wd0
  Rect $b ($ox + 5) 5 20 20 (CA '#0a1033' 255)
  for ($y = 6; $y -lt 25; $y += 5) { for ($x = 6; $x -lt 24; $x += 6) { Px $b ($ox + $x + ($y % 2) * 2) $y (C '#2a3ca0') } }
  # 上段: ぶらさがるチャーム
  $ch = @(@(8, 'star'), @(14, 'jelly'), @(20, 'moon'))
  foreach ($c in $ch) {
    $x = $ox + $c[0]
    Line $b $x 5 $x 10 (C '#c8c8e0')
    switch ($c[1]) {
      'star' { Px $b $x 11 $gld; Rect $b ($x - 1) 12 3 1 $gld; Px $b ($x - 2) 12 (C '#ffe9a0'); Px $b ($x + 2) 12 (C '#ffe9a0'); Rect $b ($x - 1) 13 3 1 $gld; Px $b ($x - 1) 14 $gld; Px $b ($x + 1) 14 $gld; Px $b $x 12 (C '#ffffff') }
      'jelly' { Rect $b ($x - 2) 11 5 2 $cy; Px $b ($x - 2) 11 (C '#d8feff'); Px $b $x 13 (C '#8ae8ff'); Px $b ($x - 1) 14 (C '#8ae8ff'); Px $b ($x + 1) 14 (C '#8ae8ff'); Px $b $x 15 (C '#8ae8ff') }
      'moon' { Px $b ($x - 1) 11 (C '#ffe9a0'); Px $b $x 11 (C '#ffe9a0'); Px $b ($x - 2) 12 (C '#ffe9a0'); Px $b ($x - 2) 13 (C '#ffe9a0'); Px $b ($x - 2) 14 (C '#ffd36a'); Px $b ($x - 1) 15 (C '#ffd36a'); Px $b $x 15 (C '#ffd36a'); Px $b ($x - 1) 14 (C '#ffe9a0') }
    }
  }
  # 下段: ネックレス（ビーズ）
  foreach ($c in @(@(9, '#ff6fcf'), @(16, '#27d8ff'), @(22, '#a688ff'))) {
    $x = $ox + $c[0]
    Line $b $x 19 $x 22 (C '#c8c8e0')
    Rect $b ($x - 1) 23 3 3 (C $c[1]); Px $b ($x - 1) 23 (C '#ffffff')
  }
  # きらり
  $sx = @(8, 20, 14, 22)[$f]; $sy = @(12, 14, 12, 23)[$f]
  Px $b ($ox + $sx) ($sy - 2) (C '#ffffff'); Px $b ($ox + $sx) ($sy + 2) (C '#ffffff'); Px $b ($ox + $sx - 2) $sy (C '#ffffff'); Px $b ($ox + $sx + 2) $sy (C '#ffffff')
  # 足元の小物台（ボックス）
  Rect $b ($ox + 6) 30 18 15 (C '#1e2874'); Rect $b ($ox + 6) 30 18 1 (C '#5068d0')
  for ($x = 7; $x -lt 24; $x += 3) { Rect $b ($ox + $x) 32 2 2 (@('#27d8ff', '#ff6fcf', '#a688ff', '#4dffc4', '#ffd36a', '#27d8ff')[($x / 3) % 6]) }
  Rect $b ($ox + 6) 36 18 1 (C '#ffd36a')
  for ($x = 8; $x -lt 24; $x += 4) { Px $b ($ox + $x) 39 (C '#ffe9a0'); Px $b ($ox + $x - 1) 40 (C '#ffd36a'); Px $b ($ox + $x + 1) 40 (C '#ffd36a'); Px $b ($ox + $x) 41 (C '#ffd36a') }
}

# =====================================================================
# 月と星の街灯 22x60 4コマ（ほのかにまたたく）
# =====================================================================
Sheet 'handmade_moonlamp.png' 22 60 4 {
  param($b, $ox, $f)
  $ha = @(24, 30, 36, 30)[$f]
  Halo $b ($ox + 10) 14 13 14 '#ffd36a' $ha
  # ポール
  Rect $b ($ox + 9) 22 3 36 $wd2; Rect $b ($ox + 9) 22 1 36 $wd3; Rect $b ($ox + 11) 22 1 36 $wd0
  for ($y = 40; $y -lt 46; $y += 2) { Rect $b ($ox + 9) $y 3 1 (C '#d8c498') }
  Rect $b ($ox + 6) 57 10 2 $wd1; Rect $b ($ox + 6) 57 10 1 $wd2; Rect $b ($ox + 7) 59 8 1 $wd0
  # 三日月
  $mx = 10; $my = 12
  for ($y = -9; $y -le 9; $y++) { for ($x = -9; $x -le 9; $x++) {
    $in1 = ($x * $x + $y * $y) -le 72
    $in2 = (($x - 4) * ($x - 4) + ($y + 1) * ($y + 1)) -le 58
    if ($in1 -and -not $in2) {
      $e = ($x * $x + $y * $y) -gt 56
      Px $b ($ox + $mx + $x) ($my + $y) $(if ($e) { C '#ffd36a' } else { C '#ffeeb0' })
    }
  } }
  Px $b ($ox + 5) 9 (C '#ffffff'); Px $b ($ox + 4) 11 (C '#fff8d8')
  # 星のまたたき
  $st = @(@(18, 6), @(17, 19), @(3, 20))
  for ($i = 0; $i -lt 3; $i++) {
    $on = (($f + $i) % 4)
    $x = $ox + $st[$i][0]; $y = $st[$i][1]
    if ($on -eq 0) { Px $b $x $y (C '#ffffff'); Px $b ($x - 1) $y (C '#ffe9a0'); Px $b ($x + 1) $y (C '#ffe9a0'); Px $b $x ($y - 1) (C '#ffe9a0'); Px $b $x ($y + 1) (C '#ffe9a0') }
    elseif ($on -eq 1 -or $on -eq 3) { Px $b $x $y (C '#ffe9a0') }
  }
  # 小さなクラゲ飾り（ぶら下がり）
  Line $b ($ox + 10) 21 ($ox + 10) 24 (C '#c8c8e0')
}

# =====================================================================
# 提灯の柱（暖色の灯り）16x58 4コマ（ゆらぎ）
# =====================================================================
Sheet 'handmade_lantern.png' 16 58 4 {
  param($b, $ox, $f)
  $gl = @(34, 40, 30, 38)[$f]
  Halo $b ($ox + 8) 14 12 13 '#ff9a3d' $gl
  Rect $b ($ox + 7) 4 2 52 $wd2; Rect $b ($ox + 7) 4 1 52 $wd3; Rect $b ($ox + 8) 4 1 52 $wd0
  Rect $b ($ox + 4) 55 8 2 $wd1; Rect $b ($ox + 4) 55 8 1 $wd2; Rect $b ($ox + 5) 57 6 1 $wd0
  # 提灯
  $c1 = @('#ff8a3d', '#ffa04d', '#ff8030', '#ff9644')[$f]
  Rect $b ($ox + 4) 8 8 2 (C '#2a1c1c')
  for ($y = 10; $y -lt 20; $y++) {
    $hw = 4.0 - [math]::Pow(([math]::Abs($y - 14.5) / 5.5), 2) * 0.0
    $dd = [math]::Abs($y - 14.5) / 5.0
    $hw = 3.2 + 1.6 * (1 - $dd * $dd)
    $xl = [int][math]::Round(8 - $hw); $xr = [int][math]::Round(8 + $hw) - 1
    for ($x = $xl; $x -le $xr; $x++) {
      $col = C $c1
      if ($x -le $xl) { $col = C '#b9421f' } elseif ($x -ge $xr) { $col = C '#c94e24' } elseif ([math]::Abs($x - 7.5) -lt 1.6) { $col = C '#ffd88a' }
      if ($y -eq 13 -or $y -eq 16) { $col = C '#8a2a14' }
      Px $b ($ox + $x) $y $col
    }
  }
  Rect $b ($ox + 5) 20 6 2 (C '#2a1c1c')
  Px $b ($ox + 7) 22 (C '#ffd36a'); Px $b ($ox + 7) 23 (C '#ff9a3d'); Px $b ($ox + 8) 22 (C '#ffd36a')
  Px $b ($ox + 8) 6 (C '#2a1c1c'); Px $b ($ox + 8) 7 (C '#2a1c1c')
}

# =====================================================================
# のぼり旗「夜のクラゲ」16x82
# =====================================================================
$nb = NewBmp 16 82
Rect $nb 0 2 16 2 $wd2; Rect $nb 0 2 2 80 $wd3; Rect $nb 0 1 2 81 (C '#b8909e')
Rect $nb 2 4 13 74 (C '#10185c')
Rect $nb 2 4 13 1 (C '#3df5ff'); Rect $nb 2 4 1 74 (C '#3df5ff'); Rect $nb 14 4 1 74 (C '#a688ff')
for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Rect $nb (2 + $i) 78 1 3 (C '#10185c') } }
# クラゲの絵（上）
$script:CX0 = 0; $script:CX1 = 100
Halo $nb 8 11 6 5 '#27d8ff' 40
Jelly $nb 8 7 9 6 $PCy 1.3 5 0.8 1.0
$chars = '夜', 'の', 'ク', 'ラ', 'ゲ'
for ($i = 0; $i -lt 5; $i++) { [void](TextPx $nb $chars[$i] 3 (19 + 11 * $i) 11 (@((C '#fff3d6'), (C '#fff3d6'), (C '#9ff8ff'), (C '#9ff8ff'), (C '#9ff8ff'))[$i]) $false) }
Save $nb 'handmade_nobori.png'
