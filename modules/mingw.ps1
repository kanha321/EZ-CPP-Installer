<#
.SYNOPSIS
    MinGW GCC 14 installation module for EZ C/C++ Installer.
.DESCRIPTION
    Downloads MinGW GCC 14 (.7z) from GitHub Releases, extracts it
    to C:\MinGW14, and configures the user PATH.
    Requires: utils.ps1 to be loaded first.
#>

# Configuration is loaded from constants.ps1:
#   $script:MingwArchiveUrl, $script:MingwInstallDir, $script:MingwBinPath

# ── Public Functions ─────────────────────────────────────────────────────────

function Test-GccInstalled {
    <#
    .SYNOPSIS
        Checks if GCC 14+ is already installed and on PATH.
    .OUTPUTS
        Hashtable with keys: Installed (bool), Version (string), Major (int), BinPath (string)
    #>
    $result = @{ Installed = $false; Version = $null; Major = 0; BinPath = $null }

    $gcc = Get-Command gcc -ErrorAction SilentlyContinue
    if (-not $gcc) { return $result }

    $result.BinPath = Split-Path $gcc.Source -Parent

    $versionLine = & gcc --version | Select-Object -First 1
    if ($versionLine -match '(\d+\.\d+\.\d+)') {
        $result.Version = $matches[1]
        $result.Major = [int]($result.Version.Split('.')[0])
        if ($result.Major -ge 14) {
            $result.Installed = $true
        }
    }

    return $result
}

function Install-MinGW {
    <#
    .SYNOPSIS
        Downloads and installs MinGW GCC 14, then updates the user PATH.
    .DESCRIPTION
        - Skips if GCC 14+ is already installed
        - Downloads .7z archive with Pac-Man progress bar
        - Extracts using 7za.exe (from utils.ps1)
        - Updates user PATH, removing old MinGW entries if present
    .OUTPUTS
        Boolean - $true if GCC 14+ is available after this function, $false on failure.
    #>

    $gccStatus = Test-GccInstalled

    if ($gccStatus.Installed) {
        Write-Ok "GCC $($gccStatus.Version) already installed — skipping MinGW"
        return $true
    }

    if ($gccStatus.Version) {
        Write-Warn "GCC $($gccStatus.Version) found (older than 14). Will install GCC 14 and update PATH."
    }

    # ── Download ─────────────────────────────────────────────────────────────
    $tempArchive = Join-Path $env:TEMP "MinGW14.7z"

    if (Test-Path $tempArchive) {
        Write-Info "Using cached download: $tempArchive"
    }
    else {
        Write-Step "Downloading MinGW GCC 14..."
        $success = Invoke-DownloadWithProgress -Url $script:MingwArchiveUrl -OutputPath $tempArchive
        if (-not $success) {
            Write-Err "Download failed. Check your internet connection and try again."
            return $false
        }
        Write-Ok "Download complete"
    }

    # ── Extract ──────────────────────────────────────────────────────────────
    Write-Step "Extracting MinGW to $($script:MingwInstallDir)..."

    if (Test-Path $script:MingwInstallDir) {
        Write-Info "Removing old MinGW installation..."
        Remove-Item -Path $script:MingwInstallDir -Recurse -Force
    }

    $success = Expand-7zArchive -ArchivePath $tempArchive -DestinationPath "C:\"
    if (-not $success) {
        Write-Err "Extraction failed."
        return $false
    }
    Write-Ok "MinGW installed to $($script:MingwInstallDir)"

    # Clean up archive
    Remove-Item -Path $tempArchive -Force -ErrorAction SilentlyContinue

    # ── Update PATH ──────────────────────────────────────────────────────────
    Set-MingwPath -OldBinPath $gccStatus.BinPath

    return $true
}

function Set-MingwPath {
    <#
    .SYNOPSIS
        Adds C:\MinGW14\bin to the user PATH, removing any old MinGW path.
    .PARAMETER OldBinPath
        Path to the old MinGW bin directory to remove (optional).
    #>
    param([string]$OldBinPath)

    Write-Step "Configuring PATH..."

    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $pathParts = ($userPath -split ';') | Where-Object { $_ }

    # Remove old MinGW path if present
    if ($OldBinPath) {
        $pathParts = $pathParts | Where-Object { $_ -ne $OldBinPath }
    }

    # Add new MinGW14 path if not already present
    if (-not ($pathParts -contains $script:MingwBinPath)) {
        $pathParts += $script:MingwBinPath
    }

    $newPath = ($pathParts -join ';').Trim(';')
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)

    # Update current session
    $env:Path = "$($script:MingwBinPath);$env:Path"

    Write-Ok "PATH updated — $($script:MingwBinPath) added"
}
