@echo off
:: Quick Cache Cleanup Script - Windows
:: This is a simplified version for regular maintenance
:: Run this weekly to keep your system clean

echo ========================================
echo Quick Cache Cleanup
echo ========================================
echo.

:: Clean temp directories silently
echo Cleaning temporary files...
rmdir /s /q "%LOCALAPPDATA%\Temp" 2>nul
mkdir "%LOCALAPPDATA%\Temp" 2>nul

del /f /s /q "%TEMP%\*" 2>nul
for /d %%x in ("%TEMP%\*") do rmdir /s /q "%%x" 2>nul

:: Clean pip cache
echo Cleaning Python pip cache...
pip cache purge >nul 2>&1
rmdir /s /q "%LOCALAPPDATA%\pip\cache" 2>nul

:: Clean Docker cache if available
echo Cleaning Docker cache...
docker system prune -f >nul 2>&1
if errorlevel 1 (
    rmdir /s /q "%LOCALAPPDATA%\Docker" 2>nul
)

:: Empty Recycle Bin
echo Emptying Recycle Bin...
PowerShell.exe -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" 2>nul

echo.
echo ✓ Quick cleanup completed!
echo.
echo Current disk space:
PowerShell.exe -NoProfile -Command "Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq 'C:'} | Select-Object @{Name='Free Space (GB)';Expression={[math]::Round($_.FreeSpace/1GB,2)}}"

echo.
pause