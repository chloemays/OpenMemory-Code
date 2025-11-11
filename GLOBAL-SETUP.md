# OpenMemory-Code Global Setup

This document explains how the automatic global command setup works.

## One-Command Complete Setup

Running `start-openmemory.bat` will automatically:

1. Check if global PowerShell commands are configured
2. If not configured, automatically set them up
3. **Detect and configure Claude Code MCP server settings**
4. Start all OpenMemory services
5. Display status and next steps

### What Gets Configured Automatically

**Global PowerShell Commands:**
- `openmemory-init` - Initialize projects from anywhere
- `start-openmemory` - Start services from anywhere
- `stop-openmemory` - Stop services from anywhere

**Claude Code MCP Server:**
- Automatically finds Claude Code config files (searches multiple locations)
- Adds OpenMemory MCP server configuration
- Works with Claude Desktop and Claude Code CLI
- Creates config file if none exists
- **Safely modifies JSON with validation and backups**
- **UTF-8 without BOM encoding** (prevents JSON corruption)
- **Atomic file operations** (prevents partial writes)
- **Automatic recovery** from errors (restores from backup)
- Backs up existing configs before modification (timestamped)

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

1. **Global Commands Detection**: Checks if global commands exist in PowerShell profile
2. **Global Commands Setup**: If not found, runs `setup-global-commands.ps1 -Force` automatically
3. **Claude MCP Detection**: Searches for Claude Code config files in multiple locations:
   - `$env:USERPROFILE\.claude.json` (Claude Code CLI)
   - `$env:APPDATA\Claude\claude_desktop_config.json` (Claude Desktop)
   - Other standard locations
4. **Claude MCP Configuration**: Runs `setup-claude-mcp.ps1 -Force` to add OpenMemory MCP server
5. **Services Start**: Starts all OpenMemory services (Backend, Context Manager, Logging, OAuth)

### Manual Setup (Optional)

**Global Commands Only:**
```powershell
.\setup-global-commands.ps1
```

**Claude MCP Server Only:**
```powershell
.\setup-claude-mcp.ps1
```

**Force Update (both):**
```powershell
.\setup-global-commands.ps1 -Force
.\setup-claude-mcp.ps1 -Force
```

## Configuration Locations

### PowerShell Profile
Global commands are added to:
```
$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```
This profile is automatically loaded every time you start PowerShell.

### Claude Code MCP Configuration
The setup script searches for and configures:
```
$env:USERPROFILE\.claude.json                                    (Claude Code CLI - Primary)
$env:APPDATA\Claude\claude_desktop_config.json                   (Claude Desktop)
$env:USERPROFILE\.config\claude\config.json                      (Alternative)
```

**MCP Server Configuration Added:**
```json
{
  "mcpServers": {
    "openmemory-code-global": {
      "command": "node",
      "args": ["C:\\...\\OpenMemory-Code\\.ai-agents\\context-injection\\mcp-server\\dist\\index.js"],
      "env": {
        "CONTEXT_MANAGER_URL": "http://localhost:8081",
        "OPENMEMORY_URL": "http://localhost:8080"
      }
    }
  }
}
```

### Backup Files
Before modifying any config, a timestamped backup is created:
```
config-file.json.backup-20250110-143022
```

**Safety Features:**
- ✅ **JSON Validation**: All JSON is validated before and after writing
- ✅ **UTF-8 No BOM**: Uses proper encoding to prevent corruption
- ✅ **Atomic Writes**: Writes to temp file first, then moves atomically
- ✅ **Automatic Recovery**: Restores from backup if anything fails
- ✅ **Node.js Check**: Verifies Node.js is installed before configuring

## Files Created/Modified

- `start-openmemory.bat` - Enhanced with 3-step setup (commands + MCP + services)
- `setup-global-commands.ps1` - Configures PowerShell profile
- `setup-claude-mcp.ps1` - **NEW** - Configures Claude Code MCP server
- `README.md` - Updated with one-command setup instructions
- `GLOBAL-SETUP.md` - This file (comprehensive documentation)

## Expected MCP Server Behavior

**IMPORTANT:** After setup, if you see this in Claude Code:
```
Tools: mcp__openmemory-code-global__* (48 tools available)
Resources: []
```

**This is CORRECT and means everything is working!** ✅

Empty resources is normal until you initialize a project:
```powershell
cd C:\Your\Project
openmemory-init
```

See [CLAUDE-MCP-TROUBLESHOOTING.md](CLAUDE-MCP-TROUBLESHOOTING.md) for detailed explanations.

## Troubleshooting

**For MCP server issues, see [CLAUDE-MCP-TROUBLESHOOTING.md](CLAUDE-MCP-TROUBLESHOOTING.md)**

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

### Claude Code not seeing MCP server

**IMPORTANT:** You must FULLY RESTART Claude Code after configuration changes!
- Closing terminal windows is NOT enough
- You must kill all Claude processes and restart

**Solution 1**: Fully restart Claude Code:
```powershell
# Kill all Claude processes
Get-Process *claude* -ErrorAction SilentlyContinue | Stop-Process -Force

# Wait a moment
Start-Sleep -Seconds 3

# Start Claude Code again (via Start menu or command line)
```

**Solution 2**: Verify config file exists and is valid:
```powershell
# Check if config exists
Test-Path $env:USERPROFILE\.claude.json

# View config
Get-Content $env:USERPROFILE\.claude.json
```

**Solution 3**: Reconfigure MCP server:
```powershell
.\setup-claude-mcp.ps1 -Force

# Then FULLY restart Claude Code (see Solution 1)
```

### MCP server tools appearing but resources empty

**This is NORMAL!** ✅ It means services are connected correctly.

Resources only appear after you initialize projects:
```powershell
cd C:\Your\Project
openmemory-init
```

### MCP server tools not appearing at all

**Solution**: Ensure OpenMemory services are running:
```powershell
start-openmemory

# Verify services are up
Test-NetConnection localhost -Port 8080
Test-NetConnection localhost -Port 8081

# Test health endpoints
Invoke-WebRequest http://localhost:8080/health
Invoke-WebRequest http://localhost:8081/health
```

Then **FULLY RESTART Claude Code** (kill all processes)

### Config file location not found

**Solution**: The setup script will create it automatically. If you need to specify a custom location, manually create the config:
```powershell
$config = @{
    mcpServers = @{
        "openmemory-code-global" = @{
            command = "node"
            args = @("C:\Path\To\OpenMemory-Code\.ai-agents\context-injection\mcp-server\dist\index.js")
            env = @{
                CONTEXT_MANAGER_URL = "http://localhost:8081"
                OPENMEMORY_URL = "http://localhost:8080"
            }
        }
    }
}
# Safe JSON writing (no BOM, with validation)
$jsonOutput = $config | ConvertTo-Json -Depth 10 -Compress:$false
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$env:USERPROFILE\.claude.json", $jsonOutput, $utf8NoBom)
```

### Claude Code config corrupted/JSON errors

**Solution**: The script creates automatic backups. Find and restore the most recent backup:
```powershell
# List backups
Get-ChildItem "$env:USERPROFILE\.claude.json.backup-*" | Sort-Object LastWriteTime -Descending

# Restore most recent backup
Copy-Item "$env:USERPROFILE\.claude.json.backup-YYYYMMDD-HHMMSS" "$env:USERPROFILE\.claude.json" -Force

# Or run the setup script again (it will validate and fix)
.\setup-claude-mcp.ps1 -Force
```

## Benefits

- ✅ **One Command Setup**: Everything configured with `start-openmemory.bat`
- ✅ **Automatic Detection**: Finds Claude Code configs anywhere on your system
- ✅ **Safe Backups**: Never lose your existing configuration
- ✅ **Cross-Platform Ready**: Works with Claude Desktop and Claude Code CLI
- ✅ **No Manual Editing**: JSON configuration handled automatically
- ✅ **Global Access**: Commands work from any directory in any PowerShell session
- ✅ **Zero Path Memorization**: No need to remember installation directories
- ✅ **Consistent Experience**: Same setup across all projects
- ✅ **One-Time Setup**: Configure once, use forever
