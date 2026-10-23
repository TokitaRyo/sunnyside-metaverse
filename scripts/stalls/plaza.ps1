# 広場の「ずんだもん」コーナーの専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/plaza.ps1   （リポジトリのルートで）
#   一部だけ作り直す: $env:PLAZA_ONLY='zunda|sign'   （名前の正規表現。空なら全部）
# 出力: client/public/brand/stall/plaza_*.png（原点は各スプライトの足元。配置は scripts/stalls/plaza.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル。特徴（黄緑の髪・枝豆のさや形の耳・笑顔・ずんだ餅）を手がかりにした、非公式のファンアート風のドット絵。
# 日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（黄緑 x 白。ずんだ餅のあんの色）
$olg = C '#2a4a1a'                                             # ふち（濃い緑）
$hr0 = C '#4f9a28'; $hr1 = C '#8ed63a'; $hr2 = C '#c4f26a'    # 髪
$sk0 = C '#ffe3cc'; $sk1 = C '#f2bf9e'; $pk = C '#ff9aa0'     # はだ・ほお
$eyc = C '#3b2314'; $eyb = C '#7a4a26'; $mth = C '#7a2a2a'; $tng = C '#ff7a8a'
$pd0 = C '#3f8a22'; $pd1 = C '#6cbc3c'; $pd2 = C '#a6e862'; $pd3 = C '#d8ffa0'   # 枝豆のさや
$zg0 = C '#5a9a26'; $zg1 = C '#8ed03a'; $zg2 = C '#b6ec5a'; $zg3 = C '#e8ffb0'   # ずんだのあん
$mc0 = C '#c9d3bf'; $mc1 = C '#f2f5ea'; $mc2 = C '#ffffff'                       # 餅
$sh0 = C '#e8efdc'; $sh1 = C '#fbfdf6'
$tx0 = C '#2f6a1a'; $bd0 = C '#f6edcc'
$wh0 = C '#f7f9f2'; $wh1 = C '#d3e3c2'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

function Want($name) { if (-not $env:PLAZA_ONLY) { return $true }; return ($name -match $env:PLAZA_ONLY) }

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

# =====================================================================
# ---- ずんだもん（NPC）6コマのアニメ。1コマ 32x38 を横に並べる（足元の中央が原点）
# 立って軽く上下にはずみ、枝豆のさや形の耳が ぴょこぴょこ（開いたり閉じたり）動く
$podRows = @(
  '...gg.',
  '..gbbg',
  '..gbyg',
  '..geeg',
  '.gbbbg',
  '.gbybg',
  '..geeg',
  '..gbbg',
  '...gg.'
)
$podPal = @{ g = $pd0; e = $pd1; b = $pd2; y = $pd3 }
$podFac = @(1.0, 1.0, 1.0, 0.7, 0.5, 0.3, 0.0, 0.0, 0.0)

function DrawPod($b, $x0, $y0, $mirror, $sh) {
  for ($r = 0; $r -lt 9; $r++) {
    $row = $podRows[$r]
    if ($mirror) { $chars = $row.ToCharArray(); [array]::Reverse($chars); $row = -join $chars }
    $off = [int][math]::Round($sh * $podFac[$r], [System.MidpointRounding]::AwayFromZero)
    for ($c = 0; $c -lt 6; $c++) {
      $ch = [string]$row[$c]
      if ($ch -ne '.') { Px $b ($x0 + $c + $off) ($y0 + $r) $podPal[$ch] }
    }
  }
}

$headRows = @(
  '....dhhllllhhd....',
  '..dhhhhhllhhhhhd..',
  '.dhhhhhhhhhhhhhhd.',
  '.dhhhhhhhhhhhhhhd.',
  'dhhhhhhhhhhhhhhhhd',
  'dhhhhsshhhhhhsshhd',
  ('dhh' + ('s' * 12) + 'hhd'),
  ('dhhs' + 'kkk' + 'ssss' + 'kkk' + 's' + 'hhd'),
  ('dhhs' + 'kwk' + 'ssss' + 'kwk' + 's' + 'hhd'),
  ('dhhs' + 'kok' + 'ssss' + 'kok' + 's' + 'hhd'),
  ('dhhss' + 'k' + 'ssssss' + 'k' + 'ss' + 'hhd'),
  ('dhhppss' + 'mmmm' + 'sspp' + 'hhd'),
  ('.dh' + 'ssss' + 'mrrm' + 'ssss' + 'hd.'),
  '...dssssssssssd...'
)
foreach ($r in $headRows) { if ($r.Length -ne 18) { throw "headRow の長さが 18 ではありません: $r ($($r.Length))" } }
$headPal = @{ d = $hr0; h = $hr1; l = $hr2; s = $sk0; n = $sk1; k = $eyc; w = $white; o = $eyb; p = $pk; m = $mth; r = $tng }

function ZunFrame($bob, $t) {
  $b = NewBmp 30 36
  $hy = 10 - $bob; $ty = $hy + 14
  $skirt0 = C '#5f9f2c'; $skirt1 = C '#86cc40'; $skirt2 = C '#a6e060'
  $shoe0 = C '#3f8a22'; $shoe1 = C '#7cc43e'
  # 足とくつ（はずむとき、足がのびる）
  foreach ($lx in 12, 16) {
    Rect $b $lx ($ty + 8) 2 (34 - ($ty + 8)) $sk0
    Rect $b $lx 32 2 2 $wh0
    Rect $b ($lx - 1) 34 4 2 $shoe1; Rect $b ($lx - 1) 35 4 1 $shoe0
  }
  # スカート（黄緑）
  Rect $b 9 ($ty + 5) 12 3 $skirt1
  Rect $b 9 ($ty + 7) 12 1 $skirt0
  foreach ($x in 11, 14, 17) { Rect $b $x ($ty + 5) 1 3 $skirt2 }
  Rect $b 9 ($ty + 5) 12 1 $skirt2
  # 上着（白）と黄緑のリボン
  Rect $b 10 $ty 10 5 $wh0
  Rect $b 19 $ty 1 5 $wh1; Rect $b 10 ($ty + 4) 10 1 $wh1
  Rect $b 10 ($ty + 3) 10 1 $skirt1
  Rect $b 12 $ty 6 1 $skirt1
  Rect $b 13 ($ty + 1) 4 1 $skirt1; Px $b 14 $ty $skirt0; Px $b 15 $ty $skirt0
  Px $b 14 ($ty + 1) $skirt2; Px $b 15 ($ty + 1) $skirt2
  # うで（はずむとき、少しあがる）
  $ad = 0; if ($bob -ge 2) { $ad = -1 }
  Rect $b 8 ($ty + 1 + $ad) 2 4 $wh0; Rect $b 8 ($ty + 5 + $ad) 2 2 $sk0
  Rect $b 20 ($ty + 1 + $ad) 2 4 $wh0; Rect $b 20 ($ty + 5 + $ad) 2 2 $sk0
  Px $b 9 ($ty + 4 + $ad) $wh1; Px $b 20 ($ty + 4 + $ad) $wh1
  # 枝豆の耳（左右がたがいちがいに開いたり閉じたり）
  DrawPod $b 5 ($hy - 7) $false (-1 + $t)
  DrawPod $b 19 ($hy - 7) $true (1 - $t)
  # 頭（黄緑の髪・笑顔）
  Ascii $b 6 $hy $headRows $headPal
  return (OutlineBmp $b $olg)
}

if (Want 'zunda') {
  $bobs = @(0, 1, 2, 2, 1, 0)
  $ts = @(0, 1, 1, 0, (-1), (-1))
  $FW = 32
  $b = NewBmp ($FW * 6) 38
  for ($f = 0; $f -lt 6; $f++) {
    $fr = ZunFrame $bobs[$f] $ts[$f]
    Blit $b $fr ($f * $FW) 0
    $fr.Dispose()
  }
  Save $b 'plaza_zunda.png'
}

# =====================================================================
# ---- ずんだ餅のお皿（餅3つ。つやのある黄緑のあんが白い餅にのっている）34x21
function Mochi() {
  $b = NewBmp 9 7
  # 白い餅（下）
  Rect $b 0 3 9 3 $mc1; Rect $b 1 6 7 1 $mc0; Rect $b 0 4 1 2 $mc2; Rect $b 8 5 1 1 $mc0
  # つやのある黄緑のあん（上。ふちから少したれる）
  Rect $b 2 0 5 1 $zg2; Rect $b 1 1 7 1 $zg1; Rect $b 0 2 9 1 $zg1; Rect $b 0 3 9 1 $zg0
  foreach ($x in 1, 4, 7) { Px $b $x 4 $zg0 }
  Px $b 4 5 $zg0
  Px $b 3 1 $zg3; Px $b 4 0 $zg3; Px $b 2 2 $zg2; Px $b 6 1 $zg2
  Px $b 5 2 $zg0; Px $b 7 2 $zg0; Px $b 2 3 $zg1
  return (OutlineBmp $b $olg)
}
if (Want 'mochi') {
  $b = NewBmp 34 21
  Ellipse $b 17 14 16.5 6.5 (C '#b4c2a4')
  Ellipse $b 17 13 16.5 6.5 (C '#cfe6a8')
  Ellipse $b 17 13 15 5.5 $sh0
  Ellipse $b 17 13 13 4.2 $sh1
  $m1 = Mochi; Blit $b $m1 6 3; $m1.Dispose()
  $m2 = Mochi; Blit $b $m2 17 3; $m2.Dispose()
  $m3 = Mochi; Blit $b $m3 11 8; $m3.Dispose()
  $o = OutlineBmp $b $olg
  Save $o 'plaza_mochi.png'
}

# ---- 枝豆のかご（さや入りの小さなかご）26x22
function PodH() {
  $b = NewBmp 10 5
  Ellipse $b 5 2.5 5 2.4 $pd1
  Rect $b 1 1 8 1 $pd2
  foreach ($x in 2, 4, 6) { Px $b $x 2 $pd2; Px $b ($x + 1) 2 $pd2 }
  Rect $b 1 4 8 1 $pd0
  Px $b 9 2 $pd0
  return (OutlineBmp $b $olg)
}
function PodV() {
  $b = NewBmp 5 10
  Ellipse $b 2.5 5 2.4 5 $pd1
  Rect $b 1 1 1 8 $pd2
  foreach ($y in 2, 4, 6) { Px $b 2 $y $pd2; Px $b 2 ($y + 1) $pd2 }
  Rect $b 4 1 1 8 $pd0
  Px $b 2 0 $pd0
  return (OutlineBmp $b $olg)
}
if (Want 'basket') {
  $b = NewBmp 26 22
  # さや（かごの上に山盛り。うしろから手前へ）
  $p = PodV; Blit $b $p 4 1; $p.Dispose()
  $p = PodV; Blit $b $p 15 0; $p.Dispose()
  $p = PodH; Blit $b $p 2 5; $p.Dispose()
  $p = PodH; Blit $b $p 12 4; $p.Dispose()
  $p = PodV; Blit $b $p 9 2; $p.Dispose()
  $p = PodH; Blit $b $p 6 8; $p.Dispose()
  $p = PodH; Blit $b $p 14 8; $p.Dispose()
  # かご（編み目）
  for ($y = 12; $y -lt 21; $y++) {
    $inset = [int][math]::Floor(($y - 12) / 4)
    for ($x = $inset; $x -lt 26 - $inset; $x++) {
      $c = $w2
      if ((([math]::Floor(($x + ($y % 2) * 2) / 4) + $y) % 2) -eq 0) { $c = $w3 }
      if ($y -eq 12) { $c = $w1 }
      if ($y -eq 20) { $c = $w3 }
      Px $b $x $y $c
    }
  }
  Rect $b 0 11 26 2 $w1; Rect $b 0 12 26 1 $w2
  $o = OutlineBmp $b $olg
  Save $o 'plaza_basket.png'
}

# ---- テーブル（白と黄緑のチェックのテーブルクロス）56x26。足元が下のへり
if (Want 'table') {
  $b = NewBmp 56 26
  $cA = $mc2; $cB = C '#c8ea92'; $cC = C '#9ccf5a'
  # 天板（上の面）
  for ($y = 1; $y -lt 12; $y++) {
    for ($x = 0; $x -lt 56; $x++) {
      $ck = ([math]::Floor($x / 4) + [math]::Floor($y / 4)) % 2
      $c = $cA; if ($ck -eq 0) { $c = $cB }
      if ($y -eq 1) { $c = $mc2 }
      Px $b $x $y $c
    }
  }
  # 垂れ下がる前の布
  for ($y = 12; $y -lt 25; $y++) {
    for ($x = 0; $x -lt 56; $x++) {
      $ck = ([math]::Floor($x / 4) + [math]::Floor($y / 4)) % 2
      $c = $cA; if ($ck -eq 0) { $c = $cB }
      if ($y -eq 12) { $c = $cC }
      if ($x % 14 -eq 0 -and $y -gt 12) { $c = $cC }
      if ($y -gt 21) { if ($c -eq $cA) { $c = $mc1 } else { $c = $cC } }
      Px $b $x $y $c
    }
  }
  # すそのぎざぎざ
  for ($x = 0; $x -lt 56; $x++) { if (([math]::Floor($x / 4) % 2) -eq 0) { Px $b $x 25 $cC } }
  $o = OutlineBmp $b $olg
  Save $o 'plaza_table.png'
}

# ---- 立て札「ずんだもん」64x32。足元が下のへり
if (Want 'sign') {
  $b = NewBmp 64 32
  # 脚
  foreach ($x in 10, 50) { Rect $b $x 17 4 15 $w2; Rect $b $x 17 1 15 $w1; Rect $b ($x + 3) 17 1 15 $w3 }
  # 板
  Rect $b 0 0 64 19 $w3
  Rect $b 1 1 62 17 $w2
  Rect $b 2 2 60 15 $bd0
  Rect $b 2 2 60 1 (C '#fffaf0')
  Rect $b 2 16 60 1 (C '#dccfa4')
  $tw = TextWidth 'ずんだもん' 11
  $tx = [int][math]::Floor((64 - ($tw + 1)) / 2)
  [void](TextPx $b 'ずんだもん' $tx 4 11 $tx0 $true)
  foreach ($p in @(@(0, 0), @(63, 0))) { Clear $b $p[0] $p[1] }
  $o = OutlineBmp $b $olg
  Save $o 'plaza_sign.png'
}
