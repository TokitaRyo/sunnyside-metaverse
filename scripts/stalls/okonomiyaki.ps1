# お好み焼き屋台の専用ドット絵（看板・のぼり・提灯・メニュー・鉄板・お皿・カウンター・屋根・柱）を作る。
#   powershell -File scripts/gen-okonomiyaki-stall.ps1
# 出力: client/public/brand/stall/*.png（原点は各スプライトの足元。配置は scripts/build-okonomiyaki-stall.mjs）
# 文字(日本語)は Windows の MS Gothic を、アンチエイリアス無し(1bit)でドットにして貼る。Windows 専用。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。文字や色を変えたいときはここを直して作り直す。
Add-Type -AssemblyName System.Drawing
$out = "client/public/brand/stall"
New-Item -ItemType Directory -Force $out | Out-Null

function C($h) { [System.Drawing.ColorTranslator]::FromHtml($h) }
function NewBmp($w, $h) { New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb) }
function Px($b, $x, $y, $col) { if ($x -ge 0 -and $y -ge 0 -and $x -lt $b.Width -and $y -lt $b.Height) { $b.SetPixel([int]$x, [int]$y, $col) } }
function Rect($b, $x, $y, $w, $h, $col) { for ($j = 0; $j -lt $h; $j++) { for ($i = 0; $i -lt $w; $i++) { Px $b ($x + $i) ($y + $j) $col } } }
function Frame($b, $x, $y, $w, $h, $col) {
  for ($i = 0; $i -lt $w; $i++) { Px $b ($x + $i) $y $col; Px $b ($x + $i) ($y + $h - 1) $col }
  for ($j = 0; $j -lt $h; $j++) { Px $b $x ($y + $j) $col; Px $b ($x + $w - 1) ($y + $j) $col }
}
function Ellipse($b, $cx, $cy, $rx, $ry, $col) {
  for ($y = [math]::Floor($cy - $ry); $y -le [math]::Ceiling($cy + $ry); $y++) {
    for ($x = [math]::Floor($cx - $rx); $x -le [math]::Ceiling($cx + $rx); $x++) {
      $dx = ($x + 0.5 - $cx) / $rx; $dy = ($y + 0.5 - $cy) / $ry
      if ($dx * $dx + $dy * $dy -le 1) { Px $b $x $y $col }
    }
  }
}
function Clear($b, $x, $y) { Px $b $x $y ([System.Drawing.Color]::FromArgb(0, 0, 0, 0)) }

# 日本語の文字をドットで貼る（$bold なら横にずらして2回描いて太くする）
function TextPx($b, $text, $x, $y, $px, $col, $bold) {
  $font = New-Object System.Drawing.Font("MS Gothic", $px, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $tmp = NewBmp ($px * ($text.Length + 2)) ($px * 2)
  $g = [System.Drawing.Graphics]::FromImage($tmp)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  $g.DrawString($text, $font, [System.Drawing.Brushes]::White, 0, 0, $fmt)
  $w = [math]::Ceiling($g.MeasureString($text, $font, 10000, $fmt).Width)
  $g.Dispose()
  for ($j = 0; $j -lt $tmp.Height; $j++) {
    for ($i = 0; $i -lt $tmp.Width; $i++) {
      if ($tmp.GetPixel($i, $j).A -ge 128) {
        Px $b ($x + $i) ($y + $j) $col
        if ($bold) { Px $b ($x + $i + 1) ($y + $j) $col }
      }
    }
  }
  $tmp.Dispose(); $font.Dispose()
  return $w
}
function TextWidth($text, $px) {
  $font = New-Object System.Drawing.Font("MS Gothic", $px, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $tmp = NewBmp 4 4
  $g = [System.Drawing.Graphics]::FromImage($tmp)
  $w = [math]::Ceiling($g.MeasureString($text, $font, 10000, [System.Drawing.StringFormat]::GenericTypographic).Width)
  $g.Dispose(); $tmp.Dispose(); $font.Dispose()
  return $w
}
function Save($b, $name) { $b.Save((Join-Path (Resolve-Path $out) $name), [System.Drawing.Imaging.ImageFormat]::Png); Write-Host "wrote $out/$name ($($b.Width)x$($b.Height))"; $b.Dispose() }

# 色
$ol = C '#4a2420'; $w1 = C '#eab382'; $w2 = C '#c97f4f'; $w3 = C '#8c4a32'
$red = C '#d62f3a'; $red2 = C '#9d1d2c'; $red3 = C '#f25b5b'
$white = C '#f6f3ee'; $cream = C '#e9dcc0'; $gold = C '#f2b544'
$iron0 = C '#1f1f27'; $iron1 = C '#2e2e38'; $iron2 = C '#4b4b58'; $iron3 = C '#6a6a78'
$dough = C '#d89a4e'; $sauce = C '#6b2f17'; $sauce2 = C '#8a4220'; $mayo = C '#fff3d2'; $nori = C '#3fae4a'; $bonito = C '#e8c9a0'
$board = C '#2f5a45'; $chalk = C '#f4f2e8'

# ---- 看板（屋根の上に掲げる）96x30。赤い板に金のふち、白い大きな文字
$b = NewBmp 96 30
Rect $b 14 0 2 5 $w3; Rect $b 80 0 2 5 $w3
Rect $b 0 4 96 26 $ol; Rect $b 1 5 94 24 $w2; Rect $b 3 7 90 20 $red
Frame $b 4 8 88 18 $gold
foreach ($p in @(@(0, 4), @(95, 4), @(0, 29), @(95, 29))) { Clear $b $p[0] $p[1] }
Rect $b 3 7 90 1 $red3
$tw = TextWidth 'お好み焼き' 14
[void](TextPx $b 'お好み焼き' ([math]::Floor((96 - $tw) / 2)) 10 14 $white $true)
Save $b 'okonomi_sign.png'

# ---- のぼり旗 16x78（左の棒の足元が原点）。赤い布に白い縦書き
$b = NewBmp 16 78
Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 76 $w2; Rect $b 0 2 1 76 $w3
Rect $b 2 4 13 66 $red; Rect $b 2 4 1 66 $red2; Rect $b 14 4 1 66 $red2
for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 70 $red; Px $b (2 + $i) 71 $red2 } }
$chars = 'お', '好', 'み', '焼', 'き'
for ($i = 0; $i -lt 5; $i++) { [void](TextPx $b $chars[$i] 3 (6 + 12 * $i) 11 $white $false) }
Save $b 'okonomi_nobori.png'

# ---- 提灯 12x22
$b = NewBmp 12 22
Rect $b 5 0 1 4 $ol
Rect $b 3 4 6 2 $ol
Ellipse $b 6 11.5 5.5 6 $red
Rect $b 2 8 8 1 $red2; Rect $b 1 11 10 1 $red2; Rect $b 2 14 8 1 $red2
Rect $b 3 7 2 6 $red3
Rect $b 3 17 6 2 $ol
Rect $b 5 19 2 3 $gold
Save $b 'okonomi_lantern.png'

# ---- メニュー（黒板の立て看板）54x50。足元が原点
$b = NewBmp 54 50
Rect $b 0 0 54 44 $ol; Rect $b 1 1 52 42 $w2; Rect $b 3 3 48 38 $board
Rect $b 6 44 3 6 $w3; Rect $b 45 44 3 6 $w3
Rect $b 6 44 1 6 $w2; Rect $b 45 44 1 6 $w2
# 品書きの中身(味・種類)は書かない。文字は「メニュー」だけ。何の店かは大きな皿の絵で伝える
$w = TextWidth 'メニュー' 11
[void](TextPx $b 'メニュー' ([math]::Floor((54 - $w) / 2)) 4 11 (C '#ffe14a') $true)
Ellipse $b 27 31 20 9 (C '#aeb4c8'); Ellipse $b 27 30 20 8.6 $white
Ellipse $b 27 29 16 7 $sauce; Ellipse $b 27 28 15 6 $dough; Ellipse $b 27 28 14 5.4 $sauce2
for ($i = -11; $i -le 11; $i++) { Px $b (27 + $i) (25 + (($i + 11) % 2) * 2) $mayo; Px $b (27 + $i) (28 + (($i + 11) % 2) * 2) $mayo }
foreach ($d in @(@(-9, 27), @(-4, 30), @(2, 26), @(7, 29), @(10, 27), @(-1, 32), @(5, 32), @(-7, 31))) { Px $b (27 + $d[0]) $d[1] $nori; Px $b (28 + $d[0]) $d[1] $nori }
foreach ($d in @(@(-5, 26), @(4, 28), @(0, 29), @(8, 31))) { Px $b (27 + $d[0]) $d[1] $bonito }
Save $b 'okonomi_menu.png'

# ---- 鉄板（焼きたてのお好み焼き2枚とコテ）52x34。足元が原点
$b = NewBmp 52 34
Rect $b 0 20 52 14 $iron1; Rect $b 0 20 52 2 $iron2; Rect $b 0 32 52 2 $iron0
Rect $b 4 28 3 3 $red; Rect $b 14 28 3 3 $red; Rect $b 24 28 3 3 $red
Rect $b 2 8 48 13 $iron0; Rect $b 3 9 46 11 $iron2; Rect $b 3 9 46 1 $iron3
foreach ($c in @(@(15, 14), @(35, 14))) {
  $cx = $c[0]; $cy = $c[1]
  Ellipse $b $cx $cy 9 5 $sauce
  Ellipse $b $cx ($cy - 1) 8 4 $dough
  Ellipse $b $cx ($cy - 1) 7 3.5 $sauce2
  for ($i = -5; $i -le 5; $i++) { Px $b ($cx + $i) ($cy - 2 + (($i + 5) % 2) * 2) $mayo }
  foreach ($d in @(@(-4, -1), @(2, 0), @(-1, 1), @(4, -2), @(-3, 1))) { Px $b ($cx + $d[0]) ($cy + $d[1]) $nori }
  Px $b ($cx - 2) ($cy - 3) $bonito; Px $b ($cx + 3) ($cy - 1) $bonito; Px $b ($cx + 1) ($cy - 3) $bonito
}
Rect $b 44 12 6 2 $iron3; Rect $b 49 12 3 2 $w2
Save $b 'okonomi_teppan.png'

# ---- お好み焼きの皿 16x10
$b = NewBmp 16 10
Ellipse $b 8 6 8 4 (C '#aeb4c8'); Ellipse $b 8 5.5 8 3.8 $white
Ellipse $b 8 5 6 3 $sauce; Ellipse $b 8 4.5 5.5 2.6 $dough; Ellipse $b 8 4.5 5 2.3 $sauce2
for ($i = -4; $i -le 4; $i++) { Px $b (8 + $i) (3 + (($i + 4) % 2)) $mayo }
foreach ($d in @(@(-3, 5), @(1, 4), @(3, 5), @(-1, 6))) { Px $b (8 + $d[0]) $d[1] $nori }
Px $b 6 3 $bonito; Px $b 10 4 $bonito
Save $b 'okonomi_plate.png'

# ---- カウンター 104x24。上の面(明るい木)と、赤い布の前掛け
$b = NewBmp 104 24
Rect $b 0 0 104 24 $ol
Rect $b 1 1 102 8 $w1; Rect $b 1 1 102 1 $cream; Rect $b 1 8 102 1 $w2
Rect $b 1 9 102 14 $w2
for ($x = 13; $x -lt 102; $x += 13) { Rect $b $x 9 1 6 $w3 }
Rect $b 3 12 98 9 $red
Rect $b 3 12 98 1 $red3
for ($x = 3; $x -lt 101; $x += 7) { Rect $b $x 13 1 8 $red2 }
for ($x = 3; $x -lt 101; $x++) { if ((($x - 3) % 14) -lt 7) { Px $b $x 21 $red2 } else { Clear $b $x 21; Px $b $x 20 $red2 } }
Rect $b 0 23 104 1 $ol
foreach ($p in @(@(0, 0), @(103, 0))) { Clear $b $p[0] $p[1] }
Save $b 'okonomi_counter.png'

# ---- 屋根の日よけ（赤白のしま）108x24。手前のへりはぎざぎざ
$b = NewBmp 108 24
for ($y = 0; $y -lt 10; $y++) {
  $inset = [int](9 - $y)
  for ($x = $inset; $x -lt 108 - $inset; $x++) { $stripe = [math]::Floor($x / 9) % 2; Px $b $x $y $(if ($stripe -eq 0) { $red } else { $white }) }
}
for ($x = 0; $x -lt 108; $x++) { Px $b $x 9 $red2 }
for ($y = 10; $y -lt 22; $y++) {
  for ($x = 0; $x -lt 108; $x++) {
    $stripe = [math]::Floor($x / 9) % 2
    $col = if ($stripe -eq 0) { $red } else { $white }
    $mid = ($x % 9) - 4; $r = 4.5
    if ($y -ge 17) {
      $dy = $y - 17; $lim = [math]::Sqrt([math]::Max(0, 25 - $mid * $mid))
      if ($dy -gt $lim) { continue }
    }
    Px $b $x $y $col
  }
}
for ($x = 0; $x -lt 108; $x++) { if ((($x / 9) -as [int]) % 2 -eq 0) { Px $b $x 10 $red3 } }
Rect $b 0 10 1 8 $red2; Rect $b 107 10 1 8 $red2
Save $b 'okonomi_roof.png'

# ---- 柱 6x48（足元が原点）
$b = NewBmp 6 48
Rect $b 0 0 6 48 $ol; Rect $b 1 0 4 47 $w2; Rect $b 1 0 1 47 $w1; Rect $b 4 0 1 47 $w3
Save $b 'okonomi_post.png'
