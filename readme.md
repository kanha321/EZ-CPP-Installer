# EZ CPP 😎



### This program streamlines the setup process for the following tasks:

1. **C Compiler (MinGW) Installation**: This step, often considered the most challenging (for beginners), is fully automated❤️.
2. **Path Addition**
3. **VS Code Extension Installation**
4. **VS Code Settings Configuration**
5. **VS Code Customised Keyboard Shortcuts**
6. **User Snippets Installation**

> Note: 
> - VS Code needs to be installed manually. Automating this step would increase the program size to over 400MB and potentially decrease stability.
> - An older version of VS Code is available in `v3.0` to ensure compatibility with older versions of Windows, specifically Windows 7.
> - Looking for a way to install Visual Studio Code via winget with the "Open with Code" context menu option. This would reduce installer size and truly automate the setup while avoiding manual registry edits, though it will require internet access.

## Installation Procedure  [(Download↓)](https://github.com/kanha321/EZ-CPP-Installer/releases)

1. Extract the zip file
2. Run the "install-c" file.
 ![](files\illustration2.png)
3. During the VS Code installation, ensure all 5 checkboxes are selected.

That's it! Enjoy your streamlined setup. 😎

## Changelog
(older versions are uploaded on [mediafire](https://www.bit.ly/c-installer) it is not recommended to try those scripts as they are just bad most of the time they just refuse to work)

### Version 1.0

- Resolved the 'looping' issue where Windows could not find minGW.exe. The minGW.exe file has been removed as some antivirus software were detecting it as a virus. The loop command has also been removed, so the program terminates after executing the given set of instructions, even if the installation fails.

### Version 2.0

- Updated VS Code.
- Created a separate file for path setting.

### Version 3.0 (Supports Windows 7 32-bit and above)

- The script can now recognise the OS architecture and execute accordingly.
- Updated 7-zip to version 22.01.
- Updated VS Code to version 1.70 (also supports Windows 7).
- Fully automated the process, eliminating the need to go to the C user snippets file (increased the program size by 10MB).
- Removed the need for a separate file for path setting.
- Added some important extensions for C/C++ (increased the program size by ~60MB).
- Introduced a new theme: HackTheBox.
- All operations are now handled by 7-zip, enhancing stability.

### Version 3.1

- No more support for 32-bit versions
- No more support for windows 7, 8 and 8.1 too (due to newer version of vs code)
- Updated VS code to version 1.92
- Updated 7-zip to version 24.07
- Nothing much to do here as the script is already pretty stable...

### Version 4.0

- Fix VS Code installation for users having ' ' space character in their user names
- VS Code and mingw is now in split zip
- updated VS Code
- supported os, windows 10 and 11 64-bit

### Changelogs will be at release sections from now on...
