# くろっふる屋台の専用ドット絵を作る（看板・のぼり・ワッフル焼き機アニメ・クロッフル・紙トレー・紙袋・生地を休ませるトレー・トッピング容器・カウンター・壁・日よけ・柱・黒板・敷物など）。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/croffle.ps1   （リポジトリのルートで）
#   一部だけ作り直す: $env:CROFFLE_ONLY='sign|iron'; powershell ...   （ファイル名の正規表現）
# 出力: client/public/brand/stall/croffle_*.png（原点は足元。配置は scripts/stalls/croffle.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル。文字は MS Gothic を1bitでドットにして貼る。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Want($n) { return ((-not $env:CROFFLE_ONLY) -or ($n -match $env:CROFFLE_ONLY)) }

# 色（ベージュ・茶色・クリーム色のカフェ調）
$cr0 = C '#fff9ea'; $cr = C '#f6ead0'; $cr2 = C '#e9d6ad'; $cr3 = C '#d4bb8a'
$bg0 = C '#3b2415'; $bg1 = C '#5a3820'; $bg2 = C '#7d5030'; $bg3 = C '#a87648'; $bg4 = C '#caa070'
$gd0 = C '#6e3f16'; $gd1 = C '#a6601f'; $gd2 = C '#e0a64a'; $gd3 = C '#f6d98c'
$pl0 = C '#d4b46a'; $pl1 = C '#f0dca0'
$cop = C '#b8733f'; $cop2 = C '#e0a066'
$ib0 = C '#2e2824'; $ib1 = C '#4a413a'; $ib2 = C '#6b6058'; $ib3 = C '#9a8e82'
$sug = C '#ffffff'; $sug2 = C '#e8e2d6'

function Blit($dst, $src, $x, $y) {
  for ($j = 0; $j -lt $src.Height; $j++) { for ($i = 0; $i -lt $src.Width; $i++) { $c = $src.GetPixel($i, $j); if ($c.A -ge 128) { Px $dst ($x + $i) ($y + $j) $c } } }
}
function Mix($c1, $c2, $t) {
  [System.Drawing.Color]::FromArgb(255,
    [int]($c1.R + ($c2.R - $c1.R) * $t), [int]($c1.G + ($c2.G - $c1.G) * $t), [int]($c1.B + ($c2.B - $c1.B) * $t))
}

# クロッフル（クロワッサン生地をワッフル型で焼いた、格子模様のまるいお菓子）。$bake 0=生地 .. 1=焼き上がり
function Croffle($b, $cx, $cy, $rx, $ry, $sp, $bake, $sugar) {
  $face = Mix $pl1 $gd2 $bake; $groove = Mix $pl0 $gd1 $bake; $hi = Mix $pl1 $gd3 $bake
  $edge = Mix $pl0 (C '#bf7a30') $bake; $out = Mix (C '#a88a50') $gd0 $bake
  Ellipse $b $cx $cy ($rx + 0.8) ($ry + 0.8) $out
  Ellipse $b $cx $cy $rx $ry $edge
  $x0 = [int][math]::Floor($cx - $rx); $y0 = [int][math]::Floor($cy - $ry)
  $x1 = [int][math]::Ceiling($cx + $rx); $y1 = [int][math]::Ceiling($cy + $ry)
  for ($y = $y0; $y -le $y1; $y++) {
    for ($x = $x0; $x -le $x1; $x++) {
      $dx = ($x + 0.5 - $cx) / ($rx - 1.1); $dy = ($y + 0.5 - $cy) / ($ry - 1.1)
      if ($dx * $dx + $dy * $dy -gt 1) { continue }
      $lx = ($x - $x0) % $sp; $ly = ($y - $y0) % $sp
      if ($lx -eq 0 -or $ly -eq 0) { $col = $groove }
      elseif ($lx -eq 1 -and $ly -eq 1) { $col = $hi }
      else { $col = $face }
      if ($col -eq $face -and ($dx + $dy) -gt 0.75) { $col = Mix $face $groove 0.4 }
      if ($sugar -and $col -ne $groove -and ((($x * 73) + ($y * 151)) % 13) -eq 0) { $col = $sug }
      Px $b $x $y $col
    }
  }
}
# 生クリームのかたまり（トッピングの一例）
function Dollop($b, $cx, $cy, $s) {
  Ellipse $b $cx $cy (2.6 * $s) (1.8 * $s) $sug2
  Ellipse $b $cx ($cy - 0.4 * $s) (2.2 * $s) (1.4 * $s) $sug
  Px $b ([int]$cx) ([int]($cy - 2 * $s)) $sug
}

# ---- 看板 120x32 を2コマ（電球とことばが交互にひかる）。足元が原点
if (Want 'sign') {
  $b = NewBmp 240 32
  for ($f = 0; $f -lt 2; $f++) {
    $ox = $f * 120
    Rect $b ($ox + 20) 0 3 5 $bg2; Rect $b ($ox + 97) 0 3 5 $bg2
    Rect $b $ox 4 120 28 $bg0
    Rect $b ($ox + 1) 5 118 26 $bg3
    Rect $b ($ox + 3) 7 114 22 $bg1
    Frame $b ($ox + 4) 8 112 20 $cr2
    foreach ($p in @(@(0, 4), @(119, 4), @(0, 31), @(119, 31))) { Clear $b ($ox + $p[0]) $p[1] }
    # 電球（上下のふち）
    for ($i = 0; $i -lt 18; $i++) {
      $on = (($i + $f) % 2 -eq 0)
      $bc = if ($on) { C '#fff3b8' } else { C '#8a6a3c' }
      Rect $b ($ox + 4 + $i * 6) 5 2 2 $bc
      Rect $b ($ox + 4 + $i * 6) 29 2 2 $bc
    }
    Croffle $b ($ox + 14) 18 5.5 5.2 3 1.0 $true
    Croffle $b ($ox + 105) 18 5.5 5.2 3 1.0 $true
    $tc = if ($f -eq 0) { C '#fff6dc' } else { C '#ffe3a0' }
    $tw = TextWidth 'くろっふる' 15
    [void](TextPx $b 'くろっふる' ($ox + [math]::Floor((120 - $tw - 1) / 2)) 10 15 $bg0 $true)
    [void](TextPx $b 'くろっふる' ($ox + [math]::Floor((120 - $tw - 1) / 2) - 1) 9 15 $tc $true)
  }
  Save $b 'croffle_sign.png'
}

# ---- のぼり旗 16x78（左の棒の足元が原点）。クリーム色の布に茶色の縦書き
if (Want 'nobori') {
  $b = NewBmp 16 78
  Rect $b 0 2 16 2 $bg3; Rect $b 0 2 2 76 $bg2; Rect $b 0 2 1 76 $bg3
  Rect $b 2 4 13 68 $cr; Rect $b 2 4 1 68 $cr3; Rect $b 14 4 1 68 $cr3
  Rect $b 2 4 13 1 $bg2; Rect $b 2 70 13 1 $bg2
  for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 71 $cr; Px $b (2 + $i) 72 $cr3 } }
  $chars = 'く', 'ろ', 'っ', 'ふ', 'る'
  for ($i = 0; $i -lt 5; $i++) { [void](TextPx $b $chars[$i] 4 (6 + 11 * $i) 11 $bg1 $true) }
  Croffle $b 8.5 64.5 4.2 4.0 3 1.0 $false
  Save $b 'croffle_nobori.png'
}

# ---- ワッフル焼き機のアニメ 6コマ（1コマ 40x40）。上下に開く・焼き色がつく・ランプがつく。足元が原点
if (Want 'iron') {
  $fw = 44; $fh = 40; $nf = 6
  $b = NewBmp ($fw * $nf) $fh
  $angles = @(44.0, 34.0, 14.0, 0.0, 0.0, 22.0)
  $bakes  = @(0.0, 0.0, 0.0, 0.55, 0.85, 1.0)
  for ($f = 0; $f -lt $nf; $f++) {
    $fx = $f * $fw; $ox = $fx + 3; $a = $angles[$f] * [math]::PI / 180.0
    # 本体（くろがね色の箱に銅の帯）
    Rect $b ($ox + 3) 31 34 9 $ib0
    Rect $b ($ox + 4) 32 32 7 $ib1; Rect $b ($ox + 4) 32 32 1 $ib2
    Rect $b ($ox + 4) 36 32 2 $cop; Rect $b ($ox + 4) 36 32 1 $cop2
    foreach ($p in @(@(3, 31), @(36, 31), @(3, 39), @(36, 39))) { Clear $b ($ox + $p[0]) $p[1] }
    $lamp = if ($angles[$f] -lt 1) { C '#ff5a3c' } else { C '#7a3a2a' }
    Rect $b ($ox + 7) 33 2 2 $lamp
    Rect $b ($ox + 29) 33 4 2 $ib3
    # 下の型板と、のっている生地（開いているとき見える）
    Rect $b ($ox + 4) 26 32 5 $ib0; Rect $b ($ox + 5) 26 30 2 $ib2
    if ($angles[$f] -ge 1) { Croffle $b ($ox + 20) 28.2 13.4 3.8 3 $bakes[$f] $false }
    # ふた（蝶番は右奥。角度に合わせて回して描く）
    $hx = $ox + 36.0; $hy = 29.5
    $dxv = -[math]::Cos($a); $dyv = -[math]::Sin($a); $nx = [math]::Sin($a); $ny = -[math]::Cos($a)
    for ($y = 0; $y -lt $fh; $y++) {
      for ($x = $fx; $x -lt $fx + $fw; $x++) {
        $wx = $x + 0.5 - $hx; $wy = $y + 0.5 - $hy
        $u = $wx * $dxv + $wy * $dyv; $v = $wx * $nx + $wy * $ny
        $col = $null
        if ($u -ge 0 -and $u -le 30 -and $v -ge 0 -and $v -lt 5.6) {
          if ($v -ge 4.6) { $col = $ib2 } elseif ($v -lt 1.0) { $col = $ib0 } elseif ($v -ge 2.2 -and $v -lt 3.2) { $col = $cop } else { $col = $ib1 }
          if ($u -lt 1.0 -or $u -gt 29.0) { $col = $ib0 }
        } elseif ($u -gt 30 -and $u -le 36 -and $v -ge 1.4 -and $v -lt 3.8) {
          $col = if ($v -lt 2.4) { $bg3 } else { $bg2 }
        }
        if ($col) { Px $b $x $y $col }
      }
    }
    # 蝶番
    Rect $b ($ox + 35) 28 2 3 $ib3
  }
  Save $b 'croffle_iron.png'
}

# ---- 湯気（アニメ）6コマ。1コマ 12x20 を横に並べる
if (Want 'steam') {
  $fr = 6; $fw = 12; $fh = 20
  $b = NewBmp ($fw * $fr) $fh
  for ($f = 0; $f -lt $fr; $f++) {
    for ($y = 0; $y -lt $fh; $y++) {
      $ph = ($y + $f * 3.3) / 2.8
      $x = 5 + [math]::Round(2.2 * [math]::Sin($ph))
      $a = [int](235 * [math]::Sin([math]::PI * ($fh - $y) / $fh) * [math]::Min(1.0, ($fh - $y) / 6.0))
      if ($y -ge $fh - 2) { $a = 0 }
      if ($a -gt 20) {
        Px $b ($f * $fw + $x) $y ([System.Drawing.Color]::FromArgb([math]::Min(230, $a), 255, 255, 255))
        Px $b ($f * $fw + $x + 1) $y ([System.Drawing.Color]::FromArgb([math]::Min(200, [int]($a * 0.8)), 255, 255, 255))
        if ($y % 3 -ne 0) { Px $b ($f * $fw + $x - 1) $y ([System.Drawing.Color]::FromArgb([math]::Min(150, [int]($a * 0.5)), 255, 255, 255)) }
      }
    }
  }
  Save $b 'croffle_steam.png'
}

# ---- 粉砂糖のきらきら（アニメ）4コマ。1コマ 9x9
if (Want 'sparkle') {
  $b = NewBmp 36 9
  $gl = C '#fff3b8'
  $sz = @(0, 1, 2, 1)
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * 9 + 4; $s = $sz[$f]
    Px $b $ox 4 $sug
    for ($i = 1; $i -le $s * 2; $i++) {
      $cc = if ($i -le $s) { $sug } else { $gl }
      Px $b ($ox + $i) 4 $cc; Px $b ($ox - $i) 4 $cc; Px $b $ox (4 + $i) $cc; Px $b $ox (4 - $i) $cc
    }
    if ($s -eq 2) { Px $b ($ox + 1) 3 $gl; Px $b ($ox - 1) 5 $gl }
  }
  Save $b 'croffle_sparkle.png'
}

# ---- 紙のトレー（クロッフルをのせて）26x17。足元が原点
if (Want 'tray') {
  $b = NewBmp 26 17
  Croffle $b 13 6.5 10.4 5.6 3 1.0 $true
  Dollop $b 15 4 1.0
  Rect $b 1 8 24 8 $bg0; Rect $b 2 9 22 6 $cr; Rect $b 2 9 22 1 $cr0
  for ($x = 2; $x -lt 24; $x += 4) { Rect $b $x 10 2 5 $bg3 }
  Rect $b 2 14 22 1 $cr3
  foreach ($p in @(@(1, 8), @(24, 8), @(1, 15), @(24, 15))) { Clear $b $p[0] $p[1] }
  Save $b 'croffle_tray.png'
}

# ---- 紙袋（クロッフルが顔を出す）14x19。足元が原点
if (Want 'bag') {
  $b = NewBmp 14 19
  Croffle $b 7 5 5.6 5.0 3 1.0 $true
  Rect $b 0 7 14 12 $bg0; Rect $b 1 8 12 10 $bg4; Rect $b 1 8 12 1 $cr2
  Rect $b 1 8 1 10 $cr2; Rect $b 12 8 1 10 $bg3; Rect $b 1 17 12 1 $bg3
  Rect $b 3 11 8 5 $cr; Frame $b 3 11 8 5 $bg2
  Rect $b 5 11 1 5 $bg2; Rect $b 8 11 1 5 $bg2; Rect $b 3 13 8 1 $bg2
  foreach ($p in @(@(0, 7), @(13, 7), @(0, 18), @(13, 18))) { Clear $b $p[0] $p[1] }
  Save $b 'croffle_bag.png'
}

# ---- 生地を休ませるトレー（クロワッサン生地のロール）34x15。足元が原点
if (Want 'rest') {
  $b = NewBmp 34 15
  foreach ($rx in @(3, 11, 19, 27)) {
    Ellipse $b ($rx + 3) 6 3.6 3.2 $pl0
    Ellipse $b ($rx + 3) 5.5 3.2 2.8 $pl1
    Line $b ($rx + 1) 4 ($rx + 1) 7 $pl0
    Line $b ($rx + 3) 3 ($rx + 3) 8 $pl0
    Line $b ($rx + 5) 4 ($rx + 5) 7 $pl0
  }
  Rect $b 0 8 34 7 $ib0
  Rect $b 1 8 32 1 $ib3; Rect $b 1 9 32 1 $ib2
  Rect $b 1 10 32 4 $ib1
  Rect $b 1 12 32 1 $cop
  foreach ($p in @(@(0, 8), @(33, 8), @(0, 14), @(33, 14))) { Clear $b $p[0] $p[1] }
  Save $b 'croffle_rest.png'
}

# ---- トッピングの容器 3つと粉砂糖のふりかけ 34x15。足元が原点
if (Want 'jars') {
  $b = NewBmp 34 15
  $fills = @(@((C '#f4ebd6'), (C '#ffffff')), @((C '#6a3b22'), (C '#8d5634')), @((C '#e9a9a2'), (C '#f6cbc4')))
  for ($i = 0; $i -lt 3; $i++) {
    $x = 1 + $i * 9
    Rect $b $x 5 8 10 $bg0
    Rect $b ($x + 1) 6 6 8 (C '#dfeeee'); Rect $b ($x + 1) 6 1 8 (C '#f2fafa')
    Rect $b ($x + 1) 8 6 6 $fills[$i][0]; Rect $b ($x + 1) 8 6 1 $fills[$i][1]
    Rect $b ($x - 1) 3 10 3 $bg0; Rect $b $x 3 8 2 $bg3; Rect $b $x 3 8 1 $bg4
    foreach ($p in @(@(0, 5), @(7, 5), @(0, 14), @(7, 14))) { Clear $b ($x + $p[0]) $p[1] }
  }
  # 粉砂糖のふりかけ
  Rect $b 28 4 5 11 $bg0; Rect $b 29 5 3 9 $sug; Rect $b 29 5 1 9 $sug2
  Rect $b 27 2 7 3 $ib1; Rect $b 28 2 5 1 $ib3; Px $b 29 3 $ib0; Px $b 31 3 $ib0
  Rect $b 29 8 3 1 $bg2
  Save $b 'croffle_jars.png'
}

# ---- カウンター 116x24。上の面(明るい木)と、前の面はワッフルの格子もよう
if (Want 'counter') {
  $b = NewBmp 116 24
  Rect $b 0 0 116 24 $bg0
  Rect $b 1 1 114 8 $bg4; Rect $b 1 1 114 1 $cr; Rect $b 1 8 114 1 $bg3
  Rect $b 1 9 114 14 $cr
  Rect $b 3 11 110 10 $cr2
  for ($x = 3; $x -lt 113; $x += 5) { Rect $b $x 11 1 10 $cr3 }
  for ($y = 11; $y -lt 21; $y += 5) { Rect $b 3 $y 110 1 $cr3 }
  Rect $b 3 11 110 1 $bg3; Rect $b 3 20 110 1 $bg3
  Frame $b 2 10 112 12 $bg2
  Rect $b 0 23 116 1 $bg0
  foreach ($p in @(@(0, 0), @(115, 0))) { Clear $b $p[0] $p[1] }
  Save $b 'croffle_counter.png'
}

# ---- 日よけ（クリームと茶色のしま）124x24。手前のへりはまるいふち
if (Want 'awning') {
  $b = NewBmp 124 24
  for ($y = 0; $y -lt 10; $y++) {
    $inset = [int](9 - $y)
    for ($x = $inset; $x -lt 124 - $inset; $x++) { $st = [math]::Floor($x / 8) % 2; Px $b $x $y $(if ($st -eq 0) { $bg2 } else { $cr }) }
  }
  for ($x = 0; $x -lt 124; $x++) { Px $b $x 9 $bg1 }
  for ($y = 10; $y -lt 22; $y++) {
    for ($x = 0; $x -lt 124; $x++) {
      $st = [math]::Floor($x / 8) % 2
      $col = if ($st -eq 0) { $bg2 } else { $cr }
      $mid = ($x % 8) - 3.5
      if ($y -ge 17) { $dy = $y - 17; $lim = [math]::Sqrt([math]::Max(0.0, 16.5 - $mid * $mid)); if ($dy -gt $lim) { continue } }
      Px $b $x $y $col
    }
  }
  for ($x = 0; $x -lt 124; $x++) { if ((([math]::Floor($x / 8)) % 2) -eq 0) { Px $b $x 10 $bg3 } else { Px $b $x 10 $cr0 } }
  Rect $b 0 10 1 8 $bg1; Rect $b 123 10 1 8 $bg1
  Save $b 'croffle_awning.png'
}

# ---- 奥の壁 108x40（クリーム色の壁と木の腰板、棚、額）。足元が原点
if (Want 'wall') {
  $b = NewBmp 108 40
  Rect $b 0 0 108 40 $bg1
  Rect $b 1 1 106 38 $cr
  for ($x = 6; $x -lt 106; $x += 8) { Rect $b $x 1 1 26 $cr2 }
  Rect $b 1 28 106 11 $bg3
  for ($x = 1; $x -lt 107; $x += 9) { Rect $b $x 29 1 10 $bg2 }
  Rect $b 1 27 106 2 $bg1; Rect $b 1 27 106 1 $bg4
  # 棚と飾り
  Rect $b 8 17 34 2 $bg2; Rect $b 8 19 34 1 $bg1
  Rect $b 11 10 5 7 $cr3; Rect $b 11 9 5 1 $bg2
  Rect $b 20 12 4 5 (C '#b05a4a'); Rect $b 20 11 4 1 $bg2
  Rect $b 28 8 6 9 $cr2; Frame $b 28 8 6 9 $bg3; Ellipse $b 31 11 1.5 1.8 (C '#7aa05a')
  Rect $b 36 13 4 4 $cop
  # 額（ワッフルの絵）
  Rect $b 72 6 24 18 $bg0; Rect $b 73 7 22 16 $bg3; Rect $b 75 9 18 12 $cr
  Croffle $b 84 15 6 5 3 1.0 $true
  Save $b 'croffle_wall.png'
}

# ---- 床のタイル 124x26（ベージュとクリームの市松）。足元が原点
if (Want 'floor') {
  $b = NewBmp 124 26
  for ($y = 0; $y -lt 26; $y++) { for ($x = 0; $x -lt 124; $x++) {
    $t = ([math]::Floor($x / 6) + [math]::Floor($y / 6)) % 2
    Px $b $x $y $(if ($t -eq 0) { $cr } else { $cr2 })
  } }
  Rect $b 0 25 124 1 $cr3
  Save $b 'croffle_floor.png'
}

# ---- 柱 6x48（足元が原点）
if (Want 'post') {
  $b = NewBmp 6 48
  Rect $b 0 0 6 48 $bg0; Rect $b 1 0 4 47 $bg2; Rect $b 1 0 1 47 $bg3; Rect $b 4 0 1 47 $bg1
  Save $b 'croffle_post.png'
}

# ---- 黒板のメニュー 52x46（中身は絵だけ。足元が原点）
if (Want 'menu') {
  $b = NewBmp 52 46
  Rect $b 0 0 52 42 $bg0; Rect $b 1 1 50 40 $bg3; Rect $b 3 3 46 36 (C '#33241b')
  Rect $b 8 42 3 4 $bg1; Rect $b 41 42 3 4 $bg1
  $w = TextWidth 'メニュー' 11
  [void](TextPx $b 'メニュー' ([math]::Floor((52 - $w) / 2)) 4 11 (C '#ffeeb8') $true)
  Croffle $b 26 28 12.5 9.5 4 1.0 $true
  Dollop $b 30 22 1.4
  Save $b 'croffle_menu.png'
}

# ---- 敷物（クリームに茶のふち、格子）56x26
if (Want 'rug') {
  $b = NewBmp 56 26
  Rect $b 0 0 56 26 $bg1; Rect $b 1 1 54 24 $cr; Frame $b 3 3 50 20 $bg3
  for ($x = 5; $x -lt 51; $x += 5) { Rect $b $x 4 1 18 $cr2 }
  for ($y = 6; $y -lt 22; $y += 5) { Rect $b 4 $y 48 1 $cr2 }
  foreach ($p in @(@(0, 0), @(55, 0), @(0, 25), @(55, 25))) { Clear $b $p[0] $p[1] }
  Save $b 'croffle_rug.png'
}
