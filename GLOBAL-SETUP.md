# OpenMemory-Code Global Setup

This document explains how the automatic global command setup works.

## One-Command Complete Setup

Running `start-openmemory.bat` will automatically:

1. Check if global PowerShell commands are configured
2. If not configured, automatically set them up
3. Start all OpenMemory services
4. Display status and next steps

## Global Commands Available

After running `start-openmemory.bat` and restarting PowerShell, these commands work from ANY directory:

### `openmemory-init [project-path]`
Initialize a project for use with OpenMemory-Code.

```powershell
# Initialize current directory
openmemory-init

# Initialize specific directory
openmemory-init C:\Projects\MyApp

# Initialize relative path
openmemory-init ..\MyNewProject
```

### `start-openmemory [-Dev] [-Verbose] [-SkipLogging]`
Start all OpenMemory services from anywhere.

```powershell
# Start in production mode
start-openmemory

# Start in development mode (with tsx hot reload)
start-openmemory -Dev

# Start with verbose output
start-openmemory -Verbose

# Start without logging API
start-openmemory -SkipLogging
```

### `stop-openmemory`
Stop all OpenMemory services.

```powershell
stop-openmemory
```

## How It Works

### Automatic Setup Process

1. **Detection**: `start-openmemory.bat` checks if global commands exist in PowerShell profile
2. **Setup**: If not found, runs `setup-global-commands.ps1 -Force` automatically
3. **Configuration**: Adds function definitions to your PowerShell profile
4. **Services**: Starts all OpenMemory services

### Manual Setup (Optional)

If you want to set up global commands without starting services:

```powershell
.\setup-global-commands.ps1
```

To force update existing configuration:

```powershell
.\setup-global-commands.ps1 -Force
```

## PowerShell Profile Location

Global commands are added to:
```
$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

This profile is automatically loaded every time you start PowerShell.

## Files Modified

- `start-openmemory.bat` - Enhanced to auto-setup global commands
- `setup-global-commands.ps1` - New script that configures PowerShell profile
- `README.md` - Updated with one-command setup instructions

## Troubleshooting

### Commands not found after setup

**Solution**: Close and reopen your PowerShell terminal, or reload profile:
```powershell
. $PROFILE
```

### Permission errors

**Solution**: Run PowerShell as Administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Want to remove global commands

Edit your PowerShell profile and remove the section between:
```powershell
# OpenMemory-Code Global Commands - START
# ... commands here ...
# OpenMemory-Code Global Commands - END
```

Profile location:
```powershell
notepad $PROFILE
```

## Benefits

- No need to navigate to OpenMemory-Code directory
- No need to remember full paths
- Works from any directory in any PowerShell session
- Consistent experience across all projects
- One-time setup, forever convenient
