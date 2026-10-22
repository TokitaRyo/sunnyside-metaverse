# 数理科学愛好会（スライム作り・布の染色教室・トポロジの展示の3コーナー）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/suuri.ps1   （リポジトリのルートで実行）
#   一部だけ作り直す: $env:SUURI_ONLY='sign|bench|mobius'; powershell ...（ファイル名の正規表現）
# 出力: client/public/brand/stall/suuri_*.png （配置は scripts/stalls/suuri.mjs）
# 配色: 黒板の深い緑・木の枠・パステル（ピンク/ミント/水色/ラベンダー/黄）。研究室というより、文化祭の「数学と科学の工作室」。
# メビウスの輪・トーラス・結び目・クラインの壺は、数式（媒介変数）で形を作ってから、zバッファでドットに落としている。
# アニメは「フレームを横一列に並べたPNG」で、suuri.mjs の k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic / BIZ UDPGothic を1bitでドットにして貼る。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Want($n) { return ((-not $env:SUURI_ONLY) -or ($n -match $env:SUURI_ONLY)) }
function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function CC($c, $a) { [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function Shade($c, $f) { [System.Drawing.Color]::FromArgb(255, [int][math]::Min(255, $c.R * $f), [int][math]::Min(255, $c.G * $f), [int][math]::Min(255, $c.B * $f)) }
function AL($v, $am) { [int][math]::Min(255, [math]::Max(0, $v * $am)) }

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
function RectO($b, $x, $y, $w, $h, $col) { for ($j = 0; $j -lt $h; $j++) { for ($i = 0; $i -lt $w; $i++) { PxO $b ($x + $i) ($y + $j) $col } } }
function EllO($b, $cx, $cy, $rx, $ry, $col) {
  for ($y = [math]::Floor($cy - $ry); $y -le [math]::Ceiling($cy + $ry); $y++) {
    for ($x = [math]::Floor($cx - $rx); $x -le [math]::Ceiling($cx + $rx); $x++) {
      $dx = ($x + 0.5 - $cx) / $rx; $dy = ($y + 0.5 - $cy) / $ry
      if ($dx * $dx + $dy * $dy -le 1) { PxO $b $x $y $col }
    }
  }
}
function Halo($b, $cx, $cy, $rx, $ry, $hex, $a) {
  EllO $b $cx $cy $rx $ry (CA $hex $a)
  EllO $b $cx $cy ($rx * 0.72) ($ry * 0.72) (CA $hex $a)
  EllO $b $cx $cy ($rx * 0.45) ($ry * 0.45) (CA $hex $a)
}
# 整数に丸めて1ドット
function P($b, $x, $y, $col) { Px $b ([int][math]::Round($x)) ([int][math]::Round($y)) $col }
# 整数に丸めた線
function LineR($b, $x0, $y0, $x1, $y1, $col) { Line $b ([int][math]::Round($x0)) ([int][math]::Round($y0)) ([int][math]::Round($x1)) ([int][math]::Round($y1)) $col }

# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  if (-not (Want $name)) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { $script:CX0 = $f * $w; $script:CX1 = $f * $w + $w - 1; & $draw $bm ($f * $w) $f }
  $script:CX0 = 0; $script:CX1 = 100000
  Save $bm $name
}

# ---- 色 ----
$ln = C '#3b2c52'                                   # 縁取り（紫がかった濃い色）
$wd0 = C '#7a4e2d'; $wd1 = C '#a8703f'; $wd2 = C '#d49a5e'; $wd3 = C '#f0c48a'
$cm0 = C '#e6d8b8'; $cm1 = C '#f4ead2'; $cm2 = C '#fffaf0'
$pk0 = C '#d9608f'; $pk1 = C '#ff8fb8'; $pk2 = C '#ffc2d9'; $pk3 = C '#ffe3ee'
$mt0 = C '#3fae93'; $mt1 = C '#7fdcc0'; $mt2 = C '#b8f0de'; $mt3 = C '#e0fbf1'
$sk0 = C '#3a78c8'; $sk1 = C '#6aaef0'; $sk2 = C '#a8d4ff'; $sk3 = C '#dcefff'
$lv0 = C '#6a52c4'; $lv1 = C '#9a84ee'; $lv2 = C '#c8b8ff'; $lv3 = C '#ece4ff'
$yl0 = C '#d9a21a'; $yl1 = C '#ffcf4a'; $yl2 = C '#ffe58a'; $yl3 = C '#fff4c4'
$og0 = C '#d9622a'; $og1 = C '#ff9a4a'
$gb0 = C '#12372f'; $gb1 = C '#1c4f43'; $gb2 = C '#2a6a5a'; $gb3 = C '#3c8672'   # 黒板（緑）
$chalk = C '#f6f4ea'
$ink = C '#2a2447'

# =====================================================================
# 3Dの形をドットにする道具（媒介変数曲面 → zバッファ）
#   $fn は { param($u,$v) @(x, y, z) }（y が上）。$col は { param($u,$v,$d) Color or $null }（$d は光の当たり具合 0..1）
#   戻り値: ARGB の int 配列（0 は透明）。$W x $H のなかで、中心($cx,$cy)・1単位=$sc px で、Y軸まわりに$rotY、X軸まわりに$tilt（ラジアン）回して見る
# =====================================================================
$script:LX = -0.40; $script:LY = 0.58; $script:LZ = 0.70
function NewZ($W, $H) {
  $zb = New-Object 'double[,]' $W, $H
  for ($j = 0; $j -lt $H; $j++) { for ($i = 0; $i -lt $W; $i++) { $zb[$i, $j] = -1e9 } }
  return ,$zb
}
function RenderSurf($cb, $zb, $nu, $nv, $u0, $u1, $v0, $v1, $fn, $rotY, $tilt, $sc, $cx, $cy, $col) {
  $W = $cb.GetLength(0); $H = $cb.GetLength(1)
  $cr = [math]::Cos($rotY); $sr = [math]::Sin($rotY); $ct = [math]::Cos($tilt); $st = [math]::Sin($tilt)
  $du = ($u1 - $u0) / $nu; $dv = ($v1 - $v0) / $nv; $eps = 0.002
  $ll = [math]::Sqrt($script:LX * $script:LX + $script:LY * $script:LY + $script:LZ * $script:LZ)
  for ($i = 0; $i -lt $nu; $i++) {
    $u = $u0 + $i * $du
    for ($j = 0; $j -le $nv; $j++) {
      $v = $v0 + $j * $dv
      $p = & $fn $u $v; $pu = & $fn ($u + $eps) $v; $pv = & $fn $u ($v + $eps)
      $ax = $pu[0] - $p[0]; $ay = $pu[1] - $p[1]; $az = $pu[2] - $p[2]
      $bx = $pv[0] - $p[0]; $by = $pv[1] - $p[1]; $bz = $pv[2] - $p[2]
      $nx = $ay * $bz - $az * $by; $ny = $az * $bx - $ax * $bz; $nz = $ax * $by - $ay * $bx
      $nl = [math]::Sqrt($nx * $nx + $ny * $ny + $nz * $nz)
      if ($nl -lt 1e-12) { continue }
      $nx /= $nl; $ny /= $nl; $nz /= $nl
      # 回転: Y軸 → X軸
      $x1 = $p[0] * $cr + $p[2] * $sr; $z1 = -$p[0] * $sr + $p[2] * $cr; $y2 = $p[1] * $ct - $z1 * $st; $z2 = $p[1] * $st + $z1 * $ct
      $mx1 = $nx * $cr + $nz * $sr; $mz1 = -$nx * $sr + $nz * $cr; $my2 = $ny * $ct - $mz1 * $st; $mz2 = $ny * $st + $mz1 * $ct
      if ($mz2 -lt 0) { $mx1 = -$mx1; $my2 = -$my2; $mz2 = -$mz2 }
      $d = [math]::Max(0.0, ($mx1 * $script:LX + $my2 * $script:LY + $mz2 * $script:LZ) / $ll)
      $ix = [int][math]::Floor($cx + $x1 * $sc); $iy = [int][math]::Floor($cy - $y2 * $sc)
      if ($ix -lt 0 -or $iy -lt 0 -or $ix -ge $W -or $iy -ge $H) { continue }
      if ($z2 -le $zb[$ix, $iy]) { continue }
      $c = & $col $u $v $d
      if ($c -eq $null) { continue }
      $zb[$ix, $iy] = $z2; $cb[$ix, $iy] = $c.ToArgb()
    }
  }
}
# 球を並べて作る太い線（結び目）。$pts は @(x,y,z) の配列、$rad は球の半径(px)、$cols は各点の基本色の配列
function RenderTube($cb, $zb, $pts, $cols, $rotY, $tilt, $sc, $cx, $cy, $rad) {
  $W = $cb.GetLength(0); $H = $cb.GetLength(1)
  $cr = [math]::Cos($rotY); $sr = [math]::Sin($rotY); $ct = [math]::Cos($tilt); $st = [math]::Sin($tilt)
  $ll = [math]::Sqrt($script:LX * $script:LX + $script:LY * $script:LY + $script:LZ * $script:LZ)
  for ($k = 0; $k -lt $pts.Count; $k++) {
    $p = $pts[$k]
    $x1 = $p[0] * $cr + $p[2] * $sr; $z1 = -$p[0] * $sr + $p[2] * $cr; $y2 = $p[1] * $ct - $z1 * $st; $z2 = $p[1] * $st + $z1 * $ct
    $sx = $cx + $x1 * $sc; $sy = $cy - $y2 * $sc
    $r0 = [int][math]::Floor($rad) + 1
    for ($dy = -$r0; $dy -le $r0; $dy++) {
      for ($dx = -$r0; $dx -le $r0; $dx++) {
        $ix = [int][math]::Floor($sx) + $dx; $iy = [int][math]::Floor($sy) + $dy
        $qx = ($ix + 0.5 - $sx) / $rad; $qy = ($iy + 0.5 - $sy) / $rad
        $q2 = $qx * $qx + $qy * $qy
        if ($q2 -gt 1.0) { continue }
        if ($ix -lt 0 -or $iy -lt 0 -or $ix -ge $W -or $iy -ge $H) { continue }
        $qz = [math]::Sqrt(1.0 - $q2)
        $zz = $z2 + $qz * $rad / $sc
        if ($zz -le $zb[$ix, $iy]) { continue }
        $d = [math]::Max(0.0, ($qx * $script:LX + (-$qy) * $script:LY + $qz * $script:LZ) / $ll)
        $base = $cols[$k]
        $c = Shade $base (0.55 + 0.62 * $d)
        if ($d -gt 0.93) { $c = Mix $c (C '#ffffff') 0.45 }
        $zb[$ix, $iy] = $zz; $cb[$ix, $iy] = $c.ToArgb()
      }
    }
  }
}
# 配列を絵に貼る。$outline があれば、まわりを1ドットで縁取る
function Blit($b, $cb, $ox, $oy, $outline) {
  $W = $cb.GetLength(0); $H = $cb.GetLength(1)
  for ($j = 0; $j -lt $H; $j++) {
    for ($i = 0; $i -lt $W; $i++) {
      $val = $cb[$i, $j]
      if ($val -ne 0) { Px $b ($ox + $i) ($oy + $j) ([System.Drawing.Color]::FromArgb($val)) }
    }
  }
  if ($outline -ne $null) {
    for ($j = 0; $j -lt $H; $j++) {
      for ($i = 0; $i -lt $W; $i++) {
        if ($cb[$i, $j] -ne 0) { continue }
        $near = $false
        if ($i -gt 0 -and $cb[($i - 1), $j] -ne 0) { $near = $true }
        elseif ($i -lt $W - 1 -and $cb[($i + 1), $j] -ne 0) { $near = $true }
        elseif ($j -gt 0 -and $cb[$i, ($j - 1)] -ne 0) { $near = $true }
        elseif ($j -lt $H - 1 -and $cb[$i, ($j + 1)] -ne 0) { $near = $true }
        if ($near) { Px $b ($ox + $i) ($oy + $j) $outline }
      }
    }
  }
}

# ---- メビウスの輪: 8コマ、Y軸まわりにゆっくり1回転 20x18 ----
$mobFn = { param($u, $v) $rr = 1.0 + $v * [math]::Cos($u / 2); @(($rr * [math]::Cos($u)), ($v * [math]::Sin($u / 2)), ($rr * [math]::Sin($u))) }
$mobCol = {
  param($u, $v, $d)
  $stripe = ([int][math]::Floor($u / ([math]::PI / 5))) % 2 -eq 0
  if ([math]::Abs($v) -gt 0.31) { $base = if ($stripe) { C '#b83d78' } else { C '#c9568a' } }
  else { $base = if ($stripe) { C '#ff8fb8' } else { C '#fff1f6' } }
  $c = Shade $base (0.62 + 0.55 * $d)
  if ($d -gt 0.9 -and [math]::Abs($v) -lt 0.31) { $c = Mix $c (C '#ffffff') 0.4 }
  return $c
}
Sheet 'suuri_mobius.png' 20 18 8 {
  param($b, $ox, $f)
  $cb = New-Object 'int[,]' 20, 18; $zb = NewZ 20 18
  $a = $f * 2 * [math]::PI / 8 + 0.35
  RenderSurf $cb $zb 240 8 0 (2 * [math]::PI) (-0.40) 0.40 $mobFn $a 0.75 6.4 10 9.0 $mobCol
  Blit $b $cb $ox 0 $ln
}

# ---- トーラス（ドーナツ。ピンクのアイシングとカラースプリンクル）: 4コマ（スプリンクルがまわる）20x16 ----
$torFn = { param($u, $v) $rr = 1.0 + 0.45 * [math]::Cos($v); @(($rr * [math]::Cos($u)), (0.45 * [math]::Sin($v)), ($rr * [math]::Sin($u))) }
$sprk = @((C '#ffffff'), (C '#58c8ff'), (C '#ffe040'), (C '#7be07b'), (C '#ff5c5c'))
$script:TorPhase = 0.0
$torCol = {
  param($u, $v, $d)
  $sv = [math]::Sin($v)
  $wave = 0.12 * [math]::Sin(5 * $u)
  $frost = ($sv -gt (0.05 + $wave))
  if ($frost) { $base = C '#ff8fc0' } else { $base = C '#dda057' }
  $c = Shade $base (0.6 + 0.58 * $d)
  if ($frost) {
    $su = (($u + $script:TorPhase) % (2 * [math]::PI / 11) + 2 * [math]::PI / 11) % (2 * [math]::PI / 11)
    if ($su -lt 0.10 -and $sv -gt 0.55) { $idx = ([int][math]::Floor(($u + $script:TorPhase) / (2 * [math]::PI / 11)) % 5 + 5) % 5; $c = Shade $sprk[$idx] 1.0 }
    elseif ($d -gt 0.88) { $c = Mix $c (C '#ffffff') 0.4 }
  }
  return $c
}
Sheet 'suuri_torus.png' 20 16 4 {
  param($b, $ox, $f)
  $cb = New-Object 'int[,]' 20 , 16; $zb = NewZ 20 16
  $script:TorPhase = $f * (2 * [math]::PI / 11) / 4.0
  RenderSurf $cb $zb 150 22 0 (2 * [math]::PI) 0 (2 * [math]::PI) $torFn 0 0.95 6.6 10 8.4 $torCol
  Blit $b $cb $ox 0 $ln
}

# ---- 結び目（三つ葉結び目）: 8コマ、まわる 20x20 ----
$knotPts = New-Object System.Collections.ArrayList
$knotCols = New-Object System.Collections.ArrayList
for ($i = 0; $i -lt 200; $i++) {
  $t = $i * 2 * [math]::PI / 200
  [void]$knotPts.Add(@(([math]::Sin($t) + 2 * [math]::Sin(2 * $t)), (-([math]::Cos($t) - 2 * [math]::Cos(2 * $t))), (-[math]::Sin(3 * $t))))
  $h = 0.5 + 0.5 * [math]::Sin($t * 3 - 1.0)
  [void]$knotCols.Add((Mix (C '#27c9a8') (C '#6a7cf0') $h))
}
Sheet 'suuri_knot.png' 20 20 8 {
  param($b, $ox, $f)
  $cb = New-Object 'int[,]' 20 , 20; $zb = NewZ 20 20
  $a = $f * 2 * [math]::PI / 8
  RenderTube $cb $zb $knotPts $knotCols $a 0.35 2.95 10 10 1.75
  Blit $b $cb $ox 0 $ln
}

# ---- クラインの壺（ガラスのびん。首が曲がって胴の横から入りこむ形。静止）18x24 ----
$kleFn = {
  param($u, $v)
  $cu = [math]::Cos($u); $su = [math]::Sin($u); $cv = [math]::Cos($v); $sv = [math]::Sin($v)
  $x = -2.0 / 15 * $cu * (3 * $cv - 30 * $su + 90 * [math]::Pow($cu, 4) * $su - 60 * [math]::Pow($cu, 6) * $su + 5 * $cu * $cv * $su)
  $y = -1.0 / 15 * $su * (3 * $cv - 3 * $cu * $cu * $cv - 48 * [math]::Pow($cu, 4) * $cv + 48 * [math]::Pow($cu, 6) * $cv - 60 * $su + 5 * $cu * $cv * $su - 5 * [math]::Pow($cu, 3) * $cv * $su - 80 * [math]::Pow($cu, 5) * $cv * $su + 80 * [math]::Pow($cu, 7) * $cv * $su)
  $z = 2.0 / 15 * (3 + 5 * $cu * $su) * $sv
  @($x, $y, $z)
}
$kleCol = {
  param($u, $v, $d)
  $band = ([int][math]::Floor($u / 0.30)) % 2 -eq 0
  $base = if ($band) { C '#8f7cf0' } else { C '#aa9cf8' }
  $c = Shade $base (0.58 + 0.72 * $d)
  if ($d -gt 0.84) { $c = Mix $c (C '#ffffff') 0.55 }
  return $c
}
Sheet 'suuri_klein.png' 18 24 1 {
  param($b, $ox, $f)
  $cb = New-Object 'int[,]' 18 , 24; $zb = NewZ 18 24
  RenderSurf $cb $zb 240 24 0 ([math]::PI) 0 (2 * [math]::PI) $kleFn 0.35 0.12 4.8 8.2 21.5 $kleCol
  Blit $b $cb $ox 0 $ln
}

# =====================================================================
# 共通の描画の道具
# =====================================================================
$tr = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
function TxS($b, $t, $x, $y, $px, $col, $sh, $bold) { [void](TextPx $b $t ($x + 1) ($y + 1) $px $sh $bold); [void](TextPx $b $t $x $y $px $col $bold) }
function Ring($b, $cx, $cy, $r, $col) {
  $n = [int][math]::Ceiling($r * 8)
  for ($i = 0; $i -lt $n; $i++) { $a = $i * 2 * [math]::PI / $n; P $b ($cx + $r * [math]::Cos($a)) ($cy + $r * [math]::Sin($a)) $col }
}
# 絞り染めの渦巻き
function TieDye($b, $cx, $cy, $r, $c1, $c2, $c3, $edge) {
  for ($y = [math]::Floor($cy - $r - 1); $y -le [math]::Ceiling($cy + $r + 1); $y++) {
    for ($x = [math]::Floor($cx - $r - 1); $x -le [math]::Ceiling($cx + $r + 1); $x++) {
      $dx = $x + 0.5 - $cx; $dy = $y + 0.5 - $cy; $d = [math]::Sqrt($dx * $dx + $dy * $dy)
      if ($d -gt $r) { continue }
      $t = [math]::Atan2($dy, $dx) / (2 * [math]::PI) + $d / ($r * 0.5)
      $fr = $t - [math]::Floor($t)
      $c = if ($fr -lt 0.34) { $c1 } elseif ($fr -lt 0.67) { $c2 } else { $c3 }
      if ($edge -ne $null -and $d -gt $r - 1.0) { $c = $edge }
      Px $b $x $y $c
    }
  }
}
# ロゴ文字の飾り（太い日本語フォントで、グラデーション・ふち・光のにじみ・影を付ける）
function TextMask($text, $px, $font, $bold) {
  $style = if ($font -like 'BIZ*') { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
  $f = New-Object System.Drawing.Font($font, $px, $style, [System.Drawing.GraphicsUnit]::Pixel)
  $tmp = NewBmp ($px * ($text.Length + 2)) ($px * 2)
  $g = [System.Drawing.Graphics]::FromImage($tmp)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  $g.DrawString($text, $f, [System.Drawing.Brushes]::White, 0, 0, $fmt)
  $g.Dispose()
  $pts = New-Object System.Collections.ArrayList
  $x0 = 9999; $y0 = 9999; $x1 = -1; $y1 = -1
  for ($j = 0; $j -lt $tmp.Height; $j++) { for ($i = 0; $i -lt $tmp.Width; $i++) {
    if ($tmp.GetPixel($i, $j).A -ge 128) { [void]$pts.Add(@($i, $j)); $x0 = [math]::Min($x0, $i); $x1 = [math]::Max($x1, $i); $y0 = [math]::Min($y0, $j); $y1 = [math]::Max($y1, $j) }
  } }
  $tmp.Dispose(); $f.Dispose()
  $set = New-Object 'System.Collections.Generic.HashSet[int]'
  foreach ($p in $pts) { [void]$set.Add(($p[1] - $y0 + 20) * 4000 + ($p[0] - $x0 + 20)); if ($bold) { [void]$set.Add(($p[1] - $y0 + 20) * 4000 + ($p[0] - $x0 + 21)) } }
  return @{ set = $set; w = $x1 - $x0 + 1 + $(if ($bold) { 1 } else { 0 }); h = $y1 - $y0 + 1 }
}
function Dil($set, $r, $diamond) {
  $o = New-Object 'System.Collections.Generic.HashSet[int]'
  foreach ($k in $set) {
    for ($dy = -$r; $dy -le $r; $dy++) { for ($dx = -$r; $dx -le $r; $dx++) {
      if ($diamond -and ([math]::Abs($dx) + [math]::Abs($dy)) -gt $r) { continue }
      [void]$o.Add($k + $dy * 4000 + $dx)
    } }
  }
  return $o
}
# $edgeHex=ふち。$shine は光が走る位置（なければ -100）
function FxText($b, $m, $x, $y, $topHex, $midHex, $botHex, $edgeHex, $glowHex, $glowA, $shine) {
  $set = $m.set; $H = $m.h
  $d1 = Dil $set 1 $false
  if ($glowA -gt 0) { $glow = Dil $set 3 $true; foreach ($k in $glow) { $px = ($k % 4000) - 20; $py = [int][math]::Floor($k / 4000) - 20; PxO $b ($x + $px) ($y + $py) (CA $glowHex $glowA) } }
  foreach ($k in $d1) { $px = ($k % 4000) - 20 + 1; $py = [int][math]::Floor($k / 4000) - 20 + 2; PxO $b ($x + $px) ($y + $py) (CA '#0a1f1a' 200) }
  $edge = C $edgeHex
  foreach ($k in $d1) { $px = ($k % 4000) - 20; $py = [int][math]::Floor($k / 4000) - 20; PxO $b ($x + $px) ($y + $py) $edge }
  $ct = C $topHex; $cm = C $midHex; $cb = C $botHex
  foreach ($k in $set) {
    $px = ($k % 4000) - 20; $py = [int][math]::Floor($k / 4000) - 20
    $t = if ($H -le 1) { 0.0 } else { $py / [double]($H - 1) }
    $col = if ($t -lt 0.5) { Mix $ct $cm ($t * 2) } else { Mix $cm $cb (($t - 0.5) * 2) }
    if ($py -eq 0) { $col = Mix $col (C '#ffffff') 0.35 }
    if ([math]::Abs(($px + $py * 0.7) - $shine) -lt 2.5) { $col = Mix $col (C '#ffffff') 0.7 }
    PxO $b ($x + $px) ($y + $py) $col
  }
}
$FONT = 'BIZ UDPGothic'

# =====================================================================
# 床 192x128: パステルの方眼タイル（左=ミント / 真ん中=水色 / 右=ラベンダー）と入口の道、チョークの落書き
# =====================================================================
if (Want 'suuri_floor') {
$fl = NewBmp 192 128
for ($y = 0; $y -lt 128; $y++) {
  for ($x = 0; $x -lt 192; $x++) {
    $tile = ((([int][math]::Floor($x / 16)) + ([int][math]::Floor($y / 16))) % 2) -eq 0
    $base = if ($tile) { $cm1 } else { $cm0 }
    if ($x -lt 64) { $base = Mix $base $mt2 0.34 } elseif ($x -ge 112) { $base = Mix $base $lv2 0.34 } else { $base = Mix $base $sk2 0.26 }
    if (($x % 16) -eq 0 -or ($y % 16) -eq 0) { $base = Mix $base $sk1 0.16 }
    Px $fl $x $y $base
  }
}
# 入口の道（手前の真ん中から奥へ）。市松の水色と、上向きの矢じるし
for ($y = 86; $y -lt 128; $y++) {
  for ($x = 72; $x -lt 96; $x++) {
    $edge = ($x -le 72) -or ($x -ge 95)
    $c = if ($edge) { $sk1 } elseif (((([int][math]::Floor(($x - 72) / 6)) + ([int][math]::Floor($y / 6))) % 2) -eq 0) { $sk3 } else { $sk2 }
    Px $fl $x $y $c
  }
}
for ($y = 122; $y -gt 90; $y -= 14) {
  $cx = 84
  Px $fl $cx $y $sk0; Px $fl ($cx - 1) ($y + 1) $sk0; Px $fl ($cx + 1) ($y + 1) $sk0; Px $fl ($cx - 2) ($y + 2) $sk0; Px $fl ($cx + 2) ($y + 2) $sk0
}
# 外わく（左右に木のふち）
for ($y = 0; $y -lt 128; $y++) { foreach ($x in 0, 191) { Px $fl $x $y $wd1 }; foreach ($x in 1, 190) { Px $fl $x $y $wd2 } }
# チョークの落書き（通路のあたり）
$dd = C '#b9acea'
[void](TextPx $fl 'π' 8 87 11 $dd $false)
[void](TextPx $fl '△' 34 88 11 (C '#e79ab8') $false)
[void](TextPx $fl '∞' 102 87 11 $dd $false)
[void](TextPx $fl '√' 128 88 11 (C '#e79ab8') $false)
[void](TextPx $fl 'Σ' 154 87 11 $dd $false)
[void](TextPx $fl 'χ' 176 88 11 (C '#e79ab8') $false)
Save $fl 'suuri_floor.png'
}

# 床のきらめき 192x128 4コマ
$spk = @(@(14, 20, 0), @(40, 34, 2), @(70, 18, 1), @(150, 24, 3), @(176, 40, 1), @(22, 70, 3), @(60, 98, 0), @(130, 92, 2), @(174, 86, 0), @(12, 112, 1), @(100, 76, 3), @(120, 12, 0), @(52, 54, 2), @(168, 64, 3), @(86, 120, 2), @(140, 122, 1), @(110, 100, 2), @(30, 100, 0))
Sheet 'suuri_sparkle.png' 192 128 4 {
  param($b, $ox, $f)
  $pc = @('#ffffff', '#ffd1e6', '#c8e8ff', '#fff1a8')
  foreach ($p in $spk) {
    $st = ($f + $p[2]) % 4
    $x = $ox + $p[0]; $y = $p[1]
    $col = CA $pc[($p[0] + $p[1]) % 4] 255
    if ($st -eq 0) { Px $b $x $y $col; Px $b ($x - 1) $y (CC $col 190); Px $b ($x + 1) $y (CC $col 190); Px $b $x ($y - 1) (CC $col 190); Px $b $x ($y + 1) (CC $col 190) }
    elseif ($st -eq 1) { Px $b $x $y (CC $col 150) }
  }
}

# =====================================================================
# 看板「数理科学愛好会」160x40 6コマ。黒板に白いチョークの文字、まわりの電球が走り、π と ∞ が光る
# =====================================================================
$mSign = TextMask '数理科学愛好会' 14 $FONT $true
$bulbC = @($pk1, $yl1, $mt1)
Sheet 'suuri_sign.png' 160 40 6 {
  param($b, $ox, $f)
  # 板（木のわく＋黒板）。下の2pxは影
  Rect $b $ox 0 160 38 $ln
  Rect $b ($ox + 1) 1 158 36 $wd1
  Rect $b ($ox + 1) 1 158 1 $wd3; Rect $b ($ox + 1) 2 158 1 $wd2; Rect $b ($ox + 1) 35 158 1 $wd0
  for ($y = 5; $y -lt 33; $y++) { Rect $b ($ox + 5) $y 150 1 (Mix $gb2 $gb0 (($y - 5) / 27.0)) }
  Rect $b ($ox + 4) 4 152 1 $wd0; Rect $b ($ox + 4) 33 152 1 $wd3; Rect $b ($ox + 4) 4 1 30 $wd0; Rect $b ($ox + 155) 4 1 30 $wd3
  Frame $b ($ox + 8) 7 144 24 (Mix $gb2 $chalk 0.45)
  # まわりの電球（3色が走る）
  $ni = 0
  for ($x = 7; $x -lt 154; $x += 8) {
    $on = ((($ni + $f) % 3) -eq 0)
    $bc = $bulbC[$ni % 3]
    foreach ($yy in 2, 34) {
      if ($on) { Px $b ($ox + $x) $yy (Mix $bc (C '#ffffff') 0.5); Px $b ($ox + $x + 1) $yy $bc; Px $b ($ox + $x) ($yy + 1) $bc; Px $b ($ox + $x + 1) ($yy + 1) (Shade $bc 0.8) }
      else { Px $b ($ox + $x) $yy (Mix $wd1 $bc 0.35); Px $b ($ox + $x + 1) $yy (Mix $wd1 $bc 0.25); Px $b ($ox + $x) ($yy + 1) (Mix $wd0 $bc 0.2); Px $b ($ox + $x + 1) ($yy + 1) (Mix $wd0 $bc 0.15) }
    }
    $ni++
  }
  # 文字: π と ∞（交互に光る）と、大きな「数理科学愛好会」
  $glowA = if ($f % 2 -eq 0) { (Mix $pk1 (C '#ffffff') 0.45) } else { $pk1 }
  $glowB = if ($f % 2 -eq 0) { $mt1 } else { (Mix $mt1 (C '#ffffff') 0.45) }
  TxS $b 'π' ($ox + 13) 12 12 $glowA $gb0 $true
  TxS $b '∞' ($ox + 135) 12 12 $glowB $gb0 $true
  $tx = [math]::Floor(80 - $mSign.w / 2)
  FxText $b $mSign ($ox + $tx) 12 '#fffaf0' '#ffe9a0' '#ffc0dc' '#0f2d27' '#fff2b0' 0 (-12 + $f * 30)
  # きらめき
  $stars = @(@(26, 9), @(148, 8), @(66, 31), @(112, 30), @(40, 29), @(136, 27))
  for ($i = 0; $i -lt $stars.Count; $i++) {
    if ((($f + $i) % 3) -eq 0) { $sx = $ox + $stars[$i][0]; $sy = $stars[$i][1]; Px $b $sx $sy (C '#ffffff'); Px $b ($sx - 1) $sy (C '#ffe9a0'); Px $b ($sx + 1) $sy (C '#ffe9a0'); Px $b $sx ($sy - 1) (C '#ffe9a0'); Px $b $sx ($sy + 1) (C '#ffe9a0') }
  }
  foreach ($p in @(@(0, 0), @(159, 0), @(0, 37), @(159, 37))) { Px $b ($ox + $p[0]) $p[1] $tr }
  Rect $b ($ox + 3) 38 154 1 (CA '#2a2447' 70); Rect $b ($ox + 6) 39 148 1 (CA '#2a2447' 40)
}

# =====================================================================
# のぼり旗「数理科学愛好会」26x100（縦書き。黒板の緑に白と黄色の文字、パステルのふち。下はツバメの尾）
# =====================================================================
if (Want 'suuri_nobori') {
$nb = NewBmp 26 100
$script:CX0 = 0; $script:CX1 = 100
Rect $nb 0 0 26 3 $wd0; Rect $nb 0 0 26 1 $wd3; Rect $nb 0 1 26 1 $wd2
Rect $nb 0 0 2 4 $wd1; Rect $nb 24 0 2 4 $wd1
for ($y = 3; $y -lt 100; $y++) {
  $notch = 0
  if ($y -ge 93) { $notch = [int][math]::Min(11, ($y - 92) * 2) }
  for ($x = 3; $x -lt 23; $x++) {
    $cx = 12.5
    if ($notch -gt 0 -and [math]::Abs($x + 0.5 - $cx) -lt $notch) { continue }
    $c = Mix $gb2 $gb0 (($y - 3) / 96.0)
    if ($x -le 4 -or $x -ge 21) { $c = if ($x -le 4) { $pk1 } else { $lv1 } }
    Px $nb $x $y $c
  }
}
for ($y = 3; $y -lt 93; $y++) { Px $nb 3 $y $ln; Px $nb 22 $y $ln }
for ($i = 0; $i -lt 8; $i++) { Px $nb (6 + $i * 2) 5 $yl1 }
$chars = @('数', '理', '科', '学', '愛', '好', '会')
for ($i = 0; $i -lt 7; $i++) { $m = TextMask $chars[$i] 11 $FONT $true; FxText $nb $m 6 (8 + $i * 11) '#fffaf0' '#ffe9a0' '#ffc0dc' '#0f2d27' '#fff2b0' 0 (-100) }
TxS $nb '∞' 6 85 11 $mt1 $gb0 $true
Save $nb 'suuri_nobori.png'
}

# =====================================================================
# 奥の壁 176x50: 黒板（式と図）・図形のポスター・ぬの染めの旗（ペナント）・足元のパネル
# =====================================================================
if (Want 'suuri_wall') {
$wl = NewBmp 176 50
Rect $wl 0 0 176 50 (C '#e8e2f6')
for ($x = 0; $x -lt 176; $x += 8) { Rect $wl $x 0 1 40 (C '#dfd8f1') }
for ($y = 6; $y -lt 40; $y += 6) { for ($x = 3; $x -lt 176; $x += 8) { Px $wl ($x + ((($y / 6) % 2) * 4)) $y (C '#f4f0fc') } }
Rect $wl 0 0 176 4 $wd1; Rect $wl 0 0 176 1 $wd3; Rect $wl 0 1 176 1 $wd2; Rect $wl 0 3 176 1 $wd0
Rect $wl 0 40 176 10 (C '#9fdccb'); Rect $wl 0 40 176 1 $cm2; Rect $wl 0 41 176 1 $mt1
for ($x = 5; $x -lt 176; $x += 11) { Rect $wl $x 42 1 6 $mt1; Rect $wl ($x + 1) 42 1 6 (C '#b8ece0') }
Rect $wl 0 48 176 2 $wd1; Rect $wl 0 48 176 1 $wd2
# ---- 黒板 (3,6) 49x30
Rect $wl 3 6 49 30 $wd0; Rect $wl 4 7 47 28 $wd2; Rect $wl 4 7 47 1 $wd3
for ($y = 9; $y -lt 33; $y++) { Rect $wl 6 $y 43 1 (Mix $gb2 $gb0 (($y - 9) / 23.0)) }
foreach ($p in @(@(9, 11), @(30, 13), @(40, 24), @(14, 29), @(24, 27))) { RectO $wl $p[0] $p[1] 3 1 (CA '#ffffff' 28) }
Rect $wl 3 33 49 3 $wd1; Rect $wl 3 33 49 1 $wd3; Rect $wl 4 35 47 1 $wd0
Rect $wl 7 32 5 2 $cm2; Rect $wl 14 32 4 2 $pk2; Rect $wl 20 32 4 2 $yl2; Rect $wl 40 31 8 3 $sk0; Rect $wl 40 31 8 1 $sk1
[void](TextPx $wl 'χ=V-E+F' 7 9 11 $chalk $false)
Ring $wl 12 25 4.6 $yl2; LineR $wl 12 25 16 23 $yl2
LineR $wl 22 29 28 20 $pk2; LineR $wl 28 20 34 29 $pk2; LineR $wl 22 29 34 29 $pk2
for ($x = 0; $x -lt 13; $x++) { P $wl (37 + $x) (25 - [math]::Round(3.2 * [math]::Sin($x * 0.62))) $sk2 }
LineR $wl 37 25 49 25 (Mix $gb1 $sk2 0.55)
# ---- ペナント（真ん中の上。ぬの染めの三角旗）
$pn = @($pk1, $yl1, $mt1, $sk1, $lv1, $pk2, $yl2, $mt2)
LineR $wl 54 13 106 13 $wd1
for ($i = 0; $i -lt 8; $i++) {
  $x0 = 56 + $i * 6
  $c = $pn[$i]
  for ($j = 0; $j -lt 6; $j++) { for ($x = $x0; $x -lt $x0 + 5; $x++) { if ($x - $x0 + $j / 2.0 -lt 5) { Px $wl $x (14 + $j) $(if ($j -eq 0) { Mix $c (C '#ffffff') 0.3 } else { $c }) } } }
}
# ---- 図形のポスター (111,7) 28x31
Rect $wl 111 7 28 31 $ln; Rect $wl 112 8 26 29 $cm2
Rect $wl 112 8 26 1 $sk2
[void](TextPx $wl '図形' 114 9 11 $sk0 $true)
Rect $wl 123 5 4 2 $pk1; Px $wl 124 5 $pk3
Frame $wl 115 22 9 9 $pk0; Frame $wl 119 18 9 9 $pk0
LineR $wl 115 22 119 18 $pk0; LineR $wl 124 22 128 18 $pk0; LineR $wl 115 30 119 26 $pk0; LineR $wl 124 30 128 26 $pk0
Rect $wl 116 23 7 7 $pk3
LineR $wl 130 31 134 20 $sk0; LineR $wl 134 20 137 31 $sk0; LineR $wl 130 31 137 31 $sk0; LineR $wl 134 20 133 31 $sk1
Rect $wl 113 33 24 2 $yl2
# ---- フラクタルのポスター (142,7) 28x31
Rect $wl 142 7 28 31 $ln; Rect $wl 143 8 26 29 $lv3
Rect $wl 143 8 26 1 $lv2
[void](TextPx $wl '∞' 150 9 11 $lv0 $true)
Rect $wl 154 5 4 2 $mt1; Px $wl 155 5 $mt2
for ($n = 0; $n -lt 16; $n++) {
  for ($k = 0; $k -le $n; $k++) {
    if (($n -band $k) -eq $k) {
      $c = Mix $pk1 $lv1 ($n / 15.0)
      Px $wl (148 + $k + 8 - [math]::Floor($n / 2)) (14 + $n) $c
    }
  }
}
Rect $wl 144 33 24 2 $mt1
Save $wl 'suuri_wall.png'
}

# =====================================================================
# 作業台 3つ（上はギンガムのクロス、前に札）。高さ30。展示台の円盤（$discs）は上面に描く
# =====================================================================
function DrawBench($b, $ox, $Wd, $top1, $top2, $front, $frontHi, $t1, $t2, $discs) {
  Rect $b $ox 0 $Wd 29 $ln
  Rect $b ($ox + 1) 1 ($Wd - 2) 4 $top1
  for ($x = 1; $x -lt $Wd - 1; $x++) { for ($y = 1; $y -lt 5; $y++) { if (((([int][math]::Floor($x / 3)) + $y) % 2) -eq 0) { Px $b ($ox + $x) $y $top2 } } }
  Rect $b ($ox + 1) 1 ($Wd - 2) 1 (Mix $top1 (C '#ffffff') 0.55)
  foreach ($dc in $discs) {
    Ellipse $b ($ox + $dc) 2.6 8 1.9 $ln
    Ellipse $b ($ox + $dc) 2.6 7 1.3 $cm2
    Px $b ($ox + $dc - 3) 2 (C '#ffffff')
  }
  Rect $b ($ox + 1) 5 ($Wd - 2) 23 $front
  Rect $b ($ox + 1) 5 ($Wd - 2) 1 $frontHi
  Rect $b ($ox + 1) 6 ($Wd - 2) 1 (Shade $front 0.78)
  Rect $b ($ox + 1) 27 ($Wd - 2) 1 (Shade $front 0.7)
  for ($x = 3; $x -lt $Wd - 3; $x += 6) { Px $b ($ox + $x) 28 $ln }
  Rect $b ($ox + 2) 29 ($Wd - 4) 1 (CA '#2a2447' 70)
  $tw1 = TextWidth $t1 11; $tw2 = TextWidth $t2 11
  TxS $b $t1 ($ox + [math]::Floor(($Wd - $tw1 - 1) / 2)) 7 11 $cm2 $ink $true
  TxS $b $t2 ($ox + [math]::Floor(($Wd - $tw2 - 1) / 2)) 17 11 $cm2 $ink $true
  foreach ($p in @(@(0, 0), @(($Wd - 1), 0))) { Px $b ($ox + $p[0]) $p[1] $tr }
}
Sheet 'suuri_bench_slime.png' 54 30 1 { param($b, $ox, $f); DrawBench $b $ox 54 $pk3 $pk2 (C '#2f9a86') (C '#62cdb6') 'スライム' 'づくり' @() }
Sheet 'suuri_bench_dye.png' 50 30 1 { param($b, $ox, $f); DrawBench $b $ox 50 $sk3 $sk2 (C '#4452b0') (C '#7a8adc') '布の' '染色教室' @() }
Sheet 'suuri_bench_topo.png' 72 30 1 { param($b, $ox, $f); DrawBench $b $ox 72 $lv3 $lv2 (C '#7a5ad0') (C '#a890f0') 'トポロジ' 'の展示' @(10, 28, 44, 60) }

# =====================================================================
# スライム作り: ボウルと混ぜる棒（スライムがぷるぷる、棒がぐるぐる）20x14 6コマ
# =====================================================================
Sheet 'suuri_slime_bowl.png' 20 14 6 {
  param($b, $ox, $f)
  $a = $f * 2 * [math]::PI / 6
  $mh = 4.3 + 0.9 * [math]::Sin($a * 2)
  # スライムの山（ふち・もも色・明るい色・つや）
  Ellipse $b ($ox + 10) 7.5 8.4 ($mh + 1.0) $ln
  Ellipse $b ($ox + 10) 7.5 7.4 $mh (C '#c9a8ff')
  Ellipse $b ($ox + 10) 7.2 6.6 ($mh - 0.8) (C '#ffa8d8')
  Ellipse $b ($ox + 9) 6.4 4.2 ($mh - 1.8) (C '#ffd0ec')
  Px $b ($ox + 7) ([int](7.5 - $mh + 1.6)) (C '#ffffff'); Px $b ($ox + 8) ([int](7.5 - $mh + 1.2)) (C '#ffffff')
  # ボウル（下半分）
  for ($y = 7; $y -lt 14; $y++) {
    $dy = ($y + 0.5 - 7) / 6.6
    $hw = 9.6 * [math]::Sqrt([math]::Max(0.0, 1 - $dy * $dy))
    $xl = [int][math]::Round(10 - $hw); $xr = [int][math]::Round(10 + $hw) - 1
    for ($x = $xl; $x -le $xr; $x++) {
      $c = $sk1
      if ($x -le $xl -or $x -ge $xr -or $y -eq 13) { $c = $ln }
      elseif ($x -le $xl + 2) { $c = $sk3 }
      elseif ($x -ge $xr - 2 -or $y -ge 12) { $c = $sk0 }
      Px $b ($ox + $x) $y $c
    }
  }
  Rect $b ($ox + 1) 7 18 1 $sk3; Px $b ($ox + 0) 7 $ln; Px $b ($ox + 19) 7 $ln
  Px $b ($ox + 6) 10 $sk3; Px $b ($ox + 7) 10 $sk3; Px $b ($ox + 13) 9 $pk2; Px $b ($ox + 14) 10 $yl2; Px $b ($ox + 10) 11 $pk2
  # 垂れるスライム（ふちから）
  Rect $b ($ox + 3) 7 2 ([int](2 + ($f % 3))) (C '#ffa8d8'); Px $b ($ox + 3) 7 (C '#ffd0ec')
  # 混ぜる棒（先がまるく回る）
  $tx = 10 + 3.2 * [math]::Cos($a); $ty = 5 + 1.3 * [math]::Sin($a)
  LineR $b ($ox + 17) 0 ($ox + $tx) $ty $wd0
  LineR $b ($ox + 16) 0 ($ox + $tx - 1) $ty $wd2
  Px $b ($ox + 17) 0 $wd3; Px $b ($ox + 16) 0 $wd3
  P $b ($ox + $tx) $ty (C '#ff8fc8')
  if ($f % 3 -eq 1) { Px $b ($ox + 13) 3 (C '#ffe8f6'); Px $b ($ox + 12) 4 (C '#ffd0ec') }
}

# 色の素のボトルと瓶入りスライムの棚 20x22 4コマ（ラメがきらきら）
Sheet 'suuri_slime_shelf.png' 20 22 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 20 22 $ln
  Rect $b ($ox + 1) 1 18 20 $cm1
  for ($x = 2; $x -lt 19; $x += 4) { Rect $b ($ox + $x) 1 1 9 (Mix $cm1 $cm0 0.5) }
  Rect $b ($ox + 1) 10 18 2 $wd2; Rect $b ($ox + 1) 10 18 1 $wd3; Rect $b ($ox + 1) 11 18 1 $wd1
  Rect $b ($ox + 1) 20 18 2 $wd2; Rect $b ($ox + 1) 20 18 1 $wd3; Rect $b ($ox + 0) 21 20 1 $ln
  # 色の素のボトル（ピンク・水色・黄色）。キャップは白
  $bc = @($pk1, $sk1, $yl1); $bx = @(3, 8, 13)
  for ($i = 0; $i -lt 3; $i++) {
    $x = $bx[$i]
    Rect $b ($ox + $x) 4 5 6 (Shade $bc[$i] 0.78); Rect $b ($ox + $x + 1) 4 3 6 $bc[$i]; Rect $b ($ox + $x + 1) 4 1 5 (Mix $bc[$i] (C '#ffffff') 0.5)
    Rect $b ($ox + $x + 1) 3 3 1 $cm1; Rect $b ($ox + $x + 1) 1 3 2 $cm2; Px $b ($ox + $x + 1) 1 (C '#ffffff')
    Rect $b ($ox + $x) 6 5 2 $cm2; Px $b ($ox + $x + 2) 7 $bc[$i]
  }
  # 瓶（ミントと紫のスライム）。ふた＝黄
  $jc = @($mt1, $lv1); $jx = @(2, 11)
  for ($i = 0; $i -lt 2; $i++) {
    $x = $jx[$i]
    Rect $b ($ox + $x) 14 7 6 (CA '#e9f6ff' 255); Frame $b ($ox + $x) 14 7 6 $sk1
    Rect $b ($ox + $x + 1) 15 5 4 $jc[$i]; Rect $b ($ox + $x + 1) 15 5 1 (Mix $jc[$i] (C '#ffffff') 0.45)
    Rect $b ($ox + $x + 1) 12 5 2 $yl1; Rect $b ($ox + $x + 1) 12 5 1 $yl2
    Px $b ($ox + $x + 1) 16 (C '#ffffff')
    $k = ($f + $i * 2) % 4
    Px $b ($ox + $x + 1 + $k) (15 + ($k % 3)) (C '#ffffff')
    Px $b ($ox + $x + 5 - $k % 3) (18 - ($k % 2)) (C '#fff4c4')
  }
}

# スライムの体験テーブル（手前の左）32x24
Sheet 'suuri_slime_table.png' 32 24 1 {
  param($b, $ox, $f)
  # 大きなボウルとスライム
  Ellipse $b ($ox + 10) 5.2 8 3.8 $ln; Ellipse $b ($ox + 10) 5.0 7 3.1 (C '#8de0b8'); Ellipse $b ($ox + 9) 4.2 4.6 2.0 (C '#c6f5dc')
  Px $b ($ox + 7) 3 (C '#ffffff'); Px $b ($ox + 8) 2 (C '#ffffff')
  for ($y = 6; $y -lt 10; $y++) {
    $dy = ($y + 0.5 - 6) / 4.0; $hw = 8.4 * [math]::Sqrt([math]::Max(0.0, 1 - $dy * $dy))
    for ($x = [int][math]::Round(10 - $hw); $x -lt [int][math]::Round(10 + $hw); $x++) { $c = if ($y -ge 9 -or $x -eq [int][math]::Round(10 - $hw) -or $x -eq [int][math]::Round(10 + $hw) - 1) { $ln } elseif ($x -lt 6) { $sk3 } elseif ($x -gt 14) { $sk0 } else { $sk1 }; Px $b ($ox + $x) $y $c }
  }
  # 小さな瓶2つ（ピンクと水色のスライム）
  foreach ($j in @(@(21, '#ffa8d8'), @(26, '#8ed0ff'))) {
    Rect $b ($ox + $j[0]) 3 4 7 (C '#e9f6ff'); Frame $b ($ox + $j[0]) 3 4 7 $sk1
    Rect $b ($ox + $j[0] + 1) 5 2 4 (C $j[1]); Rect $b ($ox + $j[0]) 1 4 2 $yl1; Px $b ($ox + $j[0]) 1 $yl2
  }
  # 天板とクロス
  Rect $b $ox 9 32 14 $ln
  Rect $b ($ox + 1) 10 30 4 $cm1; Rect $b ($ox + 1) 10 30 1 $cm2
  for ($y = 14; $y -lt 22; $y++) { for ($x = 1; $x -lt 31; $x++) { $c = if (((([int][math]::Floor($x / 3)) + ([int][math]::Floor($y / 3))) % 2) -eq 0) { $pk2 } else { $pk3 }; Px $b ($ox + $x) $y $c } }
  Rect $b ($ox + 1) 14 30 1 $pk1
  Rect $b ($ox + 1) 22 30 1 $pk0
  for ($x = 2; $x -lt 31; $x += 4) { Px $b ($ox + $x) 23 $pk1; Px $b ($ox + $x + 1) 23 $pk1 }
  Rect $b ($ox + 2) 23 28 1 (CA '#2a2447' 70)
  foreach ($p in @(@(0, 9), @(31, 9))) { Px $b ($ox + $p[0]) $p[1] $tr }
}

# =====================================================================
# 布の染色教室: 洗濯ばさみで干した布 48x28 4コマ（そよ風でゆれる）
# =====================================================================
Sheet 'suuri_dye_line.png' 48 28 4 {
  param($b, $ox, $f)
  # 縄（たるむ）と壁の金具
  for ($x = 1; $x -lt 47; $x++) { $ry = 3 + [int][math]::Round(0.9 * [math]::Sin([math]::PI * ($x - 1) / 45.0)); Px $b ($ox + $x) $ry $wd0; Px $b ($ox + $x) ($ry - 1) (Mix $wd2 $wd0 0.3) }
  Rect $b $ox 0 2 6 $wd1; Rect $b $ox 0 1 6 $wd3; Rect $b ($ox + 46) 0 2 6 $wd1; Rect $b ($ox + 47) 0 1 6 $wd0
  $hs = @(15, 12, 17, 13); $xs = @(3, 14, 26, 37)
  for ($ci = 0; $ci -lt 4; $ci++) {
    $x0 = $xs[$ci]; $h = $hs[$ci]; $w = 9
    $sway = [math]::Sin($f * [math]::PI / 2 + $ci * 0.9)
    $ph = $f * [math]::PI / 2 + $ci * 1.3
    for ($lx = 0; $lx -lt $w; $lx++) {
      $hh = $h + [int][math]::Round(1.3 * [math]::Sin($ph + $lx * 0.8))
      $ropeY = 3 + [int][math]::Round(0.9 * [math]::Sin([math]::PI * ($x0 + $lx - 1) / 45.0))
      for ($ly = 0; $ly -lt $hh; $ly++) {
        $shift = [int][math]::Round($sway * 1.4 * $ly / $h)
        switch ($ci) {
          0 { $c = if (([int][math]::Floor(($ly + 1.6 * [math]::Sin($lx * 0.9 + 0.5)) / 3)) % 2 -eq 0) { $sk1 } else { $sk3 } }
          1 { $dx = $lx + 0.5 - 4.5; $dy = $ly - $h * 0.45; $dd2 = [math]::Sqrt($dx * $dx + $dy * $dy); $t = [math]::Atan2($dy, $dx) / (2 * [math]::PI) + $dd2 / 3.2; $fr = $t - [math]::Floor($t); $c = if ($fr -lt 0.34) { $pk1 } elseif ($fr -lt 0.67) { $cm2 } else { $yl1 } }
          2 { $c = Mix $mt1 $lv1 ($ly / [double]$h); if ((($lx * 7 + $ly * 3) % 11) -eq 0) { $c = $cm2 } }
          3 { $c = C '#3f4fa8'; foreach ($q in @(@(2, 3), @(6, 6), @(2, 9), @(6, 13))) { $rx = $lx - $q[0]; $ry = $ly - $q[1]; $rr = [math]::Sqrt($rx * $rx + $ry * $ry); if ($rr -ge 1.1 -and $rr -le 2.1) { $c = C '#e8f0ff' } } }
        }
        if ($ly -ge $hh - 1) { $c = Shade $c 0.82 }
        if ($lx -eq 0 -or $lx -eq $w - 1) { $c = Shade $c 0.86 }
        Px $b ($ox + $x0 + $lx + $shift) ($ropeY + 1 + $ly) $c
      }
    }
    # 洗濯ばさみ（両はしの2つ）
    foreach ($px0 in @(($x0 + 1), ($x0 + $w - 3))) {
      $ropeY = 3 + [int][math]::Round(0.9 * [math]::Sin([math]::PI * ($px0 - 1) / 45.0))
      Rect $b ($ox + $px0) ($ropeY - 1) 2 5 $wd2; Rect $b ($ox + $px0) ($ropeY - 1) 1 5 $wd3; Px $b ($ox + $px0 + 1) ($ropeY + 1) (C '#9aa0b8'); Px $b ($ox + $px0) ($ropeY - 1) $cm2
    }
  }
  # ぽたっと落ちるしずく（ピンクの布から）
  if ($f -lt 3) { Px $b ($ox + 18) (18 + $f * 2) $pk1 }
}

# 染め道具（折りたたんだエプロン・ゴム手袋・絞り染めの見本）30x14
Sheet 'suuri_dye_goods.png' 30 14 1 {
  param($b, $ox, $f)
  # エプロン
  Rect $b $ox 3 10 11 $ln; Rect $b ($ox + 1) 4 8 9 $cm2; Rect $b ($ox + 1) 4 8 1 (C '#ffffff')
  Rect $b ($ox + 1) 9 8 1 $mt1; Rect $b ($ox + 1) 11 8 1 $mt1
  Rect $b ($ox + 2) 6 4 3 $pk2; Frame $b ($ox + 2) 6 4 3 $pk1
  LineR $b ($ox + 2) 3 ($ox + 4) 0 $ln; LineR $b ($ox + 7) 3 ($ox + 5) 0 $ln; Px $b ($ox + 4) 0 $mt0; Px $b ($ox + 5) 0 $mt0
  # ゴム手袋（黄色。2つが重なる）
  $glove = @('.O.O.O.', 'OYOYOYO', 'OYYYYYO', 'OYYZYYO', '.OYYYO.', '.OYZYO.', '.OOOOO.')
  Ascii $b ($ox + 11) 5 $glove @{ O = (C '#9a6a10'); Y = $yl1; Z = $yl0 }
  Ascii $b ($ox + 16) 6 $glove @{ O = (C '#9a6a10'); Y = $yl1; Z = $yl0 }
  Px $b ($ox + 13) 6 $yl3; Px $b ($ox + 18) 7 $yl3
  # 絞り染めの見本（ゴムでとめた渦）
  TieDye $b ($ox + 25.5) 8.5 4.4 $sk1 $cm2 $sk3 $sk0
  Px $b ($ox + 25) 8 $pk1; Px $b ($ox + 26) 9 $pk1
  Rect $b ($ox + 23) 12 5 1 $ln; Px $b ($ox + 24) 12 $og1
}

# 染め桶（手前。ピンクと藍の染め液がゆれる）36x26 4コマ
function Tub($b, $cx, $topY, $rx, $ry, $bodyH, $liq1, $liq2, $liqHi, $f) {
  for ($y = $topY; $y -lt $topY + $bodyH; $y++) {
    $t = ($y - $topY) / [double]$bodyH
    $hw = $rx - 1.4 * $t
    $xl = [int][math]::Round($cx - $hw); $xr = [int][math]::Round($cx + $hw) - 1
    for ($x = $xl; $x -le $xr; $x++) {
      $c = if ((($x - $xl) % 3) -eq 0) { $wd0 } elseif ((($x - $xl) % 3) -eq 1) { $wd1 } else { $wd2 }
      if ($x -le $xl -or $x -ge $xr -or $y -eq $topY + $bodyH - 1) { $c = $ln }
      Px $b $x $y $c
    }
  }
  foreach ($hy in @(($topY + 3), ($topY + $bodyH - 4))) {
    $t = ($hy - $topY) / [double]$bodyH; $hw = $rx - 1.4 * $t
    Rect $b ([int][math]::Round($cx - $hw) + 1) $hy ([int][math]::Round(2 * $hw) - 2) 2 (C '#7c849c')
    Rect $b ([int][math]::Round($cx - $hw) + 1) $hy ([int][math]::Round(2 * $hw) - 2) 1 (C '#b8c0d8')
  }
  Ellipse $b $cx $topY $rx $ry $ln
  Ellipse $b $cx $topY ($rx - 1) ($ry - 0.8) $wd3
  Ellipse $b $cx ($topY + 0.2) ($rx - 2.2) ($ry - 1.6) $liq1
  # 液面のゆれ（ハイライトの弧が動く）と泡
  $ang = $f * [math]::PI / 2
  for ($k = 0; $k -lt 5; $k++) { $a = $ang + $k * 0.35 - 0.4; P $b ($cx + ($rx - 3.4) * [math]::Cos($a + 3.6)) ($topY - 0.2 + ($ry - 2.2) * [math]::Sin($a + 3.6)) $liqHi }
  Px $b ($cx - 2 + ($f % 3)) ($topY - 1 + ($f % 2)) $liq2
  Px $b ($cx + 2 - ($f % 2)) ($topY + 1) $liqHi
}
Sheet 'suuri_dye_tubs.png' 36 26 4 {
  param($b, $ox, $f)
  # 棒にかけた布（左の桶の上）
  LineR $b ($ox + 3) 1 ($ox + 10) 8 $wd0
  LineR $b ($ox + 4) 1 ($ox + 11) 8 $wd2
  TieDye $b ($ox + 4.5) 4.5 3.6 $pk1 $cm2 $yl1 $pk0
  if ($f -lt 3) { Px $b ($ox + 7) (8 + $f) $pk1 }
  Tub $b ($ox + 10) 9 9 3.4 13 (C '#ff7fb2') (C '#ff4f90') (C '#ffd0e4') $f
  Tub $b ($ox + 27) 10 8 3.0 12 (C '#4a5ed0') (C '#2f3f9a') (C '#a8b8ff') ($f + 2)
  # 右の桶にひっかけた布のはし
  for ($y = 11; $y -lt 20; $y++) { $xx = 34 + [int][math]::Round(0.7 * [math]::Sin($f * [math]::PI / 2 + $y * 0.6)); Px $b ($ox + $xx) $y $(if ((($y + 1) % 3) -eq 0) { $cm2 } else { $sk1 }); Px $b ($ox + $xx + 1) $y $(if ((($y + 1) % 3) -eq 0) { $sk3 } else { $sk0 }) }
  Rect $b ($ox + 2) 23 32 3 (CA '#2a2447' 55)
}

# =====================================================================
# 説明パネル「おなじ かたち」80x38 8コマ。左の絵で、コーヒーカップがドーナツへ、とろりと変わっていく
#   形は2つの距離関数（SDF）を混ぜて作る（穴が1つの形どうし）。
# =====================================================================
$morphT = @(0.0, 0.0, 0.22, 0.5, 0.85, 1.0, 0.7, 0.3)
Sheet 'suuri_panel.png' 80 38 8 {
  param($b, $ox, $f)
  $t = $morphT[$f]
  # 足
  foreach ($lx in 9, 67) { Rect $b ($ox + $lx) 33 4 5 $wd1; Rect $b ($ox + $lx) 33 1 5 $wd2; Rect $b ($ox + $lx + 3) 33 1 5 $wd0 }
  # 板
  Rect $b $ox 0 80 34 $ln
  Rect $b ($ox + 1) 1 78 32 $wd1; Rect $b ($ox + 1) 1 78 1 $wd3; Rect $b ($ox + 1) 2 78 1 $wd2; Rect $b ($ox + 1) 32 78 1 $wd0
  Rect $b ($ox + 3) 3 74 28 $cm2
  Rect $b ($ox + 3) 3 74 1 $cm0
  # 絵のわく
  Rect $b ($ox + 4) 4 30 26 $sk3; Frame $b ($ox + 4) 4 30 26 $sk1
  # 形（中心 (19,17)）
  $msk = New-Object 'bool[,]' 34, 30
  $cl = New-Object 'int[,]' 34, 30
  $s = [math]::Min(1.0, [math]::Max(0.0, ($t - 0.25) / 0.4)); $s = $s * $s * (3 - 2 * $s)
  for ($yy = 5; $yy -lt 29; $yy++) {
    for ($xx = 5; $xx -lt 33; $xx++) {
      $px = $xx + 0.5 - 19; $py = $yy + 0.5 - 17
      # 本体（角ばった箱 → ふっくらした輪）+ 取っ手の輪 − 穴（取っ手の穴が、まん中へ動いて広がる）
      $bcx = -4.0 * (1 - $t); $bcy = 1.5 * (1 - $t)
      $brx = 6.0 + 5.5 * $t; $bry = 6.5 + 0.7 * $t
      $pe = 10.0 - 8.0 * $t
      $inBody = ([math]::Pow([math]::Abs(($px - $bcx) / $brx), $pe) + [math]::Pow([math]::Abs(($py - $bcy) / $bry), $pe)) -le 1.0
      $hx = $px - 6.0 * (1 - $t); $hy = $py - 1.5 * (1 - $t)
      $rd = [math]::Sqrt($hx * $hx + $hy * $hy)
      $inRing = ($t -lt 0.75) -and ([math]::Abs($rd - 3.9) -le 1.4 * (1 - $t / 0.75))
      $hcx = 6.0 * (1 - $t); $hcy = 1.5 * (1 - $t)
      $hrx = 2.5 + 1.7 * $t; $hry = 2.5 - 0.2 * $t
      $inHole = ((($px - $hcx) / $hrx) * (($px - $hcx) / $hrx) + (($py - $hcy) / $hry) * (($py - $hcy) / $hry)) -lt 1.0
      if (($inBody -or $inRing) -and -not $inHole) {
        $msk[$xx, $yy] = $true
        $base = Mix $sk1 (C '#dda057') $s
        if ($s -lt 0.5) {
          if ($inBody -and $py -lt ($bcy - $bry + 2.4) -and $px -lt ($bcx + $brx * 0.85)) { $base = C '#6b4226' }
          elseif ($inBody -and $px -lt ($bcx - $brx + 2.2)) { $base = $sk3 }
        } else {
          if ($py -lt (-0.8 + 1.3 * [math]::Sin($px * 0.9))) { $base = C '#ff8fc0' }
          if ($py -lt -2.0 -and (($xx * 7 + $yy * 3) % 13) -eq 0) { $base = C '#ffe040' }
        }
        if ($py -gt 4.5) { $base = Shade $base 0.82 }
        $cl[$xx, $yy] = $base.ToArgb()
      }
    }
  }
  for ($yy = 4; $yy -lt 30; $yy++) {
    for ($xx = 4; $xx -lt 34; $xx++) {
      if ($msk[$xx, $yy]) { $cv = $cl[$xx, $yy]; Px $b ($ox + $xx) $yy ([System.Drawing.Color]::FromArgb($cv)) }
    }
  }
  for ($yy = 5; $yy -lt 29; $yy++) {
    for ($xx = 5; $xx -lt 33; $xx++) {
      if ($msk[$xx, $yy]) { continue }
      $near = $msk[($xx - 1), $yy] -or $msk[($xx + 1), $yy] -or $msk[$xx, ($yy - 1)] -or $msk[$xx, ($yy + 1)]
      if ($near) { Px $b ($ox + $xx) $yy $ln }
    }
  }
  # ゆげ（カップのとき）
  if ($t -lt 0.3) { $sy = 4 + ($f % 2); Px $b ($ox + 14) $sy (C '#ffffff'); Px $b ($ox + 15) ($sy - 1) (C '#e8f0ff') }
  # 文字
  TxS $b 'おなじ' ($ox + 38) 5 12 $lv0 $cm0 $true
  TxS $b 'かたち' ($ox + 38) 18 12 $pk0 $cm0 $true
  # きらめき
  $q = $f % 4
  Px $b ($ox + 72) (8 + $q) $yl1; Px $b ($ox + 71) (8 + $q) $yl2; Px $b ($ox + 73) (8 + $q) $yl2; Px $b ($ox + 72) (7 + $q) $yl2; Px $b ($ox + 72) (9 + $q) $yl2
  foreach ($p in @(@(0, 0), @(79, 0), @(0, 33), @(79, 33))) { Px $b ($ox + $p[0]) $p[1] $tr }
}

# =====================================================================
# エプロン（人物の胴にかぶせる）96x64。人物と同じ位置・同じ向きで重ねる
# =====================================================================
Sheet 'suuri_apron.png' 96 64 1 {
  param($b, $ox, $f)
  $ap = C '#8fe6cf'; $ap2 = C '#5fc9ae'
  Rect $b ($ox + 45) 34 6 2 $ap; Px $b ($ox + 45) 34 $ap2; Px $b ($ox + 50) 34 $ap2
  Rect $b ($ox + 44) 36 8 2 $ap; Rect $b ($ox + 44) 37 8 1 $ap2
  Px $b ($ox + 47) 36 $cm2; Px $b ($ox + 48) 36 $pk1
  Px $b ($ox + 44) 33 $ap2; Px $b ($ox + 51) 33 $ap2
}
