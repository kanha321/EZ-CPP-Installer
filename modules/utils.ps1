<#
.SYNOPSIS
    Utility functions for EZ C/C++ Installer.
.DESCRIPTION
    Provides colored output helpers, Pac-Man download progress bar,
    and 7za.exe management (download / cleanup).
#>

# ── Logging & Output Helpers ─────────────────────────────────────────────────

# Expected to be set by the caller (install.ps1 or uninstall.ps1). Defaults to install log.
if (-not $global:EzLogFile) { $global:EzLogFile = Join-Path $PWD "ez-cpp-install.log" }

function Write-Log {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $global:EzLogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Write-Step { param([string]$msg) Write-Host "  [*] $msg" -ForegroundColor Cyan; Write-Log "INFO" $msg }
function Write-Ok { param([string]$msg) Write-Host "  [✓] $msg" -ForegroundColor Green; Write-Log "INFO" $msg }
function Write-Warn { param([string]$msg) Write-Host "  [!] $msg" -ForegroundColor Yellow; Write-Log "WARN" $msg }
function Write-Err { param([string]$msg) Write-Host "  [✗] $msg" -ForegroundColor Red; Write-Log "ERROR" $msg }
function Write-Info { param([string]$msg) Write-Host "      $msg" -ForegroundColor DarkGray; Write-Log "DEBUG" $msg }

# ── 7za.exe Management ──────────────────────────────────────────────────────
# Downloads the standalone 7-Zip console extractor if not already present.

$script:SevenZaPath = $null

function Get-7zaPath {
    <#
    .SYNOPSIS
        Returns the path to 7za.exe, downloading it if necessary.
    .OUTPUTS
        String - absolute path to 7za.exe
    #>
    if ($script:SevenZaPath -and (Test-Path $script:SevenZaPath)) {
        return $script:SevenZaPath
    }

    $tempDir = Join-Path $env:TEMP "ez-cpp-installer"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    $sevenZaExe = Join-Path $tempDir "7za.exe"

    if (Test-Path $sevenZaExe) {
        $script:SevenZaPath = $sevenZaExe
        return $sevenZaExe
    }

    Write-Info "Downloading 7za.exe..."
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $script:SevenZaUrl -OutFile $sevenZaExe -UseBasicParsing
        $ProgressPreference = 'Continue'
    }
    catch {
        Write-Err "Failed to download 7za.exe: $_"
        return $null
    }

    $script:SevenZaPath = $sevenZaExe
    return $sevenZaExe
}

function Remove-7za {
    <#
    .SYNOPSIS
        Cleans up the temporary 7za.exe and its directory.
    #>
    $tempDir = Join-Path $env:TEMP "ez-cpp-installer"
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    $script:SevenZaPath = $null
}

function Invoke-WithBounceProgress {
    <#
    .SYNOPSIS
        Executes a background process and displays a dancing bouncing line animation.
    #>
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList
    )

    $tempOut = Join-Path $env:TEMP "ez-cmd-out.log"
    $tempErr = Join-Path $env:TEMP "ez-cmd-err.log"

    $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden -RedirectStandardOutput $tempOut -RedirectStandardError $tempErr

    $width = 25
    $pos = 0
    $dir = 1

    while (-not $proc.HasExited) {
        $arr = [char[]]("_" * $width)
        $arr[$pos] = "-"
        $frame = $arr -join ""
        
        Write-Host -NoNewline "`r  [*] $Message [$frame]"
        
        $pos += $dir
        if ($pos -ge $width - 1) { $dir = -1 }
        elseif ($pos -le 0) { $dir = 1 }
        
        Start-Sleep -Milliseconds 40
    }

    $spaces = " " * ($Message.Length + $width + 15)
    Write-Host -NoNewline "`r$spaces`r"

    if ($proc.ExitCode -eq 0) {
        return $true
    }
    else {
        if (Test-Path $tempErr) {
            $errText = (Get-Content $tempErr -Raw).Trim()
            if ($errText) { Write-Warn "Process output: $errText" }
        }
        return $false
    }
}

function Expand-7zArchive {
    <#
    .SYNOPSIS
        Extracts a .7z archive using 7za.exe.
    .PARAMETER ArchivePath
        Path to the .7z file.
    .PARAMETER DestinationPath
        Directory to extract into.
    .OUTPUTS
        Boolean - $true if successful, $false otherwise.
    #>
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][string]$DestinationPath
    )

    $sevenZa = Get-7zaPath
    if (-not $sevenZa) {
        Write-Err "7za.exe is not available. Cannot extract archive."
        return $false
    }

    try {
        $argsArray = @("x", "`"$ArchivePath`"", "-o`"$DestinationPath`"", "-y")
        $success = Invoke-WithBounceProgress -Message "Extracting archive" -FilePath $sevenZa -ArgumentList $argsArray
        if (-not $success) {
            Write-Err "Extraction failed"
            return $false
        }
        return $true
    }
    catch {
        Write-Err "Extraction error: $_"
        return $false
    }
}

# ── Pac-Man Download Progress Bar ────────────────────────────────────────────

function Show-PacmanProgress {
    <#
    .SYNOPSIS
        Renders a Pac-Man style progress bar on the current console line.
    .PARAMETER TotalBytes
        Total file size in bytes.
    .PARAMETER BytesRead
        Bytes downloaded so far.
    .PARAMETER BarWidth
        Width of the progress bar in characters.
    .PARAMETER PacmanState
        [ref] object tracking Pac-Man mouth state (open/closed).
    .PARAMETER FoodArray
        Array of characters representing the food dots.
    .PARAMETER TotalMB
        Pre-calculated total size in MB (for display).
    #>
    param(
        [long]$TotalBytes,
        [long]$BytesRead,
        [int]$BarWidth = 40,
        [ref]$PacmanState,
        [object[]]$FoodArray,
        [double]$TotalMB
    )

    $percent = if ($TotalBytes -eq 0) { 0 } else { ($BytesRead / $TotalBytes) * 100 }
    $percentDisplay = "{0,6:N1}%" -f $percent

    $downloadedMB = if ($TotalBytes -eq 0) { 0 } else { $BytesRead / 1MB }
    $downloadedStr = "{0,6:N2} MB" -f $downloadedMB
    $totalStr = "{0:N2} MB" -f $TotalMB

    $eaten = [int](($percent / 100) * $BarWidth)

    # Pac-Man mouth animation
    if ($eaten -lt $BarWidth -and $eaten -ge 0) {
        $nextChar = $FoodArray[$eaten]
        $PacmanState.Value = if ($nextChar -eq " ") { "C" } else { "c" }
    }

    # Build the bar
    if ($eaten -ge $BarWidth) {
        $barContents = "-" * $BarWidth
    }
    else {
        $trail = "-" * $eaten
        if (($eaten + 1) -le ($FoodArray.Length - 1)) {
            $remainingFood = $FoodArray[($eaten + 1)..($FoodArray.Length - 1)] -join ""
        }
        else {
            $remainingFood = ""
        }
        $barContents = "$trail$($PacmanState.Value)$remainingFood".TrimEnd().PadRight($BarWidth)
    }

    $bar = "      [$barContents]"
    Write-Host -NoNewline "`r$bar $percentDisplay - $downloadedStr / $totalStr"
}

function Invoke-DownloadWithProgress {
    <#
    .SYNOPSIS
        Downloads a file with a Pac-Man progress bar.
    .PARAMETER Url
        URL to download from.
    .PARAMETER OutputPath
        Local file path to save to.
    .OUTPUTS
        Boolean - $true if successful, $false otherwise.
    #>
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$OutputPath
    )

    try {
        $request = [System.Net.HttpWebRequest]::Create($Url)
        $request.UserAgent = "Mozilla/5.0"
        $response = $request.GetResponse()
        $totalBytes = $response.ContentLength
        $totalMB = [math]::Round($totalBytes / 1MB, 2)

        # Check if file already exists and is complete
        if (Test-Path $OutputPath) {
            $existingSize = (Get-Item $OutputPath).Length
            if ($existingSize -eq $totalBytes -and $totalBytes -gt 0) {
                Write-Info "File already downloaded and complete. Skipping."
                $response.Close()
                return $true
            }
        }

        $stream = $response.GetResponseStream()
        $output = [System.IO.File]::Create($OutputPath)
        $buffer = New-Object byte[] 8192
        $totalRead = [long]0

        # Setup Pac-Man bar
        $barWidth = 40
        $foodArray = @()
        for ($i = 0; $i -lt $barWidth; $i++) {
            $foodArray += if ($i % 2 -eq 0) { "o" } else { " " }
        }
        $pacman = [PSCustomObject]@{ Value = "C" }

        # Download loop
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $output.Write($buffer, 0, $read)
            $totalRead += $read

            Show-PacmanProgress `
                -TotalBytes $totalBytes `
                -BytesRead $totalRead `
                -BarWidth $barWidth `
                -PacmanState ([ref]$pacman) `
                -FoodArray $foodArray `
                -TotalMB $totalMB
        }

        $output.Close()
        $stream.Close()
        $response.Close()

        Write-Host ""  # newline after progress bar
        return $true

    }
    catch {
        Write-Err "Download failed: $_"
        return $false
    }
}

# ── Refresh Session PATH ─────────────────────────────────────────────────────

function Update-SessionPath {
    <#
    .SYNOPSIS
        Refreshes the current session's PATH from the registry
        so newly installed tools are immediately available.
    #>
    $machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $env:Path = "$machinePath;$userPath"
}
