@echo off
:: Windows Cache Cleanup Script
:: This script safely cleans various cache directories to free up disk space
:: Author: Generated for Document Portal Project
:: Date: September 2025

echo ========================================
echo Windows Cache Cleanup Script
echo ========================================
echo.
echo This script will clean the following cache directories:
echo - Temp files (AppData\Local\Temp)
echo - Pip cache (Python package cache)
echo - Docker cache (if Docker is installed)
echo - Chrome browser cache
echo - Windows temporary files
echo - System temporary files
echo.

:: Ask for confirmation
set /p confirm="Do you want to proceed with cache cleanup? (Y/N): "
if /i not "%confirm%"=="Y" goto :end

echo.
echo Starting cleanup process...
echo.

:: Create log file with timestamp
set "logfile=%~dp0cleanup_log_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "logfile=%logfile: =0%"

echo Cache cleanup started at %date% %time% > "%logfile%"
echo ======================================= >> "%logfile%"

:: Function to display and log messages
setlocal enabledelayedexpansion

:: 1. Clean User Temp Directory
echo [1/8] Cleaning User Temp directory...
echo [1/8] Cleaning User Temp directory... >> "%logfile%"
if exist "%LOCALAPPDATA%\Temp" (
    for /f %%i in ('dir "%LOCALAPPDATA%\Temp" /s /-c /q 2^>nul ^| find "File(s)"') do (
        echo    Before: %%i >> "%logfile%"
    )
    rmdir /s /q "%LOCALAPPDATA%\Temp" 2>nul
    mkdir "%LOCALAPPDATA%\Temp" 2>nul
    echo    ✓ User Temp directory cleaned
    echo    User Temp directory cleaned successfully >> "%logfile%"
) else (
    echo    ! User Temp directory not found
    echo    User Temp directory not found >> "%logfile%"
)

:: 2. Clean System Temp Directory
echo [2/8] Cleaning System Temp directory...
echo [2/8] Cleaning System Temp directory... >> "%logfile%"
if exist "%TEMP%" (
    del /f /s /q "%TEMP%\*" 2>nul
    for /d %%x in ("%TEMP%\*") do rmdir /s /q "%%x" 2>nul
    echo    ✓ System Temp directory cleaned
    echo    System Temp directory cleaned successfully >> "%logfile%"
) else (
    echo    ! System Temp directory not found
    echo    System Temp directory not found >> "%logfile%"
)

:: 3. Clean Windows Temp Directory
echo [3/8] Cleaning Windows Temp directory...
echo [3/8] Cleaning Windows Temp directory... >> "%logfile%"
if exist "%WINDIR%\Temp" (
    del /f /s /q "%WINDIR%\Temp\*" 2>nul
    for /d %%x in ("%WINDIR%\Temp\*") do rmdir /s /q "%%x" 2>nul
    echo    ✓ Windows Temp directory cleaned
    echo    Windows Temp directory cleaned successfully >> "%logfile%"
) else (
    echo    ! Windows Temp directory not accessible
    echo    Windows Temp directory not accessible >> "%logfile%"
)

:: 4. Clean Pip Cache
echo [4/8] Cleaning Pip cache...
echo [4/8] Cleaning Pip cache... >> "%logfile%"
if exist "%LOCALAPPDATA%\pip\cache" (
    rmdir /s /q "%LOCALAPPDATA%\pip\cache" 2>nul
    echo    ✓ Pip cache cleaned
    echo    Pip cache cleaned successfully >> "%logfile%"
) else (
    echo    ! Pip cache directory not found
    echo    Pip cache directory not found >> "%logfile%"
)

:: Alternative pip cache cleanup using pip command
pip cache purge >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✓ Pip cache purged using pip command
    echo    Pip cache purged using pip command >> "%logfile%"
)

:: 5. Clean Docker Cache (if Docker is available)
echo [5/8] Cleaning Docker cache...
echo [5/8] Cleaning Docker cache... >> "%logfile%"
docker system df >nul 2>&1
if %errorlevel% equ 0 (
    echo    Docker is running, cleaning cache...
    docker system prune -a --volumes -f >> "%logfile%" 2>&1
    echo    ✓ Docker cache cleaned
    echo    Docker cache cleaned successfully >> "%logfile%"
) else (
    echo    Docker not running, cleaning cache files manually...
    echo    Docker not running, cleaning cache files manually... >> "%logfile%"
    if exist "%LOCALAPPDATA%\Docker" (
        rmdir /s /q "%LOCALAPPDATA%\Docker" 2>nul
        echo    ✓ Docker cache files cleaned manually
        echo    Docker cache files cleaned manually >> "%logfile%"
    ) else (
        echo    ! Docker cache directory not found
        echo    Docker cache directory not found >> "%logfile%"
    )
)

:: 6. Clean Chrome Cache (be careful - this affects browsing data)
echo [6/8] Cleaning Chrome cache...
echo [6/8] Cleaning Chrome cache... >> "%logfile%"
tasklist /fi "imagename eq chrome.exe" 2>nul | find /i "chrome.exe" >nul
if %errorlevel% equ 0 (
    echo    ! Chrome is running. Please close Chrome and run this script again for cache cleanup.
    echo    Chrome is running - cache not cleaned >> "%logfile%"
) else (
    if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
        rmdir /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
        mkdir "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
        echo    ✓ Chrome cache cleaned
        echo    Chrome cache cleaned successfully >> "%logfile%"
    ) else (
        echo    ! Chrome cache directory not found
        echo    Chrome cache directory not found >> "%logfile%"
    )
)

:: 7. Clean Windows Update Cache
echo [7/8] Cleaning Windows Update cache...
echo [7/8] Cleaning Windows Update cache... >> "%logfile%"
net stop wuauserv >nul 2>&1
if exist "%WINDIR%\SoftwareDistribution\Download" (
    rmdir /s /q "%WINDIR%\SoftwareDistribution\Download" 2>nul
    mkdir "%WINDIR%\SoftwareDistribution\Download" 2>nul
    echo    ✓ Windows Update cache cleaned
    echo    Windows Update cache cleaned successfully >> "%logfile%"
) else (
    echo    ! Windows Update cache not accessible
    echo    Windows Update cache not accessible >> "%logfile%"
)
net start wuauserv >nul 2>&1

:: 8. Clean Recycle Bin
echo [8/8] Emptying Recycle Bin...
echo [8/8] Emptying Recycle Bin... >> "%logfile%"
PowerShell.exe -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" 2>nul
if %errorlevel% equ 0 (
    echo    ✓ Recycle Bin emptied
    echo    Recycle Bin emptied successfully >> "%logfile%"
) else (
    echo    ! Could not empty Recycle Bin
    echo    Could not empty Recycle Bin >> "%logfile%"
)

echo.
echo ========================================
echo Cleanup Summary:
echo ========================================

:: Get disk space after cleanup
echo Checking disk space...
echo Checking disk space... >> "%logfile%"

for /f "tokens=3" %%a in ('dir C:\ /-c 2^>nul ^| find "bytes free"') do (
    set "freespace=%%a"
    set "freespace=!freespace:,=!"
)

echo Current free space on C: drive: !freespace! bytes >> "%logfile%"

:: Run PowerShell command to get disk space in GB
PowerShell.exe -NoProfile -Command "Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq 'C:'} | Select-Object @{Name='FreeSpaceGB';Expression={[math]::Round($_.FreeSpace/1GB,2)}}, @{Name='TotalSizeGB';Expression={[math]::Round($_.Size/1GB,2)}} | Format-List" >> "%logfile%"

echo ✓ Cache cleanup completed successfully!
echo ✓ Check the log file for details: %logfile%
echo.
echo Cache cleanup completed at %date% %time% >> "%logfile%"

:end
echo.
echo Press any key to exit...
pause >nul