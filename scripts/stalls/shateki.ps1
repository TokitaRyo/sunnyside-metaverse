# 射的（しゃてき）屋台の専用ドット絵。看板・紅白の幕・景品棚・景品いろいろ・コルク銃・コルク・的・カウンター・のぼり・提灯など。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/shateki.ps1   （リポジトリのルートで）
# 出力: client/public/brand/stall/shateki_*.png（配置は scripts/stalls/shateki.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル。文字は MS Gothic をドットにして貼る（Windows 専用）。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---------- 色 ----------
$navy = C '#243566'; $navy2 = C '#2f4584'; $navy3 = C '#3b57a3'
$blue = C '#2f6fb5'; $blue2 = C '#1f4f8a'; $sky = C '#9fd3f2'
$yellow = C '#ffd23f'; $yellow2 = C '#e0a81c'; $orange = C '#ef8a2c'
$pink = C '#f58fb0'; $pink2 = C '#d8628a'; $pink3 = C '#ffd0de'
$green = C '#4fb556'; $green2 = C '#2f7c3a'; $green3 = C '#8ee08f'
$brown = C '#b9763f'; $brown2 = C '#7e4a25'; $brown3 = C '#e0a56a'
$cork = C '#d9a86a'; $cork2 = C '#a8743c'; $cork3 = C '#efc98f'
$grey = C '#9aa3b5'; $grey2 = C '#6c7589'; $grey3 = C '#d6dbe6'
$purple = C '#8a5fc4'; $purple2 = C '#5c3b94'
$ink = C '#33202a'

# 丸い塊（ふち取り付き）
function Blob($b, $cx, $cy, $rx, $ry, $fill, $line) { Ellipse $b $cx $cy ($rx + 1) ($ry + 1) $line; Ellipse $b $cx $cy $rx $ry $fill }

# 大きな文字: TextPx で描いた文字を $scale 倍に拡大して貼る。ふち($edge)つき
function BigText($b, $text, $x, $y, $px, $scale, $fill, $edge) {
  $tmp = NewBmp ($px * ($text.Length + 2)) ($px * 2)
  [void](TextPx $tmp $text 0 0 $px (C '#ffffff') $false)
  foreach ($d in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1), @(-1, -1), @(1, -1), @(-1, 1), @(1, 1))) {
    for ($j = 0; $j -lt $tmp.Height; $j++) { for ($i = 0; $i -lt $tmp.Width; $i++) {
      if ($tmp.GetPixel($i, $j).A -ge 128) { Rect $b ($x + $i * $scale + $d[0]) ($y + $j * $scale + $d[1]) $scale $scale $edge }
    } }
  }
  for ($j = 0; $j -lt $tmp.Height; $j++) { for ($i = 0; $i -lt $tmp.Width; $i++) {
    if ($tmp.GetPixel($i, $j).A -ge 128) { Rect $b ($x + $i * $scale) ($y + $j * $scale) $scale $scale $fill }
  } }
  $tmp.Dispose()
}
function BigWidth($text, $px, $scale) { return (TextWidth $text $px) * $scale }

# 的の円（同心円: 白・赤・白・赤・金）
function Bullseye($b, $cx, $cy, $r) {
  Blob $b $cx $cy $r $r $white $ol
  Ellipse $b $cx $cy ($r * 0.72) ($r * 0.72) $red
  Ellipse $b $cx $cy ($r * 0.48) ($r * 0.48) $white
  Ellipse $b $cx $cy ($r * 0.28) ($r * 0.28) $red
  Ellipse $b $cx $cy ($r * 0.1) ($r * 0.1) $gold
}

# ---------- 看板 100x32（紅白の幕の上に掲げる）。大きな「射的」と、両わきの的 ----------
$b = NewBmp 100 32
Rect $b 14 0 3 4 $w3; Rect $b 83 0 3 4 $w3
Rect $b 0 3 100 29 $ol; Rect $b 1 4 98 27 $w2; Rect $b 2 5 96 25 $w3
Rect $b 3 6 94 23 $red; Rect $b 3 6 94 1 $red3
Frame $b 4 7 92 21 $gold
foreach ($p in @(@(0, 3), @(99, 3), @(0, 31), @(99, 31))) { Clear $b $p[0] $p[1] }
Bullseye $b 16 17.5 7
Bullseye $b 84 17.5 7
$tw = BigWidth '射的' 11 2
BigText $b '射的' ([math]::Floor((100 - $tw) / 2)) 5 11 2 $white $ol
Save $b 'shateki_sign.png'

# ---------- 紅白の幕（ひさし）116x14。ぶらさがった旗の形にぎざぎざ ----------
$b = NewBmp 116 14
Rect $b 0 0 116 3 $ol; Rect $b 0 1 116 1 $w1; Rect $b 0 2 116 1 $w3
for ($x = 0; $x -lt 116; $x++) {
  $seg = [math]::Floor($x / 8); $col = if ($seg % 2 -eq 0) { $red } else { $white }
  $lx = $x % 8
  for ($y = 3; $y -lt 14; $y++) {
    $lim = if ($y -le 8) { 0 } else { $y - 8 }   # 9行目から三角に細る
    if ($lx -lt $lim -or $lx -ge 8 - $lim) { continue }
    $c = $col
    if ($y -eq 3) { $c = if ($seg % 2 -eq 0) { $red2 } else { $cream } }
    Px $b $x $y $c
  }
}
for ($s = 0; $s -lt 15; $s++) { if ($s % 2 -eq 0) { Rect $b ($s * 8) 4 1 5 $red2 } }
Save $b 'shateki_roof.png'

# ---------- 柱 6x66 ----------
$b = NewBmp 6 66
Rect $b 0 0 6 66 $ol; Rect $b 1 0 4 65 $w2; Rect $b 1 0 1 65 $w1; Rect $b 4 0 1 65 $w3
Save $b 'shateki_post.png'

# ---------- のぼり旗 16x78（左の棒の足元が原点）。赤い布に白い「射的」と的 ----------
$b = NewBmp 16 78
Rect $b 0 2 16 2 $w3; Rect $b 0 2 2 76 $w2; Rect $b 0 2 1 76 $w3
Rect $b 2 4 13 66 $red; Rect $b 2 4 1 66 $red2; Rect $b 14 4 1 66 $red2
for ($i = 0; $i -lt 13; $i++) { if ($i % 2 -eq 0) { Px $b (2 + $i) 70 $red; Px $b (2 + $i) 71 $red2 } }
[void](TextPx $b '射' 3 6 11 $white $false)
[void](TextPx $b '的' 3 19 11 $white $false)
Bullseye $b 8.5 40 5
[void](TextPx $b '景' 3 50 11 $white $false)
[void](TextPx $b '品' 3 61 11 $white $false)
Save $b 'shateki_nobori.png'

# ---------- 紅白の提灯 12x22 ----------
$b = NewBmp 12 22
Rect $b 5 0 1 4 $ol
Rect $b 3 4 6 2 $ol
Ellipse $b 6 11.5 5.5 6 $white
for ($y = 5; $y -lt 18; $y++) { for ($x = 0; $x -lt 12; $x++) { $dx = ($x + 0.5 - 6) / 5.5; $dy = ($y + 0.5 - 11.5) / 6; if ($dx * $dx + $dy * $dy -le 1 -and ($x -lt 3 -or ($x -ge 5 -and $x -lt 7) -or $x -ge 9)) { Px $b $x $y $red } } }
Rect $b 2 8 8 1 $red2; Rect $b 1 11 10 1 $red2; Rect $b 2 14 8 1 $red2
Rect $b 3 17 6 2 $ol
Rect $b 5 19 2 3 $gold
Save $b 'shateki_lantern.png'

# ---------- 景品棚 76x42。うしろは紺色の板、3段、一番上のへりに木 ----------
$b = NewBmp 76 42
Rect $b 0 0 76 42 $ol
Rect $b 3 3 70 37 $navy
for ($x = 3; $x -lt 73; $x += 7) { Rect $b $x 3 1 37 $navy2 }
for ($x = 6; $x -lt 73; $x += 14) { for ($y = 5; $y -lt 39; $y += 13) { Px $b $x $y $navy3 } }
Rect $b 0 0 76 3 $w2; Rect $b 0 0 76 1 $w1; Rect $b 0 2 76 1 $w3
Rect $b 0 0 3 42 $w2; Rect $b 0 0 1 42 $w1; Rect $b 2 0 1 42 $w3
Rect $b 73 0 3 42 $w2; Rect $b 73 0 1 42 $w1; Rect $b 75 0 1 42 $w3
foreach ($fy in @(13, 27, 40)) {
  Rect $b 0 $fy 76 2 $w1; Rect $b 0 ($fy + 1) 76 1 $w2
  if ($fy -lt 40) { Rect $b 3 ($fy + 2) 70 1 $navy2; Rect $b 3 ($fy + 3) 70 1 (C '#1c2a52') }
}
Rect $b 0 41 76 1 $ol
Save $b 'shateki_shelf.png'

# ---------- 景品（ぬいぐるみ） ----------
# くま 11x11
$b = NewBmp 11 11
Blob $b 2.3 2.3 1.6 1.6 $brown $ol; Blob $b 8.7 2.3 1.6 1.6 $brown $ol
Blob $b 5.5 8.3 3.6 2.5 $brown $ol
Blob $b 5.5 5 4 3.2 $brown $ol
Ellipse $b 5.5 6.2 1.8 1.2 $brown3; Px $b 5 5 $ink; Px $b 3 4 $ink; Px $b 7 4 $ink
Rect $b 2 1 1 1 $brown3; Rect $b 8 1 1 1 $brown3
Rect $b 4 9 3 1 $red
Save $b 'shateki_bear.png'

# うさぎ 10x11
$b = NewBmp 10 11
Blob $b 2.6 2 1.1 2.4 $white $ol; Blob $b 7.4 2 1.1 2.4 $white $ol
Rect $b 2 1 1 3 $pink3; Rect $b 7 1 1 3 $pink3
Blob $b 5 8.5 3.3 2.2 $white $ol
Blob $b 5 5.7 3.7 2.6 $white $ol
Px $b 3 5 $ink; Px $b 6 5 $ink; Px $b 4 6 $pink2; Px $b 5 6 $pink2
Rect $b 2 7 1 1 $pink3; Rect $b 7 7 1 1 $pink3
Rect $b 3 9 4 1 $pink
Save $b 'shateki_bunny.png'

# ひよこ 10x10
$b = NewBmp 10 10
Blob $b 5 5 4 3.8 $yellow $ol
Rect $b 3 3 1 1 $ink; Rect $b 6 3 1 1 $ink
Rect $b 4 5 2 1 $orange; Px $b 5 6 $orange
Rect $b 2 5 1 1 $pink; Rect $b 7 5 1 1 $pink
Rect $b 4 0 1 1 $yellow2; Rect $b 5 0 1 1 $yellow2
Rect $b 3 9 1 1 $orange; Rect $b 6 9 1 1 $orange
Save $b 'shateki_chick.png'

# かえる 11x9
$b = NewBmp 11 9
Blob $b 5.5 5.7 4.8 2.7 $green $ol
Blob $b 2.7 2.2 1.8 1.8 $green $ol; Blob $b 8.3 2.2 1.8 1.8 $green $ol
Rect $b 2 1 2 2 $white; Rect $b 7 1 2 2 $white; Px $b 3 2 $ink; Px $b 8 2 $ink
Rect $b 3 6 5 1 $green2; Rect $b 3 5 1 1 $pink; Rect $b 7 5 1 1 $pink
Save $b 'shateki_frog.png'

# ---------- 景品（おかし・おもちゃ） ----------
# キャラメルの箱 11x8
$b = NewBmp 11 8
Rect $b 0 0 11 8 $ol; Rect $b 1 1 9 6 $yellow; Rect $b 1 1 9 1 (C '#fff08a'); Rect $b 1 6 9 1 $yellow2
Rect $b 1 3 9 2 $red; Rect $b 3 3 1 2 $white; Rect $b 5 3 1 2 $white; Rect $b 7 3 1 2 $white
Save $b 'shateki_caramel.png'

# おかしの箱（ピンク）10x10
$b = NewBmp 10 10
Rect $b 0 0 10 10 $ol; Rect $b 1 1 8 8 $pink; Rect $b 1 1 8 1 $pink3; Rect $b 1 8 8 1 $pink2
Rect $b 2 3 6 4 $white; Rect $b 3 4 1 2 $red; Rect $b 5 4 2 1 $blue; Rect $b 5 6 2 1 $green
Save $b 'shateki_snack_pink.png'

# おかしの箱（みどり・縦長）8x11
$b = NewBmp 8 11
Rect $b 0 0 8 11 $ol; Rect $b 1 1 6 9 $green; Rect $b 1 1 6 1 $green3; Rect $b 1 9 6 1 $green2
Rect $b 1 3 6 3 $white; Ellipse $b 4 4.5 1.4 1.4 $orange; Rect $b 2 7 4 1 $yellow
Save $b 'shateki_snack_green.png'

# チョコの箱（茶色）10x8
$b = NewBmp 10 8
Rect $b 0 0 10 8 $ol; Rect $b 1 1 8 6 $brown2; Rect $b 1 1 8 1 $brown; Rect $b 1 6 8 1 $ink
Rect $b 2 2 6 3 $cream; Rect $b 3 3 1 1 $brown2; Rect $b 5 3 2 1 $brown2
Save $b 'shateki_choco.png'

# ロボット 9x12
$b = NewBmp 9 12
Rect $b 4 0 1 2 $ol; Px $b 4 0 $red
Rect $b 1 2 7 5 $ol; Rect $b 2 3 5 3 $grey; Rect $b 2 3 5 1 $grey3
Px $b 3 4 $yellow; Px $b 5 4 $yellow
Rect $b 0 8 9 3 $ol; Rect $b 1 7 7 4 $blue; Rect $b 1 7 7 1 $sky; Rect $b 3 8 3 2 $yellow; Px $b 4 8 $red
Rect $b 1 11 2 1 $ol; Rect $b 6 11 2 1 $ol
Save $b 'shateki_robot.png'

# 貯金箱（ぶた）12x9
$b = NewBmp 12 9
Blob $b 5.5 4.8 4.6 3 $pink $ol
Blob $b 9.6 5 1.4 1.3 $pink2 $ol; Px $b 9 5 $ink; Px $b 10 5 $ink
Rect $b 3 1 2 1 $pink2; Rect $b 4 1 1 1 $pink3
Px $b 7 3 $ink
Rect $b 2 8 2 1 $ol; Rect $b 7 8 2 1 $ol
Rect $b 3 3 3 1 $ol
Save $b 'shateki_piggy.png'

# ゴムまり 9x9
$b = NewBmp 9 9
Blob $b 4.5 4.5 3.6 3.6 $red $ol
Rect $b 2 3 5 1 $white; Rect $b 2 5 5 1 $white
Px $b 3 2 $red3; Px $b 2 3 $red3
Save $b 'shateki_ball.png'

# ラムネの瓶 5x12
$b = NewBmp 5 12
Rect $b 1 0 3 1 $ol; Rect $b 1 1 3 2 $red; Rect $b 1 3 3 1 $ol
Rect $b 0 4 5 8 $ol; Rect $b 1 4 3 7 $sky; Rect $b 1 4 1 7 $white; Rect $b 2 7 2 2 $blue
Save $b 'shateki_ramune.png'

# 星のクッション 11x10
$b = NewBmp 11 10
Ascii $b 0 0 @(
  '.....oo.....',
  '....oyyo....',
  '....oyyo....',
  'oooooyyooooo',
  'oyyyyyyyyyyo',
  '.oyyyyyyyyo.',
  '..oyyyyyyo..',
  '..oyyooyyo..',
  '.oyyo..oyyo.',
  '.ooo....ooo.'
) @{ o = $ol; y = $yellow }
Rect $b 5 3 1 2 (C '#fff08a')
Save $b 'shateki_star.png'

# 値札のかわりの小さな札（文字なし。星のしるし）6x7
$b = NewBmp 5 5
Rect $b 0 0 5 5 $ol; Rect $b 1 1 3 3 $white; Px $b 2 2 $red
Save $b 'shateki_tag.png'

# ---------- コルク銃 30x9（銃口が右） ----------
$b = NewBmp 30 9
Rect $b 0 2 11 6 $ol; Rect $b 1 3 9 4 $brown; Rect $b 1 3 9 1 $brown3; Rect $b 1 6 9 1 $brown2
Rect $b 8 7 3 2 $ol; Rect $b 9 7 1 1 $brown      # 握り
Rect $b 10 2 17 4 $ol; Rect $b 11 3 15 2 $grey; Rect $b 11 3 15 1 $grey3     # 長い銃身
Rect $b 12 6 8 2 $ol; Rect $b 13 6 6 1 $brown2   # 先台
Rect $b 8 5 3 1 $grey2
Rect $b 26 1 4 6 $ol; Rect $b 27 2 2 4 $cork; Px $b 28 2 $cork3; Px $b 28 5 $cork2   # 先のコルク栓
Save $b 'shateki_gun.png'

# ---------- コルクの弾の皿 12x8 ----------
$b = NewBmp 12 8
Ellipse $b 6 5.5 6 2.5 $ol; Ellipse $b 6 5 5 2 $brown2; Ellipse $b 6 4.7 4.2 1.4 $brown
foreach ($x in @(2, 5, 8)) { Rect $b $x 1 3 4 $ol; Rect $b ($x + 1) 2 1 2 $cork; Rect $b ($x + 1) 1 1 1 $cork3; Rect $b $x 3 1 1 $cork2; Rect $b ($x + 2) 3 1 1 $cork2 }
Save $b 'shateki_corks.png'

# ---------- 「コルク」の札（カウンターに立てる小さな札。数の約束ごとは書かない）42x17 ----------
$b = NewBmp 42 17
Rect $b 0 0 42 15 $ol; Rect $b 1 1 40 13 $w2; Rect $b 2 2 38 11 $cream
Frame $b 2 2 38 11 $red
[void](TextPx $b 'コルク' 3 1 12 $red2 $true)
Rect $b 7 15 3 2 $w3; Rect $b 32 15 3 2 $w3
Save $b 'shateki_cork_sign.png'

# ---------- 立て札「ねらって うとう」（右前の黒板）52x36。足元が原点 ----------
$b = NewBmp 52 36
Rect $b 0 0 52 32 $ol; Rect $b 1 1 50 30 $w2; Rect $b 3 3 46 26 (C '#2f5a45')
Rect $b 6 32 3 4 $w3; Rect $b 43 32 3 4 $w3
Rect $b 6 32 1 4 $w2; Rect $b 43 32 1 4 $w2
$lines = 'ねらって', 'うとう！'
for ($i = 0; $i -lt 2; $i++) {
  $col = if ($i -eq 1) { C '#ffe14a' } else { C '#f4f2e8' }
  $w = TextWidth $lines[$i] 11
  [void](TextPx $b $lines[$i] ([math]::Floor((52 - $w) / 2)) (5 + 12 * $i) 11 $col $false)
}
Save $b 'shateki_board.png'

# ---------- 床のマット「ここから」 76x20（左に文字、右は立つ場所） ----------
$b = NewBmp 76 20
Rect $b 0 0 76 20 $ol; Rect $b 1 1 74 18 $blue2; Rect $b 2 2 72 16 $blue
Frame $b 3 3 70 14 $white
[void](TextPx $b 'ここから' 6 4 12 $white $false)
Rect $b 56 9 6 2 $yellow; Rect $b 62 7 1 6 $yellow; Rect $b 63 8 1 4 $yellow; Rect $b 64 9 1 2 $yellow
foreach ($p in @(@(0, 0), @(75, 0), @(0, 19), @(75, 19))) { Clear $b $p[0] $p[1] }
Save $b 'shateki_mat.png'

# ---------- カウンター 112x24。上の面は明るい木、前は青い板に紅白のへりと的の絵 ----------
$b = NewBmp 112 24
Rect $b 0 0 112 24 $ol
Rect $b 1 1 110 8 $w1; Rect $b 1 1 110 1 $cream; Rect $b 1 8 110 1 $w2
for ($x = 1; $x -lt 111; $x++) { $c = if ((($x - 1) % 8) -lt 4) { $red } else { $white }; Px $b $x 9 $c; Px $b $x 10 $c }
Rect $b 1 11 110 12 $blue; Rect $b 1 11 110 1 $sky; Rect $b 1 22 110 1 $blue2
foreach ($cx in @(22, 56, 90)) { Bullseye $b $cx 17 4.5 }
foreach ($cx in @(8, 39, 73, 104)) { Px $b $cx 17 $gold; Px $b ($cx - 1) 17 $gold; Px $b ($cx + 1) 17 $gold; Px $b $cx 16 $gold; Px $b $cx 18 $gold }
Rect $b 0 23 112 1 $ol
foreach ($p in @(@(0, 0), @(111, 0))) { Clear $b $p[0] $p[1] }
Save $b 'shateki_counter.png'

# ---------- アニメ: きらっと光る星 9x9 x4コマ ----------
$b = NewBmp 36 9
$sp = C '#fff6b0'
# コマ0: 点
Px $b 4 4 $white
# コマ1: 小さな十字
Px $b (9 + 4) 3 $sp; Px $b (9 + 3) 4 $sp; Px $b (9 + 4) 4 $white; Px $b (9 + 5) 4 $sp; Px $b (9 + 4) 5 $sp
# コマ2: 大きな十字
for ($i = 0; $i -lt 9; $i++) { Px $b (18 + $i) 4 $sp; Px $b (18 + 4) $i $sp }
Px $b (18 + 4) 4 $white; Px $b (18 + 3) 4 $white; Px $b (18 + 5) 4 $white; Px $b (18 + 4) 3 $white; Px $b (18 + 4) 5 $white
Px $b (18 + 2) 2 $sp; Px $b (18 + 6) 2 $sp; Px $b (18 + 2) 6 $sp; Px $b (18 + 6) 6 $sp
# コマ3: 小さな十字
Px $b (27 + 4) 2 $sp; Px $b (27 + 2) 4 $sp; Px $b (27 + 4) 4 $white; Px $b (27 + 6) 4 $sp; Px $b (27 + 4) 6 $sp
Px $b (27 + 4) 3 $white; Px $b (27 + 3) 4 $white; Px $b (27 + 5) 4 $white; Px $b (27 + 4) 5 $white
Save $b 'shateki_sparkle.png'

# ---------- アニメ: ぶらさがった的（ゆれる） 28x30 x4コマ ----------
$b = NewBmp 112 30
$offs = @(-3, 0, 3, 0)
for ($f = 0; $f -lt 4; $f++) {
  $ox = $f * 28; $o = $offs[$f]
  Rect $b ($ox + 12) 0 4 2 $w3
  Line $b ($ox + 14) 1 ($ox + 14 + $o) 12 $ink
  Bullseye $b ($ox + 14 + $o) 21 7
}
Save $b 'shateki_pendulum.png'

# ---------- アニメ: 立て札のまわる的（ぶん回し） 24x34 x4コマ ----------
$b = NewBmp 96 34
for ($f = 0; $f -lt 4; $f++) {
  $ox = $f * 24
  Rect $b ($ox + 10) 20 4 14 $w3; Rect $b ($ox + 10) 20 1 14 $w2
  Rect $b ($ox + 5) 32 14 2 $w3
  $phase = $f * [math]::PI / 8
  for ($y = 0; $y -lt 22; $y++) { for ($x = 0; $x -lt 22; $x++) {
    $dx = $x + 0.5 - 11; $dy = $y + 0.5 - 11; $d = [math]::Sqrt($dx * $dx + $dy * $dy)
    if ($d -gt 11) { continue }
    if ($d -gt 10) { Px $b ($ox + 1 + $x) $y $ol; continue }
    if ($d -gt 9) { Px $b ($ox + 1 + $x) $y $w2; continue }
    if ($d -lt 2.5) { Px $b ($ox + 1 + $x) $y $gold; continue }
    $a = [math]::Atan2($dy, $dx) + $phase + 4 * [math]::PI
    $seg = ([int][math]::Floor($a / ([math]::PI / 4))) % 2
    Px $b ($ox + 1 + $x) $y $(if ($seg -eq 0) { $red } else { $white })
  } }
}
Save $b 'shateki_wheel.png'

# ---------- アニメ: 飛んでいくコルク弾 8x44 x4コマ（下から上へ。しっぽつき） ----------
$b = NewBmp 32 44
for ($f = 0; $f -lt 4; $f++) {
  $ox = $f * 8; $cy = 40 - $f * 11
  Rect $b ($ox + 3) $cy 3 4 $ol; Rect $b ($ox + 4) ($cy + 1) 1 2 $cork; Px $b ($ox + 4) ($cy + 1) $cork3
  for ($i = 1; $i -le 4; $i++) { Px $b ($ox + 4) ($cy + 3 + $i * 2) $(if ($i -le 2) { $white } else { $grey3 }) }
}
Save $b 'shateki_shot.png'
