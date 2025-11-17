# Add to PATH and Refresh Environment
# Requires Administrator privileges for System PATH

param(
    [string]$PathToAdd,
    [switch]$System,
    [switch]$User
)

function Add-ToPath {
    param(
        [string]$NewPath,
        [string]$Scope = "User"  # "User" or "Machine"
    )
    
    # Validate path exists
    if (-not (Test-Path $NewPath)) {
        Write-Host "Warning: Path does not exist: $NewPath" -ForegroundColor Yellow
        $continue = Read-Host "Add anyway? (y/N)"
        if ($continue -notmatch '^[Yy]') {
            return $false
        }
    }
    
    # Get current PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $Scope)
    
    # Check if already in PATH
    $pathArray = $currentPath -split ';' | ForEach-Object { $_.Trim() }
    if ($pathArray -contains $NewPath) {
        Write-Host "Path already exists in $Scope PATH: $NewPath" -ForegroundColor Yellow
        return $false
    }
    
    # Add to PATH
    $newPathValue = "$currentPath;$NewPath"
    [Environment]::SetEnvironmentVariable("Path", $newPathValue, $Scope)
    
    Write-Host "Added to $Scope PATH: $NewPath" -ForegroundColor Green
    return $true
}

function Refresh-Environment {
    Write-Host "`nRefreshing environment variables..." -ForegroundColor Yellow
    
    # Refresh PATH in current session
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:Path = "$machinePath;$userPath"
    
    Write-Host "Environment refreshed in current session!" -ForegroundColor Green
    Write-Host "Note: Other open PowerShell/CMD windows need to be restarted." -ForegroundColor Gray
}

# Main script
Write-Host "`nAdd to PATH Environment Variable" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Check for admin if System scope requested
if ($System -and -NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Administrator privileges required for System PATH." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Get path if not provided
if (-not $PathToAdd) {
    Write-Host "`nEnter the path to add to PATH:" -ForegroundColor Yellow
    $PathToAdd = Read-Host "Path"
}

if (-not $PathToAdd) {
    Write-Host "No path provided. Exiting." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Expand environment variables in path
$PathToAdd = [Environment]::ExpandEnvironmentVariables($PathToAdd)

# Choose scope if not specified
if (-not $System -and -not $User) {
    Write-Host "`nAdd to:" -ForegroundColor Yellow
    Write-Host "  [1] User PATH (current user only)" -ForegroundColor Gray
    Write-Host "  [2] System PATH (all users - requires admin)" -ForegroundColor Gray
    $choice = Read-Host "Choice (1/2)"
    
    if ($choice -eq "2") {
        $System = $true
        # Check admin
        if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Host "Administrator privileges required for System PATH." -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        $User = $true
    }
}

# Add to appropriate scope
$scope = if ($System) { "Machine" } else { "User" }
$added = Add-ToPath -NewPath $PathToAdd -Scope $scope

# Refresh environment
if ($added) {
    Refresh-Environment
    
    Write-Host "`nVerifying PATH..." -ForegroundColor Yellow
    if ($env:Path -like "*$PathToAdd*") {
        Write-Host "✓ Path is now active in current session!" -ForegroundColor Green
    }
} else {
    Write-Host "`nNo changes made." -ForegroundColor Yellow
}

Read-Host "`nPress Enter to exit"