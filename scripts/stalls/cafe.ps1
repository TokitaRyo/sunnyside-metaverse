# カフェの専用ドット絵（看板・オーニング・奥の壁・カウンター・コーヒーマシン・ケーキ・カップ・パフェ・丸テーブル・椅子・パラソル・黒板・立て看板・植物・湯気）を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/cafe.ps1   （リポジトリのルートで実行）
# 出力: client/public/brand/stall/cafe_*.png（原点は各スプライトの足元中央。配置は scripts/stalls/cafe.mjs）
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

# ---- 色（クリーム・ミント・茶）
$k = C '#3d2a24'                                                   # 輪郭
$m0 = C '#d8f2e4'; $m1 = C '#a9dfc6'; $m2 = C '#7ccbab'; $m3 = C '#4fa58a'; $m4 = C '#2f7a68'   # ミント（明→暗）
$cr0 = C '#fffaf0'; $cr1 = C '#f6e9d0'; $cr2 = C '#e4d0a8'; $cr3 = C '#c9ad7e'                    # クリーム
$wd0 = C '#efc995'; $wd1 = C '#d49d63'; $wd2 = C '#a86a42'; $wd3 = C '#6e4430'; $wd4 = C '#4a2f23' # 木
$rose = C '#f4a7b9'; $rose2 = C '#d9728d'; $straw = C '#e0435a'; $straw2 = C '#a82a45'
$choc = C '#5a3425'; $latte = C '#b9835a'; $coffee = C '#4a2c1d'; $foam = C '#f3e2c4'
$slate = C '#2d4a42'; $slate2 = C '#3a5c52'; $chalk = C '#f4f2e8'; $yel = C '#ffe27a'
$leaf0 = C '#8fd36a'; $leaf1 = C '#58b35a'; $leaf2 = C '#2f8548'; $leaf3 = C '#1f5e3a'
$steel0 = C '#eef3f4'; $steel1 = C '#c3d0d4'; $steel2 = C '#8fa3aa'; $steel3 = C '#5f747c'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# ---- 道具: 大きい文字用の自前グリフ(8x9)。ＣＡＦＥ を太く描く
$G = @{
  'C' = @('..####..', '.######.', '##....##', '##......', '##......', '##......', '##....##', '.######.', '..####..')
  'A' = @('..####..', '.##..##.', '##....##', '##....##', '########', '########', '##....##', '##....##', '##....##')
  'F' = @('########', '########', '##......', '######..', '######..', '##......', '##......', '##......', '##......')
  'E' = @('########', '########', '##......', '######..', '######..', '##......', '##......', '########', '########')
}
function BigText($b, $s, $x, $y, $col, $shadow) {
  $cx = $x
  foreach ($ch in $s.ToCharArray()) {
    $rows = $G[[string]$ch]
    if ($shadow) { for ($j = 0; $j -lt 9; $j++) { for ($i = 0; $i -lt 8; $i++) { if ($rows[$j][$i] -eq '#') { Px $b ($cx + $i + 1) ($y + $j + 1) $shadow } } } }
    for ($j = 0; $j -lt 9; $j++) { for ($i = 0; $i -lt 8; $i++) { if ($rows[$j][$i] -eq '#') { Px $b ($cx + $i) ($y + $j) $col } } }
    $cx += 10
  }
}
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

# ---- 看板（屋根の上に掲げる）112x28。こげ茶の板に ＣＡＦＥ とカフェ
$b = NewBmp 112 28
Rect $b 14 0 3 6 $wd3; Rect $b 95 0 3 6 $wd3
Rect $b 0 5 112 23 $k; Rect $b 1 6 110 21 $wd2; Rect $b 2 7 108 19 $wd1
Rect $b 3 8 106 17 $coffee; Frame $b 4 9 104 15 $wd1
foreach ($p in @(@(0, 5), @(111, 5), @(0, 27), @(111, 27))) { Px $b $p[0] $p[1] $clear }
Rect $b 3 8 106 1 $wd3
# コーヒーカップの絵
Rect $b 9 17 11 6 $cr0; Rect $b 9 21 11 2 $cr2; Rect $b 11 23 7 1 $cr2; Rect $b 8 23 13 1 $cr3
Rect $b 10 16 9 1 $latte; Rect $b 20 18 3 1 $cr0; Rect $b 22 19 1 2 $cr0; Rect $b 20 21 3 1 $cr0
Px $b 12 12 $m1; Px $b 13 13 $m1; Px $b 12 14 $m1; Px $b 16 11 $m1; Px $b 17 12 $m1; Px $b 16 13 $m1
BigText $b 'CAFE' 28 10 $cr0 $k
$tw = TextWidth 'カフェ' 11
[void](TextPx $b 'カフェ' (107 - $tw) 10 11 $m1 $true)
Save $b 'cafe_sign.png'

# ---- オーニング（ミントとクリームのしま）132x22。手前のへりはまるいスカラップ
$b = NewBmp 132 22
$W = 132
for ($y = 0; $y -lt 9; $y++) {
  $inset = 8 - $y
  for ($x = $inset; $x -lt $W - $inset; $x++) { $s = [math]::Floor($x / 8) % 2; Px $b $x $y $(if ($s -eq 0) { $m2 } else { $cr0 }) }
}
for ($x = 0; $x -lt $W; $x++) { Px $b $x 8 $m3 }
for ($x = 0; $x -lt $W; $x++) { $s = [math]::Floor($x / 8) % 2; if ($s -eq 0) { Px $b $x 0 $m1 } }
for ($y = 9; $y -lt 20; $y++) {
  for ($x = 0; $x -lt $W; $x++) {
    $s = [math]::Floor($x / 8) % 2
    $col = if ($s -eq 0) { $m2 } else { $cr0 }
    $mid = ($x % 8) - 3.5
    if ($y -ge 15) { $lim = [math]::Sqrt([math]::Max(0.0, 16 - $mid * $mid)); if (($y - 15) -gt $lim) { continue } }
    Px $b $x $y $col
  }
}
for ($x = 0; $x -lt $W; $x++) { if ([math]::Floor($x / 8) % 2 -eq 0) { Px $b $x 9 $m1 } else { Px $b $x 9 $cr1 } }
# 影つきのへり（スカラップの下に1段）
for ($x = 0; $x -lt $W; $x++) {
  $mid = ($x % 8) - 3.5; $lim = [math]::Sqrt([math]::Max(0.0, 16 - $mid * $mid))
  $yy = 15 + [math]::Floor($lim)
  if ($yy -lt 22 -and $lim -gt 0) { Px $b $x $yy $(if ([math]::Floor($x / 8) % 2 -eq 0) { $m4 } else { $cr3 }) }
}
Rect $b 0 9 1 8 $m3; Rect $b 131 9 1 8 $m3
Outline $b $k
Save $b 'cafe_awning.png'

# ---- 奥の壁 124x48。ミントの壁、木の柱、棚（カップ・豆の瓶・ティーポット・お皿・観葉植物）、腰板
$b = NewBmp 124 48
Rect $b 0 0 124 48 $m2
for ($x = 6; $x -lt 124; $x += 12) { Rect $b $x 0 1 36 $m3 }              # 板張りの目地
Rect $b 0 0 124 1 $m1
Rect $b 0 20 124 6 $m3                                                      # オーニング下の影
for ($x = 0; $x -lt 124; $x++) { if ($x % 2 -eq 0) { Px $b $x 26 $m3 } }
Rect $b 0 36 124 12 $cr1; Rect $b 0 36 124 1 $cr0; Rect $b 0 37 124 1 $cr2   # 腰板
for ($x = 10; $x -lt 124; $x += 12) { Rect $b $x 38 1 9 $cr2 }
Rect $b 0 46 124 2 $wd2; Rect $b 0 46 124 1 $wd1                            # 幅木
Rect $b 0 0 4 48 $k; Rect $b 1 0 2 48 $wd2; Rect $b 1 0 1 48 $wd1          # 左右の柱
Rect $b 120 0 4 48 $k; Rect $b 121 0 2 48 $wd2; Rect $b 122 0 1 48 $wd3
# 棚板（左と右）
foreach ($sx in @(8, 76)) {
  Rect $b $sx 33 40 3 $wd3; Rect $b $sx 33 40 1 $wd1; Rect $b $sx 36 40 1 $wd4
  Rect $b ($sx + 4) 36 2 4 $wd3; Rect $b ($sx + 34) 36 2 4 $wd3
}
# 左の棚: カップ3つ、豆の瓶、クッキー缶
foreach ($cx in @(11, 18, 25)) {
  Rect $b $cx 28 6 5 $cr0; Rect $b $cx 31 6 2 $cr2; Rect ($b) ($cx + 6) 29 2 3 $cr0; Px $b ($cx + 7) 30 $cr3
  Rect $b $cx 28 6 1 $latte; Rect $b ($cx + 1) 32 4 1 $cr3
}
Rect $b 30 24 9 9 $cr1; Rect $b 30 24 9 1 $wd2; Rect $b 31 23 7 1 $wd2; Rect $b 31 27 7 4 $coffee; Rect $b 32 28 2 2 $wd3; Rect $b 30 24 1 9 $cr0   # 豆の瓶
Rect $b 40 27 7 6 $rose; Rect $b 40 27 7 1 $rose2; Rect $b 40 32 7 1 $rose2; Rect $b 42 29 3 2 $cr0    # 缶
# 右の棚: ティーポット、皿の山、小さな鉢
Rect $b 78 28 9 5 $m4; Rect $b 79 27 7 1 $m4; Rect $b 79 28 3 2 $m1; Rect $b 82 25 3 2 $m3; Px $b 83 24 $m3; Rect $b 87 29 3 1 $m4; Rect $b 77 29 1 2 $m4; Rect $b 78 32 9 1 $m3
for ($i = 0; $i -lt 3; $i++) { Rect $b 94 (31 - $i * 2) 12 2 $cr0; Rect $b 94 (32 - $i * 2) 12 1 $cr2 }
Rect $b 109 29 7 4 $wd1; Rect $b 109 29 7 1 $wd0; Rect $b 110 33 5 1 $wd2
Ellipse $b 112.5 26.5 3.5 3 $leaf1; Px $b 111 25 $leaf0; Px $b 114 26 $leaf2; Px $b 112 28 $leaf2; Px $b 113 23 $leaf1
# 中央: 壁掛けの時計（バリスタの頭より上、オーニングの下には少し隠れる）
Ellipse $b 62 28 4.5 4.5 $k; Ellipse $b 62 28 3.6 3.6 $cr0
Rect $b 62 26 1 3 $wd4; Rect $b 62 28 3 1 $wd4
Save $b 'cafe_wall.png'

# ---- カウンター 116x26。上の面は明るい木、正面はミントの羽目板
$b = NewBmp 116 26
Rect $b 0 0 116 26 $k
Rect $b 1 1 114 8 $wd0; Rect $b 1 1 114 1 $cr0; Rect $b 1 8 114 1 $wd1     # 天板
Rect $b 0 9 116 2 $wd2; Rect $b 1 9 114 1 $wd1                               # 天板の厚み
Rect $b 2 11 112 12 $m2                                                      # 羽目板
for ($x = 6; $x -lt 114; $x += 6) { Rect $b $x 11 1 12 $m3 }
Rect $b 2 11 112 1 $m1; Rect $b 2 22 112 1 $m3
Rect $b 2 23 112 2 $wd3; Rect $b 2 23 112 1 $wd2                             # 足元の木
# 正面の飾り: クリームの帯と小さなコーヒーカップ
Rect $b 36 13 44 8 $cr0; Rect $b 36 13 44 1 $cr1; Frame $b 36 13 44 8 $wd2
Rect $b 56 15 6 4 $cr1; Rect $b 62 16 2 2 $cr1; Rect $b 56 15 6 1 $latte
Px $b 58 14 $m3; Px $b 59 13 $m3
foreach ($p in @(@(0, 0), @(115, 0), @(0, 25), @(115, 25))) { Px $b $p[0] $p[1] $clear }
Save $b 'cafe_counter.png'

# ---- コーヒーマシン 26x28（エスプレッソマシン）
$b = NewBmp 26 28
Rect $b 0 0 26 28 $clear
Rect $b 1 3 24 25 $k
Rect $b 2 4 22 23 $steel1; Rect $b 2 4 22 2 $steel0; Rect $b 2 4 2 23 $steel0; Rect $b 22 4 2 23 $steel2
Rect $b 0 1 26 4 $k; Rect $b 1 2 24 2 $wd2; Rect $b 1 2 24 1 $wd1                  # 上のカップ置き
Rect $b 4 0 5 2 $cr0; Rect $b 11 0 5 2 $cr0; Rect $b 4 1 5 1 $cr3; Rect $b 11 1 5 1 $cr3     # 温め中のカップ
Rect $b 4 8 18 6 $steel3; Rect $b 4 8 18 1 $steel2                                # 操作パネル
Ellipse $b 8 11 2.2 2.2 $cr0; Px $b 8 10 $coffee; Px $b 9 11 $coffee             # ダイヤル
Rect $b 13 10 2 2 $m2; Rect $b 16 10 2 2 $rose; Rect $b 19 10 2 2 $yel           # ボタン
Rect $b 5 15 16 3 $steel2; Rect $b 8 17 3 4 $steel3; Rect $b 15 17 3 4 $steel3   # 抽出口
Rect $b 4 22 18 4 $steel3; Rect $b 4 22 18 1 $steel2                              # 受け皿
Rect $b 9 19 8 5 $cr0; Rect $b 9 19 8 1 $coffee; Rect $b 17 20 2 3 $cr0; Rect $b 9 23 8 1 $cr3   # 受けたカップ
Rect $b 2 26 22 2 $steel3
foreach ($p in @(@(1, 3), @(24, 3), @(1, 27), @(24, 27))) { Px $b $p[0] $p[1] $clear }
Save $b 'cafe_machine.png'

# ---- ショートケーキのドーム 16x17
$b = NewBmp 16 17
Ellipse $b 8 14.5 7.5 2.5 $cr2; Ellipse $b 8 14 7.5 2.3 $cr0
Rect $b 4 8 8 5 $foam; Rect $b 4 10 8 1 $latte; Rect $b 4 12 8 1 $cr3; Rect $b 4 8 8 1 $cr0     # 生クリームとスポンジ
Ellipse $b 6 7.5 1.6 1.4 $straw; Ellipse $b 10 7.5 1.6 1.4 $straw; Px $b 6 6 $straw2; Px $b 10 6 $straw2
$glass = [System.Drawing.Color]::FromArgb(200, 214, 238, 246); $glassHi = [System.Drawing.Color]::FromArgb(230, 255, 255, 255)
for ($y = 2; $y -le 13; $y++) {
  $t = ($y - 13) / 11.0; $half = [math]::Floor(6.5 * [math]::Sqrt([math]::Max(0.0, 1 - $t * $t)) + 0.5)
  if ($half -gt 0) { Px $b (8 - $half) $y $glass; Px $b (7 + $half) $y $glass }
}
for ($x = 4; $x -le 11; $x++) { Px $b $x 1 $glass }
Px $b 7 0 $steel2; Px $b 8 0 $steel2; Px $b 3 4 $glassHi; Px $b 3 5 $glassHi; Px $b 4 3 $glassHi
Save $b 'cafe_dome.png'

# ---- ケーキの皿（いちごショート）14x10
$b = NewBmp 14 10
Ellipse $b 7 7 7 3 $steel1; Ellipse $b 7 6.4 7 2.7 $cr0
Ascii $b 2 0 @(
  '....rq....',
  '...rqqr...',
  '.wwwwwwww.',
  '.wwwwwwww.',
  '.yyyyyyyyc',
  '.wwwwwwww.',
  '.yyyyyyyy.'
) @{ r = $straw; q = $straw2; w = $cr0; y = $latte; c = $cr1 }
Save $b 'cafe_cakeplate.png'

# ---- コーヒーカップ（皿つき）9x8
$b = NewBmp 9 8
Ellipse $b 4.5 5.8 4.5 2 $cr2; Ellipse $b 4.5 5.4 4.5 1.8 $cr0
Rect $b 1 1 6 4 $cr0; Rect $b 1 4 6 1 $cr2; Rect $b 7 2 2 2 $cr0; Px $b 8 3 $clear
Rect $b 1 1 6 1 $coffee; Px $b 3 1 $latte
Save $b 'cafe_cup.png'

# ---- アイスコーヒー 7x11
$b = NewBmp 7 11
Rect $b 1 2 5 8 $coffee; Rect $b 1 2 1 8 $latte; Rect $b 1 1 5 1 $steel0; Rect $b 1 10 5 1 $steel1
Rect $b 0 1 1 9 $steel1; Rect $b 6 1 1 9 $steel1
Rect $b 2 3 2 2 $steel0; Rect $b 4 5 2 2 $steel0
Rect $b 4 0 1 3 $rose2; Px $b 5 0 $rose2
Save $b 'cafe_icecoffee.png'

# ---- パフェ 9x15
$b = NewBmp 9 15
Rect $b 3 12 3 2 $steel1; Rect $b 2 14 5 1 $steel1; Rect $b 4 10 1 3 $steel1
Rect $b 1 5 7 5 $steel0; Rect $b 2 10 5 1 $steel1
Rect $b 2 6 5 1 $rose; Rect $b 2 7 5 1 $choc; Rect $b 2 8 5 1 $cr0; Rect $b 3 9 3 1 $latte
Rect $b 1 3 7 3 $foam; Rect $b 1 3 7 1 $cr0; Rect $b 2 2 5 1 $cr0
Ellipse $b 4.5 1.5 1.5 1.2 $straw; Px $b 4 0 $leaf2; Px $b 7 2 $straw2; Rect $b 6 3 1 1 $choc
Save $b 'cafe_parfait.png'

# ---- ティーポット 11x10
$b = NewBmp 11 10
Rect $b 2 3 6 5 $m1; Rect $b 3 2 4 1 $m1; Rect $b 2 7 6 1 $m3; Rect $b 3 1 2 1 $m3
Rect $b 8 4 2 1 $m1; Rect $b 9 3 1 1 $m1; Rect $b 0 3 2 1 $m3; Rect $b 0 4 1 2 $m3; Rect $b 1 6 1 1 $m3
Rect $b 3 4 1 2 $m0; Rect $b 3 8 4 1 $m3
Px $b 4 0 $m3
Save $b 'cafe_teapot.png'

# ---- 丸テーブル 28x22（足元中央。天板の中心は足元から15px上）
$b = NewBmp 28 22
Ellipse $b 14 20 6 1.8 $wd3                                                   # 台座
Rect $b 12 11 4 9 $wd3; Rect $b 12 11 1 9 $wd2
Ellipse $b 14 9 13.5 6 $wd3                                                   # 天板の厚み
Ellipse $b 14 7 13.5 6 $k; Ellipse $b 14 7 12.6 5.2 $cr0
Ellipse $b 14 7 10 3.6 $cr1
for ($i = 0; $i -lt 5; $i++) { Px $b (6 + $i * 4) 7 $m2; Px $b (8 + $i * 4) 8 $m2; Px $b (7 + $i * 4) 6 $m2 }   # ミントのチェック
Rect $b 3 7 2 1 $m2; Rect $b 23 7 2 1 $m2
Save $b 'cafe_table.png'

# ---- 椅子（前から見た）12x17。背もたれのあるミントのクッション
$b = NewBmp 12 17
Rect $b 1 0 10 8 $k; Rect $b 2 1 8 6 $wd1; Rect $b 2 1 8 1 $wd0; Rect $b 4 2 1 5 $wd3; Rect $b 7 2 1 5 $wd3
Rect $b 0 8 12 4 $k; Rect $b 1 8 10 2 $m2; Rect $b 1 8 10 1 $m1; Rect $b 1 10 10 1 $m3; Rect $b 1 11 10 1 $wd2
Rect $b 1 12 2 5 $k; Rect $b 9 12 2 5 $k; Rect $b 1 12 1 5 $wd2; Rect $b 9 12 1 5 $wd2
Save $b 'cafe_chair.png'

# ---- 椅子（後ろから見た）12x17。背もたれが手前
$b = NewBmp 12 17
Rect $b 1 3 10 9 $k; Rect $b 2 4 8 7 $wd1; Rect $b 2 4 8 1 $wd0; Rect $b 2 10 8 1 $wd2
Rect $b 5 5 2 4 $wd2
Rect $b 0 0 12 3 $k; Rect $b 1 1 10 1 $m2
Rect $b 1 12 2 5 $k; Rect $b 9 12 2 5 $k; Rect $b 1 12 1 5 $wd2; Rect $b 9 12 1 5 $wd2
Save $b 'cafe_chair_back.png'

# ---- パラソル（ミント / ローズ）44x32。足元が柱の根元（x=22）。丸いドームに骨と先端の飾り
function Parasol($name, $c1, $c2, $c3) {
  $b = NewBmp 44 32
  Rect $b 21 14 2 18 $wd3; Rect $b 21 14 1 18 $wd2; Rect $b 20 30 4 2 $wd3
  for ($y = 0; $y -le 13; $y++) {
    $half = [math]::Floor(21.5 * [math]::Sqrt([math]::Max(0.0, 1 - [math]::Pow((13.5 - $y) / 14.5, 2))) + 0.5)
    for ($x = 22 - $half; $x -lt 22 + $half; $x++) {
      $seg = [math]::Floor(($x + 2) / 6) % 2
      $col = if ($seg -eq 0) { $c1 } else { $cr0 }
      Px $b $x $y $col
    }
  }
  # 縁のスカラップ
  for ($x = 1; $x -lt 43; $x++) {
    $seg = [math]::Floor(($x + 2) / 6) % 2
    $col = if ($seg -eq 0) { $c1 } else { $cr0 }
    $mid = (($x + 2) % 6) - 2.5
    $dep = if ([math]::Abs($mid) -lt 1.6) { 2 } else { 1 }
    for ($y = 14; $y -lt 14 + $dep + 1; $y++) { Px $b $x $y $col }
  }
  for ($x = 1; $x -lt 43; $x++) { Px $b $x 14 $(if ([math]::Floor(($x + 2) / 6) % 2 -eq 0) { $c2 } else { $cr1 }) }
  # 右側の影
  for ($y = 2; $y -le 13; $y++) { $half = [math]::Floor(21.5 * [math]::Sqrt([math]::Max(0.0, 1 - [math]::Pow((13.5 - $y) / 14.5, 2))) + 0.5); Px $b (22 + $half - 1) $y $c2; Px $b (22 + $half - 2) $y $c2 }
  for ($x = 17; $x -lt 27; $x++) { Px $b $x 0 $c3 }
  Rect $b 21 0 2 2 $wd3; Px $b 21 0 $wd1
  Outline $b $k
  Save $b $name
}
Parasol 'cafe_parasol_mint.png' $m2 $m3 $m1
Parasol 'cafe_parasol_rose.png' $rose $rose2 (C '#ffd3de')

# ---- 立て看板の黒板 60x56（足元が原点）
$b = NewBmp 60 56
Rect $b 0 0 60 48 $k; Rect $b 1 1 58 46 $wd1; Rect $b 1 1 58 1 $wd0; Rect $b 3 3 54 42 $slate
Rect $b 3 3 54 1 $slate2; Frame $b 4 4 52 40 $slate2
Rect $b 9 48 3 8 $wd3; Rect $b 48 48 3 8 $wd3; Rect $b 9 48 1 8 $wd2; Rect $b 48 48 1 8 $wd2
Rect $b 8 45 44 3 $wd2
$rows = @(@('コーヒー', $yel), @('ケーキ', $chalk), @('パフェ', $chalk))
for ($i = 0; $i -lt 3; $i++) {
  [void](TextPx $b $rows[$i][0] 6 (5 + 12 * $i) 12 $rows[$i][1] $false)
}
# チョークの落書き: ハート（ケーキ・パフェの横）
Px $b 47 20 $rose; Px $b 49 20 $rose; Rect $b 46 21 5 1 $rose; Rect $b 47 22 3 1 $rose; Px $b 48 23 $rose
Px $b 47 32 $rose; Px $b 49 32 $rose; Rect $b 46 33 5 1 $rose; Rect $b 47 34 3 1 $rose; Px $b 48 35 $rose
Save $b 'cafe_board.png'

# ---- 立て看板（柱から吊るカフェ看板）50x66。柱の根元が原点 (x=7, y=66)
$b = NewBmp 50 66
Rect $b 5 8 5 58 $k; Rect $b 6 8 3 58 $wd2; Rect $b 6 8 1 58 $wd1; Rect $b 8 8 1 58 $wd3
Ellipse $b 7.5 6 3.5 3.5 $k; Ellipse $b 7.5 6 2.6 2.6 $wd0
Rect $b 8 12 40 3 $k; Rect $b 9 13 38 1 $wd2                                 # 腕
Rect $b 9 15 4 1 $k; Rect $b 11 16 2 1 $k                                    # つっかえ
Rect $b 14 15 1 6 $steel3; Rect $b 44 15 1 6 $steel3                         # 鎖
Rect $b 10 20 38 30 $k; Rect $b 11 21 36 28 $cr0; Frame $b 12 22 34 26 $wd2
Rect $b 11 21 36 1 $cr1
# カップの絵
Rect $b 25 26 9 5 $m3; Rect $b 25 29 9 2 $m4; Rect $b 34 27 3 1 $m3; Rect $b 36 28 1 2 $m3; Rect $b 34 30 3 1 $m3; Rect $b 26 31 7 1 $m4
Rect $b 26 26 7 1 $coffee
Px $b 27 23 $wd1; Px $b 28 24 $wd1; Px $b 27 25 $wd1; Px $b 31 23 $wd1; Px $b 32 24 $wd1; Px $b 31 25 $wd1
[void](TextPx $b 'カフェ' 13 34 11 $wd3 $false)
Rect $b 5 64 8 2 $k; Rect $b 6 64 6 1 $wd3
Save $b 'cafe_signpost.png'

# ---- テラスの木のデッキ 168x46（床に敷く）
$b = NewBmp 168 46
Rect $b 0 0 168 46 $k
for ($y = 0; $y -lt 44; $y += 4) {
  $row = $y / 4
  Rect $b 1 ($y + 1) 166 3 $(if ($row % 2 -eq 0) { $wd0 } else { $wd1 })
  Rect $b 1 ($y + 1) 166 1 $(if ($row % 2 -eq 0) { $cr0 } else { $wd0 })
  $off = ($row * 37) % 41
  for ($x = 4 + $off; $x -lt 166; $x += 41) { Rect $b $x ($y + 1) 1 3 $wd2 }
}
Rect $b 1 43 166 2 $wd3
foreach ($p in @(@(0, 0), @(167, 0), @(0, 45), @(167, 45), @(1, 0), @(166, 0), @(0, 1), @(167, 1))) { Px $b $p[0] $p[1] $clear }
Save $b 'cafe_deck.png'

# ---- 植木鉢の大きな観葉植物 24x36（葉を放射状に）
function Leaf($b, $x0, $y0, $x1, $y1, $col, $hi) {
  $n = 14
  for ($i = 0; $i -le $n; $i++) {
    $t = $i / $n; $x = $x0 + ($x1 - $x0) * $t; $y = $y0 + ($y1 - $y0) * $t
    $r = 1.2 + 3.0 * [math]::Sin([math]::PI * [math]::Min(1.0, $t * 1.15))
    Ellipse $b $x $y $r ($r * 0.8) $col
  }
  Line $b ([int]$x0) ([int]$y0) ([int]$x1) ([int]$y1) $hi
}
$b = NewBmp 24 36
Leaf $b 12 25 3 14 $leaf2 $leaf3
Leaf $b 12 25 21 14 $leaf2 $leaf3
Leaf $b 12 25 6 6 $leaf1 $leaf3
Leaf $b 12 25 18 7 $leaf1 $leaf3
Leaf $b 12 25 12 3 $leaf0 $leaf2
Outline $b $leaf3
Rect $b 5 25 14 11 $k; Rect $b 6 26 12 9 $wd1; Rect $b 5 25 14 2 $wd2; Rect $b 6 26 12 1 $wd0; Rect $b 6 33 12 2 $wd2
Rect $b 4 24 16 1 $k; Rect $b 6 25 12 1 $leaf3
Save $b 'cafe_plant.png'
# ---- 湯気（アニメ）6コマ。1コマ 9x18 を横に並べる
$fr = 6; $fw = 9; $fh = 18
$b = NewBmp ($fw * $fr) $fh
for ($f = 0; $f -lt $fr; $f++) {
  for ($y = 0; $y -lt $fh; $y++) {
    $ph = ($y + $f * 3) / 2.6
    $x = 4 + [math]::Round(2.0 * [math]::Sin($ph))
    $a = [int](235 * [math]::Sin([math]::PI * ($fh - $y) / $fh) * [math]::Min(1.0, ($fh - $y) / 6.0))
    if ($y -ge $fh - 2) { $a = 0 }
    if ($a -gt 20) {
      $col = [System.Drawing.Color]::FromArgb([math]::Min(230, $a), 255, 255, 255)
      Px $b ($f * $fw + $x) $y $col
      if ($y % 3 -ne 0) { Px $b ($f * $fw + $x + 1) $y ([System.Drawing.Color]::FromArgb([math]::Min(200, [int]($a * 0.7)), 255, 255, 255)) }
    }
  }
}
Save $b 'cafe_steam.png'
