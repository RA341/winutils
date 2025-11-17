# WU - Unified Script Manager
# Usage: wu <command> [args...]

param(
    [Parameter(Position = 0)]
    [string]$Command,
    
    [Parameter(Position = 1)]
    [string]$Arg1,
    
    [Parameter(Position = 2)]
    [string]$Arg2,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

# Configuration file location
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configDir = "$env:USERPROFILE\.wu"
$configFile = "$configDir\scripts.json"

# Initialize config directory
function Initialize-Config {
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    if (-not (Test-Path $configFile)) {
        $defaultScripts = @{
            "compact" = @{
                "path" = "$configDir\compact.ps1"
                "description" = "Compact VHDX files"
            }
            "clean" = @{
                "path" = "$configDir\clean.ps1"
                "description" = "Clean temp files"
            }
            "env" = @{
                "path" = "$configDir\env.ps1"
                "description" = "Manage PATH environment"
            }
        }
        $defaultScripts | ConvertTo-Json | Out-File $configFile -Encoding UTF8
    }
}

# Load scripts configuration
function Get-Scripts {
    if (Test-Path $configFile) {
        return Get-Content $configFile -Raw | ConvertFrom-Json
    }
    return @{}
}

# Save scripts configuration
function Save-Scripts {
    param($Scripts)
    $Scripts | ConvertTo-Json | Out-File $configFile -Encoding UTF8
}

# Add a new script
function Add-Script {
    param(
        [string]$Alias,
        [string]$ScriptPath,
        [string]$Description
    )
    
    if (-not $Alias -or -not $ScriptPath) {
        Write-Host "Usage: wu add <alias> <script-path> [description]" -ForegroundColor Yellow
        return
    }
    
    $ScriptPath = [Environment]::ExpandEnvironmentVariables($ScriptPath)
    
    # Convert relative path to absolute path
    if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
        $resolvedPath = Resolve-Path $ScriptPath -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Host "Error: Could not resolve path: $ScriptPath" -ForegroundColor Red
            return
        }
        $ScriptPath = $resolvedPath.Path
        Write-Host "Resolved to: $ScriptPath" -ForegroundColor Gray
    }
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "Error: Script not found: $ScriptPath" -ForegroundColor Red
        return
    }
    
    $scripts = Get-Scripts
    
    if ($scripts.PSObject.Properties.Name -contains $Alias) {
        Write-Host "Alias '$Alias' already exists. Overwrite? (y/N)" -ForegroundColor Yellow
        $response = Read-Host
        if ($response -notmatch '^[Yy]') {
            Write-Host "Cancelled." -ForegroundColor Gray
            return
        }
    }
    
    $scripts | Add-Member -NotePropertyName $Alias -NotePropertyValue @{
        "path" = $ScriptPath
        "description" = if ($Description) { $Description } else { "Custom script" }
    } -Force
    
    Save-Scripts $scripts
    Write-Host "✓ Added alias '$Alias' -> $ScriptPath" -ForegroundColor Green
}

# Update scripts from git repo
function Update-Scripts {
    Write-Host "`nUpdating WU scripts from repository..." -ForegroundColor Cyan
    
    $repoUrl = "https://github.com/RA341/winutils"
    $branch = "main"
    
    # Check if git is installed
    $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitInstalled) {
        Write-Host "Error: Git is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Git: https://git-scm.com/download/win" -ForegroundColor Yellow
        return
    }
    
    # Check if script directory is a git repo
    if (Test-Path "$scriptRoot\.git") {
        Write-Host "Pulling latest changes..." -ForegroundColor Gray
        Push-Location $scriptRoot
        try {
            git fetch origin $branch
            git reset --hard "origin/$branch"
            Write-Host "✓ Scripts updated successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Error updating: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "Script directory is not a git repository." -ForegroundColor Yellow
        Write-Host "Current location: $scriptRoot" -ForegroundColor Gray
        Write-Host "`nTo enable auto-updates, clone the repo:" -ForegroundColor Yellow
        Write-Host "  git clone -b $branch $repoUrl <target-folder>" -ForegroundColor Gray
        Write-Host "  Then move wu.ps1 to that folder" -ForegroundColor Gray
    }
}

# Remove a script
function Remove-Script {
    param([string]$Alias)
    
    if (-not $Alias) {
        Write-Host "Usage: wu remove <alias>" -ForegroundColor Yellow
        return
    }
    
    $scripts = Get-Scripts
    
    if ($scripts.PSObject.Properties.Name -notcontains $Alias) {
        Write-Host "Error: Alias '$Alias' not found" -ForegroundColor Red
        return
    }
    
    $scripts.PSObject.Properties.Remove($Alias)
    Save-Scripts $scripts
    Write-Host "✓ Removed alias '$Alias'" -ForegroundColor Green
}

# List all scripts
function Show-Scripts {
    $scripts = Get-Scripts
    
    Write-Host "`nWinutils - Available Aliases" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
    
    $scripts.PSObject.Properties | Sort-Object Name | ForEach-Object {
        $alias = $_.Name
        $info = $_.Value
        $exists = Test-Path $info.path
        $status = if ($exists) { "✓" } else { "✗" }
        $color = if ($exists) { "Green" } else { "Red" }
        
        Write-Host "  wu $alias" -ForegroundColor White -NoNewline
        Write-Host " $status" -ForegroundColor $color -NoNewline
        Write-Host " - $($info.description)" -ForegroundColor Gray
    }
    
    Write-Host "`nManagement Commands:" -ForegroundColor Cyan
    Write-Host "  wu list                       - Show this list" -ForegroundColor Gray
    Write-Host "  wu add <alias> <path> [desc]  - Add a new script" -ForegroundColor Gray
    Write-Host "  wu remove <alias>             - Remove a script" -ForegroundColor Gray
    Write-Host "  wu edit <alias>               - Edit script location" -ForegroundColor Gray
    Write-Host "  wu update                     - Update scripts from main git repo" -ForegroundColor Gray
    Write-Host ""
}

# Edit script path
function Edit-Script {
    param([string]$Alias)
    
    if (-not $Alias) {
        Write-Host "Usage: wu edit <alias>" -ForegroundColor Yellow
        return
    }
    
    $scripts = Get-Scripts
    
    if ($scripts.PSObject.Properties.Name -notcontains $Alias) {
        Write-Host "Error: Alias '$Alias' not found" -ForegroundColor Red
        return
    }
    
    $currentPath = $scripts.$Alias.path
    Write-Host "Current path: $currentPath" -ForegroundColor Gray
    $newPath = Read-Host "New path"
    
    if ($newPath) {
        # Convert relative to absolute
        if (-not [System.IO.Path]::IsPathRooted($newPath)) {
            $resolvedPath = Resolve-Path $newPath -ErrorAction SilentlyContinue
            if (-not $resolvedPath) {
                Write-Host "Error: Could not resolve path: $newPath" -ForegroundColor Red
                return
            }
            $newPath = $resolvedPath.Path
            Write-Host "Resolved to: $newPath" -ForegroundColor Gray
        }
        
        if (Test-Path $newPath) {
            $scripts.$Alias.path = $newPath
            Save-Scripts $scripts
            Write-Host "✓ Updated alias '$Alias'" -ForegroundColor Green
        } else {
            Write-Host "Error: Path not found: $newPath" -ForegroundColor Red
        }
    } else {
        Write-Host "No path provided." -ForegroundColor Gray
    }
}

# Run a script
function Invoke-Script {
    param(
        [string]$Alias,
        [string[]]$Args
    )
    
    $scripts = Get-Scripts
    
    if ($scripts.PSObject.Properties.Name -notcontains $Alias) {
        Write-Host "Error: Unknown command '$Alias'" -ForegroundColor Red
        Write-Host "Run 'wu list' to see available commands" -ForegroundColor Gray
        return
    }
    
    $scriptPath = $scripts.$Alias.path
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "Error: Script not found: $scriptPath" -ForegroundColor Red
        Write-Host "Run 'wu edit $Alias' to update the path" -ForegroundColor Gray
        return
    }
    
    Write-Host "Running: $Alias" -ForegroundColor Cyan
    Write-Host ""
    
    # Run the script with arguments
    if ($Args) {
        & $scriptPath @Args
    } else {
        & $scriptPath
    }
}

# Main logic
Initialize-Config

if (-not $Command) {
    Show-Scripts
    exit 0
}

switch ($Command.ToLower()) {
    "add" {
        $description = $RemainingArgs -join " "
        Add-Script -Alias $Arg1 -ScriptPath $Arg2 -Description $description
    }
    "update" {
        Update-Scripts
    }
    "remove" {
        Remove-Script -Alias $Arg1
    }
    "list" {
        Show-Scripts
    }
    "edit" {
        Edit-Script -Alias $Arg1
    }
    "help" {
        Show-Scripts
    }
    default {
        # Try to run as a script alias
        $allArgs = @($Arg1, $Arg2) + $RemainingArgs | Where-Object { $_ }
        Invoke-Script -Alias $Command -Args $allArgs
    }
}