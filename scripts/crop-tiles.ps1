# タイルセットの矩形領域を拡大し、行列番号とタイルIDを重ねた画像を出力する（タイル選定用）
# 使い方: powershell -File scripts\crop-tiles.ps1 -Col 0 -Row 0 -Cols 12 -Rows 8 -Scale 6 -Out reference\crop.png
param(
  [int]$Col = 0, [int]$Row = 0, [int]$Cols = 12, [int]$Rows = 8, [int]$Scale = 6,
  [string]$Out = "reference\crop.png",
  [string]$SrcPath = "client\public\assets\tilesets\sunnyside_16.png"
)
Add-Type -AssemblyName System.Drawing
$T = 16
$img = [System.Drawing.Image]::FromFile((Resolve-Path $SrcPath))
$pad = 22
$w = $Cols * $T * $Scale + $pad
$h = $Rows * $T * $Scale + $pad
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(40, 40, 52))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$dest = New-Object System.Drawing.Rectangle $pad, $pad, ($Cols * $T * $Scale), ($Rows * $T * $Scale)
$srcRect = New-Object System.Drawing.Rectangle ($Col * $T), ($Row * $T), ($Cols * $T), ($Rows * $T)
$g.DrawImage($img, $dest, $srcRect.X, $srcRect.Y, $srcRect.Width, $srcRect.Height, [System.Drawing.GraphicsUnit]::Pixel)
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, 255, 255, 255))
$font = New-Object System.Drawing.Font "Consolas", 8
$brush = [System.Drawing.Brushes]::Yellow
for ($c = 0; $c -le $Cols; $c++) { $x = $pad + $c * $T * $Scale; $g.DrawLine($pen, $x, $pad, $x, $h) ; if ($c -lt $Cols) { $g.DrawString(($Col + $c), $font, $brush, $x + 2, 4) } }
for ($r = 0; $r -le $Rows; $r++) { $y = $pad + $r * $T * $Scale; $g.DrawLine($pen, $pad, $y, $w, $y); if ($r -lt $Rows) { $g.DrawString(($Row + $r), $font, $brush, 0, $y + 2) } }
$bmp.Save((Join-Path (Get-Location) $Out), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $img.Dispose()
