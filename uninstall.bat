@echo off
:: EZ C/C++ Uninstaller - Double-click to run
:: Automatically elevates to Administrator

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell -ExecutionPolicy Bypass -File "%~dp0uninstaller\uninstall.ps1"
pause
