# Load progress bar function
. "$PSScriptRoot\progressbar.ps1"

# Set download URL and output
$url = "https://update.code.visualstudio.com/latest/win32-x64/stable"
$outputFile = Join-Path -Path (Get-Location) -ChildPath "VSCodeSetup-x64.exe"

Write-Host "Downloading the latest Visual Studio Code installer..."
Write-Host ""

# Prepare download (get totalBytes before checking file)
$request = [System.Net.HttpWebRequest]::Create($url)
$request.UserAgent = "Mozilla/5.0"
$response = $request.GetResponse()
$totalBytes = $response.ContentLength
$totalMB = [math]::Round($totalBytes / 1MB, 2)

# Check if file exists and is not corrupted/incomplete
$skipDownload = $false
if (Test-Path $outputFile) {
    $existingSize = (Get-Item $outputFile).Length
    if ($existingSize -eq $totalBytes -and $totalBytes -gt 0) {
        Write-Host "File already downloaded and complete. Skipping download."
        $skipDownload = $true
    } elseif ($existingSize -gt 0) {
        Write-Host "File exists but is incomplete or corrupted. Re-downloading."
    }
}

if (-not $skipDownload) {
    $stream = $response.GetResponseStream()
    # File and buffer
    $output = [System.IO.File]::Create($outputFile)
    $buffer = New-Object byte[] 8192
    $totalRead = 0

    # Bar setup
    $barWidth = 40
    $foodArray = @()
    for ($i = 0; $i -lt $barWidth; $i++) {
        $foodArray += if ($i % 2 -eq 0) { "o" } else { " " }
    }
    $pacman = New-Object -TypeName PSObject -Property @{ Value = "C" }
    $lastEaten = New-Object -TypeName PSObject -Property @{ Value = -1 }

    # Download loop
    while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $output.Write($buffer, 0, $read)
        $totalRead += $read

        Show-DownloadProgressBar `
            -TotalBytes $totalBytes `
            -BytesRead $totalRead `
            -BarWidth $barWidth `
            -PacmanState ([ref]$pacman) `
            -LastEaten ([ref]$lastEaten) `
            -FoodArray $foodArray `
            -TotalMB $totalMB
    }

    # Finalize
    $output.Close()
    $stream.Close()
    $response.Close()

    Write-Host "`n Download complete! File saved to: $outputFile"
} else {
    $response.Close()
}

# Run the downloaded file and wait for it to finish
Start-Process $outputFile -Wait -NoNewWindow

Write-Host "`nVisual Studio Code installer has been downloaded and is now running."