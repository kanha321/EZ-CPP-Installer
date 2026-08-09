<#
.SYNOPSIS
    EZ C/C++ Installer - Uninstaller
    Cleans up the development environment for testing/removal purposes.
#>

[CmdletBinding()]
param()

if ($PSBoundParameters.ContainsKey('Verbose') -or $VerbosePreference -eq 'Continue') {
    $global:EzVerbose = $true
}

# ── Check Administrator Privileges ────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n  [✗] Administrator privileges are required to continue." -ForegroundColor Red
    Write-Host "      Please open a new Terminal window as Administrator and run the command again." -ForegroundColor Yellow
    Write-Host "      (Right-click the Start button -> 'Terminal (Admin)' or 'Windows PowerShell (Admin)')`n" -ForegroundColor Cyan
    return
}

# ── Logging & Output Helpers ─────────────────────────────────────────────────
$global:EzLogFile = Join-Path $env:USERPROFILE "ez-cpp-uninstall.log"
Write-Host "  [i] Saving logs to: $global:EzLogFile" -ForegroundColor DarkGray

Add-Content -Path $global:EzLogFile -Value "`n=================================================="
Add-Content -Path $global:EzLogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [INFO] Starting EZ C/C++ Cleanup Tool"

function Write-Log {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $global:EzLogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Write-Step { param([string]$msg) Write-Host "  [*] $msg" -ForegroundColor Cyan; Write-Log "INFO" $msg }
function Write-Ok { param([string]$msg) Write-Host "  [+] $msg" -ForegroundColor Green; Write-Log "INFO" $msg }
function Write-Warn { param([string]$msg) Write-Host "  [!] $msg" -ForegroundColor Yellow; Write-Log "WARN" $msg }
function Write-Info { param([string]$msg) Write-Host "      $msg" -ForegroundColor DarkGray; Write-Log "DEBUG" $msg }

function Invoke-WithBounceProgress {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList
    )
    $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden -RedirectStandardOutput ([IO.Path]::GetTempFileName()) -RedirectStandardError ([IO.Path]::GetTempFileName())
    $width = 12; $pos = 0; $dir = 1
    while (-not $proc.HasExited) {
        $arr = [char[]]("_" * $width); $arr[$pos] = "-"
        Write-Host -NoNewline "`r  [*] $Message [$($arr -join '')]"
        $pos += $dir
        if ($pos -ge $width - 1) { $dir = -1 } elseif ($pos -le 0) { $dir = 1 }
        Start-Sleep -Milliseconds 40
    }
    Write-Host -NoNewline ("`r" + (" " * ($Message.Length + $width + 15)) + "`r")
    return ($proc.ExitCode -eq 0)
}

function Remove-PathEntries {
    <#
    .SYNOPSIS
        Removes matching entries from a PATH variable (case-insensitive),
        deduplicates remaining entries, and writes back to the registry.
    .PARAMETER Target
        'User' or 'Machine' environment variable target.
    .PARAMETER Pattern
        Regex pattern to match entries to remove (case-insensitive).
    .PARAMETER Label
        Display label for logging (e.g., "MinGW", "VS Code").
    .OUTPUTS
        Boolean - $true if entries were removed, $false if nothing matched.
    #>
    param(
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Label
    )

    $envTarget = if ($Target -eq 'User') { [EnvironmentVariableTarget]::User } else { [EnvironmentVariableTarget]::Machine }
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $envTarget)

    if (-not $currentPath) { return }

    # Split, deduplicate (case-insensitive, preserve first occurrence)
    $seen = @{}
    $pathParts = @()
    foreach ($entry in ($currentPath -split ';')) {
        $trimmed = $entry.Trim()
        if (-not $trimmed) { continue }
        $key = $trimmed.ToLower()
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $pathParts += $trimmed
        }
    }

    $beforeCount = $pathParts.Count
    $cleaned = $pathParts | Where-Object { $_ -notmatch $Pattern }

    if ($cleaned.Count -lt $beforeCount) {
        $removed = $beforeCount - $cleaned.Count
        [Environment]::SetEnvironmentVariable("Path", ($cleaned -join ';'), $envTarget)
        Write-Ok "$Label removed from $Target PATH - $removed duplicate/stale entries cleaned."
        return
    }

    Write-Ok "$Label absent from $Target PATH (already clean)."
}

# ── Banner ───────────────────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Red
Write-Host "  |                                          |" -ForegroundColor Red
Write-Host "  |      EZ C/C++ Cleanup Tool               |" -ForegroundColor Red
Write-Host "  |                                          |" -ForegroundColor Red
Write-Host "  +------------------------------------------+" -ForegroundColor Red
Write-Host ""

$removeMingw = Read-Host "  Remove MinGW GCC 14 (C:\MinGW14)? [y/N]"
if ([string]::IsNullOrWhiteSpace($removeMingw)) { $removeMingw = "n" }

$removeVscode = Read-Host "  Remove VS Code and ALL extensions/settings? [y/N]"
if ([string]::IsNullOrWhiteSpace($removeVscode)) { $removeVscode = "n" }

# Track what was done for the summary
$summary = @()

Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
# MinGW Cleanup
# ══════════════════════════════════════════════════════════════════════════════
if ($removeMingw -and $removeMingw.ToLower() -eq 'y') {
    $mingwDir = "C:\MinGW14"
    if (Test-Path $mingwDir) {
        Write-Log "INFO" "Removing MinGW GCC 14..."
        $argsArray = @("-NoProfile", "-Command", "Remove-Item -Path '$mingwDir' -Recurse -Force -ErrorAction SilentlyContinue")
        Invoke-WithBounceProgress -Message "Removing MinGW GCC 14" -FilePath "powershell.exe" -ArgumentList $argsArray | Out-Null

        # Verify deletion
        if (Test-Path $mingwDir) {
            Write-Warn "C:\MinGW14 could not be fully deleted (files may be in use)."
            Write-Info "Close any programs using GCC and try again."
            $summary += "MinGW: partially removed (some files locked)"
        }
        else {
            Write-Ok "Deleted C:\MinGW14"
            $summary += "MinGW: removed"
        }
    }
    else {
        Write-Ok "C:\MinGW14 not found (already removed)."
        $summary += "MinGW: already clean"
    }

    # Clean PATH inline (no child process needed)
    Remove-PathEntries -Target 'User' -Pattern 'MinGW14' -Label "MinGW"
}
else {
    Write-Info "Skipping MinGW removal."
    $summary += "MinGW: skipped"
}

# ══════════════════════════════════════════════════════════════════════════════
# VS Code Cleanup
# ══════════════════════════════════════════════════════════════════════════════
if ($removeVscode -and $removeVscode.ToLower() -eq 'y') {
    Write-Step "Uninstalling VS Code..."
    
    # Check for uninstaller
    $uninsPaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\unins000.exe",
        "$env:ProgramFiles\Microsoft VS Code\unins000.exe"
    )

    $uninstalled = $false
    foreach ($path in $uninsPaths) {
        if (Test-Path $path) {
            $argsArray = @("/VERYSILENT")
            Invoke-WithBounceProgress -Message "Running VS Code silent uninstaller" -FilePath $path -ArgumentList $argsArray | Out-Null
            $uninstalled = $true
            break
        }
    }

    if ($uninstalled) {
        Write-Ok "VS Code uninstalled."
    }
    else {
        Write-Ok "VS Code uninstaller not found (already uninstalled)."
    }

    # Clean up settings and extensions
    $appDataCode = "$env:APPDATA\Code"
    $userProfileVscode = "$env:USERPROFILE\.vscode"

    if (Test-Path $appDataCode) {
        Write-Log "INFO" "Deleting AppData\Roaming\Code..."
        $argsArray = @("-NoProfile", "-Command", "Remove-Item -Path '$appDataCode' -Recurse -Force -ErrorAction SilentlyContinue")
        Invoke-WithBounceProgress -Message "Deleting VS Code Settings" -FilePath "powershell.exe" -ArgumentList $argsArray | Out-Null
        if (Test-Path $appDataCode) {
            Write-Warn "Could not fully delete AppData\Roaming\Code (files may be in use)."
        } else {
            Write-Ok "Deleted AppData\Roaming\Code."
        }
    }
    else {
        Write-Ok "AppData\Roaming\Code not found (already clean)."
    }
    
    if (Test-Path $userProfileVscode) {
        Write-Log "INFO" "Deleting .vscode extensions folder..."
        $argsArray = @("-NoProfile", "-Command", "Remove-Item -Path '$userProfileVscode' -Recurse -Force -ErrorAction SilentlyContinue")
        Invoke-WithBounceProgress -Message "Deleting VS Code Extensions" -FilePath "powershell.exe" -ArgumentList $argsArray | Out-Null
        if (Test-Path $userProfileVscode) {
            Write-Warn "Could not fully delete .vscode folder (files may be in use)."
        } else {
            Write-Ok "Deleted .vscode extensions folder."
        }
    }
    else {
        Write-Ok ".vscode extensions folder not found (already clean)."
    }

    # Clean PATH inline - both User and Machine
    Remove-PathEntries -Target 'User' -Pattern 'Microsoft VS Code' -Label "VS Code"
    Remove-PathEntries -Target 'Machine' -Pattern 'Microsoft VS Code' -Label "VS Code"

    $summary += "VS Code: removed"
}
else {
    Write-Info "Skipping VS Code removal."
    $summary += "VS Code: skipped"
}

# ══════════════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Green
Write-Host "  |  Cleanup Summary                         |" -ForegroundColor Green
Write-Host "  +------------------------------------------+" -ForegroundColor Green
foreach ($line in $summary) {
    Write-Host "      * $line" -ForegroundColor White
}
Write-Host ""
Write-Host "  [+] Cleanup finished!" -ForegroundColor Green
Write-Host ""
Write-Host "  +--------------------------------------------------------------+" -ForegroundColor White
Write-Host "  |  PATH changes take effect in NEW terminal windows.          |" -ForegroundColor White
Write-Host "  +--------------------------------------------------------------+" -ForegroundColor White
Write-Host ""
Start-Sleep -Seconds 5
