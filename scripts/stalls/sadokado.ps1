# 茶華道部（茶道と華道）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/sadokado.ps1   （リポジトリのルートで実行）
# 出力: client/public/brand/stall/sadokado_*.png（原点は各スプライトの足元中央。配置は scripts/stalls/sadokado.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（抹茶・朱・緋毛氈・白木・瓦・畳）
$k = C '#33201a'                                                                                  # 輪郭
$wd0 = C '#f0d7a0'; $wd1 = C '#d2a468'; $wd2 = C '#a8703e'; $wd3 = C '#6e4528'; $wd4 = C '#43291a' # 木（明→暗）
$g0 = C '#d3e48c'; $g1 = C '#a4c45c'; $g2 = C '#76993c'; $g3 = C '#4f7230'; $g4 = C '#2f4a22'     # 抹茶・竹
$s0 = C '#f0805e'; $s1 = C '#d9482c'; $s2 = C '#a82e20'; $s3 = C '#75201a'                        # 朱
$h0 = C '#ea4a60'; $h1 = C '#c42a42'; $h2 = C '#94192f'; $h3 = C '#6c1223'                        # 緋毛氈
$cr0 = C '#fffaf0'; $cr1 = C '#f3e8cc'; $cr2 = C '#dcc9a0'; $cr3 = C '#b99f72'                    # 生成り
$sl0 = C '#7a8694'; $sl1 = C '#4f5a68'; $sl2 = C '#37404c'; $sl3 = C '#232a33'                    # 瓦
$st0 = C '#e2dfd6'; $st1 = C '#b9b6ad'; $st2 = C '#8c8a82'; $st3 = C '#625f5a'                    # 石
$sumi = C '#2a2420'; $gold = C '#e6b84a'; $gold2 = C '#b8872a'
$pk0 = C '#ffd3de'; $pk1 = C '#f4a2b8'; $pk2 = C '#d9728d'
$ye0 = C '#fff0a0'; $ye1 = C '#f6d34a'; $ye2 = C '#d9a21e'
$pu0 = C '#b9a3e6'; $pu1 = C '#8a6ac0'; $pu2 = C '#5d4690'
$ai0 = C '#8fb0d8'; $ai1 = C '#4d77ad'; $ai2 = C '#2f4f80'; $ai3 = C '#1f3558'                    # 藍
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# 縁取り: 透明でない画素のまわり(上下左右)を輪郭色で囲む
function Outline($b, $col) {
  $w = $b.Width; $h = $b.Height; $mark = @()
  for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) {
    if ($b.GetPixel($x, $y).A -eq 0) {
      foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $nx = $x + $d[0]; $ny = $y + $d[1]
        if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h -and $b.GetPixel($nx, $ny).A -gt 200) { $mark += , @($x, $y); break }
      }
    }
  } }
  foreach ($m in $mark) { Px $b $m[0] $m[1] $col }
}
function Disc($b, $cx, $cy, $r, $col) { Ellipse $b $cx $cy $r $r $col }
function Cut4($b, $col0) { Px $b 0 0 $clear; Px $b ($b.Width - 1) 0 $clear; Px $b 0 ($b.Height - 1) $clear; Px $b ($b.Width - 1) ($b.Height - 1) $clear }

# ---- 小さな絵（看板の飾りにも使う）
# 茶碗（抹茶入り）を (x,y) に。幅 13 x 高さ 9
function TeaBowlIcon($b, $x, $y) {
  Rect $b ($x + 2) ($y + 1) 9 2 $g1; Rect $b ($x + 3) ($y + 1) 6 1 $g0
  Rect $b ($x + 1) ($y + 3) 11 2 $ai1; Rect $b ($x + 1) ($y + 3) 11 1 $ai0
  Rect $b ($x + 2) ($y + 5) 9 1 $ai1; Rect $b ($x + 3) ($y + 6) 7 1 $ai2; Rect $b ($x + 4) ($y + 7) 5 1 $ai3
  Px $b ($x + 2) $y $g2; Px $b ($x + 6) ($y - 1) $g2; Px $b ($x + 7) ($y - 2) $g2; Px $b ($x + 6) ($y - 3) $g2
}
# 花（椿風）を (x,y) に。13x13
function FlowerIcon($b, $x, $y, $pc = $h1, $pc2 = $h0) {
  Ellipse $b ($x + 4) ($y + 11) 3 1.3 $g2; Ellipse $b ($x + 9) ($y + 11) 3 1.3 $g2; Rect $b ($x + 6) ($y + 8) 1 4 $g3
  foreach ($a in 0..4) {
    $ang = $a * 2 * [math]::PI / 5 - [math]::PI / 2
    Ellipse $b ($x + 6.5 + 3.4 * [math]::Cos($ang)) ($y + 5.5 + 3.4 * [math]::Sin($ang)) 2.6 2.6 $pc
  }
  Disc $b ($x + 6.5) ($y + 5.5) 2.2 $pc2; Disc $b ($x + 6.5) ($y + 5.5) 1.3 $gold; Px $b ($x + 6) ($y + 5) $ye0
}

# ---- 看板（木札・屋根の上に掲げる）112x30
$b = NewBmp 112 30
Rect $b 14 0 3 6 $wd3; Rect $b 95 0 3 6 $wd3
Rect $b 0 5 112 25 $k; Rect $b 1 6 110 23 $s2; Rect $b 2 7 108 21 $s1; Rect $b 2 7 108 1 $s0
Rect $b 3 9 106 18 $wd0
$rnd = New-Object System.Random 7
for ($i = 0; $i -lt 70; $i++) { $xx = 4 + $rnd.Next(100); $yy = 10 + $rnd.Next(16); Rect $b $xx $yy (2 + $rnd.Next(6)) 1 $wd1 }
Rect $b 3 26 106 1 $wd1
Cut4 $b
[void](TextPx $b '茶華道部' 25 10 16 $sumi $true)
TeaBowlIcon $b 7 14
FlowerIcon $b 93 11
Save $b 'sadokado_sign.png'

# ---- 屋根（瓦） 112x30。棟・鬼瓦・軒瓦・垂木
$b = NewBmp 112 30
$W = 112
# 棟（むね）と鬼瓦
Rect $b 8 3 96 4 $sl2; Rect $b 8 3 96 1 $sl0; Rect $b 8 6 96 1 $cr2
Rect $b 4 0 6 8 $sl1; Rect $b 4 0 6 1 $sl0; Rect $b 5 2 2 2 $cr1
Rect $b 102 0 6 8 $sl1; Rect $b 102 0 6 1 $sl0; Rect $b 105 2 2 2 $cr1
# 屋根面（上すぼまり）。瓦の筋と段
for ($y = 7; $y -lt 24; $y++) {
  $inset = [math]::Floor(8 - ($y - 7) * 8.0 / 16)
  for ($x = $inset; $x -lt $W - $inset; $x++) {
    $col = ($x - $inset) % 6
    $c = switch ($col) { 0 { $sl2 } 1 { $sl1 } 2 { $sl1 } 3 { $sl0 } 4 { $sl1 } default { $sl2 } }
    if (($y - 7) % 5 -eq 4) { $c = $sl3 }
    Px $b $x $y $c
  }
}
# 軒先の丸瓦（軒瓦）
for ($x = 0; $x -lt $W; $x += 6) { Rect $b $x 24 6 2 $sl3; Rect $b ($x + 1) 24 4 1 $cr1; Px $b ($x + 2) 24 $cr0 }
Rect $b 0 24 $W 1 $sl2
for ($x = 0; $x -lt $W; $x += 6) { Rect $b ($x + 1) 24 4 1 $cr2; Px $b ($x + 2) 24 $cr0 }
# 垂木（たるき）
Rect $b 2 26 108 4 $wd2; Rect $b 2 26 108 1 $wd3
for ($x = 3; $x -lt 110; $x += 4) { Rect $b $x 27 2 3 $wd1; Rect $b ($x + 2) 27 1 3 $wd4 }
Rect $b 2 29 108 1 $wd4
Outline $b $k
Save $b 'sadokado_roof.png'

# ---- 座敷の奥の壁（床の間＋障子） 92x36。足元＝壁の下
$b = NewBmp 92 36
Rect $b 0 0 92 36 $cr2
for ($i = 0; $i -lt 60; $i++) { Px $b ($rnd.Next(92)) (3 + $rnd.Next(30)) $cr1 }
Rect $b 0 0 92 3 $wd3; Rect $b 0 0 92 1 $wd2; Rect $b 0 3 92 2 $cr3                         # 長押と影
Rect $b 0 32 92 4 $wd3; Rect $b 0 32 92 1 $wd2                                               # 幅木
# 床の間（左）
Rect $b 3 5 30 27 $k; Rect $b 4 6 28 26 $cr3; Rect $b 4 6 28 2 $cr2
Rect $b 4 28 28 4 $wd2; Rect $b 4 28 28 1 $wd1; Rect $b 4 31 28 1 $wd3                       # 床框
# 掛け軸
Rect $b 8 6 1 3 $wd4; Rect $b 23 6 1 3 $wd4                                                   # 吊り紐
Rect $b 8 8 16 1 $wd3; Rect $b 7 8 1 1 $wd1; Rect $b 24 8 1 1 $wd1
Rect $b 9 9 14 18 $g3; Rect $b 9 9 14 1 $g2; Rect $b 9 26 14 1 $g4                           # 表装
Rect $b 11 11 10 14 $cr0
[void](TextPx $b '和' 10 12 12 $sumi $false)
Rect $b 7 27 18 1 $wd3
# 障子（右）2枚
foreach ($px0 in @(37, 64)) {
  Rect $b $px0 6 26 26 $wd3; Rect $b ($px0 + 1) 7 24 24 $cr0
  for ($gx = 1; $gx -le 23; $gx += 6) { Rect $b ($px0 + $gx) 7 1 24 $wd1 }
  for ($gy = 7; $gy -le 30; $gy += 5) { Rect $b ($px0 + 1) $gy 24 1 $wd1 }
  Rect $b ($px0 + 1) 7 24 1 $wd2
  Rect $b ($px0 + 1) 29 24 2 $cr1
}
Save $b 'sadokado_room.png'

# ---- 畳の床 92x30（奥は畳、手前に木の縁）。足元＝縁側の下
$b = NewBmp 92 30
for ($mx = 0; $mx -lt 2; $mx++) {
  $ox = 2 + $mx * 44
  Rect $b $ox 0 44 22 $k
  Rect $b ($ox + 1) 1 42 20 (C '#b7c378')
  for ($yy = 2; $yy -lt 19; $yy += 2) { Rect $b ($ox + 1) $yy 42 1 (C '#a9b76a') }
  for ($i = 0; $i -lt 40; $i++) { Px $b ($ox + 2 + $rnd.Next(40)) (2 + $rnd.Next(17)) (C '#c8d38a') }
  Rect $b ($ox + 1) 1 42 2 (C '#2c3b2a'); Rect $b ($ox + 1) 18 42 3 (C '#2c3b2a')              # 畳縁
  Rect $b ($ox + 1) 2 42 1 (C '#4a5e3f'); Rect $b ($ox + 1) 19 42 1 (C '#4a5e3f')
  for ($xx = 3; $xx -lt 42; $xx += 6) { Px $b ($ox + $xx) 2 $gold2; Px $b ($ox + $xx) 19 $gold2 }
}
Rect $b 0 21 92 4 $wd1; Rect $b 0 21 92 1 $wd0; Rect $b 0 24 92 1 $wd3                         # 縁側の板
Rect $b 0 25 92 5 $wd2; Rect $b 0 25 92 1 $wd3; Rect $b 0 29 92 1 $wd4
for ($xx = 6; $xx -lt 92; $xx += 14) { Rect $b $xx 26 1 3 $wd3 }
Save $b 'sadokado_tatami.png'

# ---- 手前の柱 8x64。足元＝礎石の下
$b = NewBmp 8 64
Rect $b 1 0 6 58 $k; Rect $b 2 0 4 58 $wd2; Rect $b 2 0 1 58 $wd1; Rect $b 5 0 1 58 $wd3
Rect $b 1 0 6 2 $k; Rect $b 2 1 4 1 $wd0
Rect $b 0 56 8 8 $k; Rect $b 1 57 6 6 $st1; Rect $b 1 57 6 2 $st0; Rect $b 1 61 6 2 $st2
Save $b 'sadokado_post.png'

# ---- 茶釜と風炉 22x26。足元＝風炉の底
$b = NewBmp 22 26
# 風炉（土の火鉢）
Rect $b 3 15 16 10 $k; Rect $b 4 15 14 9 (C '#7a4a34'); Rect $b 4 15 14 2 (C '#a8683f'); Rect $b 4 22 14 2 (C '#4e2e22')
Rect $b 2 14 18 2 $k; Rect $b 3 14 16 1 (C '#c98a55')
Rect $b 8 18 6 4 $k; Rect $b 9 19 4 2 (C '#ff9a3c'); Px $b 10 19 (C '#ffd36b')            # 火の窓
Rect $b 5 24 3 2 $k; Rect $b 14 24 3 2 $k
# 釜（鉄）
Ellipse $b 11 8.5 8.2 6.8 $k
Ellipse $b 11 8.5 7.4 6 (C '#3a3a46'); Ellipse $b 10.2 8 6 4.6 (C '#4b4b5a')
Rect $b 5 6 3 2 (C '#7a7a8c'); Px $b 6 5 (C '#8e8ea0')                                  # つや
Rect $b 4 12 14 1 (C '#25252e')
# 蓋と摘み
Rect $b 6 2 10 2 $k; Rect $b 7 2 8 1 (C '#5a5a6c'); Rect $b 9 0 4 3 $k; Rect $b 10 1 2 1 $gold
# 鐶付（かんつき）の輪
Px $b 2 8 $gold; Px $b 1 9 $gold; Px $b 2 10 $gold; Px $b 19 8 $gold; Px $b 20 9 $gold; Px $b 19 10 $gold
Save $b 'sadokado_kama.png'

# ---- 水指 11x13
$b = NewBmp 11 13
Rect $b 1 3 9 9 $k; Rect $b 2 4 7 7 $cr0; Rect $b 2 4 2 7 $cr1; Rect $b 7 4 2 7 $cr2
Rect $b 2 6 7 2 $ai1; Rect $b 2 6 7 1 $ai0
Rect $b 0 0 11 1 $k; Rect $b 1 1 9 3 $k; Rect $b 2 1 7 2 $wd1; Rect $b 2 1 7 1 $wd0; Px $b 5 0 $wd3
Rect $b 2 11 7 1 $cr3
Px $b 0 0 $clear; Px $b 10 0 $clear
Save $b 'sadokado_mizusashi.png'

# ---- 棗（黒漆の茶入れ） 7x8
$b = NewBmp 7 8
Rect $b 0 2 7 6 $k; Rect $b 1 1 5 1 $k; Rect $b 1 2 5 5 (C '#3a2a30'); Rect $b 1 2 2 4 (C '#5a424a')
Rect $b 1 3 5 1 $k; Px $b 3 5 $gold; Px $b 2 4 $gold; Px $b 4 4 $gold
Rect $b 1 7 5 1 (C '#241a1e')
Px $b 0 2 $clear; Px $b 6 2 $clear
Save $b 'sadokado_natsume.png'

# ---- 茶碗（抹茶入り） 11x8
$b = NewBmp 11 8
Rect $b 0 1 11 1 $k; Rect $b 1 0 9 2 $k; Rect $b 2 1 7 1 $g1; Rect $b 3 1 3 1 $g0
Rect $b 0 2 11 3 $k; Rect $b 1 2 9 3 $ai1; Rect $b 1 2 9 1 $ai0; Rect $b 6 3 3 1 $ai2
Rect $b 1 5 9 1 $k; Rect $b 2 5 7 1 $ai2; Rect $b 2 6 7 2 $k; Rect $b 3 6 5 1 $ai3
Px $b 0 1 $clear; Px $b 10 1 $clear; Px $b 0 2 $clear; Px $b 10 2 $clear
Save $b 'sadokado_chawan.png'

# ---- 茶筅 7x10
$b = NewBmp 7 10
Rect $b 2 0 3 4 $k; Rect $b 3 0 1 4 $wd1; Rect $b 2 1 1 3 $wd2
Rect $b 0 4 7 6 $k; Rect $b 1 4 5 5 $cr1; Rect $b 1 4 2 5 $cr0; Rect $b 5 4 1 5 $cr2
for ($xx = 1; $xx -lt 6; $xx += 2) { Rect $b $xx 6 1 3 $cr3 }
Rect $b 2 4 3 1 $wd3
Px $b 0 4 $clear; Px $b 6 4 $clear; Px $b 0 9 $clear; Px $b 6 9 $clear
Save $b 'sadokado_chasen.png'

# ---- 点前盆（低い漆の台） 40x9。足元＝台の下
$b = NewBmp 40 9
Rect $b 0 0 40 9 $k
Rect $b 1 1 38 4 (C '#7a2f26'); Rect $b 1 1 38 1 (C '#a8483a')                              # 天板（朱漆）
Rect $b 1 5 38 3 (C '#3a2a30'); Rect $b 1 5 38 1 (C '#5a424a')
Px $b 0 0 $clear; Px $b 39 0 $clear; Px $b 0 8 $clear; Px $b 39 8 $clear
for ($xx = 6; $xx -lt 38; $xx += 8) { Px $b $xx 3 $gold2 }
Save $b 'sadokado_tray.png'

# ---- 練り切りの皿 20x11（桜・若葉・雪うさぎ風の白）
$b = NewBmp 20 11
Ellipse $b 10 7.5 10 3.4 $ai2; Ellipse $b 10 7 9.5 3 $cr0; Ellipse $b 10 7 7.5 2.2 $cr1
# 桜
Ellipse $b 5.5 5.5 3 2.4 $pk1; Ellipse $b 5.5 5.2 2.4 1.9 $pk0; Px $b 5 5 $pk2; Px $b 6 4 $ye1
# 若葉
Ellipse $b 10.5 5.6 2.6 2.1 $g1; Px $b 9 5 $g0; Px $b 10 4 $g0; Line $b 10 7 12 5 $g3
# 白（雪）
Ellipse $b 15 5.6 2.7 2.3 $cr0; Px $b 14 5 $cr1; Px $b 16 6 $cr2; Px $b 15 4 $h1
Save $b 'sadokado_nerikiri.png'

# ---- 三色団子の皿 20x12
$b = NewBmp 20 12
Ellipse $b 10 8.5 10 3.4 $wd3; Ellipse $b 10 8 9.5 3 $wd1; Ellipse $b 10 8 8 2.2 $wd0
foreach ($yy in @(3.5, 6.5)) {
  Line $b 1 ([int]$yy + 1) 19 ([int]$yy) $wd3
  Disc $b 6.5 $yy 1.9 $pk1; Px $b 5 ([int]$yy - 1) $pk0
  Disc $b 10.5 $yy 1.9 $cr0; Px $b 9 ([int]$yy - 1) $cr0; Px $b 11 ([int]$yy + 1) $cr2
  Disc $b 14.5 $yy 1.9 $g1; Px $b 13 ([int]$yy - 1) $g0; Px $b 15 ([int]$yy + 1) $g2
}
Save $b 'sadokado_dango.png'

# ---- 縁台に敷いた緋毛氈 46x24。足元＝脚の下
$b = NewBmp 46 24
# 脚
Rect $b 4 14 4 10 $k; Rect $b 5 14 2 9 $wd2; Rect $b 38 14 4 10 $k; Rect $b 39 14 2 9 $wd2
Rect $b 8 19 30 2 $k; Rect $b 8 19 30 1 $wd2
# 座板
Rect $b 0 8 46 7 $k; Rect $b 1 9 44 5 $wd1; Rect $b 1 9 44 1 $wd0; Rect $b 1 13 44 1 $wd2
# 緋毛氈（上面と、右にたれる布）
Rect $b 0 0 46 9 $k; Rect $b 1 1 44 7 $h1; Rect $b 1 1 44 2 $h0; Rect $b 1 7 44 1 $h2
for ($xx = 3; $xx -lt 44; $xx += 4) { Px $b $xx 4 $h2 }
Rect $b 36 8 9 10 $k; Rect $b 37 8 7 9 $h1; Rect $b 37 8 7 1 $h2; Rect $b 37 9 2 8 $h0; Rect $b 37 16 7 1 $h3
for ($xx = 37; $xx -lt 44; $xx += 2) { Px $b $xx 17 $gold2 }
Rect $b 1 7 35 1 $gold2                                                                        # 金の縁取り
Cut4 $b $clear
Save $b 'sadokado_bench.png'

# ---- 野点傘 58x58。足元＝柱の根元（x=29）
$b = NewBmp 58 58
$cx = 29.0
function HW($y) { $t = (20.0 - $y) / 18.0; if ($t -gt 1) { $t = 1.0 }; return 28.0 * [math]::Sqrt([math]::Max(0.0, 1.0 - $t * $t)) }
for ($y = 2; $y -le 20; $y++) {
  $hw = HW $y
  for ($x = [math]::Floor($cx - $hw); $x -lt [math]::Ceiling($cx + $hw); $x++) {
    $r = ($x + 0.5 - $cx) / ([math]::Max(1.0, $hw))
    $bk = [math]::Floor(($r + 1.0) * 4.0)
    $c = if ($bk % 2 -eq 0) { $s1 } else { $s0 }
    if ($r -gt 0.35) { $c = if ($bk % 2 -eq 0) { $s2 } else { $s1 } }
    Px $b $x $y $c
  }
}
# 骨（放射の線）
foreach ($rb in @(-0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75)) {
  for ($y = 3; $y -le 20; $y++) { $hw = HW $y; Px $b ([math]::Floor($cx + $rb * $hw)) $y $s3 }
}
# へりの裏側と房
for ($x = 1; $x -lt 57; $x++) {
  $r = ($x + 0.5 - $cx) / 28.0
  if ([math]::Abs($r) -lt 1) { Px $b $x 21 $s3; if ($x % 4 -ne 0) { Px $b $x 22 $s2 } }
}
Rect $b 28 0 3 3 $gold2; Px $b 29 0 $gold; Rect $b 27 2 5 1 $s3
Outline $b $k
# 柱
Rect $b 28 23 2 31 $wd3; Rect $b 28 23 1 31 $wd2
Rect $b 23 53 12 5 $k; Rect $b 24 54 10 3 $wd2; Rect $b 24 54 10 1 $wd1
Save $b 'sadokado_umbrella.png'

# ======== 華道（生け花）の展示 ========
# ---- 展示台（2段の白木の台） 48x32。足元＝台の下
$b = NewBmp 48 32
# 上段（奥）
Rect $b 10 3 28 11 $k; Rect $b 11 4 26 5 $wd0; Rect $b 11 4 26 1 $cr0; Rect $b 11 9 26 4 $wd1; Rect $b 11 9 26 1 $wd2
# 下段（手前）
Rect $b 0 13 48 19 $k; Rect $b 1 14 46 6 $wd0; Rect $b 1 14 46 1 $cr0
Rect $b 1 20 46 11 $wd1; Rect $b 1 20 46 1 $wd2
Rect $b 4 23 18 6 $wd2; Rect $b 5 24 16 4 $wd1; Rect $b 26 23 18 6 $wd2; Rect $b 27 24 16 4 $wd1   # 羽目の凹み
Rect $b 1 30 46 1 $wd3
Px $b 0 13 $clear; Px $b 47 13 $clear
Save $b 'sadokado_stand.png'

# 花の部品
function Stem($b, $x0, $y0, $x1, $y1) { Line $b $x0 $y0 $x1 $y1 $g3 }
function Chrys($b, $cx, $cy, $r, $c0, $c1, $c2) {
  Disc $b $cx $cy ($r + 0.9) $c2; Disc $b $cx $cy $r $c1
  foreach ($a in 0..7) { $ang = $a * [math]::PI / 4; Px $b ([math]::Round($cx + ($r + 0.4) * [math]::Cos($ang))) ([math]::Round($cy + ($r + 0.4) * [math]::Sin($ang))) $c0 }
  Disc $b $cx $cy ([math]::Max(0.8, $r - 1.6)) $c0
}
function Momiji($b, $cx, $cy, $c0, $c1) {
  Px $b $cx $cy $c1; Px $b ($cx - 1) $cy $c0; Px $b ($cx + 1) $cy $c0; Px $b $cx ($cy - 1) $c0; Px $b $cx ($cy + 1) $c0
  Px $b ($cx - 1) ($cy - 1) $c1; Px $b ($cx + 1) ($cy - 1) $c1; Px $b ($cx - 2) ($cy - 1) $c1; Px $b ($cx + 2) ($cy + 1) $c1
}
function Kikyo($b, $cx, $cy) {
  foreach ($a in 0..4) { $ang = $a * 2 * [math]::PI / 5 - [math]::PI / 2; Px $b ([math]::Round($cx + 1.9 * [math]::Cos($ang))) ([math]::Round($cy + 1.9 * [math]::Sin($ang))) $pu1; Px $b ([math]::Round($cx + 2.6 * [math]::Cos($ang))) ([math]::Round($cy + 2.6 * [math]::Sin($ang))) $pu0 }
  Px $b $cx $cy $pu2; Px $b ($cx + 1) $cy $pu2; Px $b $cx ($cy + 1) $pu1
}

# ---- 水盤の盛花（菊・桔梗・紅葉） 28x26。足元＝水盤の底
$b = NewBmp 28 26
Stem $b 14 21 14 9; Stem $b 13 21 8 13; Stem $b 15 21 20 12; Stem $b 14 21 17 6; Stem $b 13 21 22 17
Ellipse $b 9 18 3 1.2 $g2; Ellipse $b 19 19 3 1.2 $g2; Ellipse $b 12 14 2 1 $g2
# 水盤（青磁の浅い器）
Ellipse $b 14 22.5 12.5 3.3 $k; Ellipse $b 14 22 11.7 2.7 $ai1; Ellipse $b 14 21.4 11.7 2.5 $ai0
Ellipse $b 14 21 9.8 1.6 (C '#7ab4d8'); Rect $b 12 20 5 1 $gold; Px $b 13 20 $cr0
Rect $b 8 24 12 1 $ai2
Chrys $b 14 7 3 $ye0 $ye1 $ye2
Chrys $b 8 12 2.2 $cr0 $cr1 $cr3
Chrys $b 20 11 2.4 $pk0 $pk1 $pk2
Kikyo $b 17 4
Momiji $b 22 16 $s0 $s1; Momiji $b 6 17 $s1 $s2
Save $b 'sadokado_ike_suiban.png'

# ---- 壺の薄と紅葉 20x38。足元＝壺の底
$b = NewBmp 20 38
foreach ($sx in @(@(10, 21, 6, 3), @(10, 21, 11, 1), @(10, 21, 15, 5), @(10, 21, 3, 8))) { Stem $b $sx[0] $sx[1] $sx[2] $sx[3] }
# 薄の穂
foreach ($pl in @(@(6, 3), @(11, 1), @(15, 5), @(3, 8))) {
  Ellipse $b $pl[0] ($pl[1] + 2) 2 3.6 (C '#d8c08a'); Px $b $pl[0] ($pl[1] - 1) $cr0; Px $b ($pl[0] - 1) ($pl[1] + 1) $cr0; Px $b ($pl[0] + 1) ($pl[1] + 3) (C '#a8905c')
}
Momiji $b 16 12 $s0 $s1; Momiji $b 14 16 $s1 $s2; Momiji $b 4 15 $s0 $s1; Momiji $b 17 9 $s1 $s2
Line $b 10 21 16 12 $wd3
# 壺（藍の釉薬）
Rect $b 7 20 7 2 $k; Rect $b 8 20 5 1 $ai0
Rect $b 8 22 5 3 $k; Rect $b 9 22 3 3 $ai1
Ellipse $b 10 30 6.8 6.3 $k; Ellipse $b 10 30 6 5.6 $ai1; Ellipse $b 9 29 4.2 3.8 (C '#5f8bc0')
Rect $b 6 26 8 1 $cr0; Px $b 7 29 $ai0; Px $b 7 30 $ai0
Rect $b 5 32 10 1 $ai2; Rect $b 6 35 8 1 $ai3
Save $b 'sadokado_ike_tsubo.png'

# ---- 竹筒の桔梗 16x32。足元＝竹筒の底
$b = NewBmp 16 32
Stem $b 8 17 8 5; Stem $b 8 17 4 8; Stem $b 8 17 12 9; Stem $b 8 17 5 12
Ellipse $b 5 14 2.4 1 $g2; Ellipse $b 12 14 2.4 1 $g2; Ellipse $b 9 11 1.6 0.8 $g2
Kikyo $b 8 4; Kikyo $b 3 8; Kikyo $b 13 8
Chrys $b 6 12 1.7 $ye0 $ye1 $ye2
# 竹筒
Rect $b 4 17 8 14 $k; Rect $b 5 17 6 14 $g1; Rect $b 5 17 2 14 $g0; Rect $b 9 17 2 14 $g3
Rect $b 4 17 8 2 $k; Rect $b 5 18 6 1 $g4
Rect $b 4 24 8 1 $g4; Rect $b 4 30 8 2 $k; Rect $b 5 30 6 1 $g3
Save $b 'sadokado_ike_take.png'

# ---- 床の間の小さな花 10x17
$b = NewBmp 10 17
Stem $b 5 10 5 4; Stem $b 5 10 2 6; Stem $b 5 10 8 5
Chrys $b 5 3 1.8 $cr0 $pk0 $pk1
Disc $b 2 5 1.3 $pk1; Disc $b 8 4 1.3 $ye1
Rect $b 2 10 6 6 $k; Rect $b 3 10 4 5 $cr0; Rect $b 3 10 1 5 $cr1; Rect $b 6 10 1 5 $cr2; Rect $b 3 13 4 1 $ai1
Save $b 'sadokado_ike_small.png'

# ---- 立て札（華道 / 野点） 30x32。足元＝柱の根元
function Tag($name, $text, $col) {
  $b = NewBmp 30 24
  Rect $b 13 14 4 10 $k; Rect $b 14 14 2 9 $wd2; Rect $b 14 14 1 9 $wd1
  Rect $b 0 0 30 18 $k; Rect $b 1 1 28 16 $col; Rect $b 1 1 28 1 $cr0; Rect $b 1 16 28 1 $wd3
  Rect $b 2 2 26 14 $wd0; Rect $b 2 2 26 1 $cr0
  [void](TextPx $b $text 4 3 12 $sumi $true)
  Px $b 0 0 $clear; Px $b 29 0 $clear; Px $b 0 17 $clear; Px $b 29 17 $clear
  Save $b $name
}
Tag 'sadokado_tag_kado.png' '華道' $h1
Tag 'sadokado_tag_nodate.png' '野点' $g3

# ---- 石畳（展示台の下） 60x40（床に敷く）
$b = NewBmp 60 40
Rect $b 0 0 60 40 $st3
$yy = 1
while ($yy -lt 39) {
  $hgt = 8 + $rnd.Next(3); if ($yy + $hgt -gt 39) { $hgt = 39 - $yy }
  $xx = 1
  while ($xx -lt 59) {
    $wid = 11 + $rnd.Next(9); if ($xx + $wid -gt 59) { $wid = 59 - $xx }
    $sc = switch ($rnd.Next(3)) { 0 { $st1 } 1 { (C '#c3c0b6') } default { (C '#aeaba2') } }
    Rect $b $xx $yy ($wid - 1) ($hgt - 1) $sc
    Rect $b $xx $yy ($wid - 1) 1 $st0
    for ($i = 0; $i -lt 3; $i++) { Px $b ($xx + 1 + $rnd.Next([math]::Max(1, $wid - 3))) ($yy + 2 + $rnd.Next([math]::Max(1, $hgt - 4))) $st2 }
    $xx += $wid
  }
  $yy += $hgt
}
foreach ($p in @(@(0, 0), @(59, 0), @(0, 39), @(59, 39), @(1, 0), @(58, 0), @(0, 1), @(59, 1), @(1, 39), @(58, 39), @(0, 38), @(59, 38))) { Px $b $p[0] $p[1] $clear }
Save $b 'sadokado_slabs.png'

# ======== 茶庭（庭の飾り）========
# ---- 石灯籠 18x34。足元＝基礎の底
$b = NewBmp 18 34
Ellipse $b 9 2.5 2.4 2.4 $st1; Px $b 8 1 $st0; Px $b 9 0 $st0
# 笠
Rect $b 7 4 4 1 $st1; Rect $b 5 5 8 1 $st1; Rect $b 4 6 10 1 $st0; Rect $b 2 7 14 1 $st1; Rect $b 1 8 16 1 $st1; Rect $b 0 9 18 2 $st2; Rect $b 0 9 18 1 $st0
Rect $b 3 11 12 1 $st3
# 火袋
Rect $b 4 12 10 9 $st1; Rect $b 4 12 2 9 $st0; Rect $b 12 12 2 9 $st2
Rect $b 6 14 6 5 $st3; Rect $b 7 15 4 3 (C '#ffd36b'); Px $b 7 15 (C '#fff0b0'); Px $b 10 17 (C '#ffab3c')
# 中台・竿・基礎
Rect $b 3 21 12 2 $st0; Rect $b 3 22 12 1 $st2
Rect $b 6 23 6 8 $st1; Rect $b 6 23 2 8 $st0; Rect $b 10 23 2 8 $st2
Rect $b 3 31 12 3 $st2; Rect $b 3 31 12 1 $st0
Px $b 7 28 $g2; Px $b 6 29 $g2; Px $b 4 33 $g2; Px $b 5 33 $g1
Outline $b $k
Save $b 'sadokado_lantern.png'

# ---- 竹垣（建仁寺垣） 48x26。足元＝垣の下
$b = NewBmp 48 26
for ($x = 1; $x -lt 47; $x += 3) {
  Rect $b $x 3 3 22 (C '#a9b95e'); Rect $b $x 3 1 22 (C '#cfdc7e'); Rect $b ($x + 2) 3 1 22 (C '#869a46')
  Px $b ($x + 1) 3 (C '#e2eca0')
}
# 横竹と結び
foreach ($ry in @(7, 15, 22)) { Rect $b 0 $ry 48 2 $wd3; Rect $b 0 $ry 48 1 $wd2 }
foreach ($ry in @(7, 15, 22)) { for ($x = 5; $x -lt 46; $x += 12) { Rect $b $x ($ry - 1) 3 4 $k; Px $b ($x + 1) $ry $wd0 } }
# 玉縁（上の丸竹）と柱
Rect $b 0 0 48 4 $k; Rect $b 0 0 48 3 $g2; Rect $b 0 0 48 1 $g0; Rect $b 0 2 48 1 $g3
for ($x = 10; $x -lt 48; $x += 16) { Rect $b $x 0 1 3 $g4 }
Rect $b 0 3 3 23 $k; Rect $b 1 3 1 23 $wd1; Rect $b 45 3 3 23 $k; Rect $b 46 3 1 23 $wd1
Rect $b 0 24 48 2 $k; Rect $b 3 24 42 1 (C '#5a4a2a')
Save $b 'sadokado_fence.png'

# ---- 竹（ゆれる 4コマ） 1コマ 34x70
$fr = 4; $fw = 34; $fh = 54
$b = NewBmp ($fw * $fr) $fh
$bendTab = @(0, 1, 2, 1)
function Blade($b, $x, $y, $dir, $len, $col) {
  $dir = [int]$dir
  for ($i = 0; $i -lt $len; $i++) { $yy = $y + [math]::Floor($i * 0.45); Px $b ($x + $dir * $i) $yy $col; if ($i -gt 0 -and $i -lt $len - 1) { Px $b ($x + $dir * $i) ($yy + 1) $g2 } }
}
for ($f = 0; $f -lt $fr; $f++) {
  $ox = $f * $fw; $bend = $bendTab[$f]
  foreach ($st in @(@(9, 50), @(17, 42), @(25, 34))) {
    $bx = $st[0]; $H = $st[1]
    for ($y = 53; $y -ge 53 - $H; $y--) {
      $t = (53 - $y) / [double]$H; $xo = [math]::Round($bend * $t * $t * 2)
      $x = $ox + $bx + $xo
      Px $b ($x - 1) $y $g4; Px $b $x $y $g1; Px $b ($x + 1) $y $g2; Px $b ($x + 2) $y $g3; Px $b ($x + 3) $y $g4
      if (($y % 11) -eq 3) { Rect $b ($x - 1) $y 5 1 $g4; Px $b $x ($y - 1) $g0 }
    }
    # 葉
    $tx = $ox + $bx + [math]::Round($bend * 2); $ty = 53 - $H
    Blade $b ($tx + 2) ($ty + 2) 1 7 $g1; Blade $b ($tx + 1) ($ty + 3) -1 7 $g2; Blade $b ($tx + 2) $ty 1 5 $g0; Blade $b ($tx + 1) ($ty + 7) -1 6 $g1; Blade $b ($tx + 2) ($ty + 8) 1 6 $g2
    $ny = 53 - [int]($H * 0.5); $nx = $ox + $bx + [math]::Round($bend * 0.5)
    Blade $b ($nx + 3) $ny 1 6 $g1; Blade $b ($nx - 1) ($ny + 2) -1 6 $g2
  }
}
Save $b 'sadokado_bamboo.png'

# ---- 玉砂利の庭と飛び石 80x34（床に敷く）。足元＝手前の縁
$b = NewBmp 80 34
Rect $b 0 0 80 34 (C '#dcd6c4')
$gA = C '#cbc4af'; $gB = C '#eee9db'
for ($i = 0; $i -lt 420; $i++) { $cc = if ($rnd.Next(2) -eq 0) { $gA } else { $gB }; Px $b ($rnd.Next(80)) ($rnd.Next(34)) $cc }
# 砂紋（熊手の筋）
for ($y = 3; $y -lt 33; $y += 4) { for ($x = 2; $x -lt 78; $x++) { $yy = $y + [math]::Round(1.2 * [math]::Sin($x / 5.0 + $y)); Px $b $x $yy (C '#bdb6a0') } }
# 縁の石
$edge = @()
for ($x = 4; $x -lt 80; $x += 9) { $edge += , @($x, 33) }
for ($y = 4; $y -lt 34; $y += 8) { $edge += , @(1, $y); $edge += , @(78, $y) }
foreach ($e in $edge) {
  $rx = 3.2 + $rnd.Next(3) * 0.5; $ry = 2.4 + $rnd.Next(2) * 0.6
  Ellipse $b $e[0] ($e[1] + 0.5) ($rx + 0.8) ($ry + 0.8) $st3; Ellipse $b $e[0] $e[1] $rx $ry $st1; Ellipse $b ($e[0] - 1) ($e[1] - 1) ($rx * 0.55) ($ry * 0.5) $st0
}
# 飛び石（中央、ジグザグ）
$stones = @(@(41, 3), @(37, 11), @(43, 19), @(39, 27))
foreach ($s in $stones) {
  Ellipse $b $s[0] ($s[1] + 1.4) 7.6 4.2 (C '#9a9588'); Ellipse $b $s[0] $s[1] 7 3.8 $st1; Ellipse $b ($s[0] - 1) ($s[1] - 1) 5 2.4 $st0
  Px $b ($s[0] + 3) ($s[1] + 1) $st2; Px $b ($s[0] - 3) $s[1] $st2
}
Px $b 0 0 $clear; Px $b 79 0 $clear
Save $b 'sadokado_gravel.png'

# ---- つくばい（手水鉢） 26x24。足元＝石の底
$b = NewBmp 26 24
Rect $b 5 12 16 11 $st2; Rect $b 6 12 14 10 $st1; Rect $b 6 12 3 10 $st0; Rect $b 17 12 3 10 $st2
Ellipse $b 13 12 12 5 $k; Ellipse $b 13 12 11 4.2 $st0; Ellipse $b 13 12.4 8.8 3.1 $ai1; Ellipse $b 12 12 7 2.2 $ai0
Px $b 16 12 $cr0; Px $b 9 11 $cr0
# 筧（竹の水口）
Line $b 1 2 10 9 $g3; Line $b 1 3 10 10 $g1; Line $b 2 3 11 10 $g2
Rect $b 0 1 3 4 $k; Rect $b 1 2 1 2 $g0
Rect $b 10 10 1 3 $ai0; Px $b 10 13 $cr0
# 柄杓
Line $b 14 10 24 6 $wd2; Line $b 14 11 24 7 $wd3; Rect $b 11 9 4 3 $wd1; Rect $b 11 9 4 1 $wd0
Rect $b 3 23 20 1 $st3
Outline $b $k
Save $b 'sadokado_tsukubai.png'

# ======== のぼり（茶道 / 華道） 4コマのはためき ========
function Nobori($name, $c1, $c2, $word, $iconKind) {
  $bw = 22; $bh = 56
  $bn = NewBmp $bw $bh
  Rect $bn 0 0 $bw $bh $k; Rect $bn 1 1 ($bw - 2) ($bh - 2) $c1; Rect $bn 1 1 1 ($bh - 2) $c2; Rect $bn ($bw - 2) 1 1 ($bh - 2) $c2
  Rect $bn 2 3 ($bw - 4) 1 $cr0; Rect $bn 2 ($bh - 5) ($bw - 4) 1 $cr0
  [void](TextPx $bn $word.Substring(0, 1) 3 6 16 $cr0 $true)
  [void](TextPx $bn $word.Substring(1, 1) 3 23 16 $cr0 $true)
  if ($iconKind -eq 'tea') { TeaBowlIcon $bn 5 ($bh - 13) } else { FlowerIcon $bn 5 ($bh - 15) $cr1 $pk1 }
  Px $bn 0 0 $clear; Px $bn ($bw - 1) 0 $clear
  for ($i = 0; $i -lt 3; $i++) { Rect $bn (3 + $i * 8) ($bh - 1) 2 1 $clear; Rect $bn (4 + $i * 8) ($bh - 2) 1 1 $clear }
  $fr = 4; $fw = 30; $fh = 70
  $b = NewBmp ($fw * $fr) $fh
  for ($f = 0; $f -lt $fr; $f++) {
    $ox = $f * $fw
    Rect $b ($ox + 0) 0 2 $fh $k; Rect $b ($ox + 0) 2 1 ($fh - 2) $wd2
    Rect $b ($ox + 0) 0 14 1 $k; Rect $b ($ox + 0) 3 14 1 $k
    for ($y = 0; $y -lt $bh; $y++) {
      $sh = [math]::Round(0.8 + 0.8 * [math]::Sin($f * [math]::PI / 2 + $y / 16.0))
      for ($x = 0; $x -lt $bw; $x++) {
        $c = $bn.GetPixel($x, $y)
        if ($c.A -gt 0) { Px $b ($ox + 3 + $sh + $x) (4 + $y) $c }
      }
    }
    Rect $b ($ox + 0) 0 2 4 $k
  }
  Save $b $name
}
Nobori 'sadokado_nobori_cha.png' $g3 $g4 '茶道' 'tea'
Nobori 'sadokado_nobori_hana.png' $h1 $h2 '華道' 'flower'

# ======== アニメ ========
# ---- 湯気 6コマ（1コマ 11x20）
$fr = 6; $fw = 11; $fh = 20
$b = NewBmp ($fw * $fr) $fh
for ($f = 0; $f -lt $fr; $f++) {
  foreach ($ph in @(0.0, 2.4)) {
    for ($y = 0; $y -lt $fh - 2; $y++) {
      $x = 5 + [math]::Round(2.0 * [math]::Sin(($y + $f * 3.0) / 3.0 + $ph))
      $a = [int](225 * [math]::Sin([math]::PI * ($fh - $y) / $fh) * [math]::Min(1.0, ($fh - $y) / 5.0))
      if ($a -gt 25) { Px $b ($f * $fw + $x) $y ([System.Drawing.Color]::FromArgb([math]::Min(220, $a), 255, 255, 255)) }
    }
  }
}
Save $b 'sadokado_steam.png'

# ---- 舞う紅葉と花びら 12コマ（1コマ 44x60）
$fr = 12; $fw = 44; $fh = 60
$b = NewBmp ($fw * $fr) $fh
$leaves = @(
  @(8, 0, 0.0, 's'), @(20, 22, 1.7, 'p'), @(33, 41, 3.1, 's'), @(12, 33, 4.4, 'y'), @(28, 10, 5.2, 'p'), @(38, 52, 2.2, 'y'), @(4, 49, 0.8, 'p')
)
for ($f = 0; $f -lt $fr; $f++) {
  foreach ($lf in $leaves) {
    $y = ($lf[1] + $f * 5) % $fh
    $x = $lf[0] + 5 * [math]::Sin(2 * [math]::PI * $f / $fr + $lf[2])
    $al = 235; if ($y -lt 7) { $al = 40 + $y * 27 } elseif ($y -gt $fh - 9) { $al = 40 + ($fh - $y) * 22 }
    $al = [math]::Min(235, [math]::Max(0, $al))
    switch ($lf[3]) { 's' { $c1 = $s1; $c2 = $s2 } 'p' { $c1 = $pk1; $c2 = $pk0 } default { $c1 = $ye1; $c2 = $ye0 } }
    $c1a = [System.Drawing.Color]::FromArgb([int]$al, $c1.R, $c1.G, $c1.B); $c2a = [System.Drawing.Color]::FromArgb([int]$al, $c2.R, $c2.G, $c2.B)
    $xi = [math]::Round($x); $ox = $f * $fw
    if ($lf[3] -eq 's') {
      Px $b ($ox + $xi) $y $c1a; Px $b ($ox + $xi + 1) $y $c1a; Px $b ($ox + $xi - 1) ($y + 1) $c1a; Px $b ($ox + $xi) ($y + 1) $c2a; Px $b ($ox + $xi + 1) ($y + 1) $c1a; Px $b ($ox + $xi) ($y + 2) $c1a
    } else {
      Px $b ($ox + $xi) $y $c1a; Px $b ($ox + $xi + 1) $y $c2a; Px $b ($ox + $xi) ($y + 1) $c2a; Px $b ($ox + $xi + 1) ($y + 1) $c1a
    }
  }
}
Save $b 'sadokado_petals.png'
