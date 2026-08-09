<#
.SYNOPSIS
    VS Code installation and configuration module for EZ C/C++ Installer.
.DESCRIPTION
    Handles VS Code detection, installation (direct installer / skip),
    extension installation via CLI, and settings/keybindings/snippets setup
    with automatic backup of existing config.
    Requires: utils.ps1 to be loaded first.
#>

# Configuration is loaded from constants.ps1:
#   $script:VSCodeInstallerUrl, $script:RepoBaseUrl, $script:Extensions, $script:ConfigFiles

# ===== Detection =============================================================

function Test-VSCodeInstalled {
    <#
    .SYNOPSIS
        Checks if VS Code is installed (on PATH or at known install locations).
    .OUTPUTS
        Hashtable with keys: Installed (bool), OnPath (bool), ExePath (string)
    #>
    $result = @{ Installed = $false; OnPath = $false; ExePath = $null }

    # Check PATH first
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        $result.Installed = $true
        $result.OnPath = $true
        $result.ExePath = $codeCmd.Source
        return $result
    }

    # Check known install locations
    $knownPaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
        "$env:ProgramFiles\Microsoft VS Code\Code.exe"
    )
    foreach ($path in $knownPaths) {
        if (Test-Path $path) {
            $result.Installed = $true
            $result.ExePath = $path
            return $result
        }
    }

    return $result
}

# ===== Installation ==========================================================

function Install-VSCode {
    <#
    .SYNOPSIS
        Detects VS Code, prompts for installation if not found, and returns
        whether VS Code is available for extension/config setup.
    #>
    $vsStatus = Test-VSCodeInstalled

    if ($vsStatus.Installed) {
        Write-Ok "VS Code already installed"
        if (-not $vsStatus.OnPath) {
            Write-Info "Found at: $($vsStatus.ExePath)"
            Write-Warn "'code' command not on PATH - extensions and config may be skipped."
        }
        return $vsStatus.OnPath
    }

    # ===== Not installed - present options ====================================
    Write-Host ""
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor White
    Write-Host "  |  Would you like to install Visual Studio Code?                   |" -ForegroundColor White
    Write-Host "  |                                                                  |" -ForegroundColor White
    Write-Host "  |  [Y] Yes, install VS Code (Recommended)                          |" -ForegroundColor Green
    Write-Host "  |      [+] Full installer with context menu integration            |" -ForegroundColor DarkGray
    Write-Host "  |                                                                  |" -ForegroundColor White
    Write-Host "  |  [N] No, skip (I do not need it)                                 |" -ForegroundColor Yellow
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Choice [Y/n]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "y" }

    switch ($choice.ToLower()) {
        "y" { return Install-VSCodeDirect }
        "n" {
            Write-Warn "Skipping VS Code installation. Extensions and settings will be skipped."
            return $false
        }
        default {
            Write-Warn "Invalid choice. Skipping VS Code installation."
            return $false
        }
    }
}

function Install-VSCodeDirect {
    <#
    .SYNOPSIS
        Downloads and runs the VS Code installer with full context menu integration.
    #>
    $installerPath = Join-Path $env:TEMP "VSCodeSetup-x64.exe"

    Write-Step "Downloading VS Code installer..."
    $success = Invoke-DownloadWithProgress -Url $script:VSCodeInstallerUrl -OutputPath $installerPath
    if (-not $success) {
        Write-Err "Download failed."
        Write-Warn "You can install VS Code manually from https://code.visualstudio.com"
        return $false
    }
    Write-Ok "Download complete"

    Write-Info "All context menu options will be enabled automatically."

    # Close VS Code if running (so installer can replace files cleanly)
    $codeProc = Get-Process code -ErrorAction SilentlyContinue
    if ($codeProc) {
        Write-Info "Closing running VS Code instances for installation..."
        Stop-Process -Name code -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    $vsLogPath = Join-Path $env:TEMP "vscode-install.log"
    Write-Info "Installer binary path: $installerPath ($((Get-Item $installerPath).Length) bytes)"
    Write-Info "Installer log path: $vsLogPath"

    # Inno Setup silent flags - checks all boxes including context menu entries
    $argsArray = @("/VERYSILENT", "/NORESTART", "/LOG=`"$vsLogPath`"", "/MERGETASKS=desktopicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath,!runcode")
    
    $success = Invoke-WithBounceProgress -Message "Running VS Code installer (this may take a minute)" -FilePath $installerPath -ArgumentList $argsArray
    
    if (Test-Path $vsLogPath) {
        if ($global:EzVerbose) {
            Write-Info "=== VS Code Inno Setup Full Installation Log ==="
            Get-Content $vsLogPath | ForEach-Object { Write-Info "  [LOG] $_" }
        }
        elseif (-not $success) {
            Write-Warn "=== VS Code Inno Setup Failure Log Tail ($vsLogPath) ==="
            Get-Content $vsLogPath | Select-Object -Last 15 | ForEach-Object { Write-Warn "  [LOG] $_" }
        }
    }

    if (-not $success) {
        Write-Err "VS Code installer failed."
        Write-Warn "You can install VS Code manually from https://code.visualstudio.com"
        return $false
    }

    # Clean up
    Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue

    # Verify VS Code via fresh process (picks up real registry PATH)
    Start-Sleep -Seconds 3
    Write-Info "Verifying VS Code installation via fresh process..."
    
    try {
        $codeCheck = cmd.exe /c "code --version 2>&1" | Select-Object -First 1
        if ($codeCheck -and $codeCheck -match '^\d+\.') {
            Write-Ok "VS Code installed with full context menu integration (v$codeCheck)"
            # Also refresh current session PATH for extension installs
            Update-SessionPath
            return $true
        }
    }
    catch { }

    # Fallback: refresh session and try locally
    Update-SessionPath
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        Write-Ok "VS Code installed with full context menu integration"
        return $true
    }
    else {
        Write-Warn "VS Code installed but 'code' command not found yet."
        Write-Info "It will be available after you restart your terminal."
        return $true
    }
}

# ===== Extensions ============================================================

function Install-VSCodeExtensions {
    <#
    .SYNOPSIS
        Installs VS Code extensions using the `code` CLI.
    #>
    Write-Step "Installing VS Code extensions..."

    # Close VS Code if running (extensions install cleaner)
    $codeProc = Get-Process code -ErrorAction SilentlyContinue
    if ($codeProc) {
        Write-Info "Closing VS Code for extension installation..."
        Stop-Process -Name code -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    $codeCmd = (Get-Command code).Source

    foreach ($ext in $script:Extensions) {
        Write-Log "INFO" "Installing extension $ext..."
        $argsArray = @("--install-extension", $ext, "--force")
        Invoke-WithBounceProgress -Message "Installing $ext" -FilePath $codeCmd -ArgumentList $argsArray | Out-Null
    }

    Write-Ok "Extensions installed ($($script:Extensions.Count) total)"
}

# ===== Configuration =========================================================

function Backup-VSCodeConfig {
    <#
    .SYNOPSIS
        Backs up existing VS Code settings, keybindings, and snippets
        to Documents\ez-cpp-backups\ before overwriting.
    .OUTPUTS
        Boolean - $true if any files were backed up, $false if nothing to back up.
    #>
    $backupRoot = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "ez-cpp-backups"
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupDir = Join-Path $backupRoot $timestamp

    $backedUp = $false

    foreach ($cfg in $script:ConfigFiles) {
        $existing = $cfg.Local
        if (Test-Path $existing) {
            if (-not $backedUp) {
                # Create backup directory on first file found
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }
            $destName = $cfg.Remote -replace '/', '_'
            Copy-Item -Path $existing -Destination (Join-Path $backupDir $destName) -Force
            $backedUp = $true
        }
    }

    if ($backedUp) {
        Write-Warn "Existing VS Code config backed up to:"
        Write-Info "$backupDir"
    }

    return $backedUp
}

function Install-VSCodeConfig {
    <#
    .SYNOPSIS
        Downloads settings, keybindings, and snippets from the GitHub repo.
        Existing config is backed up to Documents\ez-cpp-backups\ first.
    #>
    Write-Step "Configuring VS Code settings, keybindings, and snippets..."

    # Backup existing config before overwriting
    Backup-VSCodeConfig | Out-Null

    foreach ($cfg in $script:ConfigFiles) {
        $url = "$($script:RepoBaseUrl)/$($cfg.Remote)"
        $dest = $cfg.Local

        # Ensure destination directory exists
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
            $ProgressPreference = 'Continue'
            Write-Info "Applied: $(Split-Path $dest -Leaf)"
        }
        catch {
            Write-Warn "Could not download $(Split-Path $dest -Leaf): $_"
        }
    }

    Write-Ok "VS Code configured"
}
