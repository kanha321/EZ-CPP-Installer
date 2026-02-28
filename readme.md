# EZ-CPP-Installer 😎

The EZ C/C++ Installer is a streamline tool designed to take the headache out of setting up a C/C++ development environment on Windows. It automates the hardest parts of configuring MinGW and Visual Studio Code so you can start coding immediately.

### What it automates:
1. **C/C++ Compiler Setup**: Downloads, extracts, and configures MinGW GCC 14.
2. **Environment PATHs**: Automatically registers the compiler in your System PATH.
3. **VS Code Setup**: Downloads the official Visual Studio Code installer and runs it silently.
4. **VS Code Extensions**: Installs essential extensions natively (C/C++ IntelliSense, Code Runner).
5. **Pre-configured Workspace**: Merges optimal User Settings, Keyboard Shortcuts, and Code Snippets directly into your VS Code profile.

---

## 🚀 Installation Procedure (v6.0)

Gone are the days of downloading heavy zip files! The entire installer has been rewritten as a modern, single-command PowerShell script. It automatically downloads what it needs on the fly.

**Step 1:** Open PowerShell as Administrator.

**Step 2:** Paste and run the following command to begin:
```powershell
irm https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main/install.ps1 | iex
```

**Step 3:** The script will ask if you want to install VS Code (choose `Y` if you don't have it).
**Step 4:** Sit back and let the animated progress bars finish the setup!

### 🧹 Uninstallation

Need a clean slate? We provide an automated uninstaller that scrubs MinGW, VS Code, extensions, and cleans your PATH.
```powershell
irm https://raw.githubusercontent.com/kanha321/EZ-CPP-Installer/main/uninstaller/uninstall.ps1 | iex
```

---

## 📜 Project History

The installer has evolved significantly since its inception, moving from basic batch scripts to an advanced PowerShell module.

*   **v6.0 (Current)** - Complete rewrite into a modular, cloud-hosted PowerShell script. Eliminated huge zip downloads. Introduced auto-elevation, animated progress bars, detailed file logging, and a dedicated uninstaller.
*   **v5.0** - Transitioned to downloading the VS Code installer dynamically from microsoft.com instead of bundling it in a zip. Upgraded the compiler to MinGW GCC 14.
*   **v4.0** - Addressed an installation bug where Windows usernames containing spaces would fail. Split VS Code and MinGW into separate zip assets. Focused scope entirely on Windows 10/11 64-bit.
*   **v3.1** - Dropped legacy support for 32-bit architecture and Windows 7/8/8.1 due to modern VS Code compatibility limits. Upgraded VS Code to v1.92 and 7-Zip to v24.07.
*   **v3.0 (Dec 2023)** - Massive feature update. Introduced OS architecture detection, updated to VS Code v1.70. Fully automated the injection of VS Code snippets, extensions, and applied the "HackTheBox" theme. Consolidated operations using 7-Zip for better stability.
*   **v2.0 (Nov 1, 2022)** - Updated the bundled VS Code version and refactored the environment PATH logic into a dedicated script.
*   **v1.0 (Nov 3, 2021)** - The original release. Solved major "looping" bugs where Windows failed to locate `minGW.exe` (which was removed due to false-positive antivirus flags). Basic functionality established.

> **Note:** Older legacy zip versions (v1-v4) are archived on [mediafire](https://www.bit.ly/c-installer) but are no longer recommended as they were often brittle and prone to failure on modern machines. Please use the v6.0 script instead!