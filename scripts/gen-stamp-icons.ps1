# スタンプラリー用アイコン 34個 (16x16) を横一列のスプライトシートに描く。
# 実行: リポジトリのルートで powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen-stamp-icons.ps1
# 各フレームは「塗りだけ」を描き、最後に外側へ1pxの濃い縁取り(AutoOutline)を自動で付ける。
$script:OutDir = "client/public/brand/stamps"
. "$PSScriptRoot\lib\pixel.ps1"

$OL = C '#3a2230'
$FRAMES = 34

function NewFrame { NewBmp 16 16 }
# 透明ピクセルで、上下左右に不透明ピクセルが隣接しているものを縁取り色にする
function AutoOutline($b, $col) {
  $todo = New-Object System.Collections.ArrayList
  for ($y = 0; $y -lt $b.Height; $y++) {
    for ($x = 0; $x -lt $b.Width; $x++) {
      if ($b.GetPixel($x, $y).A -eq 0) {
        $hit = $false
        foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
          $nx = $x + $d[0]; $ny = $y + $d[1]
          if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $b.Width -and $ny -lt $b.Height -and $b.GetPixel($nx, $ny).A -gt 0) { $hit = $true }
        }
        if ($hit) { [void]$todo.Add(@($x, $y)) }
      }
    }
  }
  foreach ($p in $todo) { $b.SetPixel($p[0], $p[1], $col) }
}
function CheckRows($rows, $name) {
  if ($rows.Count -gt 16) { Write-Host "WARN $name : $($rows.Count) rows" }
  for ($i = 0; $i -lt $rows.Count; $i++) { if ($rows[$i].Length -ne 16) { Write-Host "WARN $name row $i length $($rows[$i].Length): $($rows[$i])" } }
}
function Blit($sheet, $f, $ox) {
  for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) { $c = $f.GetPixel($x, $y); if ($c.A -gt 0) { $sheet.SetPixel($ox + $x, $y, $c) } } }
}
# 整数座標の円(中心 cx,cy は小数可)。dark 縁付きでボールを描く
function Ball($f, $cx, $cy, $r, $body, $edge) {
  Ellipse $f $cx $cy ($r + 0.9) ($r + 0.9) $edge
  Ellipse $f $cx $cy $r $r $body
}

$sheet = NewBmp (16 * $FRAMES) 16
$f = $null

# ---------- 0 okonomiyaki: 皿の上の丸いお好み焼き ----------
$f = NewFrame
$rows = @(
  '................',
  '................',
  '....SSSMSSSS....',
  '...SSMSSSMSGS...',
  '..SSMSGSSMSSMS..',
  '..SMSSSMSGSSMS..',
  '..SSSMSSSMSSSS..',
  '..SGSSMSSSMSSS..',
  '...SSSMSSSGSS...',
  '.PPPSSSSSSSSPPP.',
  '.PPPPPPPPPPPPPP.',
  '.QPPPPPPPPPPPPQ.',
  '..QQQQQQQQQQQQ..'
)
CheckRows $rows 'f0'
Ascii $f 0 0 $rows @{ S = (C '#b5612f'); M = (C '#fff3d0'); G = (C '#4fae4a'); P = (C '#f7efe0'); Q = (C '#cdbfa6') }
AutoOutline $f $OL; Blit $sheet $f 0

# ---------- 1 taiyaki: 金茶色の魚 ----------
$f = NewFrame
$rows = @(
  '................',
  '................',
  '....GGGGGG......',
  '..GGGHHGGGG.D.D.',
  '.GGGHGGGGGGGDDD.',
  '.GGOGGGGGGGGDDD.',
  '.GGGGGGGGGGGDD..',
  '.GHGGGGGGGGGDD..',
  '.GGGGGGGGGGGDD..',
  '.GGGGGGGGGGDD...',
  '..GGGGGGGGGDDDD.',
  '...GGGGGGGG.D.D.',
  '.....GGGGG......'
)
CheckRows $rows 'f1'
Ascii $f 0 0 $rows @{ G = (C '#f2a63b'); H = (C '#ffd98a'); D = (C '#c46a1c'); O = $OL }
# えらの線とうろこ
foreach ($p in @(@(6, 4), @(6, 5), @(6, 6), @(6, 7), @(8, 5), @(9, 6), @(10, 5), @(8, 7), @(10, 7), @(9, 8))) { Px $f $p[0] ($p[1] + 1) (C '#d98a2b') }
foreach ($p in @(@(2, 5), @(3, 5), @(2, 6), @(3, 6))) { Px $f $p[0] $p[1] $OL }
Px $f 2 5 (C '#fff8ec')
foreach ($p in @(@(12, 5), @(13, 4), @(13, 10), @(12, 9), @(13, 7))) { Px $f $p[0] $p[1] (C '#e8903a') }
AutoOutline $f $OL; Blit $sheet $f 16

# ---------- 2 cafe: 湯気のコーヒーカップ ----------
$f = NewFrame
$rows = @(
  '................',
  '................',
  '................',
  '................',
  '..WWWWWWWWWW....',
  '..WKKKKKKKKW....',
  '..TTTTTTTTTTTTT.',
  '..THTTTTTTTT.TT.',
  '..THTTTTTTTT.TT.',
  '..TTTTTTTTTTTT..',
  '...TTTTTTDD.....',
  '....DDDDDD......',
  '.WWWWWWWWWWWWWW.',
  '..GGGGGGGGGGGG..'
)
CheckRows $rows 'f2'
Ascii $f 0 0 $rows @{ W = (C '#fff8ec'); K = (C '#6b3b25'); T = (C '#58c7c4'); H = (C '#b4f5f0'); D = (C '#2f948f'); G = (C '#c9c3d6') }
AutoOutline $f $OL
$steam = C '#a9c6ea'
foreach ($p in @(@(6, 2), @(7, 1), @(6, 0), @(10, 2), @(11, 1), @(10, 0))) { Px $f $p[0] $p[1] $steam }
Blit $sheet $f 32

# ---------- 3 chocobanana: チョコバナナ ----------
$f = NewFrame
$rows = @(
  '................',
  '................',
  '..........CCC...',
  '.........CCLCC..',
  '........CCLCCBC.',
  '.......CCLCCPC..',
  '......CCLCGCC...',
  '.....YYHCCPC....',
  '....YYHYCCC.....',
  '...YYHYYCC......',
  '....YYYY........',
  '...TT...........',
  '..TT............',
  '.TT.............',
  '.T..............'
)
CheckRows $rows 'f3'
Ascii $f 0 0 $rows @{ C = (C '#7b4128'); L = (C '#a8683f'); P = (C '#ff6fae'); B = (C '#5cc8ff'); G = (C '#7ddf64'); Y = (C '#ffd84a'); H = (C '#fff2a0'); T = (C '#e9c590') }
AutoOutline $f $OL; Blit $sheet $f 48

# ---------- 4 takoyaki: たこ焼き3個とピック ----------
$f = NewFrame
Rect $f 1 11 14 3 (C '#ead7ac')
Rect $f 1 13 14 1 (C '#c9a45e')
$ballc = C '#eab158'; $sauce = C '#8f4524'; $mayo = C '#fff3d0'; $bonito = C '#fbd9bd'; $green = C '#4fae4a'
$ballEdge = C '#6b3a22'
Ball $f 4.5 8.5 3.6 $ballc $ballEdge
Ball $f 11.5 8.5 3.6 $ballc $ballEdge
Ball $f 8 4.5 3.6 $ballc $ballEdge
foreach ($c in @(@(4.5, 8.5), @(11.5, 8.5), @(8, 4.5))) {
  Ellipse $f $c[0] ($c[1] - 0.8) 2.3 1.7 $sauce
  $x = [int][math]::Floor($c[0]); $y = [int][math]::Floor($c[1])
  Px $f ($x - 1) ($y - 1) $mayo; Px $f $x $y $mayo; Px $f ($x + 1) ($y - 1) $mayo
  Px $f ($x + 1) ($y + 1) $bonito; Px $f ($x - 2) $y $bonito
  Px $f ($x - 1) ($y + 1) $green
}
Line $f 14 1 10 3 (C '#e9c590')
AutoOutline $f $OL; Blit $sheet $f 64

# ---------- 5 shateki: 赤白の的に刺さった矢 ----------
$f = NewFrame
Ellipse $f 8 8 6.2 6.2 (C '#e53935')
Ellipse $f 8 8 4.7 4.7 (C '#fff8ec')
Ellipse $f 8 8 3.2 3.2 (C '#e53935')
Ellipse $f 8 8 1.6 1.6 (C '#ffd84a')
Line $f 8 8 12 4 (C '#5a3520')
$fl = C '#3aa0ff'
Line $f 12 4 14 2 $fl
Px $f 13 4 $fl; Px $f 12 3 $fl; Px $f 14 3 $fl; Px $f 13 2 $fl
AutoOutline $f $OL; Blit $sheet $f 80

# ---------- 6 suisougaku: トランペットと音符 ----------
$f = NewFrame
$rows = @(
  '................',
  '....NNN.........',
  '....N.NN........',
  '....N...........',
  '..NNN...........',
  '..NN.........GG.',
  '....S.S.S...GGG.',
  '....G.G.G..GGHG.',
  '....G.G.G.GGGHG.',
  '...HHHHHHHGGGHG.',
  '.SSGGGGGGGGGGGG.',
  '...DDDDDDDGGGGG.',
  '..........GGGGG.',
  '...........GGGG.',
  '............GGG.'
)
CheckRows $rows 'f6'
Ascii $f 0 0 $rows @{ N = (C '#3b9be8'); S = (C '#dfe6f2'); G = (C '#f5b830'); H = (C '#ffe38a'); D = (C '#c9801c') }
AutoOutline $f $OL; Blit $sheet $f 96

# ---------- 7 sadokado: 抹茶茶碗と小さな花 ----------
$f = NewFrame
$rows = @(
  '................',
  '..........PPP...',
  '.........PPPPP..',
  '.........PPYPP..',
  '.........PPPPP..',
  '..........PPP...',
  '...........S....',
  '..HHHHHHHHHHHH..',
  '..HGGFGGGGFGGH..',
  '..BBBBBBBBBBBB..',
  '..BHBBBBBBBBDB..',
  '...BBBBBBBBDD...',
  '....DDDDDDDD....',
  '......DDDD......'
)
CheckRows $rows 'f7'
Ascii $f 0 0 $rows @{ P = (C '#ff8fb8'); Y = (C '#ffd84a'); S = (C '#4ca64a'); H = (C '#a9bdf5'); G = (C '#79c241'); F = (C '#c6ea8c'); B = (C '#4d6fc9'); D = (C '#32499b') }
AutoOutline $f $OL; Blit $sheet $f 112

# ---------- 8 aburasoba: どんぶり(麺・卵黄・のり・ねぎ) ----------
$f = NewFrame
$rows = @(
  '................',
  '..........KK....',
  '....NNNNNNKKK...',
  '..NNNEEENNKKNN..',
  '.NNGNEHENNNNGNN.',
  '.NNNNEEENGNNNNN.',
  '.NNGNNNNNNNNNGN.',
  '.WWWWWWWWWWWWWW.',
  '.BBBBBBBBBBBBBB.',
  '..WWWWWWWWWWWW..',
  '..WWWWWWWWWWLL..',
  '...WWWWWWWWWL...',
  '....LLLLLLLL....',
  '.....LLLLLL.....'
)
CheckRows $rows 'f8'
Ascii $f 0 0 $rows @{ N = (C '#f0cf72'); E = (C '#ff9a1f'); H = (C '#fff1b0'); K = (C '#1f5a3e'); G = (C '#6fd45a'); W = (C '#fff8ec'); B = (C '#4a7fd0'); L = (C '#c9c2d6') }
AutoOutline $f $OL; Blit $sheet $f 128

# ---------- 9 wataame: 割り箸のわたあめ ----------
$f = NewFrame
$pk = C '#ff9ec7'; $bl = C '#8fd3ff'
Ellipse $f 5 6.5 3.4 3.3 $pk
Ellipse $f 8 4.8 3.8 3.3 $pk
Ellipse $f 11 6.5 3.4 3.3 $bl
Ellipse $f 6 8.7 4.6 2.6 $pk
Ellipse $f 10.2 8.7 4.6 2.6 $bl
Ellipse $f 8 4.8 2.2 2.0 $pk
$lp = C '#ffe0ef'; $lb = C '#e0f6ff'; $dp = C '#ff7fb2'; $db = C '#5fb8f2'
foreach ($p in @(@(4, 4), @(5, 3), @(7, 2), @(3, 6), @(6, 5))) { Px $f $p[0] $p[1] $lp }
foreach ($p in @(@(11, 4), @(12, 5), @(10, 3), @(13, 7))) { Px $f $p[0] $p[1] $lb }
foreach ($p in @(@(4, 8), @(6, 7), @(5, 9), @(8, 8))) { Px $f $p[0] $p[1] $dp }
foreach ($p in @(@(10, 7), @(12, 9), @(9, 9), @(11, 8))) { Px $f $p[0] $p[1] $db }
Rect $f 7 11 2 4 (C '#e9c590')
Px $f 7 12 (C '#c9a06a'); Px $f 7 13 (C '#c9a06a')
AutoOutline $f $OL; Blit $sheet $f 144

# ---------- 10 potato: 赤い紙カップのフライドポテト ----------
$f = NewFrame
$rows = @(
  '................',
  '....FD..FD......',
  '....FDFDFDFD....',
  '..FDFDFDFDFDFD..',
  '..FDFDFDFDFDFD..',
  '..FDFDFDFDFDFD..',
  '..FDFDFDFDFDFD..',
  '.LLLLLLLLLLLLLL.',
  '..RRRRRRRRRRRR..',
  '..RRRFFRFFRRRR..',
  '...RRFFFFFRRR...',
  '...RRRFFFRRRR...',
  '....RRRFRRRR....',
  '....KKKKKKKK....'
)
CheckRows $rows 'f10'
Ascii $f 0 0 $rows @{ F = (C '#ffd23f'); D = (C '#e0a21d'); L = (C '#ff7a6b'); R = (C '#e53935'); K = (C '#b3261e') }
AutoOutline $f $OL; Blit $sheet $f 160

# ---------- 11 casino: ポーカーチップ(赤・白の縁)とサイコロ ----------
$f = NewFrame
$red11 = C '#e53935'; $wh11 = C '#fff8ec'; $dk11 = C '#a8201c'
for ($y = 0; $y -lt 16; $y++) {
  for ($x = 0; $x -lt 16; $x++) {
    $dx = $x + 0.5 - 6.5; $dy = $y + 0.5 - 6.5
    $d = [math]::Sqrt($dx * $dx + $dy * $dy)
    if ($d -le 5.8) {
      $col = $red11
      if ($d -ge 4.3) {
        $ang = [math]::Atan2($dy, $dx) + [math]::PI
        $sec = [int][math]::Floor($ang / ([math]::PI / 4))
        if ($sec % 2 -eq 0) { $col = $wh11 }
      } elseif ($d -ge 2.3 -and $d -lt 3.3) { $col = $wh11 }
      elseif ($d -lt 2.3) { $col = $dk11 }
      Px $f $x $y $col
    }
  }
}
Rect $f 8 8 7 7 $OL
Rect $f 9 9 5 5 (C '#fff8ec')
Rect $f 13 9 1 5 (C '#d4cfe0'); Rect $f 9 13 5 1 (C '#d4cfe0')
foreach ($p in @(@(10, 10), @(12, 10), @(11, 11), @(10, 12), @(12, 12))) { Px $f $p[0] $p[1] $OL }
AutoOutline $f $OL; Blit $sheet $f 176

# ---------- 12 obakeyashiki: 白いシーツのおばけ ----------
$f = NewFrame
$rows = @(
  '................',
  '....WWWWWWWW....',
  '..WWWWWWWWWWWW..',
  '.WWWWWWWWWWWWWW.',
  '.WWWOOWWWWOOWWL.',
  '.WWWOOWWWWOOWWL.',
  '.WWPWWWWWWWWPWL.',
  '.WWWWWWOOWWWWWL.',
  '.WWWWWWWWWWWWLL.',
  '.WWWWWWWWWWWWLL.',
  '.WWWWWWWWWWWWLL.',
  '.WWWWWWWWWWWWLL.',
  '.WWWWWWWWWWWWWL.',
  '.WWW..WWWW..WWL.'
)
CheckRows $rows 'f12'
Ascii $f 0 0 $rows @{ W = (C '#fffdf7'); L = (C '#cfd3f0'); P = (C '#ffa9c0'); O = $OL }
AutoOutline $f $OL; Blit $sheet $f 192

# ---------- 13 programming: </> のモニター ----------
$f = NewFrame
$rows = @(
  '................',
  '................',
  '.SSSSSSSSSSSSSS.',
  '.SKKKKKKKKKKKKS.',
  '.SKKKKKKKKKKKKS.',
  '.SKKKKKKKKKKKKS.',
  '.SKKKKKKKKKKKKS.',
  '.SKKKKKKKKKKKKS.',
  '.SKKKKKKKKKKKKS.',
  '.SKKKKKKKKKKKKS.',
  '.SSSSSSSSSSSSSS.',
  '......DDDD......',
  '....DDDDDDDD....'
)
CheckRows $rows 'f13'
Ascii $f 0 0 $rows @{ S = (C '#c5cde0'); K = (C '#1b2a3c'); D = (C '#7f8aa6') }
$gc = C '#46e06b'; $cc = C '#4fd8ff'
foreach ($p in @(@(5, 4), @(4, 5), @(3, 6), @(4, 7), @(5, 8), @(11, 4), @(12, 5), @(13, 6), @(12, 7), @(11, 8))) { Px $f $p[0] $p[1] $gc }
foreach ($p in @(@(9, 4), @(9, 5), @(8, 6), @(7, 7), @(7, 8))) { Px $f $p[0] $p[1] $cc }
AutoOutline $f $OL; Blit $sheet $f 208

# ---------- 14 science: 光る液体の三角フラスコ ----------
$f = NewFrame
$rows = @(
  '................',
  '......GGGG......',
  '......GGGG......',
  '......GGGG......',
  '......GGGG......',
  '.....GGGGGG.....',
  '....GGGGGGGG....',
  '....GHHHHHHG....',
  '...GLLLLLLLLG...',
  '..GLLHLLLLLLLG..',
  '..GLLHLLLLLLLG..',
  '.GLLLHLLLLLLLLG.',
  '.GLLLLLLLLLLLLG.',
  '.GGGGGGGGGGGGGG.'
)
CheckRows $rows 'f14'
Ascii $f 0 0 $rows @{ G = (C '#e4f4ff'); L = (C '#6fe05a'); H = (C '#c8ffa8') }
$bub = C '#ffffff'
foreach ($p in @(@(7, 3), @(8, 5), @(10, 10), @(5, 12), @(9, 8))) { Px $f $p[0] $p[1] $bub }
AutoOutline $f $OL; Blit $sheet $f 224

# ---------- 15 library: 開いた本(しおり付き) ----------
$f = NewFrame
$rows = @(
  '................',
  '................',
  '..PPPPPDDPPPPP..',
  '.CPPPPPDDPPPPPC.',
  '.CPTTTPDDPTTTPC.',
  '.CPPPPPDDPPPPPC.',
  '.CPTTTPDDPTTTPC.',
  '.CPPPPPDDPPPPPC.',
  '.CPTTPPDDPTTPPC.',
  '.CPPPPPDDPPPPPC.',
  '.CCCCCCRRCCCCCC.',
  '..CCCCCRRCCCCC..',
  '.......RR.......',
  '.......RR.......'
)
CheckRows $rows 'f15'
Ascii $f 0 0 $rows @{ C = (C '#3a6fd0'); P = (C '#fff6e0'); T = (C '#cbb68e'); D = (C '#d8c9a5'); R = (C '#e6384f') }
AutoOutline $f $OL; Blit $sheet $f 240

# ---------- 16 handmade: 光るクラゲ ----------
$f = NewFrame
$rows = @(
  '................',
  '................',
  '....BBBBBBBB....',
  '..BBBHHBBBBBBB..',
  '.BBHBBBBBBPPBBB.',
  '.BHBBBBPBBPPPBB.',
  '.BBBBBBPPBBPBBB.',
  '.VVBBBBBBBBBBVV.',
  '..VVVVVVVVVVVV..',
  '..VV.PP.VV.PP...',
  '..VV.PP.VV.PP...',
  '...VV.PP.VV.PP..',
  '..VV.PP.VV.PP...',
  '...V..P..V..P...'
)
CheckRows $rows 'f16'
Ascii $f 0 0 $rows @{ B = (C '#86d9ff'); H = (C '#e4f8ff'); P = (C '#ff8fd1'); V = (C '#a06de0') }
AutoOutline $f $OL; Blit $sheet $f 256

# ---------- 17 photoart: レンズの大きな赤いカメラ ----------
$f = NewFrame
$rows = @(
  '................',
  '................',
  '...SS.TTTT.YY...',
  '.LLLLLLLLLLLLLL.',
  '.TTTTTTTTTTTTTT.',
  '.RRRRRRRRRRRRRR.',
  '.RRRRRRRRRRRRRR.',
  '.RRRRRRRRRRRRRR.',
  '.RRRRRRRRRRRRRR.',
  '.RRRRRRRRRRRRRR.',
  '.RRRRRRRRRRRRRR.',
  '.RRRRRRRRRRRRRR.',
  '.RRRRRRRRRRRRRR.',
  '.DDDDDDDDDDDDDD.'
)
CheckRows $rows 'f17'
Ascii $f 0 0 $rows @{ S = (C '#9aa4bd'); T = (C '#c5cde0'); L = (C '#f4f7ff'); Y = (C '#ffd84a'); R = (C '#e8504c'); D = (C '#a8282f') }
# 大きなレンズ: 黒い輪 > 青いガラス > 濃い青 > 白いハイライト
Ellipse $f 8 9 4.4 4.4 (C '#2b3347')
Ellipse $f 8 9 3.3 3.3 (C '#5bb6ff')
Ellipse $f 8 9 1.7 1.7 (C '#2a62c8')
foreach ($p in @(@(6, 7), @(7, 7), @(6, 8))) { Px $f $p[0] $p[1] (C '#ffffff') }
Px $f 9 10 (C '#9fdcff')
# 右上のダイヤルとシャッター下の小さな点
Px $f 12 5 (C '#ffd84a'); Px $f 13 5 (C '#ffd84a')
AutoOutline $f $OL; Blit $sheet $f 272

# ---------- 18 dtm: 音符を挟んだヘッドホン ----------
$f = NewFrame
$rows = @(
  '................',
  '.....BBBBBB.....',
  '...BBBHHHBBB....',
  '..BBH......BBB..',
  '.BBB........BBB.',
  '.BB..........BB.',
  '.CCCC......CCCC.',
  '.CLLC...NN.CLLC.',
  '.CLCC...N..CCLC.',
  '.CCCC...N..CCCC.',
  '.CCDD...N..DDCC.',
  '.CCDD.NNN..DDCC.',
  '.CCCC.NN...CCCC.',
  '................'
)
CheckRows $rows 'f18'
Ascii $f 0 0 $rows @{ B = (C '#4c5a82'); H = (C '#8fa0d0'); C = (C '#ff4f8b'); L = (C '#ffb3d0'); D = (C '#b52a5e'); N = (C '#2fd0ff') }
AutoOutline $f $OL; Blit $sheet $f 288

# ---------- 19 amateurradio: アンテナと電波の付いたトランシーバー ----------
$f = NewFrame
$rows = @(
  '................',
  '...........A....',
  '....R..A....A...',
  '....N...A...A...',
  '....N..A....A...',
  '....N......A....',
  '....N...........',
  '...HHHHHHHH.....',
  '...YKKKKKKD.....',
  '..PYKGGGGKD.....',
  '..PYKKKKKKD.....',
  '...YYYYYYYD.....',
  '...YOYOYOYD.....',
  '...YYRYYBYD.....',
  '...DDDDDDDD.....'
)
CheckRows $rows 'f19'
Ascii $f 0 0 $rows @{ A = (C '#3bc6ff'); R = (C '#ff4a4a'); N = (C '#8d95ad'); H = (C '#ffe58a'); Y = (C '#ffc83a'); D = (C '#c98a1a'); K = (C '#243a2a'); G = (C '#7dff8a'); O = (C '#8a5a14'); P = (C '#e53935'); B = (C '#3a7be0') }
AutoOutline $f $OL; Blit $sheet $f 304

# ---------- 20 volleyball: 白・青・黄のカーブ模様のバレーボール ----------
$f = NewFrame
$rows = @(
  '................',
'.....BBBBBB.....',
  '....WWWWBBBB....',
  '...WWWWWWBBBB...',
  '..WWWYWWWWBBBB..',
  '.WWYYYYYWWBBBBB.',
  '.WYYYYYWWWBBBBB.',
  '.YYYYYWWWWBBBBB.',
  '.YYYYYWWWWBBBBB.',
  '.YYYYYWWWBBBBBS.',
  '.YYYYYWWBBBBBSS.',
  '..YYYYWWWWBSSS..',
  '...YYYYWWSSSS...',
  '....YYYYSSSS....',
  '.....YYYYYY.....',
  '................'
)
CheckRows $rows 'f20'
Ascii $f 0 0 $rows @{ B = (C '#3a86e8'); Y = (C '#ffd23f'); W = (C '#fff8ec'); S = (C '#cdd6ea') }
AutoOutline $f $OL; Blit $sheet $f 320

# 点 (x,y) が中心 (cx,cy) から半径 r 以内か（ピクセル中心で判定）
function InCircle($x, $y, $cx, $cy, $r) { $dx = $x + 0.5 - $cx; $dy = $y + 0.5 - $cy; return (($dx * $dx + $dy * $dy) -le ($r * $r)) }
function Opaque($f, $x, $y) { return ($x -ge 0 -and $y -ge 0 -and $x -lt 16 -and $y -lt 16 -and $f.GetPixel($x, $y).A -gt 0) }

# ---------- 21 obanyaki: かじった大判焼き(あんこが見える) ----------
$f = NewFrame
Ellipse $f 8 10.3 6.8 3.7 (C '#b8641f')
Ellipse $f 8 7.6 6.8 5.2 (C '#d98a2b')
Ellipse $f 8 7.6 5.7 4.2 (C '#f2b24a')
foreach ($p in @(@(3, 6), @(4, 4), @(5, 3), @(4, 5), @(6, 3))) { Px $f $p[0] $p[1] (C '#ffd98a') }
# 焼き印の輪(濃いきつね色)
foreach ($p in @(@(7, 6), @(8, 6), @(9, 6), @(6, 7), @(10, 7), @(6, 8), @(10, 8), @(7, 9), @(8, 9), @(9, 9), @(8, 7), @(8, 8))) { Px $f $p[0] $p[1] (C '#d98a2b') }
# 右上のかじった跡: 円で消して、縁にあんこ(濃い赤)を見せる
$bx = 12.6; $by = 4.0
$cut = @(); $an = @()
for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) {
  if ($f.GetPixel($x, $y).A -gt 0) {
    if (InCircle $x $y $bx $by 3.0) { $cut += ,@($x, $y) }
    elseif (InCircle $x $y $bx $by 4.5) { $an += ,@($x, $y) }
  }
} }
foreach ($e in $cut) { Px $f $e[0] $e[1] ([System.Drawing.Color]::FromArgb(0, 0, 0, 0)) }
foreach ($e in $an) { Px $f $e[0] $e[1] (C '#7a2e3a') }
foreach ($e in $an) { if (InCircle $e[0] $e[1] $bx $by 3.7) { Px $f $e[0] $e[1] (C '#a3434f') } }
AutoOutline $f $OL; Blit $sheet $f 336

# ---------- 22 kushiyaki: 串に刺さった肉3つ(ななめ) ----------
$f = NewFrame
Line $f 0 15 15 0 (C '#e9c590'); Line $f 1 15 15 1 (C '#c9a06a'); Line $f 0 14 14 0 (C '#e9c590')
$meat = @(@(3.6, 12.4, '#9a4f2a'), @(8.0, 8.0, '#8a4424'), @(12.4, 3.6, '#a8592f'))
foreach ($c in $meat) {
  Ellipse $f ($c[0] + 0.5) ($c[1] + 0.5) 2.7 2.7 (C '#5a2814')
  Ellipse $f $c[0] $c[1] 2.7 2.7 (C $c[2])
  Ellipse $f ($c[0] - 0.9) ($c[1] - 0.9) 1.1 1.1 (C '#d4915c')
  $x = [int][math]::Floor($c[0]); $y = [int][math]::Floor($c[1])
  Px $f ($x + 1) ($y + 1) (C '#3f1c10'); Px $f ($x + 2) $y (C '#3f1c10'); Px $f $x ($y + 2) (C '#3f1c10')
}
AutoOutline $f $OL; Blit $sheet $f 352

# ---------- 23 doujinshi: ホチキス留めの薄い本(星の表紙) ----------
$f = NewFrame
$rows = @(
  '................',
  '..DDDDDDDDDD....',
  '..DCCCCCCCCDW...',
  '..DCCCCYCCCDW...',
  '..DCCCYYYCCDW...',
  '..DCCYYYYYCDW...',
  '..DCCCYYYCCDW...',
  '..DCCCYCYCCDW...',
  '..DCCCCCCCCDW...',
  '..DTTTTTTTTDW...',
  '..DCCCCCCCCDW...',
  '..DCTTTTTCCDW...',
  '..DCCCCCCCCDW...',
  '..DDDDDDDDDDW...',
  '...WWWWWWWWWW...'
)
CheckRows $rows 'f23'
Ascii $f 0 0 $rows @{ D = (C '#c02a74'); C = (C '#ff6fb1'); Y = (C '#ffe14a'); W = (C '#f3eee2'); T = (C '#fff8ec') }
# 背のホチキス(銀)
Px $f 2 4 (C '#aab4c8'); Px $f 3 4 (C '#aab4c8'); Px $f 2 10 (C '#aab4c8'); Px $f 3 10 (C '#aab4c8')
Px $f 12 6 (C '#d4cfc2'); Px $f 12 9 (C '#d4cfc2')
AutoOutline $f $OL; Blit $sheet $f 368

# ---------- 24 suuri: 半ひねりのメビウスの輪(左が青・右が白、手前の下でねじれて細くなる) ----------
$f = NewFrame
$blue = C '#3b82e6'; $blueD = C '#2455b8'; $blueL = C '#8fc2ff'; $whiteC = C '#fbfdff'; $whiteD = C '#b9cdee'; $whiteL = C '#ffffff'
$TAU = 2 * [math]::PI
# 奥(上のカーブ)を先に、手前(下のカーブ)を後に描く
foreach ($pass in 0, 1) {
  for ($phi = 0.0; $phi -lt $TAU; $phi += 0.01) {
    $front = ([math]::Sin($phi) -ge 0)
    if (($pass -eq 0 -and $front) -or ($pass -eq 1 -and -not $front)) { continue }
    $psi = $phi - [math]::PI / 2; if ($psi -lt 0) { $psi += $TAU }
    $h = 0.45 + 1.6 * [math]::Abs([math]::Sin($psi / 2))
    $isBlue = ($psi -lt [math]::PI)
    $cx = 8 + 6.4 * [math]::Cos($phi); $cy = 8 + 4.9 * [math]::Sin($phi)
    $x = [int][math]::Floor($cx)
    $y0 = [int][math]::Floor($cy - $h); $y1 = [int][math]::Floor($cy + $h)
    for ($y = $y0; $y -le $y1; $y++) {
      if ($isBlue) { $c = if ($y -eq $y1 -and $y1 -gt $y0) { $blueD } elseif ($y -eq $y0) { $blueL } else { $blue } }
      else { $c = if ($y -eq $y1 -and $y1 -gt $y0) { $whiteD } elseif ($y -eq $y0) { $whiteL } else { $whiteC } }
      Px $f $x $y $c
    }
  }
}
AutoOutline $f $OL; Blit $sheet $f 384

# ---------- 25 nazotoki: 金の南京錠と紫の？ ----------
$f = NewFrame
$rows = @(
  '................',
  '.....SSSSSS.....',
  '....SSSSSSSS....',
  '....SS....SS....',
  '....SS....SS....',
  '....SS....SS....',
  '....SS....SS....',
  '..HHHHHHHHHHHH..',
  '..GGGGGGGGGGGD..',
  '..GGGGGGGGGGGD..',
  '..GGGGGGGGGGGD..',
  '..GGGGGGGGGGGD..',
  '..GGGGGGGGGGGD..',
  '..GGGGGGGGGGGD..',
  '..DDDDDDDDDDDD..'
)
CheckRows $rows 'f25'
Ascii $f 0 0 $rows @{ S = (C '#d6dcec'); H = (C '#ffe38a'); G = (C '#f5b830'); D = (C '#c9801c') }
$pu = C '#6a24e0'
foreach ($p in @(@(7, 8), @(8, 8), @(6, 9), @(9, 9), @(9, 10), @(8, 11), @(7, 12), @(7, 13))) { Px $f $p[0] $p[1] $pu }
Px $f 6 9 $pu
AutoOutline $f $OL; Blit $sheet $f 400

# ---------- 26 entre: オレンジの車輪とシアンの噴射 ----------
$f = NewFrame
Ellipse $f 8 6.2 5.4 5.4 (C '#ff8a1f')
Ellipse $f 8 6.2 4.0 4.0 (C '#1c3350')
$sp = C '#ff9a2e'
Rect $f 7 2 2 8 $sp; Rect $f 4 5 8 2 $sp
foreach ($p in @(@(6, 4), @(5, 3), @(9, 4), @(10, 3), @(6, 7), @(5, 8), @(9, 7), @(10, 8))) { Px $f $p[0] $p[1] $sp }
Rect $f 7 5 2 2 (C '#35d6ff'); Px $f 7 5 (C '#d8f8ff')
foreach ($p in @(@(4, 2), @(5, 1), @(3, 3))) { Px $f $p[0] $p[1] (C '#ffc060') }
# 噴射(シアン + 白い芯)
$rows = @(
  '.....CCCCCC.....',
  '......CWWC......',
  '......CWWC......',
  '.......CC.......'
)
Ascii $f 0 12 $rows @{ C = (C '#35d6ff'); W = (C '#f4feff') }
AutoOutline $f $OL; Blit $sheet $f 416

# ---------- 27 hotdog: パンにはさまれたソーセージ(ケチャップとマスタード) ----------
$f = NewFrame
Rect $f 1 4 14 5 (C '#a8321f')
Rect $f 2 3 12 1 (C '#a8321f')
Rect $f 2 4 12 1 (C '#d65a3a')
Px $f 1 4 (C '#a8321f'); Px $f 14 4 (C '#a8321f'); Px $f 1 8 (C '#8a2616'); Px $f 14 8 (C '#8a2616')
$bun = C '#e8b25e'; $bunD = C '#c98a35'; $bunH = C '#ffd98a'
Rect $f 3 7 10 1 $bunH
Rect $f 3 8 10 4 $bun
Rect $f 4 12 8 1 $bunD
Px $f 3 11 $bunD; Px $f 12 11 $bunD; Px $f 12 10 $bunD; Px $f 12 9 $bunD
Px $f 5 9 $bunH; Px $f 9 10 $bunH
# 線: ケチャップ(赤)とマスタード(黄)のジグザグ
foreach ($p in @(@(3, 5), @(4, 5), @(7, 6), @(8, 6), @(11, 5), @(12, 5), @(5, 6), @(10, 6))) { Px $f $p[0] $p[1] (C '#ff2d2d') }
foreach ($p in @(@(5, 5), @(6, 5), @(9, 5), @(10, 5), @(3, 6), @(4, 6), @(7, 5), @(11, 6), @(12, 6), @(8, 5))) { Px $f $p[0] $p[1] (C '#ffd21f') }
AutoOutline $f $OL; Blit $sheet $f 432

# ---------- 28 frankfurt: 串に刺した太いソーセージ(縦、ケチャップの波線) ----------
$f = NewFrame
Rect $f 7 11 2 4 (C '#e9c590'); Px $f 8 12 (C '#c9a06a'); Px $f 8 13 (C '#c9a06a'); Px $f 8 14 (C '#c9a06a')
Ellipse $f 8 6.2 3.5 5.4 (C '#8a3f1e')
Ellipse $f 7.8 6.0 3.0 4.9 (C '#c0662d')
for ($y = 2; $y -le 9; $y++) { Px $f 5 $y (C '#e8934f') }
Px $f 6 1 (C '#e8934f')
# ケチャップの波線
$wave = @(6, 7, 8, 9, 8, 7, 6, 7, 8)
for ($i = 0; $i -lt $wave.Count; $i++) { Px $f $wave[$i] (2 + $i) (C '#ff2d2d') }
AutoOutline $f $OL; Blit $sheet $f 448

# ---------- 29 kirakira: 青→ピンクのグラデーションのドリンクとキラキラ ----------
$f = NewFrame
$top = @(0x4a, 0xb4, 0xff); $mid = @(0xb8, 0x8c, 0xff); $bot = @(0xff, 0x7f, 0xc4)
for ($y = 5; $y -le 14; $y++) {
  $u = ($y - 5) / 9.0
  $hw = 4.4 - 1.8 * $u
  if ($u -lt 0.5) { $w = $u / 0.5; $a = $top; $b = $mid } else { $w = ($u - 0.5) / 0.5; $a = $mid; $b = $bot }
  $r = [int]($a[0] + ($b[0] - $a[0]) * $w); $g = [int]($a[1] + ($b[1] - $a[1]) * $w); $bl = [int]($a[2] + ($b[2] - $a[2]) * $w)
  $col = [System.Drawing.Color]::FromArgb(255, $r, $g, $bl)
  for ($x = 0; $x -lt 16; $x++) { if ([math]::Abs($x + 0.5 - 7.5) -le $hw) { Px $f $x $y $col } }
}
# ふち(ふた)と左のつや
Rect $f 2 4 11 1 (C '#eaf6ff')
for ($y = 6; $y -le 11; $y++) { Px $f (4 - [int](($y - 5) / 4)) $y (C '#d8f0ff') }
# ストロー(赤と白)
$sc = C '#ff5f8f'; $sw = C '#fff8ec'
Px $f 9 3 $sc; Px $f 10 2 $sw; Px $f 11 1 $sc; Px $f 12 1 $sw; Px $f 10 3 $sc; Px $f 11 2 $sw
# キラキラの粒
$yl = C '#ffe14a'; $wh = C '#ffffff'
foreach ($c in @(@(2, 6), @(13, 10), @(2, 1))) {
  Px $f $c[0] $c[1] $wh
  Px $f ($c[0] - 1) $c[1] $yl; Px $f ($c[0] + 1) $c[1] $yl; Px $f $c[0] ($c[1] - 1) $yl; Px $f $c[0] ($c[1] + 1) $yl
}
foreach ($p in @(@(6, 8), @(9, 10), @(7, 12), @(8, 7))) { Px $f $p[0] $p[1] $wh }
AutoOutline $f $OL; Blit $sheet $f 464

# ---------- 30 circuit: 緑の基板(金のパッド・黒いチップ・光るLED) ----------
$f = NewFrame
Rect $f 1 2 14 12 (C '#2fa05a')
Frame $f 1 2 14 12 (C '#1f7a40')
$tr = C '#8be8a8'
Line $f 3 5 3 11 $tr; Line $f 3 5 5 5 $tr; Line $f 12 4 12 9 $tr; Line $f 11 9 12 9 $tr; Line $f 4 12 11 12 $tr
# 取り付け穴と金のパッド
$gold = C '#f5c53a'
foreach ($p in @(@(3, 4), @(3, 11), @(12, 3), @(12, 11), @(2, 8), @(14, 6))) { Px $f $p[0] $p[1] $gold }
foreach ($p in @(@(6, 12), @(8, 12), @(10, 12), @(3, 3))) { Px $f $p[0] $p[1] $gold }
# チップ(黒)と足(銀)
Rect $f 5 5 6 5 (C '#262b36')
Px $f 6 6 (C '#6a7088'); Px $f 7 6 (C '#4a5066')
foreach ($p in @(@(4, 6), @(4, 8), @(11, 6), @(11, 8), @(6, 4), @(8, 4), @(6, 10), @(8, 10))) { Px $f $p[0] $p[1] (C '#c9cfe0') }
# 光るLED(赤 + つよい光)
Px $f 13 4 (C '#ff3a3a'); Px $f 13 5 (C '#ff3a3a'); Px $f 12 5 (C '#ffd0c0'); Px $f 14 4 (C '#ff8a7a'); Px $f 13 3 (C '#ff8a7a')
AutoOutline $f $OL; Blit $sheet $f 480

# ---------- 31 printer3d: 3Dプリンタ(枠・ノズル・オレンジの積層・フィラメント) ----------
$f = NewFrame
$gr = C '#9aa3b8'; $grL = C '#cfd6e6'; $grD = C '#5f6880'
Rect $f 1 3 1 10 $gr; Rect $f 14 3 1 10 $gr
Rect $f 1 1 14 2 $grL; Rect $f 1 3 14 1 $grD
Rect $f 0 13 16 2 $grD; Rect $f 0 13 16 1 $gr
# フィラメント(オレンジ)の巻き
Rect $f 11 1 3 2 (C '#ff9a2e'); Px $f 12 1 (C '#ffc060')
# ヘッドとノズル
Rect $f 6 4 4 3 (C '#4b5266'); Rect $f 6 4 4 1 $gr
Rect $f 7 7 2 1 (C '#ff6a00'); Px $f 7 8 (C '#ffd23f')
# 積み上げ途中の立体
$o1 = C '#ff9a2e'; $o2 = C '#e57a12'; $o3 = C '#ffc060'
Rect $f 5 12 6 1 $o2; Rect $f 5 11 6 1 $o1; Rect $f 5 10 6 1 $o2; Rect $f 5 9 6 1 $o3
Rect $f 5 9 1 4 $o3
AutoOutline $f $OL; Blit $sheet $f 496

# ---------- 32 croffle: 格子模様のクロッフル(半円・粉砂糖) ----------
$f = NewFrame
for ($y = 3; $y -le 13; $y++) { for ($x = 0; $x -lt 16; $x++) {
  $dx = ($x + 0.5 - 8) / 7.2; $dy = ($y + 0.5 - 13.5) / 10.4
  if (($dx * $dx + $dy * $dy) -le 1) { Px $f $x $y (C '#f6b858') }
} }
$lat = C '#a85a1c'
for ($y = 3; $y -le 12; $y++) { for ($x = 0; $x -lt 16; $x++) {
  if (Opaque $f $x $y) {
    if ((($x + $y) % 4) -eq 0 -or ((($x - $y) % 4 + 4) % 4) -eq 0) { Px $f $x $y $lat }
  }
} }
# 外ぶち(こんがり)
$rim = @()
for ($y = 3; $y -le 12; $y++) { for ($x = 0; $x -lt 16; $x++) {
  if ((Opaque $f $x $y) -and -not ((Opaque $f ($x - 1) $y) -and (Opaque $f ($x + 1) $y) -and (Opaque $f $x ($y - 1)))) { $rim += ,@($x, $y) }
} }
foreach ($p in $rim) { Px $f $p[0] $p[1] (C '#d98a2b') }
# 折り目の平らな面(クリーム)
Rect $f 1 13 14 1 (C '#fff0c0'); Rect $f 2 14 12 1 (C '#e8c98a')
# 粉砂糖(格子のマスの中に)
foreach ($p in @(@(6, 7), @(8, 5), @(10, 9), @(5, 10), @(9, 11), @(11, 7), @(7, 9))) { if ((Opaque $f $p[0] $p[1]) -and $f.GetPixel($p[0], $p[1]).R -gt 200) { Px $f $p[0] $p[1] (C '#ffffff') } }
AutoOutline $f $OL; Blit $sheet $f 512

# ---------- 33 tamasen: 丸いせんべいに挟まれた目玉焼き ----------
$f = NewFrame
$sen = C '#d49a4a'; $senD = C '#a8691f'; $senL = C '#ebc080'
Ellipse $f 8 12 6.9 2.5 $senD
Ellipse $f 8 11.5 6.9 2.4 $sen
Ellipse $f 8 8.3 7.0 3.2 (C '#ffffff')
Ellipse $f 3.5 9 3 2.4 (C '#ffffff'); Ellipse $f 12.5 7.4 3 2.3 (C '#ffffff')
Rect $f 4 11 8 1 (C '#e3e7f2')
Ellipse $f 8 8 3.0 2.5 (C '#ffb81c'); Ellipse $f 7 7.2 1.1 0.9 (C '#ffe27a')
Ellipse $f 8 4.3 6.4 2.4 $senD
Ellipse $f 8 3.8 6.4 2.3 $sen
foreach ($p in @(@(5, 3), @(8, 2), @(11, 3), @(7, 4), @(10, 4), @(4, 4))) { Px $f $p[0] $p[1] $senL }
foreach ($p in @(@(6, 13), @(9, 13), @(12, 12))) { Px $f $p[0] $p[1] $senL }
AutoOutline $f $OL; Blit $sheet $f 528

Save $sheet 'stamps.png'
