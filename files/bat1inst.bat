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
echo Preparing for setup ...
echo Please wait for a while ...
echo.
echo It is recommended to install VS Code manually and check all the 5 checkboxes while installing.
echo.
@REM "%cd%\7-Zip\7z.exe" x "%cd%\vscode64.7z.001" -o"%cd%" -y >nul
@REM start "" /w "%cd%\vscode64.exe"
@REM del "%cd%\vscode64.exe"
call powershell.exe -ExecutionPolicy Bypass -File download-vsc.ps1
echo.
echo installing MinGW
echo.
"%cd%\7-Zip\7z" x "%cd%\MinGW14.7z.001" -o"c:\" -y
echo. 
echo MinGW installed
echo.
echo setting path to environment variable
echo.
call powershell.exe -ExecutionPolicy Bypass -File check-gcc14.ps1
echo.
echo finished...
echo.
@REM pause
call bat2set.bat