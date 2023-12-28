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
> - An older version of VS Code is used to ensure compatibility with older versions of Windows, specifically Windows 7.

## Installation Procedure

1. Execute the "install-c" file.
2. During the VS Code installation, ensure all 5 checkboxes are selected.

That's it! Enjoy your streamlined setup. 😎

## Changelog

### Version 1.0

- Resolved the 'looping' issue where Windows could not find minGW.exe. The minGW.exe file has been removed as some antivirus software were detecting it as a virus. The loop command has also been removed, so the program terminates after executing the given set of instructions, even if the installation fails.

### Version 2.0

- Updated VS Code.
- Created a separate file for path setting.

### Version 3.0

- The script can now recognise the OS architecture and execute accordingly.
- Updated 7-zip to version 22.01.
- Updated VS Code to version 1.70 (also supports Windows 7).
- Fully automated the process, eliminating the need to go to the C user snippets file (increased the program size by 10MB).
- Removed the need for a separate file for path setting.
- Added some important extensions for C/C++ (increased the program size by ~60MB).
- Introduced a new theme: HackTheBox.
- All operations are now handled by 7-zip, enhancing stability.
