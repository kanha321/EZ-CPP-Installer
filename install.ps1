<#
.SYNOPSIS
    EZ C/C++ Installer v6.0
    One-command installer for a complete C/C++ development environment on Windows.

.DESCRIPTION
    Installs MinGW GCC 14, VS Code, extensions, settings, keybindings, and snippets.

.NOTES
    Usage: irm https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main/install.ps1 | iex
#>

[CmdletBinding()]
param()

if ($PSBoundParameters.ContainsKey('Verbose') -or $VerbosePreference -eq 'Continue') {
    $global:EzVerbose = $true
}

# ── Auto-Elevate to Administrator ───────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n  [-] Administrator privileges are required to continue." -ForegroundColor Red
    Write-Host "      Please open a new Terminal window as Administrator and run the command again." -ForegroundColor Yellow
    Write-Host "      (Right-click the Start button -> 'Terminal (Admin)' or 'Windows PowerShell (Admin)')`n" -ForegroundColor Cyan
    return
}

$global:EzLogFile = Join-Path $env:USERPROFILE "ez-cpp-install.log"
Write-Host "  [i] Saving logs to: $global:EzLogFile" -ForegroundColor DarkGray

# Ensure local proxy does not intercept localhost testing requests
$env:NO_PROXY = "localhost,127.0.0.1"

Add-Content -Path $global:EzLogFile -Value "`n=================================================="
Add-Content -Path $global:EzLogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [INFO] Starting EZ C/C++ Installer v6.0"

# ── URLs (single source of truth) ───────────────────────────────────────────
$script:RepoBaseUrl = "https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main"
$script:ReleaseUrl  = "https://github.com/kanha321/EZ-CPP-Installer/releases/download/6.0"

# ── Download & Load Modules ─────────────────────────────────────────────────
$modulesDir = Join-Path $env:TEMP "ez-cpp-modules"
if (-not (Test-Path $modulesDir)) {
    New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null
}

$modules = @("constants", "utils", "mingw", "vscode")
foreach ($mod in $modules) {
    $modUrl = "$($script:RepoBaseUrl)/modules/$mod.ps1"
    $modPath = Join-Path $modulesDir "$mod.ps1"
    $maxAttempts = 3
    $downloaded = $false
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $modUrl -OutFile $modPath -UseBasicParsing
            $ProgressPreference = 'Continue'
            $downloaded = $true
            break
        }
        catch {
            if ($attempt -lt $maxAttempts) {
                Write-Host "  [!] Failed to download $mod.ps1 (attempt $attempt/$maxAttempts). Retrying..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
    }
    if (-not $downloaded) {
        Write-Host "  [✗] Failed to download module: $mod.ps1 after $maxAttempts attempts." -ForegroundColor Red
        Write-Host "      Check your internet connection and try again." -ForegroundColor Yellow
        Add-Content -Path $global:EzLogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [ERROR] Failed to download module: $mod.ps1"
        return
    }
}

# Load modules (order matters: constants -> utils -> others)
. (Join-Path $modulesDir "constants.ps1")
. (Join-Path $modulesDir "utils.ps1")
. (Join-Path $modulesDir "mingw.ps1")
. (Join-Path $modulesDir "vscode.ps1")

# ── Banner ───────────────────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Magenta
Write-Host "  |                                          |" -ForegroundColor Magenta
Write-Host "  |      EZ C/C++ Installer  v6.0            |" -ForegroundColor Magenta
Write-Host "  |      github.com/kanha321                 |" -ForegroundColor Magenta
Write-Host "  |                                          |" -ForegroundColor Magenta
Write-Host "  +------------------------------------------+" -ForegroundColor Magenta
Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1: Install MinGW GCC 14
# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
$mingwSuccess = Install-MinGW
if (-not $mingwSuccess) {
    Write-Err "MinGW installation failed. Aborting."
    return
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2: Install VS Code
# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
$vsCodeAvailable = Install-VSCode

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3: Extensions & Configuration
# ══════════════════════════════════════════════════════════════════════════════
if ($vsCodeAvailable) {
    Write-Host ""
    Install-VSCodeExtensions
    Write-Host ""
    Install-VSCodeConfig
}

# ══════════════════════════════════════════════════════════════════════════════
# Cleanup & Summary
# ══════════════════════════════════════════════════════════════════════════════
Remove-7za
Remove-Item -Path $modulesDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Green
Write-Host "  |                                          |" -ForegroundColor Green
Write-Host "  |      Installation Complete!              |" -ForegroundColor Green
Write-Host "  |                                          |" -ForegroundColor Green
Write-Host "  +------------------------------------------+" -ForegroundColor Green
Write-Host ""

# ── Final Verification (fresh process to pick up real PATH) ─────────────────
Write-Info "Launching fresh process to verify GCC on PATH..."

try {
    $gccCheck = cmd.exe /c "gcc --version 2>&1" | Select-Object -First 1
    if ($gccCheck -and $gccCheck -match 'gcc') {
        Write-Ok "GCC verified (new process): $gccCheck"
    }
    else {
        Write-Warn "gcc not found in a fresh process. PATH may need a system restart."
        Write-Info "Open a new Terminal and run: gcc --version"
    }
}
catch {
    Write-Warn "Could not verify gcc in a fresh process."
    Write-Info "Open a new Terminal and run: gcc --version"
}

if ($vsCodeAvailable) {
    Write-Ok "VS Code is configured and ready to use."
}

Write-Host ""
Write-Host "  +--------------------------------------------------------------+" -ForegroundColor White
Write-Host "  |  PATH changes take effect in NEW terminal windows.          |" -ForegroundColor White
Write-Host "  |  Open a new Terminal and verify with:                       |" -ForegroundColor White
Write-Host "  |                                                             |" -ForegroundColor White
Write-Host "  |      gcc --version                                          |" -ForegroundColor Cyan
Write-Host "  |                                                             |" -ForegroundColor White
Write-Host "  |  Or just open VS Code and start coding!                     |" -ForegroundColor White
Write-Host "  +--------------------------------------------------------------+" -ForegroundColor White
Write-Host ""

