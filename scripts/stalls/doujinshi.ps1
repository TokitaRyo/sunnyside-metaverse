# 同人誌（部員が作った本を売る即売ブース）の専用ドット絵を作る。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/stalls/doujinshi.ps1   （リポジトリのルートで実行）
#   一部だけ作り直す: $env:DJ_ONLY='sign|wall'; powershell ...（名前の正規表現）
# 出力: client/public/brand/stall/doujinshi_*.png （配置は scripts/stalls/doujinshi.mjs）
# 内容: 床(ビニールタイル+マット) / 奥のパーテーション壁(表紙のポスターと吊るした見本) / 看板(電球が流れる) /
#       布をかけた長机 / 平積み / 新刊POP / 立てかけた本のスタンド / めくれる見本誌 / スペース番号札 / ペンとインク /
#       きらきら / 見本誌ラック / パイプ椅子 / 段ボール箱 / 袋詰めの本 / のぼり2本 / 立て看板
# 絵はすべてこのスクリプトで描いたオリジナル（素材パックの絵は使わない）。本の表紙は抽象的な絵と模様だけで、実在の作品・キャラクターは描かない。
# 日本語の文字は MS Gothic を1bitでドットにして貼る。Windows 専用。
. "$PSScriptRoot\..\lib\pixel.ps1"

function Mix($a, $z, $t) { [System.Drawing.Color]::FromArgb(255, [int]($a.R + ($z.R - $a.R) * $t), [int]($a.G + ($z.G - $a.G) * $t), [int]($a.B + ($z.B - $a.B) * $t)) }
function Sheet($name, $w, $h, $n, $draw, $ol = $false) {
  if ($env:DJ_ONLY -and ($name -notmatch $env:DJ_ONLY)) { return }
  $bm = NewBmp ($w * $n) $h
  for ($f = 0; $f -lt $n; $f++) { & $draw $bm ($f * $w) $f }
  if ($ol) { Outline $bm $ink }
  Save $bm $name
}
function L($b, $x0, $y0, $x1, $y1, $col) { Line $b ([int][math]::Round($x0)) ([int][math]::Round($y0)) ([int][math]::Round($x1)) ([int][math]::Round($y1)) $col }
# 透明な画素に隣り合う画素に輪郭を付ける（絵の周りに1pxの余白が要る）
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
# 十字のきらきら（r = 腕の長さ）
function Star($b, $cx, $cy, $r, $col, $core) {
  for ($i = 1; $i -le $r; $i++) { Px $b ($cx + $i) $cy $col; Px $b ($cx - $i) $cy $col; Px $b $cx ($cy + $i) $col; Px $b $cx ($cy - $i) $col }
  Px $b $cx $cy $core
}

# ---- 色 ----
$ink = C '#2a2036'
$nv0 = C '#3b4a86'; $nv1 = C '#26325e'; $nv2 = C '#1a2347'; $nv3 = C '#10152c'                         # 紺
$gl0 = C '#fbe08a'; $gl1 = C '#e0ac3c'; $gl2 = C '#a8741c'                                           # 金
$cr0 = C '#fffaf0'; $cr1 = C '#f4ead2'; $cr2 = C '#dccfaa'; $cr3 = C '#b0a27c'                       # 紙
$wd0 = C '#e0b27a'; $wd1 = C '#b9824f'; $wd2 = C '#8a542f'; $wd3 = C '#5e3822'; $wd4 = C '#3b2214'   # 木
$lv0 = C '#d9ccfb'; $lv1 = C '#b3a2f0'; $lv2 = C '#8c78d8'; $lv3 = C '#6a56b4'; $lv4 = C '#473a86'   # 机の布（ラベンダー）
$kr0 = C '#dcb579'; $kr1 = C '#bf9156'; $kr2 = C '#8f6a38'; $kr3 = C '#634522'                       # 段ボール
$sv0 = C '#c4c9d8'; $sv1 = C '#9aa0b4'; $sv2 = C '#6c7288'                                           # 金属
$rd = C '#d6403a'; $rd2 = C '#9d2a2a'; $pk = C '#f0508a'; $yl = C '#ffd36a'
$gn0 = C '#8ed17a'; $gn1 = C '#56ad5a'; $gn2 = C '#2f7a48'
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

# 表紙の色: 地・明るい色・アクセント・暗い縁
$cvp = @(
  @((C '#e8705e'), (C '#f6a58a'), (C '#ffe3a0'), (C '#8a2f3c')),   # 0 珊瑚
  @((C '#4aa3d8'), (C '#8fd0ee'), (C '#fff2c0'), (C '#1f4f7a')),   # 1 空
  @((C '#52b788'), (C '#a5e0c0'), (C '#fff7d6'), (C '#1f6048')),   # 2 若草
  @((C '#7b5fc4'), (C '#b9a4ee'), (C '#ffd9e8'), (C '#41307a')),   # 3 すみれ
  @((C '#f2c230'), (C '#ffe58a'), (C '#e2573f'), (C '#8a5a14')),   # 4 たまご
  @((C '#ee6fa0'), (C '#f8b4cf'), (C '#ffffff'), (C '#8a2a58')),   # 5 もも
  @((C '#2c3e7a'), (C '#5b73c4'), (C '#f6d36b'), (C '#161f44'))    # 6 夜
)
# 抽象的な表紙 1 冊（x,y が左上）。st: 0 太陽と丘 / 1 しま / 2 山と月 / 3 モザイク / 4 波 / 5 水玉
function Cover($b, $x, $y, $w, $h, $ci, $st) {
  $pl = $cvp[$ci]
  $ix = $x + 1; $iy = $y + 1; $iw = $w - 2; $ih = $h - 2
  Rect $b $x $y $w $h $pl[3]
  Rect $b $ix $iy $iw $ih $pl[0]
  switch ($st) {
    0 {
      $r = [math]::Min($iw, $ih) * 0.24
      Ellipse $b ($ix + $iw * 0.5) ($iy + $ih * 0.42) $r $r $pl[2]
      for ($i = 0; $i -lt $iw; $i++) {
        $top = [int]($ih * 0.68 + 1.6 * [math]::Sin($i * 0.55))
        for ($j = $top; $j -lt $ih; $j++) { Px $b ($ix + $i) ($iy + $j) $(if ($j -eq $top) { $pl[2] } else { $pl[1] }) }
      }
    }
    1 {
      for ($j = 0; $j -lt $ih; $j++) { for ($i = 0; $i -lt $iw; $i++) { if ((($i + $j) % 7) -lt 2) { Px $b ($ix + $i) ($iy + $j) $pl[1] } } }
      $cx = [int]($ix + $iw / 2); $cy = [int]($iy + $ih / 2)
      if ($iw -ge 10) { Rect $b ($cx - 2) ($cy - 2) 5 5 $pl[3]; Rect $b ($cx - 1) ($cy - 1) 3 3 $pl[2] } else { Rect $b ($cx - 1) ($cy - 1) 3 3 $pl[2] }
    }
    2 {
      $dk = Mix $pl[0] $pl[3] 0.45
      for ($i = 0; $i -lt $iw; $i++) {
        $t1 = [int]($ih * 0.30 + [math]::Abs($i - $iw * 0.34) * 1.1)
        for ($j = $t1; $j -lt $ih; $j++) { Px $b ($ix + $i) ($iy + $j) $(if ($j -eq $t1 -and $j -lt $ih * 0.5) { $pl[2] } else { $pl[1] }) }
      }
      for ($i = 0; $i -lt $iw; $i++) {
        $t2 = [int]($ih * 0.52 + [math]::Abs($i - $iw * 0.72) * 1.0)
        for ($j = $t2; $j -lt $ih; $j++) { Px $b ($ix + $i) ($iy + $j) $dk }
      }
      Ellipse $b ($ix + $iw * 0.76) ($iy + $ih * 0.2) 1.6 1.6 $pl[2]
    }
    3 {
      for ($j = 2; $j -lt $ih - 2; $j += 3) { for ($i = 2; $i -lt $iw - 2; $i += 3) {
        $ca = [int][math]::Floor(($i - 2) / 3); $cb = [int][math]::Floor(($j - 2) / 3)
        if ($i + 2 -le $iw - 1 -and $j + 2 -le $ih - 1) { Rect $b ($ix + $i) ($iy + $j) 2 2 $(if ((($ca + $cb) % 2) -eq 0) { $pl[1] } else { $pl[2] }) }
      } }
    }
    4 {
      for ($k2 = 0; $k2 -lt 6; $k2++) {
        $base = 3 + $k2 * 3
        for ($i = 0; $i -lt $iw; $i++) {
          $yy = $base + [int][math]::Round(1.3 * [math]::Sin($i * 0.7 + $k2))
          if ($yy -ge 0 -and $yy -lt $ih) { Px $b ($ix + $i) ($iy + $yy) $(if ($k2 % 2 -eq 0) { $pl[1] } else { $pl[2] }) }
        }
      }
    }
    5 {
      for ($j = 1; $j -lt $ih - 1; $j += 3) { for ($i = 1; $i -lt $iw - 1; $i += 3) {
        $oo = 0; if ((($j - 1) / 3) % 2 -eq 1) { $oo = 1 }
        Px $b ($ix + $i + $oo) ($iy + $j) $pl[2]
      } }
      $r5 = [math]::Min($iw, $ih) * 0.22
      Ellipse $b ($ix + $iw * 0.5) ($iy + $ih * 0.55) $r5 $r5 $pl[1]
      Px $b ([int]($ix + $iw * 0.5)) ([int]($iy + $ih * 0.55)) $pl[3]
    }
  }
  if ($ih -ge 12 -and $iw -ge 8) {
    Rect $b ($ix + 1) ($iy + 1) ($iw - 2) 3 $cr0
    Rect $b ($ix + 2) ($iy + 2) ($iw - 4) 1 $pl[3]
  }
  if ($ih -ge 10) { Px $b $ix ($iy + 2) $sv2; Px $b $ix ($iy + $ih - 3) $sv2 }
}

# ====================================================================
# 床 184x74: ビニールのタイル床。奥は壁の影、手前にマット、床のテープの角
Sheet 'doujinshi_floor.png' 184 74 1 {
  param($b, $ox, $f)
  $t0 = C '#dfe3ec'; $t1 = C '#d3d8e4'; $gr = C '#b8bece'; $hi = C '#eff1f7'; $sp = C '#c4cad9'
  for ($ty = 0; $ty -lt 5; $ty++) { for ($tx = 0; $tx -lt 12; $tx++) {
    $cc = if ((($tx + $ty) % 2) -eq 0) { $t0 } else { $t1 }
    $x0 = $ox + $tx * 16; $y0 = $ty * 16
    Rect $b $x0 $y0 16 16 $cc
    Rect $b $x0 $y0 16 1 $hi; Rect $b $x0 $y0 1 16 $hi
    Rect $b $x0 ($y0 + 15) 16 1 $gr; Rect $b ($x0 + 15) $y0 1 16 $gr
    Px $b ($x0 + 5 + (($tx * 3 + $ty) % 5)) ($y0 + 4 + (($tx + $ty * 2) % 6)) $sp
    Px $b ($x0 + 10 - (($tx + $ty) % 4)) ($y0 + 10 + (($tx * 2 + $ty) % 4)) $sp
  } }
  # マット（ミント。しま模様とふさ）
  $mx = 36; $my = 36; $mw = 104; $mh = 22
  Rect $b ($ox + $mx) $my $mw $mh (C '#6fb0a0')
  Rect $b ($ox + $mx + 2) ($my + 2) ($mw - 4) ($mh - 4) (C '#b5e0cf')
  for ($x = $mx + 6; $x -lt $mx + $mw - 4; $x += 8) { Rect $b ($ox + $x) ($my + 2) 3 ($mh - 4) (C '#9ad2bd') }
  Rect $b ($ox + $mx + 2) ($my + 2) ($mw - 4) 1 (C '#d6f3e6')
  Rect $b ($ox + $mx + 2) ($my + 4) ($mw - 4) 1 (C '#fffaf0')
  Rect $b ($ox + $mx + 2) ($my + $mh - 5) ($mw - 4) 1 (C '#fffaf0')
  for ($y = $my + 2; $y -lt $my + $mh - 2; $y += 2) { Px $b ($ox + $mx - 1) $y (C '#e9dcc0'); Px $b ($ox + $mx + $mw) $y (C '#e9dcc0') }
  foreach ($p in @(@($mx, $my), @(($mx + $mw - 1), $my), @($mx, ($my + $mh - 1)), @(($mx + $mw - 1), ($my + $mh - 1)))) { Clear $b ($ox + $p[0]) $p[1] }
  # 床のテープ（ブースの角を示す黄色いL字）
  $tp = C '#f2b544'
  foreach ($c in @(@(6, 10, 1, 1), @(177, 10, -1, 1), @(6, 66, 1, -1), @(177, 66, -1, -1))) {
    Rect $b ($ox + $c[0]) $c[1] 1 1 $tp
    for ($i = 0; $i -lt 8; $i++) { Px $b ($ox + $c[0] + $i * $c[2]) $c[1] $tp; Px $b ($ox + $c[0]) ($c[1] + $i * $c[3]) $tp }
  }
  # 壁ぎわの影
  for ($i = 0; $i -lt 4; $i++) { Rect $b $ox $i 184 1 ([System.Drawing.Color]::FromArgb(70 - $i * 16, 40, 30, 70)) }
}

# ====================================================================
# 奥の壁 176x48: パーテーションに表紙のポスター、ひもに吊るした見本
Sheet 'doujinshi_wall.png' 176 48 1 {
  param($b, $ox, $f)
  $pn = C '#e9e5f3'; $pn2 = C '#ddd8ec'; $pn3 = C '#c9c1e0'
  $mt0 = C '#b9b5ce'; $mt1 = C '#8581a2'; $mt2 = C '#5c5877'
  Rect $b $ox 0 176 48 $pn
  for ($y = 6; $y -lt 40; $y += 4) { for ($x = 5; $x -lt 172; $x += 6) { Px $b ($ox + $x + (($y / 4) % 2) * 3) $y $pn2 } }
  Rect $b $ox 0 176 4 $mt1; Rect $b $ox 0 176 1 $mt0; Rect $b $ox 3 176 1 $mt2
  Rect $b $ox 4 176 1 $pn3
  foreach ($sx in @(0, 43, 87, 131, 173)) {
    Rect $b ($ox + $sx) 4 3 38 $mt1; Rect $b ($ox + $sx) 4 1 38 $mt0; Rect $b ($ox + $sx + 2) 4 1 38 $mt2
  }
  Rect $b $ox 42 176 6 (C '#9a95b8'); Rect $b $ox 42 176 1 $mt0; Rect $b $ox 47 176 1 $mt2
  for ($x = 8; $x -lt 172; $x += 20) { Rect $b ($ox + $x) 44 10 1 $mt1 }
  $tape = C '#f2d56b'
  # パネル1: 大きなポスターと小さな紙
  Cover $b ($ox + 8) 8 24 31 0 0
  Rect $b ($ox + 10) 7 4 2 $tape; Rect $b ($ox + 26) 7 4 2 $tape
  Cover $b ($ox + 33) 12 9 12 2 1
  Rect $b ($ox + 35) 11 5 2 $tape
  # パネル2・3: ひもに吊るした見本
  foreach ($row in @(@(48, 84, 7, 10, 1), @(92, 128, 9, 12, 2))) {
    $sx0 = $row[0]; $sx1 = $row[1]; $sy = $row[2]
    L $b ($ox + $sx0) $sy ($ox + ($sx0 + $sx1) / 2) ($sy + 3) $mt2
    L $b ($ox + ($sx0 + $sx1) / 2) ($sy + 3) ($ox + $sx1) $sy $mt2
    $cis = @(@(1, 3), @(5, 0), @(2, 4)); if ($row[4] -eq 2) { $cis = @(@(4, 5), @(6, 2), @(0, 1)) }
    for ($i = 0; $i -lt 3; $i++) {
      $cx0 = $sx0 + 2 + $i * 13
      $cyy = $sy + 3 + [int][math]::Round(1.5 * [math]::Sin(($i + 0.5) * 1.05))
      Cover $b ($ox + $cx0) $cyy 11 15 $cis[$i][0] $cis[$i][1]
      Rect $b ($ox + $cx0 + 4) ($cyy - 2) 3 3 $wd1; Px $b ($ox + $cx0 + 5) ($cyy - 1) $wd0
    }
  }
  # パネル4: 大きなポスター、小さな表紙、メモ
  Cover $b ($ox + 148) 8 22 30 3 2
  Rect $b ($ox + 150) 7 4 2 $tape; Rect $b ($ox + 164) 7 4 2 $tape
  Cover $b ($ox + 136) 11 9 12 4 4
  Rect $b ($ox + 138) 10 5 2 $tape
  Rect $b ($ox + 136) 27 11 10 $cr0; Rect $b ($ox + 136) 27 11 1 $cr2
  for ($yy = 29; $yy -le 33; $yy += 2) { Rect $b ($ox + 138) $yy 7 1 $cr3 }
  Rect $b ($ox + 140) 26 3 2 $rd
}

# ====================================================================
# 看板 112x32 x4コマ: 紺の板に金のふち、流れる電球、本の山とえんぴつ、「同人誌」
Sheet 'doujinshi_sign.png' 112 32 4 {
  param($b, $ox, $f)
  Rect $b ($ox + 14) 0 3 7 $wd3; Rect $b ($ox + 95) 0 3 7 $wd3
  Rect $b $ox 6 112 26 $ink
  Rect $b ($ox + 1) 7 110 24 $gl2; Rect $b ($ox + 2) 8 108 22 $gl0; Rect $b ($ox + 3) 9 106 20 $gl1
  Rect $b ($ox + 4) 10 104 18 $nv1; Rect $b ($ox + 4) 10 104 1 $nv0; Rect $b ($ox + 4) 26 104 2 $nv2
  foreach ($p in @(@(0, 6), @(111, 6), @(0, 31), @(111, 31))) { Clear $b ($ox + $p[0]) $p[1] }
  # 電球
  for ($i = 0; $i -lt 13; $i++) {
    $bx = $ox + 6 + $i * 8
    $lit = ((($i + $f) % 4) -lt 2)
    if ($lit) { foreach ($by in @(7, 29)) { Rect $b $bx $by 2 2 (C '#fffbd0'); Px $b $bx $by (C '#ffffff') } }
    else { foreach ($by in @(7, 29)) { Rect $b $bx $by 2 2 (C '#7a5614') } }
  }
  # 本の山（左）
  $cols = @(@(0, 23, 18, 0), @(2, 19, 16, 1), @(3, 15, 14, 0))
  foreach ($bk in $cols) {
    $pl = $cvp[$bk[0]]; $bx2 = $ox + 9 + $bk[3]; $by2 = $bk[1]; $bw = $bk[2]
    Rect $b $bx2 $by2 $bw 4 $cr1; Rect $b $bx2 $by2 $bw 1 $pl[1]; Rect $b $bx2 ($by2 + 3) $bw 1 $pl[3]; Rect $b $bx2 $by2 2 4 $pl[0]; Px $b $bx2 $by2 $pl[1]
  }
  # えんぴつ（右）
  Rect $b ($ox + 84) 19 2 4 $pk; Rect $b ($ox + 86) 19 1 4 $sv1
  Rect $b ($ox + 87) 19 13 4 $yl; Rect $b ($ox + 87) 19 13 1 (C '#fff0a0'); Rect $b ($ox + 87) 22 13 1 (C '#d9a73a')
  Rect $b ($ox + 100) 19 1 4 $cr1; Rect $b ($ox + 101) 20 1 2 $cr1; Px $b ($ox + 102) 20 $ink
  # 文字
  [void](TextPx $b '同人誌' ($ox + 32) 12 16 $nv3 $true)
  [void](TextPx $b '同人誌' ($ox + 31) 11 16 $cr0 $true)
  # きらきら
  $sr = @(2, 1, 0, 1)[$f]
  Star $b ($ox + 96) 14 $sr (C '#fff3a0') (C '#ffffff')
  $sr2 = @(0, 1, 2, 1)[$f]
  Star $b ($ox + 21) 12 $sr2 (C '#fff3a0') (C '#ffffff')
}

# ====================================================================
# 長机 142x31: ラベンダーの布をかけた会議用の机。前に手作りの本の貼り紙、すそはレース
Sheet 'doujinshi_table.png' 152 31 1 {
  param($b, $ox, $f)
  $tw = 150
  $pq = [int](($tw - 66) / 2) + 1
  # 天板（布）
  Rect $b ($ox + 1) 1 $tw 8 $lv1
  Rect $b ($ox + 1) 1 $tw 1 $lv0; Rect $b ($ox + 1) 2 $tw 1 $lv0
  Rect $b ($ox + 1) 8 $tw 1 $lv2
  for ($x = 4; $x -lt $tw; $x += 7) { Px $b ($ox + $x) 4 $lv0; Px $b ($ox + $x + 3) 6 $lv2 }
  # 机の前の縁
  Rect $b ($ox + 1) 9 $tw 1 $lv3
  # 垂れ（前の布）
  Rect $b ($ox + 1) 10 $tw 19 $lv2
  Rect $b ($ox + 1) 10 $tw 1 $lv3
  for ($x = 6; $x -lt $tw; $x += 14) {
    Rect $b ($ox + $x) 10 2 19 $lv1; Rect $b ($ox + $x + 2) 10 1 19 $lv3
  }
  Rect $b ($ox + 1) 10 2 19 $lv1; Rect $b ($ox + $tw - 1) 10 2 19 $lv3
  # 貼り紙
  Rect $b ($ox + $pq) 11 66 14 $cr0; Rect $b ($ox + $pq) 11 66 1 $cr1; Rect $b ($ox + $pq) 24 66 1 $cr2
  Rect $b ($ox + $pq) 11 1 14 $cr1; Rect $b ($ox + $pq + 65) 11 1 14 $cr2
  Cover $b ($ox + $pq + 3) 12 9 12 5 3
  [void](TextPx $b 'てづくり' ($ox + $pq + 15) 12 11 $nv1 $true)
  Rect $b ($ox + $pq - 1) 10 5 2 (C '#f2d56b'); Rect $b ($ox + $pq + 62) 10 5 2 (C '#f2d56b')
  # レースのすそ
  Rect $b ($ox + 1) 25 $tw 2 $cr0
  for ($x = 1; $x -lt $tw; $x += 6) {
    Ellipse $b ($ox + $x + 3) 27 3 2.6 $cr0
    Px $b ($ox + $x + 3) 27 $lv2; Px $b ($ox + $x + 2) 26 $cr1; Px $b ($ox + $x + 4) 26 $cr1
  }
  Rect $b ($ox + 1) 25 $tw 1 $cr1
  # 外のふち
  Px $b ($ox + 1) 1 $clear; Px $b ($ox + $tw) 1 $clear
} $true

# ====================================================================
# 平積みの本 30x24: 3冊重ねて一番上の表紙を見せる
Sheet 'doujinshi_flat.png' 30 24 1 {
  param($b, $ox, $f)
  $sp = @(@(0, 0, 22), @(1, 1, 22), @(3, -1, 22))
  for ($t = 0; $t -lt 3; $t++) {
    $yb = 18 - $t * 3
    $s = $sp[$t]; $pl = $cvp[$s[0]]; $x0 = $ox + 3 + $s[1]
    Rect $b $x0 $yb 22 3 $cr1; Rect $b $x0 ($yb + 2) 22 1 $cr2
    Rect $b $x0 $yb 22 1 $pl[0]; Rect $b $x0 $yb 2 3 $pl[0]; Px $b $x0 $yb $pl[1]
  }
  Cover $b ($ox + 4) 3 20 10 2 4
  Rect $b ($ox + 3) 15 1 3 $cr3
} $true

# ====================================================================
# 新刊のPOP 32x34: 黄色い札に赤い「新刊」、針金の台
Sheet 'doujinshi_pop.png' 32 34 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 15) 20 2 9 $sv2; Rect $b ($ox + 15) 20 1 9 $sv0
  Ellipse $b ($ox + 16) 29 7 2.4 $wd2; Ellipse $b ($ox + 16) 28.6 6 1.8 $wd1
  # 札
  Rect $b ($ox + 2) 2 28 18 $rd
  Rect $b ($ox + 3) 3 26 16 (C '#fff1a8'); Rect $b ($ox + 3) 3 26 1 (C '#ffffff')
  Rect $b ($ox + 3) 17 26 2 (C '#f0d878')
  foreach ($p in @(@(2, 2), @(29, 2), @(2, 19), @(29, 19))) { Px $b ($ox + $p[0]) $p[1] $clear }
  Px $b ($ox + 1) 11 $rd; Px $b ($ox + 30) 11 $rd; Px $b ($ox + 16) 1 $rd; Px $b ($ox + 16) 20 $rd
  [void](TextPx $b '新刊' ($ox + 5) 6 12 $rd $true)
  Star $b ($ox + 5) 5 1 $gl1 $gl0
  Star $b ($ox + 27) 16 1 $gl1 $gl0
} $true

# ====================================================================
# 立てかけた本のスタンド 40x22: 木の台に表紙を見せた3冊
Sheet 'doujinshi_stand.png' 40 22 1 {
  param($b, $ox, $f)
  Cover $b ($ox + 3) 2 11 16 1 0
  Cover $b ($ox + 14) 1 11 17 3 3
  Cover $b ($ox + 26) 2 11 16 5 5
  foreach ($x in @(3, 14, 26)) { Rect $b ($ox + $x) 16 11 3 $wd1; Rect $b ($ox + $x) 16 11 1 $wd0 }
  Rect $b ($ox + 2) 18 36 3 $wd2; Rect $b ($ox + 2) 18 36 1 $wd0; Rect $b ($ox + 2) 20 36 1 $wd3
} $true

# ====================================================================
# めくれる見本誌 22x15 x6コマ
Sheet 'doujinshi_sample.png' 22 15 6 {
  param($b, $ox, $f)
  Rect $b ($ox + 2) 9 18 4 $lv3; Rect $b ($ox + 2) 9 18 1 $lv1; Rect $b ($ox + 2) 12 18 1 $lv4
  Rect $b ($ox + 3) 4 8 6 $cr0; Rect $b ($ox + 11) 4 8 6 $cr0; Rect $b ($ox + 10) 4 1 7 $cr3
  Rect $b ($ox + 3) 9 16 1 $cr2
  foreach ($yy in @(5, 7)) { Rect $b ($ox + 4) $yy 5 1 $cr3 }
  if ($f -eq 0 -or $f -eq 5) { foreach ($yy in @(5, 7)) { Rect $b ($ox + 12) $yy 5 1 $cr3 }; Px $b ($ox + 14) 6 $rd }
  if ($f -ge 1 -and $f -le 4) {
    $th = [math]::PI * $f / 5.0
    for ($a2 = 0; $a2 -le 5; $a2++) {
      $t2 = [math]::Max(0.0, $th - $a2 * 0.1)
      $tx = [int][math]::Round(10 + 8 * [math]::Cos($t2)); $ty = [int][math]::Round(8 - 7 * [math]::Sin($t2))
      L $b ($ox + 10) 8 ($ox + $tx) $ty $(if ($a2 -eq 0) { $cr3 } elseif ($a2 -lt 3) { $cr0 } else { $cr1 })
    }
  }
} $true

# ====================================================================
# スペース番号の札 26x17: 立てた小さな札と、台
Sheet 'doujinshi_plate.png' 26 17 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 2) 2 22 11 $nv1; Rect $b ($ox + 3) 3 20 9 $cr0; Rect $b ($ox + 3) 3 20 1 $cr1
  $tw = TextWidth 'A12' 11
  [void](TextPx $b 'A12' ($ox + [int](13 - $tw / 2)) 3 11 $nv1 $true)
  Rect $b ($ox + 4) 13 18 2 $nv2; Rect $b ($ox + 4) 13 18 1 $nv0
  Star $b ($ox + 22) 4 1 $gl1 $gl0
} $true

# ====================================================================
# ペンとインク 18x17: ペン立てと、インクのびん
Sheet 'doujinshi_pens.png' 18 17 1 {
  param($b, $ox, $f)
  # ペン
  Rect $b ($ox + 3) 1 1 6 $rd; Px $b ($ox + 3) 0 $ink
  Rect $b ($ox + 5) 0 1 8 (C '#2f5fb8'); Px $b ($ox + 5) 0 $sv1
  Rect $b ($ox + 7) 2 1 6 $gn1; Px $b ($ox + 7) 1 $gn0; Px $b ($ox + 8) 1 $gn0
  # カップ
  Rect $b ($ox + 2) 7 8 9 (C '#3a9aa6'); Rect $b ($ox + 2) 7 1 9 (C '#7fd0d6'); Rect $b ($ox + 9) 7 1 9 (C '#256872')
  Rect $b ($ox + 2) 7 8 1 (C '#9fe0e6'); Rect $b ($ox + 3) 11 6 1 (C '#256872')
  # びん
  Rect $b ($ox + 12) 4 3 3 $ink; Rect $b ($ox + 12) 4 3 1 $sv1
  Rect $b ($ox + 11) 8 5 8 $nv1; Rect $b ($ox + 11) 8 1 8 $nv0; Rect $b ($ox + 12) 7 3 1 $nv1
  Rect $b ($ox + 12) 11 3 3 $cr0; Px $b ($ox + 13) 12 $nv1
  Px $b ($ox + 12) 9 (C '#7f93d8')
} $true

# ====================================================================
# きらきら 32x30 x4コマ（新刊POPのまわり）
Sheet 'doujinshi_sparkle.png' 32 30 4 {
  param($b, $ox, $f)
  $pts = @(@(4, 6), @(27, 3), @(14, 14), @(26, 22), @(6, 24))
  for ($i = 0; $i -lt $pts.Count; $i++) {
    $r = @(0, 1, 2, 1)[($i + $f) % 4]
    $c = if ($i % 2 -eq 0) { C '#fff3a0' } else { C '#ffffff' }
    Star $b ($ox + $pts[$i][0]) $pts[$i][1] $r $c (C '#ffffff')
  }
}

# ====================================================================
# 見本誌ラック 42x62: 木の棚に表紙を見せた見本。上に「見本」の札
Sheet 'doujinshi_rack.png' 42 62 1 {
  param($b, $ox, $f)
  # 柱
  Rect $b ($ox + 2) 12 3 48 $wd2; Rect $b ($ox + 2) 12 1 48 $wd0; Rect $b ($ox + 37) 12 3 48 $wd2; Rect $b ($ox + 37) 12 1 48 $wd0; Rect $b ($ox + 39) 12 1 48 $wd3
  # 背板
  Rect $b ($ox + 5) 13 32 46 (C '#f1e6cb'); Rect $b ($ox + 5) 13 32 1 $wd3
  # 3段
  $sets = @(@(@(0, 0), @(5, 3), @(2, 4)), @(@(3, 2), @(1, 1), @(6, 5)), @(@(4, 0), @(0, 3), @(1, 5)))
  for ($r = 0; $r -lt 3; $r++) {
    $y0 = 15 + $r * 15
    for ($i = 0; $i -lt 3; $i++) { Cover $b ($ox + 7 + $i * 10) $y0 9 12 $sets[$r][$i][0] $sets[$r][$i][1] }
    Rect $b ($ox + 5) ($y0 + 11) 32 3 $wd1; Rect $b ($ox + 5) ($y0 + 11) 32 1 $wd0; Rect $b ($ox + 5) ($y0 + 13) 32 1 $wd3
  }
  # 見本の札
  Rect $b ($ox + 3) 1 36 11 $nv1; Rect $b ($ox + 3) 1 36 1 $nv0; Rect $b ($ox + 3) 11 36 1 $nv2
  Frame $b ($ox + 3) 1 36 11 $gl1
  $tw = TextWidth '見本' 11
  [void](TextPx $b '見本' ($ox + [int](21 - ($tw + 1) / 2)) 1 11 $cr0 $true)
  # 足
  Rect $b ($ox + 0) 59 7 2 $wd3; Rect $b ($ox + 35) 59 7 2 $wd3
} $true

# ====================================================================
# パイプ椅子 20x28
Sheet 'doujinshi_chair.png' 20 28 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 4) 10 2 7 $sv1; Rect $b ($ox + 14) 10 2 7 $sv1
  Rect $b ($ox + 3) 1 14 9 (C '#8fa0c8'); Rect $b ($ox + 3) 1 14 1 (C '#bcc9ea'); Rect $b ($ox + 3) 9 14 1 (C '#6d7eaa')
  Rect $b ($ox + 2) 15 16 4 (C '#8fa0c8'); Rect $b ($ox + 2) 15 16 1 (C '#bcc9ea'); Rect $b ($ox + 2) 18 16 1 (C '#6d7eaa')
  Rect $b ($ox + 3) 19 2 7 $sv1; Rect $b ($ox + 15) 19 2 7 $sv1
  Rect $b ($ox + 3) 19 1 7 $sv0; Rect $b ($ox + 15) 19 1 7 $sv0
  Rect $b ($ox + 5) 23 10 1 $sv2
  Rect $b ($ox + 2) 26 4 1 $ink; Rect $b ($ox + 14) 26 4 1 $ink
} $true

# ====================================================================
# 段ボール箱 38x36: 下に大きな箱、上に口の開いた箱（本の背と「ほん」の札）
Sheet 'doujinshi_boxes.png' 38 36 1 {
  param($b, $ox, $f)
  # 下の箱
  Rect $b ($ox + 2) 19 34 16 $kr0; Rect $b ($ox + 2) 19 34 1 (C '#f0d6a2'); Rect $b ($ox + 2) 34 34 1 $kr2
  Rect $b ($ox + 34) 20 2 15 $kr1
  Rect $b ($ox + 15) 19 7 16 (C '#ecdcb4'); Rect $b ($ox + 15) 19 1 16 $cr3
  Rect $b ($ox + 4) 24 9 8 $cr0; Rect $b ($ox + 4) 24 9 1 $cr1
  Cover $b ($ox + 5) 25 5 6 6 0
  Rect $b ($ox + 30) 28 4 1 $kr2
  # 上の箱の中の本
  $bx = @(@(9, 0), @(14, 2), @(19, 3), @(24, 5))
  foreach ($q in $bx) { $pl = $cvp[$q[1]]; Rect $b ($ox + $q[0]) 2 5 8 $cr1; Rect $b ($ox + $q[0]) 2 5 2 $pl[0]; Rect $b ($ox + $q[0]) 2 1 8 $pl[1] }
  # 上の箱
  Rect $b ($ox + 6) 9 26 11 $kr0; Rect $b ($ox + 6) 9 26 2 $kr1; Rect $b ($ox + 6) 9 26 1 (C '#f0d6a2'); Rect $b ($ox + 6) 19 26 1 $kr2
  Rect $b ($ox + 31) 10 1 9 $kr1
  Rect $b ($ox + 9) 11 20 7 $cr0
  [void](TextPx $b 'ほん' ($ox + 8) 7 11 $kr3 $true)
} $true

# ====================================================================
# 袋詰めの本 20x24: 紙袋に本が2冊のぞく
Sheet 'doujinshi_bag.png' 20 24 1 {
  param($b, $ox, $f)
  $pa = $cvp[1]; $pb = $cvp[5]
  Rect $b ($ox + 4) 1 5 11 $pa[0]; Rect $b ($ox + 4) 1 1 11 $pa[1]; Rect $b ($ox + 4) 1 5 1 $pa[2]
  Rect $b ($ox + 10) 4 5 8 $pb[0]; Rect $b ($ox + 10) 4 1 8 $pb[1]; Rect $b ($ox + 10) 4 5 1 $pb[2]
  Rect $b ($ox + 2) 9 16 14 $kr0; Rect $b ($ox + 2) 9 16 2 $kr1; Rect $b ($ox + 2) 9 16 1 (C '#f0d6a2')
  Rect $b ($ox + 15) 11 2 12 $kr1; Rect $b ($ox + 2) 22 16 1 $kr2
  # ひも
  L $b ($ox + 6) 9 ($ox + 8) 5 $wd2; L $b ($ox + 13) 9 ($ox + 12) 5 $wd2
  # ハートのシール
  Px $b ($ox + 6) 14 $rd; Px $b ($ox + 8) 14 $rd; Rect $b ($ox + 6) 15 3 1 $rd; Px $b ($ox + 7) 16 $rd
  Rect $b ($ox + 10) 15 4 1 $cr0; Rect $b ($ox + 10) 17 4 1 $cr0
} $true

# ====================================================================
# のぼり 18x80（2種）
function Nobori($name, $chars, $flag, $flag0, $flag2, $tx) {
  Sheet $name 18 80 1 {
    param($b, $ox, $f)
    Rect $b ($ox + 1) 0 2 80 $wd3; Rect $b ($ox + 1) 0 1 80 $wd1
    Rect $b ($ox + 0) 0 18 3 $ink; Rect $b ($ox + 1) 0 16 2 $wd2; Rect $b ($ox + 1) 0 16 1 $wd1; Rect $b ($ox + 16) 0 2 4 $gl2; Px $b ($ox + 17) 0 $gl0
    Rect $b ($ox + 3) 3 14 72 $ink
    Rect $b ($ox + 4) 4 12 70 $flag
    Rect $b ($ox + 4) 4 12 1 $flag0; Rect $b ($ox + 4) 4 1 70 $flag0; Rect $b ($ox + 15) 4 1 70 $flag2
    Rect $b ($ox + 5) 5 10 1 $gl1; Rect $b ($ox + 5) 68 10 1 $gl1
    for ($y = 69; $y -le 74; $y++) { $d = $y - 68; Rect $b ($ox + 10 - $d) $y (2 * $d) 1 $clear }
    $ys = 8
    foreach ($ch in $chars) { [void](TextPx $b $ch ($ox + 4) $ys 11 $tx $true); $ys += 12 }
  }
}
Nobori 'doujinshi_nobori_a.png' @('同', '人', '誌') (C '#2f3f85') (C '#4a5fb0') (C '#1d2a5e') $cr0
Nobori 'doujinshi_nobori_b.png' @('新', '刊', 'あ', 'り') (C '#e0605a') (C '#f58a7e') (C '#a8382f') $cr0

# ====================================================================
# 立て看板 36x46: 黒板（チョークで「ほん」と本の絵）
Sheet 'doujinshi_easel.png' 36 46 1 {
  param($b, $ox, $f)
  Rect $b ($ox + 5) 33 2 11 $wd3; Rect $b ($ox + 29) 33 2 11 $wd3; Rect $b ($ox + 5) 33 1 11 $wd1; Rect $b ($ox + 29) 33 1 11 $wd1
  Rect $b ($ox + 3) 1 30 31 $wd2; Rect $b ($ox + 3) 1 30 1 $wd0; Rect $b ($ox + 3) 32 30 1 $wd3
  Rect $b ($ox + 5) 3 26 26 (C '#2f5a48'); Rect $b ($ox + 5) 3 26 1 (C '#254a3a'); Rect $b ($ox + 5) 3 1 26 (C '#254a3a')
  Rect $b ($ox + 3) 30 30 3 $wd1; Rect $b ($ox + 3) 30 30 1 $wd0; Rect $b ($ox + 3) 32 30 1 $wd3
  Rect $b ($ox + 24) 29 4 1 $cr0
  $tw = TextWidth 'ほん' 12
  [void](TextPx $b 'ほん' ($ox + [int](18 - ($tw + 1) / 2)) 5 12 $cr0 $true)
  # 本の絵
  $ch = C '#d8e8dc'
  Rect $b ($ox + 9) 20 7 5 $ch; Rect $b ($ox + 17) 20 7 5 $ch; Rect $b ($ox + 16) 20 1 6 (C '#2f5a48')
  Rect $b ($ox + 10) 22 5 1 (C '#2f5a48'); Rect $b ($ox + 18) 22 5 1 (C '#2f5a48')
  Rect $b ($ox + 9) 25 15 1 $ch
  Star $b ($ox + 11) 18 1 $gl0 $cr0
  Star $b ($ox + 26) 20 1 (C '#f6a0c0') $cr0
  Px $b ($ox + 21) 17 $yl
} $true
