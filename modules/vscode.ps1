<#
.SYNOPSIS
    VS Code installation and configuration module for EZ C/C++ Installer.
.DESCRIPTION
    Handles VS Code installation (direct installer / winget / skip),
    extension installation via CLI, and settings/keybindings/snippets setup.
    Requires: utils.ps1 to be loaded first.
#>

# Configuration is loaded from constants.ps1:
#   $script:VSCodeInstallerUrl, $script:RepoBaseUrl, $script:Extensions, $script:ConfigFiles

# ── Public Functions ─────────────────────────────────────────────────────────

function Install-VSCode {
    # ── Present Options ──────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │  Would you like to install Visual Studio Code?                   │" -ForegroundColor White
    Write-Host "  │                                                                  │" -ForegroundColor White
    Write-Host "  │  [Y] Yes, install VS Code (Recommended)                          │" -ForegroundColor Green
    Write-Host "  │      ✓ Full installer with context menu integration              │" -ForegroundColor DarkGray
    Write-Host "  │                                                                  │" -ForegroundColor White
    Write-Host "  │  [N] No, skip (I already have it or don't need it)               │" -ForegroundColor Yellow
    Write-Host "  └──────────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  Choice [Y/N]"

    switch ($choice.ToLower()) {
        "y" { return Install-VSCodeDirect }
        "n" { return Skip-VSCode }
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

    # Inno Setup silent flags — checks all boxes including context menu entries
    $argsArray = @("/VERYSILENT", "/NORESTART", "/MERGETASKS=`"!runcode,desktopicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath`"")
    
    $success = Invoke-WithBounceProgress -Message "Running VS Code installer (this may take a minute)" -FilePath $installerPath -ArgumentList $argsArray
    if (-not $success) {
        Write-Err "VS Code installer failed."
    }

    # Clean up
    Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue

    # Refresh session PATH so `code` command works immediately
    Update-SessionPath

    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        Write-Ok "VS Code installed with full context menu integration"
        return $true
    }
    else {
        Write-Warn "VS Code installed but 'code' command not found in current session."
        Write-Info "It will be available after you restart your terminal."
        return $true
    }
}



function Skip-VSCode {
    <#
    .SYNOPSIS
        Skips VS Code installation and checks if it's already accessible.
    #>
    Write-Warn "Skipping VS Code installation."
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd) {
        Write-Ok "VS Code found on PATH — will configure it."
        return $true
    }
    else {
        Write-Warn "VS Code not found on PATH. Extensions and settings will be skipped."
        return $false
    }
}

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

function Install-VSCodeConfig {
    <#
    .SYNOPSIS
        Downloads settings, keybindings, and snippets from the GitHub repo.
    #>
    Write-Step "Configuring VS Code settings, keybindings, and snippets..."

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
