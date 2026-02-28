<#
.SYNOPSIS
    EZ C/C++ Installer v6.0
    One-command installer for a complete C/C++ development environment on Windows.

.DESCRIPTION
    Installs MinGW GCC 14, VS Code, extensions, settings, keybindings, and snippets.

.NOTES
    Usage: irm https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main/install.ps1 | iex
#>

# ── Auto-Elevate to Administrator ───────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n  [✗] Administrator privileges are required to continue." -ForegroundColor Red
    Write-Host "      Please open a new Terminal window as Administrator and run the command again." -ForegroundColor Yellow
    Write-Host "      (Right-click the Start button -> 'Terminal (Admin)' or 'Windows PowerShell (Admin)')`n" -ForegroundColor Cyan
    return
}

$global:EzLogFile = Join-Path $env:USERPROFILE "ez-cpp-install.log"
Write-Host "  [i] Saving logs to: $global:EzLogFile" -ForegroundColor DarkGray

Add-Content -Path $global:EzLogFile -Value "`n=================================================="
Add-Content -Path $global:EzLogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff'))] [INFO] Starting EZ C/C++ Installer v6.0"

# ── Download & Load Modules ─────────────────────────────────────────────────
$repoBase = "http://localhost:8000"
$modulesDir = Join-Path $env:TEMP "ez-cpp-modules"

if (-not (Test-Path $modulesDir)) {
    New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null
}

$modules = @("constants", "utils", "mingw", "vscode")
foreach ($mod in $modules) {
    $modUrl = "$repoBase/modules/$mod.ps1"
    $modPath = Join-Path $modulesDir "$mod.ps1"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $modUrl -OutFile $modPath -UseBasicParsing
        $ProgressPreference = 'Continue'
    }
    catch {
        Write-Host "  [✗] Failed to download module: $mod.ps1" -ForegroundColor Red
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
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║                                          ║" -ForegroundColor Magenta
Write-Host "  ║      EZ C/C++ Installer  v6.0            ║" -ForegroundColor Magenta
Write-Host "  ║      github.com/kanha321                 ║" -ForegroundColor Magenta
Write-Host "  ║                                          ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1: System Check
# ══════════════════════════════════════════════════════════════════════════════
Write-Step "Checking system..."

if (-not [Environment]::Is64BitOperatingSystem) {
    Write-Err "32-bit system detected. This installer requires 64-bit Windows."
    Write-Info "Visit https://github.com/kanha321/EZ-CPP-Installer for the 32-bit version."
    return
}
Write-Ok "64-bit system detected"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2: Install MinGW GCC 14
# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
$mingwSuccess = Install-MinGW
if (-not $mingwSuccess) {
    Write-Err "MinGW installation failed. Aborting."
    return
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3: Install VS Code
# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
$vsCodeAvailable = Install-VSCode

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4: Extensions & Configuration
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
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║                                          ║" -ForegroundColor Green
Write-Host "  ║      Installation Complete! 🎉           ║" -ForegroundColor Green
Write-Host "  ║                                          ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Quick verification
$gccCheck = Get-Command gcc -ErrorAction SilentlyContinue
if ($gccCheck) {
    $gccVer = (& gcc --version | Select-Object -First 1)
    Write-Ok "GCC ready: $gccVer"
}
else {
    Write-Warn "GCC will be available after you restart your terminal."
}

if ($vsCodeAvailable) {
    Write-Ok "VS Code is configured and ready to use."
}

Write-Host ""
Write-Host "  → Open a NEW terminal window and try:" -ForegroundColor White
Write-Host "      gcc --version" -ForegroundColor Cyan
Write-Host ""
Write-Host "  → Or open VS Code and start coding!" -ForegroundColor White
Write-Host ""
