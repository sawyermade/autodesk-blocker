@echo off
:: ============================================================
:: block-list.bat
:: Wrapper around block.bat: reads directory paths (one per
:: line) from block-list.txt, next to this script, and runs
:: block.bat once per directory.
::
:: Generate/refresh block-list.txt by running discover.bat, or
:: create/edit it by hand -- one directory path per line. Blank
:: lines and lines starting with # are ignored.
:: ============================================================

:: ---- Re-launch elevated if not already Administrator ----
:: (done once here so block.bat doesn't prompt for UAC on every
:: directory in the list)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires Administrator privileges. Requesting elevation...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "LIST_FILE=%~dp0block-list.txt"

if not exist "%LIST_FILE%" (
    echo ERROR: "%LIST_FILE%" not found.
    echo Run discover.bat to generate it, or create it yourself with one
    echo directory path per line.
    pause
    exit /b 1
)

:: Suppress block.bat's per-run "Press any key..." so the loop
:: doesn't stop after every directory.
set "BLOCKER_NO_PAUSE=1"

set /a DIR_COUNT=0

for /f "usebackq eol=# delims=" %%D in ("%LIST_FILE%") do (
    set /a DIR_COUNT+=1
    echo.
    echo ================================================================
    echo Blocking: %%D
    echo ================================================================
    call "%~dp0block.bat" "%%D"
)

echo.
if %DIR_COUNT% equ 0 (
    echo "%LIST_FILE%" has no directory entries. Nothing to do.
) else (
    echo All %DIR_COUNT% director^(y/ies^) from "%LIST_FILE%" processed.
)
pause
