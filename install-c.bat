@echo off
for /f %%a in ('wmic os get osarchitecture ^| find /i "bit"') do set "bits=%%a"

if %bits%==64-bit (
    color 0a
    cd files
    call bat1inst.bat
) else (
    color 04
    cls
    echo 32-bit system detected
    echo.
    echo you have downloaded the wrong file
    echo.
    echo goto https://github.com/kanha321/EZ-CPP-Installer and download the v3.0 32-bit version
    echo.
    pause
    exit
)