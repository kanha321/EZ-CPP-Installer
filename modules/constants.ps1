<#
.SYNOPSIS
    Central configuration constants for EZ C/C++ Installer.
.DESCRIPTION
    All paths, extension lists, and config file mappings in one place.
    URLs are set by install.ps1 before this module is loaded.
#>


# ── MinGW ────────────────────────────────────────────────────────────────────
$script:MingwArchiveUrl = "$script:ReleaseUrl/MinGW14.7z"
$script:MingwInstallDir = "C:\MinGW14"
$script:MingwBinPath = "C:\MinGW14\bin"

# ── 7za ──────────────────────────────────────────────────────────────────────
$script:SevenZaUrl = "$script:RepoBaseUrl/7za.exe"

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
