# 横断幕の元絵（利用者が用意した絵）を、ドット絵風の小さな絵に縮める第1段階。
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/gen-banner.ps1 [元絵のパス] [出力PNG] [幅px]
# 元絵は reference/amp-banner-src.jpg に置く（公開リポジトリには入れない）。
# 第2段階 scripts/gen-banner.mjs が、色数を減らして縁取りを付け、client/public/brand/banner/amp_banner.png を作る。
# $OutH: 出力の高さ。横断幕の大きさ（map.json の定義）を変えないため、元絵の比率とは少しずれても、この高さに合わせる
param(
  [string]$Src = 'reference/amp-banner-src.jpg',
  [string]$Out = 'reference/amp-banner-small.png',
  [int]$W = 560,
  [int]$OutH = 101
)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile((Resolve-Path $Src))
# 元絵の黒い枠線の内側（2000x482 の元絵の中の絵の部分。2026-10-31 に差し替えた新しい絵）
$cx = 28; $cy = 46; $cw = 1933; $ch = 361
$H = $OutH
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, $W, $H), $cx, $cy, $cw, $ch, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose(); $img.Dispose()
$dir = Split-Path $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$bmp.Save((Join-Path (Get-Location) $Out), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "wrote $Out (${W}x${H})"
