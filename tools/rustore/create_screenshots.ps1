Add-Type -AssemblyName System.Drawing

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$outputDirectory = Join-Path $PSScriptRoot 'screenshots'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$targetWidth = 1080
$targetHeight = 1920
$screens = @(
    @{ Source = 'doc\game.jpg'; Output = '01_game.jpg'; Top = 52; Bottom = 1238 },
    @{ Source = 'doc\gmain.jpg'; Output = '02_home.jpg'; Top = 52; Bottom = 1238 },
    @{ Source = 'doc\stat.jpg'; Output = '03_settings.jpg'; Top = 52; Bottom = 1238 },
    @{ Source = 'doc\load.png'; Output = '04_splash.jpg'; Top = 0; Bottom = 1672 }
)

$jpegEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq 'image/jpeg' } |
    Select-Object -First 1
$encoderParameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
$encoderParameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new(
    [System.Drawing.Imaging.Encoder]::Quality, [long]92
)

foreach ($screen in $screens) {
    $sourcePath = Join-Path $projectRoot $screen.Source
    $outputPath = Join-Path $outputDirectory $screen.Output
    $source = [System.Drawing.Image]::FromFile($sourcePath)
    $canvas = [System.Drawing.Bitmap]::new(
        $targetWidth, $targetHeight,
        [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    try {
        $graphics.Clear([System.Drawing.Color]::FromArgb(7, 19, 49))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

        $crop = [System.Drawing.Rectangle]::new(
            0, $screen.Top, $source.Width, $screen.Bottom - $screen.Top
        )
        $scaledWidth = [int][Math]::Round($crop.Width * $targetHeight / $crop.Height)
        if ($scaledWidth -ge $targetWidth) {
            $graphics.DrawImage(
                $source,
                [System.Drawing.Rectangle]::new(0, 0, $targetWidth, $targetHeight),
                $crop,
                [System.Drawing.GraphicsUnit]::Pixel
            )
        } else {
            $left = [int][Math]::Floor(($targetWidth - $scaledWidth) / 2)
            $graphics.DrawImage(
                $source,
                [System.Drawing.Rectangle]::new($left, 0, $scaledWidth, $targetHeight),
                $crop,
                [System.Drawing.GraphicsUnit]::Pixel
            )
        }
        $canvas.Save($outputPath, $jpegEncoder, $encoderParameters)
        $bytes = (Get-Item -LiteralPath $outputPath).Length
        if ($bytes -gt 3MB) {
            throw "$outputPath exceeds the RuStore 3 MB limit"
        }
        Write-Output "$($screen.Output): ${targetWidth}x${targetHeight}, $([Math]::Round($bytes / 1MB, 2)) MB"
    } finally {
        $graphics.Dispose()
        $canvas.Dispose()
        $source.Dispose()
    }
}

$encoderParameters.Dispose()
