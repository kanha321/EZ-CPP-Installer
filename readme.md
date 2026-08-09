# EZ CPP 😎

## Table of Contents
- [What It Automates](#what-it-automates)
- [Installation Procedure](#installation-procedure)
- [Project History](#📜-project-history)

## What It Automates

### This program streamlines the setup process for the following tasks:
*(Specially designed for **Competitive Programming** efficiency!)*

1. **C/C++ Compiler (MinGW GCC 14)**: Automated download, extraction, and verification.
2. **System PATH Configuration**: Safely adds GCC and VS Code to system PATH without duplicates.
3. **VS Code Installation**: Silently installs VS Code with context menu ("Open with Code") integration.
4. **VS Code Extensions**: Installs essential C/C++ extension packs and Code Runner automatically.
5. **Pre-Configured Settings & Snippets**: Deploys optimal C/C++ settings, keyboard shortcuts, and snippets.
6. **Automated Uninstaller**: Reverses setup and cleans environment with a single command (`uninstall.bat`).

## Installation Procedure

### Option 1: One-Line Command (Recommended)
Open **PowerShell** or **Terminal** and run:
```powershell
irm https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main/install.ps1 | iex
```

### Option 2: Double-Click Batch Launcher
1. Download or clone this repository.
2. Double-click **`install.bat`** (it automatically requests Administrator rights).

That's it! Enjoy your streamlined C/C++ setup. 😎

## 📜 Project History

The installer has evolved significantly since its inception, moving from basic batch scripts to an advanced PowerShell module.

*   **v6.0 (Current)** - Complete modular redesign. Fast cloud-hosted setup with auto-elevation, animated progress bars, zero software pre-requisites, and a clean uninstaller.
*   **v5.0** - Transitioned to downloading VS Code dynamically from Microsoft servers instead of bundling in zip archives. Upgraded compiler to MinGW GCC 14.
*   **v4.0** - Fixed installation bugs for Windows usernames containing spaces. Focused scope on 64-bit Windows 10/11.
*   **v3.1** - Upgraded VS Code to v1.92 and 7-Zip to v24.07. Dropped legacy 32-bit and Windows 7/8 support.
*   **v3.0 (Dec 2023)** - Automated injection of VS Code snippets, extensions, and custom themes.
*   **v2.0 (Nov 1, 2022)** - Updated bundled VS Code version and refactored environment PATH logic.
*   **v1.0 (Nov 3, 2021)** - The original release establishing basic MinGW setup.