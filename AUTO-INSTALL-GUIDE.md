# OpenMemory-Code Auto-Installation & Configuration Guide

## Overview

OpenMemory-Code now features **complete automatic installation and configuration** on any Windows device! Simply run the `start-openmemory.bat` file and everything will be automatically set up for you.

## What Gets Automatically Installed

When you run `start-openmemory.bat`, the system automatically:

### 1. **Auto-Detects Directories** ✅
- Automatically finds the OpenMemory-Code root directory
- Detects your user profile and home directory
- Locates Claude Code configuration files
- Creates global installation directory at `%USERPROFILE%\.openmemory-global`

### 2. **Installs All Dependencies** ✅
- Checks for Node.js v18+ (required)
- Installs all npm packages for backend
- Installs Context Manager dependencies
- Installs MCP Server dependencies
- Installs Logging System dependencies
- Builds all TypeScript components automatically

### 3. **Configures .ai-agents System** ✅
- Copies complete 5-layer enforcement architecture
- Sets up autonomous AI development system
- Configures validation schemas
- Installs git hooks for enforcement
- Creates agent templates and configurations

### 4. **Sets Up Integrated Logging** ✅
- Installs comprehensive logging system (port 8082/8083)
- Creates log directory structure:
  - `logs/latest/` - Current log files
  - `logs/archive/` - Timestamped archives
- Configures auto-rotation and archival
- Enables AI agent logging enforcement
- Sets up protected configuration (`.env.logging`)

### 5. **Configures Claude Code MCP Server** ✅
- Automatically detects Claude Code config file:
  - `%USERPROFILE%\.claude.json`
  - `%APPDATA%\Claude\claude_desktop_config.json`
  - `%USERPROFILE%\.config\claude\config.json`
- Safely adds `openmemory-code-global` MCP server
- Backs up existing configuration
- Enables **40+ OpenMemory tools** for Claude Code:
  - Memory operations (store, retrieve, search, decay, reinforce)
  - Validation endpoints (enforcement checks)
  - Logging tools (search, filter, real-time streaming)
  - Intelligence tools (HSG memory, embeddings)
  - Learning tools (pattern recognition, reinforcement)

### 6. **Enables OpenMemory Init for VS Code** ✅
- Creates global command: `openmemory-init`
- Automatically initializes any VS Code project
- Creates `.openmemory` link file in project root
- Registers project in global registry
- Copies .ai-agents system to project
- Installs git hooks for enforcement

### 7. **Creates Global Commands** ✅
- `openmemory-start` - Start all services from anywhere
- `openmemory-init` - Initialize any project from anywhere
- Adds commands to Windows PATH automatically

### 8. **Verifies Installation** ✅
- Checks all components are built
- Verifies directory structure
- Tests MCP server configuration
- Confirms logging system setup
- Validates enforcement system

## Quick Start

### Method 1: Double-Click Start (Recommended)

1. Navigate to the OpenMemory-Code directory
2. Double-click `start-openmemory.bat`
3. If first-time, choose **Yes** when prompted to install
4. Wait for automatic installation (2-5 minutes)
5. All services will start automatically

### Method 2: Command Line

```cmd
cd C:\path\to\OpenMemory-Code
start-openmemory.bat
```

### Method 3: Run Installation Script Directly

If you want to reinstall or update components:

```powershell
.\install-openmemory-complete.ps1
```

Options:
- `-Force` - Force reinstallation even if already installed
- `-SkipMCP` - Skip Claude Code MCP configuration
- `-Verbose` - Show detailed installation progress

## Directory Structure After Installation

```
%USERPROFILE%\.openmemory-global\
├── backend\
│   └── backend\                    # OpenMemory backend
│       ├── dist\                   # Built backend
│       ├── src\                    # Source code
│       └── node_modules\           # Dependencies
│
├── .ai-agents\                     # Complete AI agents system
│   ├── enforcement\                # 5-layer enforcement
│   │   ├── auto-init.ts
│   │   ├── watchdog.ts
│   │   ├── schemas.ts
│   │   └── git-hooks\              # Pre-commit hooks
│   │
│   ├── context-injection\
│   │   ├── context-manager\        # Universal context (port 8081)
│   │   │   ├── dist\               # Built Context Manager
│   │   │   └── node_modules\
│   │   │
│   │   └── mcp-server\             # MCP server for Claude
│   │       ├── dist\               # Built MCP server
│   │       └── node_modules\
│   │
│   └── logging\                    # Integrated logging system
│       ├── api\                    # Logging API (port 8082/8083)
│       ├── core\                   # Logger implementation
│       ├── config\                 # Protected configuration
│       └── logs\                   # Log storage
│           ├── latest\
│           └── archive\
│
├── projects\
│   └── registry.json               # Global project registry
│
├── logs\                           # Service logs
│   ├── openmemory-YYYYMMDD-HHmmss.log
│   └── context-manager.log
│
└── bin\                            # Global commands
    ├── openmemory-start.bat
    └── openmemory-init.bat
```

## Using OpenMemory with VS Code Projects

### Initialize a New Project

1. Open your VS Code project directory in terminal
2. Run:
   ```cmd
   openmemory-init
   ```
3. The script will:
   - Create `.openmemory` link file
   - Register project globally
   - Copy .ai-agents system to project
   - Install git hooks (if git repo)
   - Update `.gitignore`

### Automatic Features

Once initialized, your project gets:
- **Cross-session memory** - AI agents remember everything
- **Enforced logging** - All actions tracked automatically
- **Autonomous AI development** - Agents work independently
- **Pattern recognition** - Learns from your coding patterns
- **Decision tracking** - Architectural choices preserved
- **5-layer enforcement** - Cannot bypass memory system

## Claude Code Integration

### Available Tools (40+)

After installation, Claude Code has access to:

#### Memory Tools
- `openmemory_store_memory` - Store information in HSG memory
- `openmemory_retrieve_memory` - Retrieve memories with similarity
- `openmemory_search_memory` - Search across all memory sectors
- `openmemory_reinforce_memory` - Strengthen important memories
- `openmemory_decay_memory` - Manage memory decay
- `openmemory_list_sectors` - List available memory sectors
- `openmemory_get_stats` - Get memory statistics

#### Validation Tools
- `openmemory_validate_enforcement` - Check enforcement status
- `openmemory_validate_schema` - Validate data structures
- `openmemory_check_hooks` - Verify git hooks installed
- `openmemory_validate_project` - Full project validation

#### Logging Tools
- `openmemory_log_write` - Write log entry
- `openmemory_log_search` - Search logs
- `openmemory_log_stream` - Real-time log streaming
- `openmemory_log_stats` - Logging statistics
- `openmemory_check_file_logging` - Verify file logging status

#### Intelligence Tools
- `openmemory_hsg_query` - Query Hierarchical Semantic Graph
- `openmemory_embedding_similarity` - Find similar content
- `openmemory_pattern_recognition` - Identify coding patterns
- `openmemory_learning_reinforcement` - Reinforce learning

#### Project Tools
- `openmemory_record_action` - Record development action
- `openmemory_record_decision` - Store architectural decision
- `openmemory_record_pattern` - Save coding pattern
- `openmemory_load_project_context` - Load full project context

### Using Tools in Claude Code

Claude Code automatically uses these tools when:
- You ask about project history
- You want to remember important information
- You need to search logs
- You ask about patterns or decisions
- You work on multi-session tasks

Example conversations:
```
You: "Remember that we decided to use Redis for caching"
Claude: [Uses openmemory_record_decision to store this]

You: "What patterns have I used for API error handling?"
Claude: [Uses openmemory_pattern_recognition to find patterns]

You: "Show me the logs from when I implemented authentication"
Claude: [Uses openmemory_log_search to find relevant logs]
```

## Services and Ports

After running `start-openmemory.bat`, these services will be running:

| Service | Port | Purpose |
|---------|------|---------|
| OpenMemory Backend | 8080 | Core memory engine (REST API) |
| Context Manager | 8081 | Universal AI context injection |
| Logging API | 8082 | Logging system REST API |
| Logging API (Alt) | 8083 | Alternative logging port |
| OAuth MCP Server | 8084 | Claude custom connectors (optional) |
| MCP Server | stdio | Claude Desktop integration |

## Troubleshooting

### Installation Fails

**Problem**: Installation script reports errors

**Solution**:
1. Check Node.js version: `node --version` (need v18+)
2. Run with Force flag: `.\install-openmemory-complete.ps1 -Force`
3. Check logs in `%USERPROFILE%\.openmemory-global\logs\`

### Claude Code Doesn't See Tools

**Problem**: MCP tools not available in Claude Code

**Solution**:
1. Restart Claude Code Desktop/CLI completely
2. Check MCP config exists:
   ```powershell
   Get-Content "$env:USERPROFILE\.claude.json"
   ```
3. Verify MCP server path in config is correct
4. Run installation again: `.\install-openmemory-complete.ps1 -Force`

### Services Don't Start

**Problem**: Services fail to start or ports in use

**Solution**:
1. Check ports not already in use:
   ```powershell
   netstat -ano | findstr "8080 8081 8082 8083"
   ```
2. Kill existing processes if needed
3. Run `.\stop-openmemory.ps1` then start again
4. Check logs for specific errors

### OpenMemory Init Fails

**Problem**: `openmemory-init` command not found or fails

**Solution**:
1. Restart terminal (PATH needs reload)
2. Run full path: `%USERPROFILE%\.openmemory-global\bin\openmemory-init.bat`
3. Ensure installation completed successfully
4. For VS Code terminal, restart VS Code

### Git Hooks Not Installing

**Problem**: Enforcement hooks fail to install

**Solution**:
1. Ensure git is installed: `git --version`
2. Ensure git repo initialized: `git init`
3. Run hook installer manually:
   ```cmd
   node .ai-agents\enforcement\git-hooks\install-hooks.js
   ```

## Advanced Usage

### Force Reinstallation

To completely reinstall all components:

```powershell
.\install-openmemory-complete.ps1 -Force
```

### Skip MCP Configuration

If you don't want Claude Code integration:

```powershell
.\install-openmemory-complete.ps1 -SkipMCP
```

### Verbose Installation

See detailed progress:

```powershell
.\install-openmemory-complete.ps1 -Verbose
```

### Manual MCP Configuration

If you need to manually configure Claude Code:

1. Locate your config file (one of):
   - `%USERPROFILE%\.claude.json`
   - `%APPDATA%\Claude\claude_desktop_config.json`
   - `%USERPROFILE%\.config\claude\config.json`

2. Add this configuration:
```json
{
  "mcpServers": {
    "openmemory-code-global": {
      "command": "node",
      "args": [
        "C:\\Users\\YourUsername\\.openmemory-global\\backend\\.ai-agents\\context-injection\\mcp-server\\dist\\index.js"
      ],
      "env": {
        "CONTEXT_MANAGER_URL": "http://localhost:8081",
        "OPENMEMORY_URL": "http://localhost:8080"
      }
    }
  }
}
```

3. Replace `YourUsername` with your actual Windows username

## System Requirements

- **OS**: Windows 10/11
- **Node.js**: v18.0.0 or higher
- **npm**: v8.0.0 or higher
- **Git**: v2.0.0 or higher (optional, for enforcement hooks)
- **PowerShell**: v5.1 or higher (included in Windows)
- **Disk Space**: ~500MB for complete installation
- **RAM**: 2GB minimum, 4GB recommended

## Security Notes

### Protected Configuration

The logging system has a protected configuration file (`.env.logging`) that:
- Only humans can modify
- AI agents cannot bypass or disable
- Enforces mandatory logging requirements
- Cannot be committed to version control

### Git Hooks Enforcement

The 5-layer enforcement system includes:
1. Auto-initialization on project start
2. API middleware (HTTP 403 on violations)
3. Persistent watchdog (monitors every 5 minutes)
4. Schema validation (Zod schemas)
5. Git pre-commit hooks (validates before commit)

This ensures AI agents **cannot bypass** memory tracking.

## Getting Help

If you encounter issues:

1. **Check logs**:
   - Backend: `%USERPROFILE%\.openmemory-global\logs\openmemory-*.log`
   - Context Manager: `%USERPROFILE%\.openmemory-global\logs\context-manager.log`
   - Logging API: `%USERPROFILE%\.openmemory-global\backend\.ai-agents\logging\logs\`

2. **Verify installation**:
   ```powershell
   Test-Path "$env:USERPROFILE\.openmemory-global\backend\backend\dist"
   Test-Path "$env:USERPROFILE\.openmemory-global\backend\.ai-agents"
   ```

3. **Check services**:
   ```cmd
   curl http://localhost:8080/health
   curl http://localhost:8081/health
   curl http://localhost:8083/api/status
   ```

4. **Report issues**:
   - GitHub: https://github.com/fatstinkypanda/OpenMemory-Code/issues
   - Include: Error messages, log files, system info

## What's Next?

After successful installation:

1. ✅ **Start the services** - Run `start-openmemory.bat`
2. ✅ **Initialize your projects** - Run `openmemory-init` in each project
3. ✅ **Restart Claude Code** - Reload to see new MCP tools
4. ✅ **Start coding** - AI agents now have perfect memory!

Enjoy your enhanced AI development experience with OpenMemory-Code!

---

**Version**: 3.0.0
**Last Updated**: 2025
**License**: MIT
