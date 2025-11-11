# Startup Scripts Fixed!

## What Was Fixed

### 1. Fixed PowerShell Script Syntax Error (ROOT CAUSE FOUND!)
- **Issue**: Unicode symbols (✓, ✗, ⚠) causing PowerShell parser failures
- **Fix**: Replaced all Unicode symbols with ASCII equivalents:
  - ✓ → [OK]
  - ✗ → [X]
  - ⚠ → [!]
- **Additional fixes**:
  - Changed path separators from backslashes to forward slashes
  - Changed `&&` to `;` in command examples
  - Normalized line endings to Windows (CRLF)

### 1b. Fixed Log Redirection Issues
- **Issue**: PowerShell `Start-Process` doesn't allow redirecting stdout and stderr to the same file
- **Fix**: Created separate .log (stdout) and .err (stderr) files for each service

### 1c. Fixed NPM Execution on Windows
- **Issue**: `Start-Process` can't execute npm directly (it's a .cmd file, not a Win32 executable)
- **Fix**: Changed to execute via `cmd.exe /c npm ...` instead of calling npm directly

### 2. Added Logging API Server Startup
- **New Feature**: Automatically starts Logging API on port 8083
- **Build Check**: Automatically builds logging system if not built
- **Dependency Install**: Automatically runs `npm install` if needed

### 3. Enhanced Status Reporting
- Shows all 3 services status (Backend, Context Manager, Logging API)
- Shows MCP tool count (48 tools total)
- Indicates if logging/tracing has full or limited functionality

## How to Use

### Start Everything (One Command)

```bash
.\start-openmemory.bat
```

Or directly with PowerShell:

```powershell
.\start-openmemory.ps1
```

This will:
1. ✅ Check prerequisites (Node.js, backend, Context Manager, Logging system)
2. ✅ Build anything that's not built yet (backend, Context Manager, Logging)
3. ✅ Install dependencies if needed
4. ✅ Start OpenMemory Backend (port 8080)
5. ✅ Wait for Context Manager to auto-start (port 8081)
6. ✅ Start Logging API Server (port 8083)
7. ✅ Verify all services are healthy
8. ✅ Show status summary

### Stop Everything

```bash
.\stop-openmemory.bat
```

Or:

```powershell
.\stop-openmemory.ps1
```

This stops all 3 services (ports 8080, 8081, 8083).

### Optional Flags

```powershell
# Development mode (uses tsx instead of compiled)
.\start-openmemory.ps1 -Dev

# Verbose output
.\start-openmemory.ps1 -Verbose

# Skip Logging API (only start backend + context manager)
.\start-openmemory.ps1 -SkipLogging
```

## What Services Will Be Running

After running `start-openmemory.bat`, you'll have:

| Service | Port | Status | Purpose |
|---------|------|--------|---------|
| **OpenMemory Backend** | 8080 | ✅ Running | Core memory and OpenMemory operations |
| **Context Manager** | 8081 | ✅ Running | Project context aggregation |
| **Logging API** | 8083 | ✅ Running | File instrumentation, trace search, performance analysis |
| **MCP Server** | - | ✅ Ready | 48 tools available (42 OpenMemory + 6 Logging/Tracing) |

## MCP Tools Available

### Without Logging API (basic)
- ✅ 42 OpenMemory tools work fully
- ⚠️ 6 Logging/Tracing tools have limited functionality
  - `log_event` - Works (basic logging)
  - Other tools - Return "API not running" errors

### With Logging API (full) ✅
- ✅ All 48 tools work fully
- ✅ Full file instrumentation
- ✅ Execution trace search
- ✅ Performance analysis
- ✅ Hotspot detection

## Verification Checklist

After running the startup script:

- [ ] Backend responds at http://localhost:8080/health
- [ ] Context Manager responds at http://localhost:8081/health
- [ ] Logging API responds at http://localhost:8083/api/status
- [ ] No error messages in console
- [ ] Status summary shows all services running

## Troubleshooting

### "Port already in use" error

The script will ask if you want to stop existing services. Answer `y` to stop and restart.

### Logging API doesn't start

Check these:
1. `.ai-agents/logging` directory exists
2. Dependencies installed: `cd .ai-agents/logging && npm install`
3. System built: `cd .ai-agents/logging && npm run build`
4. Start script exists: `.ai-agents/logging/start-logging-api.js`

If automatic build fails, build manually:
```bash
cd .ai-agents/logging
npm install
npm run build
```

Then run the startup script again.

### Services start but MCP tools don't work

1. **Restart Claude Code CLI** - The MCP server needs to be reloaded
2. Check MCP server configuration in `~/.claude.json`
3. Verify MCP server is built: `cd .ai-agents/context-injection/mcp-server && npm run build`

## What Gets Built Automatically

The startup script will automatically build:

1. **OpenMemory Backend** (if not built)
   - Runs `npm run build` in backend directory

2. **Context Manager** (if not built)
   - Runs `npm install && npm run build`

3. **Logging System** (if not built)
   - Runs `npm install` (if node_modules missing)
   - Runs `npm run build`

## Logs Location

All services log to separate files for output and errors:

- **Backend & Context Manager**:
  - Output: `~/.openmemory-global/logs/openmemory-<timestamp>.log`
  - Errors: `~/.openmemory-global/logs/openmemory-<timestamp>.err`
- **Logging API**:
  - Output: `.ai-agents/logging/logs/api-<timestamp>.log`
  - Errors: `.ai-agents/logging/logs/api-<timestamp>.err`

## Next Steps After Starting

1. **Restart Claude Code CLI**
   - Close and reopen the application
   - Or reload window (Command Palette → "Reload Window")

2. **Verify MCP tools**
   - AI should now see 48 tools instead of 42
   - Try: `log_event({ level: 'info', category: 'ai-agent', source: 'test', message: 'Testing!' })`

3. **Use the new tools**
   - Check file logging status: `check_file_logging({ file: 'src/users.ts' })`
   - Instrument a file: `instrument_file({ file: 'src/users.ts', level: 2 })`
   - Find slow executions: `find_slow_executions({ threshold: 100 })`

## Summary

✅ **Fixed**: PowerShell syntax errors
✅ **Added**: Logging API automatic startup
✅ **Added**: Automatic build and dependency installation
✅ **Added**: Comprehensive status reporting
✅ **Added**: Service health checks

**You can now start everything with a single command: `.\start-openmemory.bat`**

All 3 services will start automatically, and all 48 MCP tools will have full functionality! 🎉
