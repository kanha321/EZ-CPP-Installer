@echo off
for /f %%a in ('wmic os get osarchitecture ^| find /i "bit"') do set "bits=%%a"

if %bits%==32-bit (
    color 04
    cls
    echo 32-bit system detected
    echo.
    echo you have downloaded the wrong file
    echo.
    echo goto https://www.bit.ly/c-installer and download the 32-bit version
    echo.
    pause
    exit
)
echo.
color 0a
cls
set b=0
set c=0
set d=0
:menu
echo """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
echo "       _____      __ _____              _____              _          _  _                "
echo "      / ____|    / // ____|_      _    |_   _|            | |        | || |               "
echo "     | |        / /| |   _| |_  _| |_    | |   _ __   ___ | |_  __ _ | || |  ___  _ __    "
echo "     | |       / / | |  |_   _||_   _|   | |  | '_ \ / __|| __|/ _` || || | / _ \| '__|   "
echo "     | |____  / /  | |____|_|    |_|    _| |_ | | | |\__ \| |_| (_| || || ||  __/| |      "
echo "      \_____|/_/    \_____|            |_____||_| |_||___/ \__|\__,_||_||_| \___||_|      "
echo "                                                                                          "
echo """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
echo.
if %b%==1 (
    echo you can only enter 1, 2, or 3.
    echo try again
)
echo.
echo 1. install c and vs code ide.
echo 2. configure vs code settings.
echo 3. exit.
echo.
if %c% == 1 (
    echo compiler installed
    echo.
)
if %d% == 1 (
    echo all settings installed
    echo.
)
if %c% == 1 (
    if %d% == 1 (
        echo you can exit now
        echo.
    )
)
set /P a=enter 1, 2 or 3: 

echo. 
set /a result=%a%

if %result% == 1 (
    cls
    cd files
    call %cd%/files/bat1inst.bat
    set c=1
    cls
    goto :menu
) else if %result% == 2 (
    cls
    call %cd%/files/bat2set.bat
    set d=1
    cls
    goto :menu
) else if %result% == 3 (
    exit
) else (
    set b=1
    cls
    goto :menu
)