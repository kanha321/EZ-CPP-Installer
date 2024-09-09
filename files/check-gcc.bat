@echo off

set file=temp.txt

gcc --help>%file%

>nul find "-pass-exit-codes" %file% && (
    echo.
    echo no need to set path to environment variable
    echo.
) || (
    echo setting path
    echo.
    setx path "%path%;C:\MinGW\bin"
    echo.
)
if exist %file% (del %file%) else (echo file not found)