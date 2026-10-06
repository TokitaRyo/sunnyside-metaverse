# 模擬カジノの専用ドット絵（ネオン看板・ルーレット台・カードテーブル・ダイス台・スロットマシン・コイン交換所・ベルベットロープ・赤い絨毯など）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/casino.ps1
# 出力: client/public/brand/stall/casino_*.png （配置は scripts/stalls/casino.mjs）
# ゲーム用のコインやチップだけで遊ぶ「模擬」カジノ。お金は賭けない。配色は赤・金・黒・濃い緑 + ネオン（ピンク・シアン・金）。
# アニメは「フレームを横一列に並べたPNG」で、casino.mjs の k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。
. "$PSScriptRoot\..\lib\pixel.ps1"

function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function Sheet($name, $w, $h, $n, $draw) {
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}
function Glyph($b, $g, $x, $y, $s, $col) {
  for ($r = 0; $r -lt $g.Count; $r++) { for ($c = 0; $c -lt $g[$r].Length; $c++) { if ($g[$r].Substring($c, 1) -eq 'X') { Rect $b ($x + $c * $s) ($y + $r * $s) $s $s $col } } }
}

# ---- 色: 黒・赤・金・フェルトの緑・木・ネオン
$k0 = C '#0b080d'; $k1 = C '#17101a'; $k2 = C '#241823'; $k3 = C '#382636'
$r0 = C '#4a0a16'; $r1 = C '#7a1024'; $r2 = C '#b01a30'; $r3 = C '#e03048'; $r4 = C '#ff6a78'
$g0 = C '#6b4310'; $g1 = C '#a8741c'; $g2 = C '#e8b23a'; $g3 = C '#ffd96a'; $g4 = C '#fff2b8'
$f0 = C '#08402a'; $f1 = C '#0f5c3a'; $f2 = C '#167a4d'; $f3 = C '#22a066'
$wd0 = C '#2a140e'; $wd1 = C '#4a2618'; $wd2 = C '#6e3a22'; $wd3 = C '#94562f'
$cream = C '#f4efe0'; $wht = C '#fffaf0'
$nPink = C '#ff3d9a'; $nCyan = C '#3df5ff'; $nGold = C '#ffd23d'; $nRed = C '#ff3b4f'; $nGreen = C '#3dff7a'; $nViolet = C '#a05bff'

# ===== 床 192x128: 黒と濃い赤紫の市松 + 真ん中に金の縁取りの赤い絨毯（入口から奥まで）
Sheet 'casino_floor.png' 192 128 1 {
  param($b, $ox, $f)
  $ca = C '#1c121d'; $cb = C '#291a29'
  for ($ty = 0; $ty -lt 16; $ty++) { for ($tx = 0; $tx -lt 24; $tx++) { Rect $b ($tx * 8) ($ty * 8) 8 8 $(if ((($tx + $ty) % 2) -eq 0) { $ca } else { $cb }) } }
  $rnd = New-Object System.Random 11
  for ($i = 0; $i -lt 70; $i++) { Px $b ($rnd.Next(0, 192)) ($rnd.Next(0, 128)) (C '#5c4524') }
  for ($i = 0; $i -lt 14; $i++) { Px $b ($rnd.Next(0, 192)) ($rnd.Next(0, 128)) (C '#8a6a30') }
  # 一番奥（壁の上の部分）は壁の色
  $wa = C '#42101e'; $wb = C '#36091a'
  for ($x = 0; $x -lt 192; $x++) { Rect $b $x 0 1 18 $(if (([math]::Floor($x / 8) % 2) -eq 0) { $wa } else { $wb }) }
  # 絨毯
  Rect $b 72 0 48 128 $r1
  Rect $b 72 0 1 128 $k0; Rect $b 119 0 1 128 $k0
  Rect $b 73 0 1 128 $g2; Rect $b 118 0 1 128 $g2
  Rect $b 74 0 1 128 $r0; Rect $b 117 0 1 128 $r0
  Rect $b 76 0 1 128 $r2; Rect $b 115 0 1 128 $r2
  Rect $b 77 0 1 128 $r0; Rect $b 114 0 1 128 $r0
  for ($y = 0; $y -lt 128; $y += 16) {
    $cy = $y + 8
    for ($d = 0; $d -le 6; $d++) {
      $w = 6 - [math]::Abs($d - 3) * 2 + 1
      if ($w -gt 0) { Rect $b (96 - [int][math]::Floor($w / 2)) ($cy - 3 + $d) $w 1 $g2 }
    }
    for ($d = 1; $d -le 5; $d++) {
      $w = 4 - [math]::Abs($d - 3) * 2 + 1
      if ($w -gt 0) { Rect $b (96 - [int][math]::Floor($w / 2)) ($cy - 3 + $d) $w 1 $r2 }
    }
    Px $b 96 $cy $g3
    foreach ($sx in 83, 109) { Px $b $sx $cy $g1; Px $b ($sx - 1) $cy $r0; Px $b ($sx + 1) $cy $r0; Px $b $sx ($cy - 1) $r0; Px $b $sx ($cy + 1) $r0 }
    Px $b 83 ($y + 0) $g1
  }
  # 入口のしきい（金の帯）
  Rect $b 72 122 48 1 $g1; Rect $b 72 123 48 1 $g3; Rect $b 72 124 48 1 $g1
}

# ===== 奥の壁 192x38: ダマスク柄の赤紫の壁、上に金のコーニス（電球の溝）、下は木の腰板。上の帯の左右にトランプのマーク
$suitSpade = @('...X...', '..XXX..', '.XXXXX.', 'XXXXXXX', 'XXXXXXX', '.XX.XX.', '..XXX..')
$suitHeart = @('.XX.XX.', 'XXXXXXX', 'XXXXXXX', 'XXXXXXX', '.XXXXX.', '..XXX..', '...X...')
$suitDia = @('...X...', '..XXX..', '.XXXXX.', 'XXXXXXX', '.XXXXX.', '..XXX..', '...X...')
$suitClub = @('..XXX..', '..XXX..', 'XX.X.XX', 'XXXXXXX', 'XX.X.XX', '...X...', '..XXX..')
Sheet 'casino_wall.png' 192 38 1 {
  param($b, $ox, $f)
  $wa = C '#42101e'; $wb = C '#36091a'
  for ($x = 0; $x -lt 192; $x++) { Rect $b $x 0 1 38 $(if ((([math]::Floor($x / 8)) % 2) -eq 0) { $wa } else { $wb }) }
  # ダマスクの小さな金の十字
  for ($sx = 0; $sx -lt 24; $sx++) {
    foreach ($sy in 13, 23) {
      $x = $sx * 8 + 4; $y = $sy + (($sx % 2) * 5)
      Px $b $x $y $g1; Px $b ($x - 1) $y $g0; Px $b ($x + 1) $y $g0; Px $b $x ($y - 1) $g0; Px $b $x ($y + 1) $g0
    }
  }
  # コーニス
  Rect $b 0 0 192 1 $g3; Rect $b 0 1 192 1 $g1
  Rect $b 0 2 192 3 (C '#14080c')
  Rect $b 0 5 192 1 $g1; Rect $b 0 6 192 1 $g2; Rect $b 0 7 192 1 $g0
  for ($x = 0; $x -lt 192; $x += 4) { Px $b $x 8 $g1; Px $b ($x + 1) 8 $g1; Px $b $x 9 $g0 }
  # トランプのマーク（左右の帯）
  $lx = @(6, 22, 158, 174)
  $ro = @($suitSpade, $suitHeart, $suitDia, $suitClub)
  $cc = @($g2, $nRed, $nRed, $g2)
  for ($i = 0; $i -lt 4; $i++) {
    $ix = $lx[$i]; $iy = 14
    Rect $b ($ix - 2) ($iy - 2) 11 11 (C '#2a0812')
    Frame $b ($ix - 2) ($iy - 2) 11 11 $g0
    Ascii $b $ix $iy $ro[$i] @{ X = $cc[$i] }
    Px $b ($ix + 2) ($iy + 1) $wht
  }
  # 腰板
  Rect $b 0 30 192 8 $wd1
  Rect $b 0 30 192 1 $g2; Rect $b 0 31 192 1 $g0
  for ($x = 0; $x -lt 192; $x += 24) { Rect $b ($x + 2) 33 20 4 $wd0; Rect $b ($x + 2) 33 20 1 $wd2 }
  Rect $b 0 37 192 1 $k0
}

# ===== 壁の上の電球の列 192x6 4コマ（ちかちかと流れる）
Sheet 'casino_marquee.png' 192 6 4 {
  param($b, $ox, $f)
  for ($i = 0; $i -lt 32; $i++) {
    $x = 2 + $i * 6
    if ((($i + $f) % 4) -lt 2) {
      Rect $b ($ox + $x) 2 2 2 $g4
      Px $b ($ox + $x - 1) 2 (CA '#ffd96a' 120); Px $b ($ox + $x + 2) 2 (CA '#ffd96a' 120)
      Px $b ($ox + $x) 1 (CA '#ffd96a' 110); Px $b ($ox + $x + 1) 1 (CA '#ffd96a' 110)
      Px $b ($ox + $x) 4 (CA '#ffd96a' 110); Px $b ($ox + $x + 1) 4 (CA '#ffd96a' 110)
    } else {
      Rect $b ($ox + $x) 2 2 2 $g0
      Px $b ($ox + $x) 2 $g1
    }
  }
}

# ===== 看板 CASINO 120x36（ネオンの文字が順に光り、縁の電球が流れる）6コマ
$glyph = @{
  C = @('.XXX.', 'X...X', 'X....', 'X....', 'X....', 'X...X', '.XXX.')
  A = @('.XXX.', 'X...X', 'X...X', 'XXXXX', 'X...X', 'X...X', 'X...X')
  S = @('.XXXX', 'X....', 'X....', '.XXX.', '....X', '....X', 'XXXX.')
  I = @('XXXXX', '..X..', '..X..', '..X..', '..X..', '..X..', 'XXXXX')
  N = @('X...X', 'XX..X', 'XX..X', 'X.X.X', 'X..XX', 'X..XX', 'X...X')
  O = @('.XXX.', 'X...X', 'X...X', 'X...X', 'X...X', 'X...X', '.XXX.')
}
Sheet 'casino_sign.png' 120 36 6 {
  param($b, $ox, $f)
  Rect $b $ox 0 120 36 $k0
  Frame $b ($ox + 1) 1 118 34 $g1
  Frame $b ($ox + 2) 2 116 32 $g3
  Rect $b ($ox + 3) 3 114 30 (C '#12060c')
  # 縁の電球
  $bi = 0
  for ($x = 4; $x -lt 116; $x += 6) {
    foreach ($y in 0, 33) { $on = ((($bi + $f) % 3) -ne 0); Rect $b ($ox + $x) ($y + 0) 2 2 $(if ($on) { $g4 } else { $g0 }) }
    $bi++
  }
  $bj = 0
  for ($y = 5; $y -lt 32; $y += 6) {
    foreach ($x in 0, 118) { $on = ((($bj + $f) % 3) -ne 0); Rect $b ($ox + $x) $y 2 2 $(if ($on) { $g4 } else { $g0 }) }
    $bj++
  }
  # 文字
  $names = 'C', 'A', 'S', 'I', 'N', 'O'
  for ($i = 0; $i -lt 6; $i++) {
    $x = 8 + $i * 18
    $hot = ($i -eq ($f % 6))
    $col = if ($hot) { $nGold } else { $nPink }
    $sh = if ($hot) { C '#6b4a10' } else { C '#5a0f3a' }
    Glyph $b $glyph[$names[$i]] ($ox + $x + 1) 8 3 $sh
    Glyph $b $glyph[$names[$i]] ($ox + $x) 7 3 $col
    Rect $b ($ox + $x) 7 15 1 $(if ($hot) { $wht } else { Mix $nPink $wht 0.55 })
  }
  # 隅の星
  foreach ($p in @(@(10, 4), @(109, 4), @(10, 31), @(109, 31))) {
    $sp = if ($f % 2 -eq 0) { $nCyan } else { $wht }
    Px $b ($ox + $p[0]) $p[1] $sp
  }
  foreach ($p in @(@(0, 0), @(119, 0), @(0, 35), @(119, 35))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ===== 壁の札 104x32（「コインで あそぼう」「おかねは かけません」）
Sheet 'casino_plaque.png' 104 32 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 104 32 $k0
  Frame $b ($ox + 1) 1 102 30 $g2
  Frame $b ($ox + 2) 2 100 28 $g0
  Rect $b ($ox + 3) 3 98 26 $f0
  Rect $b ($ox + 3) 3 98 1 $f1
  [void](TextPx $b 'コインで あそぼう' ($ox + 12) 5 10 $g3 $true)
  [void](TextPx $b 'おかねは かけません' ($ox + 7) 17 10 $wht $true)
  foreach ($p in @(@(1, 1), @(102, 1), @(1, 30), @(102, 30))) { Px $b ($ox + $p[0]) $p[1] $g4 }
  foreach ($p in @(@(0, 0), @(103, 0), @(0, 31), @(103, 31))) { Clear $b ($ox + $p[0]) $p[1] }
}

# ===== たて型のネオン「カジノ」 15x46 4コマ（色がかわる）
Sheet 'casino_vsign.png' 15 46 4 {
  param($b, $ox, $f)
  $cols = @($nPink, $nCyan, $nGold, $nGreen)
  $fc = $cols[$f % 4]; $tc = $cols[($f + 2) % 4]
  Rect $b ($ox + 7) 0 1 3 $g1
  Rect $b $ox 3 15 43 $k0
  Rect $b ($ox + 1) 4 13 41 (C '#12060c')
  Frame $b ($ox + 1) 4 13 41 $fc
  Frame $b ($ox + 2) 5 11 39 (Mix $fc (C '#12060c') 0.6)
  $chars = 'カ', 'ジ', 'ノ'
  for ($i = 0; $i -lt 3; $i++) { [void](TextPx $b $chars[$i] ($ox + 2) (7 + 11 * $i) 11 $tc $false) }
  Ascii $b ($ox + 4) 40 $suitHeart @{ X = $nRed }
  Clear $b $ox 3; Clear $b ($ox + 14) 3
}

# ===== スロットマシン 15x32 4コマ（リールが回り、ランプが光る）。赤と緑の2色
$symG = @(
  @('RRR', '..R', '.R.', '.R.'),
  @('.SS', 'S.S', 'R.R', 'R.R'),
  @('KKK', 'YYY', 'YYY', 'KKK'),
  @('.B.', 'BBB', 'BBB', '.B.')
)
$symC = @{ R = (C '#d6203a'); S = (C '#2a8a3a'); Y = (C '#f2b020'); K = (C '#1a1018'); B = (C '#2f6bff') }
$reelOrder = @(@(0, 1, 2, 3), @(2, 3, 0, 1), @(1, 2, 3, 0))
function DrawSlot($b, $ox, $f, $body, $bodyD, $bodyL) {
  $lamp = @($nRed, $nGold, $nCyan, $wht)[$f % 4]
  Rect $b ($ox + 4) 1 7 5 $k0
  Ellipse $b ($ox + 7.5) 3.2 2.9 2.6 $lamp
  Px $b ($ox + 6) 2 $wht
  Rect $b $ox 5 15 27 $k0
  Rect $b ($ox + 1) 6 13 25 $body
  Rect $b ($ox + 1) 6 1 25 $bodyL
  Rect $b ($ox + 13) 6 1 25 $bodyD
  # 上の電球の帯
  Rect $b ($ox + 2) 6 11 4 $k0
  for ($i = 0; $i -lt 5; $i++) { $on = ((($i + $f) % 2) -eq 0); Rect $b ($ox + 3 + $i * 2) 7 1 2 $(if ($on) { $g3 } else { $g0 }) }
  # 窓の枠
  Rect $b ($ox + 1) 10 13 12 $g2
  Rect $b ($ox + 1) 10 13 1 $g4
  Rect $b ($ox + 2) 11 11 10 $k1
  for ($ri = 0; $ri -lt 3; $ri++) {
    $rx = $ox + 2 + $ri * 4
    for ($wy = 0; $wy -lt 10; $wy++) {
      $sy = ($wy - $f * 5 + $ri * 3 + 200) % 20
      $si = [int][math]::Floor($sy / 5); $sr = $sy % 5
      $edge = if ($wy -eq 0 -or $wy -eq 9) { 0.4 } else { 0.0 }
      for ($c = 0; $c -lt 3; $c++) {
        $col = $cream
        if ($sr -lt 4) {
          $ch = $symG[$reelOrder[$ri][$si]][$sr].Substring($c, 1)
          if ($ch -ne '.') { $col = $symC[$ch] }
        }
        if ($edge -gt 0) { $col = Mix $col $k0 $edge }
        Px $b ($rx + $c) (11 + $wy) $col
      }
    }
  }
  # ボタンとコイン口
  Rect $b ($ox + 1) 22 13 5 $bodyD
  Rect $b ($ox + 3) 23 2 2 $nRed; Rect $b ($ox + 6) 23 3 2 $g3; Rect $b ($ox + 10) 23 2 2 $nCyan
  Rect $b ($ox + 5) 26 5 1 $k0; Rect $b ($ox + 6) 26 3 1 $g2
  # コイン受け
  Rect $b ($ox + 2) 28 11 3 $k0
  Px $b ($ox + 4) 30 $g2; Px $b ($ox + 5) 30 $g2; Px $b ($ox + 8) 30 $g2; Px $b ($ox + 9) 30 $g3
  Px $b ($ox + 4 + ($f % 3) * 3) 30 $g4
  Rect $b $ox 31 15 1 $k0
  Clear $b $ox 5; Clear $b ($ox + 14) 5
}
Sheet 'casino_slot_r.png' 15 32 4 { param($b, $ox, $f) DrawSlot $b $ox $f $r2 $r1 $r3 }
Sheet 'casino_slot_g.png' 15 32 4 { param($b, $ox, $f) DrawSlot $b $ox $f (C '#168050') (C '#0d5535') (C '#22a066') }

# ===== ルーレットの回転盤 26x16 6コマ（赤黒の升目が回り、白い玉がまわる）
Sheet 'casino_wheel.png' 26 16 6 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 13) 9.2 12.8 7.2 $k0
  Ellipse $b ($ox + 13) 8 12.8 7.2 $k0
  Ellipse $b ($ox + 13) 8 12.1 6.7 $wd2
  Ellipse $b ($ox + 13) 7.6 11.4 6.2 $wd3
  for ($y = 0; $y -lt 16; $y++) {
    for ($x = 0; $x -lt 26; $x++) {
      $u = ($x + 0.5 - 13) / 10.4; $v = ($y + 0.5 - 8) / 5.8
      $r = [math]::Sqrt($u * $u + $v * $v)
      if ($r -gt 1) { continue }
      $a = [math]::Atan2($v, $u) - $f * ([math]::PI / 18)
      if ($r -gt 0.9) { $col = $g2 }
      elseif ($r -gt 0.58) {
        $idx = [int][math]::Floor((($a / (2 * [math]::PI)) % 1 + 1) % 1 * 12)
        $col = if (($idx % 2) -eq 0) { $r3 } else { $k1 }
        if ($r -gt 0.82) { $col = Mix $col $g2 0.35 }
      }
      elseif ($r -gt 0.36) { $col = $wd0 }
      elseif ($r -gt 0.16) { $col = $(if ([math]::Abs([math]::Sin(2 * $a)) -gt 0.88) { $g4 } else { $g2 }) }
      else { $col = $g4 }
      Px $b ($ox + $x) $y $col
    }
  }
  $th = -$f * 1.15 + 0.6
  $bx = 13 + 10.4 * 0.74 * [math]::Cos($th); $by = 8 + 5.8 * 0.74 * [math]::Sin($th)
  Px $b ($ox + [int][math]::Floor($bx)) ([int][math]::Floor($by)) $wht
  Px $b ($ox + [int][math]::Floor($bx) + 1) ([int][math]::Floor($by)) (C '#c8c8d8')
}

# ===== ルーレット台 62x34（緑のフェルト、数字の升目、チップ。回転盤は別の絵を左に重ねる）
Sheet 'casino_roulette_table.png' 62 34 1 {
  param($b, $ox, $f)
  # 台の側面
  Rect $b 1 24 60 9 $wd1
  Rect $b 1 24 60 1 $g2; Rect $b 1 25 60 1 $g0
  for ($x = 0; $x -lt 3; $x++) { $px0 = 4 + $x * 19; Rect $b $px0 27 15 5 $wd0; Rect $b $px0 27 15 1 $wd2; Px $b $px0 27 $g2; Px $b ($px0 + 14) 27 $g2 }
  Rect $b 1 33 60 1 $k0
  Rect $b 2 33 4 1 $k0
  # 上面のふち
  Rect $b 0 2 62 23 $k0
  Rect $b 1 3 60 21 $wd2
  Rect $b 1 3 60 1 $wd3
  Rect $b 1 23 60 1 $wd1
  # フェルト
  Rect $b 4 6 54 16 $f2
  Frame $b 4 6 54 16 $f0
  Rect $b 5 7 52 1 $f3
  # 金の線
  Frame $b 3 5 56 18 $g1
  # 数字の升目（右）
  Rect $b 30 8 3 11 $f0
  Rect $b 30 8 3 11 (C '#1d7a45')
  for ($r = 0; $r -lt 3; $r++) {
    for ($c = 0; $c -lt 6; $c++) {
      $gx = 33 + $c * 4; $gy = 8 + $r * 4
      Rect $b $gx $gy 4 4 $cream
      Rect $b ($gx + 1) ($gy + 1) 3 3 $(if ((($c + $r) % 2) -eq 0) { $r3 } else { $k1 })
    }
  }
  Rect $b 33 20 12 2 $cream; Rect $b 34 20 10 1 $r3
  Rect $b 45 20 12 2 $cream; Rect $b 46 20 10 1 $k1
  Px $b 31 13 $wht
  # チップ
  Rect $b 37 9 2 1 $nCyan; Rect $b 45 13 2 1 $nGold; Rect $b 53 9 2 1 $nPink; Rect $b 41 17 2 1 $nGreen
  Px $b 37 8 $wht; Px $b 45 12 $wht
  # 回転盤の置き場（くぼみ）
  Ellipse $b 16 14 13 7.5 $f0
  Ellipse $b 16 13.6 12.4 7 $k1
  Clear $b 0 2; Clear $b 61 2; Clear $b 0 23; Clear $b 61 23
}

# ===== カードテーブル（ブラックジャック風の半円）62x34
Sheet 'casino_card_table.png' 62 34 1 {
  param($b, $ox, $f)
  # 側面
  Ellipse $b 31 7 31 24 $wd1
  Ellipse $b 31 6 31 24 $wd0
  Ellipse $b 31 3 31 24 $k0
  Ellipse $b 31 3 30 23 (C '#2a1824')
  Ellipse $b 31 3 29 22 $k1
  Ellipse $b 31 3 28.4 21.4 $g2
  Ellipse $b 31 3 27.6 20.6 $f1
  Ellipse $b 31 3 26.8 19.8 $f2
  # 上の半分は切る
  for ($y = 0; $y -lt 3; $y++) { for ($x = 0; $x -lt 62; $x++) { Px $b $x $y ([System.Drawing.Color]::FromArgb(0, 0, 0, 0)) } }
  Rect $b 1 3 60 3 $k1; Rect $b 1 3 60 1 $k3
  Rect $b 3 6 56 1 $g2
  # フェルトの上の模様: 外側の弧
  for ($a = 0.35; $a -lt 2.8; $a += 0.05) { Px $b ([int](31 + 23 * [math]::Cos($a))) ([int](3 + 15.5 * [math]::Sin($a))) $f3 }
  # ベッティングの丸（3つ）
  foreach ($p in @(@(13, 15), @(31, 19), @(49, 15))) {
    Ellipse $b $p[0] $p[1] 4.4 3.2 $g1
    Ellipse $b $p[0] $p[1] 3.6 2.5 $f2
    Ellipse $b $p[0] $p[1] 2.2 1.4 $f1
  }
  # 配られたカード（ディーラー）
  Rect $b 24 7 6 8 $cream; Frame $b 24 7 6 8 (C '#c8c0a8'); Rect $b 26 9 2 2 $r3; Px $b 27 12 $r3
  Rect $b 31 8 6 8 $cream; Frame $b 31 8 6 8 (C '#c8c0a8'); Rect $b 33 10 2 3 $k1; Px $b 34 13 $k1
  # カード（お客さんの前）
  Rect $b 9 11 5 7 $cream; Rect $b 10 13 2 2 $k1
  Rect $b 14 12 5 7 $cream; Rect $b 15 14 2 2 $r3
  Rect $b 45 12 5 7 $cream; Rect $b 46 14 2 2 $r3
  # チップの山（円の中）
  foreach ($p in @(@(31, 18, 0), @(13, 14, 1), @(49, 14, 2))) {
    $cc = @($nRed, $nCyan, $nGold)[$p[2]]
    Rect $b ($p[0] - 1) ($p[1]) 3 2 $cc; Rect $b ($p[0] - 1) ($p[1] - 1) 3 1 (Mix $cc $wht 0.55)
  }
  # フェルト上の金の飾り（中央）
  Px $b 31 11 $g2; Px $b 30 12 $g1; Px $b 32 12 $g1; Px $b 31 13 $g2
}

# ===== ダイス台（クラップス風）46x26
Sheet 'casino_dice_table.png' 46 26 1 {
  param($b, $ox, $f)
  Rect $b 1 19 44 6 $wd1
  Rect $b 1 19 44 1 $g2; Rect $b 1 20 44 1 $g0
  for ($x = 0; $x -lt 3; $x++) { Rect $b (4 + $x * 14) 21 10 4 $wd0; Rect $b (4 + $x * 14) 21 10 1 $wd2 }
  Rect $b 1 25 44 1 $k0
  Rect $b 0 0 46 20 $k0
  Rect $b 1 1 44 18 $r1
  Rect $b 1 1 44 1 $r3
  Rect $b 2 2 42 16 $r2
  Frame $b 2 2 42 16 $g2
  Rect $b 4 4 38 12 $f2
  Frame $b 4 4 38 12 $f0
  # ペアの線とボックス
  Rect $b 6 6 34 1 $cream; Rect $b 6 13 34 1 $cream
  foreach ($x in 6, 11, 16, 30, 35, 40) { Rect $b $x 6 1 8 $cream }
  Rect $b 17 7 12 6 $f1
  Rect $b 20 9 6 2 $g2; Px $b 22 9 $g4
  # チップ
  Rect $b 8 8 2 1 $nRed; Rect $b 8 7 2 1 (Mix $nRed $wht 0.5)
  Rect $b 36 9 2 1 $nCyan; Rect $b 36 8 2 1 (Mix $nCyan $wht 0.5)
  Clear $b 0 0; Clear $b 45 0
}

# ===== ダイス 14x12 4コマ（ころがる）
$pip = @{
  1 = @(@(1, 1))
  2 = @(@(0, 0), @(2, 2))
  3 = @(@(0, 0), @(1, 1), @(2, 2))
  4 = @(@(0, 0), @(2, 0), @(0, 2), @(2, 2))
  5 = @(@(0, 0), @(2, 0), @(1, 1), @(0, 2), @(2, 2))
  6 = @(@(0, 0), @(2, 0), @(0, 1), @(2, 1), @(0, 2), @(2, 2))
}
function Die($b, $x, $y, $n) {
  Rect $b $x $y 5 5 $wht
  Rect $b $x ($y + 4) 5 1 (C '#c8c0b0')
  Px $b $x $y $k1; Px $b ($x + 4) $y $k1
  foreach ($p in $pip[$n]) { Px $b ($x + 1 + $p[0]) ($y + 1 + $p[1]) $(if ($n -eq 1) { $r3 } else { $k0 }) }
}
Sheet 'casino_dice.png' 14 12 4 {
  param($b, $ox, $f)
  $ys = @(7, 3, 1, 7)[$f]
  $fa = @(3, 6, 4, 5)[$f]; $fb = @(5, 2, 1, 6)[$f]
  if ($f -ne 3) { Ellipse $b ($ox + 4.5) 10.5 2.4 1 (CA '#000000' 90); Ellipse $b ($ox + 10.5) 10.5 2.4 1 (CA '#000000' 90) }
  Die $b ($ox + 2) ($ys) $fa
  Die $b ($ox + 8) ($ys + 1 - [int]($f -eq 2)) $fb
  if ($f -eq 3) { Px $b ($ox + 1) 5 $g4; Px $b ($ox + 13) 6 $g4 }
}

# ===== チップの山 16x12（2種類）
function Chips($b, $ox, $stacks) {
  foreach ($s in $stacks) {
    $x = $ox + $s[0]; $base = 11; $col = $s[2]
    for ($k = 0; $k -lt $s[1]; $k++) {
      $y = $base - 2 * ($k + 1)
      Rect $b $x ($y + 1) 6 2 (Mix $col $k0 0.45)
      Rect $b $x $y 6 2 $col
      Px $b ($x + 1) ($y + 1) $wht; Px $b ($x + 4) ($y + 1) $wht
    }
    $ty = $base - 2 * $s[1] - 1
    Rect $b ($x + 1) $ty 4 1 (Mix $col $wht 0.6)
    Px $b $x ($ty + 1) (Mix $col $wht 0.3)
    Ellipse $b ($x + 3) 11.2 3.4 0.8 (CA '#000000' 80)
  }
}
Sheet 'casino_chips_a.png' 16 12 1 { param($b, $ox, $f) Chips $b $ox @(@(1, 4, $nRed), @(5, 3, (C '#2f6bff')), @(9, 5, (C '#2a2a35')), @(11, 2, $g2)) }
Sheet 'casino_chips_b.png' 16 12 1 { param($b, $ox, $f) Chips $b $ox @(@(0, 3, $g2), @(5, 5, $nRed), @(10, 4, (C '#1d9a5e'))) }

# ===== きらめき 9x9 4コマ
Sheet 'casino_sparkle.png' 9 9 4 {
  param($b, $ox, $f)
  $s = @(0, 1, 2, 1)[$f]
  Px $b ($ox + 4) 4 $wht
  if ($s -ge 1) { Px $b ($ox + 3) 4 $g4; Px $b ($ox + 5) 4 $g4; Px $b ($ox + 4) 3 $g4; Px $b ($ox + 4) 5 $g4 }
  if ($s -ge 2) { Px $b ($ox + 2) 4 $g3; Px $b ($ox + 6) 4 $g3; Px $b ($ox + 4) 2 $g3; Px $b ($ox + 4) 6 $g3; Px $b ($ox + 1) 4 (CA '#ffd96a' 120); Px $b ($ox + 7) 4 (CA '#ffd96a' 120); Px $b ($ox + 4) 1 (CA '#ffd96a' 120); Px $b ($ox + 4) 7 (CA '#ffd96a' 120) }
}

# ===== あたたかい光だまり（床の上、半透明）76x48 3コマ（かすかにゆれる）
Sheet 'casino_glow.png' 76 48 3 {
  param($b, $ox, $f)
  $amp = @(1.0, 0.86, 0.95)[$f]
  for ($y = 0; $y -lt 48; $y++) {
    for ($x = 0; $x -lt 76; $x++) {
      $u = ($x + 0.5 - 38) / 37; $v = ($y + 0.5 - 24) / 23.5
      $r = [math]::Sqrt($u * $u + $v * $v)
      if ($r -lt 1) {
        $a = [int](70 * $amp * (1 - $r) * (1 - $r) + 6 * $amp * (1 - $r))
        if ($a -gt 0) { Px $b ($ox + $x) $y (CA '#ffc860' $a) }
      }
    }
  }
}

# ===== ベルベットロープ 24x18（金の支柱ふたつに赤いロープ）
Sheet 'casino_rope.png' 24 18 1 {
  param($b, $ox, $f)
  foreach ($px0 in 3, 20) {
    Ellipse $b ($ox + $px0 + 0.5) 16 3 1.3 $k0
    Ellipse $b ($ox + $px0 + 0.5) 15.6 2.4 0.9 $g1
    Rect $b ($ox + $px0) 5 2 11 $g2; Rect $b ($ox + $px0) 5 1 11 $g4
    Ellipse $b ($ox + $px0 + 1) 3.6 2.2 2.2 $g2
    Px $b ($ox + $px0) 3 $g4
  }
  for ($x = 4; $x -le 20; $x++) {
    $t = ($x - 4) / 16.0
    $y = [int][math]::Round(6 + 4 * [math]::Sin($t * [math]::PI))
    Rect $b ($ox + $x) $y 1 2 $r2
    Px $b ($ox + $x) $y $r4
    Px $b ($ox + $x) ($y + 2) $r0
  }
}

# ===== コイン交換所のカウンター 56x24（前板に「コイン」の札、天板にコインの山。店員は奥に立つ）
Sheet 'casino_counter.png' 56 24 1 {
  param($b, $ox, $f)
  Rect $b 0 9 56 15 $k0
  Rect $b 1 10 54 13 $wd1
  Rect $b 1 10 54 1 $g2; Rect $b 1 11 54 1 $g0
  foreach ($x in 2, 48) { Rect $b $x 13 6 9 $wd0; Rect $b $x 13 6 1 $wd2 }
  Rect $b 2 23 4 1 $k0; Rect $b 50 23 4 1 $k0
  # 天板
  Rect $b 0 4 56 6 $wd3
  Rect $b 0 4 56 1 (C '#d89a5a')
  Rect $b 0 9 56 1 $wd1
  # 札「コイン」
  Rect $b 10 11 36 12 $k0
  Frame $b 10 11 36 12 $nGold
  Rect $b 11 12 34 10 (C '#1a0c10')
  [void](TextPx $b 'コイン' 12 12 10 $g3 $true)
  # 天板の上のコインの山
  Rect $b 42 2 5 3 $g1; Rect $b 42 1 5 1 $g3; Px $b 43 2 $g4; Px $b 45 3 $g0
  Rect $b 49 3 5 2 $g1; Rect $b 49 2 5 1 $g3; Px $b 50 3 $g4
  Rect $b 36 3 4 2 $g2; Rect $b 36 2 4 1 $g3
  Clear $b 0 4; Clear $b 55 4
}

# ===== 黒いタキシードの蝶ネクタイ 7x4（ディーラーの胸元に重ねる）
Sheet 'casino_bowtie.png' 7 4 1 {
  param($b, $ox, $f)
  Ascii $b $ox 0 @('RR...RR', 'RRRKRRR', 'RR.K.RR', '.......') @{ R = $nRed; K = $k0 }
  Px $b ($ox + 1) 0 $r4; Px $b ($ox + 5) 0 $r4
}

# ===== 木の丸いすのスツール 9x10（赤いクッション）
Sheet 'casino_stool.png' 9 10 1 {
  param($b, $ox, $f)
  Ellipse $b ($ox + 4.5) 8.8 4 1.2 (CA '#000000' 80)
  Rect $b ($ox + 2) 5 1 4 $g1; Rect $b ($ox + 6) 5 1 4 $g1
  Rect $b ($ox + 3) 7 3 1 $g0
  Ellipse $b ($ox + 4.5) 3.4 4.5 3 $k0
  Ellipse $b ($ox + 4.5) 3.2 4 2.6 $r2
  Rect $b ($ox + 2) 2 3 1 $r3
  Px $b ($ox + 2) 1 $r4
}

# ===== 観葉植物（金のはち）16x28
Sheet 'casino_plant.png' 16 28 1 {
  param($b, $ox, $f)
  $l1 = C '#1d7a3a'; $l2 = C '#2fa04c'; $l3 = C '#6ed07a'
  Ellipse $b ($ox + 8) 26.4 6 1.4 (CA '#000000' 80)
  Rect $b ($ox + 3) 17 10 9 $k0
  Rect $b ($ox + 4) 18 8 7 $g2
  Rect $b ($ox + 4) 18 2 7 $g4; Rect $b ($ox + 10) 18 2 7 $g1
  Rect $b ($ox + 3) 17 10 2 $g3; Rect $b ($ox + 3) 17 10 1 $g4
  Rect $b ($ox + 5) 25 6 1 $k0
  Rect $b ($ox + 4) 18 8 1 $g3
  Line $b ($ox + 8) 17 ($ox + 8) 8 $l1
  foreach ($p in @(@(8, 8, 1, 3), @(8, 9, 14, 6), @(8, 10, 2, 8), @(8, 12, 13, 11), @(8, 6, 11, 2), @(8, 7, 5, 1))) {
    Line $b ($ox + $p[0]) $p[1] ($ox + $p[2]) $p[3] $l2
    Line $b ($ox + $p[0]) ($p[1] + 1) ($ox + $p[2]) ($p[3] + 1) $l1
  }
  Px $b ($ox + 8) 5 $l3; Px $b ($ox + 3) 5 $l3; Px $b ($ox + 12) 8 $l3
}
