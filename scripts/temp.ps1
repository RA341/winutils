# Temp Files Cleaner
# Requires Administrator privileges

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "`nTemp Files Cleaner" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

# Temp locations to clean
$tempLocations = @(
    "$env:TEMP",
    "$env:USERPROFILE\AppData\Local\Temp",
    "C:\Windows\Temp",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache",
    "$env:USERPROFILE\AppData\Local\CrashDumps"
)

$totalSizeBefore = 0
$totalSizeAfter = 0

Write-Host "`nCalculating current temp file size..." -ForegroundColor Yellow

foreach ($location in $tempLocations) {
    if (Test-Path $location) {
        try {
            $size = (Get-ChildItem $location -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $totalSizeBefore += $size
        } catch {}
    }
}

$sizeMB = [math]::Round($totalSizeBefore / 1MB, 2)
Write-Host "Current temp files: $sizeMB MB" -ForegroundColor Cyan

$response = Read-Host "`nDelete temp files? (y/N)"
if ($response -notmatch '^[Yy]') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nCleaning temp files..." -ForegroundColor Yellow

foreach ($location in $tempLocations) {
    if (Test-Path $location) {
        Write-Host "Cleaning: $location" -ForegroundColor Gray
        
        Get-ChildItem $location -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}

# Clear Windows Update cache
Write-Host "Cleaning Windows Update cache..." -ForegroundColor Gray
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service wuauserv -ErrorAction SilentlyContinue

# Clear Recycle Bin
Write-Host "Emptying Recycle Bin..." -ForegroundColor Gray
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# Calculate space saved
Write-Host "`nCalculating space saved..." -ForegroundColor Yellow

foreach ($location in $tempLocations) {
    if (Test-Path $location) {
        try {
            $size = (Get-ChildItem $location -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $totalSizeAfter += $size
        } catch {}
    }
}

$savedMB = [math]::Round(($totalSizeBefore - $totalSizeAfter) / 1MB, 2)
Write-Host "`nCleaning complete!" -ForegroundColor Green
Write-Host "Space freed: $savedMB MB" -ForegroundColor Green
