@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: block.bat
:: Blocks all inbound and outbound traffic (Windows Firewall)
:: for every .exe found recursively inside a given directory,
:: including hidden files and hidden subdirectories.
::
:: Usage:
::   block.bat "C:\Path\To\Folder"
::   (or drag a folder onto this file, or double-click and
::    type the path when prompted)
:: ============================================================

:: ---- Re-launch elevated if not already Administrator ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires Administrator privileges. Requesting elevation...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '\"%~1\"' -Verb RunAs"
    exit /b
)

set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" (
    set /p TARGET_DIR=Enter the full path to the directory to block:
)

if "%TARGET_DIR%"=="" (
    echo No directory provided. Exiting.
    pause
    exit /b 1
)

if not exist "%TARGET_DIR%\" (
    echo ERROR: Directory "%TARGET_DIR%" does not exist.
    pause
    exit /b 1
)

set "RULE_IN=AutodeskBlocker_In"
set "RULE_OUT=AutodeskBlocker_Out"

echo.
echo Scanning "%TARGET_DIR%" for .exe files (recursive, including hidden)...
echo.

set /a COUNT=0

for /f "usebackq delims=" %%F in (`powershell -NoProfile -Command "Get-ChildItem -LiteralPath '%TARGET_DIR%' -Recurse -Force -File -Filter *.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName"`) do (
    set "EXE=%%F"
    echo Blocking: !EXE!
    netsh advfirewall firewall add rule name="%RULE_IN%" dir=in action=block program="!EXE!" enable=yes profile=any >nul
    netsh advfirewall firewall add rule name="%RULE_OUT%" dir=out action=block program="!EXE!" enable=yes profile=any >nul
    set /a COUNT+=1
)

echo.
if !COUNT! equ 0 (
    echo No .exe files were found under "%TARGET_DIR%".
) else (
    echo Done. Blocked !COUNT! executable^(s^) under "%TARGET_DIR%".
    echo Run status.bat to review active rules, or unblock.bat to remove them.
)

if not defined BLOCKER_NO_PAUSE pause
