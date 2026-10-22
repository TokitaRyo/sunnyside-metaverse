# キラキラドリンク屋の専用ドット絵を作る（ネオン看板(点滅・きらり)・のぼり・パステルの屋根・豆電球・氷のショーケース(グラデーションが流れる)・作業台・シロップ・シェイカー・ストロー立て・ドリンク・ラメの粒子など）。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/kirakira.ps1   （リポジトリのルートで実行）
#   一部だけ作り直す: $env:KIRA_ONLY='sign|case'; powershell ...（ファイル名の正規表現）
# 出力: client/public/brand/stall/kirakira_*.png （配置は scripts/stalls/kirakira.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル。日本語の文字は MS Gothic を1bitでドットにして貼る。
# アニメは「フレームを横一列に並べたPNG」で、kirakira.mjs の k.custom(name, ox, oy, {frames, fps}) で再生する。
. "$PSScriptRoot\..\lib\pixel.ps1"

# 確認用: KIRA_ONLY（正規表現）に合う絵だけ作り直す
function Want($n) { return ((-not $env:KIRA_ONLY) -or ($n -match $env:KIRA_ONLY)) }

function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function CC($c, $a) { [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) {
  if ($t -lt 0) { $t = 0 }
  if ($t -gt 1) { $t = 1 }
  [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t))
}
# 色のならび($stops)をなめらかにつないで、0..1 の位置($t)の色を返す（1を超えたらぐるっと一周）
function Grad($stops, $t) {
  $t = $t - [math]::Floor($t)
  $n = $stops.Count - 1
  $p = $t * $n
  $i = [int][math]::Floor($p)
  if ($i -ge $n) { $i = $n - 1 }
  return (Mix $stops[$i] $stops[$i + 1] ($p - $i))
}

# いま描いているフレームの範囲（PxO がこの外には描かない）
$script:CX0 = 0; $script:CX1 = 100000
# 半透明を重ねて描く（下に何かあれば混ぜる）
function PxO($b, $x, $y, $col) {
  $x = [int]$x; $y = [int]$y
  if ($x -lt $script:CX0 -or $x -gt $script:CX1 -or $y -lt 0 -or $x -ge $b.Width -or $y -ge $b.Height) { return }
  if ($col.A -le 0) { return }
  if ($col.A -ge 255) { $b.SetPixel($x, $y, $col); return }
  $e = $b.GetPixel($x, $y)
  if ($e.A -eq 0) { $b.SetPixel($x, $y, $col); return }
  $a = $col.A / 255.0; $ea = $e.A / 255.0; $oa = $a + $ea * (1 - $a)
  $r = [int](($col.R * $a + $e.R * $ea * (1 - $a)) / $oa)
  $g = [int](($col.G * $a + $e.G * $ea * (1 - $a)) / $oa)
  $bl = [int](($col.B * $a + $e.B * $ea * (1 - $a)) / $oa)
  $b.SetPixel($x, $y, [System.Drawing.Color]::FromArgb([int]($oa * 255), $r, $g, $bl))
}
function EllO($b, $cx, $cy, $rx, $ry, $col) {
  for ($y = [math]::Floor($cy - $ry); $y -le [math]::Ceiling($cy + $ry); $y++) {
    for ($x = [math]::Floor($cx - $rx); $x -le [math]::Ceiling($cx + $rx); $x++) {
      $dx = ($x + 0.5 - $cx) / $rx; $dy = ($y + 0.5 - $cy) / $ry
      if ($dx * $dx + $dy * $dy -le 1) { PxO $b $x $y $col }
    }
  }
}
# ぼんやりした光（3段の半透明を重ねる）
function Halo($b, $cx, $cy, $rx, $ry, $hex, $a) {
  EllO $b $cx $cy $rx $ry (CA $hex $a)
  EllO $b $cx $cy ($rx * 0.72) ($ry * 0.72) (CA $hex $a)
  EllO $b $cx $cy ($rx * 0.45) ($ry * 0.45) (CA $hex $a)
}
# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $sw, $sh, $n, $draw) {
  if (-not (Want $name)) { return }
  $bm = NewBmp ($sw * $n) $sh
  for ($f = 0; $f -lt $n; $f++) { $script:CX0 = $f * $sw; $script:CX1 = $f * $sw + $sw - 1; & $draw $bm ($f * $sw) $f }
  $script:CX0 = 0; $script:CX1 = 100000
  Save $bm $name
}

# ---- 色（ブルー → むらさき → ピンクのグラデーションが主役）
$ol = C '#3b2a73'; $olS = C '#5b4aa6'
$blu = C '#62c4ff'; $bluD = C '#3a8fe0'; $bluL = C '#b4e6ff'
$vio = C '#a98bff'; $vioD = C '#7456d6'; $vioL = C '#dccdff'
$pnk = C '#ff8ad8'; $pnkD = C '#d85cb4'; $pnkL = C '#ffc8ee'
$cyn = C '#7ff3ff'; $mnt = C '#9ff5d0'; $lem = C '#fff3a0'; $lemD = C '#f0c850'
$wht = C '#ffffff'; $cream = C '#fff8f4'; $creamD = C '#efd6ec'
$glass = C '#e8f8ff'; $glassD = C '#9db8ea'
$navy = C '#1d1445'; $navy2 = C '#2d2168'
$tr = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$gradA = @($blu, $vio, $pnk, $cyn, $blu)       # 青→紫→ピンク→水色→青
$gradB = @($pnk, $vio, $blu, $vio, $pnk)       # ピンク→紫→青→紫→ピンク
$gradC = @($cyn, $blu, $vio, $blu, $cyn)       # 水色→青→紫→青→水色
$gradN = @($cyn, $blu, $vio, $pnk, $vio, $blu, $cyn)  # ネオンのへり・LEDが流れる色
$shA = CA '#ffffff' 90; $shB = CA '#ffffff' 45; $shC = CA '#ffffff' 120

$starRows = @('..y..', '.yyy.', 'yyyyy', '.yyy.', '.y.y.')
function Star($b, $x, $y, $col) { Ascii $b $x $y $starRows @{ y = $col } }
function Corners($b, $x, $y, $w, $h) { foreach ($p in @(@($x, $y), @(($x + $w - 1), $y), @($x, ($y + $h - 1)), @(($x + $w - 1), ($y + $h - 1)))) { Px $b $p[0] $p[1] $tr } }

# きらり（十字の光）。$r が大きいほど長い。$a は明るさ
function Spark($b, $cx, $cy, $r, $col, $a) {
  PxO $b $cx $cy (CC $wht $a)
  for ($d = 1; $d -le $r; $d++) {
    $aa = [int]($a * [math]::Max(0.25, 1 - 0.22 * $d))
    $cc = $col; if ($d -le 1) { $cc = $wht }
    PxO $b ($cx + $d) $cy (CC $cc $aa); PxO $b ($cx - $d) $cy (CC $cc $aa)
    PxO $b $cx ($cy + $d) (CC $cc $aa); PxO $b $cx ($cy - $d) (CC $cc $aa)
  }
  if ($r -ge 3) { foreach ($q in @(@(1, 1), @(-1, 1), @(1, -1), @(-1, -1))) { PxO $b ($cx + $q[0]) ($cy + $q[1]) (CC $col ([int]($a * 0.6))) } }
}

# ---- 文字のマスク（点の集合）。1文字ずつ MS Gothic を1bitで描き、太字にして、左上を (0,0) に詰める。キー=(y+10)*1000+(x+10)、値=何文字目か
function TextPts($text, $px, $space) {
  $font = New-Object System.Drawing.Font("MS Gothic", $px, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  $pts = New-Object System.Collections.ArrayList
  $minX = 9999; $minY = 9999; $maxX = -1; $maxY = -1
  for ($ci = 0; $ci -lt $text.Length; $ci++) {
    $tmp = NewBmp ($px * 2) ($px * 2)
    $g = [System.Drawing.Graphics]::FromImage($tmp)
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
    $g.DrawString([string]$text[$ci], $font, [System.Drawing.Brushes]::White, 0, 0, $fmt)
    $g.Dispose()
    for ($j = 0; $j -lt $tmp.Height; $j++) {
      for ($i = 0; $i -lt $tmp.Width; $i++) {
        if ($tmp.GetPixel($i, $j).A -ge 128) {
          $xx = $ci * $space + $i
          [void]$pts.Add(@($xx, $j, $ci)); [void]$pts.Add(@(($xx + 1), $j, $ci))
          if ($xx -lt $minX) { $minX = $xx }
          if ($xx + 1 -gt $maxX) { $maxX = $xx + 1 }
          if ($j -lt $minY) { $minY = $j }
          if ($j -gt $maxY) { $maxY = $j }
        }
      }
    }
    $tmp.Dispose()
  }
  $font.Dispose()
  $set = New-Object 'System.Collections.Generic.Dictionary[int,int]'
  foreach ($p in $pts) { $k = ($p[1] - $minY + 10) * 1000 + ($p[0] - $minX + 10); $set[$k] = $p[2] }
  return @{ set = $set; w = $maxX - $minX + 1; h = $maxY - $minY + 1 }
}
# 点の集合をふくらませる（ひし形なら上下左右、そうでなければ四角）
function DilD($set, $r, $diamond) {
  $o = New-Object 'System.Collections.Generic.Dictionary[int,int]'
  foreach ($kv in $set.GetEnumerator()) {
    for ($dy = -$r; $dy -le $r; $dy++) {
      for ($dx = -$r; $dx -le $r; $dx++) {
        if ($diamond -and ([math]::Abs($dx) + [math]::Abs($dy)) -gt $r) { continue }
        $k = $kv.Key + $dy * 1000 + $dx
        if (-not $o.ContainsKey($k)) { $o[$k] = $kv.Value }
      }
    }
  }
  return @{ d = $o }
}

# ---- 透明なカップ（中身は上から下へグラデーション。$ph で色が流れる）
#   左上 ($x,$y)、口のはば $w、高さ $h（$y が口。ホイップは口より上へ3pxもりあがる）。$whipH はホイップの行数。
#   $strawCol が $null でなければストロー、$big なら星の飾り棒も付く。$tw はキラキラの点滅の位相
function Cup($b, $x, $y, $w, $h, $ph, $tw, $stops, $whipH, $strawCol, $big) {
  $liqTop = $y + $whipH; $liqH = $h - $whipH
  for ($j = 0; $j -lt $h; $j++) {
    $ins = 0
    if ($j -ge $h - 3) { $ins = 1 }
    if ($j -ge $h - 1) { $ins = 2 }
    $xl = $x + $ins; $xr = $x + $w - 1 - $ins
    Px $b ($xl - 1) ($y + $j) $olS; Px $b ($xr + 1) ($y + $j) $olS
    for ($i = $xl; $i -le $xr; $i++) {
      if ($j -lt $whipH) { $col = $cream }
      else {
        $t = ($j - $whipH) / [double]([math]::Max(1, $liqH - 1))
        $col = Grad $stops ($t * 0.85 + $ph)
      }
      if ($i -eq $xl) { $col = Mix $col $glass 0.5 } elseif ($i -eq $xr) { $col = Mix $col $glassD 0.35 }
      if ($j -eq $h - 1) { $col = Mix $col $glassD 0.5 }
      Px $b $i ($y + $j) $col
    }
  }
  for ($i = $x + 2; $i -le $x + $w - 3; $i++) { Px $b $i ($y + $h) $olS }
  # ゼリーとラメの粒
  $nb = 3; if ($big) { $nb = 6 }
  $bcs = @($lem, $wht, $pnkL, $cyn, $mnt, $wht)
  for ($kk = 0; $kk -lt $nb; $kk++) {
    $bx = $x + 2 + (($kk * 3 + $kk * $kk) % ([math]::Max(1, $w - 5)))
    $by = $liqTop + 1 + (($kk * 5 + 1) % ([math]::Max(1, $liqH - 3)))
    $bc = $bcs[$kk]
    if ((($tw + $kk) % 3) -eq 0) { $bc = $wht }
    Px $b $bx $by $bc
    if ($big) { Px $b ($bx + 1) $by $bc; Px $b $bx ($by + 1) (Mix $bc $vio 0.4) }
  }
  # ガラスのつや
  for ($j = $whipH + 1; $j -lt $h - 2; $j++) { PxO $b ($x + 2) ($y + $j) $shC }
  # ホイップ（口からもりあがる）
  $cx = $x + $w / 2.0
  Ellipse $b $cx ($y + 0.6) ($w / 2.0 - 0.3) 3.3 $creamD
  Ellipse $b $cx ($y + 0.2) ($w / 2.0 - 0.9) 2.7 $cream
  Px $b ([int][math]::Floor($cx) + 1) ($y - 1) $creamD
  $tc = $lem; if (($tw % 2) -eq 1) { $tc = $pnkL }
  Px $b ([int][math]::Floor($cx)) ($y - 3) $tc; Px $b ([int][math]::Floor($cx)) ($y - 2) $tc
  # ストロー
  if ($null -ne $strawCol) {
    $sx0 = $x + $w - 4; $ytop = $y - 7; $ybot = $liqTop + 3
    for ($yy = $ytop; $yy -le $ybot; $yy++) {
      $sx = $sx0 + [int][math]::Floor(($ybot - $yy) / 6.0)
      $sc2 = $strawCol; if ((([int][math]::Floor($yy / 2)) % 2) -eq 0) { $sc2 = $wht }
      Px $b $sx $yy $sc2; Px $b ($sx + 1) $yy (Mix $sc2 $vioD 0.25)
    }
  }
  # 星の飾り棒
  if ($big) {
    $sx2 = $x + 2
    $pc = $lem; if (($tw % 2) -eq 1) { $pc = $pnkL }
    Ascii $b $sx2 ($y - 9) $starRows @{ y = $pc }
    for ($yy = $y - 4; $yy -le $y; $yy++) { Px $b ($sx2 + 2) $yy $pnkD }
  }
}

# =====================================================================
# ネオン看板 116x36 × 6コマ。ふちのネオンが流れ、文字がグラデーションで光って、ときどき点滅。きらりが走る
# =====================================================================
$TX = TextPts 'キラキラドリンク' 12 13
$glowSet = (DilD $TX.set 3 $true).d
$ringSet = (DilD $TX.set 1 $true).d
$tx0 = [int][math]::Floor((116 - $TX.w) / 2); $ty0 = [int][math]::Floor((36 - $TX.h) / 2)
$lvl = @(1.0, 1.0, 1.0, 0.3, 1.0, 0.6)
$chHex = @('#7ff3ff', '#66c8ff', '#7aa6ff', '#9a8cff', '#b784ff', '#d37cf5', '#ff7fd8', '#ff9ae0')
$chCol = @(); foreach ($hx in $chHex) { $chCol += , (C $hx) }
$sparkAt = @(@(5, 6, 1), @(5, 6, 3), @(5, 6, 2), @(110, 29, 1), @(110, 29, 3), @(110, 29, 2))
Sheet 'kirakira_sign.png' 116 36 6 {
  param($b, $ox, $f)
  $L = $lvl[$f]
  for ($y = 0; $y -lt 36; $y++) {
    $row = Mix $navy2 $navy ($y / 35.0)
    for ($x = 0; $x -lt 116; $x++) { Px $b ($ox + $x) $y $row }
  }
  Frame $b ($ox + 2) 2 112 32 (C '#0f0a2e')
  # ふちのネオン管（色が流れる）
  for ($y = 0; $y -lt 36; $y++) {
    for ($x = 0; $x -lt 116; $x++) {
      if (($x -lt 2) -or ($x -ge 114) -or ($y -lt 2) -or ($y -ge 34)) {
        $c0 = Grad $gradN (($x + $y) / 150.0 + $f / 6.0)
        if ($x -eq 0 -or $x -eq 115 -or $y -eq 0 -or $y -eq 35) { $c0 = Mix $c0 $navy 0.45 }
        Px $b ($ox + $x) $y $c0
      }
    }
  }
  foreach ($p in @(@(0, 0), @(1, 0), @(0, 1), @(115, 0), @(114, 0), @(115, 1), @(0, 35), @(1, 35), @(0, 34), @(115, 35), @(114, 35), @(115, 34))) { Px $b ($ox + $p[0]) $p[1] $tr }
  # 文字: 光のにじみ → うすいふち → グラデーションの文字
  foreach ($kv in $glowSet.GetEnumerator()) {
    $px0 = ($kv.Key % 1000) - 10; $py0 = [int][math]::Floor($kv.Key / 1000) - 10
    $cc0 = $chCol[$kv.Value]
    PxO $b ($ox + $tx0 + $px0) ($ty0 + $py0) (CC $cc0 ([int](30 * $L)))
  }
  foreach ($kv in $ringSet.GetEnumerator()) {
    $px0 = ($kv.Key % 1000) - 10; $py0 = [int][math]::Floor($kv.Key / 1000) - 10
    $cc0 = $chCol[$kv.Value]
    Px $b ($ox + $tx0 + $px0) ($ty0 + $py0) (Mix $navy (Mix $cc0 $navy 0.55) $L)
  }
  foreach ($kv in $TX.set.GetEnumerator()) {
    $px0 = ($kv.Key % 1000) - 10; $py0 = [int][math]::Floor($kv.Key / 1000) - 10
    $cc0 = $chCol[$kv.Value]
    $fc = Mix $cc0 $wht (0.5 * (1 - $py0 / [double]$TX.h))
    Px $b ($ox + $tx0 + $px0) ($ty0 + $py0) (Mix $navy $fc $L)
  }
  $sp = $sparkAt[$f]
  Spark $b ($ox + $sp[0]) $sp[1] $sp[2] $cyn 255
  Spark $b ($ox + 108 - $sp[0] + 5) (36 - $sp[1]) 1 $pnkL ([int](120 + 100 * $L))
}

# =====================================================================
# 屋根のひさし 156x24。ピンク・白・水色・ラベンダーのしまに、まるいふち。ラメつき
# =====================================================================
if (Want 'kirakira_roof') {
  $RW = 156; $b = NewBmp $RW 24
  $sc = @($pnkL, $cream, $bluL, $vioL)
  $scD = @($pnk, $glassD, $blu, $vio)
  for ($y = 0; $y -lt 10; $y++) {
    $inset = [int](9 - $y)
    for ($x = $inset; $x -lt $RW - $inset; $x++) { Px $b $x $y $sc[([int][math]::Floor($x / 13)) % 4] }
  }
  for ($x = 0; $x -lt $RW; $x++) { Px $b $x 8 $scD[([int][math]::Floor($x / 13)) % 4]; Px $b $x 9 $ol; Px $b $x 10 $vioD }
  for ($i = 0; $i -lt 12; $i++) {
    $col = $sc[$i % 4]; $cd = $scD[$i % 4]
    for ($dy = 0; $dy -lt 12; $dy++) {
      for ($x = 0; $x -lt 13; $x++) {
        $ddx = ($x + 0.5 - 6.5) / 6.5; $ddy = $dy / 11.0
        if ($ddx * $ddx + $ddy * $ddy -le 1.0) {
          $ddy2 = ($dy + 1) / 11.0
          $edge = ($ddx * $ddx + $ddy2 * $ddy2) -gt 1.0
          if ($edge -or $dy -eq 11) { Px $b ($i * 13 + $x) (11 + $dy) $ol } else { Px $b ($i * 13 + $x) (11 + $dy) $col }
        }
      }
    }
    Px $b ($i * 13 + 3) 13 $wht; Px $b ($i * 13 + 3) 14 $wht
    Px $b ($i * 13 + 9) 17 $cd; Px $b ($i * 13 + 8) 18 $cd
  }
  Rect $b 0 11 $RW 1 $ol
  # ラメ
  $rnd = New-Object System.Random 11
  $gc = @($wht, $cyn, $lem, $pnk)
  for ($k = 0; $k -lt 46; $k++) {
    $x = $rnd.Next(10, 146); $y = $rnd.Next(1, 8)
    if ($x -ge (9 - $y) -and $x -lt $RW - (9 - $y)) { Px $b $x $y $gc[$k % 4] }
  }
  Star $b 36 2 $lem; Star $b 114 2 $pnkL
  Save $b 'kirakira_roof.png'
}

# =====================================================================
# 柱 6x52（足元が原点）。キャンディのようなしま
# =====================================================================
if (Want 'kirakira_post') {
  $b = NewBmp 6 52
  Rect $b 0 0 6 52 $ol
  for ($y = 0; $y -lt 51; $y++) { for ($x = 1; $x -le 4; $x++) { $s = [math]::Floor(($y + $x * 2) / 4) % 2; Px $b $x $y $(if ($s -eq 0) { $pnkL } else { $bluL }) } }
  Rect $b 1 0 4 2 $vio; Px $b 1 0 $wht
  Save $b 'kirakira_post.png'
}

# =====================================================================
# のぼり旗 16x82（左の棒の足元が原点）。青→紫→ピンクのグラデーション布に「キラキラ」
# =====================================================================
function Nobori($name, $stops) {
  if (-not (Want $name)) { return }
  $b = NewBmp 16 82
  Rect $b 0 2 16 2 $vioD; Rect $b 0 2 2 80 $vio; Rect $b 0 2 1 80 $vioD
  for ($y = 4; $y -lt 76; $y++) {
    $cl = Grad $stops (($y - 4) / 72.0)
    for ($x = 2; $x -lt 15; $x++) {
      $c2 = $cl
      if ($x -eq 2) { $c2 = Mix $cl $wht 0.35 } elseif ($x -eq 14) { $c2 = Mix $cl $ol 0.3 }
      Px $b $x $y $c2
    }
  }
  for ($x = 3; $x -lt 14; $x += 2) { Px $b $x 5 (Mix (Grad $stops 0.0) $wht 0.5) }
  $edgeC = Grad $stops 0.985
  Rect $b 2 76 13 1 (Mix $edgeC $ol 0.3)
  foreach ($bx in @(4, 8, 12)) { Ellipse $b $bx 76.5 2.6 2.6 $edgeC; Px $b ($bx + 1) 78 (Mix $edgeC $ol 0.3) }
  Rect $b 2 75 13 1 $edgeC
  $chars = 'キ', 'ラ', 'キ', 'ラ'
  for ($i = 0; $i -lt 4; $i++) {
    foreach ($o in @(@(1, 0), @(0, 1), @(1, 1), @(-1, 0), @(0, -1))) { [void](TextPx $b $chars[$i] (3 + $o[0]) (9 + 15 * $i + $o[1]) 12 $ol $true) }
    [void](TextPx $b $chars[$i] 3 (9 + 15 * $i) 12 $wht $true)
  }
  Star $b 5 68 $lem
  Save $b $name
}
Nobori 'kirakira_nobori_blue.png' @($blu, $vio, $pnk)
Nobori 'kirakira_nobori_pink.png' @($pnk, $vio, $blu)

# =====================================================================
# 奥の壁 150x30（足元が原点）。うすいラベンダー→ピンクのグラデーション、棚とミニボトル、星
# =====================================================================
if (Want 'kirakira_back') {
  $b = NewBmp 150 30
  for ($y = 0; $y -lt 30; $y++) {
    $row = Mix (C '#efe4ff') (C '#ffe2f3') ($y / 29.0)
    for ($x = 0; $x -lt 150; $x++) { Px $b $x $y $row }
  }
  for ($x = 0; $x -lt 150; $x += 10) { for ($y = 0; $y -lt 12; $y++) { Px $b $x $y (C '#f8f0ff') } }
  Rect $b 0 12 150 2 $vio; Rect $b 0 12 150 1 $vioL
  $stopsList = @($gradA, $gradB, $gradC)
  $bi = 0
  for ($x = 6; $x -lt 142; $x += 11) {
    $stp = $stopsList[$bi % 3]; $bi++
    Px $b ($x + 1) 3 $pnkD; Px $b ($x + 2) 3 $pnkD; Px $b ($x + 1) 4 $vioL
    for ($yy = 0; $yy -lt 6; $yy++) {
      $gc2 = Grad $stp ($yy / 6.0 + ($bi * 0.13))
      Px $b $x (5 + $yy) $olS; Px $b ($x + 1) (5 + $yy) (Mix $gc2 $wht 0.45); Px $b ($x + 2) (5 + $yy) $gc2; Px $b ($x + 3) (5 + $yy) $gc2; Px $b ($x + 4) (5 + $yy) $olS
    }
  }
  Rect $b 0 24 150 6 $pnkL; Rect $b 0 24 150 1 $vio; Rect $b 0 29 150 1 $vioD
  for ($x = 4; $x -lt 150; $x += 14) { Px $b $x 26 $wht; Px $b ($x + 1) 27 $vio }
  Star $b 20 17 $lem; Star $b 75 15 $wht; Star $b 128 17 $lem
  Save $b 'kirakira_back.png'
}

# =====================================================================
# 豆電球のガーランド 156x10 × 4コマ（色がくるくる切りかわって光る）
# =====================================================================
$bulbCols = @($pnk, $cyn, $lem, $vio)
Sheet 'kirakira_garland.png' 156 10 4 {
  param($b, $ox, $f)
  $ys = @()
  for ($x = 0; $x -lt 156; $x++) {
    $yw = 1 + [int][math]::Floor(3.5 * [math]::Sin([math]::PI * ($x % 52) / 52.0))
    Px $b ($ox + $x) $yw $olS
  }
  for ($i = 0; $i -lt 12; $i++) {
    $bx = 6 + 13 * $i
    $yw = 1 + [int][math]::Floor(3.5 * [math]::Sin([math]::PI * ($bx % 52) / 52.0))
    $bc = $bulbCols[($i + $f) % 4]
    $on = (($i + $f) % 2) -eq 0
    if (-not $on) { $bc = Mix $bc $navy 0.45 } else { EllO $b ($ox + $bx) ($yw + 3) 3.2 3.2 (CC $bc 50) }
    Px $b ($ox + $bx) ($yw + 1) $olS
    Px $b ($ox + $bx - 1) ($yw + 2) $bc; Px $b ($ox + $bx) ($yw + 2) $bc; Px $b ($ox + $bx + 1) ($yw + 2) $bc
    Px $b ($ox + $bx - 1) ($yw + 3) $bc; Px $b ($ox + $bx) ($yw + 3) $bc; Px $b ($ox + $bx + 1) ($yw + 3) $bc
    Px $b ($ox + $bx) ($yw + 4) $bc
    if ($on) { Px $b ($ox + $bx - 1) ($yw + 2) $wht }
  }
}

# =====================================================================
# 氷のショーケース 56x64 × 8コマ（足元が原点）。ふちのLEDと中のドリンクのグラデーションが流れ、ガラスのつやが走り、キラキラが舞い上がる
# =====================================================================
$bgT = C '#34307e'; $bgB = C '#5a52b0'
$cupX = @(5, 17, 29, 41)
$stopsSel = @($gradA, $gradB, $gradC)
$iceC = C '#eaf8ff'; $iceD = C '#a9d4f5'
$icSp = @(@(9, 52), @(24, 53), @(40, 52), @(46, 54))
$upX = @(6, 15, 24, 33, 42, 50)
Sheet 'kirakira_case.png' 56 64 8 {
  param($b, $ox, $f)
  Rect $b $ox 8 56 56 $ol
  for ($y = 16; $y -lt 56; $y++) {
    $row = Mix $bgT $bgB (($y - 16) / 40.0)
    for ($x = 3; $x -lt 53; $x++) { Px $b ($ox + $x) $y $row }
  }
  Rect $b ($ox + 1) 16 2 40 $glassD; Rect $b ($ox + 53) 16 2 40 $glassD; Rect $b ($ox + 1) 16 1 40 $glass
  # 上のLED帯（グラデーションが流れる）
  for ($x = 0; $x -lt 56; $x++) {
    $gc3 = Grad $gradN ($x / 56.0 + $f / 8.0)
    Px $b ($ox + $x) 8 $ol; Px $b ($ox + $x) 9 (Mix $gc3 $wht 0.45)
    Px $b ($ox + $x) 10 $gc3; Px $b ($ox + $x) 11 $gc3; Px $b ($ox + $x) 12 $gc3
    Px $b ($ox + $x) 13 (Mix $gc3 $navy 0.25); Px $b ($ox + $x) 14 $ol; Px $b ($ox + $x) 15 $vioD
  }
  Px $b $ox 8 $tr; Px $b ($ox + 55) 8 $tr
  # 棚
  Rect $b ($ox + 3) 33 50 2 $glassD; Rect $b ($ox + 3) 33 50 1 $glass
  # ドリンク（2段×4つ）
  for ($r = 0; $r -lt 2; $r++) {
    $cy1 = 20; if ($r -eq 1) { $cy1 = 37 }
    for ($c = 0; $c -lt 4; $c++) {
      $st = $stopsSel[($r * 4 + $c) % 3]
      $ph = $f / 8.0 + $c * 0.19 + $r * 0.37
      Cup $b ($ox + $cupX[$c]) $cy1 9 13 $ph ($f + $c + $r) $st 3 $null $false
    }
  }
  # 氷
  Rect $b ($ox + 3) 50 50 6 $iceC; Rect $b ($ox + 3) 50 50 1 $wht
  for ($x = 4; $x -lt 48; $x += 7) {
    $cyy = 51 + (($x / 7) % 2)
    Rect $b ($ox + $x) $cyy 6 4 $iceC; Frame $b ($ox + $x) $cyy 6 4 $iceD; Px $b ($ox + $x + 1) ($cyy + 1) $wht
  }
  $ip = $icSp[$f % 4]
  Spark $b ($ox + $ip[0]) $ip[1] 2 $cyn 255
  # ガラスを走るつや
  for ($y = 16; $y -lt 50; $y++) {
    $sx = (($f * 9) % 72) - 16 + [int][math]::Floor((50 - $y) * 0.55)
    for ($d = 0; $d -lt 3; $d++) {
      $xx = $sx + $d
      if ($xx -ge 3 -and $xx -le 52) { if ($d -eq 1) { PxO $b ($ox + $xx) $y $shA } else { PxO $b ($ox + $xx) $y $shB } }
    }
  }
  # 手前の台
  Rect $b $ox 56 56 8 $ol; Rect $b ($ox + 1) 57 54 6 $vioL; Rect $b ($ox + 1) 57 54 1 $wht; Rect $b ($ox + 1) 62 54 1 $vioD
  for ($x = 8; $x -lt 48; $x += 4) { Rect $b ($ox + $x) 59 2 3 $vio }
  Px $b $ox 63 $tr; Px $b ($ox + 55) 63 $tr
  # 舞い上がるキラキラ
  for ($k = 0; $k -lt 6; $k++) {
    $u = ($f + $k * 3) % 8
    $al = [int](255 * [math]::Sin([math]::PI * ($u + 0.5) / 8.0))
    $py = 15 - [int]($u * 1.9)
    $pxx = $upX[$k] + [int][math]::Round([math]::Sin($u * 0.8 + $k) * 2)
    $cc4 = $cyn; if ($k % 3 -eq 1) { $cc4 = $pnkL } elseif ($k % 3 -eq 2) { $cc4 = $lem }
    if ($al -gt 200) { Spark $b ($ox + $pxx) $py 1 $cc4 $al } else { PxO $b ($ox + $pxx) $py (CC $cc4 $al) }
  }
}

# =====================================================================
# 作業台 78x26 × 4コマ。白い天板、LEDのラインが流れる前板、星
# =====================================================================
Sheet 'kirakira_bench.png' 78 26 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 78 26 $ol
  Rect $b ($ox + 1) 1 76 9 $cream; Rect $b ($ox + 1) 1 76 1 $wht; Rect $b ($ox + 1) 9 76 1 $vioL
  foreach ($p in @(@(6, 4), @(19, 6), @(33, 3), @(47, 6), @(60, 4), @(70, 7))) { Px $b ($ox + $p[0]) $p[1] $pnkL; Px $b ($ox + $p[0] + 1) ($p[1]) $bluL }
  Rect $b ($ox + 1) 10 76 15 $vioL; Rect $b ($ox + 1) 10 76 1 $vio
  for ($x = 2; $x -lt 76; $x++) {
    $gc3 = Grad $gradN ($x / 78.0 + $f / 4.0)
    Px $b ($ox + $x) 12 (Mix $gc3 $wht 0.5); Px $b ($ox + $x) 13 $gc3; Px $b ($ox + $x) 14 (Mix $gc3 $navy 0.3)
  }
  $i = 0
  for ($x = 6; $x -lt 70; $x += 12) { Star $b ($ox + $x) 16 $(if ($i % 3 -eq 0) { $lem } elseif ($i % 3 -eq 1) { $pnkL } else { $cyn }); $i++ }
  Rect $b ($ox + 1) 22 76 3 $vio; Rect $b ($ox + 1) 22 76 1 $vioD
  Corners $b $ox 0 78 26
}

# =====================================================================
# シロップのボトル3本 30x20 × 4コマ（中のグラデーションと、つやがきらり）
# =====================================================================
function Bottle($b, $x, $y, $stops, $capCol, $f, $labelCol) {
  Rect $b ($x + 2) $y 4 3 $ol; Rect $b ($x + 3) $y 2 2 $capCol; Px $b ($x + 3) $y (Mix $capCol $wht 0.5)
  Rect $b ($x + 2) ($y + 3) 4 2 $olS; Px $b ($x + 3) ($y + 3) $glass; Px $b ($x + 4) ($y + 3) $glass
  for ($j = 0; $j -lt 13; $j++) {
    for ($i = 0; $i -lt 8; $i++) {
      if (($j -eq 0 -or $j -eq 12) -and ($i -eq 0 -or $i -eq 7)) { continue }
      $edge = ($i -eq 0) -or ($i -eq 7) -or ($j -eq 12) -or ($j -eq 0)
      if ($edge) { $col = $ol }
      else {
        $col = Grad $stops ($j / 13.0 * 0.7 + 0.05)
        if ($i -eq 1) { $col = Mix $col $wht 0.5 } elseif ($i -eq 6) { $col = Mix $col $ol 0.25 }
        if ($j -ge 4 -and $j -le 7) { $col = $wht; if ($i -eq 6) { $col = $glassD } }
      }
      Px $b ($x + $i) ($y + 5 + $j) $col
    }
  }
  Px $b ($x + 3) ($y + 10) $labelCol; Px $b ($x + 4) ($y + 10) $labelCol; Px $b ($x + 3) ($y + 11) $labelCol; Px $b ($x + 4) ($y + 9) $labelCol; Px $b ($x + 3) ($y + 9) $labelCol
  $gy = $y + 6 + (($f * 3 + $x) % 9)
  Px $b ($x + 2) $gy $wht
}
Sheet 'kirakira_syrups.png' 30 20 4 {
  param($b, $ox, $f)
  Bottle $b ($ox + 0) 1 @($blu, $vio, $pnk) $pnk $f $bluD
  Bottle $b ($ox + 11) 1 @($pnk, $vio, $blu) $blu $f $pnkD
  Bottle $b ($ox + 22) 1 @($cyn, $blu, $vio) $vio $f $vioD
}

# =====================================================================
# シェイカー2つ 22x20（足元が原点）
# =====================================================================
if (Want 'kirakira_shaker') {
  $b = NewBmp 22 20
  $silv = C '#e9eefc'; $silv2 = C '#b7c2e4'; $silv3 = C '#8794c0'
  # 大きいシェイカー（ピンクの帯）
  Rect $b 3 0 5 3 $ol; Rect $b 4 0 3 2 $vioD; Px $b 4 0 $vio
  for ($j = 3; $j -lt 19; $j++) {
    $hw = 4; if ($j -ge 16) { $hw = 4 }
    for ($i = 0; $i -lt 10; $i++) {
      if (($j -eq 3 -or $j -eq 18) -and ($i -eq 0 -or $i -eq 9)) { continue }
      $edge = ($i -eq 0) -or ($i -eq 9) -or ($j -eq 18) -or ($j -eq 3)
      if ($edge) { $col = $ol } else { $col = $silv; if ($i -eq 1) { $col = $wht } elseif ($i -ge 7) { $col = $silv2 }; if ($j -ge 9 -and $j -le 11) { $col = $pnk; if ($i -eq 1) { $col = $pnkL } elseif ($i -ge 7) { $col = $pnkD } } }
      Px $b (1 + $i) $j $col
    }
  }
  Star $b 3 12 $lem
  # 小さいシェイカー（むらさき）
  Rect $b 14 4 4 3 $ol; Rect $b 15 4 2 2 $pnk; Px $b 15 4 $pnkL
  for ($j = 7; $j -lt 19; $j++) {
    for ($i = 0; $i -lt 8; $i++) {
      if (($j -eq 7 -or $j -eq 18) -and ($i -eq 0 -or $i -eq 7)) { continue }
      $edge = ($i -eq 0) -or ($i -eq 7) -or ($j -eq 18) -or ($j -eq 7)
      if ($edge) { $col = $ol } else { $col = $vio; if ($i -eq 1) { $col = $vioL } elseif ($i -ge 5) { $col = $vioD }; if ($j -ge 12 -and $j -le 13) { $col = $silv; if ($i -ge 5) { $col = $silv2 } } }
      Px $b (12 + $i) $j $col
    }
  }
  Px $b 14 15 $wht; Px $b 15 16 $wht
  Save $b 'kirakira_shaker.png'
}

# =====================================================================
# ストロー立て 12x20（足元が原点）。ストライプのストローがさしてある
# =====================================================================
function StrawLine($b, $x0, $y0, $x1, $y1, $c1) {
  $n = [math]::Max([math]::Abs($x1 - $x0), [math]::Abs($y1 - $y0))
  for ($s = 0; $s -le $n; $s++) {
    $x = [int][math]::Round($x0 + ($x1 - $x0) * $s / $n); $y = [int][math]::Round($y0 + ($y1 - $y0) * $s / $n)
    $cc5 = $c1; if ((([int][math]::Floor($s / 2)) % 2) -eq 0) { $cc5 = $wht }
    Px $b $x $y $cc5; Px $b ($x + 1) $y (Mix $cc5 $vioD 0.25)
  }
}
if (Want 'kirakira_straws') {
  $b = NewBmp 12 20
  StrawLine $b 3 12 0 1 $pnk
  StrawLine $b 4 12 4 0 $blu
  StrawLine $b 6 12 8 1 $vio
  StrawLine $b 7 12 10 3 $mnt
  Rect $b 1 11 10 9 $ol; Rect $b 2 12 8 7 $vioL; Rect $b 2 12 1 7 $wht; Rect $b 8 12 2 7 $vio
  Rect $b 2 14 8 1 $pnk; Rect $b 2 17 8 1 $vioD
  Star $b 4 14 $lem
  Px $b 1 19 $tr; Px $b 10 19 $tr
  Save $b 'kirakira_straws.png'
}

# =====================================================================
# ドリンク（大）16x30 × 6コマ（足元が原点）。グラデーションが流れる。3色
# =====================================================================
function CupSheet($name, $stops, $off, $strawCol) {
  Sheet $name 16 30 6 {
    param($b, $ox, $f)
    Cup $b ($ox + 2) 10 12 19 ($f / 6.0 + $off) ($f + [int]($off * 10)) $stops 3 $strawCol $true
  }
}
CupSheet 'kirakira_cup_a.png' $gradA 0.0 $pnk
CupSheet 'kirakira_cup_b.png' $gradB 0.3 $blu
CupSheet 'kirakira_cup_c.png' $gradC 0.6 $vio

# ドリンク（持つ用の小さいもの）11x20 × 6コマ
function CupSmall($name, $stops, $off, $strawCol) {
  Sheet $name 11 20 6 {
    param($b, $ox, $f)
    Cup $b ($ox + 1) 7 9 12 ($f / 6.0 + $off) ($f + [int]($off * 10)) $stops 3 $strawCol $false
  }
}
CupSmall 'kirakira_cup_s_a.png' $gradA 0.1 $pnk
CupSmall 'kirakira_cup_s_b.png' $gradB 0.5 $blu

# =====================================================================
# メニューのかわりの立て看板 54x48（足元が原点）。文字は「ドリンク」だけ。ドリンクの絵で伝える
# =====================================================================
if (Want 'kirakira_board') {
  $b = NewBmp 54 48
  Rect $b 0 0 54 42 $ol; Rect $b 1 1 52 40 $vioL; Rect $b 3 3 48 36 $navy
  for ($x = 1; $x -lt 53; $x++) { $gc3 = Grad $gradN ($x / 52.0); Px $b $x 1 $gc3; Px $b $x 40 $gc3 }
  for ($y = 1; $y -lt 41; $y++) { $gc3 = Grad $gradN ($y / 40.0); Px $b 1 $y $gc3; Px $b 52 $y $gc3 }
  Rect $b 8 42 3 6 $vioD; Rect $b 43 42 3 6 $vioD; Rect $b 8 42 1 6 $vio; Rect $b 43 42 1 6 $vio
  $tw0 = TextWidth 'ドリンク' 11
  $tx1 = [math]::Floor((54 - $tw0) / 2)
  [void](TextPx $b 'ドリンク' ($tx1 + 1) 6 11 $pnkD $true)
  [void](TextPx $b 'ドリンク' $tx1 5 11 $pnkL $true)
  Cup $b 20 25 14 13 0.1 0 $gradA 3 $pnk $true
  Star $b 7 24 $lem; Star $b 42 22 $pnkL; Star $b 9 31 $cyn; Star $b 41 30 $lem
  Corners $b 0 0 54 42
  Save $b 'kirakira_board.png'
}

# =====================================================================
# 立ち飲みテーブル 22x28（足元が原点）。パステルのまるい天板
# =====================================================================
if (Want 'kirakira_table') {
  $b = NewBmp 22 28
  Ellipse $b 11 6 10.8 5.2 $ol
  Ellipse $b 11 6 9.8 4.2 $vioL
  Ellipse $b 11 5.6 8.6 3.2 $pnkL
  Ellipse $b 11 5.2 5 1.6 $wht
  Px $b 5 5 $wht; Px $b 16 6 $lem; Px $b 8 7 $cyn; Px $b 14 4 $cyn
  Rect $b 9 10 4 14 $ol; Rect $b 10 10 2 14 $vio; Px $b 10 11 $vioL; Px $b 10 12 $vioL
  Ellipse $b 11 25 7.2 3 $ol
  Ellipse $b 11 24.6 6.2 2.1 $vioL
  Ellipse $b 11 24.2 3.4 1 $wht
  Save $b 'kirakira_table.png'
}

# =====================================================================
# 床 192x128。パステルのタイルと光だまり、まん中のグラデーションの通路
# =====================================================================
if (Want 'kirakira_floor') {
  $fl = NewBmp 192 128
  $fA = CA '#ffd9f0' 118; $fB = CA '#d9d2ff' 118; $fE = CA '#b9a2ff' 170; $fE2 = CA '#d8c8ff' 170
  for ($y = 44; $y -lt 124; $y++) {
    for ($x = 4; $x -lt 188; $x++) {
      $chk = ((([int][math]::Floor($x / 8)) + ([int][math]::Floor($y / 8))) % 2) -eq 0
      $col = $fB; if ($chk) { $col = $fA }
      if ($x -lt 7 -or $x -ge 185 -or $y -ge 121 -or $y -lt 47) { $col = $fE; if ((($x + $y) % 2) -eq 0) { $col = $fE2 } }
      Px $fl $x $y $col
    }
  }
  # ふちの豆電球
  for ($x = 8; $x -lt 184; $x += 8) { Px $fl $x 122 (CA '#ff8ad8' 255); Px $fl ($x + 4) 122 (CA '#7ff3ff' 255) }
  for ($y = 52; $y -lt 120; $y += 8) { Px $fl 5 $y (CA '#7ff3ff' 255); Px $fl 186 ($y + 4) (CA '#ff8ad8' 255) }
  # まん中の通路（グラデーションの光るカーペット）
  for ($y = 70; $y -lt 123; $y++) {
    $gc3 = Grad $gradN (($y - 70) / 53.0)
    for ($x = 84; $x -lt 108; $x++) {
      $cl2 = CC (Mix $gc3 $wht 0.45) 190
      if ($x -eq 84 -or $x -eq 107) { $cl2 = CA '#ffffff' 235 }
      Px $fl $x $y $cl2
    }
  }
  $rnd = New-Object System.Random 3
  for ($i = 0; $i -lt 26; $i++) { Px $fl $rnd.Next(86, 106) $rnd.Next(72, 121) (CA '#ffffff' 255) }
  # 光だまり
  Halo $fl 52 82 38 11 '#7fe8ff' 24
  Halo $fl 129 84 42 11 '#b79cff' 22
  Halo $fl 168 118 15 6 '#ff8ad8' 24
  Halo $fl 96 100 14 18 '#ffffff' 14
  Save $fl 'kirakira_floor.png'
}

# =====================================================================
# ラメの粒子 192x128 × 8コマ（草地全体に重ねる）。ゆらゆら漂ってまたたく
# =====================================================================
$gl = @()
$rg = New-Object System.Random 5
for ($k = 0; $k -lt 44; $k++) { $gl += , @($rg.Next(4, 188), $rg.Next(4, 124), $rg.Next(0, 8), $rg.Next(0, 5)) }
$glc = @($wht, $cyn, $pnkL, $lem, $vioL)
Sheet 'kirakira_glitter.png' 192 128 8 {
  param($b, $ox, $f)
  for ($k = 0; $k -lt $gl.Count; $k++) {
    $p = $gl[$k]
    $u = ($f + $p[2]) % 8
    $a = 2 * [math]::PI * $u / 8.0
    $gx = $ox + $p[0] + [int][math]::Round(2.5 * [math]::Sin($a + $k))
    $gy = $p[1] + [int][math]::Round(2.5 * [math]::Cos($a + $k * 0.7))
    $lv = ($f + $p[2]) % 4
    $gcol = $glc[$p[3]]
    if ($lv -eq 0) { Spark $b $gx $gy 2 $gcol 255 }
    elseif ($lv -eq 1) { Spark $b $gx $gy 1 $gcol 220 }
    elseif ($lv -eq 2) { PxO $b $gx $gy (CC $gcol 200) }
    else { PxO $b $gx $gy (CC $gcol 90) }
  }
}

# =====================================================================
# 星のきらめき 9x9 × 4コマ
# =====================================================================
$sz = @(0, 2, 4, 2)
Sheet 'kirakira_spark.png' 9 9 4 {
  param($b, $ox, $f)
  $r = $sz[$f]
  Px $b ($ox + 4) 4 $wht
  for ($d = 1; $d -le $r; $d++) {
    foreach ($q in @(@($d, 0), @(-$d, 0), @(0, $d), @(0, -$d))) { Px $b ($ox + 4 + $q[0]) (4 + $q[1]) $(if ($d -le 1) { $wht } else { $cyn }) }
  }
  if ($r -ge 3) { foreach ($q in @(@(1, 1), @(-1, 1), @(1, -1), @(-1, -1))) { Px $b ($ox + 4 + $q[0]) (4 + $q[1]) $pnkL } }
}
