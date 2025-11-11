#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete OpenMemory-Code Installation and Auto-Configuration Script

.DESCRIPTION
    This is a comprehensive installation script that:
    - Automatically detects directories and locations on any device
    - Installs all requirements and dependencies
    - Copies all necessary folders and files
    - Configures the .ai-agents system
    - Sets up the integrated logging system
    - Detects and configures Claude Code MCP server config
    - Makes OpenMemory init work for any VS Code project
    - Provides 40+ tools to Claude Code Desktop

.PARAMETER Force
    Force reinstallation even if components already exist

.PARAMETER SkipMCP
    Skip MCP server configuration

.PARAMETER Verbose
    Show detailed installation progress

.EXAMPLE
    .\install-openmemory-complete.ps1
    Complete installation with all features

.EXAMPLE
    .\install-openmemory-complete.ps1 -Force
    Force reinstallation of all components
#>

param(
    [switch]$Force,
    [switch]$SkipMCP,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# ============================================================================
# COLORS AND LOGGING
# ============================================================================

function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Step { param($msg) Write-Host "`n$msg" -ForegroundColor Magenta }

# ============================================================================
# BANNER
# ============================================================================

function Show-Banner {
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "     OpenMemory-Code Complete Installation & Auto-Configuration" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
    Write-Info "This script will:"
    Write-Host "  • Auto-detect all directories and paths"
    Write-Host "  • Install all dependencies and requirements"
    Write-Host "  • Configure .ai-agents system (5-layer enforcement)"
    Write-Host "  • Setup integrated logging system"
    Write-Host "  • Configure Claude Code MCP server (40+ tools)"
    Write-Host "  • Enable OpenMemory init for VS Code projects"
    Write-Host ""
}

# ============================================================================
# DIRECTORY DETECTION
# ============================================================================

function Get-OpenMemoryRoot {
    Write-Step "[1/10] Detecting OpenMemory-Code directory..."

    # Try to detect from script location
    $scriptPath = $PSScriptRoot

    # Check if we're in the OpenMemory-Code directory
    $markers = @("backend", ".ai-agents", "openmemory-init.js", "start-openmemory.js")
    $allMarkersPresent = $true

    foreach ($marker in $markers) {
        if (-not (Test-Path (Join-Path $scriptPath $marker))) {
            $allMarkersPresent = $false
            break
        }
    }

    if ($allMarkersPresent) {
        Write-Success "[OK] OpenMemory-Code root detected: $scriptPath"
        return $scriptPath
    }

    # Try parent directory
    $parentPath = Split-Path -Parent $scriptPath
    $allMarkersPresent = $true

    foreach ($marker in $markers) {
        if (-not (Test-Path (Join-Path $parentPath $marker))) {
            $allMarkersPresent = $false
            break
        }
    }

    if ($allMarkersPresent) {
        Write-Success "[OK] OpenMemory-Code root detected: $parentPath"
        return $parentPath
    }

    Write-Error "[X] Could not detect OpenMemory-Code root directory"
    Write-Info "Please run this script from the OpenMemory-Code directory"
    exit 1
}

function Get-GlobalDir {
    return Join-Path $env:USERPROFILE ".openmemory-global"
}

function Get-ClaudeConfigPath {
    # Try multiple locations for Claude Code config
    $possiblePaths = @(
        (Join-Path $env:USERPROFILE ".claude.json"),
        (Join-Path (Join-Path $env:USERPROFILE ".claude") "config.json"),
        (Join-Path (Join-Path $env:APPDATA "Claude") "claude_desktop_config.json"),
        (Join-Path (Join-Path $env:LOCALAPPDATA "Claude") "claude_desktop_config.json"),
        (Join-Path (Join-Path (Join-Path $env:USERPROFILE ".config") "claude") "config.json")
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # Return default path if none found
    return Join-Path $env:USERPROFILE ".claude.json"
}

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

function Test-Prerequisites {
    Write-Step "[2/10] Checking prerequisites..."

    # Check Node.js
    try {
        $nodeVersion = node --version
        $nodeMajorVersion = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')

        if ($nodeMajorVersion -lt 18) {
            Write-Error "[X] Node.js $nodeVersion found, but v18+ required"
            Write-Info "Please upgrade Node.js from https://nodejs.org/"
            exit 1
        }

        Write-Success "[OK] Node.js $nodeVersion"
    }
    catch {
        Write-Error "[X] Node.js not found"
        Write-Info "Please install Node.js v18+ from https://nodejs.org/"
        exit 1
    }

    # Check npm
    try {
        $npmVersion = npm --version
        Write-Success "[OK] npm v$npmVersion"
    }
    catch {
        Write-Error "[X] npm not found"
        exit 1
    }

    # Check Git (optional but recommended)
    try {
        $gitVersion = git --version
        Write-Success "[OK] $gitVersion"
    }
    catch {
        Write-Warning "[!] Git not found (optional, but recommended for enforcement hooks)"
    }

    Write-Success "[OK] All required prerequisites met"
}

# ============================================================================
# GLOBAL DIRECTORY STRUCTURE
# ============================================================================

function Initialize-GlobalDirectory {
    param([string]$GlobalDir, [string]$OpenMemoryRoot)

    Write-Step "[3/10] Setting up global directory structure..."

    # Create global directories
    $dirs = @(
        $GlobalDir,
        (Join-Path $GlobalDir "projects"),
        (Join-Path $GlobalDir "logs"),
        (Join-Path $GlobalDir "backend"),
        (Join-Path $GlobalDir "bin")
    )

    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Success "[OK] Created: $dir"
        }
        else {
            if ($Verbose) {
                Write-Info "[OK] Exists: $dir"
            }
        }
    }

    # Copy backend to global location
    $backendSource = Join-Path $OpenMemoryRoot "backend"
    $backendDest = Join-Path (Join-Path $GlobalDir "backend") "backend"

    if ($Force -or -not (Test-Path $backendDest)) {
        Write-Info "Copying backend to global directory..."
        if (Test-Path $backendDest) {
            Remove-Item -Path $backendDest -Recurse -Force
        }
        Copy-Item -Path $backendSource -Destination $backendDest -Recurse -Force
        Write-Success "[OK] Backend copied to global directory"
    }
    else {
        Write-Info "[OK] Backend already in global directory"
    }

    # Copy .ai-agents to global backend
    $aiAgentsSource = Join-Path $OpenMemoryRoot ".ai-agents"
    $aiAgentsDest = Join-Path (Join-Path $GlobalDir "backend") ".ai-agents"

    if ($Force -or -not (Test-Path $aiAgentsDest)) {
        Write-Info "Copying .ai-agents system to global directory..."
        if (Test-Path $aiAgentsDest) {
            Remove-Item -Path $aiAgentsDest -Recurse -Force
        }
        Copy-Item -Path $aiAgentsSource -Destination $aiAgentsDest -Recurse -Force
        Write-Success "[OK] .ai-agents system copied"
    }
    else {
        Write-Info "[OK] .ai-agents system already in global directory"
    }

    # Create project registry if it doesn't exist
    $registryPath = Join-Path (Join-Path $GlobalDir "projects") "registry.json"
    if (-not (Test-Path $registryPath)) {
        $registry = @{
            version = "1.0"
            projects = @{}
            created = (Get-Date -Format "o")
            updated = (Get-Date -Format "o")
        } | ConvertTo-Json -Depth 10

        Set-Content -Path $registryPath -Value $registry
        Write-Success "[OK] Created project registry"
    }

    Write-Success "[OK] Global directory structure initialized"
}

# ============================================================================
# INSTALL BACKEND DEPENDENCIES
# ============================================================================

function Install-BackendDependencies {
    param([string]$GlobalDir)

    Write-Step "[4/10] Installing backend dependencies..."

    $backendPath = Join-Path (Join-Path $GlobalDir "backend") "backend"

    Push-Location $backendPath
    try {
        if ($Force -or -not (Test-Path "node_modules")) {
            Write-Info "Installing backend npm packages..."
            npm install
            Write-Success "[OK] Backend dependencies installed"
        }
        else {
            Write-Info "[OK] Backend dependencies already installed"
        }

        # Build backend
        if ($Force -or -not (Test-Path "dist")) {
            Write-Info "Building backend..."
            npm run build
            Write-Success "[OK] Backend built successfully"
        }
        else {
            Write-Info "[OK] Backend already built"
        }
    }
    finally {
        Pop-Location
    }
}

# ============================================================================
# INSTALL CONTEXT MANAGER
# ============================================================================

function Install-ContextManager {
    param([string]$GlobalDir)

    Write-Step "[5/10] Installing Context Manager..."

    $backendAiAgentsPath = Join-Path (Join-Path $GlobalDir "backend") ".ai-agents"
    $contextInjectionPath = Join-Path $backendAiAgentsPath "context-injection"
    $contextManagerPath = Join-Path $contextInjectionPath "context-manager"

    if (-not (Test-Path $contextManagerPath)) {
        Write-Error "[X] Context Manager not found at: $contextManagerPath"
        exit 1
    }

    Push-Location $contextManagerPath
    try {
        if ($Force -or -not (Test-Path "node_modules")) {
            Write-Info "Installing Context Manager dependencies..."
            npm install
            Write-Success "[OK] Context Manager dependencies installed"
        }
        else {
            Write-Info "[OK] Context Manager dependencies already installed"
        }

        if ($Force -or -not (Test-Path "dist")) {
            Write-Info "Building Context Manager..."
            npm run build
            Write-Success "[OK] Context Manager built successfully"
        }
        else {
            Write-Info "[OK] Context Manager already built"
        }
    }
    finally {
        Pop-Location
    }
}

# ============================================================================
# INSTALL LOGGING SYSTEM
# ============================================================================

function Install-LoggingSystem {
    param([string]$GlobalDir)

    Write-Step "[6/10] Installing Integrated Logging System..."

    $backendAiAgentsPath = Join-Path (Join-Path $GlobalDir "backend") ".ai-agents"
    $loggingPath = Join-Path $backendAiAgentsPath "logging"

    if (-not (Test-Path $loggingPath)) {
        Write-Warning "[!] Logging system not found, skipping"
        return
    }

    Push-Location $loggingPath
    try {
        if ($Force -or -not (Test-Path "node_modules")) {
            Write-Info "Installing Logging System dependencies..."
            npm install
            Write-Success "[OK] Logging System dependencies installed"
        }
        else {
            Write-Info "[OK] Logging System dependencies already installed"
        }

        if ($Force -or -not (Test-Path "dist")) {
            Write-Info "Building Logging System..."
            npm run build
            Write-Success "[OK] Logging System built successfully"
        }
        else {
            Write-Info "[OK] Logging System already built"
        }

        # Create logs directory structure
        $logsDir = Join-Path $loggingPath "logs"
        $logDirs = @(
            $logsDir,
            (Join-Path $logsDir "latest"),
            (Join-Path $logsDir "archive")
        )

        foreach ($dir in $logDirs) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
        }

        Write-Success "[OK] Logging System initialized"
    }
    finally {
        Pop-Location
    }
}

# ============================================================================
# INSTALL MCP SERVER
# ============================================================================

function Install-MCPServer {
    param([string]$GlobalDir)

    Write-Step "[7/10] Installing MCP Server..."

    $backendAiAgentsPath = Join-Path (Join-Path $GlobalDir "backend") ".ai-agents"
    $contextInjectionPath = Join-Path $backendAiAgentsPath "context-injection"
    $mcpServerPath = Join-Path $contextInjectionPath "mcp-server"

    if (-not (Test-Path $mcpServerPath)) {
        Write-Error "[X] MCP Server not found at: $mcpServerPath"
        exit 1
    }

    Push-Location $mcpServerPath
    try {
        if ($Force -or -not (Test-Path "node_modules")) {
            Write-Info "Installing MCP Server dependencies..."
            npm install
            Write-Success "[OK] MCP Server dependencies installed"
        }
        else {
            Write-Info "[OK] MCP Server dependencies already installed"
        }

        if ($Force -or -not (Test-Path "dist")) {
            Write-Info "Building MCP Server..."
            npm run build
            Write-Success "[OK] MCP Server built successfully"
        }
        else {
            Write-Info "[OK] MCP Server already built"
        }
    }
    finally {
        Pop-Location
    }
}

# ============================================================================
# CONFIGURE CLAUDE CODE MCP
# ============================================================================

function Configure-ClaudeCodeMCP {
    param([string]$GlobalDir)

    if ($SkipMCP) {
        Write-Warning "[!] Skipping MCP configuration (-SkipMCP flag)"
        return
    }

    Write-Step "[8/10] Configuring Claude Code MCP Server..."

    $backendAiAgentsPath = Join-Path (Join-Path $GlobalDir "backend") ".ai-agents"
    $contextInjectionPath = Join-Path $backendAiAgentsPath "context-injection"
    $mcpServerDistPath = Join-Path (Join-Path $contextInjectionPath "mcp-server") "dist"
    $mcpServerPath = Join-Path $mcpServerDistPath "index.js"

    if (-not (Test-Path $mcpServerPath)) {
        Write-Error "[X] MCP Server executable not found at: $mcpServerPath"
        exit 1
    }

    # Detect Claude config path
    $claudeConfigPath = Get-ClaudeConfigPath
    $claudeConfigDir = Split-Path -Parent $claudeConfigPath

    # Create directory if it doesn't exist
    if (-not (Test-Path $claudeConfigDir)) {
        New-Item -ItemType Directory -Path $claudeConfigDir -Force | Out-Null
        Write-Info "Created Claude config directory: $claudeConfigDir"
    }

    # Read or create config
    $config = @{}
    if (Test-Path $claudeConfigPath) {
        Write-Info "Found existing Claude config at: $claudeConfigPath"
        try {
            $configContent = Get-Content -Path $claudeConfigPath -Raw
            $config = $configContent | ConvertFrom-Json -AsHashtable
        }
        catch {
            Write-Warning "[!] Could not parse existing config, creating backup"
            $backupPath = "$claudeConfigPath.backup." + (Get-Date -Format "yyyyMMdd-HHmmss")
            Copy-Item -Path $claudeConfigPath -Destination $backupPath
            Write-Info "Backup created: $backupPath"
            $config = @{}
        }
    }

    # Ensure mcpServers object exists
    if (-not $config.ContainsKey("mcpServers")) {
        $config["mcpServers"] = @{}
    }

    # Configure OpenMemory MCP server
    $mcpConfig = @{
        command = "node"
        args = @($mcpServerPath)
        env = @{
            CONTEXT_MANAGER_URL = "http://localhost:8081"
            OPENMEMORY_URL = "http://localhost:8080"
        }
    }

    # Check if already configured
    if ($config["mcpServers"].ContainsKey("openmemory-code-global")) {
        Write-Warning "[!] OpenMemory MCP server already configured"

        if ($Force) {
            Write-Info "Updating configuration (Force mode)"
            $config["mcpServers"]["openmemory-code-global"] = $mcpConfig
        }
        else {
            Write-Info "Skipping configuration (use -Force to update)"
            return
        }
    }
    else {
        Write-Info "Adding OpenMemory MCP server to Claude config"
        $config["mcpServers"]["openmemory-code-global"] = $mcpConfig
    }

    # Save config
    $configJson = $config | ConvertTo-Json -Depth 10
    Set-Content -Path $claudeConfigPath -Value $configJson

    Write-Success "[OK] Claude Code MCP server configured!"
    Write-Info "Config location: $claudeConfigPath"
    Write-Info "MCP server name: openmemory-code-global"
    Write-Success "[OK] 40+ OpenMemory tools now available to Claude Code!"
}

# ============================================================================
# CREATE STARTUP WRAPPER
# ============================================================================

function Create-StartupWrapper {
    param([string]$OpenMemoryRoot)

    Write-Step "[9/10] Creating unified startup scripts..."

    # Update start-openmemory.bat to use the PowerShell script
    $batPath = Join-Path $OpenMemoryRoot "start-openmemory.bat"
    $batContent = @"
@echo off
REM OpenMemory-Code Unified Startup Script
REM This wrapper calls the PowerShell startup script

echo Starting OpenMemory-Code...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0start-openmemory.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to start OpenMemory-Code
    echo Please check the error messages above
    pause
    exit /b %ERRORLEVEL%
)
"@

    Set-Content -Path $batPath -Value $batContent
    Write-Success "[OK] Updated start-openmemory.bat"

    # Create convenient shortcuts in global bin
    $globalDir = Get-GlobalDir
    $globalBinDir = Join-Path $globalDir "bin"

    # Note: start-openmemory.ps1 is in the OpenMemory root, not in global backend
    $startPs1Path = Join-Path $OpenMemoryRoot "start-openmemory.ps1"

    # Create openmemory-start command
    $startCmdPath = Join-Path $globalBinDir "openmemory-start.bat"
    $startCmdContent = @"
@echo off
powershell -ExecutionPolicy Bypass -File "$startPs1Path"
"@

    Set-Content -Path $startCmdPath -Value $startCmdContent

    # Create openmemory-init command
    $initCmdPath = Join-Path $globalBinDir "openmemory-init.bat"
    $initJsPath = Join-Path $OpenMemoryRoot "openmemory-init.js"
    $initCmdContent = @"
@echo off
node "$initJsPath" %*
"@

    Set-Content -Path $initCmdPath -Value $initCmdContent

    Write-Success "[OK] Created global commands: openmemory-start, openmemory-init"

    # Add to PATH if not already there
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $currentPath.Contains($globalBinDir)) {
        Write-Info "Adding global bin directory to PATH..."
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$currentPath;$globalBinDir",
            "User"
        )
        Write-Success "[OK] Added to PATH (restart terminal to use global commands)"
    }
}

# ============================================================================
# VERIFY INSTALLATION
# ============================================================================

function Test-Installation {
    param([string]$GlobalDir)

    Write-Step "[10/10] Verifying installation..."

    $backendPath = Join-Path (Join-Path $GlobalDir "backend") "backend"
    $backendAiAgentsPath = Join-Path (Join-Path $GlobalDir "backend") ".ai-agents"
    $contextInjectionPath = Join-Path $backendAiAgentsPath "context-injection"

    $checks = @(
        @{
            Name = "Backend built"
            Path = Join-Path $backendPath "dist"
        },
        @{
            Name = "Context Manager built"
            Path = Join-Path (Join-Path $contextInjectionPath "context-manager") "dist"
        },
        @{
            Name = "MCP Server built"
            Path = Join-Path (Join-Path $contextInjectionPath "mcp-server") "dist"
        },
        @{
            Name = ".ai-agents system"
            Path = Join-Path $backendAiAgentsPath "enforcement"
        },
        @{
            Name = "Logging system"
            Path = Join-Path (Join-Path $backendAiAgentsPath "logging") "api"
        },
        @{
            Name = "Project registry"
            Path = Join-Path (Join-Path $GlobalDir "projects") "registry.json"
        }
    )

    $allPassed = $true

    foreach ($check in $checks) {
        if (Test-Path $check.Path) {
            Write-Success "[OK] $($check.Name)"
        }
        else {
            Write-Error "[X] $($check.Name) - NOT FOUND"
            $allPassed = $false
        }
    }

    if ($allPassed) {
        Write-Success "[OK] All installation checks passed!"
        return $true
    }
    else {
        Write-Error "[X] Some installation checks failed"
        return $false
    }
}

# ============================================================================
# SHOW COMPLETION MESSAGE
# ============================================================================

function Show-CompletionMessage {
    param([string]$OpenMemoryRoot, [string]$GlobalDir)

    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Success "     INSTALLATION COMPLETE!"
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""

    Write-Info "OpenMemory-Code is now fully installed and configured!"
    Write-Host ""

    Write-Host "Installed Components:" -ForegroundColor Cyan
    Write-Host "  [OK] OpenMemory Backend (with HSG memory engine)" -ForegroundColor Green
    Write-Host "  [OK] Context Manager (Universal AI context injection)" -ForegroundColor Green
    Write-Host "  [OK] MCP Server (40+ tools for Claude Code)" -ForegroundColor Green
    Write-Host "  [OK] .ai-agents System (5-layer enforcement)" -ForegroundColor Green
    Write-Host "  [OK] Integrated Logging System" -ForegroundColor Green
    Write-Host "  [OK] Global Commands (openmemory-start, openmemory-init)" -ForegroundColor Green
    Write-Host ""

    Write-Host "Quick Start:" -ForegroundColor Cyan
    Write-Host "  1. Start OpenMemory services:" -ForegroundColor White
    Write-Host "     cd $OpenMemoryRoot" -ForegroundColor Gray
    Write-Host "     .\start-openmemory.bat" -ForegroundColor Green
    Write-Host "     OR use: openmemory-start (from anywhere)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  2. Initialize a VS Code project:" -ForegroundColor White
    Write-Host "     cd your-project-directory" -ForegroundColor Gray
    Write-Host "     openmemory-init" -ForegroundColor Green
    Write-Host ""
    Write-Host "  3. Restart Claude Code to load new MCP tools" -ForegroundColor White
    Write-Host ""

    Write-Host "Claude Code Integration:" -ForegroundColor Cyan
    Write-Host "  • MCP Server: openmemory-code-global" -ForegroundColor Green
    Write-Host "  • Available Tools: 40+ memory, validation, logging tools" -ForegroundColor Green
    Write-Host "  • Config: $(Get-ClaudeConfigPath)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Global Directory:" -ForegroundColor Cyan
    Write-Host "  $GlobalDir" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Start the services: .\start-openmemory.bat" -ForegroundColor Yellow
    Write-Host "  2. Initialize your projects: openmemory-init" -ForegroundColor Yellow
    Write-Host "  3. Restart Claude Code Desktop/CLI" -ForegroundColor Yellow
    Write-Host "  4. Start coding with AI assistance!" -ForegroundColor Yellow
    Write-Host ""

    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Show-Banner

    # Detect directories
    $openMemoryRoot = Get-OpenMemoryRoot
    $globalDir = Get-GlobalDir

    Write-Info "OpenMemory Root: $openMemoryRoot"
    Write-Info "Global Directory: $globalDir"
    Write-Host ""

    # Run installation steps
    Test-Prerequisites
    Initialize-GlobalDirectory -GlobalDir $globalDir -OpenMemoryRoot $openMemoryRoot
    Install-BackendDependencies -GlobalDir $globalDir
    Install-ContextManager -GlobalDir $globalDir
    Install-LoggingSystem -GlobalDir $globalDir
    Install-MCPServer -GlobalDir $globalDir
    Configure-ClaudeCodeMCP -GlobalDir $globalDir
    Create-StartupWrapper -OpenMemoryRoot $openMemoryRoot

    # Verify installation
    $installOk = Test-Installation -GlobalDir $globalDir

    if ($installOk) {
        Show-CompletionMessage -OpenMemoryRoot $openMemoryRoot -GlobalDir $globalDir
    }
    else {
        Write-Error "Installation completed with errors. Please review the messages above."
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Error "INSTALLATION FAILED: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    Write-Host ""
    Write-Info "Please review the error and try again."
    Write-Info "If the issue persists, please report it at:"
    Write-Info "  https://github.com/fatstinkypanda/OpenMemory-Code/issues"
    Write-Host ""
    exit 1
}
