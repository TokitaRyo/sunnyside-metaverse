# ドット絵(PNG)を描くための小さな道具。scripts/stalls/*.ps1 から読み込んで使う:
#   . "$PSScriptRoot\..\lib\pixel.ps1"
# リポジトリのルートで実行すること（出力先が相対パスのため）。このファイルは UTF-8 BOM 付きで保存すること（日本語が文字化けしないように）。
Add-Type -AssemblyName System.Drawing
if (-not $script:OutDir) { $script:OutDir = "client/public/brand/stall" }
New-Item -ItemType Directory -Force $script:OutDir | Out-Null

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
# 線（1px）
function Line($b, $x0, $y0, $x1, $y1, $col) {
  $dx = [math]::Abs($x1 - $x0); $dy = -[math]::Abs($y1 - $y0)
  $sx = if ($x0 -lt $x1) { 1 } else { -1 }; $sy = if ($y0 -lt $y1) { 1 } else { -1 }
  $err = $dx + $dy
  while ($true) {
    Px $b $x0 $y0 $col
    if ($x0 -eq $x1 -and $y0 -eq $y1) { break }
    $e2 = 2 * $err
    if ($e2 -ge $dy) { $err += $dy; $x0 += $sx }
    if ($e2 -le $dx) { $err += $dx; $y0 += $sy }
  }
}
function Clear($b, $x, $y) { Px $b $x $y ([System.Drawing.Color]::FromArgb(0, 0, 0, 0)) }

# ASCIIアートで描く: 行の配列と、文字→色の連想配列。'.' と ' ' は透明
#   Ascii $b 0 0 @('.rr.', 'rRRr') @{ r = (C '#d62f3a'); R = (C '#9d1d2c') }
function Ascii($b, $x, $y, $rows, $pal) {
  for ($j = 0; $j -lt $rows.Count; $j++) {
    $row = $rows[$j]
    for ($i = 0; $i -lt $row.Length; $i++) {
      $ch = [string]$row[$i]
      if ($ch -ne '.' -and $ch -ne ' ' -and $pal.ContainsKey($ch)) { Px $b ($x + $i) ($y + $j) $pal[$ch] }
    }
  }
}

# 日本語の文字をドットで貼る。MS Gothic をアンチエイリアス無し(1bit)で描く。$bold なら横にずらして2回描いて太くする。幅(px)を返す
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
function Save($b, $name) { $b.Save((Join-Path (Resolve-Path $script:OutDir) $name), [System.Drawing.Imaging.ImageFormat]::Png); Write-Host "wrote $($script:OutDir)/$name ($($b.Width)x$($b.Height))"; $b.Dispose() }

# 素材パックの木・赤・金に寄せた共通色（使っても使わなくてもよい）
$ol = C '#4a2420'; $w1 = C '#eab382'; $w2 = C '#c97f4f'; $w3 = C '#8c4a32'
$red = C '#d62f3a'; $red2 = C '#9d1d2c'; $red3 = C '#f25b5b'
$white = C '#f6f3ee'; $cream = C '#e9dcc0'; $gold = C '#f2b544'
$iron0 = C '#1f1f27'; $iron1 = C '#2e2e38'; $iron2 = C '#4b4b58'; $iron3 = C '#6a6a78'
