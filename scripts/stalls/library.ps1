# 図書委員会の専用ドット絵（看板・奥の本棚の壁・貸出カウンターと小物・猫・低い本棚・ひじかけ椅子・ラグ・座布団・丸テーブル・めくれる本・フロアランプ・おすすめの平積み台・ブックトラック・返却ボックス・脚立・植木・のぼり・光の筋）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/library.ps1   （リポジトリのルートで実行）
#   一部だけ作り直す: $env:LIB_ONLY='wall|counter'; powershell ...（名前の正規表現）
# 出力: client/public/brand/stall/library_*.png（原点は各スプライトの足元中央。配置は scripts/stalls/library.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。本の背表紙は色と飾りの線だけで、題名や実在の作品は描かない。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Want($n) { return ((-not $env:LIB_ONLY) -or ($n -match $env:LIB_ONLY)) }

# ---- 色（木・深緑・ボルドー・クリーム・金）
$k = C '#2b1810'                                                                                   # 輪郭
$wd0 = C '#e0b27a'; $wd1 = C '#b9824f'; $wd2 = C '#8a542f'; $wd3 = C '#5e3822'; $wd4 = C '#3b2214' # 木（明→暗）
$g0 = C '#5b9a7c'; $g1 = C '#3d7a5f'; $g2 = C '#2b5e49'; $g3 = C '#1d4334'; $g4 = C '#13291f'     # 深緑
$bx0 = C '#c25a6c'; $bx1 = C '#9a3550'; $bx2 = C '#6e2238'; $bx3 = C '#471525'                     # ボルドー
$c0 = C '#fff8e6'; $c1 = C '#f3e6c4'; $c2 = C '#dfca98'; $c3 = C '#b9a373'                         # クリーム
$gl0 = C '#f6d36b'; $gl1 = C '#d9a73a'; $gl2 = C '#a67a22'                                         # 金
$inb = C '#241710'                                                                                 # 本棚の奥板
$lf0 = C '#8fd36a'; $lf1 = C '#4fa35a'; $lf2 = C '#2f7a48'; $lf3 = C '#1f5736'                     # 葉
$rust = C '#b4572f'; $rust2 = C '#7c3a1c'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# 背表紙の色: 本体・ハイライト・影
$bk = @(
  @((C '#8c2f45'), (C '#b8506a'), (C '#58192b')),   # ボルドー
  @((C '#2d6a4f'), (C '#4f9473'), (C '#1b4332')),   # 深緑
  @((C '#2f4f7a'), (C '#5079a8'), (C '#1d3252')),   # 紺
  @((C '#d7a63a'), (C '#f2cb6a'), (C '#a97a1e')),   # からし
  @((C '#e9dcc0'), (C '#fff8e6'), (C '#bfae86')),   # クリーム
  @((C '#b4572f'), (C '#d97d4b'), (C '#7c3a1c')),   # 赤茶
  @((C '#6b3a62'), (C '#92588a'), (C '#472441')),   # 紫
  @((C '#3a8a86'), (C '#5fb2ac'), (C '#245c59')),   # 青緑
  @((C '#5a3a24'), (C '#7e5638'), (C '#3b2414'))    # こげ茶
)

# ---- 道具
function Outline($b, $col) {
  $w = $b.Width; $h = $b.Height; $mark = @()
  for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) {
    if ($b.GetPixel($x, $y).A -eq 0) {
      foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $nx = $x + $d[0]; $ny = $y + $d[1]
        if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h -and $b.GetPixel($nx, $ny).A -gt 200) { $mark += , @($x, $y); break }
      }
    }
  } }
  foreach ($m in $mark) { Px $b $m[0] $m[1] $col }
}
# 背表紙 1 冊（x,y が左上、w 幅、h 高さ）。飾り: 0 なし / 1 金の帯 / 2 ラベル / 3 暗い帯 / 4 クリームの線
function Book($b, $x, $y, $w, $h, $i, $deco) {
  $p = $bk[$i]
  Rect $b $x $y $w $h $p[0]
  Rect $b $x $y 1 $h $p[1]
  if ($w -ge 3) { Rect $b ($x + $w - 1) $y 1 $h $p[2] }
  Rect $b $x $y $w 1 $p[1]
  if ($h -ge 8) {
    switch ($deco) {
      1 { Rect $b $x ($y + 2) $w 1 $gl1; Rect $b $x ($y + $h - 3) $w 1 $gl1 }
      2 { if ($w -ge 3) { Rect $b $x ($y + 3) $w 2 $c1 } }
      3 { Rect $b $x ($y + 2) $w 2 $p[2] }
      4 { Rect $b $x ($y + $h - 4) $w 1 $c1 }
    }
  }
}
# 本棚の 1 段に背表紙を詰める。yb = 本の下端Y、h = 段の内側の高さ
function FillBooks($b, $x0, $wid, $yb, $h, $rng) {
  $x = $x0; $prev = -1
  while ($x -lt $x0 + $wid) {
    $bw = $rng.Next(2, 5)
    if ($x + $bw -gt $x0 + $wid) { $bw = $x0 + $wid - $x }
    if ($bw -lt 2) { break }
    $bh = $rng.Next([math]::Max(3, $h - 5), $h)
    $i = $rng.Next(0, $bk.Count); if ($i -eq $prev) { $i = ($i + 3) % $bk.Count }
    $prev = $i
    Book $b $x ($yb - $bh + 1) $bw $bh $i ($rng.Next(0, 5))
    $x += $bw
    if ($rng.Next(0, 9) -eq 0) { $x += 1 }
  }
}
# 平積みの本 1 冊（横から見た図）
function Flat($b, $x, $y, $w, $i) {
  $p = $bk[$i]
  Rect $b $x $y $w 3 $c1
  Rect $b $x $y $w 1 $p[0]; Rect $b $x ($y + 2) $w 1 $p[2]
  Rect $b $x $y 2 3 $p[0]; Px $b $x $y $p[1]
}
# 本棚の段の端に置く飾り: stack / globe / clock / plant
function RowTail($b, $tx, $yb, $kind, $rng) {
  switch ($kind) {
    'stack' {
      Flat $b $tx ($yb - 2) 14 2; Flat $b ($tx + 1) ($yb - 5) 12 0; Flat $b $tx ($yb - 8) 13 1
    }
    'globe' {
      Rect $b ($tx + 3) ($yb - 1) 5 2 $wd3; Rect $b ($tx + 5) ($yb - 3) 1 3 $gl1
      Ellipse $b ($tx + 5.5) ($yb - 5.5) 4.6 4.6 $k; Ellipse $b ($tx + 5.5) ($yb - 5.5) 3.8 3.8 (C '#4aa0a6')
      Rect $b ($tx + 3) ($yb - 7) 3 2 $lf1; Rect $b ($tx + 6) ($yb - 5) 2 3 $c1; Px $b ($tx + 4) ($yb - 4) $lf1
      Px $b ($tx + 3) ($yb - 8) (C '#9fd8dc')
    }
    'clock' {
      Rect $b $tx ($yb - 9) 11 10 $k; Rect $b ($tx + 1) ($yb - 8) 9 9 $wd2; Rect $b ($tx + 1) ($yb - 8) 9 1 $wd0
      Ellipse $b ($tx + 5.5) ($yb - 4.3) 3.6 3.6 $c0; Px $b ($tx + 5) ($yb - 6) $k; Px $b ($tx + 5) ($yb - 5) $k; Px $b ($tx + 6) ($yb - 4) $k; Px $b ($tx + 7) ($yb - 4) $k
      Px $b ($tx + 5) ($yb - 10) $gl0
    }
    'plant' {
      Rect $b ($tx + 2) ($yb - 3) 7 4 $rust; Rect $b ($tx + 2) ($yb - 3) 7 1 (C '#d97d4b'); Rect $b ($tx + 2) $yb 7 1 $rust2
      Ellipse $b ($tx + 5.5) ($yb - 6.5) 4.8 3.4 $lf1; Px $b ($tx + 3) ($yb - 8) $lf0; Px $b ($tx + 6) ($yb - 9) $lf0; Px $b ($tx + 8) ($yb - 7) $lf0
      Px $b ($tx + 4) ($yb - 5) $lf2; Px $b ($tx + 7) ($yb - 5) $lf2
    }
  }
}
function Row($b, $x0, $wid, $yb, $h, $rng, $tail, $side) {
  $tw = 0
  if ($tail) { $tw = 14 }
  if ($tail -and $side -eq 'L') {
    RowTail $b $x0 $yb $tail $rng
    FillBooks $b ($x0 + $tw) ($wid - $tw) $yb $h $rng
  } elseif ($tail) {
    FillBooks $b $x0 ($wid - $tw) $yb $h $rng
    RowTail $b ($x0 + $wid - $tw + 1) $yb $tail $rng
  } else {
    FillBooks $b $x0 $wid $yb $h $rng
  }
}
# 奥の壁の本棚 1 区画（幅60、y 3..53）
function Bay($b, $x, $seed, $t1, $s1, $t2, $s2, $t3, $s3) {
  $rng = New-Object System.Random $seed
  Rect $b ($x - 1) 3 62 3 $wd3; Rect $b ($x - 1) 3 62 1 $wd1; Rect $b ($x - 1) 5 62 1 $wd4         # 上の飾り
  Rect $b $x 6 60 48 $k; Rect $b ($x + 1) 6 58 47 $wd2; Rect $b ($x + 1) 6 1 47 $wd1; Rect $b ($x + 58) 6 1 47 $wd3
  Rect $b ($x + 3) 7 54 35 $inb
  Row $b ($x + 3) 54 16 10 $rng $t1 $s1
  Row $b ($x + 3) 54 28 10 $rng $t2 $s2
  Row $b ($x + 3) 54 40 10 $rng $t3 $s3
  foreach ($by in @(17, 29, 41)) { Rect $b ($x + 2) $by 56 1 $wd1; Rect $b ($x + 2) ($by + 1) 56 1 $wd3 }
  Rect $b ($x + 2) 43 56 1 $k
  # 下の戸棚
  Rect $b ($x + 2) 44 56 9 $wd3
  foreach ($dx in @(3, 30)) { Rect $b ($x + $dx) 45 27 7 $wd2; Frame $b ($x + $dx) 44 27 9 $wd1; Rect $b ($x + $dx + 1) 45 25 1 $wd1 }
  Rect $b ($x + 26) 47 2 2 $gl0; Rect $b ($x + 31) 47 2 2 $gl0
  Rect $b $x 52 60 2 $wd4
}

# ====================================================================================================
# ---- 看板 112x28。ボルドーの板に金のふち、開いた本の絵と「図書委員会」
if (Want 'sign') {
  $b = NewBmp 112 28
  Rect $b 14 0 3 6 $wd3; Rect $b 95 0 3 6 $wd3
  Rect $b 0 5 112 23 $k; Rect $b 1 6 110 21 $gl2; Rect $b 2 7 108 19 $gl0; Rect $b 3 8 106 17 $gl1
  Rect $b 4 9 104 15 $bx2; Rect $b 4 9 104 1 $bx1; Rect $b 4 22 104 2 $bx3
  foreach ($p in @(@(0, 5), @(111, 5), @(0, 27), @(111, 27))) { Px $b $p[0] $p[1] $clear }
  # 開いた本の絵
  Rect $b 8 12 22 11 $k; Rect $b 9 13 10 8 $c0; Rect $b 20 13 10 8 $c0; Rect $b 19 12 1 10 $k
  Rect $b 16 13 3 8 $c1; Rect $b 20 13 3 8 $c1
  foreach ($yy in @(15, 17, 19)) { Rect $b 10 $yy 5 1 $c3; Rect $b 24 $yy 5 1 $c3 }
  Rect $b 9 21 10 1 $c2; Rect $b 20 21 10 1 $c2; Rect $b 18 21 3 3 $gl1; Px $b 19 24 $gl1
  foreach ($p in @(@(8, 12), @(29, 12))) { Px $b $p[0] $p[1] $clear }
  # 文字
  $tw = TextWidth '図書委員会' 12
  [void](TextPx $b '図書委員会' 36 10 12 $c0 $true)
  # かざり
  Px $b 102 15 $gl0; Px $b 101 16 $gl0; Px $b 103 16 $gl0; Px $b 102 17 $gl0; Px $b 102 16 $gl1
  Px $b 100 20 $gl1; Px $b 104 12 $gl1
  Save $b 'library_sign.png'
}

# ---- 奥の壁 176x54: 深緑の壁紙、左右に本棚（背表紙がいろいろ）、まんなかに大きな丸窓、カーテン
if (Want 'wall') {
  $b = NewBmp 176 54
  Rect $b 0 0 176 54 $g2
  for ($x = 0; $x -lt 176; $x += 8) { Rect $b $x 0 1 54 $g3; Rect $b ($x + 1) 0 1 54 $g1 }
  Rect $b 0 0 176 4 $wd3; Rect $b 0 0 176 1 $wd1; Rect $b 0 1 176 1 $wd2; Rect $b 0 3 176 1 $wd4
  # かべ板
  Rect $b 0 43 176 11 $wd2; Rect $b 0 43 176 1 $wd1; Rect $b 0 44 176 1 $wd3
  for ($x = 4; $x -lt 176; $x += 16) { Frame $b $x 46 12 5 $wd3; Rect $b ($x + 1) 47 10 1 $wd1 }
  Rect $b 0 52 176 2 $wd4; Rect $b 0 52 176 1 $wd3
  # 左右の本棚
  Bay $b 2 11 'globe' 'R' 'clock' 'R' $null 'R'
  Bay $b 114 23 $null 'R' 'plant' 'L' 'stack' 'L'
  # 窓（上がまるいアーチ）
  $cx = 88; $wt = 10; $R = 19; $ay = $wt + $R
  for ($y = $wt; $y -le 41; $y++) {
    if ($y -lt $ay) { $t = $ay - $y; $hw = [int][math]::Floor([math]::Sqrt([math]::Max(0.0, $R * $R - $t * $t)) + 0.5) } else { $hw = $R }
    Rect $b ($cx - $hw) $y (2 * $hw) 1 $k
    if ($hw -ge 1) { Rect $b ($cx - $hw + 1) $y (2 * $hw - 2) 1 $wd2 }
    if ($hw -ge 2) { Px $b ($cx - $hw + 1) $y $wd1 }
  }
  $Rg = 15
  for ($y = $wt + 4; $y -le 38; $y++) {
    if ($y -lt $ay) { $t = $ay - $y; $hw = [int][math]::Floor([math]::Sqrt([math]::Max(0.0, $Rg * $Rg - $t * $t)) + 0.5) } else { $hw = $Rg }
    if ($hw -lt 1) { continue }
    $sky = if ($y -lt 20) { C '#c4e6f2' } elseif ($y -lt 28) { C '#dff2f0' } else { C '#eef8e8' }
    Rect $b ($cx - $hw) $y (2 * $hw) 1 $sky
  }
  # 窓の外: 遠い木と芝
  for ($x = $cx - 15; $x -lt $cx + 15; $x++) {
    $hh = 3 + [math]::Floor(2.4 * [math]::Sin($x * 0.55) + 1.6 * [math]::Sin($x * 0.23 + 1))
    for ($y = 34 - $hh; $y -le 38; $y++) { Px $b $x $y $(if (($x + $y) % 5 -eq 0) { $lf0 } else { $lf1 }) }
  }
  Rect $b ($cx - 15) 37 30 2 $lf2
  # 雲
  Rect $b ($cx - 9) 20 7 1 $c0; Rect $b ($cx - 11) 21 11 1 $c0; Rect $b ($cx + 4) 17 5 1 $c0; Rect $b ($cx + 3) 18 8 1 $c0
  # 窓わく（十字）
  Rect $b ($cx - 1) ($wt + 3) 2 36 $wd2; Rect $b ($cx - 1) ($wt + 3) 1 36 $wd1
  Rect $b ($cx - 15) 24 30 2 $wd2; Rect $b ($cx - 15) 24 30 1 $wd1
  Rect $b ($cx - 15) 32 30 2 $wd2; Rect $b ($cx - 15) 32 30 1 $wd1
  # まど辺
  Rect $b 61 40 54 3 $wd1; Rect $b 61 40 54 1 $wd0; Rect $b 61 42 54 1 $wd3; Rect $b 61 43 54 1 $k
  # カーテン（ボルドー、金のひも）
  foreach ($side in @(-1, 1)) {
    for ($y = 9; $y -le 40; $y++) {
      $w = if ($y -lt 25) { 9 } elseif ($y -lt 30) { 5 } else { 10 }
      for ($i = 0; $i -lt $w; $i++) {
        if ($side -lt 0) { $px = 63 + $i } else { $px = 112 - $i }
        $col = switch ($i % 4) { 0 { $bx2 } 1 { $bx1 } 2 { $bx0 } default { $bx1 } }
        Px $b $px $y $col
      }
    }
    if ($side -lt 0) { Rect $b 63 27 5 2 $gl0; Rect $b 63 29 5 1 $gl2 } else { Rect $b 108 27 5 2 $gl0; Rect $b 108 29 5 1 $gl2 }
  }
  Save $b 'library_wall.png'
}

# ---- 床 184x74（木の板張り。草地のうえに敷く）
if (Want 'floor') {
  $b = NewBmp 184 74
  $f1 = C '#c18d58'; $f2 = C '#a8743f'; $f3 = C '#8b5a30'; $f4 = C '#d2a06a'
  Rect $b 0 0 184 74 $f1
  for ($row = 0; $row -lt 12; $row++) {
    $y = $row * 6
    Rect $b 0 $y 184 1 $f3
    Rect $b 0 ($y + 1) 184 1 $f4
    for ($x = (($row * 17) % 31); $x -lt 184; $x += 31) { Rect $b $x ($y + 1) 1 5 $f3 }
    for ($x = (($row * 13) % 29) + 3; $x -lt 184; $x += 29) { Px $b $x ($y + 3) $f2; Px $b ($x + 1) ($y + 3) $f2; Px $b ($x + 5) ($y + 4) $f4 }
  }
  Rect $b 0 0 184 3 $f3; Rect $b 0 3 184 1 $f2                 # 壁際のかげ
  Rect $b 0 72 184 2 $wd4; Rect $b 0 71 184 1 $wd2
  Rect $b 0 0 1 74 $wd4; Rect $b 183 0 1 74 $wd4
  Save $b 'library_floor.png'
}

# ---- 貸出カウンター 94x28。上は明るい木、正面は深緑の羽目板に「しずかに」「貸出」の札
if (Want 'counter') {
  $b = NewBmp 94 28
  Rect $b 0 0 94 28 $k
  Rect $b 1 1 92 8 $wd0; Rect $b 1 1 92 1 $c1; Rect $b 1 8 92 1 $wd1
  Rect $b 0 9 94 2 $wd2; Rect $b 1 9 92 1 $wd1
  Rect $b 2 11 90 14 $g1; Rect $b 2 11 90 1 $g0; Rect $b 2 24 90 1 $g3
  for ($x = 8; $x -lt 92; $x += 8) { Rect $b $x 12 1 12 $g2 }
  Rect $b 2 25 90 3 $wd3; Rect $b 2 25 90 1 $wd2
  # 札: しずかに
  Rect $b 5 12 50 12 $k; Rect $b 6 13 48 10 $c1; Rect $b 6 13 48 1 $c0
  [void](TextPx $b 'しずかに' 8 12 11 $bx2 $true)
  # 札: 貸出
  Rect $b 59 12 30 12 $k; Rect $b 60 13 28 10 $bx1; Rect $b 60 13 28 1 $bx0; Frame $b 60 13 28 10 $gl1
  [void](TextPx $b '貸出' 64 12 11 $c0 $true)
  foreach ($p in @(@(0, 0), @(93, 0), @(0, 27), @(93, 27))) { Px $b $p[0] $p[1] $clear }
  Save $b 'library_counter.png'
}

# ---- カウンターの上の小物
if (Want 'props') {
  # バーコードリーダー 9x12
  $b = NewBmp 9 12
  Rect $b 0 9 9 3 $k; Rect $b 1 9 7 2 $iron1; Rect $b 1 9 7 1 $iron3
  Rect $b 3 5 3 5 $iron2; Rect $b 3 5 1 5 $iron3
  Rect $b 0 1 9 5 $k; Rect $b 1 2 7 3 $iron1; Rect $b 1 2 7 1 $iron3
  Rect $b 2 4 5 1 (C '#ff4d4d'); Px $b 4 6 (C '#ff8a8a')
  Save $b 'library_reader.png'
  # 日付スタンプとインク台 11x10
  $b = NewBmp 11 10
  Rect $b 0 6 11 4 $k; Rect $b 1 7 9 2 (C '#c0344a'); Rect $b 1 7 9 1 (C '#e0627a')
  Rect $b 2 4 7 3 $k; Rect $b 3 5 5 1 $wd3
  Rect $b 4 1 3 4 $k; Rect $b 5 1 1 4 $wd1; Rect $b 3 0 5 2 $k; Rect $b 4 0 3 1 $wd0
  Save $b 'library_stamp.png'
  # 貸出カードのトレイ 13x10
  $b = NewBmp 13 10
  Rect $b 0 6 13 4 $k; Rect $b 1 7 11 2 $wd2; Rect $b 1 7 11 1 $wd0
  $cc = @($gl1, $g1, $bx1, $gl1)
  for ($i = 0; $i -lt 4; $i++) { Rect $b (1 + $i * 3) 1 3 6 $k; Rect $b (2 + $i * 3) 2 2 5 $c0; Rect $b (2 + $i * 3) 2 2 1 $cc[$i] }
  Save $b 'library_cards.png'
  # ブックスタンド（開いた本）15x14
  $b = NewBmp 15 14
  Rect $b 1 12 13 2 $k; Rect $b 2 12 11 1 $wd2
  Rect $b 1 2 13 11 $k; Rect $b 2 3 6 8 $c0; Rect $b 8 3 5 8 $c0; Rect $b 7 3 1 8 $c3
  Rect $b 5 3 3 8 $c1; Rect $b 8 3 2 8 $c1
  foreach ($yy in @(5, 7, 9)) { Rect $b 3 $yy 3 1 $c3; Rect $b 9 $yy 3 1 $c3 }
  Rect $b 2 10 11 1 $bx1; Rect $b 7 10 1 4 $gl1; Px $b 7 14 $gl1
  Px $b 1 2 $clear; Px $b 13 2 $clear
  Save $b 'library_stand.png'
  # しおりのかご 12x12
  $b = NewBmp 12 12
  Rect $b 1 6 10 6 $k; Rect $b 2 7 8 4 $wd2; Rect $b 2 7 8 1 $wd0
  $sc = @($bx0, $gl0, $g0, $c0, $bx0)
  $sx = @(2, 4, 6, 8, 9)
  for ($i = 0; $i -lt 4; $i++) { Rect $b $sx[$i] ($i % 2 + 1) 2 6 $sc[$i]; Px $b $sx[$i] ($i % 2 + 1) $c0 }
  Rect $b 1 6 10 1 $k
  Rect $b 2 7 8 1 $wd0
  Save $b 'library_bookmarks.png'
}

# ---- 本の山の上で眠る猫 28x30 x 4コマ（寝息で背中がふくらむ、zが昇る）
if (Want 'cat') {
  $b = NewBmp (28 * 4) 30
  $or = C '#e8903e'; $or1 = C '#f6b872'; $or2 = C '#b8601f'; $belly = C '#f8e3c0'
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * 28
    $up = @(0.0, 1.0, 2.0, 1.0)[$f]
    # 本の山
    Rect $b ($ox + 2) 26 24 4 $k; Rect $b ($ox + 3) 26 22 2 $bx1; Rect $b ($ox + 3) 28 22 1 $c1; Rect $b ($ox + 3) 29 22 1 $bx2; Rect $b ($ox + 3) 26 22 1 $bx0
    Rect $b ($ox + 4) 23 20 4 $k; Rect $b ($ox + 5) 23 18 2 $g1; Rect $b ($ox + 5) 25 18 1 $c1; Rect $b ($ox + 5) 23 18 1 $g0; Rect $b ($ox + 5) 26 18 1 $g2
    Rect $b ($ox + 3) 20 22 4 $k; Rect $b ($ox + 4) 20 20 2 (C '#d7a63a'); Rect $b ($ox + 4) 22 20 1 $c1; Rect $b ($ox + 4) 20 20 1 (C '#f2cb6a'); Rect $b ($ox + 4) 23 20 1 (C '#a97a1e')
    # 猫の体（食パン座り）
    $ry = 3.8 + 0.5 * $up
    $cy = 20.0 - $ry
    Ellipse $b ($ox + 11.5) $cy 9.8 ($ry + 0.8) $k
    Ellipse $b ($ox + 11.5) $cy 9.0 $ry $or
    Ellipse $b ($ox + 10.5) ($cy - 0.5) 6.5 ($ry * 0.55) $or1
    foreach ($sx in @(6, 9, 12, 15)) { Rect $b ($ox + $sx) ([int]($cy - $ry + 1)) 1 2 $or2 }
    # しっぽ（左はし）
    Rect $b ($ox + 1) 18 3 2 $or; Rect $b ($ox + 0) 17 2 2 $k; Px $b ($ox + 1) 17 $c0; Rect $b ($ox + 1) 20 3 1 $or2; Rect $b ($ox + 2) 17 2 1 $k
    # 頭（右、まるくて耳がとがる）
    Ellipse $b ($ox + 22.5) 17.5 4.9 4.2 $k; Ellipse $b ($ox + 22.5) 17.5 4.1 3.4 $or
    Rect $b ($ox + 18) 12 3 3 $k; Px $b ($ox + 19) 13 $or2; Px $b ($ox + 19) 14 $or; Px $b ($ox + 20) 14 $or; Px $b ($ox + 18) 14 $or
    Rect $b ($ox + 24) 12 3 3 $k; Px $b ($ox + 25) 13 $or2; Px $b ($ox + 25) 14 $or; Px $b ($ox + 24) 14 $or; Px $b ($ox + 26) 14 $or
    Rect $b ($ox + 20) 15 6 1 $or1
    Px $b ($ox + 20) 17 $k; Px $b ($ox + 21) 18 $k; Px $b ($ox + 22) 18 $k; Px $b ($ox + 24) 18 $k; Px $b ($ox + 25) 18 $k; Px $b ($ox + 26) 17 $k   # とじた目
    Rect $b ($ox + 22) 19 3 2 $belly; Px $b ($ox + 23) 19 (C '#f08aa0')
    Px $b ($ox + 20) 19 (C '#f6a0a8'); Px $b ($ox + 26) 19 (C '#f6a0a8')
    # z
    $zy = 11 - $f * 2
    if ($zy -ge 0) { Rect $b ($ox + 19) $zy 3 1 $c0; Px $b ($ox + 20) ($zy + 1) $c0; Rect $b ($ox + 19) ($zy + 2) 3 1 $c0 }
    $zy2 = 5 - $f * 2 + 2
    if ($f -ge 1 -and $zy2 -ge 0) { Rect $b ($ox + 23) $zy2 2 1 $c1; Px $b ($ox + 23) ($zy2 + 1) $c1; Rect $b ($ox + 23) ($zy2 + 2) 2 1 $c1 }
  }
  Save $b 'library_cat.png'
}

# ---- 低い本棚（絵本の表紙を見せる棚）40x36。上に鉢と本、上の段に表紙、下の段に背表紙
if (Want 'lowshelf') {
  $b = NewBmp 40 36
  $rng = New-Object System.Random 77
  Rect $b 0 9 40 6 $k; Rect $b 1 10 38 4 $wd0; Rect $b 1 10 38 1 $c1; Rect $b 1 13 38 1 $wd1
  Rect $b 0 15 40 21 $k; Rect $b 1 15 38 20 $wd2; Rect $b 1 15 1 20 $wd1; Rect $b 38 15 1 20 $wd3
  Rect $b 3 17 34 11 $inb
  $cv = @(@(0, 'sun'), @(1, 'tree'), @(2, 'star'), @(3, 'heart'))
  for ($i = 0; $i -lt 4; $i++) {
    $cx0 = 4 + $i * 8; $ci = $cv[$i][0]; $p = $bk[$ci]
    Rect $b $cx0 18 7 9 $p[0]; Frame $b $cx0 18 7 9 $p[1]; Rect $b ($cx0 + 6) 19 1 8 $p[2]
    switch ($cv[$i][1]) {
      'sun' { Rect $b ($cx0 + 2) 21 3 3 $gl0; Px $b ($cx0 + 3) 20 $gl0; Px $b ($cx0 + 3) 24 $gl0 }
      'tree' { Rect $b ($cx0 + 3) 24 1 2 $wd3; Rect $b ($cx0 + 2) 22 3 2 $lf0; Px $b ($cx0 + 3) 21 $lf0 }
      'star' { Px $b ($cx0 + 3) 20 $gl0; Rect $b ($cx0 + 2) 21 3 1 $gl0; Rect $b ($cx0 + 3) 22 1 3 $gl0; Px $b ($cx0 + 2) 24 $gl0; Px $b ($cx0 + 4) 24 $gl0 }
      'heart' { Px $b ($cx0 + 2) 21 $c0; Px $b ($cx0 + 4) 21 $c0; Rect $b ($cx0 + 2) 22 3 1 $c0; Px $b ($cx0 + 3) 23 $c0 }
    }
  }
  Rect $b 2 28 36 2 $wd1; Rect $b 2 29 36 1 $wd3
  Rect $b 3 30 34 5 $inb
  FillBooks $b 3 34 34 6 $rng
  Rect $b 0 34 40 2 $k; Rect $b 2 35 36 1 $wd4
  # 上のもの: 鉢植えと本
  Rect $b 4 5 8 5 $k; Rect $b 5 6 6 3 $rust; Rect $b 5 6 6 1 (C '#d97d4b')
  Ellipse $b 8 3.5 4.6 3.4 $lf1; Px $b 6 1 $lf0; Px $b 9 0 $lf0; Px $b 11 3 $lf0; Px $b 6 4 $lf2; Px $b 9 4 $lf2
  Flat $b 22 7 13 4; Flat $b 23 4 11 1; Rect $b 24 1 9 3 $k; Rect $b 25 2 7 1 $c0
  Save $b 'library_lowshelf.png'
}

# ---- ひじかけ椅子（うしろ 30x32 と まえ 30x12。人を挟むと座って見える）
if (Want 'chair') {
  $b = NewBmp 30 32
  # 背もたれ
  Rect $b 4 1 22 22 $k; Rect $b 5 2 20 21 $g1; Rect $b 5 2 20 2 $g0; Rect $b 5 2 1 21 $g0; Rect $b 24 2 1 21 $g2
  Px $b 4 1 $clear; Px $b 25 1 $clear
  for ($y = 6; $y -lt 22; $y += 4) { Px $b 12 $y $g2; Px $b 17 ($y + 2) $g2; Px $b 12 ($y + 1) $g0 }
  Px $b 14 6 $gl0; Px $b 14 12 $gl0; Px $b 14 18 $gl0
  # 座面のうしろ側とひじかけ
  Rect $b 4 21 22 6 $c2; Rect $b 4 21 22 1 $c1
  Rect $b 0 14 6 17 $k; Rect $b 1 15 4 16 $g1; Rect $b 1 15 4 2 $g0; Rect $b 1 16 1 15 $g0; Rect $b 4 17 1 14 $g2
  Rect $b 24 14 6 17 $k; Rect $b 25 15 4 16 $g1; Rect $b 25 15 4 2 $g0; Rect $b 25 16 1 15 $g0; Rect $b 28 17 1 14 $g2
  Px $b 0 14 $clear; Px $b 5 14 $clear; Px $b 24 14 $clear; Px $b 29 14 $clear
  Save $b 'library_chair_back.png'
  $b = NewBmp 30 9
  # 座面の前と、ひじかけの前
  Rect $b 4 0 22 7 $k; Rect $b 5 1 20 5 $c1; Rect $b 5 1 20 1 $c0; Rect $b 5 5 20 1 $c3; Rect $b 14 1 1 5 $c2
  Rect $b 3 6 24 3 $k; Rect $b 4 6 22 2 $g1; Rect $b 4 6 22 1 $gl1
  Rect $b 0 0 6 8 $k; Rect $b 1 1 4 6 $g1; Rect $b 1 1 1 6 $g0; Rect $b 4 1 1 6 $g2
  Rect $b 24 0 6 8 $k; Rect $b 25 1 4 6 $g1; Rect $b 25 1 1 6 $g0; Rect $b 28 1 1 6 $g2
  Rect $b 1 8 3 1 $k; Rect $b 26 8 3 1 $k
  Save $b 'library_chair_front.png'
}

# ---- ラグ 64x30（だ円。ボルドーにクリームの縁と深緑のひし形）
if (Want 'rug') {
  $b = NewBmp 64 30
  Ellipse $b 32 15 32 15 $bx3; Ellipse $b 32 15 31 14 $bx1
  Ellipse $b 32 15 28 11.5 $c2; Ellipse $b 32 15 27 10.5 $bx2
  Ellipse $b 32 15 22 8 $bx1
  foreach ($d in @(-12, 0, 12)) {
    for ($y = -5; $y -le 5; $y++) { $hw = 6 - [math]::Abs($y); if ($hw -gt 0) { Rect $b ([int](32 + $d - $hw)) (15 + $y) (2 * $hw) 1 $(if ($d -eq 0) { $c1 } else { $g1 }) } }
    Px $b (32 + $d) 15 $(if ($d -eq 0) { $bx1 } else { $c1 })
  }
  foreach ($d in @(-6, 6)) { Px $b (32 + $d) 15 $gl1; Px $b (32 + $d) 14 $gl1 }
  for ($x = 6; $x -lt 58; $x += 2) { Px $b $x 5 $c3 }
  Save $b 'library_rug.png'
}

# ---- 丸い座布団 18x10
if (Want 'zabuton') {
  $b = NewBmp 18 10
  Ellipse $b 9 6 9 4 $k; Ellipse $b 9 5.5 8.2 3.5 $g2; Ellipse $b 9 4.2 8 3.4 $g1; Ellipse $b 9 3.6 6.4 2.6 $g0
  Px $b 9 4 $c1; Px $b 8 4 $g1; Px $b 10 4 $g1; Px $b 9 3 $g1; Px $b 9 5 $g1
  Rect $b 4 8 10 1 $g3
  Save $b 'library_zabuton.png'
}

# ---- 小さな丸テーブル 30x24（上にマグカップ）
if (Want 'rtable') {
  $b = NewBmp 30 24
  Ellipse $b 15 7 14.5 6 $k; Ellipse $b 15 7 13.6 5.2 $wd1; Ellipse $b 15 6.4 12.4 4.4 $wd0; Ellipse $b 15 6.2 9 2.8 $c2
  Rect $b 2 8 26 2 $wd2
  Rect $b 13 13 4 7 $k; Rect $b 14 13 2 7 $wd2
  Ellipse $b 15 21 8 2.6 $k; Ellipse $b 15 20.8 7 2 $wd3
  Rect $b 23 1 5 4 $k; Rect $b 24 2 3 3 $c0; Rect $b 24 2 3 1 $bx1; Px $b 28 2 $k; Px $b 28 3 $k
  Save $b 'library_rtable.png'
}

# ---- ページがめくれる開いた本 18x12 x 6コマ
if (Want 'book') {
  $b = NewBmp (18 * 6) 12
  for ($f = 0; $f -lt 6; $f++) {
    $ox = $f * 18
    Rect $b ($ox + 0) 6 18 6 $k; Rect $b ($ox + 1) 7 16 3 $bx1; Rect $b ($ox + 1) 7 16 1 $bx0
    Rect $b ($ox + 1) 3 8 6 $c0; Rect $b ($ox + 9) 3 8 6 $c0; Rect $b ($ox + 8) 3 2 7 $c3
    Rect $b ($ox + 1) 6 8 1 $c2; Rect $b ($ox + 9) 6 8 1 $c2
    foreach ($yy in @(4, 5)) { Rect $b ($ox + 2) $yy 5 1 $c3 }
    if ($f -eq 0 -or $f -eq 5) { foreach ($yy in @(4, 5)) { Rect $b ($ox + 11) $yy 5 1 $c3 } }
    Px $b ($ox + 15) 9 $gl1
    Rect $b ($ox + 1) 10 16 1 $bx2
    if ($f -ge 1 -and $f -le 4) {
      $th = [math]::PI * $f / 5.0
      for ($a2 = 0; $a2 -le 6; $a2++) {
        $t2 = [math]::Max(0.0, $th - $a2 * 0.09)
        $tx = [int][math]::Round(9 + 8 * [math]::Cos($t2)); $ty = [int][math]::Round(7 - 6.5 * [math]::Sin($t2))
        Line $b ($ox + 9) 7 ($ox + $tx) $ty $(if ($a2 -eq 0) { $c3 } elseif ($a2 -lt 3) { $c0 } else { $c1 })
      }
    }
  }
  Save $b 'library_book.png'
}

# ---- フロアランプ 14x52
if (Want 'lamp') {
  $b = NewBmp 14 52
  Ellipse $b 7 49 6 2.6 $k; Ellipse $b 7 48.6 5 2 $wd3; Ellipse $b 7 48.2 3.6 1.2 $wd1
  Rect $b 6 14 2 34 $k; Rect $b 6 14 1 34 $gl1; Rect $b 7 14 1 34 $gl2
  Rect $b 5 47 4 2 $gl2; Rect $b 5 47 4 1 $gl0
  # シェード
  for ($y = 2; $y -le 14; $y++) {
    $hw = [int][math]::Floor(3.5 + ($y - 2) * 0.5)
    Rect $b (7 - $hw - 1) $y (2 * $hw + 2) 1 $k
    Rect $b (7 - $hw) $y (2 * $hw) 1 $(if ($y -lt 12) { $c1 } else { $gl0 })
    Px $b (7 - $hw) $y $c0
    Px $b (6 + $hw) $y $c2
  }
  Rect $b 3 14 8 1 $gl2
  Rect $b 6 4 2 8 $c0
  Rect $b 4 1 6 1 $k
  Save $b 'library_lamp.png'
}

# ---- ランプの光 44x44 x 4コマ（ゆらぐ）
if (Want 'glow') {
  $b = NewBmp (44 * 4) 44
  $rr = @(19.0, 21.0, 20.0, 18.0)
  $am = @(80.0, 96.0, 88.0, 72.0)
  for ($f = 0; $f -lt 4; $f++) {
    for ($y = 0; $y -lt 44; $y++) { for ($x = 0; $x -lt 44; $x++) {
      $d = [math]::Sqrt(($x - 21.5) * ($x - 21.5) + ($y - 21.5) * ($y - 21.5))
      if ($d -lt $rr[$f]) {
        $t = 1.0 - $d / $rr[$f]
        $a = [int]($am[$f] * $t * $t + 6 * $t)
        if ($a -gt 0) { $b.SetPixel($f * 44 + $x, $y, [System.Drawing.Color]::FromArgb($a, 255, 214, 120)) }
      }
    } }
  }
  Save $b 'library_glow.png'
}

# ---- おすすめの平積み台 72x38（手書きポップ、平積みの本、表紙を見せた本）
if (Want 'pile') {
  $b = NewBmp 72 44
  # 台（ボルドーのクロス）
  Rect $b 3 22 66 9 $k; Rect $b 4 23 64 7 $wd0; Rect $b 4 23 64 1 $c1
  Rect $b 2 30 68 13 $k; Rect $b 3 31 66 11 $bx1; Rect $b 3 31 66 1 $c2
  for ($x = 9; $x -lt 68; $x += 7) { Rect $b $x 32 1 9 $bx2; Px $b ($x + 1) 33 $bx0; Px $b ($x + 1) 34 $bx0 }
  Rect $b 3 40 66 1 $gl1; Rect $b 3 41 66 1 $bx2
  for ($x = 3; $x -lt 69; $x += 3) { Px $b $x 42 $gl1 }
  # 手書きポップ（台のうしろに立てる）
  Rect $b 7 0 58 15 $k; Rect $b 8 1 56 13 $c0; Rect $b 8 1 56 1 $bx1; Rect $b 8 13 56 1 $c2
  Rect $b 10 3 1 1 $c0; Rect $b 61 3 1 1 $c0
  [void](TextPx $b 'おすすめ' 17 2 11 $g2 $true)
  # ハートと星のらくがき
  Px $b 10 7 $bx1; Px $b 12 7 $bx1; Rect $b 10 8 3 1 $bx1; Px $b 11 9 $bx1
  Px $b 60 6 $gl1; Rect $b 59 7 3 1 $gl1; Px $b 60 8 $gl1; Px $b 58 5 $gl0
  # 平積み（左）
  Flat $b 6 27 15 2; Flat $b 7 24 13 0; Flat $b 6 21 14 3; Rect $b 8 18 9 3 $k; Rect $b 9 19 7 1 $c0
  # 表紙を見せた本（中）
  Rect $b 26 15 11 15 $k; Rect $b 27 16 9 13 $g1; Frame $b 27 16 9 13 $gl0; Ellipse $b 31.5 21 2.6 2.6 $gl0; Rect $b 30 26 3 1 $gl1
  Rect $b 36 17 1 12 $g2
  Rect $b 38 17 11 13 $k; Rect $b 39 18 9 11 $bk[2][0]; Frame $b 39 18 9 11 $bk[2][1]; Rect $b 41 21 5 1 $c1; Rect $b 42 23 3 1 $c1; Px $b 43 25 $gl0
  # 平積み（右）
  Flat $b 53 27 14 4; Flat $b 54 24 12 5; Flat $b 53 21 13 7
  Rect $b 55 17 9 4 $k; Rect $b 56 18 7 2 $lf1; Px $b 57 16 $lf0; Px $b 60 15 $lf0; Px $b 62 17 $lf0
  Save $b 'library_pile.png'
}

# ---- ブックトラック 36x38（3段の台車）
if (Want 'truck') {
  $b = NewBmp 36 38
  $rng = New-Object System.Random 303
  Rect $b 3 4 2 31 $k; Rect $b 31 4 2 31 $k
  Rect $b 2 4 32 31 $wd4
  Rect $b 4 5 28 29 $inb
  foreach ($yy in @(4, 15, 26)) { Rect $b 2 ($yy + 8) 32 3 $k; Rect $b 3 ($yy + 9) 30 1 $bx1; Rect $b 3 ($yy + 10) 30 1 $bx2 }
  FillBooks $b 4 28 11 7 $rng
  FillBooks $b 4 28 22 8 $rng
  FillBooks $b 4 28 33 7 $rng
  Rect $b 2 33 32 3 $k; Rect $b 3 34 30 1 $bx1
  Rect $b 2 4 2 30 $bx2; Rect $b 2 4 1 30 $bx1; Rect $b 32 4 2 30 $bx2; Rect $b 33 4 1 30 $bx3
  # 取っ手
  Rect $b 0 2 6 2 $k; Rect $b 1 2 4 1 $gl0; Rect $b 0 2 2 6 $k; Rect $b 0 3 1 4 $gl1
  # 車輪
  foreach ($wx in @(5, 28)) { Ellipse $b ($wx + 1.5) 36 2.6 2.4 $k; Ellipse $b ($wx + 1.5) 36 1.2 1.1 $iron3 }
  Save $b 'library_truck.png'
}

# ---- 返却ボックス 28x28（投入口と「返却」の札）
if (Want 'return') {
  $b = NewBmp 28 28
  Rect $b 0 5 28 23 $k; Rect $b 1 6 26 21 $g1; Rect $b 1 6 1 21 $g0; Rect $b 26 6 1 21 $g2
  for ($x = 6; $x -lt 26; $x += 7) { Rect $b $x 18 1 8 $g2 }
  Rect $b 0 2 28 4 $k; Rect $b 1 3 26 2 $wd1; Rect $b 1 3 26 1 $wd0
  Rect $b 4 1 20 2 $k; Rect $b 5 2 18 1 $inb
  Rect $b 6 0 8 3 $k; Rect $b 7 1 6 2 $bx1; Rect $b 7 0 6 1 $c1
  Rect $b 2 8 24 14 $k; Rect $b 3 9 22 12 $c1; Rect $b 3 9 22 1 $c0; Frame $b 3 9 22 12 $gl1
  [void](TextPx $b '返却' 3 10 11 $bx2 $true)
  Rect $b 0 25 28 3 $wd3; Rect $b 1 25 26 1 $wd2
  Save $b 'library_return.png'
}

# ---- 本棚用のころがる脚立 18x46
if (Want 'ladder') {
  $b = NewBmp 18 46
  Rect $b 1 6 3 38 $wd2; Rect $b 1 6 1 38 $wd0; Rect $b 14 6 3 38 $wd2; Rect $b 14 6 1 38 $wd0
  Rect $b 3 0 12 1 $gl2
  for ($yy = 10; $yy -lt 42; $yy += 7) { Rect $b 3 $yy 12 2 $wd1; Rect $b 3 $yy 12 1 $wd0; Rect $b 3 ($yy + 2) 12 1 $wd3 }
  Rect $b 0 0 5 4 $k; Rect $b 1 1 3 2 $gl0
  Rect $b 13 0 5 4 $k; Rect $b 14 1 3 2 $gl0
  Rect $b 0 42 5 4 $k; Rect $b 1 43 3 2 $iron2; Rect $b 13 42 5 4 $k; Rect $b 14 43 3 2 $iron2
  Outline $b $k
  Save $b 'library_ladder.png'
}

# ---- 大きな観葉植物 22x38（モンステラ風）
if (Want 'plant') {
  $b = NewBmp 22 38
  Rect $b 5 28 12 10 $k; Rect $b 6 29 10 8 $c1; Rect $b 6 29 10 2 $c0; Rect $b 6 35 10 2 $c3; Rect $b 4 27 14 3 $k; Rect $b 5 28 12 1 $c0
  Rect $b 6 32 10 1 $bx1; Rect $b 6 33 10 1 $bx2
  Rect $b 10 17 2 11 $lf3
  foreach ($lv in @(@(5, 20, 5.5, 4, 0), @(16, 18, 5.5, 4, 1), @(11, 10, 6, 4.6, 0), @(4, 12, 4.5, 3.5, 1), @(17, 10, 4.5, 3.5, 0), @(10, 4, 4.5, 3.8, 1), @(11, 19, 4, 3, 0))) {
    Ellipse $b $lv[0] $lv[1] ($lv[2] + 0.8) ($lv[3] + 0.8) $k
    Ellipse $b $lv[0] $lv[1] $lv[2] $lv[3] $(if ($lv[4] -eq 0) { $lf1 } else { $lf2 })
    Ellipse $b ($lv[0] - 1) ($lv[1] - 1) ($lv[2] * 0.55) ($lv[3] * 0.5) $lf0
    Line $b ([int]$lv[0] - 2) ([int]$lv[1]) ([int]$lv[0] + 2) ([int]$lv[1]) $lf3
  }
  Save $b 'library_plant.png'
}

# ---- のぼり「本をよもう」 18x80
if (Want 'nobori') {
  $b = NewBmp 18 80
  Rect $b 1 0 2 80 $wd3; Rect $b 1 0 1 80 $wd1
  Rect $b 0 0 18 3 $k; Rect $b 1 0 16 2 $wd2; Rect $b 1 0 16 1 $wd1; Rect $b 16 0 2 4 $gl2; Px $b 17 0 $gl0
  # 旗（下はV字に切れ込み）
  Rect $b 3 3 14 72 $k
  Rect $b 4 4 12 70 $g1
  Rect $b 4 4 12 1 $g0; Rect $b 4 4 1 70 $g0; Rect $b 15 4 1 70 $g2
  Rect $b 5 5 10 1 $gl1; Rect $b 5 68 10 1 $gl1
  for ($y = 69; $y -le 74; $y++) { $d = $y - 68; Rect $b (10 - $d) $y (2 * $d) 1 $clear }
  $ys = 7
  foreach ($ch in @('本', 'を', 'よ', 'も', 'う')) { [void](TextPx $b $ch 4 $ys 11 $c0 $true); $ys += 12 }
  Save $b 'library_nobori.png'
}

# ---- まどの光の筋とほこり 72x66 x 6コマ（ほこりがきらきら舞う）
if (Want 'beam') {
  $fw = 72; $nf = 6
  $b = NewBmp ($fw * $nf) 66
  for ($f = 0; $f -lt $nf; $f++) {
    $ox = $f * $fw
    $pulse = 1.0 + 0.18 * [math]::Sin($f * 1.047)
    for ($y = 0; $y -lt 66; $y++) {
      $l = [int][math]::Round(4 + 30 * $y / 65.0)
      $a0 = [int]((62 - $y * 0.7) * $pulse)
      if ($a0 -lt 4) { $a0 = 4 }
      for ($i = 0; $i -lt 36; $i++) {
        $e = [math]::Min($i, 35 - $i); $a = [int]($a0 * [math]::Min(1.0, ($e + 1) / 6.0))
        $b.SetPixel($ox + $l + $i, $y, [System.Drawing.Color]::FromArgb($a, 255, 238, 160))
      }
    }
    for ($m = 0; $m -lt 8; $m++) {
      $yy = (66 - (($f * 5 + $m * 17) % 66)) % 66
      $l = [int][math]::Round(4 + 30 * $yy / 65.0)
      $xx = $l + 3 + (($m * 11) % 28) + [int][math]::Round(1.6 * [math]::Sin($f * 0.9 + $m))
      $tw = (($f + $m) % 3)
      $al = if ($tw -eq 0) { 235 } elseif ($tw -eq 1) { 170 } else { 110 }
      $b.SetPixel($ox + $xx, $yy, [System.Drawing.Color]::FromArgb($al, 255, 252, 225))
      if ($tw -eq 0 -and ($m % 2 -eq 0)) {
        $b.SetPixel($ox + $xx + 1, $yy, [System.Drawing.Color]::FromArgb(110, 255, 252, 225))
        $b.SetPixel($ox + $xx, $yy + 1, [System.Drawing.Color]::FromArgb(110, 255, 252, 225))
      }
    }
  }
  Save $b 'library_beam.png'
}
