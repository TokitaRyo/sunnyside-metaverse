# フランクフルト屋（串に刺した太いソーセージ）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/frankfurt.ps1   （リポジトリのルートで）
# 出力: client/public/brand/stall/frankfurt_*.png（原点は各スプライトの足元。配置は scripts/stalls/frankfurt.mjs）
# 一部だけ作り直す: $env:FRANKFURT_ONLY='sign|grill'  （名前の正規表現）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（青 x 白の屋台。主役は、こんがり焼けたソーセージと、ケチャップ・マスタードの赤と黄）
$bl0 = C '#10285e'; $bl1 = C '#2a62c4'; $bl2 = C '#4e8cec'; $bl3 = C '#a6c8ff'
$wh0 = C '#a9b8d2'; $wh1 = C '#e6edf8'; $wh2 = C '#ffffff'
$sa0 = C '#7a2216'; $sa1 = C '#b8402a'; $sa2 = C '#dc6a48'; $sa3 = C '#f7a07c'
$brn1 = C '#8a3a1c'; $brn2 = C '#5c2210'; $brn3 = C '#3c140a'
$ketch = C '#d3261f'; $ketchHi = C '#ff6a52'; $ketchDk = C '#8a1612'
$mus = C '#f2c418'; $musHi = C '#fff0a0'; $musDk = C '#b8860b'
$stick1 = C '#d9b780'; $stick2 = C '#a07a44'
$st0 = C '#6b7587'; $st1 = C '#a9b3c4'; $st2 = C '#dbe3ee'; $st3 = C '#f4f8fc'
$glow1 = C '#ffb43a'; $glow2 = C '#ffe08a'; $glow3 = C '#ff8a2a'
$back = C '#3a2a2e'; $backGlow = C '#6a3a26'
$coal = C '#2a1814'; $ember1 = C '#ff7a2a'; $ember2 = C '#ffb347'; $ember3 = C '#a8321a'
$paper = C '#f6f0dc'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# ---- 小さな道具
function Want($n) { if (-not $env:FRANKFURT_ONLY) { return $true }; return ($n -match $env:FRANKFURT_ONLY) }
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
# いま描いてある色に白（など）を薄く重ねる（ガラスの照り返し用）
function BlendPx($b, $x, $y, $r, $g, $bb, $a) {
  if ($x -lt 0 -or $y -lt 0 -or $x -ge $b.Width -or $y -ge $b.Height) { return }
  $p = $b.GetPixel([int]$x, [int]$y)
  if ($p.A -eq 0) { return }
  $nr = [int]($p.R * (1 - $a) + $r * $a); $ng = [int]($p.G * (1 - $a) + $g * $a); $nb = [int]($p.B * (1 - $a) + $bb * $a)
  $b.SetPixel([int]$x, [int]$y, [System.Drawing.Color]::FromArgb(255, $nr, $ng, $nb))
}

# ---- 横向きのソーセージ（ふち無し）。$phase でらせん状の焼き色の帯がずれる（ローラーで回って見える）
function SausageBmp($len, $th, $phase, $browned) {
  $s = NewBmp $len $th
  for ($j = 0; $j -lt $th; $j++) {
    for ($i = 0; $i -lt $len; $i++) {
      if (($i -eq 0 -or $i -eq $len - 1) -and ($j -eq 0 -or $j -eq $th - 1)) { continue }
      if ($j -eq 0) { $col = $sa2 } elseif ($j -eq 1) { $col = $sa3 } elseif ($j -eq $th - 1) { $col = $sa0 } else { $col = $sa1 }
      if ($browned -and ((($i + $j * 2 + $phase) % 6) -lt 2)) {
        if ($j -le 1) { $col = $brn1 } elseif ($j -eq $th - 1) { $col = $brn3 } else { $col = $brn2 }
      }
      if ($i -eq 0 -or $i -eq $len - 1) { if ($j -ge 1) { $col = $sa0 } }
      $s.SetPixel($i, $j, $col)
    }
  }
  return $s
}
# 縦向きのソーセージ（ふち無し）。上下が丸い
function VSausage($w, $h) {
  $s = NewBmp $w $h
  for ($j = 0; $j -lt $h; $j++) {
    $ins = 0
    if ($j -eq 0 -or $j -eq $h - 1) { $ins = 2 } elseif ($j -eq 1 -or $j -eq $h - 2) { $ins = 1 }
    for ($i = $ins; $i -lt $w - $ins; $i++) {
      $col = $sa1
      if ($i -le 0) { $col = $sa2 } elseif ($i -eq 1 -and $j -ge 2 -and $j -le $h - 4) { $col = $sa3 } elseif ($i -ge $w - 1) { $col = $sa0 }
      $s.SetPixel($i, $j, $col)
    }
  }
  return $s
}
# 紙のトレイ（舟形の皿。青と白のしましま）。x,y は左上、w は上のはば
function PaperTray($b, $x, $y, $w, $h) {
  for ($r = 0; $r -lt $h; $r++) {
    $t = $r / [math]::Max(1, ($h - 1)); $ins = [int][math]::Round($t * 2)
    for ($xx = $ins; $xx -lt $w - $ins; $xx++) {
      $col = if ((([math]::Floor($xx / 2)) % 2) -eq 0) { $wh2 } else { $bl2 }
      if ($r -eq 0) { $col = $wh1 }
      if ($r -eq 0 -or $r -eq $h - 1 -or $xx -eq $ins -or $xx -eq $w - 1 - $ins) { $col = $ol }
      elseif ($r -eq $h - 2) { $col = if ((([math]::Floor($xx / 2)) % 2) -eq 0) { $wh0 } else { $bl1 } }
      Px $b ($x + $xx) ($y + $r) $col
    }
  }
}
# 串に刺したソーセージ（ふち付き、th=5）。$kp / $mp = 0..1 で、ケチャップ・マスタードの線をどこまで引いたか。x,y は左上
function DressedSausage($b, $x, $y, $len, $kp, $mp) {
  Rect $b ($x - 3) ($y + 3) ($len + 8) 1 $stick1
  Px $b ($x - 3) ($y + 3) $stick2; Px $b ($x + $len + 4) ($y + 3) $stick2
  $s = SausageBmp $len 5 0 $false
  $o = OutlineBmp $s $ol
  Blit $b $o $x $y
  $o.Dispose()
  $kn = [int][math]::Floor(($len - 2) * $kp)
  for ($i = 0; $i -lt $kn; $i++) {
    $zy = if ((([math]::Floor($i / 2)) % 2) -eq 0) { 1 } else { 2 }
    Px $b ($x + 2 + $i) ($y + $zy) $(if (($i % 4) -eq 1) { $ketchHi } else { $ketch })
  }
  $mn = [int][math]::Floor(($len - 2) * $mp)
  for ($i = 0; $i -lt $mn; $i++) {
    $zy = if (((([math]::Floor($i / 2)) + 1) % 2) -eq 0) { 2 } else { 3 }
    Px $b ($x + 2 + $i) ($y + $zy) $(if (($i % 4) -eq 2) { $musHi } else { $mus })
  }
}
# ケチャップ／マスタードの容器（ふち付き）。$inv なら口を下にした持ち方
function BottleBmp($body, $hi, $dark, $inv) {
  $s = NewBmp 6 15
  $pal = @{ r = $body; h = $hi; d = $dark; w = $wh2; n = $bl1; k = $bl0 }
  if ($inv) {
    $s.Dispose(); $s = NewBmp 6 10
    Ascii $s 0 0 @(
      '.dddd.',
      'rrrrrd',
      'rhrrrd',
      'rwwwrd',
      'rwwwrd',
      'rhrrrd',
      '.rrrd.',
      '.nnnn.',
      '..nn..',
      '..kk..') $pal
  } else {
    Ascii $s 0 0 @(
      '..kk..',
      '..nn..',
      '.nnnn.',
      '.rrrd.',
      'rhrrrd',
      'rhrrrd',
      'rwwwrd',
      'rwwwrd',
      'rwwwrd',
      'rwwwrd',
      'rhrrrd',
      'rhrrrd',
      'rrrrrd',
      'rrrrrd',
      '.dddd.') $pal
  }
  return (OutlineBmp $s $ol)
}

# =====================================================================
# ---- 看板（屋根の上に掲げる）120x30、4コマ。青い板に白いふち、ふちの電球がチカチカ点滅。大きな「フランクフルト」と、串刺しのソーセージ
if (Want 'sign') {
  $base = NewBmp 120 30
  Rect $base 0 0 120 27 $bl0; Rect $base 1 1 118 25 $bl1; Rect $base 1 1 118 1 $bl2
  Rect $base 0 27 120 3 $bl0; Rect $base 0 27 120 1 $bl1
  Frame $base 2 2 116 23 $wh2
  Frame $base 3 3 114 21 $bl0
  foreach ($p in @(@(0, 0), @(119, 0))) { Clear $base $p[0] $p[1] }
  # 左右: 串に刺したソーセージ（縦）
  foreach ($ix in 6, 107) {
    $v = VSausage 5 11
    Px $v 2 4 $mus; Px $v 1 5 $mus; Px $v 3 5 $mus; Px $v 2 6 $ketch; Px $v 1 7 $ketch; Px $v 3 7 $ketch
    $o = OutlineBmp $v $ol
    Rect $base ($ix + 3) 5 1 16 $stick1
    Blit $base $o ($ix + 1) 6
    $o.Dispose()
  }
  [void](TextShadow $base 'フランクフルト' 17 7 12 $wh2 $bl0 $true)
  $b = NewBmp 480 30
  for ($f = 0; $f -lt 4; $f++) {
    Blit $b $base ($f * 120) 0
    # ふちの電球（交互に光る）
    for ($k = 0; $k -lt 18; $k++) {
      $on = ((($k + $f) % 2) -eq 0)
      $cc = if ($on) { C '#ffe45a' } else { $wh0 }
      Rect $b ($f * 120 + 5 + $k * 6) 2 2 1 $cc
      Rect $b ($f * 120 + 5 + $k * 6) 24 2 1 $cc
      if ($on) { Px $b ($f * 120 + 5 + $k * 6) 3 (C '#ffd23a') }
    }
  }
  $base.Dispose()
  Save $b 'frankfurt_sign.png'
}

# ---- のぼり旗 16x96（左の棒の足元が原点）。白い布に青い縦書き
if (Want 'nobori') {
  $b = NewBmp 16 96
  Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 94 $w2; Rect $b 0 2 1 94 $w3
  Rect $b 2 4 13 88 $wh2; Rect $b 2 4 1 88 $wh1; Rect $b 14 4 1 88 $wh0
  Rect $b 2 4 13 2 $bl1; Rect $b 2 4 13 1 $bl2
  # 下のぎざぎざ
  for ($i = 0; $i -lt 13; $i++) { if ($i % 4 -ge 2) { Rect $b (2 + $i) 88 1 4 $clear } else { Px $b (2 + $i) 91 $wh0 } }
  Rect $b 2 87 13 1 $bl1
  $chars = 'フ', 'ラ', 'ン', 'ク', 'フ', 'ル', 'ト'
  for ($i = 0; $i -lt 7; $i++) { [void](TextPx $b $chars[$i] 3 (8 + 11 * $i) 11 $bl1 $true) }
  Save $b 'frankfurt_nobori.png'
}

# ---- 日よけ屋根 128x21（青と白のしましま、下はくるっとした縁）。足元が下のへり
if (Want 'roof') {
  $RW = 128; $SW = 16
  $b = NewBmp $RW 21
  for ($y = 0; $y -lt 5; $y++) {
    $inset = 5 - $y
    for ($x = $inset; $x -lt $RW - $inset; $x++) {
      $col = $bl1
      if ($y -eq 0) { $col = $bl3 } elseif ($y -eq 4) { $col = $bl0 }
      elseif (($x % 8) -eq 3 -and $y -eq 2) { $col = $bl2 }
      Px $b $x $y $col
    }
  }
  for ($y = 5; $y -lt 21; $y++) {
    for ($x = 0; $x -lt $RW; $x++) {
      $s = [math]::Floor($x / $SW); $lx = $x % $SW
      $isBlue = ($s % 2) -eq 0
      if ($y -ge 16) {
        $dy = $y - 16; $cxs = ($SW - 1) / 2.0; $rr = ($SW / 2.0)
        $dxs = $lx - $cxs
        if (($dxs * $dxs) / ($rr * $rr) + ($dy * $dy) / (5.0 * 5.0) -gt 1.0) { continue }
      }
      if ($isBlue) { $col = $bl1; if ($lx -eq 0) { $col = $bl2 } elseif ($lx -eq $SW - 1) { $col = $bl0 } }
      else { $col = $wh1; if ($lx -eq 0) { $col = $wh2 } elseif ($lx -eq $SW - 1) { $col = $wh0 } }
      if ($y -eq 5) { $col = $bl0 }
      if ($y -eq 6 -and -not $isBlue) { $col = $wh2 }
      Px $b $x $y $col
    }
  }
  for ($x = 0; $x -lt $RW; $x++) {
    $lx = $x % $SW; $cxs = ($SW - 1) / 2.0; $rr = ($SW / 2.0)
    $dxs = $lx - $cxs
    $v = 1.0 - ($dxs * $dxs) / ($rr * $rr)
    if ($v -gt 0) { $ey = 16 + [int][math]::Floor(5.0 * [math]::Sqrt($v)); Px $b $x ([math]::Min(20, $ey)) $bl0 }
  }
  Save $b 'frankfurt_roof.png'
}

# ---- カウンター 112x24。木の天板と、青い前掛けに白い串ソーセージの柄
if (Want 'counter') {
  $CW = 112
  $b = NewBmp $CW 24
  Rect $b 0 0 $CW 24 $ol
  Rect $b 1 1 ($CW - 2) 8 $w1; Rect $b 1 1 ($CW - 2) 1 $cream; Rect $b 1 8 ($CW - 2) 1 $w2
  Rect $b 1 9 ($CW - 2) 14 $w2
  for ($x = 12; $x -lt $CW - 2; $x += 15) { Rect $b $x 9 1 3 $w3 }
  Rect $b 3 11 ($CW - 6) 11 $bl1
  Rect $b 3 11 ($CW - 6) 1 $bl3; Rect $b 3 21 ($CW - 6) 1 $bl3
  Rect $b 3 12 ($CW - 6) 1 $bl0
  for ($x = 8; $x -lt $CW - 20; $x += 17) {
    # 白い串ソーセージの柄
    Rect $b $x 17 13 1 $stick1
    Rect $b ($x + 3) 15 7 4 $wh2; Rect $b ($x + 3) 15 7 1 $wh1; Rect $b ($x + 3) 18 7 1 $wh0
    Px $b ($x + 3) 15 $bl1; Px $b ($x + 9) 15 $bl1; Px $b ($x + 3) 18 $bl1; Px $b ($x + 9) 18 $bl1
  }
  Rect $b 0 23 $CW 1 $ol
  foreach ($p in @(@(0, 0), @(($CW - 1), 0))) { Clear $b $p[0] $p[1] }
  Save $b 'frankfurt_counter.png'
}

# ---- 柱 6x48（足元が原点）。上に青と白のしましま
if (Want 'post') {
  $b = NewBmp 6 48
  Rect $b 0 0 6 48 $ol; Rect $b 1 0 4 47 $w2; Rect $b 1 0 1 47 $w1; Rect $b 4 0 1 47 $w3
  for ($y = 12; $y -lt 20; $y++) { $c = if ((($y - 12) % 4) -lt 2) { $bl1 } else { $wh2 }; Rect $b 1 $y 4 1 $c }
  Save $b 'frankfurt_post.png'
}

# ---- ローラー式ロースター（回るローラーの上で、ソーセージがくるくる回る）6コマ 48x34 を横に並べる
# 焼き色の帯がらせん状に動き、ローラーのすじも流れる。上のランプの光がゆれ、ランプが点滅する
if (Want 'grill') {
  $GW = 48; $GH = 34
  function GrillFrame($b, $ox, $f) {
    # 上のランプ棚
    Rect $b $ox 0 $GW 3 $iron0; Rect $b ($ox + 1) 1 ($GW - 2) 1 $st1
    foreach ($lx in 6, 16, 26, 36) {
      $gc = @($glow3, $glow1, $glow2)[([int][math]::Floor($lx / 10) + $f) % 3]
      Rect $b ($ox + $lx) 2 6 1 $gc
    }
    # 奥の板と、ガラスの枠
    Rect $b ($ox + 2) 3 ($GW - 4) 21 $back; Rect $b ($ox + 2) 3 ($GW - 4) 3 $backGlow; Rect $b ($ox + 2) 6 ($GW - 4) 1 (C '#4e3028')
    Rect $b $ox 3 1 21 $iron0; Rect $b ($ox + 1) 3 1 21 $st1
    Rect $b ($ox + $GW - 2) 3 1 21 $st1; Rect $b ($ox + $GW - 1) 3 1 21 $iron0
    # 3段のローラーとソーセージ
    for ($t = 0; $t -lt 3; $t++) {
      $yt = 3 + $t * 7
      $s = SausageBmp 34 4 (($f + $t * 2) % 6) $true
      $o = OutlineBmp $s $ol
      Blit $b $o ($ox + 6) $yt
      $o.Dispose()
      for ($x = 2; $x -lt $GW - 2; $x++) {
        $ridge = ((($x - $f) % 3) + 3) % 3
        $rc = if ($ridge -eq 0) { $st3 } else { $st1 }
        Px $b ($ox + $x) ($yt + 6) $rc
      }
    }
    # ガラスの照り返し
    for ($y = 4; $y -le 22; $y++) {
      $gx = 9 + [int][math]::Floor(($y - 4) * 0.5)
      BlendPx $b ($ox + $gx) $y 255 255 255 0.20
      BlendPx $b ($ox + $gx + 1) $y 255 255 255 0.20
      BlendPx $b ($ox + $gx + 4) $y 255 255 255 0.10
      BlendPx $b ($ox + 2) $y 255 255 255 0.12
    }
    # 本体の前面
    Rect $b $ox 24 $GW 10 $iron0; Rect $b ($ox + 1) 25 ($GW - 2) 8 $st1
    Rect $b ($ox + 1) 25 ($GW - 2) 1 $st3; Rect $b ($ox + 1) 26 ($GW - 2) 1 $st2; Rect $b ($ox + 1) 32 ($GW - 2) 1 $st0
    # 青い銘板
    Rect $b ($ox + 14) 27 20 4 $bl1; Rect $b ($ox + 14) 27 20 1 $bl3; Rect $b ($ox + 16) 29 16 1 $wh2
    # つまみ・ランプ
    Ellipse $b ($ox + 7) 29 2.4 2.4 $bl2; Px $b ($ox + 6) 28 $bl3; Px $b ($ox + 8) 30 $bl0
    $lamp = if (($f % 2) -eq 0) { C '#5fe36a' } else { C '#3aa845' }
    Rect $b ($ox + 39) 28 2 2 $lamp; Rect $b ($ox + 42) 28 2 2 (C '#ff5a44')
    foreach ($p in @(@(0, 33), @(($GW - 1), 33))) { Clear $b ($ox + $p[0]) $p[1] }
  }
  $b = NewBmp ($GW * 6) $GH
  for ($f = 0; $f -lt 6; $f++) { GrillFrame $b ($f * $GW) $f }
  Save $b 'frankfurt_grill.png'
}

# ---- 網焼きコンロ（串に刺したフランクフルトが網の上に4本並ぶ）3コマ 44x34。炭火がゆらゆら光る
if (Want 'net') {
  $NW = 44; $NH = 34
  function NetFrame($b, $ox, $f) {
    # 網のある面（上から見た炭と網）
    Rect $b $ox 0 $NW 22 $iron0
    Rect $b ($ox + 1) 1 ($NW - 2) 20 $coal
    for ($k = 0; $k -lt 16; $k++) {
      $ex = 2 + (($k * 17 + $f * 5) % 40); $ey = 1 + (($k * 7 + $f * 3) % 19)
      $ec = @($ember1, $ember2, $ember3)[($k + $f) % 3]
      Px $b ($ox + $ex) $ey $ec
    }
    for ($y = 1; $y -lt 21; $y++) { for ($x = 1; $x -lt $NW - 1; $x++) { if (($y % 4) -eq 0 -or ($x % 4) -eq 0) { BlendPx $b ($ox + $x) $y 169 179 196 0.55 } } }
    # 串に刺したソーセージ4本
    for ($r = 0; $r -lt 4; $r++) {
      $yy = $r * 5
      $x1 = 1 + (($r * 3) % 4); $x2 = 36 + (($r * 5) % 7)
      Rect $b ($ox + $x1) ($yy + 3) ($x2 - $x1 + 1) 1 $stick1
      Px $b ($ox + $x2) ($yy + 3) $stick2
      $s = SausageBmp 24 4 ($r * 2) $true
      $o = OutlineBmp $s $ol
      Blit $b $o ($ox + 5 + ($r % 2) * 2) $yy
      $o.Dispose()
    }
    # 脚つきの本体（青いふち）
    Rect $b ($ox + 2) 22 ($NW - 4) 10 $iron0; Rect $b ($ox + 3) 23 ($NW - 6) 8 $iron1
    Rect $b ($ox + 3) 23 ($NW - 6) 3 $bl1; Rect $b ($ox + 3) 23 ($NW - 6) 1 $bl3; Rect $b ($ox + 3) 25 ($NW - 6) 1 $bl0
    for ($k = 0; $k -lt 6; $k++) {
      $vc = @($ember3, $ember1, $ember2)[($k + $f) % 3]
      Rect $b ($ox + 6 + $k * 6) 28 4 2 $vc
    }
    Rect $b ($ox + 4) 32 3 2 $iron0; Rect $b ($ox + 37) 32 3 2 $iron0
  }
  $b = NewBmp ($NW * 3) $NH
  for ($f = 0; $f -lt 3; $f++) { NetFrame $b ($f * $NW) $f }
  Save $b 'frankfurt_net.png'
}

# ---- 湯気（6コマのアニメ）14x22 を横に並べる。ふんわり上って消える
if (Want 'steam') {
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
  Save $b 'frankfurt_steam.png'
}

# ---- ソース係（ケチャップとマスタードの容器。口を下にした容器が動いて、ソーセージにぎざぎざの線を引く）9コマ 36x28
if (Want 'sauce') {
  $SW2 = 36; $SH2 = 28
  $kb = BottleBmp $ketch $ketchHi $ketchDk $false
  $mb = BottleBmp $mus $musHi $musDk $false
  $kinv = BottleBmp $ketch $ketchHi $ketchDk $true
  $minv = BottleBmp $mus $musHi $musDk $true
  # (ケチャップの線, マスタードの線, 動かす容器: 0=なし 1=ケチャップ 2=マスタード)
  $seq = @(@(1.0, 1.0, 0), @(1.0, 1.0, 0), @(0.0, 0.0, 0), @(0.35, 0.0, 1), @(0.7, 0.0, 1), @(1.0, 0.0, 1), @(1.0, 0.35, 2), @(1.0, 0.7, 2), @(1.0, 1.0, 2))
  $b = NewBmp ($SW2 * 9) $SH2
  for ($f = 0; $f -lt 9; $f++) {
    $ox = $f * $SW2
    $kp = $seq[$f][0]; $mp = $seq[$f][1]; $mv = $seq[$f][2]
    Blit $b $kb $ox 11
    Blit $b $mb ($ox + 7) 11
    DressedSausage $b ($ox + 17) 13 15 $kp $mp
    PaperTray $b ($ox + 15) 19 21 9
    if ($mv -ne 0) {
      $prog = if ($mv -eq 1) { $kp } else { $mp }
      $bx = $ox + 17 + 2 + [int][math]::Floor(13 * $prog) - 3
      $src = if ($mv -eq 1) { $kinv } else { $minv }
      Blit $b $src $bx 0
    }
  }
  $kb.Dispose(); $mb.Dispose(); $kinv.Dispose(); $minv.Dispose()
  Save $b 'frankfurt_sauce.png'
}

# ---- 紙のトレイ（積んだ空のトレイと、ソースをかけたソーセージ入り）カウンター用 24x14
if (Want 'trays') {
  $b = NewBmp 24 14
  PaperTray $b 0 9 11 5
  PaperTray $b 0 6 11 5
  PaperTray $b 0 3 11 5
  Rect $b 1 4 9 1 $wh2
  DressedSausage $b 14 0 8 1.0 1.0
  PaperTray $b 13 6 11 7
  Save $b 'frankfurt_trays.png'
}

# ---- メニュー（立て看板）62x46。足元が原点。品書きの中身(種類)は書かない
if (Want 'menu') {
  $b = NewBmp 62 46
  Rect $b 0 0 62 40 $ol; Rect $b 1 1 60 38 $bl1; Rect $b 3 3 56 34 $wh1
  Rect $b 3 3 56 1 $wh2
  Rect $b 6 40 3 6 $w3; Rect $b 53 40 3 6 $w3; Rect $b 6 40 1 6 $w2; Rect $b 53 40 1 6 $w2
  $tw = TextWidth 'メニュー' 11
  [void](TextPx $b 'メニュー' ([math]::Floor((62 - $tw) / 2)) 5 11 $bl0 $true)
  Rect $b 8 18 46 1 $wh0
  DressedSausage $b 19 21 22 1.0 1.0
  PaperTray $b 17 26 28 9
  $kb = BottleBmp $ketch $ketchHi $ketchDk $false
  Blit $b $kb 3 19
  $kb.Dispose()
  $mb = BottleBmp $mus $musHi $musDk $false
  Blit $b $mb 51 19
  $mb.Dispose()
  Save $b 'frankfurt_menu.png'
}

# ---- フランくん（ソーセージのマスコット。台つき）22x32
if (Want 'mascot') {
  $b = NewBmp 22 32
  Rect $b 10 0 2 6 $stick1; Px $b 10 0 $stick2; Px $b 11 0 $stick2
  $v = VSausage 10 17
  # 顔
  Rect $v 2 5 2 2 $iron0; Rect $v 6 5 2 2 $iron0; Px $v 2 5 $white; Px $v 6 5 $white
  Px $v 1 8 (C '#ff9a8a'); Px $v 8 8 (C '#ff9a8a')
  Px $v 3 8 $iron0; Px $v 6 8 $iron0; Px $v 4 9 $iron0; Px $v 5 9 $iron0
  # ソースのぎざぎざ
  for ($x = 1; $x -lt 9; $x++) { Px $v $x (11 + ($x % 2)) $mus; Px $v $x (14 + (($x + 1) % 2)) $ketch }
  $o = OutlineBmp $v $ol
  Blit $b $o 5 4
  $o.Dispose()
  # 台
  Rect $b 2 23 18 9 $ol; Rect $b 3 24 16 7 $bl1; Rect $b 3 24 16 1 $bl3; Rect $b 3 27 16 2 $wh2; Rect $b 3 30 16 1 $bl0
  Save $b 'frankfurt_mascot.png'
}

# ---- 床のマット 60x22（青に白のふち、まんなかに市松）
if (Want 'mat') {
  $b = NewBmp 60 22
  Rect $b 0 0 60 22 $bl0; Rect $b 2 2 56 18 $wh2; Rect $b 4 4 52 14 $bl1
  for ($y = 4; $y -lt 18; $y++) { for ($x = 4; $x -lt 56; $x++) { if ((([math]::Floor(($x - 4) / 4) + [math]::Floor(($y - 4) / 4)) % 2) -eq 0) { Px $b $x $y $bl2 } } }
  for ($i = 0; $i -lt 4; $i++) { Rect $b (10 + $i * 12) 10 5 1 $wh2; Rect $b (12 + $i * 12) 8 1 5 $wh2 }
  foreach ($p in @(@(0, 0), @(59, 0), @(0, 21), @(59, 21))) { Clear $b $p[0] $p[1] }
  Save $b 'frankfurt_mat.png'
}
