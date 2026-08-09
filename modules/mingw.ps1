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

# ── Detection Helpers ────────────────────────────────────────────────────────

function Test-GccAt {
    <#
    .SYNOPSIS
        Tests if a valid GCC executable exists at a given path and returns its version.
    .PARAMETER GccPath
        Full path to gcc.exe.
    .OUTPUTS
        Hashtable with keys: Valid (bool), Version (string), Major (int)
    #>
    param([Parameter(Mandatory)][string]$GccPath)

    $result = @{ Valid = $false; Version = $null; Major = 0 }

    if (-not (Test-Path $GccPath)) { return $result }

    try {
        $versionLine = & $GccPath --version 2>$null | Select-Object -First 1
        if ($versionLine -match '(\d+\.\d+\.\d+)') {
            $result.Version = $matches[1]
            $result.Major = [int]($result.Version.Split('.')[0])
            $result.Valid = $true
        }
    }
    catch {
        # gcc.exe exists but can't execute - corrupted binary
        Write-Log "WARN" "gcc.exe at $GccPath exists but failed to execute: $_"
    }

    return $result
}

function Get-GccStatus {
    <#
    .SYNOPSIS
        Comprehensive GCC detection: checks the expected install directory first,
        then falls back to PATH discovery.
    .OUTPUTS
        Hashtable with keys:
          Ready     (bool)   - GCC 14+ is usable right now
          OnDisk    (bool)   - C:\MinGW14\bin\gcc.exe exists and runs
          OnPath    (bool)   - Some gcc is reachable via PATH
          Version   (string) - Detected version string
          Major     (int)    - Major version number
          BinPath   (string) - Path to the bin directory of the found gcc
    #>
    $status = @{
        Ready   = $false
        OnDisk  = $false
        OnPath  = $false
        Version = $null
        Major   = 0
        BinPath = $null
    }

    # ── Check 1: Is GCC already at C:\MinGW14\bin? ──────────────────────────
    $expectedGcc = Join-Path $script:MingwBinPath "gcc.exe"
    $diskCheck = Test-GccAt -GccPath $expectedGcc

    if ($diskCheck.Valid) {
        $status.OnDisk  = $true
        $status.Version = $diskCheck.Version
        $status.Major   = $diskCheck.Major
        $status.BinPath = $script:MingwBinPath

        if ($diskCheck.Major -ge 14) {
            $status.Ready = $true
            return $status
        }
    }

    # ── Check 2: Is any gcc reachable via current PATH? ─────────────────────
    $pathGcc = Get-Command gcc -ErrorAction SilentlyContinue
    if ($pathGcc) {
        $pathCheck = Test-GccAt -GccPath $pathGcc.Source
        if ($pathCheck.Valid) {
            $status.OnPath  = $true
            $status.Version = $pathCheck.Version
            $status.Major   = $pathCheck.Major
            $status.BinPath = Split-Path $pathGcc.Source -Parent

            if ($pathCheck.Major -ge 14) {
                $status.Ready = $true
            }
        }
    }

    return $status
}

# ── Installation ─────────────────────────────────────────────────────────────

function Install-MinGW {
    <#
    .SYNOPSIS
        Ensures MinGW GCC 14 is installed and on PATH.
    .DESCRIPTION
        Detection flow (no room for error):
          1. If C:\MinGW14\bin\gcc.exe exists and is GCC 14+ -> just fix PATH if needed
          2. If gcc 14+ is found elsewhere on PATH -> skip entirely
          3. If older gcc or no gcc -> download, extract, verify, update PATH
        Post-install verification:
          - Confirms gcc.exe exists on disk
          - Confirms gcc.exe actually runs and reports version 14+
          - Confirms gcc is reachable via the updated session PATH
    .OUTPUTS
        Boolean - $true if GCC 14+ is usable after this function, $false on failure.
    #>

    Write-Step "Checking for GCC..."

    $gccStatus = Get-GccStatus

    # ── Case 1: GCC 14+ already at C:\MinGW14 ──────────────────────────────
    if ($gccStatus.OnDisk -and $gccStatus.Major -ge 14) {
        Write-Ok "GCC $($gccStatus.Version) found at $($script:MingwInstallDir)"
        Ensure-MingwOnPath
        return $true
    }

    # ── Case 2: GCC 14+ found elsewhere on PATH ────────────────────────────
    if ($gccStatus.OnPath -and $gccStatus.Major -ge 14) {
        Write-Ok "GCC $($gccStatus.Version) already installed at $($gccStatus.BinPath) - skipping"
        return $true
    }

    # ── Case 3: Older GCC or no GCC - need to install ──────────────────────
    if ($gccStatus.Version) {
        Write-Warn "GCC $($gccStatus.Version) found (older than 14). Installing GCC 14..."
    } else {
        Write-Step "No GCC found. Installing MinGW GCC 14..."
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
        Remove-Item -Path $script:MingwInstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    $success = Expand-7zArchive -ArchivePath $tempArchive -DestinationPath "C:\"
    if (-not $success) {
        Write-Err "Extraction failed."
        return $false
    }

    # ── Post-Install Verification (3 checks) ────────────────────────────────

    # Check 1: Does the directory exist?
    if (-not (Test-Path $script:MingwInstallDir)) {
        Write-Err "Extraction completed but $($script:MingwInstallDir) was not created."
        return $false
    }

    # Check 2: Does gcc.exe exist on disk?
    $gccExe = Join-Path $script:MingwBinPath "gcc.exe"
    if (-not (Test-Path $gccExe)) {
        Write-Err "gcc.exe not found at $gccExe. Archive may be corrupted."
        Write-Info "Try deleting $tempArchive and running the installer again."
        return $false
    }

    # Check 3: Does gcc.exe actually run and report version 14+?
    $verifyResult = Test-GccAt -GccPath $gccExe
    if (-not $verifyResult.Valid) {
        Write-Err "gcc.exe exists but failed to execute. The binary may be corrupted."
        return $false
    }
    if ($verifyResult.Major -lt 14) {
        Write-Err "Extracted GCC reports version $($verifyResult.Version) - expected 14+. Archive may be wrong."
        return $false
    }

    Write-Ok "MinGW GCC $($verifyResult.Version) installed to $($script:MingwInstallDir)"

    # Clean up archive
    Remove-Item -Path $tempArchive -Force -ErrorAction SilentlyContinue

    # ── Update PATH ──────────────────────────────────────────────────────────
    Set-MingwPath -OldBinPath $gccStatus.BinPath

    return $true
}

# ── PATH Management ──────────────────────────────────────────────────────────

function Get-DeduplicatedPath {
    <#
    .SYNOPSIS
        Splits a PATH string, removes empty entries and case-insensitive duplicates,
        preserving the order of first occurrence.
    #>
    param([string]$PathString)

    $seen = @{}
    $result = @()
    foreach ($entry in ($PathString -split ';')) {
        $trimmed = $entry.Trim()
        if (-not $trimmed) { continue }
        $key = $trimmed.ToLower()
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $result += $trimmed
        }
    }
    return $result
}

function Ensure-MingwOnPath {
    <#
    .SYNOPSIS
        Ensures C:\MinGW14\bin is on the user PATH. Deduplicates existing entries.
    #>
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $pathParts = Get-DeduplicatedPath -PathString $userPath

    $alreadyPresent = $pathParts | Where-Object { $_.ToLower() -eq $script:MingwBinPath.ToLower() }

    if ($alreadyPresent) {
        Write-Ok "PATH already contains $($script:MingwBinPath)"
    }
    else {
        Write-Step "Adding $($script:MingwBinPath) to PATH..."
        $pathParts += $script:MingwBinPath
        $newPath = ($pathParts -join ';')
        [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
        Write-Ok "PATH updated"
    }

    # Always ensure the current session has it too
    if ($env:Path -notlike "*$($script:MingwBinPath)*") {
        $env:Path = "$($script:MingwBinPath);$env:Path"
    }
}

function Set-MingwPath {
    <#
    .SYNOPSIS
        Adds C:\MinGW14\bin to the user PATH, removing any old MinGW path.
        Deduplicates all entries to clean up damage from old setx usage.
    .PARAMETER OldBinPath
        Path to the old MinGW bin directory to remove (optional).
    #>
    param([string]$OldBinPath)

    Write-Step "Configuring PATH..."

    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $pathParts = Get-DeduplicatedPath -PathString $userPath

    $beforeCount = $pathParts.Count

    # Remove old MinGW path if present (case-insensitive)
    if ($OldBinPath) {
        $oldLower = $OldBinPath.ToLower()
        $pathParts = $pathParts | Where-Object { $_.ToLower() -ne $oldLower }
        if ($pathParts.Count -lt $beforeCount) {
            Write-Info "Removed old MinGW path: $OldBinPath"
        }
    }

    # Add new MinGW14 path if not already present (case-insensitive)
    $alreadyPresent = $pathParts | Where-Object { $_.ToLower() -eq $script:MingwBinPath.ToLower() }
    if (-not $alreadyPresent) {
        $pathParts += $script:MingwBinPath
    }

    $dupsRemoved = $beforeCount - ($pathParts.Count - 1)  # account for the one we may have added
    if ($dupsRemoved -gt 0 -and $beforeCount -gt $pathParts.Count) {
        Write-Info "Cleaned up $($beforeCount - $pathParts.Count + 1) duplicate PATH entries"
    }

    $newPath = ($pathParts -join ';')
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)

    # Update current session so gcc works immediately without reopening terminal
    if ($env:Path -notlike "*$($script:MingwBinPath)*") {
        $env:Path = "$($script:MingwBinPath);$env:Path"
    }

    Write-Ok "PATH updated - $($script:MingwBinPath) added"
}

