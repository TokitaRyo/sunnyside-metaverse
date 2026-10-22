# 3Dプリンタ屋の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/printer3d.ps1   （リポジトリのルートで実行）
#   一部だけ作り直す: $env:P3D_ONLY='sign|printer'  （ファイル名の正規表現）
# 出力: client/public/brand/stall/printer3d_*.png （配置は scripts/stalls/printer3d.mjs）
# 配色: オレンジ・白（あたたかいクリーム）・灰色が中心。造形物とフィラメントだけ、ピンク・水色・黄色などの小さな差し色。
# アニメは「フレームを横一列に並べたPNG」を k.custom(name, ox, oy, {frames, fps}) で再生する。
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。実在のキャラクターは描かない。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
# フレームを横に並べたシートを作る。$draw には ($b, $ox, $f) が渡る
function Sheet($name, $w, $h, $n, $draw) {
  if ($env:P3D_ONLY -and ($name -notmatch $env:P3D_ONLY)) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  Save $bm $name
}
function P($b, $x, $y, $col) { Px $b ([int][math]::Round($x)) ([int][math]::Round($y)) $col }
# すでにある色にむけて少しだけ混ぜる（光・反射用）。透明なところは触らない
function Tint($b, $x, $y, $col, $t) {
  $x = [int]$x; $y = [int]$y
  if ($x -lt 0 -or $y -lt 0 -or $x -ge $b.Width -or $y -ge $b.Height) { return }
  $o = $b.GetPixel($x, $y)
  if ($o.A -eq 0) { return }
  Px $b $x $y (Mix $o $col $t)
}
$none = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
function Cut($b, $x, $y) { Px $b $x $y $none }

# ---- 色
$ol = C '#262a30'
$g0 = C '#f6f7f9'; $g1 = C '#e3e6ea'; $g2 = C '#c9cdd3'; $g3 = C '#9ca3ad'; $g4 = C '#6f7681'; $g5 = C '#4a505a'; $g6 = C '#343941'
$wh = C '#fffaf0'; $cr1 = C '#f5ecd9'; $cr2 = C '#e6d9bc'; $cr3 = C '#c9b78f'
$or0 = C '#8c3d0c'; $or1 = C '#e8721a'; $or2 = C '#ff9a2e'; $or3 = C '#ffc46b'; $or4 = C '#ffe6b8'
# フィラメント・造形物の差し色
$pk = C '#ff7aa8'; $tq = C '#2cc6c0'; $yw = C '#ffd23c'; $lv = C '#a07bff'; $sk = C '#52aaff'; $rr = C '#ee4b4b'
$glass = C '#eceff2'; $glass2 = C '#e0e4e8'

# ---- 小さな造形物（かわいい動物・ロボット・キーホルダー）。M=本体 d=濃い 輪郭 h=明るい w=白 o=オレンジ e=目 c=水色 p=ほっぺ
$ITEMS = @{
  cat      = @('dd.....dd', 'dMd...dMd', 'dMMdddMMd', 'dMMMMMMMd', 'dMeMMMeMd', 'dMMMpMMMd', '.dMMMMMd.', '.dMhMMMd.', '.dMMMMMd.', '..ddddd..')
  bear     = @('dd.....dd', 'dMdddddMd', '.dMMMMMd.', 'dMMMMMMMd', 'dMeMMMeMd', 'dMMwwwMMd', 'dMMwdwMMd', '.dMMMMMd.', '..ddddd..')
  robot    = @('...o....', '...d....', '.dddddd.', 'dMMMMMMd', 'dMeMMeMd', 'dMMMMMMd', '.dddddd.', 'dMMooMMd', 'dMMMMMMd', '.dMddMd.', '.dd..dd.')
  penguin  = @('..dddd..', '.dMMMMd.', 'dMeMMeMd', 'dMMooMMd', 'dMwwwwMd', 'dMwwwwMd', 'dMwwwwMd', '.dMwwMd.', '.dMMMMd.', '..oo.oo.')
  mushroom = @('..ddddd..', '.dMMwMMd.', 'dMwwMMMMd', 'dMMMMwwMd', 'ddddddddd', '..dwwwd..', '..dwwwd..', '..ddddd..')
  rocket   = @('..dd..', '.dMMd.', '.dhMd.', 'dMccMd', 'dMccMd', 'dMMMMd', 'ddMMdd', 'd.oo.d', '..oo..')
  heart    = @('.dd.dd.', 'dhMMMMd', 'dMMMMMd', '.dMMMd.', '..dMd..', '...d...')
  star     = @('...d...', '..dMd..', 'ddMhMdd', '.dMMMd.', '.dMMMd.', 'dMdddMd', 'dd...dd')
  vase     = @('.ddddd.', '..dMd..', '.dMhMd.', 'dMhMMMd', 'dMMMMMd', 'dMMMMMd', '.dMMMd.', '..dMd..', '.dMMMd.', 'ddddddd')
}
# 造形物を描く。$sc は拡大率、$back=$true なら顔のない後ろ姿
function Item($b, $x, $y, $name, $main, $sc, $back) {
  $rows = $ITEMS[$name]
  $dk = Mix $main $ol 0.5; $hi = Mix $main $wh 0.5; $m2 = Mix $main $ol 0.1
  for ($j = 0; $j -lt $rows.Count; $j++) {
    for ($i = 0; $i -lt $rows[$j].Length; $i++) {
      $ch = [string]$rows[$j][$i]
      if ($ch -eq '.') { continue }
      $col = $null
      switch ($ch) {
        'M' { $col = $(if ($j % 2 -eq 1) { $m2 } else { $main }) }
        'd' { $col = $dk }
        'h' { $col = $hi }
        'w' { $col = $wh }
        'o' { $col = $or2 }
        'e' { $col = $ol }
        'c' { $col = (C '#9fdcff') }
        'p' { $col = $pk }
      }
      if ($back -and ($ch -eq 'e' -or $ch -eq 'w' -or $ch -eq 'p' -or $ch -eq 'c')) { $col = $main }
      if ($col -ne $null) { Rect $b ($x + $i * $sc) ($y + $j * $sc) $sc $sc $col }
    }
  }
}
function ItemOn($b, $cxx, $baseY, $name, $main) {
  $rows = $ITEMS[$name]
  Item $b ([int]($cxx - $rows[0].Length / 2)) ($baseY - $rows.Count + 1) $name $main 1 $false
}

# ---- 3Dプリンタ本体（アニメ）。造形物が下から積み上がり、ノズルが左右に動く。$big=大きい方
function PrintProf($kind, $t) {
  if ($kind -eq 'vase') { return 4.0 + 5.0 * [math]::Sin($t * [math]::PI) + 1.5 * (1 - $t) }
  return 1.5 + 8.5 * [math]::Pow(1 - $t, 0.9)
}
function Printer($b, $ox, $f, $nf, $big, $col, $kind) {
  if ($big) { $sw = 56; $sh = 56; $baseH = 12; $post = 4; $topT = 4; $maxh = 24; $nh = 5; $tipl = 2; $bedT = 3; $sc = 1.0; $nbw = 5 }
  else { $sw = 26; $sh = 28; $baseH = 6; $post = 3; $topT = 3; $maxh = 9; $nh = 3; $tipl = 1; $bedT = 2; $sc = 0.5; $nbw = 3 }
  $gn = $nf - 2
  $hold = ($f -ge $gn)
  $prog = $(if ($hold) { 1.0 } else { ($f + 1) / [double]$gn })
  $hp = [int][math]::Round([math]::Max(1.0, $maxh * $prog))
  $cx = $ox + [int]($sw / 2)
  $inL = $ox + $post; $inR = $ox + $sw - $post; $inW = $inR - $inL
  $bot = $sh - $baseH
  $bedY = $bot - $bedT
  $baseRow = $bedY - 1
  $ytop = $baseRow - $hp + 1
  # うしろの板（ガラス）と、上のLEDライト
  Rect $b $inL $topT $inW ($bot - $topT) $glass
  for ($x = $inL + 6; $x -lt $inR - 2; $x += 8) { Rect $b $x $topT 1 ($bot - $topT) $glass2 }
  for ($x = $inL; $x -lt $inR; $x++) {
    $lit = (((($x - $ox) + $f) % 6) -lt 2)
    Px $b $x $topT $(if ($lit) { $or4 } else { $or3 })
    if ($lit) { Tint $b $x ($topT + 1) $or4 0.6; Tint $b $x ($topT + 2) $or4 0.3; if ($big) { Tint $b $x ($topT + 3) $or4 0.15 } }
  }
  # ベッド（造形物をのせる板）
  Rect $b ($inL + 1) $bedY ($inW - 2) $bedT $g5
  Rect $b ($inL + 1) $bedY ($inW - 2) 1 $g3
  # 造形物（下から1そうずつ）
  $dkp = Mix $col $ol 0.55; $colA = Mix $col $ol 0.12
  for ($k = 0; $k -lt $hp; $k++) {
    $y = $baseRow - $k
    $t = $k / [double]($maxh - 1)
    $hw = (PrintProf $kind $t) * $sc
    $xl = [int][math]::Round($cx - $hw); $xr = [int][math]::Round($cx + $hw)
    for ($x = $xl; $x -le $xr; $x++) {
      if ($x -eq $xl -or $x -eq $xr) { $c = $dkp }
      elseif ($k -eq $hp - 1 -and -not $hold) { $c = Mix $col $or3 0.6 }
      elseif ($k -eq $hp - 1) { $c = Mix $col $wh 0.4 }
      else {
        $c = $(if ($k % 2 -eq 1) { $colA } else { $col })
        if ($x -le $xl + 1 + [int]$sc) { $c = Mix $c $wh 0.35 } elseif ($x -ge $xr - 1) { $c = Mix $c $ol 0.22 }
      }
      Px $b $x $y $c
    }
  }
  # レール（左右に走る）とノズル
  if ($hold) {
    $ry = $topT + 2
    $nx = $cx + $(if ($f -eq $gn) { [int]($sw * 0.26) } else { -[int]($sw * 0.26) })
  } else {
    $ry = [int][math]::Max($topT + 2, $ytop - ($nh + 2 + $tipl))
    $hwTop = (PrintProf $kind (($hp - 1) / [double]($maxh - 1))) * $sc
    $nx = $cx + [int][math]::Round($hwTop * [math]::Sin($f * 2.1 + 0.6))
  }
  Rect $b $inL $ry $inW 1 $g4
  Rect $b $inL ($ry + 1) $inW 1 $g5
  Rect $b $inL ($ry + 2) $inW 1 $ol
  Rect $b $inL $ry 2 3 $or1; Rect $b ($inR - 2) $ry 2 3 $or1
  $nx0 = $nx - [int]($nbw / 2)
  Rect $b $nx0 ($ry + 2) $nbw $nh $ol
  Rect $b ($nx0 + 1) ($ry + 3) ($nbw - 2) ($nh - 2) $g2
  Px $b ($nx0 + 1) ($ry + 3) $wh
  if ($big) { Px $b ($nx0 + 3) ($ry + 4) $or2; Px $b ($nx0 + 3) ($ry + 5) $or1 }
  for ($i = 0; $i -lt $tipl; $i++) { Px $b $nx ($ry + 2 + $nh + $i) $(if ($i -eq $tipl - 1) { $or3 } else { $or1 }) }
  if (-not $hold) { Tint $b ($nx - 1) ($ry + 1 + $nh + $tipl) $or3 0.4; Tint $b ($nx + 1) ($ry + 1 + $nh + $tipl) $or3 0.4 }
  # ガラスの照り返し
  $nrf = $bot - $topT - 4
  for ($i = 0; $i -lt $nrf; $i++) {
    $xx = $inL + 4 + [int]($i * 0.6)
    Tint $b $xx ($topT + 2 + $i) $wh 0.4; Tint $b ($xx + 1) ($topT + 2 + $i) $wh 0.22
  }
  # はしら（オレンジ）
  Rect $b $ox $topT $post ($bot - $topT) $ol
  Rect $b ($ox + $sw - $post) $topT $post ($bot - $topT) $ol
  Rect $b ($ox + 1) $topT ($post - 2) ($bot - $topT) $or1
  Rect $b ($ox + 1) $topT 1 ($bot - $topT) $or2
  Rect $b ($ox + $sw - $post + 1) $topT ($post - 2) ($bot - $topT) $or1
  Rect $b ($ox + $sw - 2) $topT 1 ($bot - $topT) $or0
  for ($y = $topT + 3; $y -lt $bot - 2; $y += 4) { Px $b ($ox + 1) $y $or0; Px $b ($ox + $sw - 2) $y $or1 }
  # 上のふた
  Rect $b $ox 0 $sw $topT $ol
  Rect $b ($ox + 1) 1 ($sw - 2) ($topT - 2) $g5
  Rect $b ($ox + 1) 1 ($sw - 2) 1 $g4
  Rect $b ($ox + 1) 1 ($post - 1) ($topT - 2) $or2
  Rect $b ($ox + $sw - $post) 1 ($post - 1) ($topT - 2) $or1
  # 下の箱
  Rect $b $ox $bot $sw $baseH $ol
  Rect $b ($ox + 1) ($bot + 1) ($sw - 2) ($baseH - 2) $g1
  Rect $b ($ox + 1) ($bot + 1) ($sw - 2) 1 $wh
  Rect $b ($ox + 1) ($sh - 2) ($sw - 2) 1 $g2
  $lampOn = $(if ($hold) { C '#ffffff' } elseif ($f % 2 -eq 0) { $or2 } else { $or0 })
  if ($big) {
    Rect $b ($ox + 1) ($sh - 4) ($sw - 2) 1 $or1
    Rect $b ($ox + 1) ($sh - 3) ($sw - 2) 1 $or0
    $sx = $ox + 5; $sy = $bot + 3
    Rect $b $sx $sy 16 7 $ol
    Rect $b ($sx + 1) ($sy + 1) 14 5 $g6
    foreach ($q in 2, 3, 5, 6, 8, 9) { Px $b ($sx + $q) ($sy + 2) $or3 }
    Rect $b ($sx + 2) ($sy + 4) 12 1 $g4
    Rect $b ($sx + 2) ($sy + 4) ([int][math]::Round(12 * $prog)) 1 $(if ($hold) { C '#ffffff' } else { $or2 })
    # 重ねた層のロゴ
    Rect $b ($cx - 1) ($bot + 3) 3 1 $or1; Rect $b ($cx - 2) ($bot + 5) 5 1 $or2; Rect $b ($cx - 3) ($bot + 7) 7 1 $or1
    # つまみとランプ
    Ellipse $b ($ox + $sw - 13) ($bot + 6) 3.2 3.2 $ol; Ellipse $b ($ox + $sw - 13) ($bot + 6) 2.4 2.4 $g3; Px $b ($ox + $sw - 14) ($bot + 5) $wh; Px $b ($ox + $sw - 13) ($bot + 6) $g5
    Rect $b ($ox + $sw - 7) ($bot + 3) 2 2 $lampOn
    Tint $b ($ox + $sw - 8) ($bot + 3) $lampOn 0.4; Tint $b ($ox + $sw - 5) ($bot + 4) $lampOn 0.4
  } else {
    Rect $b ($ox + 3) ($bot + 2) 6 2 $g6
    Px $b ($ox + 4) ($bot + 3) $or3; Px $b ($ox + 5) ($bot + 3) $or3
    Rect $b ($ox + $sw - 6) ($bot + 2) 2 2 $lampOn
    Rect $b ($cx - 2) ($sh - 3) 5 1 $or1
  }
  foreach ($p in @(@(0, 0), @(($sw - 1), 0), @(0, ($sh - 1)), @(($sw - 1), ($sh - 1)))) { Cut $b ($ox + $p[0]) $p[1] }
}

# ====================================================================
# 看板 128x34（オレンジの電飾看板。まわりの電球が流れて、左の小さなプリンタが造形物を積み上げる）6コマ
Sheet 'printer3d_sign.png' 128 34 6 {
  param($b, $ox, $f)
  Rect $b $ox 2 128 32 $ol
  Rect $b ($ox + 1) 3 126 30 $or0
  Rect $b ($ox + 2) 4 124 28 $or1
  Rect $b ($ox + 2) 4 124 2 $or2
  Rect $b ($ox + 2) 4 124 1 $or3
  Rect $b ($ox + 2) 29 124 2 $or0
  for ($x = 3; $x -lt 125; $x++) {
    $lit = ((($x + $f) % 6) -lt 2)
    $c = $(if ($lit) { C '#fff8dc' } else { $or3 })
    Px $b ($ox + $x) 3 $c; Px $b ($ox + $x) 32 $c
    if ($lit) { Tint $b ($ox + $x) 4 (C '#fff8dc') 0.5; Tint $b ($ox + $x) 31 (C '#fff8dc') 0.5 }
  }
  Rect $b ($ox + 3) 6 1 22 $or2; Rect $b ($ox + 124) 6 1 22 $or0
  # 左の小さなプリンタ（積み上がる）
  Rect $b ($ox + 7) 9 20 20 $ol
  Rect $b ($ox + 8) 10 18 18 $wh
  Rect $b ($ox + 8) 10 2 18 $or2; Rect $b ($ox + 24) 10 2 18 $or1
  Rect $b ($ox + 10) 25 14 2 $g5; Rect $b ($ox + 10) 25 14 1 $g3
  $lay = $f + 1
  for ($l = 0; $l -lt $lay; $l++) { Rect $b ($ox + 12) (24 - 2 * $l - 1) 10 2 $(if ($l % 2 -eq 0) { $pk } else { Mix $pk $ol 0.2 }) ; Px $b ($ox + 12) (24 - 2 * $l - 1) (Mix $pk $wh 0.5) }
  $topy = 24 - 2 * $lay - 1
  $ry = $topy - 5
  Rect $b ($ox + 10) $ry 14 2 $g5
  Rect $b ($ox + 15 + ($f % 3) * 2) ($ry + 2) 3 2 $ol; Px $b ($ox + 16 + ($f % 3) * 2) ($ry + 4) $or3
  # 文字: 影 → 白
  $tw = TextWidth '3Dプリンタ' 16
  $tx = 31 + [int]((93 - $tw) / 2)
  [void](TextPx $b '3Dプリンタ' ($ox + $tx + 1) 11 16 $or0 $true)
  [void](TextPx $b '3Dプリンタ' ($ox + $tx) 10 16 $wh $true)
  # 下線と、動くノズルの点
  Rect $b ($ox + $tx) 28 $tw 1 $or3
  $dx = [int](($tw - 6) * $f / 5.0)
  Rect $b ($ox + $tx + $dx) 28 6 1 (C '#ffffff')
  foreach ($p in @(@(0, 2), @(127, 2), @(0, 33), @(127, 33))) { Cut $b ($ox + $p[0]) $p[1] }
}

# ====================================================================
# 床 184x94: 六角形（ハニカム）の模様。真ん中の舞台のまわりにオレンジの輪、手前にオレンジの点線
Sheet 'printer3d_floor.png' 184 94 1 {
  param($b, $ox, $f)
  $s = 7.0
  $fa = C '#eef0f3'; $fb = C '#e5e8ec'; $fc = C '#f3f4f6'; $fe = C '#d0d4da'
  for ($y = 0; $y -lt 94; $y++) {
    for ($x = 0; $x -lt 184; $x++) {
      $px = $x + 0.5; $py = $y + 0.5
      $q = (0.57735 * $px - 0.33333 * $py) / $s
      $r = (0.66667 * $py) / $s
      $z = -$q - $r
      $rq = [math]::Floor($q + 0.5); $rr_ = [math]::Floor($r + 0.5); $rz = [math]::Floor($z + 0.5)
      $dq = [math]::Abs($rq - $q); $dr = [math]::Abs($rr_ - $r); $dz = [math]::Abs($rz - $z)
      if ($dq -gt $dr -and $dq -gt $dz) { $rq = -$rr_ - $rz } elseif ($dr -gt $dz) { $rr_ = -$rq - $rz }
      $hx = $s * 1.73205 * ($rq + $rr_ / 2.0); $hy = $s * 1.5 * $rr_
      $ddx = [math]::Abs($px - $hx); $ddy = [math]::Abs($py - $hy)
      $m = [math]::Max($ddx, 0.5 * $ddx + 0.86603 * $ddy)
      if ($m -gt $s * 0.86603 - 0.75) { $c = $fe }
      else {
        $sel = ((([int]($rq - $rr_)) % 3) + 3) % 3
        $c = $(if ($sel -eq 0) { $fa } elseif ($sel -eq 1) { $fb } else { $fc })
      }
      Px $b $x $y $c
    }
  }
  # 舞台（真ん中）のまわりのオレンジの輪
  for ($y = 40; $y -lt 94; $y++) {
    for ($x = 60; $x -lt 124; $x++) {
      $ex = ($x + 0.5 - 92) / 17.0; $ey = ($y + 0.5 - 76) / 5.4
      $d = $ex * $ex + $ey * $ey
      if ($d -le 1.0 -and $d -ge 0.62) { Tint $b $x $y $or2 0.75 }
    }
  }
  # 手前のオレンジの点線
  for ($x = 0; $x -lt 184; $x++) { if (($x % 10) -lt 6) { Px $b $x 91 $or1; Px $b $x 92 $or2 } }
  Rect $b 0 93 184 1 $g3
  # 奥に向かって少し暗く（壁の影）
  for ($y = 0; $y -lt 5; $y++) { for ($x = 0; $x -lt 184; $x++) { Tint $b $x $y $g4 (0.30 - $y * 0.055) } }
}

# ====================================================================
# 奥の壁 184x46: 層の線が入った白い壁、上のオレンジのはり、足元の灰色
Sheet 'printer3d_wall.png' 184 46 1 {
  param($b, $ox, $f)
  Rect $b 0 0 184 46 $cr1
  $lineC = Mix $cr1 $cr2 0.7
  for ($y = 7; $y -lt 38; $y += 3) { Rect $b 0 $y 184 1 $lineC }
  for ($x = 46; $x -lt 184; $x += 46) { Rect $b $x 5 1 33 $cr2; Rect $b ($x + 1) 5 1 33 $wh }
  # はり
  Rect $b 0 0 184 5 $ol
  Rect $b 0 1 184 3 $or1
  Rect $b 0 1 184 1 $or3
  Rect $b 0 3 184 1 $or0
  for ($x = 4; $x -lt 184; $x += 12) { Px $b $x 2 $ol; Px $b ($x + 1) 2 $or2 }
  for ($x = 0; $x -lt 184; $x++) { Tint $b $x 5 $cr3 0.5; Tint $b $x 6 $cr3 0.25 }
  # 足元
  Rect $b 0 38 184 8 $ol
  Rect $b 0 39 184 5 $g4
  Rect $b 0 39 184 1 $g3
  Rect $b 0 42 184 1 $or1
  Rect $b 0 43 184 1 $g5
  for ($x = 0; $x -lt 184; $x += 12) { Rect $b $x 40 1 2 $g5 }
}

# ====================================================================
# 3Dプリンタ本体 56x56（造形物が下から積み上がる。ノズルが左右に動く。LEDが流れる）14コマ
Sheet 'printer3d_printer.png' 56 56 14 {
  param($b, $ox, $f)
  Printer $b $ox $f 14 $true $tq 'vase'
}

# 小さなプリンタ 26x28（黄色い円すいを積む）10コマ
Sheet 'printer3d_mini.png' 26 28 10 {
  param($b, $ox, $f)
  Printer $b $ox $f 10 $false $yw 'cone'
}

# ====================================================================
# プリンタの台 60x12（白いキャビネット、オレンジの帯）
Sheet 'printer3d_ped.png' 60 12 1 {
  param($b, $ox, $f)
  Rect $b 0 0 60 12 $ol
  Rect $b 1 1 58 10 $g1
  Rect $b 1 1 58 3 $wh
  Rect $b 1 4 58 1 $g2
  foreach ($x in 20, 40) { Rect $b $x 5 1 5 $g3 }
  foreach ($x in 7, 27, 47) { Rect $b $x 6 6 1 $or1; Rect $b $x 7 6 1 $or0 }
  Rect $b 1 10 58 1 $or1
  Rect $b 3 11 6 1 $ol; Rect $b 51 11 6 1 $ol
  foreach ($p in @(@(0, 0), @(59, 0), @(0, 11), @(59, 11))) { Cut $b $p[0] $p[1] }
}

# ====================================================================
# 展示棚 58x50（できあがった造形物がならぶ。棚の中にもうっすら層の線）
Sheet 'printer3d_shelf.png' 58 50 1 {
  param($b, $ox, $f)
  Rect $b 0 0 58 50 $ol
  Rect $b 1 1 56 48 $g1
  $inner = $cr1; $lineC = Mix $cr1 $cr2 0.7
  # 3つの棚（4..16 / 19..31 / 34..46）
  foreach ($top in 4, 19, 34) {
    Rect $b 4 $top 50 13 $inner
    for ($y = $top + 2; $y -lt $top + 13; $y += 3) { Rect $b 4 $y 50 1 $lineC }
    Rect $b 4 ($top + 13) 50 2 $g3
    Rect $b 4 ($top + 13) 50 1 $g2
  }
  # 上のオレンジのふちと光
  Rect $b 1 1 56 3 $or1
  Rect $b 1 1 56 1 $or3
  Rect $b 1 3 56 1 $or0
  foreach ($top in 4, 19, 34) {
    if ($top -eq 4) { $ly = 4 } else { $ly = $top }
    for ($x = 4; $x -lt 54; $x++) { if (($x % 4) -lt 2) { Tint $b $x $ly $or4 0.6; Tint $b $x ($ly + 1) $or4 0.25 } }
  }
  # 足
  Rect $b 1 47 56 2 $g4
  Rect $b 1 47 56 1 $g3
  # 側板の色
  Rect $b 1 4 3 43 $g0; Rect $b 54 4 3 43 $g2
  # 造形物（1段目）
  ItemOn $b 11 16 'robot' $tq
  ItemOn $b 23 16 'cat' $pk
  ItemOn $b 35 16 'penguin' $sk
  ItemOn $b 47 16 'mushroom' $rr
  # 2段目
  ItemOn $b 10 31 'bear' $or2
  ItemOn $b 22 31 'vase' $lv
  ItemOn $b 33 31 'rocket' $yw
  ItemOn $b 44 31 'heart' $pk
  ItemOn $b 51 31 'star' $yw
  # 3段目（右半分はとなりの小さなプリンタの後ろ）
  ItemOn $b 10 46 'cat' $tq
  ItemOn $b 21 46 'bear' $pk
  ItemOn $b 31 46 'penguin' $lv
  ItemOn $b 41 46 'robot' $yw
  ItemOn $b 51 46 'mushroom' $or2
  foreach ($p in @(@(0, 0), @(57, 0), @(0, 49), @(57, 49))) { Cut $b $p[0] $p[1] }
}

# ====================================================================
# フィラメントのスプール（正面から見た巻き）
function Spool($b, $cx, $cy, $col, $f) {
  Ellipse $b ($cx + 0.5) ($cy + 0.5) 7.2 7.2 $ol
  Ellipse $b ($cx + 0.5) ($cy + 0.5) 6.4 6.4 (Mix $col $wh 0.35)
  Ellipse $b ($cx + 0.5) ($cy + 0.5) 5.4 5.4 $col
  Ellipse $b ($cx + 0.5) ($cy + 0.5) 4.1 4.1 (Mix $col $ol 0.3)
  Ellipse $b ($cx + 0.5) ($cy + 0.5) 3.2 3.2 $wh
  Ellipse $b ($cx + 0.5) ($cy + 0.5) 1.0 1.0 $ol
  for ($i = 0; $i -lt 3; $i++) {
    $a = ($f * 30 + $i * 120) * [math]::PI / 180
    P $b ($cx + 0.0 + 2.2 * [math]::Cos($a)) ($cy + 0.0 + 2.2 * [math]::Sin($a)) $g4
  }
  Px $b ($cx - 3) ($cy - 4) $wh; Px $b ($cx - 4) ($cy - 3) $wh
}
# スプールかけ 54x44（かべに かける。スプールが ゆっくり まわる）4コマ
Sheet 'printer3d_rack.png' 54 44 4 {
  param($b, $ox, $f)
  Rect $b $ox 0 54 44 $ol
  Rect $b ($ox + 1) 1 52 42 $g1
  for ($y = 3; $y -lt 42; $y += 4) { for ($x = 3; $x -lt 52; $x += 4) { Px $b ($ox + $x) $y $g2 } }
  foreach ($by in 18, 40) { Rect $b ($ox + 1) $by 52 3 $ol; Rect $b ($ox + 1) ($by + 1) 52 1 $or1; Rect $b ($ox + 1) ($by + 1) 52 1 $or2; Rect $b ($ox + 1) ($by + 2) 52 1 $or0 }
  Spool $b ($ox + 10) 10 $pk $f
  Spool $b ($ox + 27) 10 $tq $f
  Spool $b ($ox + 44) 10 $yw $f
  Spool $b ($ox + 10) 32 $lv $f
  Spool $b ($ox + 27) 32 $or2 $f
  Spool $b ($ox + 44) 32 $sk $f
  foreach ($p in @(@(0, 0), @(53, 0), @(0, 43), @(53, 43))) { Cut $b ($ox + $p[0]) $p[1] }
}

# ====================================================================
# 作業台 56x26（ヘラ・やすり・ニッパー・ナイフ。天板に灰色のマット。右はミニプリンタを置くあき）
Sheet 'printer3d_bench.png' 56 26 1 {
  param($b, $ox, $f)
  Rect $b 0 0 56 10 $ol
  Rect $b 1 1 54 8 $wh
  Rect $b 1 8 54 1 $cr2
  # マット
  Rect $b 3 2 26 6 $g5
  for ($x = 6; $x -lt 28; $x += 4) { Rect $b $x 2 1 6 $g4 }
  Rect $b 3 4 26 1 $g4
  Rect $b 3 2 3 1 $or2; Rect $b 3 2 1 3 $or2
  # ヘラ（オレンジの持ち手、灰色の刃）
  Rect $b 6 3 5 2 $or1; Rect $b 6 3 5 1 $or3
  Rect $b 11 3 8 2 $g2; Rect $b 11 3 8 1 $wh; Px $b 18 3 $g3; Px $b 18 4 $g3
  # やすり
  Rect $b 6 6 3 2 $or1; Rect $b 9 6 8 2 $g3; Rect $b 9 6 8 1 $g2
  # ナイフ
  Rect $b 19 6 3 2 $g6; Line $b 22 6 26 5 $g2
  # ニッパー
  Line $b 20 3 26 3 $rr; Line $b 20 4 26 4 $rr; Px $b 27 3 $g3; Px $b 27 4 $g3
  # 前の面
  Rect $b 0 10 56 14 $ol
  Rect $b 1 10 54 13 $g1
  Rect $b 1 10 54 1 $wh
  foreach ($dx0 in 3, 30) {
    Rect $b $dx0 12 24 9 $ol; Rect $b ($dx0 + 1) 13 22 7 $g0; Rect $b ($dx0 + 1) 13 22 1 $wh
    Rect $b ($dx0 + 9) 16 6 1 $or1; Rect $b ($dx0 + 9) 17 6 1 $or0
  }
  Rect $b 1 22 54 1 $or1
  Rect $b 2 24 4 2 $ol; Rect $b 50 24 4 2 $ol
  foreach ($p in @(@(0, 0), @(55, 0), @(0, 25), @(55, 25))) { Cut $b $p[0] $p[1] }
}

# ====================================================================
# 売り台 56x38（オレンジと白のしましま。上に造形物。前の札は別の絵）
Sheet 'printer3d_sales.png' 56 38 1 {
  param($b, $ox, $f)
  # 天板（上の面）: 12..22
  Rect $b 0 12 56 10 $ol
  Rect $b 1 13 54 8 $wh
  Rect $b 1 20 54 1 $cr2
  # 前のしまクロス
  Rect $b 0 22 56 14 $ol
  for ($x = 1; $x -lt 55; $x++) {
    $st = ((([int][math]::Floor(($x - 1) / 4)) % 2) -eq 0)
    Rect $b $x 22 1 12 $(if ($st) { $or1 } else { $g0 })
    if ($st) { Px $b $x 22 $or3 } else { Px $b $x 22 $wh }
  }
  for ($x = 1; $x -lt 55; $x += 4) { Rect $b $x 34 4 1 $(if ((([int][math]::Floor(($x - 1) / 4)) % 2) -eq 0) { $or0 } else { $g2 }) }
  Rect $b 2 36 4 2 $ol; Rect $b 50 36 4 2 $ol
  # 上の造形物（右がわ。左はキーホルダーかけ）
  ItemOn $b 33 19 'bear' $or2
  ItemOn $b 42 19 'penguin' $sk
  ItemOn $b 50 19 'rocket' $rr
  foreach ($p in @(@(0, 12), @(55, 12), @(0, 37), @(55, 37))) { Cut $b $p[0] $p[1] }
}

# 札「おみやげ」 48x12（売り台の前に重ねる。太字・読みやすさ優先）
Sheet 'printer3d_sales_tag.png' 48 12 1 {
  param($b, $ox, $f)
  Rect $b 0 0 48 12 $ol
  Rect $b 1 1 46 10 $cr1
  Rect $b 1 1 46 1 $wh
  [void](TextPx $b 'おみやげ' 2 0 11 $or0 $true)
  foreach ($p in @(@(0, 0), @(47, 0), @(0, 11), @(47, 11))) { Cut $b $p[0] $p[1] }
}


# ====================================================================
# キーホルダーかけ 22x24（キーホルダーがゆらゆら）4コマ
Sheet 'printer3d_keys.png' 22 24 4 {
  param($b, $ox, $f)
  # 台と柱
  Rect $b ($ox + 6) 21 10 3 $ol; Rect $b ($ox + 7) 22 8 1 $g3; Rect $b ($ox + 7) 21 8 1 $g2
  Rect $b ($ox + 10) 3 2 18 $ol; Rect $b ($ox + 10) 4 1 17 $g3; Rect $b ($ox + 11) 4 1 17 $g5
  # よこぼう
  Rect $b ($ox + 1) 2 20 3 $ol; Rect $b ($ox + 2) 3 18 1 $g3
  Rect $b ($ox + 1) 2 2 3 $or1; Rect $b ($ox + 19) 2 2 3 $or1
  $kc = @(@(4, 5, 'heart', $pk), @(11, 8, 'star', $yw), @(18, 5, 'heart', $sk))
  $i = 0
  foreach ($k in $kc) {
    $sway = [int][math]::Round(1.2 * [math]::Sin($f * [math]::PI / 2 + $i * 2.1))
    $hx = $k[0]; $len = $k[1]
    $ix = $hx + $sway
    # くさり
    for ($yy = 4; $yy -lt 4 + $len; $yy++) { $tt = ($yy - 4) / [double]$len; Px $b ($ox + [int][math]::Round($hx + $sway * $tt)) $yy $g4 }
    Px $b ($ox + $ix) (4 + $len) $g3
    Item $b ($ox + $ix - 3) (5 + $len) $k[2] $k[3] 1 $false
    $i++
  }
}

# ====================================================================
# 回転台 24x38（できあがった ねこ が くるくる回る）8コマ
Sheet 'printer3d_turntable.png' 24 38 8 {
  param($b, $ox, $f)
  # 台
  $cx = $ox + 12
  Ellipse $b $cx 33.5 10.8 3.4 $ol
  Rect $b ($ox + 1) 26 22 8 $ol
  Rect $b ($ox + 2) 26 20 8 $g1
  Rect $b ($ox + 2) 26 3 8 $wh
  Rect $b ($ox + 19) 26 3 8 $g2
  Rect $b ($ox + 2) 30 20 2 $or1; Rect $b ($ox + 2) 30 20 1 $or2
  Ellipse $b $cx 33.5 10.2 3.0 $g1
  Rect $b ($ox + 2) 30 20 2 $or1; Rect $b ($ox + 2) 30 20 1 $or2
  Rect $b ($ox + 2) 26 20 3 $g1
  Ellipse $b $cx 26.5 10.8 3.4 $ol
  Ellipse $b $cx 26.5 9.8 2.6 $g0
  Ellipse $b $cx 26.5 7.6 1.8 $or2
  Ellipse $b $cx 26.5 6.6 1.3 $g0
  # 回るねこ
  $tf = NewBmp 18 20; $tb = NewBmp 18 20
  Item $tf 0 0 'cat' $or2 2 $false
  Item $tb 0 0 'cat' $or2 2 $true
  $cv = [math]::Cos($f * [math]::PI / 4)
  $s = [math]::Max([math]::Abs($cv), 0.1)
  $src = $(if ($cv -ge 0) { $tf } else { $tb })
  for ($i = 0; $i -lt 18; $i++) {
    $u = ($i + 0.5 - 9) / $s
    if ($cv -lt 0) { $u = -$u }
    $sxx = [int][math]::Floor($u + 9)
    if ($sxx -lt 0 -or $sxx -ge 18) { continue }
    for ($yy = 0; $yy -lt 20; $yy++) {
      $c = $src.GetPixel($sxx, $yy)
      if ($c.A -gt 0) { Px $b ($ox + 3 + $i) (6 + $yy) $c }
    }
  }
  $tf.Dispose(); $tb.Dispose()
  # きらっ
  if ($f % 4 -eq 1) { Px $b ($ox + 3) 7 $wh; Px $b ($ox + 2) 7 $or4; Px $b ($ox + 4) 7 $or4; Px $b ($ox + 3) 6 $or4; Px $b ($ox + 3) 8 $or4 }
  if ($f % 4 -eq 3) { Px $b ($ox + 20) 12 $wh; Px $b ($ox + 19) 12 $or4; Px $b ($ox + 21) 12 $or4; Px $b ($ox + 20) 11 $or4; Px $b ($ox + 20) 13 $or4 }
}

# ====================================================================
# ポスター（設計図の線画）24x20
Sheet 'printer3d_poster_a.png' 24 20 1 {
  param($b, $ox, $f)
  Rect $b 0 0 24 20 $ol
  Rect $b 1 1 22 18 $wh
  Rect $b 1 1 22 1 $cr2
  # 立方体（等角図）
  $pT = @(12, 3); $pUR = @(18, 6); $pLR = @(18, 12); $pB = @(12, 15); $pLL = @(6, 12); $pUL = @(6, 6); $pC = @(12, 9)
  Line $b $pT[0] $pT[1] $pUR[0] $pUR[1] $g4; Line $b $pUR[0] $pUR[1] $pLR[0] $pLR[1] $g4; Line $b $pLR[0] $pLR[1] $pB[0] $pB[1] $g4
  Line $b $pB[0] $pB[1] $pLL[0] $pLL[1] $g4; Line $b $pLL[0] $pLL[1] $pUL[0] $pUL[1] $g4; Line $b $pUL[0] $pUL[1] $pT[0] $pT[1] $g4
  Line $b $pC[0] $pC[1] $pUL[0] $pUL[1] $or1; Line $b $pC[0] $pC[1] $pUR[0] $pUR[1] $or1; Line $b $pC[0] $pC[1] $pB[0] $pB[1] $or1
  # 寸法線
  Line $b 6 17 18 17 $or1; Px $b 6 16 $or1; Px $b 6 18 $or1; Px $b 18 16 $or1; Px $b 18 18 $or1
  Rect $b 1 1 3 2 $g2; Rect $b 20 1 3 2 $g2
}
Sheet 'printer3d_poster_b.png' 24 20 1 {
  param($b, $ox, $f)
  Rect $b 0 0 24 20 $ol
  Rect $b 1 1 22 18 $wh
  Rect $b 1 1 22 1 $cr2
  # 輪切りにした花びん
  $hws = @(2, 3, 4, 5, 5, 4, 3, 4, 5, 5)
  for ($i = 0; $i -lt 10; $i++) {
    $yy = 3 + $i * 1.5
    $hw = $hws[$i]
    $c = $(if ($i -lt 6) { $or1 } else { $g4 })
    Line $b ([int](9 - $hw)) ([int]$yy) ([int](9 + $hw)) ([int]$yy) $c
    Px $b ([int](9 - $hw)) ([int]$yy) $ol; Px $b ([int](9 + $hw)) ([int]$yy) $ol
  }
  # 矢印と層
  Line $b 17 4 17 14 $g3; Px $b 16 5 $g3; Px $b 18 5 $g3; Px $b 16 13 $g3; Px $b 18 13 $g3
  Line $b 19 4 21 4 $or1; Line $b 19 8 21 8 $or1; Line $b 19 12 21 12 $or1
  Line $b 4 17 14 17 $g4
  Rect $b 1 1 3 2 $g2; Rect $b 20 1 3 2 $g2
}

# ====================================================================
# のぼり 16x60（オレンジ地に白い縦書き / 白地にオレンジ）
Sheet 'printer3d_nobori_a.png' 16 60 1 {
  param($b, $ox, $f)
  Rect $b 0 0 2 60 $g5; Rect $b 0 0 1 60 $g3
  Rect $b 0 0 16 2 $ol; Rect $b 14 0 2 3 $or0
  Rect $b 2 2 14 56 $ol
  Rect $b 3 3 12 54 $or1
  Rect $b 3 3 12 1 $or3; Rect $b 3 3 1 54 $or2; Rect $b 14 3 1 54 $or0
  for ($y = 55; $y -le 59; $y++) { $d = $y - 54; Rect $b (9 - $d) $y (2 * $d) 1 $none }
  Rect $b 4 5 10 1 $or3
  $ys = 7
  foreach ($ch in @('プ', 'リ', 'ン', 'タ')) { [void](TextPx $b $ch 4 $ys 11 $wh $true); $ys += 11 }
}
Sheet 'printer3d_nobori_b.png' 16 60 1 {
  param($b, $ox, $f)
  Rect $b 0 0 2 60 $g5; Rect $b 0 0 1 60 $g3
  Rect $b 0 0 16 2 $ol; Rect $b 14 0 2 3 $or0
  Rect $b 2 2 14 56 $ol
  Rect $b 3 3 12 54 $wh
  Rect $b 3 3 12 1 $or2; Rect $b 3 3 1 54 $cr2; Rect $b 14 3 1 54 $cr2
  for ($y = 55; $y -le 59; $y++) { $d = $y - 54; Rect $b (9 - $d) $y (2 * $d) 1 $none }
  Rect $b 4 5 10 1 $or1
  $ys = 7
  foreach ($ch in @('つ', 'く', 'ろ', 'う')) { [void](TextPx $b $ch 4 $ys 11 $or1 $true); $ys += 11 }
}

# ====================================================================
# 失敗作の箱 16x14（ぐちゃっと からまった フィラメント）
Sheet 'printer3d_bin.png' 16 14 1 {
  param($b, $ox, $f)
  # からまり
  $pts = @(@(2, 5, 6, 1), @(6, 1, 11, 3), @(11, 3, 5, 4), @(5, 4, 12, 1), @(12, 1, 14, 5), @(3, 2, 9, 5), @(9, 5, 4, 0), @(4, 0, 8, 2))
  $cc = @($or1, $or2, $or3, $or1, $or2, $or1, $or3, $or2)
  for ($i = 0; $i -lt $pts.Count; $i++) { Line $b $pts[$i][0] $pts[$i][1] $pts[$i][2] $pts[$i][3] $cc[$i] }
  Ellipse $b 5.5 4.2 2.4 1.6 $pk; Px $b 4 3 (Mix $pk $wh 0.5); Ellipse $b 5.5 5 2.4 0.6 (Mix $pk $ol 0.4)
  # 箱
  Rect $b 0 5 16 9 $ol
  Rect $b 1 6 14 7 $cr3
  Rect $b 1 6 14 1 $cr2
  Rect $b 1 12 14 1 (Mix $cr3 $ol 0.3)
  Rect $b 6 8 4 3 $cr2; Rect $b 6 8 4 1 $wh
  Rect $b 3 8 2 1 $ol; Rect $b 11 8 2 1 $ol
  foreach ($p in @(@(0, 5), @(15, 5), @(0, 13), @(15, 13))) { Cut $b $p[0] $p[1] }
}

# ====================================================================
# スプールの山 22x22（よこにして つんである）
function SpoolSide($b, $x, $y, $col) {
  Rect $b $x $y 12 11 $ol
  Rect $b ($x + 1) ($y + 1) 10 9 $col
  Rect $b ($x + 1) ($y + 1) 10 1 (Mix $col $wh 0.5)
  Rect $b ($x + 1) ($y + 8) 10 2 (Mix $col $ol 0.2)
  # フランジ
  Rect $b $x $y 2 11 $ol; Rect $b ($x + 1) ($y + 1) 1 9 (Mix $col $wh 0.55)
  Rect $b ($x + 10) $y 2 11 $ol; Rect $b ($x + 10) ($y + 1) 1 9 (Mix $col $wh 0.3)
  # まきこみの線
  for ($i = 3; $i -lt 10; $i += 2) { Rect $b ($x + $i) ($y + 2) 1 7 (Mix $col $ol 0.12) }
}
Sheet 'printer3d_pile.png' 24 22 1 {
  param($b, $ox, $f)
  SpoolSide $b 0 11 $pk
  SpoolSide $b 12 11 $yw
  SpoolSide $b 6 0 $lv
  Line $b 22 20 23 16 $yw
  foreach ($p in @(@(0, 11), @(23, 11), @(0, 21), @(23, 21), @(6, 0), @(17, 0))) { Cut $b $p[0] $p[1] }
}

# ====================================================================
# エプロン（人物の胴にかぶせる）96x64。人物と同じ位置・同じ向きで重ねる
Sheet 'printer3d_apron.png' 96 64 1 {
  param($b, $ox, $f)
  Rect $b 43 34 10 4 $or1
  Rect $b 43 34 10 1 $or3
  Rect $b 44 37 8 1 $or0
  Px $b 46 35 $wh; Px $b 47 35 $wh; Px $b 46 36 $or3
  Px $b 43 33 $or2; Px $b 52 33 $or2
}
