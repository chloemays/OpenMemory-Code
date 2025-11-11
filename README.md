# OpenMemory-Code

> **AI Agent Development Platform with Enforced Long-Term Memory**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.6-blue)](https://www.typescriptlang.org/)

**OpenMemory-Code** is a powerful AI agent development platform specifically designed for coding projects. Built on the foundation of [OpenMemory](https://github.com/caviraoss/openmemory), it adds comprehensive automatic service management, MCP server support, enforced AI agent compliance, and unlimited long-term memory for AI coding assistants.

---

## 🎯 What is OpenMemory-Code?

**The Problem:** AI coding assistants (Claude Code, GitHub Copilot, etc.) forget context between sessions, can't maintain project memory, and have no enforcement mechanisms to ensure they use available memory systems.

**The Solution:** OpenMemory-Code provides:
- ✅ **Unlimited Long-Term Memory** - AI agents never forget across sessions
- ✅ **Enforced Memory Usage** - Git hooks and middleware prevent bypassing
- ✅ **Automatic Service Management** - One command starts everything
- ✅ **MCP Server Integration** - Native Claude Desktop support
- ✅ **Context Injection** - Automatic project context for AI assistants
- ✅ **Cross-Session Continuity** - Pick up exactly where you left off

---

## 🚀 Quick Start (Windows)

### One-Command Setup 🎉

```batch
# 1. Clone repository
git clone https://github.com/fatstinkypanda/OpenMemory-Code.git
cd OpenMemory-Code

# 2. Install dependencies
npm run install:all

# 3. Build everything
npm run build

# 4. Run the complete setup (sets up global commands + starts services)
start-openmemory.bat
```

**That's it!** This single command will:
- ✅ Automatically configure global PowerShell commands
- ✅ **Automatically detect and configure Claude Code MCP server** (safely, with backups)
- ✅ Start all OpenMemory services
- ✅ Make `openmemory-init` available from ANY directory

**Services Running:**
- Backend: http://localhost:8080
- Context Manager: http://localhost:8081
- Logging API: http://localhost:8083
- OAuth MCP Server: http://localhost:8084
- MCP Server: Ready for Claude Code (48 tools)

**IMPORTANT:** After setup, you must **fully restart Claude Code** (close all windows & restart the app) for the MCP server to connect. See [MCP-AUTO-SETUP-SUMMARY.md](MCP-AUTO-SETUP-SUMMARY.md) for details.

### Claude Code MCP Server Setup

After running `start-openmemory.bat`:

1. **Restart Claude Code completely** (close all windows, kill processes if needed)
2. You should see 48 MCP tools available in Claude Code
3. If you see "Tools: 48" but "Resources: []" - **this is normal!** ✅
   - Resources appear after you initialize projects
   - See [CLAUDE-MCP-TROUBLESHOOTING.md](CLAUDE-MCP-TROUBLESHOOTING.md) for details

### Initialize Your First Project

After setup, close and reopen PowerShell, then:

```powershell
# Navigate to ANY project directory
cd C:\Projects\MyApp

# Initialize OpenMemory (now available globally!)
openmemory-init

# Start coding - AI agents automatically use long-term memory!
```

**Now** resources will appear in Claude Code's MCP server!

### Quick Start (Linux/macOS)

```bash
# 1-3: Same as above (clone, install, build)

# 4. Start services
npm start

# 5. Initialize a project
cd ~/Projects/MyApp
node /path/to/OpenMemory-Code/openmemory-init.js
```

For detailed setup instructions, see [QUICKSTART.md](QUICKSTART.md).

---

## 📖 Key Features

### 1. Automatic Service Management ⚡

**Before:** Manually start 3 services in separate terminals
**Now:** One command starts everything automatically

```bash
npm start  # Starts backend + context manager + all services
```

- Process Manager handles all dependent services
- Health checks ensure readiness
- Clean shutdown with Ctrl+C (no orphaned processes)
- Self-documenting with status messages

### 2. Enforced AI Agent Compliance 🔒

**5-Layer Enforcement Architecture:**

1. **Git Pre-Commit Hooks** - Block invalid commits before they happen
2. **API Middleware** - Validate all HTTP requests (returns 403 on violations)
3. **Persistent Watchdog** - Monitor compliance every 5 minutes
4. **Schema Validation** - Enforce data structure requirements
5. **16+ Validation Endpoints** - Consistency, patterns, decisions, quality

**Result:** AI agents **cannot bypass** the memory system without detection and logging.

### 3. MCP Server for Claude Desktop 🤖

Native Model Context Protocol support for seamless Claude Desktop integration.

**Features:**
- Auto-detects current project
- One-click context injection
- Tools for recording decisions, actions, patterns
- Prompts: `load_project_context`, `quick_context`

### 4. Universal Context Injection 🌐

**Context Manager** (port 8081) provides project context to ANY AI interface:

- REST API for context retrieval
- 5-minute TTL cache for performance
- Auto-detection of current project
- Markdown or JSON format
- Works with Claude Code, Cursor, Windsurf, any MCP client

### 5. Long-Term Memory Architecture 🧠

**Hierarchical Memory Decomposition (HMD):**

- **Semantic Memory** - Facts, knowledge, project state
- **Episodic Memory** - Events, actions, development history
- **Procedural Memory** - Patterns, best practices, how-tos
- **Reflective Memory** - Architectural decisions, rationale
- **Emotional Memory** - Agent sentiment, confidence levels

**Performance:**
- 95% recall accuracy
- 115ms average query time
- 338 QPS throughput
- Natural memory decay
- Cross-session continuity

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     OpenMemory-Code Ecosystem                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  npm start                                                       │
│    └─> OpenMemory Backend (port 8080)                           │
│        └─> Process Manager (automatic)                          │
│            ├─> Context Manager (port 8081)                      │
│            ├─> Watchdog (5-min monitoring)                      │
│            └─> All enforcement systems                          │
│                                                                  │
│  MCP Server (stdio)                                              │
│    └─> Started by Claude Desktop                                │
│    └─> Provides prompts, tools, resources                       │
│                                                                  │
│  Projects                                                        │
│    ├─> .openmemory (3-line link file)                           │
│    ├─> Git hooks (auto-validation)                              │
│    └─> Isolated memory per project                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🆚 What's New in OpenMemory-Code?

This project builds on [OpenMemory](https://github.com/caviraoss/openmemory) with major enhancements for AI coding assistants:

### Added Features

1. ✨ **Process Manager** - Automatic service lifecycle management
2. ✨ **Unified Startup** - `npm start` runs everything
3. ✨ **Quick Initialization** - `openmemory-init.js` for easy setup
4. ✨ **Enhanced MCP Server** - Better auto-detection and context
5. ✨ **Comprehensive Docs** - QUICKSTART, installation guides
6. ✨ **Development Focus** - Tailored for coding projects
7. ✨ **Seamless Integration** - Works with Claude Code, VS Code

### Inherited from OpenMemory

- ✅ Hierarchical Memory Decomposition (HMD)
- ✅ Multi-sector memory system
- ✅ Memory decay and reinforcement
- ✅ AI agent enforcement architecture
- ✅ Comprehensive validation system
- ✅ High-performance recall

---

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[INSTALLATION_METHODS.md](INSTALLATION_METHODS.md)** - Compare installation options
- **[AUTOMATIC_STARTUP.md](AUTOMATIC_STARTUP.md)** - Technical deep dive
- **[INTEGRATION_COMPLETE.md](INTEGRATION_COMPLETE.md)** - Integration summary

---

## 💡 Use Cases

### Solo Developer with Claude Code

```bash
# One-time setup
npm start  # Keep running
node openmemory-init.js ~/Projects/MyApp

# Daily work
cd ~/Projects/MyApp
code .  # Claude Code has full project memory!
```

**Benefits:**
- Claude Code remembers all architectural decisions
- No need to re-explain project structure
- Consistent coding patterns across sessions
- Never loses context

### Team Development

- Shared OpenMemory instance
- Each developer's AI assistant uses same memory
- Consistent understanding across team

### Long-Running Projects

- Day 1: Make architectural decisions
- Day 30: AI remembers everything from Day 1
- Day 100: Complete project history available

---

## 🛠️ Installation

### Method 1: Direct Repository (Recommended)

```bash
git clone https://github.com/fatstinkypanda/OpenMemory-Code.git
cd OpenMemory-Code
npm run install:all
npm run build
npm start
```

### Method 2: Global System

```bash
# Install globally
./.ai-agents/enforcement/install-global.sh  # Linux/macOS
.\.ai-agents\enforcement\install-global.ps1  # Windows

# Use global commands
openmemory-start
openmemory-init ~/Projects/MyApp
```

### Method 3: Docker

```bash
docker compose up --build -d
```

See [INSTALLATION_METHODS.md](INSTALLATION_METHODS.md) for detailed comparison.

---

## 🔧 Configuration

### Environment Variables

```bash
# Backend port
OM_PORT=8080

# Context Manager port
CONTEXT_MANAGER_PORT=8081

# Disable auto-start
ENABLE_CONTEXT_MANAGER=false

# Embedding provider
OM_EMBEDDING_PROVIDER=synthetic  # or openai, gemini, ollama
```

### Claude Desktop Setup

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "openmemory-code": {
      "command": "node",
      "args": ["/absolute/path/to/.ai-agents/context-injection/mcp-server/dist/index.js"]
    }
  }
}
```

---

## 📊 Performance

| Metric | Value |
|--------|-------|
| **Recall @10** | 95% |
| **Average Query** | 115ms |
| **Throughput** | 338 QPS |
| **Storage (100k)** | 1.5 GB |
| **Cost (1M memories)** | $17-30/month |

**Compared to alternatives:**
- 2-3× faster than Zep, Supermemory
- 6-10× cheaper than cloud solutions
- 95% recall vs 68-78% for vector DBs

---

## 🤝 Contributing

Contributions welcome!

```bash
# Fork and clone
git clone https://github.com/yourusername/OpenMemory-Code.git

# Create feature branch
git checkout -b feature/amazing-feature

# Make changes and test
npm run dev

# Submit pull request
```

---

## 📄 License

MIT License - Copyright (c) 2025 Daniel A Bissey

This project is built on [OpenMemory](https://github.com/caviraoss/openmemory) by OpenMemory Contributors (MIT License).

See [LICENSE](LICENSE) file for details.

---

## 🙏 Attribution

**OpenMemory-Code** is built on the excellent foundation of [OpenMemory](https://github.com/caviraoss/openmemory) created by [nullure](https://github.com/nullure) and the OpenMemory Contributors.

### Original OpenMemory Features
- Hierarchical Memory Decomposition (HMD)
- Multi-sector memory system
- Memory decay and reinforcement
- AI agent enforcement architecture
- MCP server implementation
- Comprehensive validation system

### Our Additions
- Automatic service management system
- Process manager for lifecycle control
- Unified startup scripts
- Enhanced project initialization
- Context Manager auto-start
- Comprehensive quick start documentation
- Focus on AI coding assistants

**We thank the original OpenMemory team for creating such a robust and well-designed memory system!**

---

## 🔗 Links

- **GitHub:** https://github.com/fatstinkypanda/OpenMemory-Code
- **Original OpenMemory:** https://github.com/caviraoss/openmemory
- **Author:** Daniel A Bissey
- **Email:** support@fatstinkypanda.com
- **Issues:** https://github.com/fatstinkypanda/OpenMemory-Code/issues

---

## 📞 Support

- **Issues:** https://github.com/fatstinkypanda/OpenMemory-Code/issues
- **Email:** support@fatstinkypanda.com
- **Original OpenMemory Discord:** https://discord.gg/P7HaRayqTh

---

## 🎯 Project Goals

**OpenMemory-Code aims to:**

1. ✅ Make AI coding assistants truly powerful with unlimited memory
2. ✅ Enforce memory usage so AI can't bypass the system
3. ✅ Provide seamless integration with Claude Code, VS Code, etc.
4. ✅ Support multiple projects effortlessly
5. ✅ Maintain cross-session continuity indefinitely
6. ✅ Keep setup simple and automatic
7. ✅ Build on the solid OpenMemory foundation

**We're focused on one thing:** Making AI coding assistants remember everything, forever, with enforcement.

---

**Made with ❤️ by [Daniel A Bissey](https://github.com/fatstinkypanda)**

**Built on [OpenMemory](https://github.com/caviraoss/openmemory) by [nullure](https://github.com/nullure) and contributors**
