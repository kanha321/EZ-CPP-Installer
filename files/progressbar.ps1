function Show-DownloadProgressBar {
    param (
        [int]$TotalBytes,
        [int]$BytesRead,
        [int]$BarWidth = 40,
        [ref]$PacmanState,
        [ref]$LastEaten,
        [object[]]$FoodArray,
        [double]$TotalMB
    )

    # Calculate percentage
    $percent = if ($TotalBytes -eq 0) { 0 } else { ($BytesRead / $TotalBytes) * 100 }
    $percentDisplay = "{0,6:N1}%" -f $percent

    # Calculate downloaded MB
    $downloadedMB = if ($TotalBytes -eq 0) { 0 } else { $BytesRead / 1MB }

    # Calculate padding width based on total size
    $totalStrRaw = "{0:N2}" -f $TotalMB
    $padWidth = $totalStrRaw.Length

    # Format downloaded and total strings with 2 character padding
    $downloadedStr = "{0,6:N2} MB" -f $downloadedMB  # 6 = 4 for number, 2 for padding
    $totalStr = "$totalStrRaw MB"

    # Determine how much of the bar is eaten
    $eaten = [int](($percent / 100) * $BarWidth)

    # Determine Pac-Man mouth direction
    if ($eaten -lt $BarWidth -and $eaten -ge 0) {
        $nextChar = $FoodArray[$eaten]
        $PacmanState.Value = if ($nextChar -eq " ") { "C" } else { "c" }
    }

    # Build the progress bar
    if ($eaten -ge $BarWidth) {
        $barContents = "-" * $BarWidth
    }
    else {
        $trail = "-" * $eaten

        # Ensure index range is valid
        if (($eaten + 1) -le ($FoodArray.Length - 1)) {
            $remainingFood = $FoodArray[($eaten + 1)..($FoodArray.Length - 1)] -join ""
        } else {
            $remainingFood = ""
        }

        $barContents = "$trail$($PacmanState.Value)$remainingFood".TrimEnd().PadRight($BarWidth)
    }

    $bar = "[$barContents]"
    Write-Host -NoNewline "`r$bar$percentDisplay - $downloadedStr / $totalStr"
}
