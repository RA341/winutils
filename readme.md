# Winutils 

a collection of pwsh scripts for windows



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