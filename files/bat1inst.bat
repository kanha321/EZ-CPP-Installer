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
"%cd%\7-Zip\7z.exe" x "%cd%\vscode64.7z.001" -o"%cd%" -y >nul
start "" /w "%cd%\vscode64.exe"
del "%cd%\vscode64.exe"
echo.
echo installing MinGW
echo.
"%cd%\7-Zip\7z" x "%cd%\MinGW.7z.001" -o"c:\" -y
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