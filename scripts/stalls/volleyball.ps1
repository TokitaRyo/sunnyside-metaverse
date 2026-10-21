# バレーボール部（風船バレー・スパイクチャレンジ）の専用ドット絵。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/volleyball.ps1   （リポジトリのルートで）
# 出力: client/public/brand/stall/volleyball_*.png（配置は scripts/stalls/volleyball.mjs）
# 一部だけ作り直す: $env:VB_ONLY='sign|net'（名前の正規表現。例: 'maid' で メイド衣装だけ）
# 絵はすべてこのスクリプトで描いたオリジナル。文字は MS Gothic をドットにして貼る（Windows 専用）。
# 配色: バレーボールの青・黄・白に、メイド衣装の黒・白・ピンクのフリル。
. "$PSScriptRoot\..\lib\pixel.ps1"

function CA($h, $a) { $c = C $h; [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  if ($env:VB_ONLY -and ($name -notmatch $env:VB_ONLY)) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}
function Clr($b, $x, $y) { Px $b $x $y ([System.Drawing.Color]::FromArgb(0, 0, 0, 0)) }
function P($b, $x, $y, $col) { Px $b ([int][math]::Round($x)) ([int][math]::Round($y)) $col }
function Blob($b, $cx, $cy, $rx, $ry, $fill, $line) { Ellipse $b $cx $cy ($rx + 1) ($ry + 1) $line; Ellipse $b $cx $cy $rx $ry $fill }

# ---------- 色 ----------
$navy0 = C '#14224a'; $navy = C '#1f3a78'; $navy2 = C '#27489a'
$blu = C '#2f6fd0'; $blu2 = C '#1d4a9a'; $blu3 = C '#78b0f4'; $sky = C '#bfe3fb'; $sky2 = C '#9ccbef'
$yel = C '#ffd23f'; $yel2 = C '#e0a81c'; $yel3 = C '#fff08a'
$org = C '#ef8a2c'; $org2 = C '#b8601a'
$pk = C '#f58fb0'; $pk2 = C '#d8628a'; $pk3 = C '#ffd0de'
$gn = C '#4fb556'; $gn2 = C '#2f7c3a'; $gn3 = C '#8ee08f'
$bk = C '#2a2733'; $bk2 = C '#4a4658'
$wh = C '#fbf8f2'; $wh2 = C '#e4e0ee'; $wh3 = C '#bdb8d0'
$ink = C '#33202a'
$gy = C '#9aa3b5'; $gy2 = C '#6c7589'; $gy3 = C '#d6dbe6'
$ol2 = C '#1b2f66'

# 縁取りつきの太字。TextPx で描いた文字を 8 方向にふくらませる
function OutText($b, $text, $x, $y, $px, $fill, $edge, $bold) {
  $tmp = NewBmp ($px * ($text.Length + 2)) ($px + 4)
  [void](TextPx $tmp $text 1 1 $px (C '#ffffff') $bold)
  foreach ($d in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1), @(-1, -1), @(1, -1), @(-1, 1), @(1, 1))) {
    for ($j = 0; $j -lt $tmp.Height; $j++) { for ($i = 0; $i -lt $tmp.Width; $i++) {
      if ($tmp.GetPixel($i, $j).A -ge 128) { Px $b ($x + $i - 1 + $d[0]) ($y + $j - 1 + $d[1]) $edge }
    } }
  }
  for ($j = 0; $j -lt $tmp.Height; $j++) { for ($i = 0; $i -lt $tmp.Width; $i++) {
    if ($tmp.GetPixel($i, $j).A -ge 128) { Px $b ($x + $i - 1) ($y + $j - 1) $fill }
  } }
  $tmp.Dispose()
}

# バレーボール（黄・白・青のパネル）。$ph で回転
function VBall($b, $cx, $cy, $r, $ph) {
  $cols = @((C '#ffd23f'), (C '#fbf8f2'), (C '#3f7fe0'))
  $seam = C '#27489a'; $edge = C '#1b2f66'
  for ($y = [int][math]::Floor($cy - $r - 1); $y -le [int][math]::Ceiling($cy + $r + 1); $y++) {
    for ($x = [int][math]::Floor($cx - $r - 1); $x -le [int][math]::Ceiling($cx + $r + 1); $x++) {
      $dx = $x + 0.5 - $cx; $dy = $y + 0.5 - $cy
      $d = [math]::Sqrt($dx * $dx + $dy * $dy)
      if ($d -gt $r) { continue }
      if ($d -gt $r - 1.0) { Px $b $x $y $edge; continue }
      $a = [math]::Atan2($dy, $dx) + $ph + 8 * [math]::PI
      $t = ($a + 1.3 * $d / $r) / ([math]::PI / 3)
      $fi = [math]::Floor($t); $fr = $t - $fi
      $k = ([int]$fi) % 3
      $thr = [math]::Min(0.35, 0.5 / (1.05 * [math]::Max($d, 1.0)))
      if ($d -gt 1.2 -and ($fr -lt $thr -or $fr -gt (1 - $thr))) { $col = $seam } else { $col = $cols[$k] }
      Px $b $x $y $col
    }
  }
  Px $b ([int][math]::Round($cx - $r * 0.45)) ([int][math]::Round($cy - $r * 0.5)) (C '#ffffff')
}

# 風船。$str=$true なら下にひも。$wob でひもがゆれる
function Balloon($b, $cx, $cy, $rx, $ry, $base, $dark, $lite, $str, $wob) {
  $edge = Mix $dark (C '#000000') 0.4
  Ellipse $b $cx $cy ($rx + 0.9) ($ry + 0.9) $edge
  Ellipse $b $cx $cy $rx $ry $base
  for ($y = [int][math]::Floor($cy - $ry); $y -le [int][math]::Ceiling($cy + $ry); $y++) {
    for ($x = [int][math]::Floor($cx - $rx); $x -le [int][math]::Ceiling($cx + $rx); $x++) {
      $dx = ($x + 0.5 - $cx) / $rx; $dy = ($y + 0.5 - $cy) / $ry
      if ($dx * $dx + $dy * $dy -le 1 -and ($dx * 0.65 + $dy * 0.75) -gt 0.5) { Px $b $x $y $dark }
    }
  }
  Ellipse $b ($cx - $rx * 0.42) ($cy - $ry * 0.42) ($rx * 0.24) ($ry * 0.2) $lite
  Px $b ([int][math]::Round($cx - $rx * 0.55)) ([int][math]::Round($cy - $ry * 0.2)) $lite
  $ky = [int][math]::Round($cy + $ry + 0.5)
  Px $b ([int][math]::Round($cx)) $ky $edge
  Rect $b ([int][math]::Round($cx) - 1) ($ky + 1) 3 1 $dark
  if ($str) {
    for ($i = 0; $i -lt 12; $i++) { Px $b ([int][math]::Round($cx + [math]::Sin($i * 0.8 + $wob) * 1.3)) ($ky + 2 + $i) $gy2 }
  }
}

# ビットマップを回して貼る（$spx,$spy = 元絵の回転の中心、$dpx,$dpy = 貼る先の中心、$deg = 時計回り）
function RotBlit($dst, $src, $spx, $spy, $dpx, $dpy, $deg) {
  $a = $deg * [math]::PI / 180; $ca = [math]::Cos($a); $sa = [math]::Sin($a)
  $rad = [int][math]::Ceiling([math]::Sqrt($src.Width * $src.Width + $src.Height * $src.Height)) + 1
  for ($y = -$rad; $y -le $rad; $y++) { for ($x = -$rad; $x -le $rad; $x++) {
    $sx = $x * $ca + $y * $sa; $sy = -$x * $sa + $y * $ca
    $ix = [int][math]::Floor($spx + $sx + 0.5); $iy = [int][math]::Floor($spy + $sy + 0.5)
    if ($ix -ge 0 -and $iy -ge 0 -and $ix -lt $src.Width -and $iy -lt $src.Height) {
      $col = $src.GetPixel($ix, $iy)
      if ($col.A -gt 0) { Px $dst ($dpx + $x) ($dpy + $y) $col }
    }
  } }
}

# 的のピン 8x15（青と黄の帯）
function PinBmp() {
  $t = NewBmp 8 15
  Ascii $t 0 0 @(
    '..oooo..',
    '.owwwso.',
    '.owwwso.',
    '.owwwso.',
    '..owso..',
    '..obbo..',
    '..owso..',
    '.owwwso.',
    'owwwwwso',
    'owwwwwso',
    'oyyyyyyo',
    'owwwwwso',
    'owwwwwso',
    '.owwwso.',
    '..oooo..'
  ) @{ o = $ol2; w = $wh; s = (C '#cdd6ee'); b = $blu; y = $yel }
  return $t
}
# だるま 12x15
function DarumaBmp() {
  $t = NewBmp 12 15
  Blob $t 6 8 5.2 6 $red $ol
  Ellipse $t 6 5.8 3.7 3 $cream
  Px $t 4 5 $ink; Px $t 8 5 $ink; Px $t 4 4 $ol; Px $t 5 4 $ol; Px $t 7 4 $ol; Px $t 8 4 $ol
  Px $t 5 7 $ol; Px $t 6 7 $ol; Px $t 7 7 $ol; Px $t 3 7 $ol; Px $t 8 7 $ol
  Rect $t 2 10 8 1 $gold; Rect $t 3 11 6 1 $red2
  Px $t 4 3 $red3; Px $t 3 7 $red3
  return $t
}

# ====================================================================
# 看板 156x40（青い板に白い「バレーボール部」。両わきのバレーボールが回り、枠の電球が流れる。下にフリルのレース）4コマ
Sheet 'volleyball_sign.png' 156 40 4 {
  param($b, $ox, $f)
  # 下のレース（板より先に描く）
  for ($s = 0; $s -lt 26; $s++) {
    $cx = 3 + 6 * $s
    Ellipse $b ($ox + $cx) 34.5 3.4 4.4 $wh3
    Ellipse $b ($ox + $cx) 34.5 2.5 3.5 $wh
    if ($s % 2 -eq 0) { Px $b ($ox + $cx - 1) 36 $pk2; Px $b ($ox + $cx) 36 $pk }
  }
  # ひもを掛ける金具
  Rect $b ($ox + 20) 0 3 4 $w3; Rect $b ($ox + 133) 0 3 4 $w3
  # 板
  Rect $b $ox 4 156 30 $ol
  Rect $b ($ox + 1) 5 154 28 $blu2
  Rect $b ($ox + 2) 6 152 26 $blu
  Rect $b ($ox + 3) 7 150 24 $blu2
  Rect $b ($ox + 4) 8 148 22 $navy
  Rect $b ($ox + 1) 5 154 1 $blu3
  for ($x = 6; $x -lt 150; $x += 8) { Rect $b ($ox + $x) 8 1 22 $navy2 }
  Rect $b ($ox + 4) 8 148 1 $navy0; Rect $b ($ox + 4) 29 148 1 $navy0
  # 枠の電球
  for ($i = 0; $i -lt 24; $i++) {
    $lit = ((($i + $f) % 4) -lt 2)
    $c1 = if ($lit) { $yel3 } else { $yel2 }
    $x = 6 + 6 * $i
    Rect $b ($ox + $x) 6 2 1 $c1; Rect $b ($ox + $x) 31 2 1 $c1
  }
  foreach ($p in @(@(0, 4), @(155, 4), @(0, 33), @(155, 33))) { Clr $b ($ox + $p[0]) $p[1] }
  # 文字
  $tw = TextWidth 'バレーボール部' 16
  OutText $b 'バレーボール部' ($ox + [math]::Floor((156 - $tw - 1) / 2)) 11 16 $wh $ol2 $true
  Rect $b ($ox + 24) 28 108 1 $yel
  # 両わきのバレーボール（回る）
  VBall $b ($ox + 13) 19 5.5 ($f * [math]::PI / 6)
  VBall $b ($ox + 143) 19 5.5 (-$f * [math]::PI / 6)
}

# ====================================================================
# のぼり旗: 布の絵を一度描いて、1行ずつ横にずらして「はためく」4コマにする
function WaveCloth($b, $ox, $f, $t, $x0, $x1, $y0, $y1, $amp) {
  for ($y = $y0; $y -le $y1; $y++) {
    $off = [int][math]::Round($amp * [math]::Sin($y * 0.2 - $f * [math]::PI / 2))
    for ($x = $x0; $x -le $x1; $x++) {
      $c = $t.GetPixel($x, $y)
      if ($c.A -gt 0) { Px $b ($ox + $x + $off) $y $c }
    }
  }
}
# のぼり A 18x80（左の棒の足元が原点）: 青い布に白い「風船バレー」
Sheet 'volleyball_nobori_a.png' 18 80 4 {
  param($b, $ox, $f)
  $t = NewBmp 18 80
  Rect $t 2 5 14 66 $blu
  Rect $t 2 5 14 2 $navy
  Rect $t 2 5 1 66 $blu2; Rect $t 15 5 1 66 $blu2
  $i = 0
  foreach ($ch in @('風', '船', 'バ', 'レ', '｜')) { [void](TextPx $t $ch 3 (8 + 11 * $i) 11 $wh $false); $i++ }
  VBall $t 8.5 67 3.5 0.3
  for ($q = 0; $q -lt 14; $q++) { if ($q % 2 -eq 0) { Px $t (2 + $q) 71 $blu; Px $t (2 + $q) 72 $blu2 } }
  WaveCloth $b $ox $f $t 2 15 4 72 1.0
  $t.Dispose()
  Rect $b $ox 3 18 2 $w3; Rect $b $ox 3 18 1 $w2
  Rect $b $ox 3 2 77 $w2; Rect $b $ox 3 1 77 $w3
  Rect $b $ox 1 2 2 $w3
}
# のぼり B 16x92: 黄色い布に紺の「スパイクゲーム」（縦書き）
Sheet 'volleyball_nobori_b.png' 16 92 4 {
  param($b, $ox, $f)
  $t = NewBmp 16 92
  Rect $t 2 5 13 80 $yel
  Rect $t 2 5 13 2 $org
  Rect $t 2 5 1 80 $yel2; Rect $t 14 5 1 80 $yel2
  $i = 0
  foreach ($ch in @('ス', 'パ', 'イ', 'ク', 'ゲ', '｜', 'ム')) { [void](TextPx $t $ch 3 (8 + 11 * $i) 11 $navy $true); $i++ }
  VBall $t 8.5 81 3.5 0.9
  for ($q = 0; $q -lt 13; $q++) { if ($q % 2 -eq 0) { Px $t (2 + $q) 85 $yel; Px $t (2 + $q) 86 $yel2 } }
  WaveCloth $b $ox $f $t 2 14 4 86 1.0
  $t.Dispose()
  Rect $b $ox 3 16 2 $w3; Rect $b $ox 3 16 1 $w2
  Rect $b $ox 3 2 89 $w2; Rect $b $ox 3 1 89 $w3
  Rect $b $ox 1 2 2 $w3
}

# ====================================================================
# ネット 80x34（両わきの支柱・白い上のテープ・網目・アンテナ。足元が原点）
Sheet 'volleyball_net.png' 80 34 1 {
  param($b, $ox, $f)
  # 網目
  for ($y = 12; $y -lt 26; $y++) { for ($x = 4; $x -lt 76; $x++) {
    if ((($y - 12) % 3 -eq 0) -or (($x - 4) % 3 -eq 0)) { Px $b ($ox + $x) $y $(if ((($x + $y) % 5) -eq 0) { $wh2 } else { $wh }) }
  } }
  # 上のテープ・下のひも
  Rect $b ($ox + 4) 8 72 4 $ol; Rect $b ($ox + 4) 9 72 2 $wh; Rect $b ($ox + 4) 10 72 1 $wh2
  Rect $b ($ox + 4) 26 72 2 $ol; Rect $b ($ox + 4) 26 72 1 $wh2
  # 支柱
  foreach ($px0 in @(0, 76)) {
    Rect $b ($ox + $px0) 6 4 28 $ol
    Rect $b ($ox + $px0 + 1) 7 2 26 $gy3; Rect $b ($ox + $px0 + 1) 7 1 26 $wh
    Rect $b ($ox + $px0) 4 4 3 $ol; Rect $b ($ox + $px0 + 1) 5 2 1 $blu3
    Rect $b ($ox + $px0) 31 4 3 $ol; Rect $b ($ox + $px0 + 1) 31 2 1 $gy2
    # 青いクッション
    Rect $b ($ox + $px0 + 1) 16 2 8 $blu; Rect $b ($ox + $px0 + 1) 16 1 8 $blu3
  }
  # アンテナ（赤白のしま）
  foreach ($ax in @(6, 73)) {
    for ($y = 0; $y -lt 27; $y++) { Px $b ($ox + $ax) $y $(if ((($y / 3) -band 1) -eq 0) { $red } else { $wh }) }
  }
  Clr $b $ox 4; Clr $b ($ox + 79) 4
}

# ====================================================================
# 的の台 72x22（上の面は木、前は青い布に白いフリル。足元が原点）
Sheet 'volleyball_table.png' 72 22 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 72 19 $ol
  Rect $b ($ox + 1) 1 70 6 $w1; Rect $b ($ox + 1) 1 70 1 $cream; Rect $b ($ox + 1) 6 70 1 $w2
  Rect $b ($ox + 1) 8 70 11 $blu; Rect $b ($ox + 1) 8 70 1 $blu3; Rect $b ($ox + 1) 17 70 2 $blu2
  for ($x = 8; $x -lt 70; $x += 12) { Rect $b ($ox + $x) 9 1 8 $blu2 }
  VBall $b ($ox + 17) 13 3.8 0.2
  VBall $b ($ox + 55) 13 3.8 1.4
  for ($s = 0; $s -lt 12; $s++) {
    $cx = 3 + 6 * $s
    Ellipse $b ($ox + $cx) 18.5 3.4 3.4 $wh3
    Ellipse $b ($ox + $cx) 18.2 2.5 2.6 $wh
    if ($s % 2 -eq 0) { Px $b ($ox + $cx) 19 $pk }
  }
  Clr $b $ox 0; Clr $b ($ox + 71) 0
}

# ====================================================================
# 的いろいろ
# ピン（立っている） 8x15
Sheet 'volleyball_pin.png' 8 15 1 {
  param($b, $ox, $f)
  $t = PinBmp
  for ($y = 0; $y -lt 15; $y++) { for ($x = 0; $x -lt 8; $x++) { $c = $t.GetPixel($x, $y); if ($c.A -gt 0) { Px $b ($ox + $x) $y $c } } }
  $t.Dispose()
}
# 缶のピラミッド 21x22（6個）
function Can($b, $x, $y, $c1, $c2, $c3) {
  Rect $b $x $y 7 8 $ol
  Rect $b ($x + 1) ($y + 1) 5 1 $gy3
  Rect $b ($x + 1) ($y + 2) 5 5 $c1
  Rect $b ($x + 1) ($y + 4) 5 2 $c2
  Px $b ($x + 1) ($y + 2) $c3; Px $b ($x + 1) ($y + 3) $c3; Px $b ($x + 1) ($y + 4) $wh
}
Sheet 'volleyball_cans.png' 21 22 1 {
  param($b, $ox, $f)
  Can $b ($ox + 0) 14 $blu $wh $blu3
  Can $b ($ox + 7) 14 $yel $org $yel3
  Can $b ($ox + 14) 14 $pk $wh $pk3
  Can $b ($ox + 3) 7 $gn $yel $gn3
  Can $b ($ox + 10) 7 $blu $yel $blu3
  Can $b ($ox + 7) 0 $red $wh $red3
}
# だるま 12x15
Sheet 'volleyball_daruma.png' 12 15 1 {
  param($b, $ox, $f)
  $t = DarumaBmp
  for ($y = 0; $y -lt 15; $y++) { for ($x = 0; $x -lt 12; $x++) { $c = $t.GetPixel($x, $y); if ($c.A -gt 0) { Px $b ($ox + $x) $y $c } } }
  $t.Dispose()
}
# ねこのぬいぐるみの的 13x14（おなかが的）
Sheet 'volleyball_cat.png' 13 14 1 {
  param($b, $ox, $f)
  Ascii $b $ox 0 @(
    'o.........o..',
    'oo.......oo..',
    'oco.....oco..'
  ) @{ o = $ol; c = $pk }
  Blob $b ($ox + 6.5) 11 3.6 2.4 $cream $ol
  Blob $b ($ox + 6.5) 6 5 3.6 $org $ol
  Ellipse $b ($ox + 6.5) 7.2 3 2 $cream
  Px $b ($ox + 4) 5 $ink; Px $b ($ox + 9) 5 $ink; Px $b ($ox + 6) 7 $pk2; Px $b ($ox + 7) 7 $pk2
  Rect $b ($ox + 5) 9 3 1 $blu; Px $b ($ox + 6) 9 $yel
  Ellipse $b ($ox + 6.5) 11.4 1.9 1.4 $red
  Ellipse $b ($ox + 6.5) 11.4 1.0 0.7 $wh
  Rect $b ($ox + 3) 13 2 1 $ol; Rect $b ($ox + 8) 13 2 1 $ol
}
# たおれるピン（立つ → かたむく → ころがる → 起こされる）28x22 8コマ
Sheet 'volleyball_topple.png' 28 22 8 {
  param($b, $ox, $f)
  $deg = @(0, 0, 10, 32, 62, 90, 90, 40)[$f]
  $t = PinBmp
  $a = $deg * [math]::PI / 180
  $lift = [int][math]::Round(4 * [math]::Sin($a))
  RotBlit $b $t 3.5 14.5 ($ox + 8) (17 - $lift) $deg
  if ($f -eq 5) { Px $b ($ox + 17) 20 $wh; Px $b ($ox + 19) 19 $wh; Px $b ($ox + 21) 20 $wh }
  if ($f -eq 6) { Px $b ($ox + 22) 18 $wh2; Px $b ($ox + 25) 19 $wh2 }
  $t.Dispose()
}
# ころがったピン 17x8、ころがった缶 9x8、ころがっただるま 15x12、まる缶（ころころ）12x9 4コマ
Sheet 'volleyball_pin_lying.png' 17 9 1 {
  param($b, $ox, $f)
  $t = PinBmp
  RotBlit $b $t 3.5 7.5 ($ox + 8) 4 90
  $t.Dispose()
}
Sheet 'volleyball_daruma_lying.png' 15 13 1 {
  param($b, $ox, $f)
  $t = DarumaBmp
  RotBlit $b $t 6 7.5 ($ox + 7) 6 (-90)
  $t.Dispose()
}
Sheet 'volleyball_can_roll.png' 12 9 4 {
  param($b, $ox, $f)
  # 横向きの缶。ラベルの帯がまわる
  Rect $b ($ox + 2) 1 8 7 $ol
  Rect $b ($ox + 1) 2 1 5 $gy2; Rect $b ($ox + 10) 2 1 5 $gy2
  Rect $b ($ox + 3) 2 6 5 $blu
  Rect $b ($ox + 3) 2 6 1 $blu3
  $sx = 3 + ($f * 2) % 6
  Rect $b ($ox + $sx) 3 2 3 $wh
  Rect $b ($ox + 2) 2 1 5 $gy3
  Px $b ($ox + 0) (4 + ($f % 2)) $wh2; Px $b ($ox + 11) (3 + (($f + 1) % 2)) $wh2
}

# ====================================================================
# 景品の棚 74x56（3段・上から ★★★ ★★ ★。左は星の札、右に景品を置く）
Sheet 'volleyball_shelf.png' 74 56 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 74 56 $ol
  Rect $b ($ox + 3) 6 68 48 $sky
  for ($y = 8; $y -lt 54; $y += 4) { for ($x = 5 + (($y / 4) % 2) * 3; $x -lt 71; $x += 6) { Px $b ($ox + $x) $y $sky2 } }
  # 枠（白木）
  Rect $b ($ox + 1) 1 2 54 $wh2; Rect $b ($ox + 71) 1 2 54 $wh2
  Rect $b ($ox + 1) 1 1 54 $wh; Rect $b ($ox + 71) 1 1 54 $wh
  # 上のフリル（ピンクと白のしま、下はぎざぎざ）
  for ($x = 1; $x -lt 73; $x++) {
    $seg = [math]::Floor(($x - 1) / 5); $col = if ($seg % 2 -eq 0) { $pk } else { $wh }
    $col2 = if ($seg % 2 -eq 0) { $pk2 } else { $wh2 }
    Px $b ($ox + $x) 1 $col; Px $b ($ox + $x) 2 $col; Px $b ($ox + $x) 3 $col; Px $b ($ox + $x) 4 $col2
    $lx = ($x - 1) % 5; if ($lx -ge 1 -and $lx -le 3) { Px $b ($ox + $x) 5 $col2 }
  }
  Rect $b ($ox + 1) 1 72 1 $wh
  # 各段の板
  foreach ($by in @(24, 41, 54)) {
    Rect $b $ox $by 74 2 $w2; Rect $b $ox $by 74 1 $w1
    if ($by -lt 54) { Rect $b ($ox + 3) ($by + 2) 68 1 $sky2 }
  }
  Rect $b $ox 55 74 1 $ol
  # 星の札（上段 ★★★、中段 ★★、下段 ★）
  $starRows = @('..y..', '.yyy.', 'yyyyy', '.yyy.', '.y.y.')
  $plates = @(@(10, 3), @(29, 2), @(44, 1))
  foreach ($pl in $plates) {
    $py = $pl[0]; $ns = $pl[1]
    Rect $b ($ox + 3) $py 20 9 $ol; Rect $b ($ox + 4) ($py + 1) 18 7 $navy; Rect $b ($ox + 4) ($py + 1) 18 1 $navy2
    $sw = $ns * 5 + ($ns - 1)
    $sx0 = 4 + [math]::Floor((18 - $sw) / 2)
    for ($s = 0; $s -lt $ns; $s++) {
      Ascii $b ($ox + $sx0 + $s * 6) ($py + 2) $starRows @{ y = $gold }
      Px $b ($ox + $sx0 + $s * 6 + 2) ($py + 3) $yel3
    }
  }
  Clr $b $ox 0; Clr $b ($ox + 73) 0
}

# 箱（リボンつき）
function GiftBox($b, $x, $y, $w, $h, $c1, $c2, $rib, $bow) {
  Rect $b $x $y $w $h $ol
  Rect $b ($x + 1) ($y + 1) ($w - 2) ($h - 2) $c1
  Rect $b ($x + 1) ($y + 1) ($w - 2) 1 (Mix $c1 (C '#ffffff') 0.4)
  Rect $b ($x + 1) ($y + $h - 2) ($w - 2) 1 $c2
  $mx = $x + [math]::Floor($w / 2)
  Rect $b ($mx - 0) ($y + 1) 1 ($h - 2) $rib
  if ($w -ge 6) { Rect $b ($mx - 1) ($y + 1) 3 ($h - 2) $rib }
  $my = $y + [math]::Floor($h / 2)
  Rect $b ($x + 1) $my ($w - 2) 1 $rib
  if ($bow) { Px $b ($mx - 2) ($y - 1) $rib; Px $b ($mx - 1) ($y - 2) $rib; Px $b ($mx + 1) ($y - 2) $rib; Px $b ($mx + 2) ($y - 1) $rib; Px $b $mx ($y - 1) $ol }
}
# くま（景品）
function PlushBear($b, $x, $y, $s, $body, $dark) {
  # $s = 大きさ（幅）。左上 ($x,$y)
  $r = $s / 2.0
  Blob $b ($x + 1.9) ($y + 2.2) 1.8 1.8 $body $ol
  Blob $b ($x + $s - 2.9) ($y + 2.2) 1.8 1.8 $body $ol
  Blob $b ($x + $r) ($y + $s - 4) ($r - 2.2) 3.6 $body $ol
  Blob $b ($x + $r) ($y + 4.8) ($r - 1.2) 3.8 $body $ol
  Ellipse $b ($x + $r) ($y + 6.4) 2.2 1.6 $cream
  Px $b ($x + $r - 2) ($y + 4) $ink; Px $b ($x + $r + 1) ($y + 4) $ink; Px $b ($x + $r - 1) ($y + 6) $ink; Px $b ($x + $r) ($y + 6) $ink
  Rect $b ($x + $r - 2) ($y + $s - 5) 4 1 $blu
  Px $b ($x + 2) ($y + 1) $pk3; Px $b ($x + $s - 3) ($y + 1) $pk3
}
# 景品の列。上段（大）: くまと大きな箱とトロフィー 46x18
Sheet 'volleyball_prize_l.png' 46 18 1 {
  param($b, $ox, $f)
  PlushBear $b ($ox + 0) 2 15 $pk $pk2
  GiftBox $b ($ox + 17) 3 17 15 $blu $blu2 $yel $true
  # トロフィー
  $tx = $ox + 36
  Rect $b ($tx + 1) 0 9 7 $ol; Rect $b ($tx + 2) 1 7 5 $gold; Rect $b ($tx + 2) 1 2 5 $yel3; Rect $b ($tx + 2) 5 7 1 $yel2
  Px $b ($tx + 0) 2 $ol; Px $b ($tx + 0) 3 $gold; Px $b ($tx + 10) 2 $ol; Px $b ($tx + 10) 3 $gold
  Rect $b ($tx + 4) 7 3 4 $ol; Rect $b ($tx + 5) 7 1 4 $gold
  Rect $b ($tx + 2) 11 7 3 $ol; Rect $b ($tx + 3) 12 5 1 $blu; Rect $b ($tx + 2) 14 7 2 $ol; Rect $b ($tx + 3) 14 5 1 $blu2
}
# 中段（中）: 中くらいの箱とひよこ 46x14
Sheet 'volleyball_prize_m.png' 46 14 1 {
  param($b, $ox, $f)
  GiftBox $b ($ox + 1) 3 12 11 $pk $pk2 $wh $true
  GiftBox $b ($ox + 15) 4 11 10 $gn $gn2 $yel $true
  GiftBox $b ($ox + 28) 4 11 10 $yel $yel2 $red $false
  # ひよこ
  Blob $b ($ox + 42) 9 3.6 3.4 $yel $ol
  Px $b ($ox + 41) 8 $ink; Px $b ($ox + 44) 8 $ink; Rect $b ($ox + 42) 10 2 1 $org
  Px $b ($ox + 42) 4 $yel2; Px $b ($ox + 43) 4 $yel2
}
# 下段（小）: 小さな箱いろいろ 46x10
Sheet 'volleyball_prize_s.png' 30 10 1 {
  param($b, $ox, $f)
  GiftBox $b ($ox + 1) 2 8 8 $pk $pk2 $wh $false
  GiftBox $b ($ox + 11) 3 8 7 $blu $blu2 $yel $false
  GiftBox $b ($ox + 21) 2 8 8 $yel $yel2 $blu $false
}
# きらっと光る 9x9 4コマ
Sheet 'volleyball_twinkle.png' 9 9 4 {
  param($b, $ox, $f)
  $sp = C '#fff6b0'
  switch ($f) {
    0 { Px $b ($ox + 4) 4 $wh }
    1 { Px $b ($ox + 4) 3 $sp; Px $b ($ox + 3) 4 $sp; Px $b ($ox + 4) 4 $wh; Px $b ($ox + 5) 4 $sp; Px $b ($ox + 4) 5 $sp }
    2 {
      for ($i = 0; $i -lt 9; $i++) { Px $b ($ox + $i) 4 $sp; Px $b ($ox + 4) $i $sp }
      Rect $b ($ox + 3) 3 3 3 $wh; Px $b ($ox + 2) 2 $sp; Px $b ($ox + 6) 2 $sp; Px $b ($ox + 2) 6 $sp; Px $b ($ox + 6) 6 $sp
    }
    3 { Px $b ($ox + 4) 2 $sp; Px $b ($ox + 2) 4 $sp; Px $b ($ox + 4) 4 $wh; Px $b ($ox + 6) 4 $sp; Px $b ($ox + 4) 6 $sp; Px $b ($ox + 4) 3 $wh; Px $b ($ox + 3) 4 $wh; Px $b ($ox + 5) 4 $wh; Px $b ($ox + 4) 5 $wh }
  }
}

# ====================================================================
# 景品カウンター 72x22（上は木に白いランナー、前はピンクのギンガム、下に白いフリル）
Sheet 'volleyball_counter.png' 72 22 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 72 19 $ol
  Rect $b ($ox + 1) 1 70 6 $w1; Rect $b ($ox + 1) 1 70 1 $cream; Rect $b ($ox + 1) 6 70 1 $w2
  Rect $b ($ox + 8) 1 56 6 $wh; Rect $b ($ox + 8) 6 56 1 $wh2
  for ($x = 8; $x -lt 64; $x += 4) { Px $b ($ox + $x) 2 $pk3; Px $b ($ox + $x + 2) 4 $pk3 }
  for ($y = 8; $y -lt 19; $y++) { for ($x = 1; $x -lt 71; $x++) {
    $cx = [math]::Floor(($x - 1) / 3); $cy = [math]::Floor(($y - 8) / 3)
    $c1 = if (($cx + $cy) % 2 -eq 0) { $pk } else { $pk3 }
    if ((($cx % 2) -eq 0) -and (($cy % 2) -eq 0)) { $c1 = $pk2 }
    Px $b ($ox + $x) $y $c1
  } }
  Rect $b ($ox + 1) 8 70 1 $wh
  for ($s = 0; $s -lt 12; $s++) {
    $cx = 3 + 6 * $s
    Ellipse $b ($ox + $cx) 18.5 3.4 3.4 $wh3
    Ellipse $b ($ox + $cx) 18.2 2.5 2.6 $wh
    if ($s % 2 -eq 1) { Px $b ($ox + $cx) 19 $blu3 }
  }
  Clr $b $ox 0; Clr $b ($ox + 71) 0
}
# ベル 8x8
Sheet 'volleyball_bell.png' 8 8 1 {
  param($b, $ox, $f)
  Ascii $b $ox 0 @(
    '...oo...',
    '..oyyo..',
    '.oyyyyo.',
    '.oyyyyo.',
    'oyyyyyyo',
    'oooooooo',
    '.oyyyo..',
    '..ooo...'
  ) @{ o = $ol; y = $gold }
  Px $b ($ox + 3) 3 $yel3; Px $b ($ox + 3) 4 $yel3
}
# ====================================================================
# 風船（ふわふわ浮かぶ）16x30 6コマ。a=黄 b=ピンク c=青 d=緑
function BalloonSheet($name, $base, $dark, $lite) {
  Sheet $name 16 30 6 {
    param($b, $ox, $f)
    $bob = [int][math]::Round(1.6 * [math]::Sin($f * 2 * [math]::PI / 6))
    $sq = 0.35 * [math]::Cos($f * 2 * [math]::PI / 6)
    Balloon $b ($ox + 8) (9 + $bob) (6.2 - $sq * 0.5) (7.6 + $sq) $base $dark $lite $true ($f * 1.0)
  }
}
BalloonSheet 'volleyball_balloon_a.png' $yel $yel2 $yel3
BalloonSheet 'volleyball_balloon_b.png' $pk $pk2 $pk3
BalloonSheet 'volleyball_balloon_c.png' (C '#5aa8f0') $blu (C '#c4e4ff')
BalloonSheet 'volleyball_balloon_d.png' $gn $gn2 $gn3

# 風船バレーのボール（バレーボール柄の大きな風船）20x26 6コマ。ぽんぽん弾んで、ゆっくり回る
Sheet 'volleyball_ball.png' 20 26 6 {
  param($b, $ox, $f)
  $bob = @(0, -2, -3, -2, 0, 1)[$f]
  VBall $b ($ox + 10) (11 + $bob) 8.5 ($f * [math]::PI / 8)
  Rect $b ($ox + 9) (21 + $bob) 3 1 $ol2
  Px $b ($ox + 10) (22 + $bob) $ol2
  # 影の筋（ふくらみ）
  Px $b ($ox + 14) (6 + $bob) (C '#ffffff')
}

# ====================================================================
# バルーンのスタンド（ボールを置く台）14x30
Sheet 'volleyball_tee.png' 14 30 1 {
  param($b, $ox, $f)
  # 土台
  Ellipse $b ($ox + 7) 26.5 6.6 3 $ol
  Ellipse $b ($ox + 7) 26 5.8 2.4 $blu
  Ellipse $b ($ox + 7) 25.5 4.6 1.6 $blu3
  # 柱（青と白のしま）
  Rect $b ($ox + 5) 10 4 17 $ol
  for ($y = 11; $y -lt 26; $y++) { Rect $b ($ox + 6) $y 2 1 $(if (((($y - 11) / 3) -band 1) -eq 0) { $wh } else { $blu }) }
  # 受け皿
  Ellipse $b ($ox + 7) 7 6 3.4 $ol
  Ellipse $b ($ox + 7) 6.5 5.2 2.7 $yel
  Ellipse $b ($ox + 7) 6.2 3.6 1.7 $yel2
  Rect $b ($ox + 3) 5 1 1 $yel3
}

# ====================================================================
# 床: 体育館のコート 112x52（板張り・白線。ネットの位置は上から18本目あたり）
Sheet 'volleyball_court.png' 112 52 1 {
  param($b, $ox, $f)
  $pc1 = C '#f1c680'; $pc2 = C '#e8b672'; $seamc = C '#cf9857'
  for ($y = 0; $y -lt 52; $y++) { for ($x = 0; $x -lt 112; $x++) {
    $row = [math]::Floor($y / 4)
    $c1 = if ($row % 2 -eq 0) { $pc1 } else { $pc2 }
    if (($y % 4) -eq 3) { $c1 = $seamc }
    elseif ((($x + $row * 11) % 28) -eq 0) { $c1 = $seamc }
    Px $b ($ox + $x) $y $c1
  } }
  $ln = C '#fbf8f2'
  Rect $b ($ox + 3) 1 106 1 $ln
  Rect $b ($ox + 3) 49 106 1 $ln
  Rect $b ($ox + 3) 1 1 49 $ln; Rect $b ($ox + 108) 1 1 49 $ln
  Rect $b ($ox + 3) 17 106 2 $ln
  for ($x = 3; $x -lt 109; $x += 1) { if (($x % 6) -lt 4) { Px $b ($ox + $x) 33 $ln } }
  foreach ($p in @(@(0, 0), @(111, 0), @(0, 51), @(111, 51))) { Clr $b ($ox + $p[0]) $p[1] }
}
# 床: スパイクのマット 72x22（「スパイク」と矢印）
Sheet 'volleyball_mat.png' 72 22 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 72 22 $ol; Rect $b ($ox + 1) 1 70 20 $blu2; Rect $b ($ox + 2) 2 68 18 $blu
  Frame $b ($ox + 3) 3 66 16 $wh
  [void](TextPx $b 'スパイク' ($ox + 7) 5 11 $wh $true)
  Ascii $b ($ox + 56) 6 @(
    '...yy...',
    '..yyyy..',
    '.yyyyyy.',
    'yyyyyyyy',
    '..yyyy..',
    '..yyyy..',
    '..yyyy..',
    '..yyyy..'
  ) @{ y = $yel }
  foreach ($p in @(@(0, 0), @(71, 0), @(0, 21), @(71, 21))) { Clr $b ($ox + $p[0]) $p[1] }
}
# 床: 立て札がわりのマット「たおした かずで しょうひんが かわるよ！」 90x44
Sheet 'volleyball_rug.png' 90 44 1 {
  param($b, $ox, $f)
  Rect $b $ox 0 90 44 $ol; Rect $b ($ox + 1) 1 88 42 $navy; Frame $b ($ox + 2) 2 86 40 $wh
  Frame $b ($ox + 3) 3 84 38 $pk2
  $ln = @('たおした かずで', 'しょうひんが', 'かわるよ！')
  $cols = @($wh, $wh, $yel)
  for ($i = 0; $i -lt 3; $i++) {
    $w = TextWidth $ln[$i] 11
    $tx = if ($i -eq 2) { 9 } else { [math]::Floor((90 - $w) / 2) }
    [void](TextPx $b $ln[$i] ($ox + $tx) (6 + 12 * $i) 11 $cols[$i] $false)
  }
  $starRows = @('..y..', '.yyy.', 'yyyyy', '.yyy.', '.y.y.')
  foreach ($s in 0..2) { Ascii $b ($ox + 66 + $s * 6) 31 $starRows @{ y = $gold } }
  foreach ($p in @(@(0, 0), @(89, 0), @(0, 43), @(89, 43))) { Clr $b ($ox + $p[0]) $p[1] }
}

# ====================================================================
# かご（予備の風船）24x20
Sheet 'volleyball_basket.png' 24 20 1 {
  param($b, $ox, $f)
  Balloon $b ($ox + 6) 6 4.4 4.9 $yel $yel2 $yel3 $false 0
  Balloon $b ($ox + 12) 4.5 4.4 4.9 $pk $pk2 $pk3 $false 0
  Balloon $b ($ox + 18) 6 4.4 4.9 (C '#5aa8f0') $blu (C '#c4e4ff') $false 0
  Balloon $b ($ox + 9) 8 4.2 4.7 $gn $gn2 $gn3 $false 0
  Balloon $b ($ox + 15) 8.5 4.2 4.7 $red $red2 $red3 $false 0
  # かご（あみ目）
  $bw1 = C '#d9a05f'; $bw2 = C '#a8743c'
  Rect $b ($ox + 1) 11 22 9 $ol
  Rect $b ($ox + 2) 12 20 7 $bw1
  for ($y = 12; $y -lt 19; $y++) { for ($x = 2; $x -lt 22; $x++) { if ((($x + $y * 2) % 4) -eq 0) { Px $b ($ox + $x) $y $bw2 } } }
  Rect $b ($ox + 2) 12 20 1 (C '#efc98f')
  Rect $b ($ox + 2) 18 20 1 $bw2
  Clr $b ($ox + 1) 11; Clr $b ($ox + 22) 11; Clr $b ($ox + 1) 19; Clr $b ($ox + 22) 19
}
# もらったプレゼント 10x11
Sheet 'volleyball_gift.png' 10 11 1 {
  param($b, $ox, $f)
  GiftBox $b ($ox + 1) 3 8 8 $pk $pk2 $yel $true
}

# ====================================================================
# スパイクのエフェクト: ドンッ（当たった瞬間のひらめき）32x32 4コマ
Sheet 'volleyball_burst.png' 32 32 4 {
  param($b, $ox, $f)
  $cx = 16; $cy = 16
  $rr = @(4, 8, 12, 14)[$f]
  if ($f -le 2) {
    for ($i = 0; $i -lt 10; $i++) {
      $a = $i * [math]::PI / 5 + 0.3
      $r0 = $rr * 0.35; $r1 = if ($i % 2 -eq 0) { $rr } else { $rr * 0.65 }
      $x0 = [int][math]::Round($cx + $r0 * [math]::Cos($a)); $y0 = [int][math]::Round($cy + $r0 * [math]::Sin($a))
      $x1 = [int][math]::Round($cx + $r1 * [math]::Cos($a)); $y1 = [int][math]::Round($cy + $r1 * [math]::Sin($a))
      Line $b ($ox + $x0) $y0 ($ox + $x1) $y1 $yel
      if ($f -ge 1) { Px $b ($ox + $x1) $y1 $wh }
    }
    Ellipse $b ($ox + $cx) $cy ([math]::Max(1.5, $rr * 0.4)) ([math]::Max(1.5, $rr * 0.4)) $wh
    if ($f -ge 1) { Ellipse $b ($ox + $cx) $cy ($rr * 0.22) ($rr * 0.22) $yel3 }
  } else {
    for ($i = 0; $i -lt 10; $i++) {
      $a = $i * [math]::PI / 5 + 0.3
      $x1 = [int][math]::Round($cx + 14 * [math]::Cos($a)); $y1 = [int][math]::Round($cy + 14 * [math]::Sin($a))
      Px $b ($ox + $x1) $y1 $(if ($i % 2 -eq 0) { $yel } else { $wh })
      $x2 = [int][math]::Round($cx + 9 * [math]::Cos($a + 0.3)); $y2 = [int][math]::Round($cy + 9 * [math]::Sin($a + 0.3))
      Px $b ($ox + $x2) $y2 $yel3
    }
  }
}
# 飛んでいくボール 40x48 6コマ（右下から左上へ。最後は的にぶつかる）
Sheet 'volleyball_flight.png' 40 48 6 {
  param($b, $ox, $f)
  $sx = 35.0; $sy = 43.0; $ex = 6.0; $ey = 7.0
  for ($k = 3; $k -ge 1; $k--) {
    $tt = ($f - $k * 0.55) / 5.0
    if ($tt -lt 0) { continue }
    $px0 = $sx + ($ex - $sx) * $tt; $py0 = $sy + ($ey - $sy) * $tt - 9 * [math]::Sin([math]::PI * $tt)
    P $b ($ox + $px0) $py0 $(if ($k -eq 1) { $wh } else { $wh2 })
    if ($k -le 2) { P $b ($ox + $px0 + 1) $py0 $wh2 }
  }
  $tt = $f / 5.0
  $px1 = $sx + ($ex - $sx) * $tt; $py1 = $sy + ($ey - $sy) * $tt - 9 * [math]::Sin([math]::PI * $tt)
  if ($f -lt 5) {
    VBall $b ($ox + $px1) $py1 4.2 ($f * 1.1)
  } else {
    foreach ($a in 0..7) {
      $ang = $a * [math]::PI / 4
      Px $b ($ox + [int][math]::Round($ex + 5 * [math]::Cos($ang))) ([int][math]::Round($ey + 5 * [math]::Sin($ang))) $(if ($a % 2 -eq 0) { $yel } else { $wh })
    }
    Ellipse $b ($ox + $ex) $ey 2 2 $yel3
  }
}

# 三角旗のかざり 72x16（ひもにぶらさがった旗が、ゆらゆらゆれる）4コマ
Sheet 'volleyball_bunting.png' 72 16 4 {
  param($b, $ox, $f)
  $cols = @($blu, $yel, $wh, $pk)
  for ($x = 0; $x -lt 72; $x++) { Px $b ($ox + $x) ([int][math]::Round(1 + 3 * [math]::Sin([math]::PI * $x / 71))) $ol }
  for ($i = 0; $i -lt 9; $i++) {
    $x0 = 3 + $i * 8
    $sy = [int][math]::Round(1 + 3 * [math]::Sin([math]::PI * ($x0 + 3) / 71))
    $sw = [int][math]::Round(1.0 * [math]::Sin($f * [math]::PI / 2 + $i * 0.9))
    $c1 = $cols[$i % 4]
    for ($r = 0; $r -lt 7; $r++) {
      $half = [math]::Floor((6 - $r) / 2)
      for ($x = $x0 + 1 + [math]::Floor($r / 2); $x -le $x0 + 5 - [math]::Floor($r / 2); $x++) { Px $b ($ox + $x + [int][math]::Round($sw * $r / 6.0)) ($sy + 1 + $r) $c1 }
    }
    Px $b ($ox + $x0 + 3 + $sw) ($sy + 7) (Mix $c1 (C '#000000') 0.3)
  }
}

# ====================================================================
# メイド衣装（人物の胴と頭にかぶせる）96x64。人物と同じ位置・同じ向きで重ねる。
# 黒いワンピース・白いエプロン（ピンクのリボン）・すその白いフリル・頭の白いフリルのカチューシャ。
# 人物の idle は体が 1px 上下するので、胴は動かない足元(y38)に合わせ、カチューシャは髪の中ほどに置く
function MaidSheet($name, $bandX0, $bandX1, $bandY) {
  Sheet $name 96 64 1 {
    param($b, $ox, $f)
    Ascii $b ($ox + 44) 35 @(
      '.wkppkw.',
      '.kgwwkk.',
      'kkkwwkkk',
      'iwiwiwiw'
    ) @{ k = $bk; g = $bk2; w = $wh; i = $wh2; p = $pk }
    # カチューシャ
    for ($x = $bandX0; $x -le $bandX1; $x++) {
      $c1 = if ($x -eq $bandX0 -or $x -eq $bandX1) { $wh2 } else { $wh }
      Px $b ($ox + $x) $bandY $c1
      if ((($x - $bandX0) % 2) -eq 0) { Px $b ($ox + $x) ($bandY + 1) $wh2 }
    }
    Px $b ($ox + $bandX1) $bandY $pk
  }
}
MaidSheet 'volleyball_maid_short.png' 45 51 25
MaidSheet 'volleyball_maid_long.png' 43 51 25
MaidSheet 'volleyball_maid_mop.png' 45 53 26
MaidSheet 'volleyball_maid_bowl.png' 44 52 26
