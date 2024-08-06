@echo off

set file=temp.txt

code --help>%file%

>nul find "--diff" %file% && (
    echo.
    echo vs code is installed, proceeding to install
    echo extensions, settings, Keybindings and user snippets
    echo.
) || (
    echo vs code may not be installed properly,
    echo run "install-c" file again and 
    echo "check all the 5 checkboxes in the installer"
    pause
    exit
    echo.
)
if exist %file% (del %file%) else (echo file not found)