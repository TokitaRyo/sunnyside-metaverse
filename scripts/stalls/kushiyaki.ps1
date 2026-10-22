# 串焼き屋台の専用ドット絵（看板・のぼり・赤提灯・縞の日よけ・炭火の焼き台・串立て・たこ唐揚げの揚げ鍋/バット/紙の容器・メニュー・牛のマスコットなど）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/kushiyaki.ps1   （リポジトリのルートで）
#   一部だけ作り直す: $env:KUSHIYAKI_ONLY='sign|grill'   （名前の正規表現。sign nobori lantern roof counter post grill smoke fryer bat cups plate kushitate menu mascot sumi mat）
# 出力: client/public/brand/stall/kushiyaki_*.png（原点は各スプライトの足元。配置は scripts/stalls/kushiyaki.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Want($n) { if (-not $env:KUSHIYAKI_ONLY) { return $true }; return ($n -match $env:KUSHIYAKI_ONLY) }

# ---- 色（炭の黒・炭火の橙・赤提灯の赤。たこ焼き屋の紺と黄色、お好み焼き屋の赤白とはちがう）
$ch0 = C '#221d1b'; $ch1 = C '#352e2b'; $ch2 = C '#4d4440'; $ch3 = C '#6e625b'
$or0 = C '#a8431c'; $or = C '#e0662a'; $or2 = C '#f2923a'; $or3 = C '#ffd27a'
$goldT = C '#ffe08a'
$redL = C '#d8342b'; $redL2 = C '#a82320'; $redL3 = C '#f25b4a'
$cream2 = C '#f3e9d0'; $cream3 = C '#d9ceb0'
$stick = C '#e0c088'; $stick2 = C '#b8914f'
$kraft = C '#d6ad72'; $kraft2 = C '#a8804a'
$mt0 = C '#4a413c'; $mt1 = C '#6e625a'; $mt2 = C '#9c8f84'
$st0 = C '#7d8696'; $st1 = C '#b9c0cc'; $st2 = C '#e4e8f2'
$e0 = C '#7a2a18'; $e1 = C '#d8401a'; $e2 = C '#ff7a28'; $e3 = C '#ffb347'
$ka0 = C '#a8601c'; $ka1 = C '#d9902c'; $ka2 = C '#f0c060'; $kaR = C '#c0602a'; $flour = C '#f6efe0'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
# 串の肉の色（面・ハイライト・こげ）
$kC = @((C '#d29a55'), (C '#ecc079'), (C '#6e3b1e'))   # 焼き鳥
$kB = @((C '#80382a'), (C '#a8573e'), (C '#34170f'))   # 牛串
$kG = @((C '#4f9f40'), (C '#8ed06a'), (C '#2c5f26'))   # ねぎ

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
        $a = $i + $d[0]; $c2 = $j + $d[1]
        if ($a -ge 0 -and $c2 -ge 0 -and $a -lt $src.Width -and $c2 -lt $src.Height -and $m[$a, $c2]) { $near = $true }
      }
      if ($near) { $n.SetPixel($i + 1, $j + 1, $col) }
    }
  }
  $src.Dispose()
  return $n
}
# 0..1 の決まった乱数（x,y,z から）
function Hs($x, $y, $z) { $v = [math]::Sin($x * 12.9898 + $y * 78.233 + $z * 37.719) * 43758.5453; return ($v - [math]::Floor($v)) }

# ---- 串（肉3切れ）。type: c=焼き鳥 b=牛串 n=ねぎま
function Chunk($b, $x, $y, $w, $h, $pal) {
  Rect $b $x $y $w $h $pal[0]
  Rect $b $x $y $w 1 $pal[1]
  Px $b ($x + $w - 1) ($y + $h - 1) $pal[2]
  Px $b ($x + 1) ($y + $h - 1) $pal[2]
}
function ChunkPal($type, $i) {
  if ($type -eq 'b') { return ,$kB }
  if ($type -eq 'n' -and ($i % 2) -eq 1) { return ,$kG }
  return ,$kC
}
# 横向きの串。stick は (x,y) から len の長さ。肉は幅 cw の3切れを真ん中に
function HSkew($b, $x, $y, $len, $cw, $type) {
  Line $b $x $y ($x + $len) $y $stick
  $x0 = $x + [int][math]::Floor(($len - 3 * $cw) / 2)
  for ($i = 0; $i -lt 3; $i++) { $p = ChunkPal $type $i; Chunk $b ($x0 + $i * $cw) ($y - 1) $cw 3 $p }
}
# 縦向きの串。stick は (xc,y) から下へ len。肉は幅3高さ3の3切れを先のほうに
function VSkew($b, $xc, $y, $len, $type) {
  Line $b $xc $y $xc ($y + $len) $stick
  for ($i = 0; $i -lt 3; $i++) { $p = ChunkPal $type $i; Chunk $b ($xc - 1) ($y + 2 + $i * 3) 3 3 $p }
}
# たこの唐揚げ1個（4x3）
function Kara($b, $x, $y, $v) {
  Rect $b $x $y 4 3 $ka1
  Px $b $x $y $ka2; Px $b ($x + 1) $y $ka2
  Px $b $x ($y + 2) $ka0; Px $b ($x + 2) ($y + 2) $ka0; Px $b ($x + 3) ($y + 2) $ka0
  if (($v % 2) -eq 1) { Px $b ($x + 2) ($y + 1) $kaR }
  if (($v % 3) -eq 0) { Px $b ($x + 1) ($y + 1) $flour }
  if (($v % 5) -eq 2) { Px $b ($x + 3) $y $ka2 }
}

# ---- 牛のマスコット（はちまきをしめた牛の顔）
function Cow() {
  $b = NewBmp 16 14
  $cw = C '#fbf7ee'; $cs = C '#d9d2c4'; $ck = C '#2b2624'; $cp = C '#f2a8a0'; $cph = C '#b86a68'; $chn = C '#e8d4a0'; $ce = C '#1b1b2b'
  Rect $b 2 0 2 3 $chn; Rect $b 12 0 2 3 $chn
  Rect $b 0 5 3 3 $cw; Px $b 1 6 $cp; Rect $b 13 5 3 3 $cw; Px $b 14 6 $cp
  Rect $b 2 2 12 11 $cw
  Rect $b 13 3 1 9 $cs
  Rect $b 3 2 3 2 $ck
  Rect $b 12 8 2 4 $ck
  Rect $b 2 4 12 2 $redL; Rect $b 2 4 12 1 $redL3
  Rect $b 4 7 1 2 $ce; Rect $b 11 7 1 2 $ce
  Rect $b 4 9 8 4 $cp; Rect $b 5 9 6 1 (C '#f8c4be')
  Px $b 6 11 $cph; Px $b 9 11 $cph
  return (OutlineBmp $b (C '#3a2420'))
}

# =====================================================================
# ---- 看板（光る電球がまわる4コマ）140x54。黒い板に木のふち、「串焼き屋」と品名、下に赤い札「北海道産牛」
if (Want 'sign') {
  $FW = 160; $FH = 54
  $t1 = '串焼き屋'; $t2 = '牛串 焼き鳥 たこ唐揚げ'; $t3 = '北海道産牛'
  $w1t = TextWidth $t1 14; $w2t = TextWidth $t2 11; $w3t = TextWidth $t3 11
  Write-Host "sign text widths: $w1t $w2t $w3t"
  $fl0 = @('...oo...', '...oo...', '..ooo...', '..ooyo..', '.oooyoo.', '.ooyyoo.', '.oyyyyo.', '.oyyyyo.', '..oyyo..', '...oo...')
  $fl1 = @('...oo...', '...ooo..', '...ooo..', '..oyoo..', '.oooyoo.', '.ooyyoo.', '.oyyyyo.', '.oyyyyo.', '..oyyo..', '...oo...')
  $flPal = @{ o = $or; y = (C '#ffd24a') }
  $b = NewBmp ($FW * 4) $FH
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * $FW
    Rect $b ($ox + 24) 0 3 4 $w3; Rect $b ($ox + 133) 0 3 4 $w3
    Rect $b $ox 3 $FW 34 $ol
    Rect $b ($ox + 1) 4 ($FW - 2) 32 $w3
    Rect $b ($ox + 1) 4 ($FW - 2) 1 $w2
    Rect $b ($ox + 4) 7 ($FW - 8) 26 $ch0
    Rect $b ($ox + 4) 7 ($FW - 8) 1 $ch1
    # まわる電球（上と下のふち）
    for ($i = 0; $i -lt 19; $i++) {
      $x = $ox + 7 + 8 * $i
      $on1 = ((($i + $f) % 4) -lt 2); $on2 = ((($i + 2 + $f) % 4) -lt 2)
      $c1 = if ($on1) { $or3 } else { $or0 }; $c2 = if ($on2) { $or3 } else { $or0 }
      Rect $b $x 5 2 2 $c1; Rect $b $x 33 2 2 $c2
    }
    foreach ($p in @(@(0, 3), @(($FW - 1), 3), @(0, 36), @(($FW - 1), 36))) { Px $b ($ox + $p[0]) $p[1] $clear }
    # 炎のしるし（左右）と大きな店名
    if (($f % 2) -eq 0) { $fl = $fl0 } else { $fl = $fl1 }
    Ascii $b ($ox + 20) 10 $fl $flPal
    Ascii $b ($ox + $FW - 28) 10 $fl $flPal
    [void](TextPx $b $t1 ($ox + [int][math]::Floor(($FW - $w1t - 1) / 2)) 8 14 $goldT $true)
    [void](TextPx $b $t2 ($ox + [int][math]::Floor(($FW - $w2t - 1) / 2)) 21 11 $white $true)
    # 札
    Rect $b ($ox + 106) 37 1 2 $cream3; Rect $b ($ox + 150) 37 1 2 $cream3
    Rect $b ($ox + 98) 39 60 14 $cream2
    Rect $b ($ox + 99) 40 58 12 $redL
    Rect $b ($ox + 99) 40 58 1 $redL3
    Rect $b ($ox + 99) 51 58 1 $redL2
    foreach ($p in @(@(98, 39), @(157, 39), @(98, 52), @(157, 52))) { Px $b ($ox + $p[0]) $p[1] $clear }
    [void](TextPx $b $t3 ($ox + 98 + [int][math]::Floor((60 - $w3t - 1) / 2)) 41 11 $white $true)
  }
  Save $b 'kushiyaki_sign.png'
}

# ---- のぼり旗 16x78（左の棒の足元が原点）。橙の布に白い縦書き「串焼き」と串
if (Want 'nobori') {
  $b = NewBmp 16 78
  Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 76 $w2; Rect $b 0 2 1 76 $w3
  Rect $b 2 4 13 66 $or; Rect $b 2 4 1 66 $or2; Rect $b 14 4 1 66 $or0
  Rect $b 2 4 13 1 $or3
  for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 70 $or; Px $b (2 + $i) 71 $or0 } }
  $chars = '串', '焼', 'き'
  for ($i = 0; $i -lt 3; $i++) { [void](TextPx $b $chars[$i] 3 (6 + 12 * $i) 11 $white $false) }
  # 串の絵（縦。肉は焼き鳥・牛・焼き鳥）
  $sk = NewBmp 7 26
  VSkew $sk 3 0 22 'n'
  $sk2 = OutlineBmp $sk $ch0
  Blit $b $sk2 5 43
  $sk2.Dispose()
  Save $b 'kushiyaki_nobori.png'
}

# ---- 赤提灯 14x24 の3コマ（明かりがゆれる）。赤い紙に白い「串」
if (Want 'lantern') {
  $b = NewBmp 42 24
  $reds = @((C '#d8342b'), (C '#e8452f'), (C '#e03b2c'))
  for ($f = 0; $f -lt 3; $f++) {
    $ox = $f * 14
    Rect $b ($ox + 6) 0 1 4 $ol
    Rect $b ($ox + 3) 4 8 2 $ch0
    Ellipse $b ($ox + 7) 12.5 6.5 7 $reds[$f]
    Rect $b ($ox + 2) 9 10 1 $redL2; Rect $b ($ox + 1) 12 12 1 $redL2; Rect $b ($ox + 2) 15 10 1 $redL2
    Rect $b ($ox + 1) 8 1 8 $redL2; Rect $b ($ox + 12) 8 1 8 $redL2
    Rect $b ($ox + 3) 18 8 2 $ch0
    Rect $b ($ox + 6) 20 2 4 $gold
    [void](TextPx $b '串' ($ox + 2) 7 11 $white $false)
  }
  Save $b 'kushiyaki_lantern.png'
}

# ---- 縞の日よけ 156x26（橙と炭色の縞に、まるいスカラップのへり）。足元が下のへり
if (Want 'roof') {
  $RW = 156
  $b = NewBmp $RW 26
  for ($y = 0; $y -lt 9; $y++) {
    $inset = 9 - $y
    for ($x = $inset; $x -lt $RW - $inset; $x++) {
      $s = [int][math]::Floor($x / 12) % 2
      if ($s -eq 0) { $col = $or } else { $col = $ch1 }
      if ($y -eq 0) { if ($s -eq 0) { $col = $or2 } else { $col = $ch3 } }
      Px $b $x $y $col
    }
  }
  for ($x = 0; $x -lt $RW; $x++) { Px $b $x 9 $cream2 }
  for ($s = 0; $s -lt 13; $s++) {
    $x0 = $s * 12
    for ($i = 0; $i -lt 12; $i++) {
      $bot = 22 + [int][math]::Round(3 * [math]::Sin([math]::PI * ($i + 0.5) / 12))
      for ($y = 10; $y -le $bot; $y++) {
        if (($s % 2) -eq 0) { $col = $or; $hi = $or2; $lo = $or0 } else { $col = $ch1; $hi = $ch2; $lo = $ch0 }
        $c3 = $col
        if ($i -eq 0) { $c3 = $hi } elseif ($i -eq 11) { $c3 = $lo }
        if ($y -eq $bot) { $c3 = $ch0 }
        if ($y -eq 10) { $c3 = $lo }
        Px $b ($x0 + $i) $y $c3
      }
    }
  }
  Save $b 'kushiyaki_roof.png'
}

# ---- カウンター 144x24。木の天板と、炭色の前掛けに橙のひし形
if (Want 'counter') {
  $b = NewBmp 144 24
  Rect $b 0 0 144 24 $ol
  Rect $b 1 1 142 8 $w1; Rect $b 1 1 142 1 $cream; Rect $b 1 8 142 1 $w2
  for ($x = 18; $x -lt 142; $x += 18) { Rect $b $x 1 1 7 $w2 }
  Rect $b 1 9 142 14 $w3
  Rect $b 3 10 138 12 $ch1
  Rect $b 3 10 138 1 $ch3
  Rect $b 3 11 138 2 $or
  Rect $b 3 11 138 1 $or2
  Rect $b 3 21 138 1 $ch0
  $dm = @('..o..', '.opo.', 'opppo', '.opo.', '..o..')
  for ($x = 11; $x -lt 136; $x += 14) { Ascii $b $x 14 $dm @{ o = $or; p = $or2 } }
  Rect $b 0 23 144 1 $ol
  foreach ($p in @(@(0, 0), @(143, 0))) { Px $b $p[0] $p[1] $clear }
  Save $b 'kushiyaki_counter.png'
}

# ---- 柱 6x48（足元が原点）。上に炭色の布をまく
if (Want 'post') {
  $b = NewBmp 6 48
  Rect $b 0 0 6 48 $ol; Rect $b 1 0 4 47 $w2; Rect $b 1 0 1 47 $w1; Rect $b 4 0 1 47 $w3
  Rect $b 1 12 4 5 $ch1; Rect $b 1 12 4 1 $ch3; Rect $b 1 14 4 1 $or; Rect $b 1 16 4 1 $ch0
  Save $b 'kushiyaki_post.png'
}

# ---- 炭火の焼き台 60x34 の4コマ（炭がちらちら赤く光り、炎と火の粉がゆれる）。串が9本並ぶ
if (Want 'grill') {
  $GW = 60
  $b = NewBmp ($GW * 4) 34
  $types = 'c', 'b', 'n', 'c', 'b', 'n', 'c', 'b', 'n'
  $ashA = C '#2a2220'; $ashB = C '#3a3230'; $bedDark = C '#1a1412'
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * $GW
    # 炭を入れる箱（奥のふち・炭・手前のふち）
    Rect $b $ox 5 60 15 $mt0
    Rect $b ($ox + 1) 5 58 1 $mt2
    Rect $b ($ox + 1) 6 58 1 $mt1
    Rect $b ($ox + 2) 7 56 11 $bedDark
    Rect $b ($ox + 1) 18 58 2 $mt1; Rect $b ($ox + 1) 18 58 1 $mt2
    for ($y = 7; $y -le 17; $y++) {
      for ($x = 2; $x -le 57; $x++) {
        if ((Hs $x $y 0) -gt 0.5) {
          $g = Hs $x $y ($f * 3 + 1)
          if ($g -gt 0.78) { $cc = $e3 } elseif ($g -gt 0.5) { $cc = $e2 } elseif ($g -gt 0.2) { $cc = $e1 } else { $cc = $e0 }
        } else {
          if ((Hs $x $y 9) -gt 0.7) { $cc = $ashB } else { $cc = $ashA }
        }
        Px $b ($ox + $x) $y $cc
      }
    }
    # 前の本体（炭色の箱に、赤く光る風穴）
    Rect $b $ox 20 60 14 $ch0
    Rect $b ($ox + 1) 21 58 12 $ch1
    Rect $b ($ox + 1) 21 58 1 $ch2
    Rect $b ($ox + 1) 21 2 12 $ch2
    Rect $b ($ox + 57) 21 2 12 $ch0
    Rect $b ($ox + 1) 30 58 1 $ch0
    for ($j = 0; $j -lt 4; $j++) {
      $vx = $ox + 7 + 14 * $j
      $g = Hs $j 4 $f
      if ($g -gt 0.66) { $vc = $e3 } elseif ($g -gt 0.33) { $vc = $e2 } else { $vc = $e1 }
      Rect $b ($vx - 1) 24 10 5 $ch0
      Rect $b $vx 25 8 3 $vc
      if ($g -gt 0.5) { Rect $b $vx 25 8 1 $e3 }
    }
    # 炎（串と串のすき間から）
    for ($i = 0; $i -lt 8; $i++) {
      $xg = $ox + 8 + 6 * $i
      if ((Hs $i 7 $f) -gt 0.45) {
        $h = 3 + [int][math]::Floor((Hs $i 8 $f) * 4)
        for ($k = 0; $k -lt $h; $k++) {
          $y = 8 - $k
          if ($k -lt 2) { $cc = $e2 } elseif ($k -lt $h - 1) { $cc = $e3 } else { $cc = (C '#ffe9a0') }
          if ($k -eq $h - 1) { Px $b ($xg + ($i % 2)) $y $cc } else { Px $b $xg $y $cc; Px $b ($xg + 1) $y $cc }
        }
      }
    }
    # 串（肉3切れ。手前のふちに持つ所が出る）
    for ($i = 0; $i -lt 9; $i++) {
      $xs = $ox + 4 + 6 * $i
      Line $b ($xs + 1) 6 ($xs + 1) 21 $stick
      for ($j = 0; $j -lt 3; $j++) { $p = ChunkPal $types[$i] $j; Chunk $b $xs (7 + 3 * $j) 4 3 $p }
      Px $b ($xs + 1) 21 $stick2
    }
    # 火の粉
    for ($k = 0; $k -lt 4; $k++) {
      $sx = $ox + 2 + [int][math]::Floor((Hs $k 11 $f) * 56)
      $sy = [int][math]::Floor((Hs $k 12 $f) * 5)
      Px $b $sx $sy (C '#ffc45a')
    }
  }
  Save $b 'kushiyaki_grill.png'
}

# ---- 煙・湯気（6コマのアニメ）24x34 を横に並べる。炭火の煙と揚げ鍋の湯気に使う
if (Want 'smoke') {
  $FW = 24
  $b = NewBmp ($FW * 6) 34
  for ($f = 0; $f -lt 6; $f++) {
    for ($k = 0; $k -lt 3; $k++) {
      $phase = (($f * 4) + ($k * 8)) % 24
      $t = $phase / 24.0
      $y = 31 - $phase * 1.2
      $x = 12 + [math]::Sin($t * 6.28 * 1.4 + $k * 2.1) * 5 + ($k - 1) * 3
      $r = 2 + $t * 3.6
      $a = [int](215 * (1 - $t))
      Ellipse $b ($f * $FW + $x) $y $r ($r * 0.85) ([System.Drawing.Color]::FromArgb($a, 214, 208, 200))
      Ellipse $b ($f * $FW + $x - $r * 0.25) ($y - $r * 0.25) ($r * 0.5) ($r * 0.4) ([System.Drawing.Color]::FromArgb([int]($a * 0.9), 240, 236, 228))
    }
  }
  Save $b 'kushiyaki_smoke.png'
}

# ---- たこ唐揚げの揚げ鍋 30x32 の4コマ（かごが上下し、油の泡がはじけ、下の火がゆれる）
if (Want 'fryer') {
  $PW = 30
  $b = NewBmp ($PW * 4) 32
  for ($f = 0; $f -lt 4; $f++) {
    $ox = $f * $PW
    $lift = @(0, 1, 2, 1)[$f]
    # 下の火
    Rect $b ($ox + 6) 30 18 2 $ch0
    for ($k = 0; $k -lt 5; $k++) {
      $h = 1 + [int][math]::Floor((Hs $k 21 $f) * 3)
      Rect $b ($ox + 8 + 3 * $k) (30 - $h) 2 $h $e2
      Px $b ($ox + 8 + 3 * $k) (30 - $h) $e3
    }
    # 鍋の胴
    Ellipse $b ($ox + 15) 23 13 4 $iron1
    Rect $b ($ox + 2) 12 26 11 $iron1
    Rect $b ($ox + 4) 12 2 11 $iron3
    Rect $b ($ox + 6) 12 1 11 $iron2
    Rect $b ($ox + 24) 12 4 11 $iron0
    Rect $b ($ox + 2) 17 26 1 $iron0
    Ellipse $b ($ox + 15) 25 12 2.5 $iron0
    Rect $b $ox 13 3 3 $iron0; Rect $b ($ox + 27) 13 3 3 $iron0
    # ふちと油
    Ellipse $b ($ox + 15) 12 13.5 5 $iron3
    Ellipse $b ($ox + 15) 12.5 12 4.2 $iron0
    Ellipse $b ($ox + 15) 12.5 11 3.6 (C '#c47a1a')
    Ellipse $b ($ox + 11) 11.7 4 1.6 (C '#e0a43a')
    # 揚がっているたこ唐揚げ
    $bob = @(0, 1, 0, 1)[$f]
    Kara $b ($ox + 13) (10 + $bob) 1
    Kara $b ($ox + 18) (12 - $bob) 3
    Kara $b ($ox + 8) (12 + $bob) 2
    # 泡
    for ($k = 0; $k -lt 6; $k++) {
      $bx = $ox + 6 + [int][math]::Floor((Hs $k 31 $f) * 19)
      $by = 9 + [int][math]::Floor((Hs $k 32 $f) * 6)
      Px $b $bx $by (C '#ffe9a8')
      if ((Hs $k 33 $f) -gt 0.6) { Px $b ($bx + 1) $by (C '#fff6d0') }
    }
    # 揚げかごと長い柄
    Frame $b ($ox + 5) (9 - $lift) 8 5 $st1
    Rect $b ($ox + 6) (10 - $lift) 6 3 (C '#a4acbb')
    Line $b ($ox + 12) (9 - $lift) ($ox + 25) (3 - $lift) $st2
    Line $b ($ox + 12) (10 - $lift) ($ox + 25) (4 - $lift) $iron2
    Rect $b ($ox + 24) (1 - $lift) 4 2 $w3
    Px $b ($ox + 24) (1 - $lift) $w2
  }
  Save $b 'kushiyaki_fryer.png'
}

# ---- バット 26x14（ステンレスのバットに、紙を敷いたたこ唐揚げの山）
if (Want 'bat') {
  $b = NewBmp 26 14
  Rect $b 0 5 26 3 $cream2; Rect $b 1 5 24 1 $cream3
  $v = 0
  foreach ($x in 3, 7, 11, 15, 19) { Kara $b $x 3 $v; $v++ }
  foreach ($x in 5, 9, 13, 17) { Kara $b $x 0 $v; $v++ }
  Rect $b 0 7 26 1 $st2
  Rect $b 1 8 24 5 $st1
  Rect $b 1 8 24 1 $st2
  Rect $b 1 12 24 1 $st0
  Rect $b 2 13 22 1 $iron1
  Px $b 0 8 $st0; Px $b 25 8 $st0
  $b2 = OutlineBmp $b $ol
  Save $b2 'kushiyaki_bat.png'
}

# ---- 紙の容器（唐揚げが入った2つ） 24x14 → ふちつきで 26x16
if (Want 'cups') {
  $b = NewBmp 24 14
  foreach ($cx in 0, 13) {
    Kara $b ($cx + 1) 4 ($cx + 1); Kara $b ($cx + 5) 3 ($cx + 2); Kara $b ($cx + 3) 1 ($cx + 4)
    for ($y = 6; $y -le 13; $y++) {
      $ins = [int][math]::Floor(($y - 6) * 0.4)
      for ($x = $ins; $x -le 10 - $ins; $x++) {
        $col = $kraft
        if ($y -eq 6) { $col = $kraft2 }
        elseif ($y -ge 8 -and $y -le 9) { if (($x % 2) -eq 0) { $col = $redL } else { $col = $cream2 } }
        elseif ($x -eq $ins) { $col = (C '#e6c48c') }
        elseif ($x -eq 10 - $ins) { $col = $kraft2 }
        Px $b ($cx + $x) $y $col
      }
    }
  }
  Line $b 9 0 11 4 $stick
  Px $b 9 0 $redL
  $b2 = OutlineBmp $b $ol
  Save $b2 'kushiyaki_cups.png'
}

# ---- 串の皿（木の皿に焼き鳥・牛串・ねぎまが横たわる） 28x14
if (Want 'plate') {
  $b = NewBmp 28 14
  Rect $b 0 9 28 5 $ol; Rect $b 1 9 26 3 $w2; Rect $b 1 9 26 1 $w1; Rect $b 1 12 26 1 $w3
  HSkew $b 1 2 26 4 'c'
  HSkew $b 1 5 26 4 'b'
  HSkew $b 1 8 26 4 'n'
  Save $b 'kushiyaki_plate.png'
}

# ---- 串立て 16x26（焼けた串が立つ壺。足元が原点）
if (Want 'kushitate') {
  $b = NewBmp 16 26
  $xs = 2, 6, 10, 14; $tops = 3, 0, 4, 1; $ty = 'c', 'b', 'n', 'c'
  for ($i = 0; $i -lt 4; $i++) { VSkew $b $xs[$i] $tops[$i] 17 $ty[$i] }
  Rect $b 0 14 16 12 $ol
  Rect $b 1 15 14 10 (C '#7a5238')
  Rect $b 1 15 14 1 (C '#a07650')
  Rect $b 1 18 14 2 $cream2
  Rect $b 1 20 14 1 $or
  Rect $b 1 24 14 1 (C '#4a3020')
  Rect $b 2 15 1 9 (C '#9a7048')
  Px $b 0 25 $clear; Px $b 15 25 $clear
  Save $b 'kushiyaki_kushitate.png'
}

# ---- 品書き（炭色の黒板）80x48。足元が原点。絵と品名だけで値段は書かない
if (Want 'menu') {
  $b = NewBmp 80 48
  Rect $b 0 0 80 42 $ol; Rect $b 1 1 78 40 $w2; Rect $b 3 3 74 36 $ch0
  Rect $b 3 3 74 1 $ch2
  Rect $b 8 42 3 6 $w3; Rect $b 69 42 3 6 $w3; Rect $b 8 42 1 6 $w2; Rect $b 69 42 1 6 $w2
  # 絵は明るい丸皿の上に（黒板の上で見えやすいように）
  foreach ($ry in 4, 16, 28) { Rect $b 4 $ry 14 9 $cream2; Rect $b 4 ($ry + 8) 14 1 $cream3; foreach ($p in @(@(4, $ry), @(17, $ry), @(4, ($ry + 8)), @(17, ($ry + 8)))) { Px $b $p[0] $p[1] $ch0 } }
  # 牛串
  HSkew $b 4 8 13 3 'b'
  [void](TextPx $b '牛串' 19 3 12 $or3 $true)
  # 焼き鳥
  HSkew $b 4 20 13 3 'c'
  [void](TextPx $b '焼き鳥' 19 15 12 $white $true)
  # たこ唐揚げ
  Kara $b 6 30 0; Kara $b 11 31 1
  [void](TextPx $b 'たこ唐揚げ' 19 27 11 $white $true)
  Save $b 'kushiyaki_menu.png'
}

# ---- 牛のマスコット（台つき）20x26
if (Want 'mascot') {
  $b = NewBmp 20 26
  $o = Cow
  Blit $b $o 1 3
  $o.Dispose()
  Rect $b 1 18 18 8 $ol; Rect $b 2 19 16 6 $w2; Rect $b 2 19 16 1 $w1; Rect $b 2 24 16 1 $w3
  Rect $b 4 21 12 3 $ch1; Rect $b 4 21 12 1 $ch3; Rect $b 4 23 12 1 $or
  Save $b 'kushiyaki_mascot.png'
}

# ---- 炭の箱とうちわ 30x20 → ふちつきで 32x22
if (Want 'sumi') {
  $b = NewBmp 30 20
  Rect $b 0 8 22 12 $w3; Rect $b 0 8 22 1 $w1; Rect $b 1 12 20 1 $ol; Rect $b 1 16 20 1 $ol
  Rect $b 1 9 1 10 $w2; Rect $b 20 9 1 10 $w3
  Ellipse $b 11 6 10 4 $ch1
  foreach ($p in @(@(3, 5), @(7, 3), @(12, 4), @(16, 6), @(5, 7), @(10, 7), @(14, 3), @(18, 5))) {
    Rect $b $p[0] $p[1] 3 2 $ch0; Px $b $p[0] $p[1] $ch3
  }
  Px $b 9 6 $e1; Px $b 15 5 $e2; Px $b 4 8 $e1
  Ellipse $b 25 6 4.6 4.6 $cream2
  Rect $b 21 5 9 1 $or; Rect $b 22 8 7 1 $or
  Rect $b 25 10 1 9 $stick2
  $b2 = OutlineBmp $b $ol
  Save $b2 'kushiyaki_sumi.png'
}

# ---- 床のマット 60x22（炭色に橙のふち、ひし形が並ぶ）
if (Want 'mat') {
  $b = NewBmp 60 22
  Rect $b 0 0 60 22 $ch0; Rect $b 2 2 56 18 $or; Rect $b 4 4 52 14 $ch1
  for ($y = 4; $y -lt 18; $y++) { for ($x = 4; $x -lt 56; $x++) { if ((($x + $y) % 8) -eq 0 -and ($y % 2) -eq 0) { Px $b $x $y $ch2 } } }
  $dm = @('..o..', '.opo.', 'opppo', '.opo.', '..o..')
  for ($i = 0; $i -lt 4; $i++) { Ascii $b (9 + $i * 12) 8 $dm @{ o = $or; p = $or3 } }
  foreach ($p in @(@(0, 0), @(59, 0), @(0, 21), @(59, 21))) { Px $b $p[0] $p[1] $clear }
  Save $b 'kushiyaki_mat.png'
}
