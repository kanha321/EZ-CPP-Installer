@echo off
echo.
echo configuring vs code...
echo.
echo finding vs code on your system...
if exist "C:\Users\%username%\AppData\Local\Programs\Microsoft VS Code\Code.exe" (
    goto install
) else if exist "C:\Program Files\Microsoft VS Code\Code.exe" (
    goto install
) else (
    echo VS code not found on your given path.
    echo checking for vs code in environment variables...
    call check-vsc.bat
    pause
)
:install

tasklist /fi "ImageName eq code.exe" /fo csv 2>NUL | find /I "code.exe">NUL
if "%ERRORLEVEL%"=="0" (
	echo.
    echo vs code is running
    echo trying to close vs-code
    Taskkill /IM code.exe /F
    echo.
)
echo.
echo.
echo Installing required extensions
echo.
%cd%\7-Zip\7z x "%cd%\vs_code_settings\vscode.7z" -o"c:\users\%username%" -y
echo.
echo.
echo Configuring Settings and Keybindings
%cd%\7-Zip\7z x "%cd%\vs_code_settings\Code.7z" -o"C:\Users\%username%\AppData\Roaming" -y
echo.
echo.
echo Installation Complete
pause