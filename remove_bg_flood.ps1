Add-Type -AssemblyName System.Drawing

$assets = @(
    "capybara_front",
    "bunny_front",
    "puppy_front",
    "kitty_front"
)

$assetsDir = "C:\Users\agamr\.gemini\antigravity\scratch\couple_app\assets"

foreach ($asset in $assets) {
    $inPath = Join-Path $assetsDir "$asset.jpg"
    $outPath = Join-Path $assetsDir "$asset.png"
    
    if (Test-Path $inPath) {
        Write-Host "Processing $asset"
        $bmp = [System.Drawing.Bitmap]::FromFile($inPath)
        $w = $bmp.Width
        $h = $bmp.Height
        
        $transparentBmp = New-Object System.Drawing.Bitmap($w, $h)
        
        # Copy pixels
        for ($y = 0; $y -lt $h; $y++) {
            for ($x = 0; $x -lt $w; $x++) {
                $transparentBmp.SetPixel($x, $y, $bmp.GetPixel($x, $y))
            }
        }
        
        $visited = New-Object 'bool[,]' $w, $h
        $queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
        
        $queue.Enqueue((New-Object System.Drawing.Point(0, 0)))
        $queue.Enqueue((New-Object System.Drawing.Point($w - 1, 0)))
        $queue.Enqueue((New-Object System.Drawing.Point(0, $h - 1)))
        $queue.Enqueue((New-Object System.Drawing.Point($w - 1, $h - 1)))
        
        while ($queue.Count -gt 0) {
            $p = $queue.Dequeue()
            $x = $p.X
            $y = $p.Y
            
            if ($x -lt 0 -or $x -ge $w -or $y -lt 0 -or $y -ge $h) { continue }
            if ($visited[$x, $y]) { continue }
            
            $color = $transparentBmp.GetPixel($x, $y)
            $r = $color.R
            $g = $color.G
            $b = $color.B
            
            $isBg = $false
            $dist = (255 - $r)*(255 - $r) + (255 - $g)*(255 - $g) + (255 - $b)*(255 - $b)
            
            if ($dist -lt 5000) { $isBg = $true }
            # Soft shadow edge handling
            if ($dist -lt 15000 -and ($x -lt 20 -or $x -gt $w - 20 -or $y -lt 20 -or $y -gt $h - 20)) { $isBg = $true }
            
            if ($isBg) {
                $visited[$x, $y] = $true
                $transparentBmp.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                
                $queue.Enqueue((New-Object System.Drawing.Point(($x - 1), $y)))
                $queue.Enqueue((New-Object System.Drawing.Point(($x + 1), $y)))
                $queue.Enqueue((New-Object System.Drawing.Point($x, ($y - 1))))
                $queue.Enqueue((New-Object System.Drawing.Point($x, ($y + 1))))
            }
        }
        
        # Second pass to clean up isolated bright pixels
        for ($y = 0; $y -lt $h; $y++) {
            for ($x = 0; $x -lt $w; $x++) {
                $c = $transparentBmp.GetPixel($x, $y)
                if ($c.A -gt 0) {
                    $d = (255 - $c.R)*(255 - $c.R) + (255 - $c.G)*(255 - $c.G) + (255 - $c.B)*(255 - $c.B)
                    if ($d -lt 1000) {
                        $transparentBmp.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                    }
                }
            }
        }
        
        $transparentBmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        $transparentBmp.Dispose()
        Write-Host "Done $asset"
    }
}
