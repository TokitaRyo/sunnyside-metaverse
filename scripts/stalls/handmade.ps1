# くらげファクトリー（夜の海の底のような工房で、5つの体験ができる）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/handmade.ps1   （リポジトリのルートで実行）
#   一部だけ作り直す: $env:HM_ONLY='sign|bench|pool'; powershell ...（ファイル名の正規表現。全部だと10分以上かかる）
# 出力: client/public/brand/stall/handmade_*.png （配置は scripts/stalls/handmade.mjs）
# 体験: ラテキャンドル作り / キャンドルすくい / ぷるぷる石鹸作り / オイルキーホルダー / スライムキーホルダー
# 夜の海の底のような濃紺・紫の地面に、光るクラゲを飾りにして、5つの体験コーナー（作業台・プール）を並べる。
# アニメは「フレームを横一列に並べたPNG」で、handmade.mjs の k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。
. "$PSScriptRoot\..\lib\pixel.ps1"

# 確認用: HM_ONLY（正規表現）に合う絵だけ作り直す
function Want($n) { return ((-not $env:HM_ONLY) -or ($n -match $env:HM_ONLY)) }

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
  if (-not (Want $name)) { return }
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
if (Want 'handmade_floor') {
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
}

# =====================================================================
# 光だまり（床の上に重ねる半透明の光）192x128。プール・作業台の下
# =====================================================================
if (Want 'handmade_pools') {
$pl = NewBmp 192 128
Halo $pl 36 112 40 15 '#27d8ff' 30     # キャンドルすくいのプール
Halo $pl 150 114 34 13 '#a688ff' 30    # オイルキーホルダー
Halo $pl 96 80 26 8 '#ffb347' 26       # ラテキャンドル（温かい色）
Halo $pl 38 82 28 8 '#ff9ae0' 24       # 石鹸
Halo $pl 154 82 28 8 '#4dffc4' 24      # スライム
Halo $pl 96 108 20 14 '#3dd8ff' 14
Save $pl 'handmade_pools.png'
}

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

# ---- ロゴ文字の飾り（MS Gothic 以外の太いフォントで、グラデーション・二重のふち・光のにじみ・影を付ける）----
# 文字のマスク（点の集合）を作る。$font に太い日本語フォントを渡す
function TextMask($text, $px, $font, $bold) {
  $style = if ($font -like 'BIZ*') { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
  $f = New-Object System.Drawing.Font($font, $px, $style, [System.Drawing.GraphicsUnit]::Pixel)
  $tmp = NewBmp ($px * ($text.Length + 2)) ($px * 2)
  $g = [System.Drawing.Graphics]::FromImage($tmp)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  $g.DrawString($text, $f, [System.Drawing.Brushes]::White, 0, 0, $fmt)
  $g.Dispose()
  $pts = New-Object System.Collections.ArrayList
  $x0 = 9999; $y0 = 9999; $x1 = -1; $y1 = -1
  for ($j = 0; $j -lt $tmp.Height; $j++) { for ($i = 0; $i -lt $tmp.Width; $i++) {
    if ($tmp.GetPixel($i, $j).A -ge 128) { [void]$pts.Add(@($i, $j)); $x0 = [math]::Min($x0, $i); $x1 = [math]::Max($x1, $i); $y0 = [math]::Min($y0, $j); $y1 = [math]::Max($y1, $j) }
  } }
  $tmp.Dispose(); $f.Dispose()
  # 左上を (0,0) に詰めて、点を整数キー（(y+20)*4000+(x+20)）の集合にする
  $set = New-Object 'System.Collections.Generic.HashSet[int]'
  foreach ($p in $pts) { [void]$set.Add(($p[1] - $y0 + 20) * 4000 + ($p[0] - $x0 + 20)); if ($bold) { [void]$set.Add(($p[1] - $y0 + 20) * 4000 + ($p[0] - $x0 + 21)) } }
  return @{ set = $set; w = $x1 - $x0 + 1 + $(if ($bold) { 1 } else { 0 }); h = $y1 - $y0 + 1 }
}
# 縦棒（「ー」を縦書き用に）
function VBarMask($w, $h) {
  $set = New-Object 'System.Collections.Generic.HashSet[int]'
  for ($j = 0; $j -lt $h; $j++) { for ($i = 0; $i -lt $w; $i++) { [void]$set.Add(($j + 20) * 4000 + ($i + 20)) } }
  return @{ set = $set; w = $w; h = $h }
}
function Dil($set, $r, $diamond) {
  $o = New-Object 'System.Collections.Generic.HashSet[int]'
  foreach ($k in $set) {
    for ($dy = -$r; $dy -le $r; $dy++) { for ($dx = -$r; $dx -le $r; $dx++) {
      if ($diamond -and ([math]::Abs($dx) + [math]::Abs($dy)) -gt $r) { continue }
      [void]$o.Add($k + $dy * 4000 + $dx)
    } }
  }
  return $o
}
# ロゴ文字を描く。$ring が $null でなければネオンの外ぶち（太い縁取り）、内側にこい紺のふち。$shine は光が走る位置（なければ -100）
function FxText($b, $m, $x, $y, $topHex, $midHex, $botHex, $ring, $glowHex, $glowA, $shine) {
  $set = $m.set; $H = $m.h
  $d1 = Dil $set 1 $false
  $d2 = Dil $set 2 $true
  $dark = C '#060a26'
  $glow = Dil $set 3 $true
  foreach ($k in $glow) { $px = ($k % 4000) - 20; $py = [int][math]::Floor($k / 4000) - 20; PxO $b ($x + $px) ($y + $py) (CA $glowHex $glowA) }
  # 影（右下へ）
  $base = if ($ring) { $d2 } else { $d1 }
  foreach ($k in $base) { $px = ($k % 4000) - 20 + 1; $py = [int][math]::Floor($k / 4000) - 20 + 2; PxO $b ($x + $px) ($y + $py) (CA '#02041a' 235) }
  if ($ring) { foreach ($k in $d2) { $px = ($k % 4000) - 20; $py = [int][math]::Floor($k / 4000) - 20; PxO $b ($x + $px) ($y + $py) (CC $ring 255) } }
  foreach ($k in $d1) { $px = ($k % 4000) - 20; $py = [int][math]::Floor($k / 4000) - 20; PxO $b ($x + $px) ($y + $py) (CC $dark 255) }
  $ct = C $topHex; $cm = C $midHex; $cb = C $botHex
  foreach ($k in $set) {
    $px = ($k % 4000) - 20; $py = [int][math]::Floor($k / 4000) - 20 - 20 + 20
    $py = [int][math]::Floor($k / 4000) - 20
    $t = if ($H -le 1) { 0.0 } else { $py / [double]($H - 1) }
    $col = if ($t -lt 0.5) { Mix $ct $cm ($t * 2) } else { Mix $cm $cb (($t - 0.5) * 2) }
    if ($py -eq 0) { $col = Mix $col (C '#ffffff') 0.35 }
    if ([math]::Abs(($px + $py * 0.7) - $shine) -lt 2.5) { $col = Mix $col (C '#ffffff') 0.7 }
    PxO $b ($x + $px) ($y + $py) $col
  }
}

# 歯車。中心($cx,$cy)・外半径$r・歯の数$teeth・回転角$ang(ラジアン)
function Gear($b, $cx, $cy, $r, $teeth, $ang, $main, $dk, $hi, $holeCol) {
  $rin = $r - 2.2
  for ($y = [math]::Floor($cy - $r - 1); $y -le [math]::Ceiling($cy + $r + 1); $y++) {
    for ($x = [math]::Floor($cx - $r - 1); $x -le [math]::Ceiling($cx + $r + 1); $x++) {
      $dx = $x + 0.5 - $cx; $dy = $y + 0.5 - $cy
      $dist = [math]::Sqrt($dx * $dx + $dy * $dy)
      $a = [math]::Atan2($dy, $dx)
      $tooth = if ([math]::Cos($teeth * ($a - $ang)) -gt -0.15) { 2.2 } else { 0.0 }
      $lim = $rin + $tooth
      if ($dist -gt $lim) { continue }
      if ($dist -lt $r * 0.34) { PxO $b $x $y $holeCol; continue }
      $col = $main
      if ($dist -gt $lim - 1.0) { $col = $dk }
      elseif (($dx + $dy) -lt -$r * 0.5) { $col = $hi }
      elseif (($dx + $dy) -gt $r * 0.55) { $col = $dk }
      PxO $b $x $y $col
    }
  }
}

# =====================================================================
# 看板「くらげファクトリー」156x38 8コマ。歯車が回り、ネオンのふちが走り、光が文字をなでて、クラゲの触手が垂れる
# =====================================================================
$neon4 = @((C '#3df5ff'), (C '#ff6fcf'), (C '#a688ff'), (C '#4dffc4'))
$FONT = 'BIZ UDPGothic'
$mA = TextMask 'くらげ' 15 $FONT $true
$mB = TextMask 'ファクトリー' 11 $FONT $true
$brass = C '#c8962c'; $brassD = C '#6a4a14'; $brassH = C '#ffe08a'
Sheet 'handmade_sign.png' 164 38 8 {
  param($b, $ox, $f)
  # 板（鉄のわく＋リベット）。下の10pxは触手用に透明のまま
  Rect $b $ox 0 164 28 $n0
  Rect $b ($ox + 1) 1 162 26 (C '#46537e')
  Rect $b ($ox + 1) 1 162 1 (C '#8a9ad0')
  Rect $b ($ox + 2) 2 160 24 (C '#0a0f3a')
  for ($y = 3; $y -lt 25; $y++) { Rect $b ($ox + 3) $y 158 1 (Mix (C '#0e1656') (C '#1c1070') (($y - 3) / 22.0)) }
  # ネオンのふち（色が走る）
  for ($x = 3; $x -lt 161; $x++) {
    $col = $neon4[([int][math]::Floor($x / 9) + $f) % 4]
    Px $b ($ox + $x) 3 $col; Px $b ($ox + $x) 24 $col
    Px $b ($ox + $x) 4 (Mix $col (C '#0a0f3a') 0.65); Px $b ($ox + $x) 23 (Mix $col (C '#0a0f3a') 0.65)
  }
  for ($y = 3; $y -lt 25; $y++) {
    $col = $neon4[([int][math]::Floor($y / 5) + $f + 2) % 4]
    Px $b ($ox + 3) $y $col; Px $b ($ox + 160) $y $col
    Px $b ($ox + 4) $y (Mix $col (C '#0a0f3a') 0.65); Px $b ($ox + 159) $y (Mix $col (C '#0a0f3a') 0.65)
  }
  # リベット（ボルト）
  foreach ($p in @(@(2, 2), @(160, 2), @(2, 24), @(160, 24))) { Rect $b ($ox + $p[0]) $p[1] 2 2 (C '#c8d0f0'); Px $b ($ox + $p[0]) $p[1] (C '#ffffff'); Px $b ($ox + $p[0] + 1) ($p[1] + 1) (C '#5a6a9a') }
  # 歯車（左右で逆回転。8コマで歯1つぶん回って元に戻る）
  $ang = $f * ([math]::PI / 4.0) / 8.0
  Gear $b ($ox + 14) 14 8.5 8 $ang $brass $brassD $brassH (C '#0a0f3a')
  Gear $b ($ox + 149) 14 8.5 8 (0.39 - $ang) $brass $brassD $brassH (C '#0a0f3a')
  # 文字: 大きな「くらげ」＋小さな「ファクトリー」（グラデーション・こい紺のふち・影・光のにじみ）
  $tx = [math]::Floor(82 - ($mA.w + 4 + $mB.w) / 2)
  $shine = -12 + $f * 18
  FxText $b $mA ($ox + $tx) 6 '#9ff8ff' '#c0b0ff' '#ff7fd8' $null '#27d8ff' 40 $shine
  FxText $b $mB ($ox + $tx + $mA.w + 4) (6 + $mA.h - $mB.h) '#ffe0f8' '#ffa8e4' '#c890ff' $null '#ff4fd0' 36 ($shine - $mA.w)
  # 触手（下に垂れる）
  $xs = 8, 21, 34, 47, 60, 73, 86, 99, 112, 125, 138, 150, 156
  $i = 0
  foreach ($x0 in $xs) {
    $L = 5 + (($i * 7) % 5)
    $col = @('#3df5ff', '#ff6fcf', '#a688ff', '#4dffc4')[$i % 4]
    for ($j = 0; $j -lt $L; $j++) {
      $sx = 1.6 * [math]::Sin(($f / 8.0) * 2 * [math]::PI - $j * 0.55 + $i) * ($j / [double]$L)
      PxO $b ($ox + $x0 + [int][math]::Round($sx)) (28 + $j) (CA $col ([int](235 - 150 * $j / $L)))
    }
    $sx = 1.6 * [math]::Sin(($f / 8.0) * 2 * [math]::PI - $L * 0.55 + $i)
    PxO $b ($ox + $x0 + [int][math]::Round($sx)) (28 + $L) (CA '#ffffff' 200)
    $i++
  }
  foreach ($p in @(@(0, 0), @(163, 0), @(0, 27), @(163, 27))) { Clear $b ($ox + $p[0]) $p[1] }
}

# =====================================================================
# 天幕（夜空の縞に星）140x26。ふちはほのかに光る
# =====================================================================
if (Want 'handmade_awning') {
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
}

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
# のぼり旗「くらげファクトリー」26x86（2列の縦書き。下のふちはクラゲの触手）
# =====================================================================
if (Want 'handmade_nobori') {
$nb = NewBmp 26 90
$script:CX0 = 0; $script:CX1 = 100
Rect $nb 0 2 26 2 $wd2; Rect $nb 0 2 2 88 $wd3; Rect $nb 0 1 2 89 (C '#b8909e')
for ($y = 5; $y -lt 80; $y++) { Rect $nb 2 $y 23 1 (Mix (C '#0e1656') (C '#1c1070') (($y - 5) / 74.0)) }
Rect $nb 2 4 23 1 (C '#3df5ff'); Rect $nb 2 4 1 76 (C '#3df5ff'); Rect $nb 24 4 1 76 (C '#a688ff')
for ($i = 0; $i -lt 6; $i++) { Px $nb (4 + $i * 4) 6 (C '#ffd36a') }
# 縦書き: 右の列が「くらげ」、左の列が「ファクトリー」
$cols1 = @('く', 'ら', 'げ')
for ($i = 0; $i -lt 3; $i++) { $m = TextMask $cols1[$i] 11 $FONT; FxText $nb $m 14 (22 + $i * 12) '#8ff6ff' '#a8c8ff' '#e8a8ff' $null '#27d8ff' 18 -100 }
$cols2 = @('フ', 'ァ', 'ク', 'ト', 'リ', 'ー')
for ($i = 0; $i -lt 6; $i++) {
  if ($cols2[$i] -eq 'ー') { $m = VBarMask 2 7; FxText $nb $m 9 (22 + $i * 9 + 1) '#ffb0e8' '#ff8fdc' '#ff6fcf' $null '#ff4fd0' 18 -100 }
  else { $m = TextMask $cols2[$i] 10 $FONT; FxText $nb $m 4 (22 + $i * 9) '#ffc0ee' '#ff9ae0' '#c890ff' $null '#ff4fd0' 18 -100 }
}
# 下に垂れるクラゲ（旗のふち）
Halo $nb 13 79 9 6 '#27d8ff' 36
Jelly $nb 13 74 16 7 $PCy 1.3 9 0.8 1.6
Save $nb 'handmade_nobori.png'
}

# =====================================================================
# 奥の壁（カーテン・柱・星・ペナント）186x50。体験コーナーの後ろに回る
# =====================================================================
if (Want 'handmade_wall') {
$wl = NewBmp 186 50
Rect $wl 6 0 174 50 (C '#0c1244')
for ($x = 6; $x -lt 180; $x++) {
  $m = $x % 9
  if ($m -lt 2) { Rect $wl $x 0 1 49 (C '#141c5c') } elseif ($m -eq 5 -or $m -eq 6) { Rect $wl $x 0 1 49 (C '#080c30') }
}
Rect $wl 6 49 174 1 $n0
$rs = New-Object System.Random 11
for ($i = 0; $i -lt 40; $i++) {
  $x = $rs.Next(8, 178); $y = $rs.Next(24, 47)
  Px $wl $x $y (@((C '#cfe0ff'), (C '#ffd36a'), (C '#8fb0ff'))[$rs.Next(0, 3)])
}
# 柱
foreach ($px in 0, 180) {
  Rect $wl $px 0 6 50 (C '#5a3a50')
  Rect $wl ($px + 1) 0 1 50 (C '#8e6a8a'); Rect $wl ($px + 5) 0 1 50 $wd0; Rect $wl $px 0 1 50 $wd1
  for ($y = 30; $y -lt 36; $y += 2) { Rect $wl $px $y 6 1 (C '#d8c498'); Rect $wl ($px + 1) ($y + 1) 5 1 (C '#a89068') }
  Rect $wl $px 49 6 1 $wd0
}
# ペナント（小さな三角の旗）
for ($x = 8; $x -lt 178; $x++) { $yy = 40 + [int][math]::Round(2 * [math]::Sin(($x - 8) / 170.0 * [math]::PI * 3)); Px $wl $x $yy (C '#3a2a50') }
$pc = @('#27d8ff', '#ff6fcf', '#a688ff', '#4dffc4', '#ffd36a')
for ($i = 0; $i -lt 15; $i++) {
  $x = 14 + $i * 11
  $yy = 40 + [int][math]::Round(2 * [math]::Sin(($x - 8) / 170.0 * [math]::PI * 3))
  $c = C $pc[$i % 5]
  Rect $wl ($x - 2) ($yy + 1) 5 1 $c; Rect $wl ($x - 1) ($yy + 2) 3 1 $c; Px $wl $x ($yy + 3) $c
}
Save $wl 'handmade_wall.png'
}

# =====================================================================
# 体験コーナーの作業台 w x 30。上の面(7行) → レースのふち → 体験名の札(2行) → 金のふさ
# =====================================================================
function BoardText($b, $ox, $bw, $text, $y, $px, $col, $bold) {
  $tw = TextWidth $text $px
  $x = $ox + [int][math]::Floor(($bw - $tw - $(if ($bold) { 1 } else { 0 })) / 2)
  [void](TextPx $b $text $x $y $px $col $bold)
}
# $acc=札の線の色 $top=上の面の布の色 $bd1,$bd2=札の上と下の色
function Bench($name, $bw, $acc, $top, $top2, $bd1, $bd2, $l1, $y1, $p1, $c1, $l2, $y2, $p2, $c2) {
  Sheet $name $bw 35 1 {
    param($b, $ox, $f)
    $A = C $acc
    Rect $b $ox 0 $bw 7 (C $top)
    Rect $b $ox 0 $bw 1 (Mix (C $top) (C '#ffffff') 0.5)
    Rect $b $ox 1 $bw 1 (Mix (C $top) (C '#ffffff') 0.22)
    for ($x = 0; $x -lt $bw; $x += 6) { Px $b ($ox + $x) 3 (C $top2); Px $b ($ox + $x + 3) 5 (C $top2) }
    Rect $b $ox 6 $bw 1 (Mix (C $top) $n1 0.4)
    for ($x = 0; $x -lt $bw; $x++) { Px $b ($ox + $x) 7 (C '#e8ecff'); if ($x % 4 -lt 2) { Px $b ($ox + $x) 8 (C '#c0c8f0') } }
    for ($y = 9; $y -lt 33; $y++) { Rect $b $ox $y $bw 1 (Mix (C $bd1) (C $bd2) (($y - 9) / 23.0)) }
    Rect $b $ox 9 $bw 1 $A
    Rect $b $ox 10 $bw 1 (Mix $A (C $bd1) 0.65)
    for ($x = 0; $x -lt $bw; $x++) { $m = $x % 12; if ($m -lt 1) { Rect $b ($ox + $x) 11 1 22 (Mix (C $bd1) $A 0.12) } }
    Rect $b $ox 33 $bw 1 (Mix $A (C $bd2) 0.55)
    for ($x = 0; $x -lt $bw; $x += 2) { Px $b ($ox + $x) 34 (C '#c8962c'); Px $b ($ox + $x + 1) 34 (C '#ffd36a') }
    BoardText $b $ox $bw $l1 $y1 $p1 (C $c1) $true
    BoardText $b $ox $bw $l2 $y2 $p2 (C $c2) $true
    foreach ($p in @(@(0, 0), @(($bw - 1), 0))) { Clear $b ($ox + $p[0]) $p[1] }
  }
}
Bench 'handmade_bench_latte.png' 66 '#ffd9a0' '#7a5236' '#5a3a28' '#2a1a24' '#150c14' 'ラテ' 11 12 '#fff3d6' 'キャンドル作り' 23 9 '#ffd9a0'
Bench 'handmade_bench_soap.png' 56 '#6fe8ff' '#3a5cc4' '#2a44a0' '#141c5c' '#0a0f3a' 'ぷるぷる' 11 12 '#bff6ff' '石鹸作り' 22 10 '#ffc8ee'
Bench 'handmade_bench_slime.png' 56 '#7dffb0' '#2a8a7a' '#1c6a5c' '#10305a' '#0a1a3a' 'スライム' 11 12 '#c8ffd8' 'キーホルダー' 23 9 '#fff3a0'
Bench 'handmade_bench_oil.png' 56 '#a688ff' '#5a3ab0' '#46308f' '#1c1560' '#0e0a3a' 'オイル' 11 12 '#e0d4ff' 'キーホルダー' 23 9 '#9ff8ff'

# =====================================================================
# 形の部品（星・貝・ハート・丸いキャンドル）
# =====================================================================
# 星（外半径$ro、横の伸び$sx・縦の伸び$sy、$c0=本体 $c1=ハイライト $c2=ふち、$al=濃さ）
function StarShape($b, $cx, $cy, $ro, $sx, $sy, $c0, $c1, $c2, $al) {
  $ri = $ro * 0.52; $seg = 2 * [math]::PI / 5
  for ($y = [math]::Floor($cy - $ro * $sy - 1); $y -le [math]::Ceiling($cy + $ro * $sy + 1); $y++) {
    for ($x = [math]::Floor($cx - $ro * $sx - 1); $x -le [math]::Ceiling($cx + $ro * $sx + 1); $x++) {
      $dx = ($x + 0.5 - $cx) / $sx; $dy = ($y + 0.5 - $cy) / $sy
      $d = [math]::Sqrt($dx * $dx + $dy * $dy)
      $a = [math]::Atan2($dy, $dx) + [math]::PI / 2 + 4 * [math]::PI
      $m = $a % $seg
      $kk = [math]::Abs($m - $seg / 2) / ($seg / 2)
      $rad = $ri + ($ro - $ri) * $kk
      if ($d -le $rad) {
        $col = $c0
        if ($d -gt $rad - 0.9) { $col = $c2 } elseif ((($dx + $dy) -lt (-0.35 * $ro)) -and ($d -gt $ro * 0.15)) { $col = $c1 }
        PxO $b $x $y (CC $col $al)
      }
    }
  }
}
# 貝（ホタテ形の扇。下の中心$cx,$by、半径$r）
function ShellShape($b, $cx, $by, $r, $sx, $sy, $c0, $c1, $c2, $al) {
  for ($y = [math]::Floor($by - $r * $sy - 1); $y -le $by; $y++) {
    for ($x = [math]::Floor($cx - $r * $sx - 1); $x -le [math]::Ceiling($cx + $r * $sx + 1); $x++) {
      $dx = ($x + 0.5 - $cx) / $sx; $dy = ($by - ($y + 0.5)) / $sy
      if ($dy -lt 0) { continue }
      $d = [math]::Sqrt($dx * $dx + $dy * $dy)
      if ($d -gt $r) { continue }
      $ang = [math]::Atan2($dy, $dx)
      $rib = [int][math]::Floor($ang / ([math]::PI / 6)) % 2
      $col = if ($rib -eq 0) { $c0 } else { Mix $c0 $c2 0.45 }
      if ($d -gt $r - 0.9) { $col = $c2 } elseif ($d -lt $r * 0.3) { $col = $c1 }
      PxO $b $x $y (CC $col $al)
    }
  }
}
# 水に浮かぶキャンドル（丸・ハート・星・クラゲ）。中心($cx,$cy)。炎はちらちら
function Cand($b, $cx, $cy, $type, $hex, $f, $ph) {
  $c0 = C $hex; $hi = Mix $c0 (C '#ffffff') 0.55; $dk = Mix $c0 $n1 0.42
  $cx = [int]$cx; $cy = [int]$cy
  EllO $b $cx ($cy + 3) 4.4 1.5 (CA '#06103a' 90)
  $pal = @{ a = $c0; b = $hi; c = $dk }
  $top = 3
  switch ($type) {
    'round' {
      Ellipse $b $cx $cy 3.6 2.6 $c0
      Ellipse $b $cx ($cy + 1) 3.2 1.6 $dk
      Ellipse $b $cx ($cy - 0.4) 3.2 1.9 $c0
      Px $b ($cx - 2) ($cy - 1) $hi; Px $b ($cx - 1) ($cy - 2) $hi
      $top = 3
    }
    'heart' { Ascii $b ($cx - 3) ($cy - 3) @('.aa.aa.', 'abaaaaa', 'aaaaaaa', '.aaaaac', '..aaac.', '...c...') $pal; $top = 3 }
    'star' { Ascii $b ($cx - 3) ($cy - 3) @('...a...', '..aba..', 'aaabaaa', '.aaaaac', '..aaac.', '.aac.ac', '.ac..ac') $pal; $top = 3 }
    'jelly' { Ascii $b ($cx - 3) ($cy - 3) @('..aaa..', '.abaaa.', 'aaaaaac', 'aaaaaac', 'c.a.a.c', '..c.c..') $pal; $top = 3 }
  }
  # 炎
  $fx = @(0, 1, 0, -1)[($f + $ph) % 4]
  $fy = $cy - $top - 1
  PxO $b ($cx + $fx) ($fy - 1) (CA '#fff6c0' 255)
  Px $b ($cx + $fx) $fy (C '#ffb347')
  EllO $b ($cx + $fx) ($fy - 0.5) 3 2.4 (CA '#ffb347' 42)
}

# =====================================================================
# ラテキャンドル作り: ろうの鍋（ゆげ）とピックのカップ 20x17 4コマ、見本のマグ 26x14
# =====================================================================
Sheet 'handmade_latte_pot.png' 20 17 4 {
  param($b, $ox, $f)
  $t = $f / 4.0 * 2 * [math]::PI
  # 温め台
  Rect $b ($ox + 0) 13 12 4 (C '#3a4468'); Rect $b ($ox + 0) 13 12 1 (C '#8a9ad0'); Rect $b ($ox + 1) 16 10 1 (C '#1c2240')
  $fc = @('#ffb347', '#ff8a3d', '#ffd36a', '#ff9a3d')[$f]
  Px $b ($ox + 3) 14 (C $fc); Px $b ($ox + 6) 14 (C '#ffe9a0'); Px $b ($ox + 8) 14 (C $fc)
  # 鍋
  Rect $b ($ox + 1) 6 10 7 (C '#c87a3a'); Rect $b ($ox + 2) 7 1 5 (C '#e8a860'); Rect $b ($ox + 9) 7 2 5 (C '#8a4a28'); Rect $b ($ox + 1) 12 10 1 (C '#6a3a1a')
  Ellipse $b ($ox + 6) 6 5.4 2.4 (C '#e8a860')
  Ellipse $b ($ox + 6) 6 4.4 1.7 (C '#fff3d6')
  Px $b ($ox + 4) 6 (C '#a8744a'); Px $b ($ox + 5) 5 (C '#a8744a'); Px $b ($ox + 6) 6 (C '#a8744a'); Px $b ($ox + 7) 5 (C '#c8a070'); Px $b ($ox + 8) 6 (C '#a8744a')
  # 持ち手
  Rect $b ($ox + 11) 8 3 1 (C '#5a3a28'); Rect $b ($ox + 13) 8 1 3 (C '#5a3a28'); Rect $b ($ox + 11) 10 3 1 (C '#5a3a28')
  # ゆげ
  for ($k = 0; $k -lt 3; $k++) {
    for ($y = 0; $y -lt 4; $y++) {
      $x = 3 + $k * 3 + [int][math]::Round(1.3 * [math]::Sin($t + $k * 1.9 + $y * 0.9))
      PxO $b ($ox + $x) $y (CA '#ffffff' (150 - $y * 28))
    }
  }
  # ピックのカップ
  Rect $b ($ox + 14) 11 6 6 (C '#f4ede0'); Rect $b ($ox + 18) 11 2 6 (C '#c8bca8'); Rect $b ($ox + 14) 16 6 1 (C '#a89c88'); Rect $b ($ox + 14) 13 6 1 (C '#ff9ae0')
  Rect $b ($ox + 15) 4 1 8 (C '#d8b88a'); Px $b ($ox + 15) 3 (C '#7a4a2a')
  Rect $b ($ox + 17) 6 1 6 (C '#e8cfa0'); Px $b ($ox + 17) 5 (C '#fff3d6')
  Rect $b ($ox + 19) 5 1 7 (C '#d8b88a'); Px $b ($ox + 19) 4 (C '#7a4a2a')
}

if (Want 'handmade_latte_mugs') {
$mg = NewBmp 26 14
function Mug($b, $ox, $band, $art) {
  # 本体
  Rect $b ($ox + 1) 6 9 7 (C '#f8f2e6'); Rect $b ($ox + 8) 6 2 7 (C '#c8bca8'); Rect $b ($ox + 1) 12 9 1 (C '#a89c88')
  Rect $b ($ox + 1) 9 9 1 (C $band)
  Ellipse $b ($ox + 5.5) 6 5.4 2.6 (C '#f8f2e6')
  Ellipse $b ($ox + 5.5) 6 4.5 1.9 (C '#7a4a2a')
  # ハンドル
  Rect $b ($ox + 10) 7 2 1 (C '#f8f2e6'); Rect $b ($ox + 11) 8 1 3 (C '#f8f2e6'); Rect $b ($ox + 10) 11 2 1 (C '#c8bca8')
  $cm = C '#fff3d6'; $co = C '#a8744a'
  if ($art -eq 'heart') {
    Px $b ($ox + 3) 4 $cm; Px $b ($ox + 4) 4 $cm; Px $b ($ox + 7) 4 $cm; Px $b ($ox + 8) 4 $cm
    Rect $b ($ox + 3) 5 6 1 $cm; Rect $b ($ox + 4) 6 4 1 $cm; Rect $b ($ox + 5) 7 2 1 $cm
  } else {
    Rect $b ($ox + 4) 4 4 1 $cm; Rect $b ($ox + 3) 5 6 1 $cm; Rect $b ($ox + 3) 6 6 1 $cm; Rect $b ($ox + 4) 7 4 1 $cm
    Rect $b ($ox + 5) 4 1 4 $co; Px $b ($ox + 4) 5 $co; Px $b ($ox + 7) 5 $co; Px $b ($ox + 4) 6 $co; Px $b ($ox + 7) 6 $co
  }
  # しん
  Px $b ($ox + 6) 5 (C '#3a2a2a'); Px $b ($ox + 6) 4 (C '#3a2a2a'); Px $b ($ox + 6) 3 (C '#3a2a2a'); Px $b ($ox + 6) 2 (C '#3a2a2a')
}
Mug $mg 0 '#ff9ae0' 'heart'
Mug $mg 13 '#4dffc4' 'leaf'
Save $mg 'handmade_latte_mugs.png'
}

# =====================================================================
# ぷるぷる石鹸作り: ぷるぷる石鹸（クラゲ・星・貝）24x17 4コマ、混ぜるボウル 16x13 4コマ
# =====================================================================
Sheet 'handmade_soap_jelly.png' 24 17 4 {
  param($b, $ox, $f)
  $t = $f / 4.0 * 2 * [math]::PI
  # ガラスの皿
  EllO $b ($ox + 12) 14.5 11.6 2.3 (CA '#d8ecff' 235)
  EllO $b ($ox + 12) 14 10.4 1.6 (CA '#8ab8f0' 200)
  # クラゲの石鹸（ぷるんと伸び縮み）
  $p1 = [math]::Sin($t)
  $bw = [int][math]::Round(9 * (1 - 0.1 * $p1)); $bh = [int][math]::Round(6 * (1 + 0.16 * $p1))
  Jelly $b ($ox + 6) (13 - $bh - 3) $bw $bh $PCy 1.3 3 ($t * 1.0) 0.6
  # 星の石鹸
  $p2 = [math]::Sin($t + 1.6)
  $sy = 1 + 0.14 * $p2; $sx = 1 - 0.08 * $p2
  StarShape $b ($ox + 14) (13 - 5.0 * $sy * 0.8) 5.0 $sx $sy (C '#ff8fd8') (C '#ffd8f4') (C '#d855b8') 235
  # 貝の石鹸
  $p3 = [math]::Sin($t + 3.2)
  ShellShape $b ($ox + 20) 13.5 4.8 (1 - 0.08 * $p3) (1 + 0.15 * $p3) (C '#b79cff') (C '#e4d8ff') (C '#7a56d8') 235
  Px $b ($ox + 19) 9 (CA '#ffffff' 255); Px $b ($ox + 13) 9 (CA '#ffffff' 255); Px $b ($ox + 5) 9 (CA '#ffffff' 255)
}

Sheet 'handmade_soap_bowl.png' 16 13 4 {
  param($b, $ox, $f)
  $t = $f / 4.0 * 2 * [math]::PI
  # 本体
  for ($y = 6; $y -lt 12; $y++) {
    $hw = 7.0 - ($y - 6) * 0.55
    $xl = [int][math]::Round(8 - $hw); $xr = [int][math]::Round(8 + $hw) - 1
    Rect $b ($ox + $xl) $y ($xr - $xl + 1) 1 (C '#e8eaff')
    Px $b ($ox + $xr) $y (C '#a8aee0'); Px $b ($ox + $xr - 1) $y (C '#b8bee8')
  }
  Rect $b ($ox + 4) 11 8 1 (C '#8a90c8')
  Rect $b ($ox + 2) 9 11 1 (C '#ff9ae0')
  Ellipse $b ($ox + 8) 6 7.2 2.4 (C '#f4f6ff')
  Ellipse $b ($ox + 8) 6 6.0 1.8 (C '#ffb8e8')
  # さざなみ
  $r = 1.2 + ($f % 4) * 1.1
  for ($a = 0; $a -lt 16; $a++) { $an = $a / 16.0 * 2 * [math]::PI; PxO $b ($ox + 8 + [int][math]::Round($r * 1.6 * [math]::Cos($an))) (6 + [int][math]::Round($r * 0.55 * [math]::Sin($an))) (CA '#fff0fa' 200) }
  Px $b ($ox + 5) 5 (C '#ffe8f8'); Px $b ($ox + 11) 6 (C '#ffe8f8')
  # 泡立て器
  $wx = 12 + [int][math]::Round(1.2 * [math]::Cos($t)); $wy = 6 + [int][math]::Round(0.6 * [math]::Sin($t))
  Line $b ($ox + 13) 0 ($ox + $wx - 1) ($wy - 1) (C '#c8a070')
  Line $b ($ox + 14) 0 ($ox + $wx) ($wy - 1) (C '#e8c898')
  Px $b ($ox + $wx - 1) $wy (C '#e8f0ff'); Px $b ($ox + $wx) $wy (C '#c8d0f0'); Px $b ($ox + $wx - 2) ($wy) (C '#e8f0ff')
}

# =====================================================================
# スライムキーホルダー: スライムのボウル 18x14 6コマ、色の素のボトルと瓶の棚 22x20 4コマ
# =====================================================================
Sheet 'handmade_slime_bowl.png' 18 14 6 {
  param($b, $ox, $f)
  $t = $f / 6.0 * 2 * [math]::PI
  # ボウルのうしろのふち
  Ellipse $b ($ox + 9) 8 8.2 2.6 (C '#e6f0ff')
  Ellipse $b ($ox + 9) 8 7.0 1.9 (C '#2a3a9a')
  # 棒
  $tx = 10 + [int][math]::Round(1.6 * [math]::Cos($t))
  Line $b ($ox + 14) 0 ($ox + $tx) 6 (C '#c8a070')
  Line $b ($ox + 15) 0 ($ox + $tx + 1) 6 (C '#e8c898')
  # スライム（盛り上がりがゆれる）
  $rise = 3.0 + 0.9 * [math]::Sin($t)
  EllO $b ($ox + 8.5) (8 - $rise * 0.5) 6.6 $rise (CA '#ff9ad8' 255)
  EllO $b ($ox + 8.0) (8 - $rise * 0.7) 4.2 ($rise * 0.55) (CA '#ffc0ec' 255)
  EllO $b ($ox + 6.5) (8 - $rise * 0.95) 1.8 1.0 (CA '#fff0fa' 255)
  # ラメ
  $gp = @(@(5, 3), @(9, 2), @(12, 4), @(7, 5), @(11, 6), @(4, 6))
  $i = 0
  foreach ($q in $gp) { if ((($f + $i) % 3) -eq 0) { PxO $b ($ox + $q[0]) $q[1] (CA '#ffffff' 255) } elseif ((($f + $i) % 3) -eq 1) { PxO $b ($ox + $q[0]) $q[1] (CA '#fff8a0' 220) }; $i++ }
  # ボウル本体
  for ($y = 8; $y -lt 13; $y++) {
    $hw = 8.0 - ($y - 8) * 0.7
    $xl = [int][math]::Round(9 - $hw); $xr = [int][math]::Round(9 + $hw) - 1
    Rect $b ($ox + $xl) $y ($xr - $xl + 1) 1 (C '#3a56c8')
    Px $b ($ox + $xl + 1) $y (C '#6a8aff'); Px $b ($ox + $xr) $y (C '#22348a'); Px $b ($ox + $xr - 1) $y (C '#2a3fa0')
  }
  Rect $b ($ox + 4) 13 10 1 (C '#1c2a70')
  Rect $b ($ox + 2) 8 14 1 (C '#e6f0ff')
  Rect $b ($ox + 4) 10 10 1 (C '#ffd36a')
}

Sheet 'handmade_slime_shelf.png' 22 20 4 {
  param($b, $ox, $f)
  # 棚（柱と板）
  Rect $b ($ox + 0) 2 1 18 (C '#6a4a6e'); Rect $b ($ox + 21) 2 1 18 (C '#46304e')
  Rect $b ($ox + 0) 9 22 2 (C '#8e6a8a'); Rect $b ($ox + 0) 9 22 1 (C '#b8909e')
  Rect $b ($ox + 0) 18 22 2 (C '#8e6a8a'); Rect $b ($ox + 0) 18 22 1 (C '#b8909e'); Rect $b ($ox + 0) 19 22 1 (C '#46304e')
  # 上の段: 色の素のボトル（スポイト付き）
  $bt = @(@(3, '#ff7fcf'), @(10, '#4dffc4'), @(17, '#a688ff'))
  foreach ($q in $bt) {
    $x = $ox + $q[0]; $c = C $q[1]
    Rect $b ($x - 1) 4 3 5 (Mix $c $n1 0.25); Rect $b ($x - 1) 4 1 5 $c; Px $b ($x - 1) 4 (Mix $c (C '#ffffff') 0.6)
    Rect $b ($x - 1) 3 3 1 (C '#f4f6ff'); Rect $b $x 1 1 2 (C '#f4f6ff'); Px $b $x 0 (C '#d8e0ff')
  }
  # 下の段: 小さな瓶のスライム（ラメが光る）
  $jr = @(@(3, '#ff9ad8'), @(10, '#7dffd0'), @(17, '#b79cff'))
  $i = 0
  foreach ($q in $jr) {
    $x = $ox + $q[0]; $c = C $q[1]
    Rect $b ($x - 2) 11 5 7 (Mix $c $n1 0.2); Rect $b ($x - 2) 11 1 7 (Mix $c (C '#ffffff') 0.5); Rect $b ($x + 2) 11 1 7 (Mix $c $n1 0.45)
    Rect $b ($x - 2) 10 5 1 (C '#d8e0ff'); Rect $b ($x - 1) 9 3 1 (C '#c8d0f0'); Px $b $x 8 (C '#ffd36a'); Px $b ($x + 1) 7 (C '#ffd36a')
    $st = ($f + $i) % 4
    if ($st -eq 0) { Px $b ($x) 14 (C '#ffffff'); Px $b ($x - 1) 14 (CA '#ffffff' 150); Px $b ($x + 1) 14 (CA '#ffffff' 150); Px $b $x 13 (CA '#ffffff' 150); Px $b $x 15 (CA '#ffffff' 150) }
    elseif ($st -eq 2) { Px $b ($x + 1) 16 (C '#fff8a0') }
    $i++
  }
}

# =====================================================================
# オイルキーホルダー: キーホルダーの展示台 28x24 6コマ、素材（オイル・ラメ・ビーズ）26x15 4コマ
# =====================================================================
Sheet 'handmade_oil_display.png' 28 20 6 {
  param($b, $ox, $f)
  $t = $f / 6.0 * 2 * [math]::PI
  # わく
  Rect $b ($ox + 0) 2 1 18 (C '#6a4a6e'); Rect $b ($ox + 27) 2 1 18 (C '#46304e')
  Rect $b ($ox + 0) 0 28 2 (C '#8e6a8a'); Rect $b ($ox + 0) 0 28 1 (C '#b8909e')
  Rect $b ($ox + 0) 17 28 3 (C '#8e6a8a'); Rect $b ($ox + 0) 17 28 1 (C '#b8909e'); Rect $b ($ox + 0) 19 28 1 (C '#46304e')
  # 4つのオイルキーホルダー（液体の中でラメ・星・ビーズがゆっくり動く）
  $ks = @(
    @('#3d9bff', '#ffe08a', 'star'),
    @('#ff7fcf', '#ffe8f8', 'heart'),
    @('#9a6bff', '#e0e8ff', 'glit'),
    @('#4dffc4', '#ffd36a', 'bead')
  )
  for ($i = 0; $i -lt 4; $i++) {
    $c = C $ks[$i][0]; $pc = C $ks[$i][1]; $kind = $ks[$i][2]
    $x0 = $ox + 1 + 7 * $i
    $sw = [int][math]::Round(0.5 * [math]::Sin($t + $i))
    Px $b ($x0 + 3) 2 (C '#e8f0ff'); Px $b ($x0 + 2) 3 (C '#c8d0f0'); Px $b ($x0 + 3) 4 (C '#e8f0ff')
    $cx0 = $x0 + $sw
    # ケース（透明アクリル）
    Rect $b $cx0 5 6 12 (CC (Mix $c $n1 0.25) 230)
    Rect $b ($cx0 + 1) 7 4 9 (CC $c 215)
    Rect $b $cx0 5 6 1 (C '#e8f6ff'); Rect $b $cx0 16 6 1 (C '#8ab0e8'); Rect $b $cx0 5 1 12 (C '#e8f6ff'); Rect $b ($cx0 + 5) 5 1 12 (C '#6a88c8')
    Rect $b ($cx0 + 2) 5 2 2 (C '#c8d0f0'); Px $b ($cx0 + 3) 5 (C '#4a5a8a')
    Rect $b ($cx0 + 1) 8 1 4 (CA '#ffffff' 170)
    # 中身（ゆっくり上下・ゆれる）
    for ($k = 0; $k -lt 4; $k++) {
      $py = 10.5 + 2.6 * [math]::Sin($t + $k * 1.7 + $i)
      $px = 1.5 + 2.0 * (0.5 + 0.5 * [math]::Sin($t + $k * 2.3 + $i * 0.8))
      $xx = $cx0 + [int][math]::Round($px); $yy = [int][math]::Round($py)
      if ($kind -eq 'star' -and $k -lt 2) { Px $b $xx $yy $pc; Px $b ($xx - 1) $yy (CC $pc 200); Px $b ($xx + 1) $yy (CC $pc 200); Px $b $xx ($yy - 1) (CC $pc 200); Px $b $xx ($yy + 1) (CC $pc 200) }
      elseif ($kind -eq 'heart' -and $k -lt 2) { Px $b $xx $yy $pc; Px $b ($xx + 1) $yy $pc; Px $b ($xx - 1) ($yy - 1) (CC $pc 220); Px $b ($xx + 1) ($yy - 1) (CC $pc 220) }
      elseif ($kind -eq 'bead') { Px $b $xx $yy (@((C '#ffd36a'), (C '#ff6fcf'), (C '#ffffff'), (C '#a688ff'))[$k]) }
      else { Px $b $xx $yy $pc }
    }
  }
}

Sheet 'handmade_oil_mats.png' 26 15 4 {
  param($b, $ox, $f)
  # オイルのボトル（2本）
  $ob = @(@(0, '#3d9bff'), @(6, '#ff7fcf'))
  foreach ($q in $ob) {
    $x = $ox + $q[0]; $c = C $q[1]
    Rect $b ($x + 1) 0 3 2 (C '#c8a070'); Rect $b ($x + 1) 0 3 1 (C '#e8c898')
    Rect $b ($x + 1) 2 3 2 (CC (Mix $c $n1 0.2) 230)
    Rect $b $x 4 5 10 (CC (Mix $c $n1 0.25) 235); Rect $b $x 4 1 10 (Mix $c (C '#ffffff') 0.55); Rect $b ($x + 4) 4 1 10 (Mix $c $n1 0.5)
    Rect $b ($x + 1) 7 3 1 (C '#f4f6ff'); Rect $b $x 13 5 1 (Mix $c $n1 0.55)
    Px $b ($x + 1) 5 (C '#ffffff')
  }
  # ラメの瓶（きらきら）
  Rect $b ($ox + 12) 7 7 7 (C '#2a3a8a'); Rect $b ($ox + 12) 7 1 7 (C '#8aa8e8'); Rect $b ($ox + 18) 7 1 7 (C '#1c2a70')
  Rect $b ($ox + 11) 5 9 2 (C '#ffd36a'); Rect $b ($ox + 11) 5 9 1 (C '#ffe9a0')
  Rect $b ($ox + 13) 10 5 3 (C '#c8d0f0')
  $gl = @(@(14, 8), @(16, 9), @(15, 11), @(17, 12), @(13, 12))
  $i = 0
  foreach ($q in $gl) { if ((($f + $i) % 4) -eq 0) { Px $b ($ox + $q[0]) $q[1] (C '#ffffff') } else { Px $b ($ox + $q[0]) $q[1] (C @('#ffd36a', '#8fe8ff', '#ff9ae0', '#e0e8ff')[(($f + $i) % 4)]) }; $i++ }
  # ビーズのお皿
  Ellipse $b ($ox + 22.5) 11 3.6 2.4 (C '#e8e0ff')
  Ellipse $b ($ox + 22.5) 11 2.8 1.6 (C '#8a7ac8')
  $bd = @(@(21, 10, '#ff6fcf'), @(23, 10, '#27d8ff'), @(22, 11, '#ffd36a'), @(24, 11, '#4dffc4'), @(21, 12, '#a688ff'), @(23, 12, '#ffffff'))
  foreach ($q in $bd) { Px $b ($ox + $q[0]) $q[1] (C $q[2]) }
  Rect $b ($ox + 19) 14 7 1 (C '#5a4a8a')
}

# =====================================================================
# キャンドルすくい: 水を張った浅いプール 64x44 8コマ（水面がゆれて光り、小さなキャンドルがぷかぷか浮かぶ）
#   上の6行はふちに置いたポイ・網・カップ、下の札に体験名
# =====================================================================
$cdl = @(
  @(10, 17, 'round', '#ff6fcf', 0),
  @(21, 14, 'heart', '#ff4f6f', 2),
  @(33, 18, 'star', '#ffd36a', 4),
  @(47, 15, 'jelly', '#4de8ff', 6),
  @(55, 19, 'round', '#4dffc4', 1),
  @(38, 12, 'heart', '#b090ff', 5)
)
Sheet 'handmade_pool.png' 64 48 8 {
  param($b, $ox, $f)
  $t = $f / 8.0 * 2 * [math]::PI
  # 水（上が明るく、下が深い）
  for ($y = 9; $y -lt 23; $y++) { Rect $b ($ox + 4) $y 56 1 (Mix (C '#43b6ff') (C '#1c5ad0') (($y - 9) / 13.0)) }
  Rect $b ($ox + 4) 9 56 1 (C '#1a50b8')
  # ゆれる光の筋（さざなみ）
  for ($r = 0; $r -lt 4; $r++) {
    $yy = 11 + $r * 3
    for ($x = 4; $x -lt 60; $x++) {
      if ((($x + $f * 2 + $r * 5) % 13) -lt 4) { PxO $b ($ox + $x) ($yy + [int][math]::Round(0.6 * [math]::Sin($x * 0.4 + $t))) (CA '#a8e8ff' 120) }
    }
  }
  # きらめき（水面のつぶ）
  foreach ($q in @(@(8, 12), @(25, 19), @(41, 14), @(52, 11), @(16, 21), @(46, 20), @(31, 11))) {
    $st = ($f + $q[0]) % 8
    if ($st -eq 0) { Px $b ($ox + $q[0]) $q[1] (C '#ffffff'); PxO $b ($ox + $q[0] - 1) $q[1] (CA '#e8fcff' 200); PxO $b ($ox + $q[0] + 1) $q[1] (CA '#e8fcff' 200) }
    elseif ($st -eq 1 -or $st -eq 7) { PxO $b ($ox + $q[0]) $q[1] (CA '#e8fcff' 190) }
  }
  # 浮かぶキャンドル
  foreach ($q in $cdl) {
    $cx = $q[0] + [math]::Round(1.2 * [math]::Sin($t + $q[4] * 0.9))
    $cy = $q[1] + [math]::Round(0.8 * [math]::Cos($t * 1.0 + $q[4] * 1.3))
    Cand $b ($ox + $cx) $cy $q[2] $q[3] $f $q[4]
  }
  # ふち（奥・左右・手前）
  Rect $b ($ox + 1) 6 62 1 (C '#ffffff'); Rect $b ($ox + 1) 7 62 1 (C '#d0e0ff'); Rect $b ($ox + 1) 8 62 1 (C '#8aa8e0')
  Rect $b ($ox + 0) 7 4 18 (C '#c8d8f8'); Rect $b ($ox + 60) 7 4 18 (C '#c8d8f8')
  Rect $b ($ox + 0) 7 1 18 (C '#8aa8e0'); Rect $b ($ox + 63) 7 1 18 (C '#7090d0')
  Rect $b ($ox + 3) 9 1 14 (C '#f4f8ff'); Rect $b ($ox + 60) 9 1 14 (C '#8aa8e0')
  Rect $b ($ox + 1) 23 62 1 (C '#f4f8ff'); Rect $b ($ox + 0) 24 64 1 (C '#c8d8f8')
  # 手前の札（水色のかべ）
  for ($y = 25; $y -lt 46; $y++) { Rect $b $ox $y 64 1 (Mix (C '#143c9c') (C '#0a1a5a') (($y - 25) / 20.0)) }
  Rect $b $ox 25 64 1 (C '#6fe8ff'); Rect $b $ox 26 64 1 (C '#2a6ad0')
  for ($x = 0; $x -lt 64; $x += 12) { Rect $b ($ox + $x) 27 1 18 (C '#1a50b8') }
  Rect $b $ox 45 64 1 (C '#6fe8ff')
  for ($x = 0; $x -lt 64; $x += 2) { Px $b ($ox + $x) 46 (C '#c8962c'); Px $b ($ox + $x + 1) 46 (C '#ffd36a'); Px $b ($ox + $x) 47 (C '#8a6418') }
  BoardText $b $ox 64 'キャンドル' 26 10 (C '#bff6ff') $true
  BoardText $b $ox 64 'すくい' 36 10 (C '#fff3a0') $true
  # ふちに置いた道具: ポイ（輪と紙）、網、すくったキャンドルの入ったカップ2つ
  # ポイ
  for ($y = 0; $y -le 6; $y++) { for ($x = 3; $x -le 13; $x++) {
    $dx = ($x + 0.5 - 8) / 5.2; $dy = ($y + 0.5 - 3.4) / 3.0; $dd = $dx * $dx + $dy * $dy
    if ($dd -le 1.0 -and $dd -gt 0.55) { Px $b ($ox + $x) $y (C '#ff6fcf') } elseif ($dd -le 0.55) { PxO $b ($ox + $x) $y (CA '#f4faff' 170) }
  } }
  Line $b ($ox + 13) 3 ($ox + 19) 5 (C '#e8c898')
  # 網
  for ($y = 0; $y -le 6; $y++) { for ($x = 22; $x -le 32; $x++) {
    $dx = ($x + 0.5 - 27) / 5.2; $dy = ($y + 0.5 - 3.4) / 3.0; $dd = $dx * $dx + $dy * $dy
    if ($dd -le 1.0 -and $dd -gt 0.6) { Px $b ($ox + $x) $y (C '#c8d0f0') } elseif ($dd -le 0.6 -and (($x + $y) % 2) -eq 0) { Px $b ($ox + $x) $y (C '#8aa8e0') }
  } }
  Line $b ($ox + 32) 3 ($ox + 37) 5 (C '#c8a070')
  # カップ
  foreach ($cxx in 49, 57) {
    Rect $b ($ox + $cxx - 3) 2 7 1 (C '#ffffff')
    for ($y = 3; $y -le 6; $y++) { Rect $b ($ox + $cxx - 3 + [int][math]::Floor(($y - 3) / 2)) $y (7 - 2 * [int][math]::Floor(($y - 3) / 2)) 1 (C '#f4f8ff') }
    Rect $b ($ox + $cxx - 2) 4 5 1 (C '#4aa8ff')
    Px $b ($ox + $cxx + 3) 3 (C '#a8c0e8')
  }
  Px $b ($ox + 48) 1 (C '#ff6fcf'); Px $b ($ox + 49) 1 (C '#ff9ae0'); Px $b ($ox + 49) 0 (C '#ffd36a')
  Px $b ($ox + 57) 1 (C '#ffd36a'); Px $b ($ox + 56) 1 (C '#ffe9a0'); Px $b ($ox + 57) 0 (C '#ffffff')
  foreach ($p in @(@(0, 6), @(63, 6), @(0, 24), @(63, 24))) { Clear $b ($ox + $p[0]) $p[1] }
}
