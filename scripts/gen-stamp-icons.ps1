# スタンプラリー用アイコン 17個 (16x16) を横一列のスプライトシートに描く。
# 実行: リポジトリのルートで powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen-stamp-icons.ps1
# 各フレームは「塗りだけ」を描き、最後に外側へ1pxの濃い縁取り(AutoOutline)を自動で付ける。
$script:OutDir = "client/public/brand/stamps"
. "$PSScriptRoot\lib\pixel.ps1"

$OL = C '#3a2230'
$FRAMES = 17

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

Save $sheet 'stamps.png'
