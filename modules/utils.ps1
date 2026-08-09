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

function Write-Step {
    param([string]$msg)
    $time = Get-Date -Format "HH:mm:ss"
    if ($global:EzVerbose) { Write-Host "  [*] [$time] $msg" -ForegroundColor Cyan } else { Write-Host "  [*] $msg" -ForegroundColor Cyan }
    Write-Log "STEP" $msg
}
function Write-Ok {
    param([string]$msg)
    $time = Get-Date -Format "HH:mm:ss"
    if ($global:EzVerbose) { Write-Host "  [+] [$time] $msg" -ForegroundColor Green } else { Write-Host "  [+] $msg" -ForegroundColor Green }
    Write-Log "SUCCESS" $msg
}
function Write-Warn {
    param([string]$msg)
    $time = Get-Date -Format "HH:mm:ss"
    if ($global:EzVerbose) { Write-Host "  [!] [$time] $msg" -ForegroundColor Yellow } else { Write-Host "  [!] $msg" -ForegroundColor Yellow }
    Write-Log "WARN" $msg
}
function Write-Err {
    param([string]$msg)
    $time = Get-Date -Format "HH:mm:ss"
    if ($global:EzVerbose) { Write-Host "  [-] [$time] $msg" -ForegroundColor Red } else { Write-Host "  [-] $msg" -ForegroundColor Red }
    Write-Log "ERROR" $msg
}
function Write-Info {
    param([string]$msg)
    $time = Get-Date -Format "HH:mm:ss"
    if ($global:EzVerbose -or $VerbosePreference -eq 'Continue') {
        Write-Host "      [$time] $msg" -ForegroundColor DarkGray
    }
    Write-Log "DEBUG" $msg
}

# ── Retry Wrapper ────────────────────────────────────────────────────────────

function Invoke-WithRetry {
    <#
    .SYNOPSIS
        Retries a script block up to MaxAttempts times with a delay between attempts.
    #>
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [int]$MaxAttempts = 3,
        [int]$DelaySeconds = 2,
        [string]$Label = "operation"
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Write-Info "Executing $Label (attempt $attempt/$MaxAttempts)..."
            $res = (& $Action)
            Write-Info "$Label attempt $attempt succeeded."
            return $res
        }
        catch {
            if ($attempt -eq $MaxAttempts) {
                Write-Err "$Label failed after $MaxAttempts attempts: $_"
                throw
            }
            Write-Warn "$Label failed (attempt $attempt/$MaxAttempts): $_. Retrying in ${DelaySeconds}s..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

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
        Write-Info "Using cached 7za.exe path: $script:SevenZaPath"
        return $script:SevenZaPath
    }

    $tempDir = Join-Path $env:TEMP "ez-cpp-installer"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        Write-Info "Created temporary directory: $tempDir"
    }

    $sevenZaExe = Join-Path $tempDir "7za.exe"

    if (Test-Path $sevenZaExe) {
        Write-Info "Found 7za.exe in temp: $sevenZaExe ($((Get-Item $sevenZaExe).Length) bytes)"
        $script:SevenZaPath = $sevenZaExe
        return $sevenZaExe
    }
    
    try {
        Write-Info "Downloading 7za.exe from: $script:SevenZaUrl"
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $script:SevenZaUrl -OutFile $sevenZaExe -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Info "7za.exe downloaded successfully ($((Get-Item $sevenZaExe).Length) bytes)"
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
        Cleans up 7za.exe from the temporary directory.
    #>
    $tempDir = Join-Path $env:TEMP "ez-cpp-installer"
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Info "Cleaned up temporary 7za directory: $tempDir"
    }
    $script:SevenZaPath = $null
}

# ── Process Runner with Animation ────────────────────────────────────────────

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

    Write-Info "Executing: '$FilePath' $($ArgumentList -join ' ')"
    Write-Info "Redirecting Stdout to: $tempOut"
    Write-Info "Redirecting Stderr to: $tempErr"

    $startTime = Get-Date
    $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden -RedirectStandardOutput $tempOut -RedirectStandardError $tempErr

    Write-Info "Process started with PID: $($proc.Id)"

    $width = 12
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

    $duration = (Get-Date) - $startTime
    $spaces = " " * ($Message.Length + $width + 15)
    Write-Host -NoNewline "`r$spaces`r"

    # Ensure exit code is fully populated (Inno Setup spawns child processes)
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode

    Write-Info "Process PID $($proc.Id) finished in $([math]::Round($duration.TotalSeconds, 2))s with ExitCode: $exitCode"

    # Read and print Stdout / Stderr (verbose-only for success, always on failure)
    if (Test-Path $tempOut) {
        $outText = Get-Content $tempOut -Raw
        if ($outText -and $outText.Trim()) {
            Write-Info "=== Process Stdout Output ==="
            $outText.Trim().Split("`n") | ForEach-Object { Write-Info "  [OUT] $($_.Trim())" }
        }
    }
    $stderrContent = $null
    if (Test-Path $tempErr) {
        $stderrContent = Get-Content $tempErr -Raw
        if ($stderrContent -and $stderrContent.Trim()) {
            # Only show stderr in verbose mode; on failure it gets shown below
            Write-Info "=== Process Stderr Output ==="
            $stderrContent.Trim().Split("`n") | ForEach-Object { Write-Info "  [ERR] $($_.Trim())" }
        }
    }

    # Treat null exit code as success (Inno Setup child process case)
    if ($null -eq $exitCode -or $exitCode -eq 0 -or $exitCode -eq 3000) {
        return $true
    }
    else {
        Write-Warn "Process failed with ExitCode $exitCode"
        # Show stderr on failure even in non-verbose mode
        if (-not $global:EzVerbose -and $stderrContent -and $stderrContent.Trim()) {
            Write-Warn "=== Process Stderr Output ==="
            $stderrContent.Trim().Split("`n") | ForEach-Object { Write-Warn "  [ERR] $($_.Trim())" }
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
        $tempOut = Join-Path $env:TEMP "ez-7z-out.log"
        $tempErr = Join-Path $env:TEMP "ez-7z-err.log"
        
        $argsArray = @("x", "`"$ArchivePath`"", "-o`"$DestinationPath`"", "-y", "-bsp1")
        $proc = Start-Process -FilePath $sevenZa -ArgumentList $argsArray -PassThru -WindowStyle Hidden -RedirectStandardOutput $tempOut -RedirectStandardError $tempErr

        $ps = New-PacmanState
        $barWidth = $ps.BarWidth; $foodArray = $ps.FoodArray; $pacman = $ps.Pacman
        
        $percent = 0
        while (-not $proc.HasExited) {
            try {
                if (Test-Path $tempOut) {
                    $fs = New-Object IO.FileStream($tempOut, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
                    $sr = New-Object IO.StreamReader($fs)
                    $outContent = $sr.ReadToEnd()
                    $sr.Close()
                    $fs.Close()
                    
                    $percentMatches = [regex]::Matches($outContent, '(\d{1,3})%')
                    if ($percentMatches.Count -gt 0) {
                        $percent = [int]($percentMatches[$percentMatches.Count - 1].Groups[1].Value)
                    }
                }
            }
            catch {}
            
            Show-PacmanProgress -TotalBytes 100 -BytesRead $percent -BarWidth $barWidth -PacmanState ([ref]$pacman) -FoodArray $foodArray -PercentMode
            Start-Sleep -Milliseconds 100
        }
        
        # Output 100% at the end
        Show-PacmanProgress -TotalBytes 100 -BytesRead 100 -BarWidth $barWidth -PacmanState ([ref]$pacman) -FoodArray $foodArray -PercentMode
        Write-Host ""
        
        if ($proc.ExitCode -eq 0) {
            return $true
        }
        else {
            Write-Err "Extraction failed"
            return $false
        }
    }
    catch {
        Write-Err "Extraction error: $_"
        return $false
    }
}

# ── Pac-Man Download Progress Bar ────────────────────────────────────────────

function New-PacmanState {
    <#
    .SYNOPSIS
        Creates a fresh Pac-Man progress bar state (food array and mouth toggle).
    #>
    param([int]$BarWidth = 40)
    $foodArray = @()
    for ($i = 0; $i -lt $BarWidth; $i++) {
        $foodArray += if ($i % 2 -eq 0) { "o" } else { " " }
    }
    return @{
        FoodArray = $foodArray
        Pacman    = [PSCustomObject]@{ Value = "C" }
        BarWidth  = $BarWidth
    }
}

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
    .PARAMETER ItemMode
        If specified, displays counts (e.g., 2 / 5) instead of Megabytes.
    .PARAMETER PercentMode
        If specified, displays only the percentage.
    #>
    param(
        [long]$TotalBytes,
        [long]$BytesRead,
        [int]$BarWidth = 40,
        [ref]$PacmanState,
        [object[]]$FoodArray,
        [double]$TotalMB,
        [switch]$ItemMode,
        [switch]$PercentMode
    )

    $percent = if ($TotalBytes -eq 0) { 0 } else { ($BytesRead / $TotalBytes) * 100 }
    $percentDisplay = "{0,6:N1}%" -f $percent

    if ($PercentMode) {
        $downloadedStr = ""
        $totalStr = ""
    }
    elseif ($ItemMode) {
        $downloadedStr = "{0,2}" -f $BytesRead
        $totalStr = "$TotalBytes"
    }
    else {
        $downloadedMB = if ($TotalBytes -eq 0) { 0 } else { $BytesRead / 1MB }
        $downloadedStr = "{0,6:N2} MB" -f $downloadedMB
        $totalStr = "{0:N2} MB" -f $TotalMB
    }

    $eaten = [int](($percent / 100) * $BarWidth)

    # Pac-Man mouth animation (toggles C <-> c every 750ms based on wall-clock time)
    $ticks = [Environment]::TickCount
    $isMouthOpen = ([math]::Floor([math]::Abs($ticks) / 750) % 2 -eq 0)
    $pacmanChar = if ($isMouthOpen) { "C" } else { "c" }

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
        $barContents = "$trail$pacmanChar$remainingFood".TrimEnd().PadRight($BarWidth)
    }

    $bar = "      [$barContents]"
    if ($PercentMode) {
        Write-Host -NoNewline "`r$bar $percentDisplay                "
    }
    else {
        Write-Host -NoNewline "`r$bar $percentDisplay - $downloadedStr / $totalStr"
    }
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
        $buffer = New-Object byte[] 524288  # 512 KB buffer (150 updates total for 77MB, great balance)
        $totalRead = [long]0

        # Setup Pac-Man bar
        $ps = New-PacmanState
        $barWidth = $ps.BarWidth; $foodArray = $ps.FoodArray; $pacman = $ps.Pacman

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
