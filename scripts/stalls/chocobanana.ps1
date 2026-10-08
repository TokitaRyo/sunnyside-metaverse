# チョコバナナ屋台の専用ドット絵を作る（看板・のぼり・屋根・柱・カウンター・チョコバナナのスタンド・チョコ鍋・スプレー瓶・バナナ箱・メニュー・風船・キラキラ）。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/chocobanana.ps1
# 出力: client/public/brand/stall/chocobanana_*.png（原点は各スプライトの足元。配置は scripts/stalls/chocobanana.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル。色や文字を変えたいときはここを直して作り直す。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色
$ol = C '#4a2420'; $w1 = C '#eab382'; $w2 = C '#c97f4f'; $w3 = C '#8c4a32'
$pink = C '#e8537f'; $pink2 = C '#b93a62'; $pinkL = C '#f58aa8'; $pinkLL = C '#fdc6d6'
$cream = C '#fff3d9'; $white = C '#fffaf0'; $yel = C '#f7d84a'; $yel2 = C '#d9a82a'; $yelL = C '#fff08a'
$mint = C '#6fd3a8'; $sky = C '#5ab9f2'; $orange = C '#ff9a3c'; $gold = C '#f2b544'
$choc = C '#6b3420'; $chocD = C '#4a2420'
$mil = C '#8a4a2a'; $milhi = C '#b5703f'; $milsh = C '#5e3019'
$strw = C '#f58aa8'; $strwhi = C '#ffc2d2'; $strwsh = C '#cf5f85'
$whc = C '#fff1d6'; $whchi = C '#ffffff'; $whcsh = C '#e0c9a0'
$drk = C '#5a2a1c'; $drkhi = C '#7e4730'; $drksh = C '#3e1c12'
$wood = C '#d9a95f'; $wood2 = C '#a8743a'
$rainbow = @((C '#ff5c8a'), (C '#ffe14a'), (C '#5ac8fa'), (C '#6fe3a0'), (C '#ffffff'), (C '#ff9a3c'))
$arazan = @((C '#ffffff'), (C '#dfe8f2'), (C '#f2b544'), (C '#ffffff'))
$almond = @((C '#e6c48c'), (C '#c8a066'), (C '#f3dcae'))
$iron0 = C '#1f1f27'; $iron1 = C '#2e2e38'; $iron2 = C '#4b4b58'
$tr = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# ---- 道具
# チョコバナナ1本（幅7・本体16 + 串3）。$k = @{base;hi;sh;dots;seed;half;pen}。$flip なら串が上（鍋に浸した絵用）
function Banana($b, $x, $y, $k, $flip) {
  $rnd = New-Object System.Random([int]$k.seed)
  $ins = @(2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2)
  $top = if ($flip) { $y + 3 } else { $y }
  for ($r = 0; $r -lt 16; $r++) {
    $in = $ins[$r]
    $ry = if ($flip) { 15 - $r } else { $r }
    $yellowPart = ($k.half -and $ry -ge 10)
    for ($c = $in; $c -le 6 - $in; $c++) {
      $edge = ($c -eq $in) -or ($c -eq 6 - $in) -or ($r -eq 0) -or ($r -eq 15)
      if ($edge) { $col = $ol }
      else {
        if ($yellowPart) { $col = $yel; if ($c -eq 1) { $col = $yelL }; if ($c -eq 5) { $col = $yel2 } }
        else {
          $col = $k.base
          if ($c -eq 1 -and $ry -ge 2 -and $ry -le 12) { $col = $k.hi }
          if ($c -eq 5) { $col = $k.sh }
          if ($rnd.NextDouble() -lt 0.22 -and $k.dots.Count -gt 0) { $col = $k.dots[$rnd.Next($k.dots.Count)] }
        }
      }
      Px $b ($x + $c) ($top + $r) $col
    }
  }
  if ($k.pen -ne $null) {
    for ($r = 3; $r -le 12; $r++) {
      $t = $r % 8; $c = if ($t -le 4) { 1 + $t } else { 1 + (8 - $t) }
      $ry = if ($flip) { 15 - $r } else { $r }
      Px $b ($x + $c) ($top + $r) $k.pen
    }
  }
  for ($s = 0; $s -lt 3; $s++) { $sy = if ($flip) { $y + $s } else { $y + 16 + $s }; Px $b ($x + 3) $sy $wood; }
}
# 曲がったバナナ（黄色）。$tip 先端、$stem 軸の色
function Crescent($b, $x0, $y0, $x1, $y1, $bulge, $col, $col2, $tip, $stem) {
  $dx = $x1 - $x0; $dy = $y1 - $y0; $len = [math]::Sqrt($dx * $dx + $dy * $dy); $nx = -$dy / $len; $ny = $dx / $len
  foreach ($pass in 0, 1) {
    for ($i = 0; $i -le 30; $i++) {
      $t = $i / 30; $s = [math]::Sin([math]::PI * $t) * $bulge
      $x = [math]::Round($x0 + $dx * $t + $nx * $s); $y = [math]::Round($y0 + $dy * $t + $ny * $s)
      if ($pass -eq 0) { Rect $b ($x + 1) ($y + 1) 2 2 $col2 } else { Rect $b $x $y 2 2 $col }
    }
  }
  Rect $b ([math]::Round($x1)) ([math]::Round($y1)) 2 2 $tip
  Rect $b ([math]::Round($x0)) ([math]::Round($y0)) 2 2 $stem
}
function Confetti($b, $pts) { $i = 0; foreach ($p in $pts) { Rect $b $p[0] $p[1] 2 1 $rainbow[$i % $rainbow.Count]; $i++ } }

$kinds = @(
  @{ base = $mil; hi = $milhi; sh = $milsh; dots = $rainbow; seed = 11; half = $false; pen = $null },
  @{ base = $strw; hi = $strwhi; sh = $strwsh; dots = $arazan; seed = 22; half = $false; pen = $null },
  @{ base = $whc; hi = $whchi; sh = $whcsh; dots = $rainbow; seed = 33; half = $false; pen = $null },
  @{ base = $drk; hi = $drkhi; sh = $drksh; dots = @(); seed = 44; half = $false; pen = (C '#ff7ea6') },
  @{ base = $mil; hi = $milhi; sh = $milsh; dots = $almond; seed = 55; half = $true; pen = $null },
  @{ base = $strw; hi = $strwhi; sh = $strwsh; dots = @((C '#5ac8fa'), (C '#ffffff'), (C '#f2b544')); seed = 66; half = $false; pen = $null },
  @{ base = $whc; hi = $whchi; sh = $whcsh; dots = @((C '#ff5c8a'), (C '#ff5c8a'), (C '#ffe14a')); seed = 77; half = $true; pen = $null }
)

# ---- 看板 104x32。ピンクの板、上にチョコがとろ〜り、白い文字
$b = NewBmp 104 32
Rect $b 16 0 2 6 $w3; Rect $b 86 0 2 6 $w3
Rect $b 0 5 104 27 $ol; Rect $b 1 6 102 25 $pinkL; Rect $b 3 8 98 21 $pink
Frame $b 3 8 98 21 $cream
foreach ($p in @(@(0, 5), @(103, 5), @(0, 31), @(103, 31))) { Clear $b $p[0] $p[1] }
# とろけるチョコ（内側の上）
Rect $b 4 9 96 3 $choc; Rect $b 4 9 96 1 $milhi
$drips = @(@(8, 6), @(15, 4), @(23, 7), @(31, 4), @(41, 5), @(50, 3), @(58, 6), @(67, 4), @(76, 7), @(84, 4), @(92, 6))
foreach ($d in $drips) { Rect $b $d[0] 12 2 ($d[1] - 3) $choc; Rect $b ($d[0] - 1) (12 + $d[1] - 4) 4 2 $choc }
Rect $b 4 25 96 3 $pink2
$tw = TextWidth 'チョコバナナ' 13
[void](TextPx $b 'チョコバナナ' ([math]::Floor((104 - $tw) / 2) + 1) 14 13 $chocD $true)
[void](TextPx $b 'チョコバナナ' ([math]::Floor((104 - $tw) / 2)) 13 13 $white $true)
Confetti $b @(@(8, 20), @(12, 25), @(7, 26), @(16, 22), @(90, 22), @(95, 26), @(88, 26), @(93, 18))
Save $b 'chocobanana_sign.png'

# ---- のぼり旗 16x82（左の棒の足元が原点）。ピンク版と黄色版
function Nobori($name, $cloth, $clothD, $textCol, $drip) {
  $b = NewBmp 16 82
  Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 80 $w2; Rect $b 0 2 1 80 $w3
  Rect $b 2 4 13 74 $cloth; Rect $b 2 4 1 74 $clothD; Rect $b 14 4 1 74 $clothD
  Rect $b 2 4 13 2 $drip
  foreach ($d in @(@(4, 5), @(8, 7), @(12, 4))) { Rect $b $d[0] 6 2 ($d[1] - 4) $drip }
  for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 78 $cloth; Px $b (2 + $i) 79 $clothD } }
  $chars = 'チ', 'ョ', 'コ', 'バ', 'ナ', 'ナ'
  for ($i = 0; $i -lt 6; $i++) { [void](TextPx $b $chars[$i] 3 (9 + 11 * $i) 11 $textCol $false) }
  Save $b $name
}
Nobori 'chocobanana_nobori_pink.png' $pink $pink2 $white $choc
Nobori 'chocobanana_nobori_yellow.png' $yel $yel2 $chocD $choc

# ---- 屋根の日よけ 108x24。ピンクと白のしまの屋根、手前はカラフルなペナント
$b = NewBmp 108 24
for ($y = 0; $y -lt 10; $y++) {
  $inset = [int](9 - $y)
  for ($x = $inset; $x -lt 108 - $inset; $x++) { $stripe = [math]::Floor($x / 9) % 2; Px $b $x $y $(if ($stripe -eq 0) { $pinkL } else { $white }) }
}
for ($x = 0; $x -lt 108; $x++) { Px $b $x 9 $w3; Px $b $x 10 $w2 }
for ($x = 0; $x -lt 108; $x++) { if ((($x / 9) -as [int]) % 2 -eq 0) { Px $b $x 8 $pink } }
$pcols = @($pink, $yel, $mint, $sky)
for ($i = 0; $i -lt 12; $i++) {
  $col = $pcols[$i % 4]
  for ($dy = 0; $dy -lt 12; $dy++) {
    $half = 4.6 * (1 - $dy / 12.0)
    for ($x = 0; $x -lt 9; $x++) {
      if ([math]::Abs($x - 4) -le $half) { Px $b ($i * 9 + $x) (11 + $dy) $col }
    }
  }
  for ($dy = 0; $dy -lt 10; $dy++) { $half = 4.6 * (1 - $dy / 12.0); $xr = [int]([math]::Floor(4 + $half)); Px $b ($i * 9 + $xr) (11 + $dy) $ol }
}
Rect $b 0 11 108 1 $ol
Save $b 'chocobanana_roof.png'

# ---- 柱 6x48（足元が原点）。ピンクと白のキャンディしま
$b = NewBmp 6 48
Rect $b 0 0 6 48 $ol
for ($y = 0; $y -lt 47; $y++) { for ($x = 1; $x -le 4; $x++) { $s = [math]::Floor(($y + $x * 2) / 4) % 2; Px $b $x $y $(if ($s -eq 0) { $pinkL } else { $white }) } }
Save $b 'chocobanana_post.png'

# ---- カウンター 104x24。茶色の天板と、カラースプレーの水玉の前板
$b = NewBmp 104 24
Rect $b 0 0 104 24 $ol
Rect $b 1 1 102 8 $w1; Rect $b 1 1 102 1 $cream; Rect $b 1 8 102 1 $w2
Rect $b 1 9 102 14 $pink
Rect $b 1 9 102 1 $pink2
for ($x = 2; $x -lt 102; $x += 6) { Rect $b $x 10 4 1 $white; Px $b ($x + 1) 11 $white; Px $b ($x + 2) 11 $white }
$i = 0
for ($y = 14; $y -lt 22; $y += 4) {
  for ($x = 4 + (($y / 4) % 2) * 3; $x -lt 100; $x += 6) { Rect $b $x $y 2 1 $rainbow[$i % $rainbow.Count]; $i++ }
}
Rect $b 0 23 104 1 $ol
foreach ($p in @(@(0, 0), @(103, 0))) { Clear $b $p[0] $p[1] }
Save $b 'chocobanana_counter.png'

# ---- チョコバナナのスタンド（発泡スチロールの台に5本）42x28
function Rack($name, $order) {
  $b = NewBmp 34 28
  # 台（上の面は発泡スチロール、前はピンク）
  Rect $b 0 19 34 9 $ol
  Rect $b 1 20 32 4 $cream; Rect $b 1 20 32 1 $white
  Rect $b 1 24 32 3 $pinkL; Rect $b 1 24 32 1 $pinkLL
  for ($x = 3; $x -lt 32; $x += 6) { Px $b $x 26 $white }
  for ($i = 0; $i -lt 4; $i++) { $bx = 1 + 8 * $i; Rect $b ($bx + 2) 21 3 2 (C '#8a7a66') }
  for ($i = 0; $i -lt 4; $i++) { Banana $b (1 + 8 * $i) 0 $kinds[$order[$i]] $false }
  foreach ($p in @(@(0, 19), @(33, 19), @(0, 27), @(33, 27))) { Clear $b $p[0] $p[1] }
  Save $b $name
}
Rack 'chocobanana_rack_a.png' @(0, 1, 2, 4)
Rack 'chocobanana_rack_b.png' @(5, 3, 6, 0)

# ---- チョコ鍋（とけたチョコにバナナをつけている）24x32
$b = NewBmp 24 32
# コンロ
Rect $b 4 27 16 5 $iron1; Rect $b 4 27 16 1 $iron2; Rect $b 4 31 16 1 $iron0
Rect $b 6 29 2 2 $orange; Rect $b 11 29 2 2 $orange; Rect $b 16 29 2 2 $orange
# 鍋の本体
Ellipse $b 12 22 9.5 5.5 $ol
Ellipse $b 12 21.5 8.5 5 $cream
Rect $b 4 18 16 5 $cream
Rect $b 3 19 1 3 $ol; Rect $b 20 19 1 3 $ol
for ($x = 4; $x -lt 20; $x++) { Px $b $x 22 $pinkL }
Rect $b 4 22 16 1 $pinkL; Rect $b 4 23 16 1 $pink
# ふちとチョコの面
Ellipse $b 12 18 10 3.8 $ol
Ellipse $b 12 18 9 3.2 $pinkLL
Ellipse $b 12 18 7.5 2.6 $choc
Px $b 8 17 $milhi; Px $b 9 17 $milhi; Px $b 15 18 $milhi
# つけているバナナ（串が上）
Banana $b 9 0 $kinds[0] $true
Ellipse $b 12 18 5 1.6 $choc
Px $b 10 17 $milhi
Save $b 'chocobanana_pot.png'

# ---- カラースプレーの瓶 9x12（2色）
function Jar($name, $lid, $lid2, $cols) {
  $b = NewBmp 9 12
  Rect $b 1 0 7 3 $lid; Rect $b 1 0 7 1 $white; Rect $b 1 2 7 1 $lid2
  Rect $b 0 3 9 9 (C '#9fb6c8'); Rect $b 1 4 7 7 (C '#e6f1fa')
  Rect $b 1 4 1 7 $white
  $i = 0
  foreach ($p in @(@(2, 9), @(4, 9), @(6, 9), @(3, 8), @(5, 8), @(2, 7), @(4, 7), @(6, 7), @(3, 6), @(5, 6), @(4, 5))) { Px $b $p[0] $p[1] $cols[$i % $cols.Count]; $i++ }
  Rect $b 0 11 9 1 (C '#6f8ba3')
  foreach ($p in @(@(0, 3), @(8, 3), @(0, 11), @(8, 11))) { Clear $b $p[0] $p[1] }
  Save $b $name
}
Jar 'chocobanana_jar_a.png' $pink $pink2 $rainbow
Jar 'chocobanana_jar_b.png' $sky (C '#2f8ac8') @((C '#ffffff'), (C '#f2b544'), (C '#dfe8f2'))

# ---- バナナの箱 26x22（足元が原点）。黄色いバナナがあふれている
$b = NewBmp 26 22
Crescent $b 13 11 4 2 -3.2 $yel $yel2 (C '#5a3a1a') (C '#6a8f2a')
Crescent $b 13 11 20 1 3.2 $yel $yel2 (C '#5a3a1a') (C '#6a8f2a')
Crescent $b 13 11 12 0 1.5 $yel $yel2 (C '#5a3a1a') (C '#6a8f2a')
Crescent $b 13 11 22 6 2 $yel $yel2 (C '#5a3a1a') (C '#6a8f2a')
Crescent $b 13 11 3 7 -2 $yel $yel2 (C '#5a3a1a') (C '#6a8f2a')
Rect $b 0 10 26 12 $ol; Rect $b 1 11 24 10 $w2; Rect $b 1 11 24 1 $w1
for ($x = 1; $x -lt 25; $x++) { Px $b $x 16 $w3 }
Rect $b 8 13 10 5 $yel; Frame $b 8 13 10 5 $ol
Rect $b 10 15 2 1 $pink; Rect $b 13 15 3 1 $pink; Rect $b 10 17 6 1 $yel2
Rect $b 1 20 24 1 $w3
foreach ($p in @(@(0, 10), @(25, 10), @(0, 21), @(25, 21))) { Clear $b $p[0] $p[1] }
Save $b 'chocobanana_crate.png'

# ---- 紙トレイにのったチョコバナナ（横向き）20x10
function DrawTray($b) {
  Rect $b 0 4 20 6 $ol; Rect $b 1 5 18 4 $white; Rect $b 1 5 18 1 $pinkLL; Rect $b 1 8 18 1 $pinkL
  for ($x = 1; $x -lt 19; $x += 2) { Px $b $x 7 $pinkL }
  foreach ($p in @(@(0, 4), @(19, 4), @(0, 9), @(19, 9))) { Clear $b $p[0] $p[1] }
  Rect $b 2 0 14 6 $ol; Rect $b 3 1 12 4 $mil; Rect $b 3 1 12 1 $milhi; Rect $b 3 4 12 1 $milsh
  Rect $b 16 2 4 1 $wood; Rect $b 16 3 4 1 $wood2
  $rnd = New-Object System.Random(5)
  for ($x = 4; $x -lt 15; $x++) { for ($y = 1; $y -lt 5; $y++) { if ($rnd.NextDouble() -lt 0.28) { Px $b $x $y $rainbow[$rnd.Next($rainbow.Count)] } } }
  foreach ($p in @(@(2, 0), @(2, 5), @(15, 0), @(15, 5))) { Clear $b $p[0] $p[1] }
}
$b = NewBmp 20 10
DrawTray $b
Save $b 'chocobanana_tray.png'

# ---- メニュー（立て看板）62x50。足元が原点
$b = NewBmp 62 50
Rect $b 0 0 62 44 $ol; Rect $b 1 1 60 42 $pinkL; Rect $b 3 3 56 38 $cream
Rect $b 3 3 56 3 $pink
Rect $b 8 44 3 6 $w3; Rect $b 51 44 3 6 $w3; Rect $b 8 44 1 6 $w2; Rect $b 51 44 1 6 $w2
# 品書きの中身(味・種類)は書かない。文字は「メニュー」だけ。何の店かは大きなチョコバナナの絵で伝える
$w = TextWidth 'メニュー' 11
[void](TextPx $b 'メニュー' ([math]::Floor((62 - $w) / 2)) 8 11 $chocD $true)
$t = NewBmp 20 10
DrawTray $t
for ($j = 0; $j -lt 10; $j++) { for ($i = 0; $i -lt 20; $i++) { $c = $t.GetPixel($i, $j); if ($c.A -ge 128) { Rect $b (11 + $i * 2) (20 + $j * 2) 2 2 $c } } }
$t.Dispose()
foreach ($p in @(@(0, 0), @(61, 0), @(0, 43), @(61, 43))) { Clear $b $p[0] $p[1] }
Save $b 'chocobanana_menu.png'
# ---- ピンクのマット 44x24
$b = NewBmp 44 24
Rect $b 0 0 44 24 $gold; Rect $b 1 1 42 22 $pink2; Rect $b 2 2 40 20 $pinkLL
$i = 0
for ($y = 4; $y -lt 21; $y += 5) { for ($x = 4 + (($y / 5) % 2) * 4; $x -lt 40; $x += 8) { Rect $b $x $y 2 2 $rainbow[$i % $rainbow.Count]; $i++ } }
foreach ($p in @(@(0, 0), @(43, 0), @(0, 23), @(43, 23))) { Clear $b $p[0] $p[1] }
Save $b 'chocobanana_mat.png'

# ---- 風船（ゆれる）。横一列4コマ、1コマ18x46。足元（ひもの先）が原点
$bs = NewBmp 72 46
$sway = @(-1, 0, 1, 0)
for ($f = 0; $f -lt 4; $f++) {
  $ox = $f * 18; $s = $sway[$f]
  $bal = @(@(5, 11, $pink, $pinkLL), @(13, 9, $yel, $yelL), @(9, 19, $sky, (C '#b9e6ff')))
  foreach ($bl in $bal) {
    $cx = $bl[0] + $s * 1.0; $cy = $bl[1]
    Line $bs ($ox + 9) 45 ($ox + [math]::Round($cx)) ($cy + 7) (C '#f4efe6')
  }
  foreach ($bl in $bal) {
    $cx = $bl[0] + $s; $cy = $bl[1]
    Ellipse $bs ($ox + $cx) $cy 5.5 6.5 $ol
    Ellipse $bs ($ox + $cx) $cy 4.5 5.5 $bl[2]
    Px $bs ($ox + $cx - 2) ($cy - 3) $bl[3]; Px $bs ($ox + $cx - 2) ($cy - 2) $bl[3]; Px $bs ($ox + $cx - 1) ($cy - 4) $bl[3]
    Px $bs ($ox + [math]::Round($cx)) ($cy + 7) $ol
  }
}
Save $bs 'chocobanana_balloon.png'

# ---- キラキラ（アラザンの輝き）。横一列4コマ、1コマ9x9
$sp = NewBmp 36 9
$sz = @(0, 2, 4, 2)
for ($f = 0; $f -lt 4; $f++) {
  $ox = $f * 9; $r = $sz[$f]
  Px $sp ($ox + 4) 4 $white
  if ($r -ge 1) { for ($d = 1; $d -le $r; $d++) { foreach ($q in @(@($d, 0), @(-$d, 0), @(0, $d), @(0, -$d))) { Px $sp ($ox + 4 + $q[0]) (4 + $q[1]) $(if ($d -le 1) { $white } else { $yelL }) } } }
  if ($r -ge 3) { foreach ($q in @(@(1, 1), @(-1, 1), @(1, -1), @(-1, -1))) { Px $sp ($ox + 4 + $q[0]) (4 + $q[1]) $yelL } }
}
Save $sp 'chocobanana_sparkle.png'

# ---- 店の奥の壁 96x26（足元が原点）。ピンクのしまの布で、バナナを引き立てる
$b = NewBmp 96 26
Rect $b 0 0 96 26 $cream
for ($x = 0; $x -lt 96; $x += 12) { Rect $b $x 0 6 26 $pinkLL }
Rect $b 0 20 96 6 (C '#f0c4d2'); Rect $b 0 20 96 1 $pinkL
Rect $b 0 25 96 1 (C '#d99ab0')
Save $b 'chocobanana_back.png'
