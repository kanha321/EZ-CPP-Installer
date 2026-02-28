<#
.SYNOPSIS
    EZ C/C++ Installer - Uninstaller
    Cleans up the development environment for testing/removal purposes.
#>

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
function Write-Ok { param([string]$msg) Write-Host "  [✓] $msg" -ForegroundColor Green; Write-Log "INFO" $msg }
function Write-Warn { param([string]$msg) Write-Host "  [!] $msg" -ForegroundColor Yellow; Write-Log "WARN" $msg }
function Write-Info { param([string]$msg) Write-Host "      $msg" -ForegroundColor DarkGray; Write-Log "DEBUG" $msg }

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

    $spaces = " " * ($Message.Length + $width + 15)
    Write-Host -NoNewline "`r$spaces`r"

    if ($proc.ExitCode -eq 0) {
        return $true
    }
    else {
        if (Test-Path $tempErr) {
            $errContent = Get-Content $tempErr -Raw
            if ($null -ne $errContent) {
                $errText = $errContent.Trim()
                if ($errText) { Write-Warn "Process output: $errText" }
            }
        }
        return $false
    }
}

Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "  ║                                          ║" -ForegroundColor Red
Write-Host "  ║      EZ C/C++ Cleanup Tool               ║" -ForegroundColor Red
Write-Host "  ║                                          ║" -ForegroundColor Red
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

$removeMingw = Read-Host "  Remove MinGW GCC 14 (C:\MinGW14)? [Y/N]"
$removeVscode = Read-Host "  Remove VS Code and ALL extensions/settings? [Y/N]"

Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
# MinGW Cleanup
# ══════════════════════════════════════════════════════════════════════════════
if ($removeMingw.ToLower() -eq 'y') {
    $mingwDir = "C:\MinGW14"
    if (Test-Path $mingwDir) {
        Write-Log "INFO" "Removing MinGW GCC 14..."
        $argsArray = @("-NoProfile", "-Command", "Remove-Item -Path '$mingwDir' -Recurse -Force -ErrorAction SilentlyContinue")
        Invoke-WithBounceProgress -Message "Removing MinGW GCC 14" -FilePath "powershell.exe" -ArgumentList $argsArray | Out-Null
        Write-Ok "Deleted C:\MinGW14"
    }
    else {
        Write-Ok "C:\MinGW14 not found (already removed)."
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($userPath -and $userPath -match 'MinGW14') {
        Write-Log "INFO" "Cleaning MinGW from User PATH..."
        $scriptBlock = {
            $path = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
            $cleaned = ($path -split ';') | Where-Object { $_ -and $_ -notmatch 'MinGW14' }
            [Environment]::SetEnvironmentVariable('Path', ($cleaned -join ';').Trim(';'), [EnvironmentVariableTarget]::User)
        }.ToString()
        $argsArray = @("-NoProfile", "-Command", $scriptBlock)
        Invoke-WithBounceProgress -Message "Cleaning MinGW Path" -FilePath "powershell.exe" -ArgumentList $argsArray | Out-Null
        Write-Ok "MinGW removed from User PATH."
    }
    else {
        Write-Ok "MinGW absent from User PATH (already clean)."
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# VS Code Cleanup
# ══════════════════════════════════════════════════════════════════════════════
if ($removeVscode.ToLower() -eq 'y') {
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

    $appDataCode = "$env:APPDATA\Code"
    $userProfileVscode = "$env:USERPROFILE\.vscode"

    if (Test-Path $appDataCode) {
        Write-Log "INFO" "Deleting AppData\Roaming\Code..."
        $argsArray = @("-NoProfile", "-Command", "Remove-Item -Path '$appDataCode' -Recurse -Force -ErrorAction SilentlyContinue")
        Invoke-WithBounceProgress -Message "Deleting VS Code Settings" -FilePath "powershell.exe" -ArgumentList $argsArray | Out-Null
        Write-Ok "Deleted AppData\Roaming\Code."
    }
    else {
        Write-Ok "AppData\Roaming\Code not found (already clean)."
    }
    
    if (Test-Path $userProfileVscode) {
        Write-Log "INFO" "Deleting .vscode extensions folder..."
        $argsArray = @("-NoProfile", "-Command", "Remove-Item -Path '$userProfileVscode' -Recurse -Force -ErrorAction SilentlyContinue")
        Invoke-WithBounceProgress -Message "Deleting VS Code Extensions" -FilePath "powershell.exe" -ArgumentList $argsArray | Out-Null
        Write-Ok "Deleted .vscode extensions folder."
    }
    else {
        Write-Ok ".vscode extensions folder not found (already clean)."
    }

    # User PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($userPath -and ($userPath -match 'Microsoft VS Code')) {
        Write-Log "INFO" "Cleaning VS Code from User PATH..."
        $scriptBlock = {
            $path = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
            $cleaned = ($path -split ';') | Where-Object { $_ -and $_ -notmatch 'Microsoft VS Code' }
            [Environment]::SetEnvironmentVariable('Path', ($cleaned -join ';').Trim(';'), [EnvironmentVariableTarget]::User)
        }.ToString()
        $argsArray = @("-NoProfile", "-Command", $scriptBlock)
        Invoke-WithBounceProgress -Message "Cleaning VS Code User Path" -FilePath "powershell.exe" -ArgumentList $argsArray | Out-Null
        Write-Ok "VS Code removed from User PATH."
    }
    else {
        Write-Ok "VS Code absent from User PATH."
    }
    
    # Machine PATH
    $machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    if ($machinePath -and ($machinePath -match 'Microsoft VS Code')) {
        Write-Log "INFO" "Cleaning VS Code from Machine PATH..."
        $scriptBlock = {
            $path = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
            $cleaned = ($path -split ';') | Where-Object { $_ -and $_ -notmatch 'Microsoft VS Code' }
            [Environment]::SetEnvironmentVariable('Path', ($cleaned -join ';').Trim(';'), [EnvironmentVariableTarget]::Machine)
        }.ToString()
        $argsArray = @("-NoProfile", "-Command", $scriptBlock)
        Invoke-WithBounceProgress -Message "Cleaning VS Code Sys Path" -FilePath "powershell.exe" -ArgumentList $argsArray | Out-Null
        Write-Ok "VS Code removed from Machine PATH."
    }
    else {
        Write-Ok "VS Code absent from Machine PATH."
    }
}

Write-Host ""
Write-Host "  [✓] Cleanup finished!" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 5
