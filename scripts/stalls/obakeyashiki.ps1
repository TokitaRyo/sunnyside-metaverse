# おばけやしき（お化け屋敷）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/obakeyashiki.ps1
# 出力: client/public/brand/stall/obakeyashiki_*.png （配置は scripts/stalls/obakeyashiki.mjs）
# 配色は暗い紫・青・黒に、鬼火の青緑・提灯のオレンジ・血のあかを差す。アニメは「フレームを横一列に並べたPNG」。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function Sheet($name, $sw, $sh, $n, $draw) {
  $bm = NewBmp ($sw * $n) $sh
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $sw) $f }
  Save $bm $name
}
# 太い線（幅 $t px）
function Thick($b, $x0, $y0, $x1, $y1, $t, $col) {
  $o = [int][math]::Floor($t / 2)
  for ($i = 0; $i -lt $t; $i++) { Line $b ($x0 + $i - $o) $y0 ($x1 + $i - $o) $y1 $col }
}
# 絵の外側のふちどり（透明なマスで、となりに不透明な絵があるところを色でぬる）。1コマ分(ox..ox+sw, 0..sh)
function Outline($b, $ox, $sw, $sh, $col) {
  $list = New-Object System.Collections.ArrayList
  for ($y = 0; $y -lt $sh; $y++) {
    for ($x = 0; $x -lt $sw; $x++) {
      if ($b.GetPixel($ox + $x, $y).A -eq 0) {
        $adj = $false
        foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
          $nx = $x + $d[0]; $ny = $y + $d[1]
          if ($nx -ge 0 -and $nx -lt $sw -and $ny -ge 0 -and $ny -lt $sh) { if ($b.GetPixel($ox + $nx, $ny).A -gt 200) { $adj = $true } }
        }
        if ($adj) { [void]$list.Add(@($x, $y)) }
      }
    }
  }
  foreach ($p in $list) { Px $b ($ox + $p[0]) $p[1] $col }
}
# クモの巣（角 (cx,cy) から sx,sy 方向へ半径 R）
function Web($b, $cx, $cy, $sx, $sy, $rad, $col) {
  $sx = [int]$sx; $sy = [int]$sy
  $angs = @(0, 22, 45, 68, 90)
  foreach ($a in $angs) {
    $ar = $a * [math]::PI / 180
    Line $b $cx $cy ([int][math]::Round($cx + $sx * $rad * [math]::Cos($ar))) ([int][math]::Round($cy + $sy * $rad * [math]::Sin($ar))) $col
  }
  foreach ($rr in @(($rad * 0.35), ($rad * 0.65), $rad)) {
    for ($i = 0; $i -lt 4; $i++) {
      $a0 = $angs[$i] * [math]::PI / 180; $a1 = $angs[$i + 1] * [math]::PI / 180
      $k = 0.9
      Line $b ([int][math]::Round($cx + $sx * $rr * [math]::Cos($a0))) ([int][math]::Round($cy + $sy * $rr * [math]::Sin($a0))) ([int][math]::Round($cx + $sx * $rr * $k * [math]::Cos(($a0 + $a1) / 2))) ([int][math]::Round($cy + $sy * $rr * $k * [math]::Sin(($a0 + $a1) / 2))) $col
      Line $b ([int][math]::Round($cx + $sx * $rr * $k * [math]::Cos(($a0 + $a1) / 2))) ([int][math]::Round($cy + $sy * $rr * $k * [math]::Sin(($a0 + $a1) / 2))) ([int][math]::Round($cx + $sx * $rr * [math]::Cos($a1))) ([int][math]::Round($cy + $sy * $rr * [math]::Sin($a1))) $col
    }
  }
}

# ---- パレット
$k0 = C '#07040e'; $k1 = C '#150e2b'; $k2 = C '#241a45'; $k3 = C '#34285e'; $k4 = C '#4b3b80'; $k5 = C '#6a58a8'; $k6 = C '#8a7be0'
$wd0 = C '#1a1220'; $wd1 = C '#2a1c34'; $wd2 = C '#3b2a48'; $wd3 = C '#54406a'
$bone = C '#f4f2ff'; $bone2 = C '#cfd0ee'; $bone3 = C '#a8a9d6'
$onb0 = C '#12807c'; $onb1 = C '#3dffd8'; $onb2 = C '#9afff0'; $onb3 = C '#e8fffd'
$or0 = C '#7a2e12'; $or1 = C '#c8581a'; $or2 = C '#ff9a2e'; $or3 = C '#ffcf5a'; $or4 = C '#fff2a0'
$bl0 = C '#5a0c18'; $bl1 = C '#8a1220'; $bl2 = C '#c8202e'
$st0 = C '#1e1a30'; $st1 = C '#3c3c58'; $st2 = C '#5a5a7a'; $st3 = C '#7a7a9a'; $st4 = C '#a8a8c8'
$gold2 = C '#e8b23a'; $gold3 = C '#a8741c'
$moss = C '#3f7a4a'

# ---- 床の暗い覆い（草地ぜんたい 192x128、半透明。ふちほど濃い）。sort:floor で敷く
Sheet 'obakeyashiki_overlay.png' 192 128 1 {
  param($b, $ox, $f)
  $rng = New-Object System.Random 11
  $base = C '#0e0726'
  for ($y = 0; $y -lt 128; $y++) {
    for ($x = 0; $x -lt 192; $x++) {
      $dx = ($x - 96) / 96.0; $dy = ($y - 74) / 74.0
      $d = [math]::Sqrt($dx * $dx + $dy * $dy * 0.6)
      $a = [int](138 + 58 * [math]::Min(1.0, $d * 0.9))
      Px $b $x $y ([System.Drawing.Color]::FromArgb($a, $base.R, $base.G, $base.B))
    }
  }
  for ($i = 0; $i -lt 70; $i++) {
    $x = $rng.Next(2, 190); $y = $rng.Next(2, 126)
    Px $b $x $y (CA '#150a30' 210); Px $b ($x + 1) ($y - 1) (CA '#150a30' 210); Px $b ($x - 1) ($y - 1) (CA '#150a30' 210)
  }
  for ($i = 0; $i -lt 40; $i++) {
    $x = $rng.Next(2, 190); $y = $rng.Next(2, 126)
    Px $b $x $y (CA '#6a58c8' 90)
  }
}

# ---- 参道（うす暗い石だたみ）40x58。草地のまん中から手前へ
Sheet 'obakeyashiki_path.png' 40 58 1 {
  param($b, $ox, $f)
  $rng = New-Object System.Random 5
  for ($y = 0; $y -lt 58; $y++) {
    $hw = 11 + $y * 0.2 + $rng.Next(0, 2)
    for ($x = 0; $x -lt 40; $x++) {
      if ([math]::Abs($x + 0.5 - 20) -le $hw) {
        $row = [int][math]::Floor($y / 7); $off = ($row % 2) * 5
        $cx = ($x + $off) % 10; $cy = $y % 7
        if ($cx -eq 0 -or $cy -eq 0) { Px $b $x $y (C '#0e0b20') }
        elseif ($cy -eq 1) { Px $b $x $y (C '#383258') }
        elseif ($cy -eq 6) { Px $b $x $y (C '#1c1836') }
        else { Px $b $x $y (C '#2a2548') }
      }
    }
  }
  for ($i = 0; $i -lt 20; $i++) { $x = $rng.Next(6, 34); $y = $rng.Next(2, 56); if ($b.GetPixel($x, $y).A -gt 0) { Px $b $x $y (C '#1c1838') } }
  foreach ($p in @(@(12, 20), @(26, 40), @(18, 49))) { Rect $b $p[0] $p[1] 3 2 $moss; Px $b ($p[0] + 1) ($p[1] - 1) $moss }
  # 落ちている骨
  Rect $b 24 24 5 1 $bone2; Px $b 23 23 $bone2; Px $b 23 25 $bone2; Px $b 29 23 $bone2; Px $b 29 25 $bone2
}

# ---- やしき本体 136x74（屋根・板壁・窓の枠・暗幕の入口・クモの巣）
Sheet 'obakeyashiki_house.png' 136 74 1 {
  param($b, $ox, $f)
  $rng = New-Object System.Random 21
  $r0 = C '#0b0716'; $r1 = C '#1b1236'; $r2 = C '#2b1f55'; $r3 = C '#3f3079'; $r4 = C '#5a49a0'
  # 煙突（ななめにかたむく）
  for ($y = 0; $y -lt 12; $y++) {
    $sx = if ($y -lt 5) { 1 } else { 0 }
    Rect $b (98 + $sx) $y 10 1 (C '#4a2a38')
    if ($y % 3 -eq 2) { Rect $b (98 + $sx) $y 10 1 (C '#2a1626') }
    if (($y % 3) -eq 0) { Px $b (101 + $sx) $y (C '#6a3a4a'); Px $b (105 + $sx) $y (C '#6a3a4a') }
  }
  Rect $b 97 0 12 2 $r1; Rect $b 97 0 12 1 $r3
  # 屋根（台形）
  for ($y = 6; $y -lt 27; $y++) {
    $t = ($y - 6) / 20.0
    $lx = [int][math]::Round(24 - 21 * $t); $rx = [int][math]::Round(112 + 21 * $t)
    for ($x = $lx; $x -le $rx; $x++) {
      $row = $y - 6
      $col = $r2
      if ($row % 4 -eq 3) { $col = $r1 }
      elseif ((($x + ([int][math]::Floor($row / 4) % 2) * 3) % 6) -eq 0) { $col = $r1 }
      elseif ($row % 4 -eq 0) { $col = $r3 }
      Px $b $x $y $col
    }
    Px $b $lx $y $r4; Px $b $rx $y $r1
  }
  Rect $b 24 6 89 1 $r4
  # 欠けた瓦と穴
  Rect $b 58 11 7 5 $r0; Rect $b 59 10 4 1 $r0; Rect $b 84 17 6 4 $r0; Rect $b 36 19 4 3 $r0
  Px $b 61 12 (C '#ffe94a'); Px $b 62 12 (C '#ffe94a')
  # 軒（ひさし）と影
  Rect $b 1 26 134 2 $r0; Rect $b 1 26 134 1 $r4
  for ($x = 3; $x -lt 134; $x += 6) { Rect $b $x 28 3 1 $r0 }
  # 板壁
  for ($y = 28; $y -lt 74; $y++) {
    for ($x = 3; $x -lt 133; $x++) {
      $c = $wd1
      if ($x % 6 -eq 0) { $c = $wd0 } elseif ($x % 6 -eq 1) { $c = $wd2 }
      Px $b $x $y $c
    }
  }
  for ($i = 0; $i -lt 60; $i++) { $x = $rng.Next(4, 132); $y = $rng.Next(30, 66); Px $b $x $y $wd0 }
  for ($i = 0; $i -lt 30; $i++) { $x = $rng.Next(4, 132); $y = $rng.Next(30, 66); Px $b $x $y $wd3 }
  for ($y = 28; $y -lt 33; $y++) { Rect $b 3 $y 130 1 (Mix $wd1 $r0 (0.8 - ($y - 28) * 0.15)) }
  # ひび割れ
  Line $b 30 40 34 46 $wd0; Line $b 34 46 33 52 $wd0; Line $b 100 36 104 43 $wd0; Line $b 104 43 102 50 $wd0
  # 基礎の石
  Rect $b 3 68 130 6 (C '#2a2548')
  for ($x = 3; $x -lt 133; $x += 9) { Rect $b $x 68 1 6 (C '#0e0b20') }
  Rect $b 3 68 130 1 (C '#4e4876')
  Rect $b 3 73 130 1 (C '#14102a')
  # 壁のはし（柱）
  Rect $b 0 27 3 47 $wd0; Rect $b 133 27 3 47 $wd0; Rect $b 1 27 1 47 $wd3
  # 窓（左右）。ガラスの中はあとで光るシートをのせる
  foreach ($wx in 5, 117) {
    Rect $b $wx 32 14 22 $wd3; Rect $b ($wx + 1) 33 12 20 $wd0
    Rect $b ($wx + 2) 34 10 16 (C '#03020a')
    Rect $b ($wx - 1) 52 16 3 $wd2; Rect $b ($wx - 1) 54 16 1 $wd0
  }
  # こわれた雨戸
  Rect $b 1 33 4 17 $wd2; Rect $b 1 33 1 17 $wd3; Rect $b 4 33 1 17 $wd0
  Clear $b 1 49; Clear $b 2 49; Clear $b 1 48; Clear $b 4 33; Clear $b 3 33
  Line $b 1 36 4 39 $wd0; Line $b 1 42 4 45 $wd0
  Rect $b 131 40 4 14 $wd2; Rect $b 131 40 1 14 $wd3; Rect $b 134 40 1 14 $wd0
  Clear $b 134 40; Clear $b 133 40; Clear $b 131 53; Line $b 131 44 134 47 $wd0
  # 入口（アーチの枠と暗幕）
  Rect $b 45 49 46 23 $wd3
  Rect $b 46 50 44 22 $wd0
  Rect $b 45 49 46 2 $wd2; Rect $b 45 49 46 1 $wd3
  Rect $b 49 53 38 17 $k0
  for ($x = 49; $x -lt 87; $x++) {
    $m = ($x - 49) % 6
    for ($y = 58; $y -lt 70; $y++) {
      if ($m -eq 0 -or $m -eq 1) { Px $b $x $y $k1 }
      elseif ($m -eq 2) { Px $b $x $y $k2 }
    }
  }
  Rect $b 67 56 3 14 (C '#000000')
  Rect $b 66 56 1 14 $k1; Rect $b 70 56 1 14 $k1
  # スリットからのぞく目
  Rect $b 66 61 2 2 (C '#ffe94a'); Rect $b 69 61 2 2 (C '#ffe94a'); Px $b 67 62 $k0; Px $b 69 62 $k0
  # 飾り幕（上の波）
  Rect $b 49 53 38 3 (C '#6a1a4a')
  for ($x = 49; $x -lt 87; $x++) { $d = if ((($x - 49) % 6) -lt 3) { 3 } else { 2 }; Rect $b $x 56 1 $d (C '#6a1a4a'); Px $b $x (56 + $d) $gold3 }
  for ($x = 52; $x -lt 87; $x += 6) { Px $b $x 54 $gold2 }
  # 階段
  Rect $b 44 70 48 2 (C '#4e4876'); Rect $b 44 72 48 2 (C '#2a2548')
  Rect $b 42 72 52 2 (C '#3b3560'); Rect $b 42 73 52 1 (C '#14102a')
  # 血の手形
  foreach ($hp in @(@(34, 58), @(103, 56))) {
    $hx = $hp[0]; $hy = $hp[1]
    Rect $b $hx ($hy + 2) 4 4 $bl1; Px $b $hx $hy $bl1; Px $b ($hx + 1) ($hy - 1) $bl1; Px $b ($hx + 2) ($hy - 1) $bl1; Px $b ($hx + 3) $hy $bl1; Px $b ($hx + 1) ($hy + 1) $bl1; Px $b ($hx + 2) ($hy + 1) $bl1
    Px $b ($hx + 1) ($hy + 6) $bl1; Px $b ($hx + 2) ($hy + 7) $bl0
    Px $b ($hx + 1) ($hy + 3) $bl2
  }
  # クモの巣
  $web = CA '#cfd0ee' 190
  Web $b 3 28 1 1 11 $web
  Web $b 132 28 -1 1 11 $web
  Web $b 46 51 1 1 6 $web
  Web $b 90 51 -1 1 6 $web
  # 角を透明に
  foreach ($p in @(@(0, 73), @(135, 73))) { Clear $b $p[0] $p[1] }
}

# ---- 窓の中の光（10x16。まどあかりがゆらぎ、おばけのかげがよぎる）4コマ
Sheet 'obakeyashiki_win.png' 10 16 4 {
  param($b, $ox, $f)
  $cols = @('#2f7a6a', '#7affc8', '#1f4a4a', '#b6ffe8')
  $g = C $cols[$f]
  Rect $b $ox 0 10 16 $g
  Rect $b ($ox + 1) 1 8 4 (Mix $g (C '#ffffff') 0.18)
  Rect $b ($ox + 4) 0 2 16 (C '#0b0716'); Rect $b $ox 6 10 2 (C '#0b0716')
  if ($f -eq 1 -or $f -eq 2) {
    $gx = if ($f -eq 1) { 1 } else { 5 }
    Ellipse $b ($ox + $gx + 2) 11 2.6 2.4 (C '#06100f')
    Rect $b ($ox + $gx) 11 5 3 (C '#06100f')
    Px $b ($ox + $gx + 1) 10 $g; Px $b ($ox + $gx + 3) 10 $g
  }
  Line $b ($ox + 2) 13 ($ox + 3) 9 (C '#0b0716')
}

# ---- 看板「おばけやしき」100x46（血のしたたる文字・ゆれる鎖・のぞくおばけ）4コマ
$signTxt = 'おばけやしき'
$signTw = TextWidth $signTxt 13
Sheet 'obakeyashiki_sign.png' 100 46 4 {
  param($b, $ox, $f)
  # 鎖
  foreach ($cx in 14, 85) {
    for ($y = 0; $y -lt 14; $y++) { Px $b ($ox + $cx) $y $(if ($y % 3 -eq 2) { $k3 } else { C '#9494b0' }); Px $b ($ox + $cx + 1) $y $(if ($y % 3 -eq 2) { $k1 } else { C '#4b4b60' }) }
  }
  # 板
  Rect $b $ox 12 100 29 $k0
  Rect $b ($ox + 1) 13 98 27 $wd1
  Frame $b ($ox + 1) 13 98 27 $k5
  Frame $b ($ox + 2) 14 96 25 $k2
  for ($x = 4; $x -lt 96; $x += 7) { Px $b ($ox + $x) 15 $wd3; Px $b ($ox + $x + 3) 37 $wd0 }
  foreach ($p in @(@(4, 16), @(95, 16), @(4, 36), @(95, 36))) { Px $b ($ox + $p[0]) $p[1] (C '#9494b0') }
  # 割れた角
  Clear $b ($ox + 99) 12; Clear $b $ox 12; Clear $b $ox 40; Clear $b ($ox + 99) 40; Clear $b ($ox + 98) 12
  # 文字
  $tx = [int][math]::Floor((100 - $signTw) / 2) - 1
  [void](TextPx $b $signTxt ($ox + $tx) 18 13 $k0 $true)
  [void](TextPx $b $signTxt ($ox + $tx - 1) 17 13 $k2 $true)
  [void](TextPx $b $signTxt ($ox + $tx) 17 13 $bone $true)
  # 血のしたたり（コマごとに長くなる。さいごに雫が落ちる）
  $drips = @(@(11, 5), @(37, 3), @(63, 6), @(76, 2), @(90, 4))
  $di = 0
  foreach ($d in $drips) {
    $len = $d[1] + (($f + $di) % 4) * 2
    $dx = $ox + $d[0]
    Rect $b $dx 29 2 ($len) $bl2
    Rect $b $dx 29 1 $len (C '#e8505a')
    Rect $b $dx (29 + $len) 2 1 $bl1; Px $b ($dx + 1) (29 + $len - 1) $bl0
    $di++
  }
  Rect $b ($ox + 25) 29 8 2 $bl1; Rect $b ($ox + 26) 29 4 3 $bl2; Px $b ($ox + 27) 32 $bl2
  # のぞくおばけ（板の上にすわる）
  $gx = $ox + 56
  Ellipse $b ($gx + 8) 6 6.5 6 $bone
  Rect $b ($gx + 2) 6 13 6 $bone
  for ($x = 2; $x -lt 15; $x++) { $by = 12 + [int](($x + $f) % 3 -eq 0) ; Px $b ($gx + $x) 12 $bone2 }
  Rect $b ($gx + 11) 4 4 7 $bone2
  if ($f -eq 3) { Rect $b ($gx + 5) 6 2 1 $k2; Rect $b ($gx + 10) 6 2 1 $k2 } else { Rect $b ($gx + 5) 5 2 3 $k2; Rect $b ($gx + 10) 5 2 3 $k2; Px $b ($gx + 5) 5 $bone }
  Rect $b ($gx + 7) 9 2 2 $k2
  Px $b ($gx + 4) 8 (C '#ffb0d0'); Px $b ($gx + 12) 8 (C '#ffb0d0')
  $aw = @(0, -1, -2, -1)[$f]
  Ellipse $b ($gx + 17) (7 + $aw) 2 1.5 $bone; Ellipse $b ($gx + 0.5) 9 1.8 1.4 $bone
  Outline $b $ox 100 46 (C '#6a5ab8')
  # 板の外ふちを戻す（おばけのふちどりが板に重ならないように、板の上辺だけ線を引き直す）
  Rect $b ($ox + 2) 12 52 1 $k0; Rect $b ($ox + 74) 12 24 1 $k0
}

# ---- ふわふわ浮かぶおばけ 24x30 8コマ（白・青・ももの3色。表情も3種）
function GhostFrame($b, $ox, $f, $pal, $kind) {
  $ph = 2 * [math]::PI * $f / 8
  $bob = [int][math]::Round(2 * [math]::Sin($ph))
  $cy = 11 + $bob
  Ellipse $b ($ox + 12) $cy 8.5 8.5 $pal.body
  for ($x = 4; $x -le 20; $x++) {
    $bot = 23 + $bob + [int][math]::Round(1.8 * [math]::Sin($x * 0.95 - $ph))
    for ($y = $cy; $y -le $bot; $y++) { Px $b ($ox + $x) $y $pal.body }
  }
  $ao = [int][math]::Round(1.5 * [math]::Sin($ph + 1))
  Ellipse $b ($ox + 2.5) ($cy + 4 + $ao) 2.4 1.6 $pal.body
  Ellipse $b ($ox + 21.5) ($cy + 4 - $ao) 2.4 1.6 $pal.body
  for ($x = 15; $x -lt 24; $x++) { for ($y = 0; $y -lt 30; $y++) { if ($b.GetPixel($ox + $x, $y).A -gt 0) { Px $b ($ox + $x) $y $(if ($x -ge 19) { $pal.shade2 } else { $pal.shade }) } } }
  Px $b ($ox + 7) ($cy - 5) $bone; Px $b ($ox + 8) ($cy - 6) $bone; Px $b ($ox + 6) ($cy - 4) $bone
  $dk = C '#2a2250'
  if ($kind -eq 2) {
    Px $b ($ox + 8) $cy $dk; Px $b ($ox + 9) ($cy - 1) $dk; Px $b ($ox + 10) $cy $dk
    Px $b ($ox + 14) $cy $dk; Px $b ($ox + 15) ($cy - 1) $dk; Px $b ($ox + 16) $cy $dk
  } else {
    Rect $b ($ox + 8) ($cy - 1) 2 3 $dk; Rect $b ($ox + 14) ($cy - 1) 2 3 $dk
    Px $b ($ox + 8) ($cy - 1) $bone; Px $b ($ox + 14) ($cy - 1) $bone
  }
  if ($kind -eq 1) { Px $b ($ox + 10) ($cy + 4) $dk; Px $b ($ox + 11) ($cy + 5) $dk; Px $b ($ox + 12) ($cy + 5) $dk; Px $b ($ox + 13) ($cy + 4) $dk }
  else { Rect $b ($ox + 11) ($cy + 4) 2 2 $dk }
  $pk = C '#ffa0c8'
  Rect $b ($ox + 6) ($cy + 3) 2 1 $pk; Rect $b ($ox + 16) ($cy + 3) 2 1 $pk
  Outline $b $ox 24 30 $pal.line
}
$gpalW = @{ body = (C '#f4f2ff'); shade = (C '#d6d6f2'); shade2 = (C '#b0b1de'); line = (C '#7f72d6') }
$gpalB = @{ body = (C '#dcf0ff'); shade = (C '#b8d8f6'); shade2 = (C '#8cb8e8'); line = (C '#5a8ad6') }
$gpalP = @{ body = (C '#ffe6f6'); shade = (C '#f4c4e6'); shade2 = (C '#d896c8'); line = (C '#b068c8') }
Sheet 'obakeyashiki_ghost_w.png' 24 30 8 { param($b, $ox, $f) GhostFrame $b $ox $f $gpalW 0 }
Sheet 'obakeyashiki_ghost_b.png' 24 30 8 { param($b, $ox, $f) GhostFrame $b $ox $f $gpalB 1 }
Sheet 'obakeyashiki_ghost_p.png' 24 30 8 { param($b, $ox, $f) GhostFrame $b $ox $f $gpalP 2 }

# ---- 驚かし役（シーツをかぶった人。足が見える）22x30 2コマ
Sheet 'obakeyashiki_sheetman.png' 22 30 2 {
  param($b, $ox, $f)
  $sw = @(0, 1)[$f]
  Ellipse $b ($ox + 11) 9 7.5 7.5 $bone
  for ($y = 9; $y -le 25; $y++) {
    $hw = 7 + ($y - 9) * 0.22
    for ($x = [int][math]::Round(11 - $hw); $x -le [int][math]::Round(11 + $hw - 1); $x++) { Px $b ($ox + $x) $y $bone }
  }
  # すそのギザギザ
  for ($x = 4; $x -lt 18; $x++) { if ($x % 3 -eq 1) { Px $b ($ox + $x) 26 $bone2 } else { Px $b ($ox + $x) 25 $bone2 } }
  # うでを上げる（シーツのこぶ）
  Ellipse $b ($ox + 2.5) (13 - $sw * 2) 2.6 2.2 $bone
  Ellipse $b ($ox + 19.5) (13 - (1 - $sw) * 2) 2.6 2.2 $bone
  for ($x = 14; $x -lt 22; $x++) { for ($y = 0; $y -lt 30; $y++) { if ($b.GetPixel($ox + $x, $y).A -gt 0) { Px $b ($ox + $x) $y $(if ($x -ge 18) { $bone3 } else { $bone2 }) } } }
  # めのあな
  Ellipse $b ($ox + 8) 9 1.8 2.4 $k0; Ellipse $b ($ox + 14) 9 1.8 2.4 $k0
  Px $b ($ox + 7) 8 (C '#fff2a0'); Px $b ($ox + 13) 8 (C '#fff2a0')
  Ellipse $b ($ox + 11) 14 1.2 1.4 (C '#9a8ccc')
  # 足（くつ）
  Rect $b ($ox + 6) 26 4 2 (C '#d8d8e8'); Rect $b ($ox + 12) 26 4 2 (C '#d8d8e8'); Rect $b ($ox + 6) 28 4 1 $k2; Rect $b ($ox + 12) 28 4 1 $k2
  Outline $b $ox 22 30 (C '#7f72d6')
}

# ---- 鬼火（ひとだま）14x22 6コマ。ゆらめく炎、青緑のかさ
Sheet 'obakeyashiki_hitodama.png' 14 22 6 {
  param($b, $ox, $f)
  $ph = 2 * [math]::PI * $f / 6
  Ellipse $b ($ox + 7) 15 7 6.5 (CA '#3dffd8' 38)
  Ellipse $b ($ox + 7) 15 5.5 5 (CA '#3dffd8' 60)
  for ($y = 1; $y -le 19; $y++) {
    $t = (19 - $y) / 19.0
    $wig = 2.2 * [math]::Sin($ph + $y * 0.55) * $t
    $cx = 7 + $wig
    if ($y -lt 12) { $hw = 0.4 + ($y - 1) * 0.28 } else { $hw = 3.2 + ($y - 12) * 0.2 }
    if ($y -ge 15) { $hw = 4.4 - ($y - 15) * 0.55 }
    for ($x = [int][math]::Floor($cx - $hw); $x -le [int][math]::Ceiling($cx + $hw); $x++) {
      $e = [math]::Abs($x + 0.5 - $cx) / [math]::Max($hw, 0.5)
      $col = if ($e -lt 0.35) { $onb3 } elseif ($e -lt 0.65) { $onb2 } elseif ($e -lt 0.9) { $onb1 } else { $onb0 }
      Px $b ($ox + $x) $y $col
    }
  }
  Rect $b ($ox + 5) 14 1 2 (C '#0a3a3a'); Rect $b ($ox + 8) 14 1 2 (C '#0a3a3a')
}

# ---- コウモリ（屋根のまわりを飛ぶ。2匹）64x34 8コマ
function Bat($b, $cx, $cy, $up) {
  $wing = C '#3f3079'; $edge = C '#8a7be0'; $body = C '#241a45'
  $ty = if ($up) { -4 } else { 3 }
  foreach ($s in -1, 1) {
    for ($i = 0; $i -lt 3; $i++) { Line $b ($cx + $s) ($cy + $i - 1) ($cx + $s * 6) ([int][math]::Round($cy + $ty + $i * 0.5)) $wing }
    Line $b ($cx + $s) ($cy - 1) ($cx + $s * 6) ($cy + $ty) $edge
    Px $b ($cx + $s * 3) ($cy + $ty + 2) $wing
  }
  Rect $b ($cx - 1) ($cy - 1) 3 3 $body
  Px $b ($cx - 1) ($cy - 2) $body; Px $b ($cx + 1) ($cy - 2) $body
  Px $b ($cx - 1) $cy (C '#ff4a4a'); Px $b ($cx + 1) $cy (C '#ff4a4a')
}
Sheet 'obakeyashiki_bats.png' 64 34 8 {
  param($b, $ox, $f)
  $th = 2 * [math]::PI * $f / 8
  $up = ($f % 2) -eq 0
  Bat $b ($ox + [int][math]::Round(32 + 22 * [math]::Cos($th))) ([int][math]::Round(17 + 8 * [math]::Sin($th))) $up
  Bat $b ($ox + [int][math]::Round(32 + 18 * [math]::Cos($th + [math]::PI))) ([int][math]::Round(17 + 6 * [math]::Sin($th + [math]::PI))) (-not $up)
}

# ---- かぼちゃ提灯 16x16 3コマ（顔の光がちらつく）
Sheet 'obakeyashiki_pumpkin.png' 16 16 3 {
  param($b, $ox, $f)
  $glow = @((C '#ffcf5a'), (C '#fff2a0'), (C '#ff9a2e'))[$f]
  Ellipse $b ($ox + 8) 9.5 7.6 6 $or0
  Ellipse $b ($ox + 8) 9.5 6.8 5.4 $or2
  Ellipse $b ($ox + 4) 9.5 3 5.4 $or1
  Ellipse $b ($ox + 12) 9.5 3 5.4 $or1
  Rect $b ($ox + 3) 5 1 9 $or1; Rect $b ($ox + 12) 5 1 9 $or1; Rect $b ($ox + 7) 4 1 11 $or1
  Rect $b ($ox + 6) 4 4 1 $or3; Px $b ($ox + 4) 6 $or3
  Rect $b ($ox + 7) 1 2 3 (C '#3a5a2a'); Px $b ($ox + 9) 2 (C '#5a8a3a'); Px $b ($ox + 8) 1 (C '#5a8a3a')
  # 顔
  Rect $b ($ox + 4) 7 3 3 $glow; Rect $b ($ox + 10) 7 3 3 $glow
  Px $b ($ox + 4) 7 $or2; Px $b ($ox + 12) 7 $or2
  Rect $b ($ox + 5) 11 7 2 $glow; Px $b ($ox + 6) 11 $or1; Px $b ($ox + 8) 11 $or1; Px $b ($ox + 10) 11 $or1; Px $b ($ox + 7) 13 $or1; Px $b ($ox + 9) 13 $or1
}

# ---- ちょうちんおばけの柱 22x42 4コマ（柱に腕木、ひとつ目の提灯がゆれて、まばたきして、舌が出る）
Sheet 'obakeyashiki_lamppost.png' 22 42 4 {
  param($b, $ox, $f)
  # 柱
  Rect $b ($ox + 1) 4 4 38 $wd2; Rect $b ($ox + 1) 4 1 38 $wd3; Rect $b ($ox + 4) 4 1 38 $wd0
  Rect $b ($ox + 0) 38 6 4 $st2; Rect $b ($ox + 0) 38 6 1 $st4; Rect $b ($ox + 0) 41 6 1 $st1
  Rect $b ($ox + 1) 3 17 3 $wd2; Rect $b ($ox + 1) 3 17 1 $wd3; Rect $b ($ox + 1) 5 17 1 $wd0
  Line $b ($ox + 5) 13 ($ox + 10) 6 $wd2
  Line $b ($ox + 5) 14 ($ox + 10) 7 $wd0
  $sx = @(0, 1, 0, -1)[$f]
  $lx = 16 + $sx
  Line $b ($ox + $lx) 6 ($ox + $lx) 8 (C '#9494b0')
  Rect $b ($ox + $lx - 3) 8 7 2 $wd0
  Ellipse $b ($ox + $lx + 0.5) 17 6.2 8 (C '#6a5a40')
  Ellipse $b ($ox + $lx + 0.5) 17 5.4 7.2 (C '#f0e6c8')
  Ellipse $b ($ox + $lx + 0.5) 17 3.6 5.4 (C '#fff4c8')
  foreach ($ry in 12, 15, 19, 22) { Rect $b ($ox + $lx - 4) $ry 9 1 (C '#c8b890') }
  Rect $b ($ox + $lx + 2) 12 3 10 (C '#d8c898')
  # ひとつ目
  Ellipse $b ($ox + $lx) 16 3.2 3.4 (C '#6a3a40')
  if ($f -eq 3) { Rect $b ($ox + $lx - 3) 16 7 1 (C '#3a1a20'); Px $b ($ox + $lx - 3) 15 (C '#3a1a20'); Px $b ($ox + $lx + 3) 15 (C '#3a1a20') }
  else {
    Ellipse $b ($ox + $lx) 16 2.7 2.9 $bone
    Rect $b ($ox + $lx - 1) 15 2 3 $k0; Px $b ($ox + $lx - 1) 15 $bone
    Px $b ($ox + $lx - 2) 14 (C '#e05060'); Px $b ($ox + $lx + 2) 18 (C '#e05060')
  }
  Rect $b ($ox + $lx - 3) 24 7 2 $wd0
  $tl = @(5, 6, 5, 4)[$f]
  Rect $b ($ox + $lx - 1) 25 3 $tl (C '#e0507a'); Rect $b ($ox + $lx) 25 1 $tl (C '#ff90b0'); Rect $b ($ox + $lx - 1) (25 + $tl) 3 1 (C '#a02a54')
}

# ---- 大鍋（ぐつぐつ、緑の泡）20x24 4コマ
Sheet 'obakeyashiki_cauldron.png' 20 24 4 {
  param($b, $ox, $f)
  # 足元の火
  $fl = @(2, 3, 2, 3)[$f]
  Rect $b ($ox + 6) (22 - $fl) 3 $fl $or2; Rect $b ($ox + 10) (22 - $fl + 1) 3 ($fl - 1) $or3; Px $b ($ox + 8) (21 - $fl) $or3; Px $b ($ox + 12) (21 - $fl) $or2
  Rect $b ($ox + 3) 19 2 4 $k1; Rect $b ($ox + 15) 19 2 4 $k1
  Ellipse $b ($ox + 10) 15 8.6 7 (C '#120c20')
  Ellipse $b ($ox + 10) 15 7.8 6.2 (C '#1f1736')
  Ellipse $b ($ox + 7) 14 3 4.4 (C '#2a2150')
  Ellipse $b ($ox + 10) 9 8.8 3.2 (C '#3b3b4d')
  Ellipse $b ($ox + 10) 9.4 7.4 2.4 (C '#8bff4a')
  Ellipse $b ($ox + 9) 9.2 4.4 1.4 (C '#c8ffa0')
  Rect $b ($ox + 1) 9 2 2 (C '#5e5e78'); Rect $b ($ox + 17) 9 2 2 (C '#5e5e78')
  # 泡
  $by = @(8, 6, 4, 2)[$f]
  Rect $b ($ox + 7) $by 2 2 (C '#c8ffa0'); Px $b ($ox + 7) $by (C '#ffffff')
  $by2 = @(5, 3, 8, 7)[$f]
  Rect $b ($ox + 12) $by2 2 2 (C '#a8ff80'); Px $b ($ox + 12) $by2 (C '#ffffff')
  if ($f -eq 3) { Px $b ($ox + 6) 0 (CA '#8bff4a' 160); Px $b ($ox + 14) 1 (CA '#8bff4a' 160) }
  if ($f -eq 2) { Px $b ($ox + 9) 1 (CA '#8bff4a' 160); Px $b ($ox + 10) 0 (CA '#8bff4a' 110) }
}

# ---- 糸でおりてくるクモ 10x30 4コマ
Sheet 'obakeyashiki_spider.png' 10 30 4 {
  param($b, $ox, $f)
  $y = @(12, 16, 20, 16)[$f]
  for ($i = 0; $i -lt $y - 2; $i++) { Px $b ($ox + 5) $i (CA '#cfd0ee' 170) }
  Ellipse $b ($ox + 5) ($y + 1) 2.6 2.4 $k2
  Ellipse $b ($ox + 5) ($y) 1.8 1.6 $k3
  Px $b ($ox + 4) $y (C '#ff4a4a'); Px $b ($ox + 6) $y (C '#ff4a4a')
  $lg = C '#4b3b80'
  foreach ($s in -1, 1) {
    Line $b ($ox + 5 + $s * 2) ($y + 1) ($ox + 5 + $s * 4) ($y - 1) $lg; Line $b ($ox + 5 + $s * 4) ($y - 1) ($ox + 5 + $s * 5) ($y + 1) $lg
    Line $b ($ox + 5 + $s * 2) ($y + 2) ($ox + 5 + $s * 4) ($y + 3) $lg; Line $b ($ox + 5 + $s * 4) ($y + 3) ($ox + 5 + $s * 5) ($y + 4) $lg
  }
}

# ---- 霧（足もとをただよう）192x28 8コマ。横にゆっくり流れてつなぎ目なくループする
Sheet 'obakeyashiki_fog.png' 192 28 16 {
  param($b, $ox, $f)
  $tp = 2 * [math]::PI / 192
  for ($y = 0; $y -lt 28; $y++) {
    for ($x = 0; $x -lt 192; $x++) {
      $xs = $x - 12 * $f
      $n = [math]::Sin($tp * 3 * $xs + $y * 0.22) + [math]::Sin($tp * 5 * $xs - $y * 0.4 + 1.3) * 0.8 + [math]::Sin($tp * 2 * $xs + 2.1)
      $edge = 1.0 - [math]::Abs($y - 13) / 14.0
      $v = $n * 0.33 + $edge * 0.9 - 0.75
      if ($v -gt 0.28) { Px $b ($ox + $x) $y (CA '#c8c0f0' 62) }
      elseif ($v -gt 0.12) { if ((($x + $y) % 2) -eq 0) { Px $b ($ox + $x) $y (CA '#c8c0f0' 46) } }
    }
  }
}

# ---- 墓石（十字・丸型・かたむいた丸型）
function Shadow($b, $cx, $cy, $rx) { Ellipse $b $cx $cy $rx 2 (CA '#05030c' 100) }
Sheet 'obakeyashiki_tomb_a.png' 14 22 1 {
  param($b, $ox, $f)
  Shadow $b 7 20 6.5
  Rect $b 5 1 4 18 $st3; Rect $b 1 5 12 4 $st3
  Rect $b 5 1 1 18 $st4; Rect $b 1 5 1 4 $st4; Rect $b 5 1 4 1 $st4
  Rect $b 8 1 1 18 $st2; Rect $b 12 5 1 4 $st2; Rect $b 8 9 5 1 $st2
  Rect $b 4 18 6 2 $st1
  Line $b 6 11 7 14 $st0; Line $b 7 14 6 17 $st0
  Px $b 5 17 $moss; Px $b 6 18 $moss; Px $b 4 18 $moss; Px $b 9 18 $moss
  Outline $b 0 14 22 $st0
}
Sheet 'obakeyashiki_tomb_b.png' 14 20 1 {
  param($b, $ox, $f)
  Shadow $b 7 18 7
  Rect $b 1 6 12 11 $st3; Ellipse $b 7 6 6 5.5 $st3
  Rect $b 1 6 1 11 $st4; Rect $b 3 2 3 1 $st4; Px $b 2 4 $st4
  Rect $b 12 6 1 11 $st2; Rect $b 0 16 14 2 $st1; Rect $b 1 16 12 1 $st2
  # きざんだ十字
  Rect $b 6 6 2 7 $st1; Rect $b 4 8 6 2 $st1
  Line $b 3 14 5 13 $st1; Line $b 9 13 11 14 $st1
  for ($x = 2; $x -lt 12; $x += 3) { Px $b $x 15 $moss }
  Outline $b 0 14 20 $st0
}
Sheet 'obakeyashiki_tomb_c.png' 12 18 1 {
  param($b, $ox, $f)
  Shadow $b 6 16 5.5
  Rect $b 1 5 10 10 $st3; Ellipse $b 6 5 5 4.5 $st3
  Clear $b 10 2; Clear $b 11 3; Clear $b 11 4; Clear $b 10 3; Clear $b 11 5
  Rect $b 1 5 1 10 $st4; Rect $b 10 6 1 9 $st2; Rect $b 0 14 12 2 $st1
  Rect $b 4 6 4 3 $st1; Px $b 4 8 $st3; Px $b 7 8 $st3; Rect $b 5 9 2 1 $st1
  Line $b 8 10 5 14 $st0
  Px $b 2 13 $moss; Px $b 3 13 $moss; Px $b 9 14 $moss
  Outline $b 0 12 18 $st0
}

# ---- 枯れ木 44x64（うろに光る目、ぶら下がる小さなかぼちゃ）
Sheet 'obakeyashiki_tree.png' 44 64 1 {
  param($b, $ox, $f)
  $t0 = C '#2a1c24'; $t1 = C '#3d2832'; $t2 = C '#573a44'
  # 枝
  Thick $b 20 36 5 14 4 $t1; Thick $b 12 22 2 17 2 $t1; Thick $b 9 19 7 5 2 $t1
  Thick $b 23 34 38 12 4 $t1; Thick $b 32 21 42 15 2 $t1; Thick $b 34 17 36 4 2 $t1
  Thick $b 21 36 19 8 4 $t1; Thick $b 20 17 26 6 2 $t1; Thick $b 6 28 1 26 2 $t1
  # 幹（ねじれる）
  for ($y = 28; $y -lt 63; $y++) {
    $hw = 4 + ($y - 28) * 0.04 + $(if ($y -gt 54) { ($y - 54) * 0.7 } else { 0 })
    $cx = 22 + 1.4 * [math]::Sin($y * 0.16)
    for ($x = [int][math]::Floor($cx - $hw); $x -le [int][math]::Ceiling($cx + $hw - 1); $x++) {
      $e = ($x - ($cx - $hw)) / (2 * $hw)
      $c = if ($e -lt 0.28) { $t2 } elseif ($e -lt 0.7) { $t1 } else { $t0 }
      Px $b $x $y $c
    }
  }
  for ($i = 0; $i -lt 14; $i++) { $yy = 32 + $i * 2; Px $b (20 + ($i * 3) % 5) $yy $t0 }
  # うろ（顔）
  Ellipse $b 22 47 3.2 5 (C '#05030c')
  Rect $b 20 45 1 2 (C '#ffe94a'); Rect $b 24 45 1 2 (C '#ffe94a')
  Rect $b 21 50 3 1 (C '#2a1626'); Px $b 20 49 (C '#2a1626'); Px $b 24 49 (C '#2a1626')
  # 根
  Line $b 14 62 8 63 $t0; Line $b 30 62 36 63 $t0
  Outline $b 0 44 64 (C '#120a14')
  # ぶら下がるかぼちゃ
  Line $b 38 13 38 17 (C '#9494b0')
  Ellipse $b 38 20 3.6 3 $or1; Ellipse $b 38 20 2.8 2.4 $or2
  Px $b 37 19 $or4; Px $b 39 19 $or4; Rect $b 37 21 3 1 $or4; Px $b 38 16 (C '#3a5a2a')
  # 枯れ葉
  foreach ($p in @(@(5, 14), @(37, 11), @(14, 18), @(26, 8))) { Px $b $p[0] $p[1] (C '#7a3a40'); Px $b ($p[0] + 1) ($p[1] + 1) (C '#5a2a30') }
}

# ---- 鉄の柵（墓場のかこい）32x16
Sheet 'obakeyashiki_fence.png' 32 16 1 {
  param($b, $ox, $f)
  $ir = C '#2a2236'; $ih = C '#6a58a8'; $ir2 = C '#3b3b4d'
  Rect $b 0 6 32 1 $ir2; Rect $b 0 11 32 1 $ir2; Rect $b 0 6 32 1 (C '#4b4b60')
  for ($x = 2; $x -lt 32; $x += 6) {
    $top = if ($x -eq 14) { 5 } else { 2 }
    Rect $b $x $top 2 (15 - $top) $ir; Rect $b $x $top 1 (15 - $top) $ih
    Px $b $x ($top - 1) $ih; Px $b ($x + 1) $top $ir; Px $b $x ($top - 1) $ir
  }
  foreach ($x in 0, 28) { Rect $b $x 3 3 12 $ir; Rect $b $x 3 1 12 $ih; Ellipse $b ($x + 1.5) 3 2.2 2 $ir2; Px $b $x 2 $ih }
  Rect $b 0 15 32 1 (CA '#05030c' 120)
  Clear $b 14 4; Clear $b 15 4
}

# ---- 受付の机 46x28（黒い布と「受付」の札、ろうそく、鐘、がいこつ）
Sheet 'obakeyashiki_booth.png' 46 28 1 {
  param($b, $ox, $f)
  # 机の上
  Rect $b 0 8 46 4 $wd3; Rect $b 0 8 46 1 (C '#7a5a8a'); Rect $b 0 11 46 1 $wd0
  # 布
  Rect $b 1 12 44 14 $k0
  for ($x = 2; $x -lt 45; $x += 5) { Rect $b $x 12 1 14 $k2 }
  Rect $b 1 12 44 2 $k3
  for ($x = 1; $x -lt 45; $x++) { $d = if ((($x - 1) % 6) -lt 3) { 2 } else { 1 }; Rect $b $x 26 1 $d (C '#6a1a4a') }
  Rect $b 1 24 44 1 (C '#6a1a4a')
  # 札
  Rect $b 8 14 30 9 $k1; Frame $b 8 14 30 9 $k6
  [void](TextPx $b '受付' 19 14 11 $bone $false)
  Ellipse $b 14 18.5 2.8 3.2 $bone; Rect $b 12 18 5 3 $bone; Px $b 13 18 $k0; Px $b 15 18 $k0
  # ろうそく
  Rect $b 5 3 3 6 $bone2; Rect $b 5 3 1 6 $bone; Px $b 6 1 $or3; Px $b 6 0 $or2; Px $b 6 2 $or4; Rect $b 4 8 5 1 $gold3
  # 鐘と紙
  Ellipse $b 40 6.5 2.6 2.4 $gold2; Rect $b 37 7 7 2 $gold2; Px $b 40 3 $gold3; Px $b 39 6 (C '#fff0b0'); Rect $b 39 9 2 1 $gold3
  Rect $b 18 4 8 4 (C '#d8d0b8'); Rect $b 18 4 8 1 $bone; Px $b 20 6 $k3; Px $b 23 6 $k3
  Rect $b 28 5 6 3 (C '#c8c0a8'); Px $b 29 6 $bl1; Px $b 31 6 $bl1
  Clear $b 0 8; Clear $b 45 8
  Rect $b 3 26 4 2 $k0; Rect $b 39 26 4 2 $k0
}

# ---- のぼり旗「おばけやしき」18x80（血のしたたるふち）
Sheet 'obakeyashiki_nobori.png' 18 80 1 {
  param($b, $ox, $f)
  Rect $b 0 2 18 2 $wd2; Rect $b 0 2 2 78 $wd3; Rect $b 0 2 1 78 (C '#7a5a8a')
  Rect $b 3 4 14 72 $k2; Rect $b 3 4 14 1 $k5; Rect $b 3 4 1 72 $k5; Rect $b 16 4 1 72 $k1; Rect $b 4 75 12 1 $k1
  Frame $b 4 5 12 70 $k3
  $chars = 'お', 'ば', 'け', 'や', 'し', 'き'
  for ($i = 0; $i -lt 6; $i++) { [void](TextPx $b $chars[$i] 5 (7 + 11 * $i) 11 $k0 $false); [void](TextPx $b $chars[$i] 4 (6 + 11 * $i) 11 $bone $false) }
  # 血のしたたり
  $dl = @(2, 5, 3, 6, 2, 4, 3)
  for ($i = 0; $i -lt 7; $i++) { Rect $b (4 + $i * 2) 76 1 $dl[$i] $bl2; Rect $b (5 + $i * 2) 76 1 ($dl[$i] - 1) $bl1 }
  Rect $b 3 74 14 2 $bl1
  Clear $b 17 79
}

# ---- 行列ロープの支柱 8x16 と ロープ（たてに長い）8x22
Sheet 'obakeyashiki_stanchion.png' 8 16 1 {
  param($b, $ox, $f)
  Ellipse $b 4 14 3.6 1.6 $k0; Ellipse $b 4 13.6 3 1.2 $k3
  Rect $b 3 4 2 10 (C '#2a2236'); Rect $b 3 4 1 10 $k5
  Ellipse $b 4 3 2.6 2.4 $gold3; Ellipse $b 4 2.8 2 1.8 $gold2; Px $b 3 2 (C '#fff0b0')
}
Sheet 'obakeyashiki_rope.png' 8 17 1 {
  param($b, $ox, $f)
  for ($y = 0; $y -lt 17; $y++) {
    $sag = [int][math]::Round(2.4 * [math]::Sin($y / 16.0 * [math]::PI))
    Px $b (3 + $sag) $y $bl2; Px $b (4 + $sag) $y $bl1
  }
}

# ---- 光だまり・影
Sheet 'obakeyashiki_glow_o.png' 44 22 1 {
  param($b, $ox, $f)
  $i = 0
  foreach ($r in @(1.0, 0.78, 0.56, 0.34)) { Ellipse $b 22 11 (22 * $r) (11 * $r) (CA '#ff9a2e' (20 + $i * 16)); $i++ }
}
Sheet 'obakeyashiki_glow_b.png' 36 18 1 {
  param($b, $ox, $f)
  $i = 0
  foreach ($r in @(1.0, 0.78, 0.56, 0.34)) { Ellipse $b 18 9 (18 * $r) (9 * $r) (CA '#3dffd8' (14 + $i * 12)); $i++ }
}
Sheet 'obakeyashiki_shadow.png' 16 6 1 {
  param($b, $ox, $f)
  Ellipse $b 8 3 7 2.4 (CA '#05030c' 90); Ellipse $b 8 3 4.5 1.4 (CA '#05030c' 40)
}
