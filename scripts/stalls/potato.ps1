# ポテト屋台（フライドポテト）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/potato.ps1   （リポジトリのルートで）
# 出力: client/public/brand/stall/potato_*.png（原点は各スプライトの足元。配置は scripts/stalls/potato.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（ファストフード風: 赤 x 黄。ほかの屋台より、黄色と銀色のフライヤーが主役）
$pr0 = C '#6e1220'; $pr1 = C '#c91f2b'; $pr2 = C '#e8383a'; $pr3 = C '#ff7a64'
$py0 = C '#c47a0c'; $py1 = C '#f7b81c'; $py2 = C '#ffd84a'; $py3 = C '#fff2a8'
$fry1 = C '#f0a826'; $fry2 = C '#ffd25a'; $fry3 = C '#c97a14'; $fry4 = C '#8f520e'
$sk0 = C '#7a4a24'; $sk1 = C '#b4814a'; $sk2 = C '#d6ad74'
$st0 = C '#6b7587'; $st1 = C '#a9b3c4'; $st2 = C '#dbe3ee'; $st3 = C '#f4f8fc'
$oil1 = C '#e49a14'; $oil2 = C '#f5bd3c'; $oil3 = C '#ffe08a'
$ketch = C '#d3261f'; $ketchHi = C '#ff6a52'
$paper = C '#f6f0dc'; $paper2 = C '#d9ceb0'
$salt = C '#f4f6fa'; $nori = C '#3d9a46'; $nori2 = C '#7ed27a'; $cons = C '#b8601c'; $cons2 = C '#e39a46'
$bur1 = C '#c9a46a'; $bur2 = C '#a47e44'; $bur3 = C '#e0c590'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# ---- 小さな道具
function Blit($dst, $src, $x, $y) {
  for ($j = 0; $j -lt $src.Height; $j++) { for ($i = 0; $i -lt $src.Width; $i++) { $p = $src.GetPixel($i, $j); if ($p.A -gt 0) { Px $dst ($x + $i) ($y + $j) $p } } }
}
# まわりに1pxのふちを付けた新しい絵を返す（元の絵は破棄する）
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
# 文字に影（ふち）を付けて貼る: 暗い色を右下にずらして先に貼る
function TextShadow($b, $text, $x, $y, $px, $col, $shadow, $bold) {
  [void](TextPx $b $text ($x + 1) ($y + 1) $px $shadow $bold)
  [void](TextPx $b $text ($x - 1) $y $px $shadow $bold)
  [void](TextPx $b $text $x ($y - 1) $px $shadow $bold)
  [void](TextPx $b $text $x ($y + 1) $px $shadow $bold)
  return (TextPx $b $text $x $y $px $col $bold)
}

# ---- フライドポテトの束（スティックが扇形に立つ）。底が下の辺。$top があれば、上のほうに味付けの粒を散らす
function FryBunch($w, $h, $seed, $top) {
  $b = NewBmp $w $h
  $n = [int][math]::Floor(($w - 1) / 1.6)
  $c = ($w - 2) / 2.0
  $order = @(0..($n - 1) | Sort-Object { -[math]::Abs($_ - ($n - 1) / 2.0) })
  foreach ($i in $order) {
    $x = $i * ($w - 3) / [math]::Max(1, $n - 1)
    $off = ($x - $c) / [math]::Max(1, $c)
    $len = $h - 1 - [math]::Abs($off) * ($h * 0.35) - (($i * 5 + $seed * 3) % 3)
    $x1 = $x + $off * ($h * 0.25)
    $y1 = ($h - 1) - $len
    $dark = ((($i + $seed) % 3) -eq 0)
    $cA = if ($dark) { $fry1 } else { $fry2 }
    $cB = if ($dark) { $fry3 } else { $fry1 }
    Line $b ([int][math]::Round($x)) ($h - 1) ([int][math]::Round($x1)) ([int][math]::Round($y1)) $cA
    Line $b ([int][math]::Round($x + 1)) ($h - 1) ([int][math]::Round($x1 + 1)) ([int][math]::Round($y1)) $cB
    if (((($i * 3) + $seed) % 4) -eq 0) { Px $b ([int][math]::Round($x1 + 1)) ([int][math]::Round($y1)) $fry4 }
  }
  if ($top) {
    for ($j = 0; $j -lt [math]::Floor($h * 0.6); $j++) {
      for ($i = 0; $i -lt $w; $i++) {
        if ($b.GetPixel($i, $j).A -gt 0 -and ((($i * 7) + ($j * 13) + $seed) % 5) -eq 0) { Px $b $i $j $top }
      }
    }
  }
  return $b
}
# 紙カップ（上が広い台形。赤に黄色の帯）。x,y は左上、w は上の幅
function CupBody($b, $x, $y, $w, $h, $band) {
  for ($r = 0; $r -lt $h; $r++) {
    $t = $r / [math]::Max(1, ($h - 1)); $ins = [int][math]::Round($t * 1.6)
    for ($xx = $ins; $xx -lt $w - $ins; $xx++) {
      $col = $pr1
      if ($r -eq 0 -or $r -eq $h - 1 -or $xx -eq $ins -or $xx -eq $w - 1 - $ins) { $col = $ol }
      elseif ($r -eq 1) { $col = $pr3 }
      elseif ($xx -eq $ins + 1) { $col = $pr2 }
      elseif ($xx -eq $w - 2 - $ins) { $col = $pr0 }
      $bandY = [int][math]::Floor($h * 0.4)
      if ($band -and $r -ge $bandY -and $r -lt $bandY + 3 -and $col -ne $ol) { $col = $py1; if ($r -eq $bandY) { $col = $py2 } elseif ($r -eq $bandY + 2) { $col = $py0 } }
      Px $b ($x + $xx) ($y + $r) $col
    }
  }
}
# 紙カップに入ったポテト。幅 $w+2、高さ $fh+$ch のおよそ。戻り値は新しい絵
function FryCup($w, $fh, $ch, $seed, $top) {
  $bunch = FryBunch ($w - 2) $fh $seed $top
  $o = OutlineBmp $bunch $ol
  $bmp = NewBmp ($w + 2) ($fh + $ch + 3)
  Blit $bmp $o 0 0
  $o.Dispose()
  CupBody $bmp 1 ($fh) $w $ch $true
  return $bmp
}
# いも1個（ふちつき）。cx,cy は中心
function Potato($b, $cx, $cy, $rx, $ry) {
  Ellipse $b $cx $cy ($rx + 0.9) ($ry + 0.9) $ol
  Ellipse $b $cx $cy $rx $ry $sk1
  Ellipse $b ($cx - $rx * 0.2) ($cy - $ry * 0.25) ($rx * 0.6) ($ry * 0.5) $sk2
  for ($i = 0; $i -lt 3; $i++) { Px $b ($cx + $rx * (0.1 * $i + 0.1)) ($cy + $ry * (0.2 * $i - 0.1)) $sk0 }
  Px $b ($cx + $rx * 0.45) ($cy + $ry * 0.55) $sk0; Px $b ($cx - $rx * 0.5) ($cy + $ry * 0.4) $sk0
}
# らせんポテト（トルネード）。cx は中心、y0..y1 が見える範囲。竹串が上下に飛び出す
function Tornado($b, $cx, $y0, $y1, $top) {
  Rect $b $cx ($y0 - 5) 1 ($y1 - $y0 + 12) $paper2
  Px $b $cx ($y0 - 6) $bur3
  for ($y = $y0; $y -le $y1; $y++) {
    $taper = 0
    if ($y -le $y0 + 1) { $taper = 2 } elseif ($y -le $y0 + 3) { $taper = 1 }
    if ($y -ge $y1 - 1) { $taper = 1 }
    for ($x = $cx - 4 + $taper; $x -le $cx + 4 - $taper; $x++) {
      $ph = (($x - $cx + 4) + ($y * 2)) % 6
      if ($ph -lt 4) {
        $col = $fry2
        if ($x -ge $cx + 2) { $col = $fry1 }
        if ($x -ge $cx + 4 - $taper) { $col = $fry3 }
        if ($ph -eq 3) { $col = $fry3 }
        Px $b $x $y $col
      }
      elseif ($ph -eq 4) { Px $b $x $y $fry4 }
    }
  }
  if ($top) {
    for ($y = $y0 + 1; $y -le $y1; $y += 2) { for ($x = $cx - 3; $x -le $cx + 3; $x++) { if (((($x * 5) + ($y * 3)) % 7) -eq 0 -and $b.GetPixel($x, $y).A -gt 0) { Px $b $x $y $top } } }
  }
}

# =====================================================================
# ---- 看板（屋根の上に掲げる）100x30。赤い板に黄色のふち、フライドポテトの絵と大きな「ポテト」
$b = NewBmp 100 30
Rect $b 17 0 2 5 $w3; Rect $b 81 0 2 5 $w3
Rect $b 0 4 100 26 $pr0; Rect $b 1 5 98 24 $pr1; Rect $b 1 5 98 1 $pr3
Frame $b 3 7 94 20 $py1
Frame $b 4 8 92 18 $pr0
foreach ($p in @(@(0, 4), @(99, 4), @(0, 29), @(99, 29))) { Clear $b $p[0] $p[1] }
foreach ($p in @(@(3, 7), @(96, 7), @(3, 26), @(96, 26))) { Px $b $p[0] $p[1] $py3 }
# 左: ポテトのカップ（大）
$cup = FryCup 12 12 8 1 $null
Blit $b $cup 7 6
$cup.Dispose()
# 文字
$tw = TextShadow $b 'ポテト' 30 9 16 $py2 $pr0 $true
# 右: いもと光
Potato $b 88 19 5 4
Px $b 83 11 $py3; Px $b 82 12 $py3; Px $b 84 12 $py3; Px $b 83 13 $py3
Px $b 91 11 $py3; Px $b 90 12 $py3; Px $b 92 12 $py3; Px $b 91 13 $py3
Save $b 'potato_sign.png'

# ---- のぼり旗 16x78（左の棒の足元が原点）。黄色い布に赤い縦書きと、ポテトのカップ
$b = NewBmp 16 78
Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 76 $w2; Rect $b 0 2 1 76 $w3
Rect $b 2 4 13 66 $py1; Rect $b 2 4 1 66 $py2; Rect $b 14 4 1 66 $py0
Rect $b 2 4 13 1 $pr1
for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 70 $py1; Px $b (2 + $i) 71 $py0 } }
$chars = 'ポ', 'テ', 'ト'
for ($i = 0; $i -lt 3; $i++) { [void](TextPx $b $chars[$i] 3 (6 + 12 * $i) 11 $pr1 $true) }
$cup = FryCup 9 8 7 2 $null
Blit $b $cup 3 43
$cup.Dispose()
Save $b 'potato_nobori.png'

# ---- 日よけ屋根 144x21（赤と黄色のしましま、下はくるっとした縁）。足元が下のへり
$RW = 144
$b = NewBmp $RW 21
$SW = 12
for ($y = 0; $y -lt 5; $y++) {
  $inset = 5 - $y
  for ($x = $inset; $x -lt $RW - $inset; $x++) {
    $col = $pr1
    if ($y -eq 0) { $col = $pr3 } elseif ($y -eq 4) { $col = $pr0 }
    elseif (($x % 6) -eq 2 -and $y -eq 2) { $col = $pr2 }
    Px $b $x $y $col
  }
}
for ($y = 5; $y -lt 21; $y++) {
  for ($x = 0; $x -lt $RW; $x++) {
    $s = [math]::Floor($x / $SW); $lx = $x % $SW
    $isRed = ($s % 2) -eq 0
    if ($y -ge 16) {
      # 縁のくるっとしたところ（半円）
      $dy = $y - 16; $cxs = ($SW - 1) / 2.0; $rr = ($SW / 2.0)
      $dxs = $lx - $cxs
      if (($dxs * $dxs) / ($rr * $rr) + ($dy * $dy) / (5.0 * 5.0) -gt 1.0) { continue }
    }
    if ($isRed) { $col = $pr1; if ($lx -eq 0) { $col = $pr2 } elseif ($lx -eq $SW - 1) { $col = $pr0 } }
    else { $col = $py1; if ($lx -eq 0) { $col = $py2 } elseif ($lx -eq $SW - 1) { $col = $py0 } }
    if ($y -eq 5) { $col = $pr0 }
    if ($y -eq 6 -and -not $isRed) { $col = $py2 }
    Px $b $x $y $col
  }
}
# 縁のふち取り（暗い線）
for ($x = 0; $x -lt $RW; $x++) {
  $lx = $x % $SW; $cxs = ($SW - 1) / 2.0; $rr = ($SW / 2.0)
  $dxs = $lx - $cxs
  $v = 1.0 - ($dxs * $dxs) / ($rr * $rr)
  if ($v -gt 0) { $ey = 16 + [int][math]::Floor(5.0 * [math]::Sqrt($v)); Px $b $x ([math]::Min(20, $ey)) $pr0 }
}
Save $b 'potato_roof.png'

# ---- カウンター 136x24。上の面と、赤い前掛けに小さなポテトの柄
$CW = 136
$b = NewBmp $CW 24
Rect $b 0 0 $CW 24 $ol
Rect $b 1 1 ($CW - 2) 8 $w1; Rect $b 1 1 ($CW - 2) 1 $cream; Rect $b 1 8 ($CW - 2) 1 $w2
Rect $b 1 9 ($CW - 2) 14 $w2
for ($x = 14; $x -lt $CW - 2; $x += 15) { Rect $b $x 9 1 3 $w3 }
Rect $b 3 11 ($CW - 6) 11 $pr1
Rect $b 3 11 ($CW - 6) 1 $py1; Rect $b 3 21 ($CW - 6) 1 $py1
Rect $b 3 12 ($CW - 6) 1 $pr0
for ($x = 12; $x -lt $CW - 12; $x += 12) {
  # 小さなカップ柄
  Rect $b ($x + 1) 17 5 3 $py1; Rect $b ($x + 1) 17 5 1 $py2
  Rect $b ($x + 1) 14 1 3 $py2; Rect $b ($x + 3) 13 1 4 $py3; Rect $b ($x + 5) 14 1 3 $py2
}
Rect $b 0 23 $CW 1 $ol
foreach ($p in @(@(0, 0), @(($CW - 1), 0))) { Clear $b $p[0] $p[1] }
Save $b 'potato_counter.png'

# ---- 柱 6x48（足元が原点）。上に赤と黄のしましま
$b = NewBmp 6 48
Rect $b 0 0 6 48 $ol; Rect $b 1 0 4 47 $w2; Rect $b 1 0 1 47 $w1; Rect $b 4 0 1 47 $w3
for ($y = 12; $y -lt 20; $y++) { $c = if ((($y - 12) % 4) -lt 2) { $pr1 } else { $py1 }; Rect $b 1 $y 4 1 $c }
Save $b 'potato_post.png'

# ---- フライヤー（卓上の2槽フライヤー）4コマのアニメ。1コマ 50x28 を横に並べる
# 揚げかごが油から上がったり下がったりして、油の泡がはじける。左右でタイミングをずらす
$FW = 50; $FH = 28
$yBs = @(9, 7, 5, 7)
function FryerFrame($b, $ox, $f) {
  # 奥のしきり板
  Rect $b $ox 3 $FW 6 $iron0; Rect $b ($ox + 1) 4 ($FW - 2) 5 $st0; Rect $b ($ox + 1) 4 ($FW - 2) 1 $st2
  foreach ($rx in 8, 25, 41) { Px $b ($ox + $rx) 6 $st3 }
  # 本体の前面
  Rect $b $ox 14 $FW 14 $iron0; Rect $b ($ox + 1) 15 ($FW - 2) 12 $st1
  Rect $b ($ox + 1) 15 ($FW - 2) 1 $st3; Rect $b ($ox + 1) 16 ($FW - 2) 1 $st2; Rect $b ($ox + 1) 26 ($FW - 2) 1 $st0
  Rect $b ($ox + 4) 18 ($FW - 8) 6 $iron1; Rect $b ($ox + 4) 18 ($FW - 8) 1 $iron0
  # つまみ・ランプ・赤い銘板
  foreach ($kx in 9, 40) { Ellipse $b ($ox + $kx) 21 2.4 2.4 $py1; Px $b ($ox + $kx - 1) 20 $py3; Px $b ($ox + $kx + 1) 22 $py0 }
  $lamp = if ($f % 2 -eq 0) { C '#5fe36a' } else { C '#3aa845' }
  Rect $b ($ox + 16) 20 2 2 $lamp; Rect $b ($ox + 19) 20 2 2 (C '#ff5a44')
  Rect $b ($ox + 24) 19 11 4 $pr1; Rect $b ($ox + 24) 19 11 1 $pr3; Rect $b ($ox + 26) 21 7 1 $py2
  # 槽（左右）
  for ($k = 0; $k -lt 2; $k++) {
    $x0 = $ox + 2 + $k * 24
    Rect $b $x0 8 22 7 $iron0; Rect $b ($x0 + 1) 9 20 5 $st2
    Rect $b ($x0 + 2) 10 18 3 $oil1; Rect $b ($x0 + 2) 10 18 1 $oil2
    Rect $b ($x0 + 1) 13 20 1 $st0
    # 泡
    for ($j = 0; $j -lt 6; $j++) {
      $bx = $x0 + 3 + (($j * 3) + ($f * 2) + $k * 5) % 16; $by = 10 + (($j + $f) % 3)
      if ((($j + $f) % 2) -eq 0) { Px $b $bx $by $oil3 } else { Px $b $bx $by $st3 }
    }
    # 揚げかご
    $ph = ($f + 2 * $k) % 4
    $yB = $yBs[$ph]; $bx0 = $x0 + 4
    $sub = ($ph -eq 0)
    for ($i = 0; $i -lt 7; $i++) {
      $hh = 3 + (($i * 5 + $k * 3) % 3); if ($sub) { $hh = 1 + ($i % 2) }
      $c1 = if ($i % 2 -eq 0) { $fry2 } else { $fry1 }
      if ($sub) { $c1 = $fry3 }
      Rect $b ($bx0 + 1 + $i * 2) ($yB - $hh) 2 $hh $c1
      if ((-not $sub) -and ($i % 3 -eq 0)) { Px $b ($bx0 + 1 + $i * 2 + 1) ($yB - $hh) $fry4 }
    }
    Rect $b $bx0 $yB 14 1 $st1
    for ($r = 1; $r -le 3; $r++) { for ($i = 0; $i -lt 14; $i += 2) { Px $b ($bx0 + $i) ($yB + $r) $iron2 } }
    Rect $b $bx0 ($yB + 3) 14 1 $iron2
    # 持ち手
    Rect $b ($bx0 + 14) ($yB - 1) 1 2 $iron2
    Rect $b ($bx0 + 14) ($yB - 5) 2 4 $pr1; Px $b ($bx0 + 14) ($yB - 5) $pr3
    # 上がっているときは、油のしずく
    if ($ph -ge 1) { $dx = $bx0 + 3 + (($f * 3 + $k * 4) % 9); Px $b $dx ($yB + 4) $oil2; if ($ph -eq 2) { Px $b ($dx + 5) ($yB + 5) $oil3 } }
  }
}
$b = NewBmp ($FW * 4) $FH
for ($f = 0; $f -lt 4; $f++) { FryerFrame $b ($f * $FW) $f }
Save $b 'potato_fryer.png'

# ---- 保温ライト（ポテトの山と、オレンジに光る保温ランプ）3コマ 22x30
$LW = 22; $LH = 30
$b = NewBmp ($LW * 3) $LH
for ($f = 0; $f -lt 3; $f++) {
  $ox = $f * $LW
  # ポテトの山
  $bunch = FryBunch 16 11 ($f + 2) $null
  $o = OutlineBmp $bunch $ol
  Blit $b $o ($ox + 0) 10
  $o.Dispose()
  # 銀の浅い皿
  Rect $b $ox 21 19 9 $iron0; Rect $b ($ox + 1) 22 17 7 $st1; Rect $b ($ox + 1) 22 17 1 $st3; Rect $b ($ox + 1) 23 17 1 $st2; Rect $b ($ox + 1) 28 17 1 $st0
  Rect $b ($ox + 3) 25 13 2 $pr1; Rect $b ($ox + 3) 25 13 1 $pr3
  # 支柱とランプの傘
  Rect $b ($ox + 18) 5 2 24 $iron0; Rect $b ($ox + 18) 5 1 24 $iron2
  Rect $b ($ox + 8) 1 12 1 $iron0
  Rect $b ($ox + 6) 2 16 1 $iron0
  Rect $b ($ox + 4) 3 19 3 $iron0
  Rect $b ($ox + 9) 2 10 1 $st2; Rect $b ($ox + 7) 3 14 1 $st2; Rect $b ($ox + 5) 4 17 1 $st1; Rect $b ($ox + 5) 5 17 1 $st0
  Rect $b ($ox + 7) 6 12 1 $iron0
  # 光る電球
  $bulb = @($oil3, $py3, $oil3)[$f]
  Rect $b ($ox + 9) 6 6 1 $bulb
  # 光の筋（ポテトにかぶらない所だけ。コマごとに強さがゆれる）
  $al = @(130, 90, 165)[$f]
  for ($y = 7; $y -le 17; $y++) {
    $half = 3 + [int](($y - 7) * 0.55)
    for ($x = $ox + 12 - $half; $x -le $ox + 12 + $half; $x++) {
      if ($x -ge $ox + 17) { continue }
      if ($b.GetPixel($x, $y).A -eq 0) {
        $fade = [int]($al * (1.0 - ($y - 7) / 14.0))
        if ((($x + $y + $f) % 2) -eq 0 -or $fade -gt 70) { Px $b $x $y ([System.Drawing.Color]::FromArgb($fade, 255, 190, 60)) }
      }
    }
  }
  # ポテトのてっぺんがあたたかく光る
  Px $b ($ox + 5 + $f * 3) 11 $py3; Px $b ($ox + 10 - $f) 12 $py2
}
Save $b 'potato_warmer.png'

# ---- 湯気（6コマのアニメ）14x22 を横に並べる。ふんわり上って消える
$SWD = 14
$b = NewBmp ($SWD * 6) 22
for ($f = 0; $f -lt 6; $f++) {
  for ($k = 0; $k -lt 3; $k++) {
    $off = (($f * 4) + ($k * 8)) % 24
    for ($dy = 0; $dy -lt 9; $dy++) {
      $y = 21 - $off - $dy
      if ($y -lt 0) { continue }
      $prog = ($off + $dy) / 24.0
      $a = [int](245 * (1 - $prog))
      if ($a -lt 20) { continue }
      $x = 4 + $k * 3 + [math]::Sin(($y + $k * 2) * 0.5) * 2.2 + $prog * 2
      $xi = [int][math]::Round($x)
      Px $b ($f * $SWD + $xi) $y ([System.Drawing.Color]::FromArgb($a, 255, 255, 255))
      Px $b ($f * $SWD + $xi + 1) $y ([System.Drawing.Color]::FromArgb([int]($a * 0.7), 255, 246, 220))
    }
  }
}
Save $b 'potato_steam.png'

# ---- 紙カップのポテト（2個。塩・のり塩）カウンター用
$c1 = FryCup 9 10 7 1 $salt
$c2 = FryCup 9 10 7 3 $nori2
$b = NewBmp 25 20
Blit $b $c1 0 0; Blit $b $c2 13 1
$c1.Dispose(); $c2.Dispose()
Save $b 'potato_cups.png'

# ---- 調味料セット（ケチャップとシェイカー3本: 塩・のり塩・コンソメ）
$b = NewBmp 28 12
Ascii $b 0 0 @(
  '...y...',
  '..yyy..',
  '..yyy..',
  '.rrrrd.',
  'rrrrrrd',
  'rwwwrrd',
  'rwkwrrd',
  'rwwwrrd',
  'rrrrrrd',
  'rrrrrrd',
  'rrrrrrd',
  '.rrrrd.') @{ y = $py1; r = $ketch; d = (C '#8a1612'); w = $white; k = $pr1 }
$jars = @(
  @{ g = $salt; h = $white; d = (C '#aeb6c6'); l = (C '#4a78d0') },
  @{ g = $nori; h = $nori2; d = (C '#26722e'); l = (C '#1d5a24') },
  @{ g = $cons2; h = (C '#f3bc70'); d = $cons; l = (C '#7a3a10') })
for ($j = 0; $j -lt 3; $j++) {
  $pal = $jars[$j]; $pal.s = $st2; $pal.k = $iron0; $pal.w = $white
  Ascii $b (8 + $j * 7) 3 @(
    '.ssss.',
    'sskksd',
    'ghgggd',
    'gwwwgd',
    'gwlwgd',
    'gwwwgd',
    'gggggd',
    'gggggd') $pal
}
$b2 = OutlineBmp $b $ol
Save $b2 'potato_shakers.png'

# ---- 小さなバスケット（テーブル用）16x15
$b = NewBmp 16 15
$bunch = FryBunch 12 9 5 $null
$o = OutlineBmp $bunch $ol
Blit $b $o 1 0
$o.Dispose()
Rect $b 0 8 16 7 $ol
Rect $b 1 9 14 5 $pr1; Rect $b 1 9 14 1 $pr3
for ($x = 2; $x -lt 14; $x++) { for ($y = 10; $y -lt 13; $y++) { $ck = ([math]::Floor(($x - 2) / 2) + [math]::Floor(($y - 10) / 2)) % 2; if ($ck -eq 0) { Px $b $x $y $paper } } }
Rect $b 1 13 14 1 $pr0
Save $b 'potato_basket_s.png'

# ---- トルネードポテト（竹串に刺した らせんポテトが3本、木の台に立つ）
$tl = NewBmp 30 30
Tornado $tl 5 7 22 $null
Tornado $tl 15 6 21 $nori2
Tornado $tl 25 7 22 $cons2
$o = OutlineBmp $tl $ol
$b2 = NewBmp 32 36
Blit $b2 $o 0 0
$o.Dispose()
Rect $b2 1 26 30 9 $ol; Rect $b2 2 27 28 7 $w2; Rect $b2 2 27 28 1 $w1; Rect $b2 2 33 28 1 $w3
foreach ($hx in 6, 16, 26) { Rect $b2 $hx 27 2 2 $w3 }
Rect $b2 5 30 22 2 $pr1
Save $b2 'potato_tornado.png'

# ---- じゃがいもの木箱（つみあがった いも）26x22
$b = NewBmp 26 22
foreach ($p in @(@(5, 7, 3.6, 2.8), @(11, 5, 4, 3), @(17, 7, 3.8, 2.8), @(21, 9, 3, 2.4), @(8, 10, 3.4, 2.6), @(14, 10, 3.6, 2.8))) { Potato $b $p[0] $p[1] $p[2] $p[3] }
Rect $b 0 11 26 11 $ol; Rect $b 1 12 24 9 $w2; Rect $b 1 12 24 1 $w1
Rect $b 1 16 24 1 $ol
Rect $b 1 17 24 1 $w1; Rect $b 1 20 24 1 $w3
Rect $b 3 12 2 9 $w3; Rect $b 21 12 2 9 $w3
Rect $b 8 13 10 3 $paper; Rect $b 10 14 6 1 $pr1
Save $b 'potato_crate.png'

# ---- じゃがいもの麻袋 15x17
$b = NewBmp 15 17
Potato $b 7 4 3.2 2.4
$s = NewBmp 15 17
Ascii $s 0 4 @(
  '.....yyy.....',
  '....yyyyy....',
  '...bbbbbbb...',
  '..bbbbbbbbb..',
  '.bbbbbbbbbbd.',
  '.bbbbbbbbbbd.',
  '.bbbpppbbbbd.',
  '.bbbpppbbbbd.',
  '.bbbbbbbbbbd.',
  '.bbbbbbbbbbd.',
  '.dbbbbbbbbdd.',
  '..dddddddddd.') @{ b = $bur1; d = $bur2; y = $bur3; p = $pr1 }
$o = OutlineBmp $s $ol
Blit $b $o 0 0
$o.Dispose()
Rect $b 5 6 5 1 $pr1; Rect $b 4 7 7 1 $pr0
Save $b 'potato_sack.png'

# ---- メニュー（立て看板）56x44。足元が原点。あじ3つ
$b = NewBmp 62 46
Rect $b 0 0 62 40 $ol; Rect $b 1 1 60 38 $pr1; Rect $b 3 3 56 34 $paper
Rect $b 3 3 56 1 $paper2
Rect $b 6 40 3 6 $w3; Rect $b 53 40 3 6 $w3; Rect $b 6 40 1 6 $w2; Rect $b 53 40 1 6 $w2
$items = @(@('しお', $salt, $st1), @('のりしお', $nori2, $nori), @('コンソメ', $cons2, $cons))
for ($i = 0; $i -lt 3; $i++) {
  $y = 4 + $i * 11
  Ellipse $b 8.5 ($y + 5.5) 3.2 3.2 $ol
  Ellipse $b 8.5 ($y + 5.5) 2.4 2.4 $items[$i][1]
  Px $b 8 ($y + 4) $white
  [void](TextPx $b $items[$i][0] 14 $y 11 $pr0 $true)
}
Save $b 'potato_menu.png'

# ---- ポテくん（フライドポテトのマスコット。台つき）22x30
$b = NewBmp 22 30
$bunch = FryBunch 14 12 3 $null
$o = OutlineBmp $bunch $ol
Blit $b $o 3 0
$o.Dispose()
CupBody $b 4 12 14 10 $false
# 顔
Rect $b 7 15 2 3 $white; Rect $b 13 15 2 3 $white; Px $b 8 16 $iron0; Px $b 8 17 $iron0; Px $b 14 16 $iron0; Px $b 14 17 $iron0
Rect $b 5 18 2 1 $pr3; Rect $b 15 18 2 1 $pr3
Line $b 9 19 12 19 $py2; Px $b 8 18 $py2; Px $b 13 18 $py2
# うで
Line $b 3 16 1 14 $ol; Line $b 18 16 20 14 $ol; Px $b 1 14 $py2; Px $b 20 14 $py2
# 台
Rect $b 2 22 18 8 $ol; Rect $b 3 23 16 6 $w2; Rect $b 3 23 16 1 $w1; Rect $b 3 28 16 1 $w3
Rect $b 5 25 12 3 $pr1; Rect $b 5 25 12 1 $pr3
Save $b 'potato_mascot.png'

# ---- 床のマット 60x22（赤に黄色のふち、まんなかに市松）
$b = NewBmp 60 22
Rect $b 0 0 60 22 $pr0; Rect $b 2 2 56 18 $py1; Rect $b 4 4 52 14 $pr1
for ($y = 4; $y -lt 18; $y++) { for ($x = 4; $x -lt 56; $x++) { if ((([math]::Floor(($x - 4) / 4) + [math]::Floor(($y - 4) / 4)) % 2) -eq 0) { Px $b $x $y $pr2 } } }
for ($i = 0; $i -lt 4; $i++) { Rect $b (10 + $i * 12) 10 5 1 $py2; Rect $b (12 + $i * 12) 8 1 5 $py2 }
foreach ($p in @(@(0, 0), @(59, 0), @(0, 21), @(59, 21))) { Clear $b $p[0] $p[1] }
Save $b 'potato_mat.png'
