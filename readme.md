<div align="center">

# EZ CPP 😎

[![Version](https://img.shields.io/github/v/release/kanha321/EZ-CPP-Installer?style=for-the-badge&color=blue)](https://github.com/kanha321/EZ-CPP-Installer/releases)
[![Platform](https://img.shields.io/badge/Platform-Windows_10_%7C_11_(64--bit)-0078D4?style=for-the-badge&logo=windows)](https://microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell)](https://docs.microsoft.com/powershell/)
[![GCC](https://img.shields.io/badge/GCC-14%2B_(UCRT64)-00599C?style=for-the-badge&logo=cplusplus)](https://gcc.gnu.org/)

**A one-command, fully automated installer for a complete C/C++ Development Environment on Windows.**  
*(Specially designed for **Competitive Programming** efficiency!)*

---

</div>

## 📌 Table of Contents
- [What It Automates](#-what-it-automates)
- [Requirements](#-requirements)
- [Installation Procedure](#-installation-procedure)
- [Uninstallation Procedure](#-uninstallation-procedure)
- [Project History](#-project-history)

---

## ⚡ What It Automates

### This program streamlines the setup process for the following tasks:
*(Specially designed for **Competitive Programming** efficiency!)*

1. **C Compiler (MinGW) Installation**: This step, often considered the most challenging (for beginners), is fully automated❤️.
2. **Path Addition**
3. **VS Code Extension Installation**
4. **VS Code Settings Configuration**
5. **VS Code Customised Keyboard Shortcuts**
6. **User Snippets Installation**
7. **🌟 NEW in v6.0: Automatic Visual Studio Code Installation!** (The official IDE is now dynamically downloaded and installed completely silently behind the scenes!)
8. **🌟 NEW in v6.0: Automated Cleanup Uninstaller!** (A dedicated uninstaller script allows you to easily reverse the entire setup with a single command.)

> ~~Note:~~
> - ~~VS Code needs to be installed manually. Automating this step would increase the program size to over 400MB and potentially decrease stability.~~
> - ~~An older version of VS Code is available in `v3.0` to ensure compatibility with older versions of Windows, specifically Windows 7.~~
> - ~~Looking for a way to install Visual Studio Code via winget with the "Open with Code" context menu option. This would reduce installer size and truly automate the setup while avoiding manual registry edits, though it will require internet access.~~

---

## 📋 Requirements

| Requirement | Specification |
| :--- | :--- |
| **Supported OS** | Windows 10 (64-bit) or Windows 11 (64-bit) |
| **PowerShell** | Windows PowerShell 5.1 or higher *(pre-installed on all Windows 10/11 PCs out-of-the-box)* |
| **Internet** | Active internet connection required to download GCC compiler, VS Code, and extensions |

---

## 🚀 Installation Procedure  [(Download↓)](https://github.com/kanha321/EZ-CPP-Installer/releases)

~~1. Extract the zip file~~  
~~2. Run the "install-c" file.~~  
~~3. During the VS Code installation, ensure all 5 checkboxes are selected.~~

**New in Version 6.0!** Run everything effortlessly.

### Option 1: Simple Double-Click (Recommended)
1. Download or clone this repository.
2. Double-click **`install.bat`** (automatically requests Administrator rights).

### Option 2: One-Line Command
Open **Terminal (Admin)** or **PowerShell (Admin)** and run:
```powershell
irm https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main/install.ps1 | iex
```

That's it! Enjoy your streamlined setup. 😎

---

## 🧹 Uninstallation Procedure

To clean up or reset your C/C++ environment:

### Option 1: Simple Double-Click
Double-click **`uninstall.bat`** (automatically requests Administrator rights).

### Option 2: One-Line Command
Open **Terminal (Admin)** or **PowerShell (Admin)** and run:
```powershell
irm https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main/uninstaller/uninstall.ps1 | iex
```

---

## 📜 Project History

The installer has evolved significantly since its inception, moving from basic batch scripts to an advanced PowerShell module.

| Version | Release Date | Key Changelog & Evolution Highlights |
| :---: | :---: | :--- |
| **`v6.0`** 🚀 | **Aug 2026** *(Current)* | **Complete modular redesign.** Fast cloud-hosted setup with auto-elevation, animated progress bars, zero software pre-requisites, and a clean uninstaller. |
| **`v5.0`** 🌐 | **Jun 2025** | Transitioned to downloading the VS Code installer dynamically from microsoft.com instead of bundling it in a zip. Upgraded the compiler to MinGW GCC 14. |
| **`v4.0`** 🛠️ | **Nov 2024** | Addressed an installation bug where Windows usernames containing spaces would fail. Split VS Code and MinGW into separate zip assets. Focused scope entirely on Windows 10/11 64-bit. |
| **`v3.1`** ⚡ | **Aug 2024** | Dropped legacy support for 32-bit architecture and Windows 7/8/8.1 due to modern VS Code compatibility limits. Upgraded VS Code to v1.92 and 7-Zip to v24.07. |
| **`v3.0`** 🌟 | **Dec 2023** | **Massive feature update.** Introduced OS architecture detection, updated to VS Code v1.70. Fully automated the injection of VS Code snippets, extensions, and applied the "HackTheBox" theme. Consolidated operations using 7-Zip for better stability. |
| **`v2.0`** 🔧 | **Nov 1, 2022** | Updated the bundled VS Code version and refactored the environment PATH logic into a dedicated script. |
| **`v1.0`** 🎉 | **Nov 3, 2021** | **The original release.** Solved major "looping" bugs where Windows failed to locate `minGW.exe` (which was removed due to false-positive antivirus flags). Basic functionality established. |

> [!NOTE]
> **Legacy Archives:** Older legacy zip versions (v1-v2) are archived on [mediafire](https://www.bit.ly/c-installer) but are no longer recommended as they were often brittle and prone to failure on modern machines. Please use the latest script instead!