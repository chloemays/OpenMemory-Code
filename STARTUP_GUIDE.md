# OpenMemory Startup Guide

Quick guide to launching the OpenMemory MCP server for Claude Code.

## Quick Start

### Option 1: Double-Click (Easiest)
Simply double-click `start-openmemory.bat` in Windows Explorer.

### Option 2: PowerShell
```powershell
.\start-openmemory.ps1
```

### Option 3: Command Prompt
```cmd
start-openmemory.bat
```

## What Gets Started

When you run the startup script, it automatically launches:

1. **OpenMemory Backend** (port 8080)
   - Core memory and AI agent system
   - Automatic decay and reflection processes

2. **Context Manager** (port 8081)
   - Auto-started by the backend
   - Provides context injection for Claude Code

3. **MCP Server Ready**
   - The global `openmemory-code-global` MCP server is configured
   - Works with ALL Claude Code instances automatically
   - Provides 38 tools for memory, patterns, decisions, and more

## Stopping Services

### Option 1: Double-Click
Double-click `stop-openmemory.bat`

### Option 2: PowerShell
```powershell
.\stop-openmemory.ps1
```

## Advanced Usage

### Development Mode
Start with live TypeScript reloading:
```powershell
.\start-openmemory.ps1 -Dev
```

### Verbose Output
See detailed startup progress:
```powershell
.\start-openmemory.ps1 -Verbose
```

## Verification

After starting, verify the services are running:

1. **Check Backend**: Open http://localhost:8080/health in your browser
   - Should return JSON with `"ok": true`

2. **Check Context Manager**: Open http://localhost:8081/health
   - Should return JSON with service status

3. **Check MCP in Claude Code**:
   - Run `/mcp` command
   - Should show `openmemory-code-global` as connected

## Troubleshooting

### "Port already in use"
The script will detect this and ask if you want to stop the existing service and restart.

### Services don't start
Check the logs at: `%USERPROFILE%\.openmemory-global\logs\openmemory-TIMESTAMP.log`

### MCP server not showing in Claude Code
1. Restart Claude Code after starting services
2. Check that `~/.claude.json` contains `openmemory-code-global` in `mcpServers`
3. Run `/mcp` in Claude Code to see server status

### Context Manager fails to start
The script automatically builds it if needed. If it still fails:
```powershell
cd $env:USERPROFILE\.openmemory-global\backend\.ai-agents\context-injection\context-manager
npm install
npm run build
```

## Files Location

- **Services**: `%USERPROFILE%\.openmemory-global\backend\`
- **Logs**: `%USERPROFILE%\.openmemory-global\logs\`
- **Registry**: `%USERPROFILE%\.openmemory-global\projects\registry.json`
- **MCP Config**: `%USERPROFILE%\.claude.json`

## System Requirements

- Windows 10/11
- Node.js (v18 or later recommended)
- PowerShell (pre-installed on Windows)

## Creating a Desktop Shortcut

1. Right-click `start-openmemory.bat`
2. Select "Send to" → "Desktop (create shortcut)"
3. Rename to "Start OpenMemory"
4. (Optional) Right-click shortcut → Properties → Change icon

Now you can start OpenMemory with a single desktop click!

## Auto-Start on Windows Boot (Optional)

To have OpenMemory start automatically when Windows boots:

1. Press `Win + R`, type `shell:startup`, press Enter
2. Copy `start-openmemory.bat` to this folder
3. Services will start automatically on next boot

**Note**: This will keep OpenMemory running in the background always.

## Integration with Claude Code

Once services are running, the MCP server is automatically available to:
- Claude Code CLI (terminal)
- Claude Code VS Code Extension
- Any future Claude Code interfaces

The server auto-detects your current project based on:
- Working directory
- Registered projects in `~/.openmemory-global/projects/registry.json`

## Available MCP Tools

The `openmemory-code-global` server provides 38 tools across multiple categories:

- **Memory Management**: record_action, record_pattern, record_decision, record_emotion
- **Memory Queries**: query_memory, get_history, get_patterns, get_decisions
- **Memory Relationships**: link_memories, get_memory_graph, reinforce_memory
- **Validation**: validate_consistency, validate_effectiveness, validate_decisions
- **Self-Correction**: analyze_failures, get_lessons_learned, adjust_confidence
- **Proactive Intelligence**: detect_conflicts, predict_blockers, generate_recommendations
- **Quality & Monitoring**: run_quality_gate, get_quality_trends, detect_anomalies
- **Continuous Learning**: detect_patterns, extract_success_patterns, consolidate_memories
- **Autonomous Intelligence**: run_autonomous_intelligence, check_compliance, get_usage_report

All tools work across ALL your projects automatically!
