# Windows Cache Cleanup PowerShell Script
# This script provides comprehensive cache cleanup with detailed reporting
# Run as Administrator for best results

param(
    [switch]$Force,
    [switch]$Quiet
)

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Function to write colored output
function Write-Status {
    param([string]$Message, [string]$Status = "Info")
    
    switch ($Status) {
        "Success" { Write-Host "✓ $Message" -ForegroundColor Green }
        "Warning" { Write-Host "⚠ $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "✗ $Message" -ForegroundColor Red }
        "Info"    { Write-Host "ℹ $Message" -ForegroundColor Cyan }
        default   { Write-Host $Message }
    }
}

# Function to get folder size
function Get-FolderSize {
    param([string]$Path)
    
    if (Test-Path $Path) {
        try {
            $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
            return [math]::Round($size / 1MB, 2)
        } catch {
            return 0
        }
    }
    return 0
}

# Function to safely remove directory contents
function Clear-DirectoryContents {
    param([string]$Path, [string]$Name)
    
    if (Test-Path $Path) {
        $sizeBefore = Get-FolderSize -Path $Path
        
        try {
            Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            
            $sizeAfter = Get-FolderSize -Path $Path
            $freed = $sizeBefore - $sizeAfter
            
            if ($freed -gt 0) {
                Write-Status "$Name cleaned: ${freed} MB freed" "Success"
                return $freed
            } else {
                Write-Status "$Name was already clean" "Info"
                return 0
            }
        } catch {
            Write-Status "Failed to clean $Name`: $($_.Exception.Message)" "Error"
            return 0
        }
    } else {
        Write-Status "$Name directory not found" "Warning"
        return 0
    }
}

# Main cleanup function
function Start-CacheCleanup {
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "Windows Cache Cleanup Script (PowerShell)" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Get initial disk space
    $diskBefore = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}
    $freeSpaceBefore = [math]::Round($diskBefore.FreeSpace / 1GB, 2)
    
    Write-Status "Initial free space on C: drive: $freeSpaceBefore GB" "Info"
    Write-Host ""
    
    $totalFreed = 0
    
    # Confirmation
    if (-not $Force -and -not $Quiet) {
        $confirm = Read-Host "Do you want to proceed with cache cleanup? (Y/N)"
        if ($confirm -ne "Y" -and $confirm -ne "y") {
            Write-Status "Cleanup cancelled by user" "Warning"
            return
        }
    }
    
    Write-Host "Starting cleanup process..." -ForegroundColor Yellow
    Write-Host ""
    
    # 1. User Temp Directory
    Write-Status "[1/8] Cleaning User Temp directory..." "Info"
    $freed = Clear-DirectoryContents -Path "$env:LOCALAPPDATA\Temp" -Name "User Temp"
    $totalFreed += $freed
    
    # 2. System Temp Directory
    Write-Status "[2/8] Cleaning System Temp directory..." "Info"
    $freed = Clear-DirectoryContents -Path "$env:TEMP" -Name "System Temp"
    $totalFreed += $freed
    
    # 3. Windows Temp Directory
    Write-Status "[3/8] Cleaning Windows Temp directory..." "Info"
    $freed = Clear-DirectoryContents -Path "$env:WINDIR\Temp" -Name "Windows Temp"
    $totalFreed += $freed
    
    # 4. Pip Cache
    Write-Status "[4/8] Cleaning Pip cache..." "Info"
    try {
        pip cache purge 2>$null
        Write-Status "Pip cache purged using pip command" "Success"
    } catch {
        Write-Status "Pip command not available, cleaning manually" "Warning"
    }
    $freed = Clear-DirectoryContents -Path "$env:LOCALAPPDATA\pip\cache" -Name "Pip Cache"
    $totalFreed += $freed
    
    # 5. Docker Cache
    Write-Status "[5/8] Cleaning Docker cache..." "Info"
    try {
        $dockerRunning = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
        if ($dockerRunning) {
            docker system prune -a --volumes -f 2>$null
            Write-Status "Docker cache cleaned using docker command" "Success"
        } else {
            $freed = Clear-DirectoryContents -Path "$env:LOCALAPPDATA\Docker" -Name "Docker Cache"
            $totalFreed += $freed
        }
    } catch {
        $freed = Clear-DirectoryContents -Path "$env:LOCALAPPDATA\Docker" -Name "Docker Cache"
        $totalFreed += $freed
    }
    
    # 6. Chrome Cache
    Write-Status "[6/8] Cleaning Chrome cache..." "Info"
    $chromeRunning = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
    if ($chromeRunning) {
        Write-Status "Chrome is running. Please close Chrome first." "Warning"
    } else {
        $freed = Clear-DirectoryContents -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" -Name "Chrome Cache"
        $totalFreed += $freed
    }
    
    # 7. Windows Update Cache
    Write-Status "[7/8] Cleaning Windows Update cache..." "Info"
    try {
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        $freed = Clear-DirectoryContents -Path "$env:WINDIR\SoftwareDistribution\Download" -Name "Windows Update Cache"
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        $totalFreed += $freed
    } catch {
        Write-Status "Could not clean Windows Update cache (requires admin privileges)" "Warning"
    }
    
    # 8. Recycle Bin
    Write-Status "[8/8] Emptying Recycle Bin..." "Info"
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Status "Recycle Bin emptied" "Success"
    } catch {
        Write-Status "Could not empty Recycle Bin" "Warning"
    }
    
    # Final disk space check
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "Cleanup Summary" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    
    $diskAfter = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}
    $freeSpaceAfter = [math]::Round($diskAfter.FreeSpace / 1GB, 2)
    $spaceFreed = $freeSpaceAfter - $freeSpaceBefore
    
    Write-Status "Free space before: $freeSpaceBefore GB" "Info"
    Write-Status "Free space after: $freeSpaceAfter GB" "Info"
    Write-Status "Total space freed: $spaceFreed GB" "Success"
    
    Write-Host ""
    Write-Status "Cleanup completed successfully!" "Success"
    
    # Create log entry
    $logEntry = @"
$(Get-Date): Cache cleanup completed
- Free space before: $freeSpaceBefore GB
- Free space after: $freeSpaceAfter GB  
- Total space freed: $spaceFreed GB
"@
    
    $logFile = Join-Path $PSScriptRoot "cleanup_log.txt"
    Add-Content -Path $logFile -Value $logEntry
    Write-Status "Log saved to: $logFile" "Info"
}

# Run the cleanup
Start-CacheCleanup

if (-not $Quiet) {
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}