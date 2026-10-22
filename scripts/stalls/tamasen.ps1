# たませんや（たません屋台）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/tamasen.ps1   （リポジトリのルートで）
# 出力: client/public/brand/stall/tamasen_*.png（原点は各スプライトの足元。配置は scripts/stalls/tamasen.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
# アニメは「フレームを横一列に並べたPNG」。tamasen.mjs の k.custom(name, ox, oy, {frames, fps}) で再生する。
# 一部だけ作り直す: $env:TAMASEN_ONLY='sign|griddle'  （ファイル名の正規表現）
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（みどり・たまごの黄色・せんべいの狐色。ほかの屋台の赤白/紺/黒と変える）
$tl0 = C '#12433f'; $tl1 = C '#1e6e66'; $tl2 = C '#2f9c8f'; $tl3 = C '#7fd8c8'
$sb0 = C '#8a5a2a'; $sb0b = C '#a8703a'; $sb1 = C '#dcA85e'; $sb2 = C '#f0c984'; $sb3 = C '#fae3b0'; $shr = C '#e88a6c'
$ew = C '#fffdf4'; $ew2 = C '#e3dcc2'; $yk = C '#f9b81c'; $yk2 = C '#ffe066'; $yk3 = C '#d98a10'; $crisp = C '#cf9f40'
$sauce = C '#5a2a12'; $sauce2 = C '#85431c'
$pap = C '#f4ecd4'; $pap2 = C '#d6c79e'; $pap3 = C '#a69668'
$cream2 = C '#fff6dc'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# ---- 小さな道具
function Blit($dst, $src, $x, $y) {
  for ($j = 0; $j -lt $src.Height; $j++) { for ($i = 0; $i -lt $src.Width; $i++) { $p = $src.GetPixel($i, $j); if ($p.A -gt 0) { Px $dst ($x + $i) ($y + $j) $p } } }
}
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
# 絵を1枚ずつ（横に $n コマ並べて）作って保存する。$draw は param($b,$f) で、$b は1コマ分の空の絵
function Sheet($name, $w, $h, $n, $draw) {
  if ($env:TAMASEN_ONLY -and ($name -notmatch $env:TAMASEN_ONLY)) { return }
  $sheet = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) {
    $fr = NewBmp $w $h
    & $draw $fr $f
    Blit $sheet $fr ($f * $w) 0
    $fr.Dispose()
  }
  Save $sheet "$name.png"
}

# 丸いえびせんべい（斜め上から）。cx,cy は上面の中心。えびのつぶつぶと、ふちのぎざぎざ
function Sembei($b, $cx, $cy, $rx, $ry, $nfl) {
  Ellipse $b $cx ($cy + 1.0) ($rx + 0.9) ($ry + 0.9) $sb0
  Ellipse $b $cx ($cy + 0.6) $rx $ry $sb0b
  Ellipse $b $cx $cy $rx $ry $sb1
  Ellipse $b ($cx - $rx * 0.12) ($cy - $ry * 0.12) ($rx * 0.8) ($ry * 0.78) $sb2
  for ($k = 0; $k -lt $nfl; $k++) {
    $fx = $cx + ((($k * 37 + 11) % 100) / 50.0 - 1) * $rx * 0.68
    $fy = $cy + ((($k * 53 + 7) % 100) / 50.0 - 1) * $ry * 0.6
    if ($k % 3 -eq 2) { Px $b $fx $fy $sb3 } else { Px $b $fx $fy $shr }
  }
}
# 目玉焼き。cx,cy は中心。$edge はふちの色（鉄板の上では焦げ目、お皿では少し影）
function FriedEgg($b, $cx, $cy, $rx, $ry, $edge) {
  Ellipse $b $cx $cy ($rx + 0.9) ($ry + 0.9) $edge
  Ellipse $b ($cx - $rx * 0.5) ($cy + $ry * 0.2) ($rx * 0.55 + 0.9) ($ry * 0.7 + 0.9) $edge
  Ellipse $b ($cx + $rx * 0.55) ($cy - $ry * 0.15) ($rx * 0.5 + 0.9) ($ry * 0.65 + 0.9) $edge
  Ellipse $b $cx $cy $rx $ry $ew
  Ellipse $b ($cx - $rx * 0.5) ($cy + $ry * 0.2) ($rx * 0.55) ($ry * 0.7) $ew
  Ellipse $b ($cx + $rx * 0.55) ($cy - $ry * 0.15) ($rx * 0.5) ($ry * 0.65) $ew
  Ellipse $b ($cx + $rx * 0.1) ($cy - $ry * 0.05) ($ry * 0.85) ($ry * 0.68) $yk3
  Ellipse $b ($cx + $rx * 0.1) ($cy - $ry * 0.15) ($ry * 0.72) ($ry * 0.55) $yk
  Px $b ($cx + $rx * 0.1 - $ry * 0.3) ($cy - $ry * 0.4) $yk2
}
# 二つ折りのたません（まっすぐな辺が手前下。ソース・卵がのぞく）。by は直線の位置
function Fold($b, $cx, $by, $rx, $ry) {
  for ($y = $by - $ry - 1; $y -le $by + 2; $y++) {
    for ($x = [math]::Floor($cx - $rx - 1); $x -le [math]::Ceiling($cx + $rx + 1); $x++) {
      $dx = ($x + 0.5 - $cx) / ($rx + 0.9); $dy = ($y + 0.5 - $by) / ($ry + 0.9)
      if ($y -le $by + 2 -and ($dx * $dx + $dy * $dy -le 1 -or ($y -ge $by -and [math]::Abs($x + 0.5 - $cx) -le $rx + 0.9))) { Px $b $x $y $sb0 }
    }
  }
  for ($y = $by - $ry; $y -lt $by - 1; $y++) {
    for ($x = [math]::Floor($cx - $rx); $x -le [math]::Ceiling($cx + $rx); $x++) {
      $dx = ($x + 0.5 - $cx) / $rx; $dy = ($y + 0.5 - $by) / $ry
      if ($dx * $dx + $dy * $dy -le 1) { Px $b $x $y $sb1 }
    }
  }
  # つやのある上のふち
  for ($y = $by - $ry; $y -lt $by - 2; $y++) {
    for ($x = [math]::Floor($cx - $rx * 0.8); $x -le [math]::Ceiling($cx + $rx * 0.3); $x++) {
      $dx = ($x + 0.5 - $cx + 1) / ($rx * 0.78); $dy = ($y + 0.5 - $by + 1) / ($ry * 0.78)
      if ($dx * $dx + $dy * $dy -le 1) { Px $b $x $y $sb2 }
    }
  }
  Px $b ($cx - $rx * 0.4) ($by - $ry * 0.55) $shr; Px $b ($cx + $rx * 0.35) ($by - $ry * 0.7) $shr; Px $b ($cx + $rx * 0.1) ($by - $ry * 0.3) $sb3
  # はさんだ中身（ソース・白身・黄身）
  $x0 = [int]($cx - $rx + 1); $x1 = [int]($cx + $rx - 1)
  for ($x = $x0; $x -le $x1; $x++) {
    Px $b $x ($by - 1) $sauce
    Px $b $x $by $ew
    $near = [math]::Abs($x - $cx) -lt [math]::Max(1.5, $rx * 0.42)
    if ($near) { Px $b $x ($by + 1) $yk } else { Px $b $x ($by + 1) $ew2 }
  }
  Px $b ($x0 + 1) ($by - 1) $sauce2; Px $b ($x1 - 2) ($by - 1) $sauce2
}
# 紙に包んだたません（16x16）。cx,by は Fold と同じ
function Wrap($b, $cx, $by) {
  Fold $b $cx $by 7 6
  # 包み紙（下のほう）
  for ($y = $by - 2; $y -le $by + 5; $y++) {
    $ins = 0; if ($y -gt $by + 3) { $ins = 1 }
    for ($x = $cx - 7 + $ins; $x -le $cx + 6 - $ins; $x++) {
      $c = $pap
      if ($x -eq $cx - 7 + $ins) { $c = $pap3 } elseif ($x -eq $cx + 6 - $ins) { $c = $pap3 } elseif ($y -eq $by + 5) { $c = $pap3 } elseif ($x -gt $cx + 3) { $c = $pap2 }
      Px $b $x $y $c
    }
  }
  for ($x = $cx - 6; $x -le $cx + 5; $x++) { if (($x % 2) -eq 0) { Px $b $x ($by - 3) $pap3; Px $b $x ($by - 2) $pap } else { Px $b $x ($by - 2) $pap3 } }
  for ($x = $cx - 6; $x -le $cx + 5; $x++) { Px $b $x ($by + 1) $tl2 }
  Px $b ($cx - 1) ($by + 3) $pap3; Px $b ($cx - 1) ($by + 4) $pap3; Px $b ($cx + 3) ($by + 3) $pap2
}

# =====================================================================
# ---- 看板（屋根の上に掲げる）96x30。緑の板に金のふち。電球がかわりばんこに光る（2コマ）。「たませんや」
Sheet 'tamasen_sign' 96 30 2 {
  param($b, $f)
  Rect $b 14 0 2 5 $w3; Rect $b 80 0 2 5 $w3
  Rect $b 0 4 96 26 $tl0; Rect $b 1 5 94 24 $w2; Rect $b 3 7 90 20 $tl1
  Frame $b 4 8 88 18 $gold
  foreach ($p in @(@(0, 4), @(95, 4), @(0, 29), @(95, 29))) { Clear $b $p[0] $p[1] }
  Rect $b 3 7 90 1 $tl2
  for ($i = 0; $i -lt 15; $i++) {
    $x = 6 + $i * 6
    if (($i + $f) % 2 -eq 0) { $c = C '#fff6b0' } else { $c = C '#a97a22' }
    Px $b $x 8 $c; Px $b ($x + 1) 8 $c; Px $b $x 25 $c; Px $b ($x + 1) 25 $c
  }
  Fold $b 14 21 7 7
  [void](TextPx $b 'たませんや' 26 12 12 $tl0 $true)
  [void](TextPx $b 'たませんや' 25 11 12 $cream2 $true)
}

# ---- のぼり旗 16x78（左の棒の足元が原点）。緑の布に白い縦書き「たません」と目玉焼き
Sheet 'tamasen_nobori' 16 78 1 {
  param($b, $f)
  Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 76 $w2; Rect $b 0 2 1 76 $w3
  Rect $b 2 4 13 66 $tl1; Rect $b 2 4 1 66 $tl2; Rect $b 14 4 1 66 $tl0
  for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 70 $tl1; Px $b (2 + $i) 71 $tl0 } }
  $chars = 'た', 'ま', 'せ', 'ん'
  for ($i = 0; $i -lt 4; $i++) { [void](TextPx $b $chars[$i] 3 (6 + 12 * $i) 11 $cream2 $false) }
  FriedEgg $b 8.5 61 5 3.6 $tl0
}

# ---- 提灯（3コマ: あかりがゆらぐ）14x24。白い紙にたまごのしるし
Sheet 'tamasen_lantern_a' 14 24 3 {
  param($b, $f)
  Rect $b 6 0 1 4 $ol
  Rect $b 3 4 8 2 $tl0
  $glow = @((C '#fff1b8'), (C '#ffe38a'), (C '#fff7d6'))[$f]
  Ellipse $b 7 12.5 6.5 7 $pap2
  Ellipse $b 7 12.5 5.6 6.2 $glow
  Rect $b 2 9 10 1 $pap2; Rect $b 1 12 12 1 $pap2; Rect $b 2 15 10 1 $pap2
  FriedEgg $b 7 12.5 3.4 2.6 $pap2
  Rect $b 3 18 8 2 $tl0
  Rect $b 6 20 2 4 $gold
  if ($f -eq 1) { Px $b 3 8 $ew; Px $b 4 7 $ew }
}

# ---- 日よけの屋根 124x26（緑とクリームのしま。手前のへりは丸いぎざぎざ）。足元が下のへり
Sheet 'tamasen_roof' 124 26 1 {
  param($b, $f)
  $RW = 124
  for ($y = 0; $y -lt 9; $y++) {
    $inset = 9 - $y
    for ($x = $inset; $x -lt $RW - $inset; $x++) {
      $stripe = [math]::Floor($x / 8) % 2
      if ($stripe -eq 0) { $c = $tl1 } else { $c = $cream2 }
      if ($y -eq 0) { $c = $tl3 }
      Px $b $x $y $c
    }
  }
  for ($x = 0; $x -lt $RW; $x++) { Px $b $x 9 $tl0 }
  for ($y = 10; $y -lt 23; $y++) {
    for ($x = 0; $x -lt $RW; $x++) {
      $stripe = [math]::Floor($x / 8) % 2
      if ($stripe -eq 0) { $c = $tl1 } else { $c = $cream2 }
      $mid = ($x % 8) - 3.5
      if ($y -ge 18) {
        $dy = $y - 18; $lim = [math]::Sqrt([math]::Max(0.0, 20.25 - $mid * $mid))
        if ($dy -gt $lim) { continue }
      }
      if ($y -eq 10 -and $stripe -eq 0) { $c = $tl2 }
      if ($x % 8 -eq 7 -and $stripe -eq 1) { $c = $pap2 }
      Px $b $x $y $c
    }
  }
  Rect $b 0 10 1 8 $tl0; Rect $b 123 10 1 8 $tl0
}

# ---- 柱 6x48（足元が原点）。上に緑の布をまく
Sheet 'tamasen_post' 6 48 1 {
  param($b, $f)
  Rect $b 0 0 6 48 $ol; Rect $b 1 0 4 47 $w2; Rect $b 1 0 1 47 $w1; Rect $b 4 0 1 47 $w3
  Rect $b 1 12 4 5 $tl1; Rect $b 1 12 4 1 $tl2; Rect $b 1 16 4 1 $tl0
}

# ---- 店の床（木の板）124x36。カウンターの内側に敷く
Sheet 'tamasen_floor' 124 36 1 {
  param($b, $f)
  Rect $b 0 0 124 36 $w2
  for ($y = 0; $y -lt 36; $y += 6) { Rect $b 0 $y 124 1 $w3 }
  for ($row = 0; $row -lt 6; $row++) {
    $off = ($row * 23) % 31
    for ($x = $off; $x -lt 124; $x += 31) { Rect $b $x ($row * 6) 1 6 $w3 }
    for ($x = ($off + 9) % 31; $x -lt 124; $x += 31) { Px $b $x ($row * 6 + 3) $w1; Px $b ($x + 1) ($row * 6 + 3) $w1 }
  }
  foreach ($p in @(@(0, 0), @(123, 0), @(0, 35), @(123, 35))) { Clear $b $p[0] $p[1] }
}

# ---- カウンター 120x24。上の面と、緑の前板に丸いせんべいの模様
Sheet 'tamasen_counter' 120 24 1 {
  param($b, $f)
  Rect $b 0 0 120 24 $ol
  Rect $b 1 1 118 8 $w1; Rect $b 1 1 118 1 $cream; Rect $b 1 8 118 1 $w2
  Rect $b 1 9 118 14 $w2
  Rect $b 3 11 114 11 $tl1; Rect $b 3 11 114 1 $tl2; Rect $b 3 21 114 1 $tl0
  for ($i = 0; $i -lt 8; $i++) {
    $cx = 10 + $i * 14.5
    Ellipse $b $cx 16.5 4.6 4.6 $sb0; Ellipse $b $cx 16.5 3.8 3.8 $sb1; Ellipse $b ($cx - 0.5) 16 2.6 2.6 $sb2
    Px $b ($cx + 1) 17 $shr; Px $b ($cx - 1) 15 $shr
  }
  Rect $b 0 23 120 1 $ol
  foreach ($p in @(@(0, 0), @(119, 0))) { Clear $b $p[0] $p[1] }
}

# ---- 丸い鉄板（5つの卵がジュージュー焼ける。火もゆらぐ。4コマ）60x40。足元が原点
Sheet 'tamasen_griddle_a' 60 40 4 {
  param($b, $f)
  Ellipse $b 30 26 29.5 10.5 $iron0
  Rect $b 1 12 58 14 $iron1
  Rect $b 4 12 2 14 $iron2; Rect $b 54 12 3 14 $iron0
  Ellipse $b 30 12 30 10.5 $iron3
  Ellipse $b 30 12 28.6 9.4 $iron1
  Ellipse $b 30 11.4 27 8.2 (C '#3a3a46')
  # 油のつや
  Px $b 8 9 $iron3; Px $b 9 8 $iron3; Px $b 50 8 $iron3; Px $b 51 9 $iron3
  # 火の穴（炎がゆらぐ）
  foreach ($vx in 12, 26, 40) {
    Rect $b $vx 25 8 7 $iron0
    $i = [math]::Floor(($vx - 12) / 14)
    $h = 2 + (($f + $i) % 3)
    Rect $b ($vx + 1) (31 - $h) 6 $h (C '#f2860c')
    Rect $b ($vx + 2) (31 - $h + 1) 4 ([math]::Max(1, $h - 1)) (C '#ffd24a')
    Px $b ($vx + 3 + ($f % 2)) (30 - $h) (C '#ffbe3a')
  }
  Rect $b 52 21 4 4 $red; Rect $b 52 21 4 1 $red3
  # 卵
  $eggs = @(@(14, 13, 6.8, 3.6), @(30, 16, 7.4, 3.9), @(46, 13, 6.8, 3.6), @(22, 6, 6.2, 3.2), @(38, 6, 6.2, 3.2))
  for ($i = 0; $i -lt 5; $i++) {
    $e = $eggs[$i]
    FriedEgg $b $e[0] $e[1] $e[2] $e[3] $crisp
    # ジュージュー: ふちに泡のきらめきが、コマごとに動く
    for ($k = 0; $k -lt 3; $k++) {
      $a = ($f * 1.7 + $i * 2.3 + $k * 2.1)
      $px = $e[0] + [math]::Cos($a) * $e[2] * 0.85
      $py = $e[1] + [math]::Sin($a) * $e[3] * 0.85
      Px $b $px $py $ew
      Px $b ($px + 1) ($py - 1) (C '#fffbe8')
    }
    Px $b ($e[0] + [math]::Cos($f * 1.3 + $i) * $e[2] * 1.05) ($e[1] + [math]::Sin($f * 1.3 + $i) * $e[3] * 1.0) $crisp
    # 油のはね
    Px $b ($e[0] - $e[2] - 1 + (($f * 3 + $i) % 4)) ($e[1] - $e[3] - 1 - ($f % 2)) (C '#ffe9a6')
  }
}

# ---- 湯気（6コマのアニメ）22x28。鉄板の上でゆらゆら
Sheet 'tamasen_steam' 22 28 6 {
  param($b, $f)
  for ($k = 0; $k -lt 3; $k++) {
    $phase = (($f * 4) + ($k * 8)) % 24
    $t = $phase / 24.0
    $y = 25 - $phase
    $x = 11 + [math]::Sin($t * 6.28 * 1.4 + $k * 2.1) * 4 + ($k - 1) * 3
    $r = 1.8 + $t * 3.2
    $a = [int](235 * (1 - $t))
    Ellipse $b $x $y $r ($r * 0.85) ([System.Drawing.Color]::FromArgb($a, 255, 255, 255))
    Ellipse $b ($x - $r * 0.25) ($y - $r * 0.25) ($r * 0.5) ($r * 0.4) ([System.Drawing.Color]::FromArgb([int]($a * 0.9), 255, 245, 220))
  }
}

# ---- せんべいの山 36x25（丸いえびせんべいを重ねた山と、立てかけた1枚）
Sheet 'tamasen_pile' 36 25 1 {
  param($b, $f)
  # 立てかけた1枚（正面から見た丸）
  Ellipse $b 27 12 8.8 8.8 $sb0
  Ellipse $b 27 12 7.8 7.8 $sb1
  Ellipse $b 26 11 6.2 6.2 $sb2
  foreach ($d in @(@(24, 8), @(29, 10), @(26, 14), @(30, 15), @(23, 12), @(28, 7))) { Px $b $d[0] $d[1] $shr }
  Px $b 25 9 $sb3
  # 重ねた山（下から3枚）
  for ($i = 0; $i -lt 3; $i++) {
    $cy = 19 - $i * 3.4
    $dx = @(0, 0.8, -0.6)[$i]
    Ellipse $b (13 + $dx) ($cy + 1.6) 12.4 4.6 $sb0
    Ellipse $b (13 + $dx) ($cy + 1.0) 11.6 4.1 $sb0b
    Ellipse $b (13 + $dx) $cy 11.6 4.1 $sb1
    if ($i -lt 2) { Rect $b ([int](1.6 + $dx)) ([int]($cy + 1)) 23 1 $sb0 }
  }
  Ellipse $b 12.5 12.2 9.2 3.1 $sb2
  foreach ($d in @(@(7, 12), @(11, 11), @(15, 13), @(18, 12), @(9, 13), @(13, 12))) { Px $b $d[0] $d[1] $shr }
  Px $b 10 11 $sb3; Px $b 16 12 $sb3
}

# ---- 作業台 58x30（せんべいで卵をはさむ台）。上に物は別に置く。足元が原点
Sheet 'tamasen_work' 58 30 1 {
  param($b, $f)
  Rect $b 0 0 58 30 $ol
  Rect $b 1 1 56 13 $w1; Rect $b 1 1 56 1 $cream; Rect $b 1 13 56 1 $w2
  for ($x = 14; $x -lt 56; $x += 14) { Rect $b $x 2 1 11 $w2 }
  Rect $b 1 14 56 13 $w2
  Rect $b 3 16 52 9 $tl1; Rect $b 3 16 52 1 $tl2; Rect $b 3 24 52 1 $tl0
  # 前板の字: たません
  [void](TextPx $b 'たません' 7 15 11 $cream2 $false)
  Rect $b 1 27 4 3 $w3; Rect $b 53 27 4 3 $w3
  foreach ($p in @(@(0, 0), @(57, 0))) { Clear $b $p[0] $p[1] }
}

# ---- ひらいたせんべいに卵をのせたところ 22x13
Sheet 'tamasen_open' 22 13 1 {
  param($b, $f)
  Sembei $b 11 6 10 5 6
  FriedEgg $b 11 5.5 6.2 3 $ew2
  # ソースをさっと塗った線
  for ($i = 0; $i -lt 8; $i++) { Px $b (5 + $i * 1.5) (3.5 + ($i % 2) * 5) $sauce2 }
}

# ---- 二つ折りのたません 18x12
Sheet 'tamasen_fold' 18 12 1 {
  param($b, $f)
  Fold $b 9 8 7 6
}

# ---- 紙に包んだできあがり 16x16
Sheet 'tamasen_wrap' 16 16 1 {
  param($b, $f)
  Wrap $b 8 8
}

# ---- ソースのつぼと刷毛 24x18
Sheet 'tamasen_sauce' 24 18 1 {
  param($b, $f)
  $s = NewBmp 20 16
  # つぼ
  Ellipse $s 7.5 12 6.5 3 (C '#6e4a2a')
  Rect $s 2 6 11 7 (C '#8c5a30'); Rect $s 3 6 2 7 (C '#b07a46'); Rect $s 11 6 2 7 (C '#6e4a2a')
  Rect $s 3 4 9 3 (C '#8c5a30'); Rect $s 3 4 9 1 (C '#b07a46')
  Rect $s 4 5 7 2 $sauce; Rect $s 5 5 3 1 $sauce2
  # 刷毛（つぼにさして、とっては立てかける）
  Line $s 10 5 16 0 (C '#d9a35c'); Line $s 11 5 17 0 (C '#b8823e')
  Rect $s 8 4 3 2 $sauce2; Rect $s 9 3 2 1 $sauce
  $o = OutlineBmp $s $ol
  Blit $b $o 1 0
  $o.Dispose(); $s.Dispose()
}

# ---- 卵のカゴ 28x18（わらのカゴに卵がいっぱい）
Sheet 'tamasen_eggs' 28 18 1 {
  param($b, $f)
  $s = NewBmp 26 16
  $eggC = @($ew, (C '#f6e4c4'), $ew, (C '#f2d8b0'), $ew, (C '#f6e4c4'), $ew)
  $pos = @(@(5, 5), @(10, 4), @(15, 5), @(20, 4), @(7, 8), @(13, 8), @(19, 8))
  for ($i = 0; $i -lt 7; $i++) {
    Ellipse $s $pos[$i][0] $pos[$i][1] 3.8 4.3 $ew2
    Ellipse $s $pos[$i][0] $pos[$i][1] 3 3.5 $eggC[$i]
    Px $s ($pos[$i][0] - 1) ($pos[$i][1] - 2) (C '#ffffff')
    Px $s ($pos[$i][0] + 1) ($pos[$i][1] + 2) $ew2
  }
  Rect $s 1 9 24 7 (C '#b88a50'); Rect $s 1 9 24 1 (C '#e0b878')
  for ($y = 10; $y -lt 16; $y++) { for ($x = 1; $x -lt 25; $x++) { if ((($x + $y * 2) % 4) -eq 0) { Px $s $x $y (C '#7a5228') } elseif ((($x + $y * 2) % 4) -eq 2) { Px $s $x $y (C '#d4a468') } } }
  Rect $s 0 8 26 2 (C '#a8743a'); Rect $s 0 8 26 1 (C '#d4a468')
  $o = OutlineBmp $s $ol
  Blit $b $o 1 0
  $o.Dispose(); $s.Dispose()
}

# ---- コテ(へら) 20x8
Sheet 'tamasen_tools' 20 8 1 {
  param($b, $f)
  $s = NewBmp 18 6
  Rect $s 0 2 8 2 (C '#a8743a'); Rect $s 0 2 8 1 (C '#d4a468')
  Rect $s 8 2 2 2 (C '#8d93a8')
  Rect $s 10 0 7 5 (C '#c7ccdc'); Rect $s 10 0 7 1 (C '#eef1fa'); Rect $s 10 4 7 1 (C '#8d93a8')
  $o = OutlineBmp $s $ol
  Blit $b $o 0 0
  $o.Dispose(); $s.Dispose()
}

# ---- メニュー（黒板の立て看板）54x50。足元が原点。中身の種類は書かず、大きなたません1つ
Sheet 'tamasen_menu' 54 50 1 {
  param($b, $f)
  Rect $b 0 0 54 44 $ol; Rect $b 1 1 52 42 $w2; Rect $b 3 3 48 38 (C '#2f5a45')
  Rect $b 6 44 3 6 $w3; Rect $b 45 44 3 6 $w3; Rect $b 6 44 1 6 $w2; Rect $b 45 44 1 6 $w2
  $tw = TextWidth 'たません' 11
  [void](TextPx $b 'たません' ([math]::Floor((54 - $tw) / 2)) 5 11 (C '#ffe14a') $true)
  Fold $b 27 34 15 13
}

# ---- 床のマット 60x22（緑に白いふち。丸いせんべい模様）
Sheet 'tamasen_mat' 60 22 1 {
  param($b, $f)
  Rect $b 0 0 60 22 $tl0; Rect $b 2 2 56 18 $pap; Rect $b 4 4 52 14 $tl1
  for ($i = 0; $i -lt 5; $i++) {
    $cx = 10.5 + $i * 10
    Ellipse $b $cx 11 4 4 $sb0; Ellipse $b $cx 11 3.2 3.2 $sb1; Ellipse $b ($cx - 0.4) 10.6 2 2 $sb2
    Px $b ($cx + 1) 11.6 $shr
  }
  foreach ($p in @(@(0, 0), @(59, 0), @(0, 21), @(59, 21))) { Clear $b $p[0] $p[1] }
}
