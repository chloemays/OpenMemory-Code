# Claude Code MCP Server Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: "Tools available but no resources" or "Resources: []"

**What it means:** ✅ **This is NORMAL and means everything is working!**

Claude Code is successfully connected to the OpenMemory MCP server. The MCP server has no resources to show because:
- You haven't initialized any projects yet
- Resources only appear after you run `openmemory-init` in a project directory

**What you should see:**
```
Tools: mcp__openmemory-code-global__* (48 tools)
Resources: []
```

**This is GOOD** - it means:
- ✅ Claude Code configuration is correct
- ✅ MCP server is running
- ✅ Backend services (ports 8080, 8081) are running
- ✅ Everything is connected properly

**Next step:**
```powershell
cd C:\Your\Project
openmemory-init
```

After initializing a project, resources will appear.

---

### Issue 2: "No MCP servers currently configured"

**What it means:** ❌ Claude Code can't find the MCP server configuration

**Possible causes:**
1. You didn't run `start-openmemory.bat` yet
2. The `.claude.json` file wasn't created/updated
3. Claude Code is looking in a different location

**Solution:**
```powershell
# Run the MCP setup script
.\setup-claude-mcp.ps1 -Force

# Verify config was created
Test-Path $env:USERPROFILE\.claude.json

# View the config
Get-Content $env:USERPROFILE\.claude.json

# Restart Claude Code COMPLETELY (close all windows)
```

---

### Issue 3: "MCP server tools not available" or "Connection failed"

**What it means:** ❌ Claude Code found the config but can't connect

**Possible causes:**
1. OpenMemory backend services aren't running
2. Node.js isn't installed or not in PATH
3. MCP server files aren't built
4. Claude Code wasn't fully restarted

**Solution:**

**Step 1:** Verify services are running
```powershell
# Check if ports are listening
Test-NetConnection -ComputerName localhost -Port 8080
Test-NetConnection -ComputerName localhost -Port 8081

# If not running, start them
.\start-openmemory.ps1
```

**Step 2:** Verify Node.js is installed
```powershell
node --version
# Should show v18.0.0 or higher
```

**Step 3:** Verify MCP server is built
```powershell
Test-Path ".\.ai-agents\context-injection\mcp-server\dist\index.js"
# Should return True

# If false, build it
cd .ai-agents\context-injection\mcp-server
npm install
npm run build
```

**Step 4:** Fully restart Claude Code
```powershell
# Kill all Claude processes
Get-Process *claude* | Stop-Process -Force

# Start Claude Code again
```

---

### Issue 4: Claude Code still running old configuration

**What it means:** ❌ You updated the config but Claude Code didn't reload it

**Solution:**
```powershell
# FULLY RESTART CLAUDE CODE
# This means:
# 1. Close ALL Claude Code windows
# 2. Kill all processes
Get-Process *claude* | Stop-Process -Force

# 3. Wait a few seconds
Start-Sleep -Seconds 3

# 4. Start Claude Code again
# (Use your normal method - Start menu, command line, etc.)
```

**Important:** Reloading the terminal window is NOT enough. You must kill the entire Claude Code process.

---

### Issue 5: JSON syntax error / Config corrupted

**What it means:** ❌ The `.claude.json` file has invalid JSON

**This should NEVER happen** with the new robust script, but if it does:

**Solution:**
```powershell
# Find backup files
Get-ChildItem "$env:USERPROFILE\.claude.json.backup-*" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5

# Restore the most recent backup
Copy-Item "$env:USERPROFILE\.claude.json.backup-YYYYMMDD-HHMMSS" `
          "$env:USERPROFILE\.claude.json" -Force

# Or run the setup script again (it will fix the JSON)
.\setup-claude-mcp.ps1 -Force
```

---

## Understanding MCP Server States

### State 1: Not Configured
```
No MCP servers available
```
**Action:** Run `start-openmemory.bat`

---

### State 2: Configured but Services Not Running
```
MCP server "openmemory-code-global" connection failed
Error: ECONNREFUSED localhost:8080
```
**Action:** Run `start-openmemory.ps1` to start services

---

### State 3: Configured and Connected (No Projects)
```
Tools: 48 available
Resources: []
```
**Action:** ✅ This is correct! Initialize a project with `openmemory-init`

---

### State 4: Fully Operational
```
Tools: 48 available
Resources: [project-memory, context-data, ...]
```
**Action:** ✅ Everything working! Start coding!

---

## Quick Diagnostic Commands

### Check Configuration
```powershell
# Does config file exist?
Test-Path $env:USERPROFILE\.claude.json

# What's in it?
Get-Content $env:USERPROFILE\.claude.json | ConvertFrom-Json |
    Select-Object -ExpandProperty mcpServers

# Is OpenMemory MCP configured?
(Get-Content $env:USERPROFILE\.claude.json | ConvertFrom-Json).mcpServers.PSObject.Properties.Name
```

### Check Services
```powershell
# Are backend services running?
Test-NetConnection localhost -Port 8080 | Select-Object TcpTestSucceeded
Test-NetConnection localhost -Port 8081 | Select-Object TcpTestSucceeded

# Test health endpoints
Invoke-WebRequest http://localhost:8080/health
Invoke-WebRequest http://localhost:8081/health
```

### Check Node.js
```powershell
# Is Node.js installed?
node --version

# Is it in PATH?
where.exe node

# Can it run the MCP server?
node ".\.ai-agents\context-injection\mcp-server\dist\index.js" --version
```

### Check Claude Code Process
```powershell
# Is Claude Code running?
Get-Process *claude* -ErrorAction SilentlyContinue

# What processes are using Claude-related ports?
netstat -ano | findstr "8080 8081 8083 8084"
```

---

## The Golden Rules

1. **ALWAYS fully restart Claude Code** after changing configuration
   - Closing terminals is NOT enough
   - Kill the entire process: `Get-Process *claude* | Stop-Process`

2. **Services MUST be running** before using MCP server
   - Backend: `http://localhost:8080`
   - Context Manager: `http://localhost:8081`
   - Run `start-openmemory.ps1` if they're not

3. **Empty resources is NORMAL** until you initialize projects
   - Tools available + empty resources = **working correctly**
   - Run `openmemory-init` in your project to add resources

4. **Check the logs** if services won't start
   - Located in: `logs\openmemory-TIMESTAMP.log`
   - Or: `$env:USERPROFILE\.openmemory-global\logs\`

5. **Backups are automatic** - never fear breaking config
   - Every change creates a timestamped backup
   - Restore with: `Copy-Item *.backup-TIMESTAMP .claude.json`

---

## Getting Help

If none of these solutions work:

1. **Collect diagnostic info:**
   ```powershell
   # Save to a file
   @"
   Node Version: $(node --version)
   Config Exists: $(Test-Path $env:USERPROFILE\.claude.json)
   Backend Running: $(Test-NetConnection localhost -Port 8080 -InformationLevel Quiet)
   Context Manager Running: $(Test-NetConnection localhost -Port 8081 -InformationLevel Quiet)
   MCP Server Built: $(Test-Path .\.ai-agents\context-injection\mcp-server\dist\index.js)
   Claude Processes: $(Get-Process *claude* -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName)
   "@ | Out-File diagnostic.txt
   ```

2. **Check the logs:**
   ```powershell
   # View recent logs
   Get-ChildItem logs\*.log |
       Sort-Object LastWriteTime -Descending |
       Select-Object -First 1 |
       Get-Content -Tail 50
   ```

3. **Create an issue** on GitHub with the diagnostic info and logs

---

## Pro Tips

- **Alias the restart command:**
  ```powershell
  # Add to PowerShell profile
  function Restart-ClaudeCode {
      Get-Process *claude* | Stop-Process -Force
      Write-Host "Claude Code stopped. Start it manually now." -ForegroundColor Green
  }
  Set-Alias -Name rcc -Value Restart-ClaudeCode
  ```

- **Check health before starting Claude:**
  ```powershell
  # Quick health check script
  $backend = Invoke-WebRequest http://localhost:8080/health -UseBasicParsing -ErrorAction SilentlyContinue
  $context = Invoke-WebRequest http://localhost:8081/health -UseBasicParsing -ErrorAction SilentlyContinue

  if ($backend -and $context) {
      Write-Host "✓ All services healthy - Claude Code ready!" -ForegroundColor Green
  } else {
      Write-Host "✗ Services not running - run start-openmemory.ps1" -ForegroundColor Red
  }
  ```

- **Watch the logs in real-time:**
  ```powershell
  # Follow the latest log file
  Get-ChildItem logs\*.log |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1 |
      Get-Content -Wait -Tail 20
  ```
