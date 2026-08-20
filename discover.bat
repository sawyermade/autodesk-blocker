@echo off
:: ============================================================
:: discover.bat
:: Read-only scan for known Autodesk install/data locations:
:: Program Files, Program Files (x86), ProgramData, and every
:: user profile's AppData (Roaming + Local). Prints what it
:: finds plus a recursive .exe count, so you can copy paths
:: into block-list.bat. Makes no changes to the system.
::
:: Scanning other users' AppData folders requires Administrator,
:: so this self-elevates like the other scripts.
:: ============================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires Administrator privileges to read other users' AppData folders. Requesting elevation...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0discover.ps1"

echo.
pause
