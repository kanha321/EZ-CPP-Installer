# EZ C/C++ Installer 😎 (v6.0)

[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011%20(64--bit)-blue.svg)](https://microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/powershell/)
[![GCC](https://img.shields.io/badge/GCC-14%2B%20(UCRT64)-green.svg)](https://gcc.gnu.org/)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

A one-command, fully automated installer for a complete **C/C++ Development Environment** on Windows. Specially designed for **Competitive Programming** and modern C/C++ development.

---

## Table of Contents
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Installation Guide](#-installation-guide)
- [Verbose & Debug Mode](#-verbose--debug-mode)
- [Uninstallation Guide](#-uninstallation-guide)
- [Project History](#-project-history)

---

## ⚡ Features

1. **GCC 14 Compiler (MinGW-w64 UCRT64)**: Automated download, extraction, and clean PATH setup.
2. **Visual Studio Code**: Automated silent installation with context menu integration (`Open with Code` for files & folders).
3. **VS Code Extensions**: Automatically installs the latest versions directly from VS Code Marketplace:
   - `ms-vscode.cpptools-extension-pack` (Microsoft C/C++ Extension Pack)
   - `formulahendry.code-runner` (1-Click Code Runner)
   - `Catppuccin.catppuccin-vsc` (Catppuccin Theme)
   - `yandeu.five-server` (Development Live Server)
   - `vscjava.vscode-java-pack` (Java Extension Pack)
   - `DivyanshuAgrawal.competitive-programming-helper` (CPH)
4. **Pre-configured Settings & Shortcuts**: Optimized `settings.json`, custom keybindings, and C/C++/Java user snippets.
5. **Automatic Config Backup**: Existing VS Code configurations are backed up to `Documents\ez-cpp-backups\<timestamp>\` before applying updates.
6. **Pac-Man Progress Bar**: High-throughput 512 KB streaming downloads with an animated Pac-Man progress indicator.
7. **Robust Real-Process Verification**: Verifies PATH changes using fresh processes (`cmd.exe`) without requiring a system reboot.
8. **Clean Uninstaller**: Dedicated 1-click uninstaller (`uninstall.bat`) to reverse changes cleanly.

---

## 📋 Prerequisites

### What You Need:
- **OS**: Windows 10 or Windows 11 (64-bit).
- **Internet**: Active internet connection.
- **Permissions**: Administrator rights (*`install.bat` handles elevation automatically*).
- **PowerShell**: Windows PowerShell 5.1+ (*pre-installed on 100% of Windows 10/11 PCs*).

### What You DO NOT Need:
- ❌ **No Node.js, Python, or Git** required.
- ❌ **No 7-Zip** required (standalone `7za.exe` included).
- ❌ **No manual environment variable / PATH editing**.

---

## 🚀 Installation Guide

### Option 1: Simple Double-Click (Recommended)
1. Download or clone this repository.
2. Double-click **`install.bat`**.
3. Accept the Administrator prompt (UAC).
4. Sit back and watch it complete!

### Option 2: One-Line PowerShell Command
Open **Terminal (Admin)** or **PowerShell (Admin)** and run:
```powershell
irm https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main/install.ps1 | iex
```

---

## 🔍 Verbose & Debug Mode

To inspect detailed step-by-step logs, execution trace, and Inno Setup log summaries, run with `--verbose` or `-v`:

```cmd
install.bat --verbose
```
or in PowerShell:
```powershell
.\install.ps1 -Verbose
```

Logs are automatically saved to `ez-cpp-install.log` in your user directory.

---

## 🧹 Uninstallation Guide

To clean up MinGW or VS Code configurations:
1. Double-click **`uninstall.bat`**.
2. Or run:
```cmd
uninstall.bat
```

---

## 📜 Project History

- **v6.0 (Current)** - Modular cloud-hosted architecture. Added auto-elevating batch launchers (`install.bat` / `uninstall.bat`), Pac-Man progress bar, automatic VS Code config backups, fresh process PATH verification, and full uninstaller.
- **v5.0** - Transitioned to dynamic VS Code installer fetching from Microsoft CDN. Upgraded compiler to MinGW GCC 14.
- **v4.0** - Fixed space-in-username path bug. Focused scope on 64-bit Windows 10/11.
- **v3.1** - Upgraded VS Code to v1.92 and 7-Zip to v24.07. Dropped legacy 32-bit/Win7 support.
- **v3.0** - Automated VS Code snippets, extensions, and custom themes injection using 7-Zip.
- **v2.0** - Refactored environment PATH logic into dedicated script modules.
- **v1.0** - Initial public release.