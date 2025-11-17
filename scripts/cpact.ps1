# Requires Administrator privileges

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "`nSimple VHDX Compactor" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Stop Docker and WSL
Write-Host "`nStopping Docker and WSL..." -ForegroundColor Yellow
Get-Process | Where-Object { $_.ProcessName -like "*docker*" } | Stop-Process -Force -ErrorAction SilentlyContinue
wsl --shutdown
Start-Sleep -Seconds 3

# Common VHDX locations
$vhdxFiles = @()

# Docker
$dockerVhdx = "$env:USERPROFILE\AppData\Local\Docker\wsl\disk\docker_data.vhdx"
if (Test-Path $dockerVhdx) {
    $vhdxFiles += $dockerVhdx
}

# WSL distributions
Get-ChildItem "$env:USERPROFILE\AppData\Local\Packages\*\LocalState\ext4.vhdx" -ErrorAction SilentlyContinue | ForEach-Object {
    $vhdxFiles += $_.FullName
}

if ($vhdxFiles.Count -eq 0) {
    Write-Host "`nNo VHDX files found in common locations." -ForegroundColor Red
    Write-Host "Please enter the full path to your VHDX file:" -ForegroundColor Yellow
    $manualPath = Read-Host "VHDX Path"
    if ($manualPath -and (Test-Path $manualPath)) {
        $vhdxFiles += $manualPath
    } else {
        Write-Host "File not found. Exiting." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Show found files
Write-Host "`nFound VHDX files:" -ForegroundColor Green
for ($i = 0; $i -lt $vhdxFiles.Count; $i++) {
    $size = [math]::Round((Get-Item $vhdxFiles[$i]).Length / 1GB, 2)
    Write-Host "  [$($i+1)] $($vhdxFiles[$i]) - $size GB" -ForegroundColor Gray
}

Write-Host "`nCompacting all files..." -ForegroundColor Yellow
$response = Read-Host "Continue? (y/N)"
if ($response -notmatch '^[Yy]') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Compact each file
foreach ($vhdx in $vhdxFiles) {
    $sizeBefore = [math]::Round((Get-Item $vhdx).Length / 1GB, 2)
    Write-Host "`nCompacting: $vhdx ($sizeBefore GB)" -ForegroundColor Cyan
    
    $diskpartScript = @"
select vdisk file="$vhdx"
compact vdisk
exit
"@
    
    $scriptFile = "$env:TEMP\compact.txt"
    $diskpartScript | Out-File -FilePath $scriptFile -Encoding ASCII
    
    diskpart /s $scriptFile | Out-Null
    Remove-Item $scriptFile -ErrorAction SilentlyContinue
    
    $sizeAfter = [math]::Round((Get-Item $vhdx).Length / 1GB, 2)
    $saved = $sizeBefore - $sizeAfter
    Write-Host "Done: $sizeBefore GB -> $sizeAfter GB (Saved: $saved GB)" -ForegroundColor Green
}

Write-Host "`nAll files compacted successfully!" -ForegroundColor Green
