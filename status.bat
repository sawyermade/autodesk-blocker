@echo off
:: ============================================================
:: status.bat
:: Lists every firewall rule currently created by block.bat,
:: showing direction, action, enabled state and the blocked
:: program path. Read-only; does not require elevation, but
:: some systems restrict rule visibility to Administrators.
:: ============================================================

echo ===============================================
echo   AutodeskBlocker - Active Firewall Rules
echo ===============================================
echo.

powershell -NoProfile -Command ^
  "$rules = Get-NetFirewallRule -DisplayName 'AutodeskBlocker_*' -ErrorAction SilentlyContinue; if (-not $rules) { Write-Host 'No AutodeskBlocker rules found.'; exit }; $rules | ForEach-Object { $app = ($_ | Get-NetFirewallApplicationFilter).Program; [PSCustomObject]@{Direction=$_.Direction; Action=$_.Action; Enabled=$_.Enabled; Program=$app} } | Sort-Object Program, Direction | Format-Table -AutoSize; Write-Host ''; Write-Host ('Total rules: {0}' -f $rules.Count)"

if errorlevel 1 (
    echo.
    echo Could not query firewall rules. Try running this script as Administrator.
)

echo.
pause
