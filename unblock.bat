@echo off
:: ============================================================
:: unblock.bat
:: Removes every firewall rule created by block.bat, restoring
:: normal network access for the previously blocked executables.
:: ============================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires Administrator privileges. Requesting elevation...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Removing AutodeskBlocker firewall rules...
netsh advfirewall firewall delete rule name="AutodeskBlocker_In" >nul 2>&1
netsh advfirewall firewall delete rule name="AutodeskBlocker_Out" >nul 2>&1

echo Done. All AutodeskBlocker firewall rules have been removed.
pause
