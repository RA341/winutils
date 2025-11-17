# Winutils 

A collection of useful pwsh scripts for windows

with a companion script manager for easy access

## Installtion

Prequisites

- Git
- Windows

1. Get the files
  ```
  git clone -b main https://github.com/RA341/winutils /path/to/script/folder
  ```
2. move to folder
  ```
  cd /path/to/script/folder
  ```
3. Bootstrap the folder by adding to env
  ```
  # wu manager script
  scripts/env.ps1 -PathToAdd . -User
  # all scripts now accessible by path
  scripts/env.ps1 -PathToAdd ./scripts -User 
  ```
4. Explore
  ```
  wu
  ```

## Env 

Usage: powershell# Interactive mode (will prompt for path and scope)
```
.\env.ps1
```

### Add to User PATH
```
.\env.ps1 -PathToAdd "C:\MyFolder" -User
```

### to System PATH (requires admin)
```
.\env.ps1 -PathToAdd "C:\MyFolder" -System
```
It will:

Check if the path already exists in PATH
Add it to User or System PATH
Refresh the current session so it takes effect immediately
Verify it was added successfully

No need to restart PowerShell!Retry