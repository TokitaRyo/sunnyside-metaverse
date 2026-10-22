# ホットドッグ屋台の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/hotdog.ps1   （リポジトリのルートで）
#   一部だけ作り直す: $env:HOTDOG_ONLY='sign|grill'   （名前の正規表現。空なら全部）
# 出力: client/public/brand/stall/hotdog_*.png（原点は各スプライトの足元。配置は scripts/stalls/hotdog.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（赤 x 黄 の屋台。パンのきつね色とソーセージの赤茶が主役）
$hr0 = C '#6e1220'; $hr1 = C '#cf2a2a'; $hr2 = C '#ea4a3a'; $hr3 = C '#ff8068'
$hy0 = C '#c8860a'; $hy1 = C '#f8c21c'; $hy2 = C '#ffdf4e'; $hy3 = C '#fff4a8'
$bn0 = C '#9a5a24'; $bn1 = C '#d99a4e'; $bn2 = C '#f0bd72'; $bn3 = C '#fbdca0'
$sg0 = C '#6a2418'; $sg1 = C '#a8402c'; $sg2 = C '#c8573a'; $sg3 = C '#e88a62'; $sgb = C '#4a1a0e'
$ketch = C '#d3261f'; $ketchHi = C '#ff6a52'; $must = C '#e8b81a'; $mustHi = C '#ffe36a'; $mustDk = C '#b88a08'
$paper = C '#f6f0dc'; $paper2 = C '#d9ceb0'
$st0 = C '#6b7587'; $st1 = C '#a9b3c4'; $st2 = C '#dbe3ee'; $st3 = C '#f4f8fc'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

function Want($name) { if (-not $env:HOTDOG_ONLY) { return $true }; return ($name -match $env:HOTDOG_ONLY) }

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
# 整数倍に拡大した新しい絵を返す
function ScaleBmp($src, $n) {
  $d = NewBmp ($src.Width * $n) ($src.Height * $n)
  for ($j = 0; $j -lt $src.Height; $j++) { for ($i = 0; $i -lt $src.Width; $i++) { $p = $src.GetPixel($i, $j); if ($p.A -gt 0) { Rect $d ($i * $n) ($j * $n) $n $n $p } } }
  $src.Dispose()
  return $d
}
# 文字に影（ふち）を付けて貼る
function TextShadow($b, $text, $x, $y, $px, $col, $shadow, $bold) {
  [void](TextPx $b $text ($x + 1) ($y + 1) $px $shadow $bold)
  [void](TextPx $b $text ($x - 1) $y $px $shadow $bold)
  [void](TextPx $b $text $x ($y - 1) $px $shadow $bold)
  [void](TextPx $b $text $x ($y + 1) $px $shadow $bold)
  return (TextPx $b $text $x $y $px $col $bold)
}
# 角を丸めた横長の形。行ごとの色の配列で塗る
function StadiumRows($b, $x, $y, $w, $cols) {
  $h = $cols.Count
  for ($j = 0; $j -lt $h; $j++) {
    $ins = 0
    if ($j -eq 0 -or $j -eq $h - 1) { $ins = 1; if ($h -ge 7) { $ins = 2 } }
    elseif ($h -ge 7 -and ($j -eq 1 -or $j -eq $h - 2)) { $ins = 1 }
    Rect $b ($x + $ins) ($y + $j) ($w - 2 * $ins) 1 $cols[$j]
  }
}
# 疑似乱数（0以上の整数）
function Hs($a, $c, $d) { return ((($a * 37) + ($c * 91) + ($d * 53) + ($a * $c * 7)) % 17) }

# ---- ホットドッグ1本（横向き。パンの幅 $w、ソーセージは両端に2pxはみ出す）。外側に1pxのふち付きの絵を返す
function Dog($w, $sauce) {
  $b = NewBmp ($w + 4) 9
  # パンの奥側
  StadiumRows $b 2 2 $w @($bn2, $bn1, $bn1, $bn1, $bn1, $bn1, $bn0)
  # ソーセージ
  StadiumRows $b 0 0 ($w + 4) @($sg2, $sg3, $sg2, $sg1, $sg0)
  Px $b 0 2 $sg0; Px $b ($w + 3) 2 $sg0
  for ($x = 3; $x -lt $w; $x += 4) { Px $b $x 1 $hr3 }
  # パンの手前（ソーセージを下から包む）
  for ($y = 4; $y -le 8; $y++) {
    $r = $y - 2
    $ins = 0
    if ($r -eq 0 -or $r -eq 6) { $ins = 2 } elseif ($r -eq 1 -or $r -eq 5) { $ins = 1 }
    $col = @($bn3, $bn3, $bn2, $bn2, $bn1, $bn1, $bn0)[$r]
    Rect $b (2 + $ins) $y ($w - 2 * $ins) 1 $col
  }
  Px $b 2 4 $bn1; Px $b ($w + 1) 4 $bn1
  # ケチャップとマスタードの線（2本の波がかさなる）
  if ($sauce) {
    for ($x = 3; $x -lt $w + 1; $x++) {
      $i = $x - 3
      $kr = 1 + ([int][math]::Floor($i / 2) % 2)
      $mr = 1 + ((1 + [int][math]::Floor($i / 2)) % 2)
      Px $b $x $mr $must
      Px $b $x $kr $ketch
    }
    Px $b 4 1 $ketchHi; Px $b 5 2 $mustHi
  }
  return (OutlineBmp $b $ol)
}

# =====================================================================
# ---- 看板（屋根の上に掲げる）124x30 を2コマ。赤い板に黄色のふち。ふちの電球が交互に点滅する
$SGW = 124
if (Want 'sign') {
  $b = NewBmp ($SGW * 2) 30
  $dog = Dog 14 $true
  for ($f = 0; $f -lt 2; $f++) {
    $ox = $f * $SGW
    Rect $b ($ox + 21) 0 2 5 $w3; Rect $b ($ox + 101) 0 2 5 $w3
    Rect $b $ox 4 $SGW 26 $hr0; Rect $b ($ox + 1) 5 ($SGW - 2) 24 $hr1; Rect $b ($ox + 1) 5 ($SGW - 2) 1 $hr3
    Frame $b ($ox + 3) 7 ($SGW - 6) 20 $hy1
    Frame $b ($ox + 4) 8 ($SGW - 8) 18 $hr0
    foreach ($p in @(@(0, 4), @(($SGW - 1), 4), @(0, 29), @(($SGW - 1), 29))) { Clear $b ($ox + $p[0]) $p[1] }
    # ふちの電球
    for ($i = 0; $i -lt 28; $i++) {
      $on = ((($i + $f) % 2) -eq 0)
      $c = if ($on) { $hy3 } else { $hy0 }
      Px $b ($ox + 6 + $i * 4) 7 $c; Px $b ($ox + 7 + $i * 4) 7 $c
      Px $b ($ox + 6 + $i * 4) 26 $c; Px $b ($ox + 7 + $i * 4) 26 $c
    }
    # 左: ホットドッグの絵
    Blit $b $dog ($ox + 7) 13
    # 文字
    [void](TextShadow $b 'ホットドッグ' ($ox + 31) 9 14 $hy2 $hr0 $true)
    # きらり
    if ($f -eq 0) { Px $b ($ox + 117) 12 $hy3; Px $b ($ox + 116) 13 $hy3; Px $b ($ox + 118) 13 $hy3; Px $b ($ox + 117) 14 $hy3 }
    else { Px $b ($ox + 26) 12 $hy3; Px $b ($ox + 25) 13 $hy3; Px $b ($ox + 27) 13 $hy3; Px $b ($ox + 26) 14 $hy3 }
  }
  $dog.Dispose()
  Save $b 'hotdog_sign.png'
}

# ---- のぼり旗 16x84（左の棒の足元が原点）。黄色い布に赤い縦書き
if (Want 'nobori') {
  $b = NewBmp 16 84
  Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 82 $w2; Rect $b 0 2 1 82 $w3
  Rect $b 2 4 13 74 $hy1; Rect $b 2 4 1 74 $hy2; Rect $b 14 4 1 74 $hy0
  Rect $b 2 4 13 1 $hr1
  for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 78 $hy1; Px $b (2 + $i) 79 $hy0 } }
  $chars = 'ホ', 'ッ', 'ト', 'ド', 'ッ', 'グ'
  for ($i = 0; $i -lt 6; $i++) { [void](TextPx $b $chars[$i] 3 (5 + 12 * $i) 11 $hr1 $true) }
  Save $b 'hotdog_nobori.png'
}

# ---- 日よけ屋根 144x22（赤と黄色のしましま。下の縁は三角のぎざぎざ）。足元が下のへり
if (Want 'roof') {
  $RW = 144; $SW = 12
  $b = NewBmp $RW 22
  for ($y = 0; $y -lt 5; $y++) {
    $inset = 5 - $y
    for ($x = $inset; $x -lt $RW - $inset; $x++) {
      $col = $hr1
      if ($y -eq 0) { $col = $hr3 } elseif ($y -eq 4) { $col = $hr0 }
      elseif (($x % 6) -eq 2 -and $y -eq 2) { $col = $hr2 }
      Px $b $x $y $col
    }
  }
  for ($y = 5; $y -lt 22; $y++) {
    for ($x = 0; $x -lt $RW; $x++) {
      $s = [int][math]::Floor($x / $SW); $lx = $x % $SW
      $isRed = ($s % 2) -eq 0
      $depth = [int][math]::Round(5.0 * (1.0 - [math]::Abs($lx - 5.5) / 6.0))
      if ($y -gt 16 + $depth) { continue }
      if ($isRed) { $col = $hr1; if ($lx -eq 0) { $col = $hr2 } elseif ($lx -eq $SW - 1) { $col = $hr0 } }
      else { $col = $hy1; if ($lx -eq 0) { $col = $hy2 } elseif ($lx -eq $SW - 1) { $col = $hy0 } }
      if ($y -eq 5) { $col = $hr0 }
      elseif ($y -eq 6) { if ($isRed) { $col = $hr2 } else { $col = $hy2 } }
      elseif ($y -eq 16 + $depth -and $y -gt 16) { $col = $hr0 }
      Px $b $x $y $col
    }
  }
  Save $b 'hotdog_roof.png'
}

# ---- カウンター 136x24。上の面と、赤い前掛けに小さなホットドッグの柄
if (Want 'counter') {
  $CW = 136
  $b = NewBmp $CW 24
  Rect $b 0 0 $CW 24 $ol
  Rect $b 1 1 ($CW - 2) 8 $w1; Rect $b 1 1 ($CW - 2) 1 $cream; Rect $b 1 8 ($CW - 2) 1 $w2
  Rect $b 1 9 ($CW - 2) 14 $w2
  for ($x = 14; $x -lt $CW - 2; $x += 15) { Rect $b $x 9 1 1 $w3 }
  Rect $b 1 10 ($CW - 2) 1 $hy1
  Rect $b 3 11 ($CW - 6) 11 $hr1
  Rect $b 3 11 ($CW - 6) 1 $hr0
  Rect $b 3 21 ($CW - 6) 1 $hr0
  $mini = Dog 8 $true
  foreach ($x in 11, 32, 53, 74, 95, 116) { Blit $b $mini $x 11 }
  $mini.Dispose()
  Rect $b 0 23 $CW 1 $ol
  foreach ($p in @(@(0, 0), @(($CW - 1), 0))) { Clear $b $p[0] $p[1] }
  Save $b 'hotdog_counter.png'
}

# ---- 柱 6x48（足元が原点）。赤と黄色のらせん（ななめのしま）
if (Want 'post') {
  $b = NewBmp 6 48
  Rect $b 0 0 6 48 $ol
  for ($y = 0; $y -lt 47; $y++) {
    for ($x = 1; $x -le 4; $x++) {
      $st = [int][math]::Floor(($y + $x) / 3) % 2
      if ($st -eq 0) { $c = $hr1 } else { $c = $hy1 }
      if ($x -eq 1) { if ($st -eq 0) { $c = $hr2 } else { $c = $hy2 } }
      if ($x -eq 4) { if ($st -eq 0) { $c = $hr0 } else { $c = $hy0 } }
      Px $b $x $y $c
    }
  }
  Save $b 'hotdog_post.png'
}

# ---- グリル（ソーセージを焼く）4コマのアニメ。1コマ 60x30 を横に並べる
# 炭火がちらつき、ソーセージがころがって焼き色が動き、ときどき火の粉が上がる
if (Want 'grill') {
  $GW = 60; $GH = 30
  $coalCols = @((C '#ff7a1a'), (C '#ffb03a'), (C '#d63a12'), (C '#8a1a0a'), (C '#ffd870'))
  $b = NewBmp ($GW * 4) $GH
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * $GW
    # 本体
    Rect $b ($ox + 1) 18 58 11 $iron0; Rect $b ($ox + 2) 19 56 9 $iron1; Rect $b ($ox + 2) 19 56 1 $iron2
    Rect $b ($ox + 4) 29 6 1 $iron0; Rect $b ($ox + 50) 29 6 1 $iron0
    # 炭火の口
    Rect $b ($ox + 5) 21 50 7 (C '#1c0a05')
    for ($y = 22; $y -le 26; $y++) {
      for ($x = 6; $x -le 53; $x++) {
        $h = Hs $x $y $f
        if ($h -lt 6) { continue }
        $ci = ($h + $x + $f) % 5
        if ($y -eq 22 -and $ci -eq 3) { continue }
        Px $b ($ox + $x) $y $coalCols[$ci]
      }
    }
    Rect $b ($ox + 5) 27 50 1 $iron0
    # 赤い銘板
    Rect $b ($ox + 25) 19 10 2 $hr1; Px $b ($ox + 29) 19 $hy2; Px $b ($ox + 30) 19 $hy2
    # 焼き網
    Rect $b $ox 8 $GW 10 $iron0; Rect $b ($ox + 1) 9 ($GW - 2) 8 $iron2; Rect $b ($ox + 1) 9 ($GW - 2) 1 $iron3
    for ($x = 3; $x -lt $GW - 1; $x += 3) { Rect $b ($ox + $x) 10 1 7 $iron1 }
    # ソーセージ6本（縦向きにならぶ）
    for ($i = 0; $i -lt 6; $i++) {
      $sx = $ox + 5 + 9 * $i
      $roll = ($f + $i) % 4
      $hl = 1 + ($roll % 3)
      for ($j = 0; $j -lt 10; $j++) {
        $ins = 0; if ($j -eq 0 -or $j -eq 9) { $ins = 1 }
        for ($k = $ins; $k -lt 5 - $ins; $k++) {
          $d = [math]::Abs($k - $hl)
          if ($d -eq 0) { $c = $sg3 } elseif ($d -eq 1) { $c = $sg2 } elseif ($d -eq 2) { $c = $sg1 } else { $c = $sg0 }
          if (($j -eq 2 -or $j -eq 5 -or $j -eq 8) -and ((($k + $roll) % 4) -ne 0)) { $c = $sgb }
          if ($j -eq 0 -or $j -eq 9) { $c = $sg0 }
          Px $b ($sx + $k) (5 + $j) $c
        }
      }
    }
    # 網の手前のふち
    Rect $b $ox 15 $GW 3 $iron0; Rect $b ($ox + 1) 15 ($GW - 2) 1 $iron2; Rect $b ($ox + 1) 16 ($GW - 2) 1 $iron1
    # 火の粉
    for ($i = 0; $i -lt 3; $i++) {
      $ex = 6 + (($i * 19 + $f * 13) % 48); $ey = ($i * 5 + $f * 3) % 4
      $ec = @((C '#ffd870'), (C '#ffb03a'), (C '#ff7a1a'))[($i + $f) % 3]
      Px $b ($ox + $ex) $ey $ec
    }
  }
  Save $b 'hotdog_grill.png'
}

# ---- 湯気（6コマのアニメ）16x26 を横に並べる。ふんわり上って消える
if (Want 'steam') {
  $SWD = 16
  $b = NewBmp ($SWD * 6) 26
  for ($f = 0; $f -lt 6; $f++) {
    for ($k = 0; $k -lt 3; $k++) {
      $off = (($f * 4) + ($k * 8)) % 24
      for ($dy = 0; $dy -lt 8; $dy++) {
        $y = 25 - $off - $dy
        if ($y -lt 0) { continue }
        $prog = ($off + $dy) / 24.0
        $a = [int](235 * (1 - $prog))
        if ($a -lt 20) { continue }
        $x = 4 + $k * 4 + [math]::Sin(($y + $k * 3) * 0.45) * 2.4 + $prog * 2
        $xi = [int][math]::Round($x)
        Px $b ($f * $SWD + $xi) $y ([System.Drawing.Color]::FromArgb($a, 255, 255, 255))
        Px $b ($f * $SWD + $xi + 1) $y ([System.Drawing.Color]::FromArgb([int]($a * 0.8), 255, 246, 224))
        if (($dy % 3) -eq 0) { Px $b ($f * $SWD + $xi - 1) $y ([System.Drawing.Color]::FromArgb([int]($a * 0.45), 255, 255, 255)) }
      }
    }
  }
  Save $b 'hotdog_steam.png'
}

# ---- パンの山（編みかごに積んだホットドッグ用のパン）36x32
if (Want 'buns') {
  $pile = NewBmp 30 19
  $pos = @(@(1, 11), @(16, 11), @(4, 6), @(14, 6), @(9, 1))
  # 下の段から順に（上の段が手前に乗る）
  $order = @(0, 1, 2, 3, 4)
  foreach ($i in $order) {
    $bx = $pos[$i][0]; $by = $pos[$i][1]
    StadiumRows $pile $bx $by 13 @($bn3, $bn2, $bn2, $bn1, $bn1, $bn1, $bn0)
    Rect $pile ($bx + 3) ($by + 2) 7 1 $bn0
    Px $pile ($bx + 4) $by $bn3; Px $pile ($bx + 8) ($by + 1) $bn3
  }
  $o = OutlineBmp $pile $ol
  $b = NewBmp 32 32
  Blit $b $o 0 0
  $o.Dispose()
  # 編みかご
  Rect $b 0 17 32 15 $ol; Rect $b 1 18 30 13 $w2; Rect $b 1 18 30 1 $w1
  for ($y = 19; $y -lt 31; $y++) { for ($x = 1; $x -lt 31; $x++) { if ((([math]::Floor(($x + ($y % 2) * 2) / 4) + $y) % 2) -eq 0) { Px $b $x $y $w3 } } }
  Rect $b 1 18 30 1 $w1; Rect $b 1 30 30 1 $w3
  # 赤い布の札
  Rect $b 9 21 14 7 $paper; Rect $b 9 21 14 1 $hr1; Rect $b 9 27 14 1 $hr1
  $mini = Dog 6 $true
  Blit $b $mini 10 21
  $mini.Dispose()
  Save $b 'hotdog_buns.png'
}

# ---- 紙のトレイに入った焼き上がりのホットドッグ（ケチャップとマスタードの線）32x19
if (Want 'tray') {
  $t = NewBmp 30 17
  Rect $t 0 8 30 3 $paper2
  $d1 = Dog 12 $true
  Blit $t $d1 6 0
  $d1.Dispose()
  $d2 = Dog 12 $true
  Blit $t $d2 8 5
  $d2.Dispose()
  for ($y = 11; $y -lt 17; $y++) {
    $inset = $y - 11
    for ($x = $inset; $x -lt 30 - $inset; $x++) {
      $c = $paper
      if ($y -eq 11) { $c = $st3 }
      elseif ($y -eq 13 -or $y -eq 14) { $c = $hr1 }
      elseif ($y -eq 16) { $c = $paper2 }
      if (($y -eq 13 -or $y -eq 14) -and ($x % 6) -eq 1) { $c = $hy1 }
      Px $t $x $y $c
    }
  }
  $o = OutlineBmp $t $ol
  Save $o 'hotdog_tray.png'
}

# ---- 紙の包みのホットドッグ 20x16（半分だけ包み紙から出ている）
if (Want 'wrap') {
  $t = NewBmp 18 14
  $d = Dog 10 $true
  Blit $t $d 1 0
  $d.Dispose()
  for ($x = 0; $x -lt 18; $x++) {
    $topY = 6 + (([int][math]::Floor($x / 2)) % 2)
    for ($y = $topY; $y -lt 14; $y++) {
      $c = $paper
      if ($y -eq $topY) { $c = $st3 }
      elseif ($y -eq 10) { $c = $hr1 }
      elseif ($y -eq 13) { $c = $paper2 }
      elseif (($x % 6) -eq 5) { $c = $paper2 }
      Px $t $x $y $c
    }
  }
  $o = OutlineBmp $t $ol
  Save $o 'hotdog_wrap.png'
}

# ---- 紙トレイの重ね（空のトレイを積んだもの）16x14
if (Want 'trays') {
  $t = NewBmp 16 12
  foreach ($i in 0..3) {
    $y = 8 - $i * 2
    Rect $t 1 $y 14 3 $paper
    Rect $t 1 $y 14 1 $st3
    Rect $t 1 ($y + 2) 14 1 $paper2
    Rect $t 2 ($y + 1) 12 1 $hr1
  }
  $o = OutlineBmp $t $ol
  Save $o 'hotdog_trays.png'
}

# ---- ケチャップとマスタードの容器 22x15
if (Want 'sauces') {
  $b = NewBmp 20 13
  Ascii $b 0 0 @(
    '....c....',
    '...ccc...',
    '...cdc...',
    '.rhrrrrd.',
    '.rhrrrrd.',
    '.rwwwwwd.',
    '.rwkkkwd.',
    '.rwwwwwd.',
    '.rhrrrrd.',
    '.rhrrrrd.',
    '.rrrrrrd.',
    '.rrrrrrd.',
    '.ddddddd.') @{ c = $hr0; d = (C '#8a1612'); r = $ketch; h = $ketchHi; w = $white; k = $hr1 }
  Ascii $b 11 0 @(
    '....c....',
    '...ccc...',
    '...cdc...',
    '.mhmmmmd.',
    '.mhmmmmd.',
    '.mwwwwwd.',
    '.mwkkkwd.',
    '.mwwwwwd.',
    '.mhmmmmd.',
    '.mhmmmmd.',
    '.mmmmmmd.',
    '.mmmmmmd.',
    '.ddddddd.') @{ c = $hy0; d = $mustDk; m = $must; h = $mustHi; w = $white; k = $hy0 }
  $o = OutlineBmp $b $ol
  Save $o 'hotdog_sauces.png'
}

# ---- ホットドッグくん（マスコット。台つき）24x34
if (Want 'mascot') {
  $m = NewBmp 22 24
  Ellipse $m 11 14 9 10.5 $bn1
  # ソーセージ
  Rect $m 7 4 8 17 $sg2
  Ellipse $m 11 4 4.5 3.5 $sg2
  Rect $m 7 4 2 17 $sg3; Rect $m 13 4 2 17 $sg1
  Rect $m 9 2 2 1 $sg3
  # パンの手前（左右のふち）
  for ($y = 7; $y -lt 24; $y++) {
    for ($x = 2; $x -lt 21; $x++) {
      if ($x -gt 6 -and $x -lt 16) { continue }
      $dx = ($x + 0.5 - 11) / 9.0; $dy = ($y + 0.5 - 14) / 10.5
      if ($dx * $dx + $dy * $dy -le 1) {
        $c = $bn2
        if ($x -le 3 -or $x -ge 19) { $c = $bn1 }
        if ($x -eq 6 -or $x -eq 16) { $c = $bn3 }
        Px $m $x $y $c
      }
    }
  }
  # 顔
  Rect $m 8 8 2 3 $white; Rect $m 12 8 2 3 $white
  Px $m 9 9 $iron0; Px $m 9 10 $iron0; Px $m 13 9 $iron0; Px $m 13 10 $iron0
  Px $m 8 12 $hr3; Px $m 9 12 $hr3; Px $m 13 12 $hr3; Px $m 14 12 $hr3
  Line $m 9 13 12 13 $sg0; Px $m 8 12 $hr3
  # ケチャップとマスタードの波
  for ($x = 7; $x -le 14; $x++) {
    $i = $x - 7
    $kr = 16 + ([int][math]::Floor($i / 2) % 2)
    $mr = 16 + ((1 + [int][math]::Floor($i / 2)) % 2)
    Px $m $x $mr $must; Px $m $x $kr $ketch
  }
  # うで
  Line $m 2 15 0 12 $ol; Line $m 20 15 21 12 $ol
  Px $m 0 11 $hy2; Px $m 21 11 $hy2
  $o = OutlineBmp $m $ol
  $b = NewBmp 24 34
  Blit $b $o 0 0
  $o.Dispose()
  Rect $b 2 24 20 10 $ol; Rect $b 3 25 18 8 $w2; Rect $b 3 25 18 1 $w1; Rect $b 3 32 18 1 $w3
  Rect $b 5 27 14 3 $hr1; Rect $b 5 27 14 1 $hr3
  foreach ($x in 7, 11, 15) { Px $b $x 29 $hy2 }
  Save $b 'hotdog_mascot.png'
}

# ---- メニュー（立て看板）54x50。足元が原点。品書きの中身は書かず、大きなホットドッグの絵で伝える
if (Want 'menu') {
  $b = NewBmp 54 40
  Rect $b 0 0 54 34 $ol; Rect $b 1 1 52 32 $hr1; Rect $b 3 3 48 28 (C '#3a2a22')
  Rect $b 6 34 3 6 $w3; Rect $b 45 34 3 6 $w3
  Rect $b 6 34 1 6 $w2; Rect $b 45 34 1 6 $w2
  $w = TextWidth 'メニュー' 11
  [void](TextPx $b 'メニュー' ([math]::Floor((54 - $w) / 2) - 1) 4 11 $hy2 $true)
  $d = Dog 22 $true
  Blit $b $d ([int][math]::Floor((54 - $d.Width) / 2)) 17
  $d.Dispose()
  foreach ($p in @(@(8, 20), @(45, 23), @(9, 26), @(44, 17))) { Px $b $p[0] $p[1] $hy3; Px $b ($p[0] - 1) ($p[1] + 1) $hy3; Px $b ($p[0] + 1) ($p[1] + 1) $hy3; Px $b $p[0] ($p[1] + 2) $hy3 }
  Save $b 'hotdog_menu.png'
}

# ---- 床のマット 60x22（赤と白の市松に黄色のふち、まんなかにホットドッグ）
if (Want 'mat') {
  $b = NewBmp 60 22
  Rect $b 0 0 60 22 $hr0; Rect $b 2 2 56 18 $hy1
  for ($y = 4; $y -lt 18; $y++) { for ($x = 4; $x -lt 56; $x++) { if ((([math]::Floor(($x - 4) / 4) + [math]::Floor(($y - 4) / 4)) % 2) -eq 0) { Px $b $x $y $hr1 } else { Px $b $x $y $paper } } }
  Rect $b 19 5 22 12 $hy2; Frame $b 19 5 22 12 $hy0
  $d = Dog 12 $true
  Blit $b $d 22 5
  $d.Dispose()
  foreach ($p in @(@(0, 0), @(59, 0), @(0, 21), @(59, 21))) { Clear $b $p[0] $p[1] }
  Save $b 'hotdog_mat.png'
}
