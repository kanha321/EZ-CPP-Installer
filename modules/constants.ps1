<#
.SYNOPSIS
    Central configuration constants for EZ C/C++ Installer.
.DESCRIPTION
    All URLs, paths, extension lists, and config file mappings in one place.
    Change these to switch between local testing and production.
#>

# ── Base URLs ────────────────────────────────────────────────────────────────
# For production, use:
#   $script:RepoBaseUrl   = "https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main"
#   $script:ReleaseUrl    = "https://github.com/kanha321/EZ-CPP-Installer/releases/download/v6.0"
$script:RepoBaseUrl = "http://localhost:8000"
$script:ReleaseUrl = "http://localhost:8000"

# ── MinGW ────────────────────────────────────────────────────────────────────
$script:MingwArchiveUrl = "$script:ReleaseUrl/MinGW14.7z"
$script:MingwInstallDir = "C:\MinGW14"
$script:MingwBinPath = "C:\MinGW14\bin"

# ── 7za ──────────────────────────────────────────────────────────────────────
$script:SevenZaUrl = "$script:ReleaseUrl/7za.exe"

# ── VS Code ──────────────────────────────────────────────────────────────────
$script:VSCodeInstallerUrl = "https://update.code.visualstudio.com/latest/win32-x64/stable"

$script:Extensions = @(
    "ms-vscode.cpptools-extension-pack",
    "formulahendry.code-runner",
    "yandeu.five-server",
    "Catppuccin.catppuccin-vsc",
    "vscjava.vscode-java-pack",
    "DivyanshuAgrawal.competitive-programming-helper"
)

$script:ConfigFiles = @(
    @{ Remote = "config/settings.json"; Local = "$env:APPDATA\Code\User\settings.json" },
    @{ Remote = "config/keybindings.json"; Local = "$env:APPDATA\Code\User\keybindings.json" },
    @{ Remote = "config/snippets/c.json"; Local = "$env:APPDATA\Code\User\snippets\c.json" },
    @{ Remote = "config/snippets/cpp.json"; Local = "$env:APPDATA\Code\User\snippets\cpp.json" },
    @{ Remote = "config/snippets/java.json"; Local = "$env:APPDATA\Code\User\snippets\java.json" }
)
