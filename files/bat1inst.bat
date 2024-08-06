@echo off
echo """"""""""""""""""""""""""""""""""""""""""""""""""
echo "        _____       __   _____                  "
echo "       / ____|     / /  / ____|_     _          "
echo "      | |         / /  | |   _| |_ _| |_        "
echo "      | |        / /   | |  |_   _|_   _|       "
echo "      | |____   / /    | |____|_|   |_|         "
echo "       \_____| /_/      \_____|                 "
echo "       _           _        _ _                 "
echo "      (_)         | |      | | |                "
echo "       _ _ __  ___| |_ __ _| | | ___ _ __       "
echo "      | | '_ \/ __| __/ _` | | |/ _ \ '__|      "
echo "      | | | | \__ \ || (_| | | |  __/ |         "
echo "      |_|_| |_|___/\__\__,_|_|_|\___|_|         "
echo "                                                "
echo """"""""""""""""""""""""""""""""""""""""""""""""""
echo.
echo.
for /f %%a in ('wmic os get osarchitecture ^| find /i "bit"') do set "bits=%%a"
@REM start %cd%\illustration2.png
@REM timeout /t 20
if %bits%==64-bit (
    start /w %cd%\vscode64.exe
) else (
    echo you have downloaded the wrong file, your system is 32-bit
    echo.
    echo go to https://github.com/kanha321/EZ-CPP-Installer and download vscode32.exe from vscode folder and install it
)
echo.
echo installing MinGW
echo.
%cd%\7-Zip\7z x "%cd%\MinGW.7z" -o"c:\" -y
echo. 
echo MinGW installed
echo.
echo setting path to environment variable
echo.
call check-gcc.bat
echo.
echo finished...
echo.
call bat2set.bat