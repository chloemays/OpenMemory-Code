#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start OpenMemory services (Backend + Context Manager + Logging API)

.DESCRIPTION
    Launches the complete OpenMemory ecosystem:
    - OpenMemory Backend (port 8080)
    - Context Manager (port 8081) - auto-started by backend
    - Logging API Server (port 8083) - for logging/tracing tools
    - MCP Server ready for Claude Code

.EXAMPLE
    .\start-openmemory.ps1
    Start all OpenMemory services

.EXAMPLE
    .\start-openmemory.ps1 -Dev
    Start in development mode (with tsx)
#>

param(
    [switch]$Dev,
    [switch]$Verbose,
    [switch]$SkipLogging
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "           OpenMemory Startup Manager" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
}

# Check if a port is in use
function Test-PortInUse {
    param([int]$Port)

    try {
        # Use Test-NetConnection for reliable port detection
        $test = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
        return $test
    }
    catch {
        # Fallback to netstat if Test-NetConnection fails
        $netstat = netstat -ano | Select-String ":$Port.*LISTENING"
        return $null -ne $netstat
    }
}

# Kill process using a port
function Stop-ProcessOnPort {
    param([int]$Port)

    try {
        $connections = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $Port })
        foreach ($conn in $connections) {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            if ($process) {
                Write-Warning "Stopping existing process on port ${Port}: $($process.Name) (PID: $($process.Id))"
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
        }
    }
    catch {
        Write-Warning "Could not stop process on port $Port : $_"
    }
}

# Wait for service to be ready
function Wait-ForService {
    param(
        [string]$Url,
        [int]$MaxAttempts = 30,
        [string]$ServiceName
    )

    Write-Info "Waiting for $ServiceName to be ready..."

    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 2 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Success "[OK] $ServiceName is ready!"
                return $true
            }
        }
        catch {
            if ($Verbose) {
                Write-Host "  Attempt $i/$MaxAttempts..." -ForegroundColor DarkGray
            }
        }
        Start-Sleep -Seconds 1
    }

    Write-Error "[X] $ServiceName failed to start after $MaxAttempts seconds"
    return $false
}

# Detect backend path
function Get-BackendPath {
    # First, check if we're running from the project directory
    $scriptDir = Split-Path -Parent $PSCommandPath
    $localBackend = Join-Path $scriptDir "backend"

    if (Test-Path $localBackend) {
        Write-Verbose "Using local backend at: $localBackend"
        return $localBackend
    }

    # Fallback to global installation
    $globalBackend = "$env:USERPROFILE\.openmemory-global\backend\backend"
    if (Test-Path $globalBackend) {
        Write-Verbose "Using global backend at: $globalBackend"
        return $globalBackend
    }

    return $null
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    # Check Node.js
    try {
        $nodeVersion = node --version
        Write-Success "[OK] Node.js $nodeVersion found"
    }
    catch {
        Write-Error "[X] Node.js not found. Please install Node.js from https://nodejs.org/"
        exit 1
    }

    # Detect and check backend
    $script:backendPath = Get-BackendPath
    if (-not $script:backendPath) {
        $scriptDir = Split-Path -Parent $PSCommandPath
        Write-Error "[X] OpenMemory backend not found!"
        Write-Info "Searched locations:"
        Write-Info "  - Local: $(Join-Path $scriptDir 'backend')"
        Write-Info "  - Global: $env:USERPROFILE\.openmemory-global\backend\backend"
        Write-Info "Please ensure OpenMemory is properly installed."
        exit 1
    }
    Write-Success "[OK] OpenMemory backend found at: $script:backendPath"

    # Check if backend is built
    $distPath = Join-Path $script:backendPath "dist"
    if (-not (Test-Path $distPath)) {
        Write-Warning "[!] Backend not built, building now..."
        Push-Location $script:backendPath
        try {
            npm run build | Out-Null
            Write-Success "[OK] Backend built successfully"
        }
        catch {
            Write-Error "[X] Failed to build backend: $_"
            exit 1
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Success "[OK] Backend is built"
    }

    # Check Context Manager (look for it relative to backend path or in project)
    $scriptDir = Split-Path -Parent $PSCommandPath
    $contextManagerPath = Join-Path $scriptDir ".ai-agents\context-injection\context-manager"

    # Fallback to global location if not found locally
    if (-not (Test-Path $contextManagerPath)) {
        $contextManagerPath = "$env:USERPROFILE\.openmemory-global\backend\.ai-agents\context-injection\context-manager"
    }

    if (-not (Test-Path $contextManagerPath)) {
        Write-Error "[X] Context Manager not found at: $contextManagerPath"
        exit 1
    }

    $contextManagerDist = Join-Path $contextManagerPath "dist"
    if (-not (Test-Path $contextManagerDist)) {
        Write-Warning "[!] Context Manager not built, building now..."
        Push-Location $contextManagerPath
        try {
            npm install | Out-Null
            npm run build | Out-Null
            Write-Success "[OK] Context Manager built successfully"
        }
        catch {
            Write-Error "[X] Failed to build Context Manager: $_"
            exit 1
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Success "[OK] Context Manager is built"
    }

    # Check Logging System (if not skipped)
    if (-not $SkipLogging) {
        $loggingPath = Join-Path (Get-Location) ".ai-agents/logging"
        if (Test-Path $loggingPath) {
            $loggingDist = Join-Path $loggingPath "dist"
            if (-not (Test-Path $loggingDist)) {
                Write-Warning "Logging system not built, building now..."
                Push-Location $loggingPath
                try {
                    if (-not (Test-Path "node_modules")) {
                        Write-Info "Installing logging dependencies..."
                        npm install | Out-Null
                    }
                    npm run build | Out-Null
                    Write-Success "Logging system built successfully"
                }
                catch {
                    Write-Warning "Failed to build logging system"
                    Write-Info "You can build it manually later"
                }
                finally {
                    Pop-Location
                }
            }
            else {
                Write-Success "[OK] Logging system is built"
            }
        }
        else {
            Write-Warning "[!] Logging system not found at: $loggingPath"
            Write-Info "Logging/tracing MCP tools will have limited functionality"
        }
    }

    # Check OAuth MCP Server
    $mcpServerPath = Join-Path (Get-Location) ".ai-agents/context-injection/mcp-server"
    if (Test-Path $mcpServerPath) {
        $mcpServerDist = Join-Path $mcpServerPath "dist"
        if (-not (Test-Path $mcpServerDist)) {
            Write-Warning "OAuth MCP server not built, building now..."
            Push-Location $mcpServerPath
            try {
                if (-not (Test-Path "node_modules")) {
                    Write-Info "Installing OAuth MCP server dependencies..."
                    npm install | Out-Null
                }
                npm run build | Out-Null
                Write-Success "OAuth MCP server built successfully"
            }
            catch {
                Write-Warning "Failed to build OAuth MCP server"
                Write-Info "You can build it manually later"
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Success "[OK] OAuth MCP server is built"
        }
    }
    else {
        Write-Warning "[!] OAuth MCP server not found at: $mcpServerPath"
        Write-Info "Claude custom connector functionality will not be available"
    }

    Write-Success "[OK] All prerequisites met"
    Write-Host ""
}

# Start OpenMemory
function Start-OpenMemory {
    param([switch]$DevMode)

    # Use the detected backend path from Test-Prerequisites
    if (-not $script:backendPath) {
        Write-Error "[X] Backend path not set. This should not happen."
        exit 1
    }

    # Check if services are already running
    if (Test-PortInUse -Port 8080) {
        Write-Warning "[!] Port 8080 is already in use"
        $response = Read-Host "Stop existing service and restart? (y/N)"
        if ($response -eq "y" -or $response -eq "Y") {
            Stop-ProcessOnPort -Port 8080
            Stop-ProcessOnPort -Port 8081
            Stop-ProcessOnPort -Port 8083
            Stop-ProcessOnPort -Port 8084
        }
        else {
            Write-Info "Keeping existing services running"
            return
        }
    }

    Write-Info "Starting OpenMemory Backend..."

    Push-Location $script:backendPath

    try {
        # Create log directory - use local project logs if running locally, global otherwise
        $scriptDir = Split-Path -Parent $PSCommandPath
        if ($script:backendPath -like "$scriptDir*") {
            # Local installation - use local logs
            $logDir = Join-Path $scriptDir "logs"
        }
        else {
            # Global installation - use global logs
            $logDir = "$env:USERPROFILE\.openmemory-global\logs"
        }

        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $logFile = Join-Path $logDir "openmemory-$timestamp.log"
        $errorFile = Join-Path $logDir "openmemory-$timestamp.err"

        # Start the backend
        if ($DevMode) {
            Write-Info "Starting in development mode (tsx)..."
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "run", "dev" -NoNewWindow -RedirectStandardOutput $logFile -RedirectStandardError $errorFile
        }
        else {
            Write-Info "Starting in production mode..."
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "start" -NoNewWindow -RedirectStandardOutput $logFile -RedirectStandardError $errorFile
        }

        Write-Success "[OK] Backend process started (logs: $logFile)"

        # Wait for backend to be ready
        if (-not (Wait-ForService -Url "http://localhost:8080/health" -ServiceName "OpenMemory Backend" -MaxAttempts 30)) {
            Write-Error "Failed to start OpenMemory Backend. Check logs at: $logFile"
            exit 1
        }

        # Wait for Context Manager to be ready (started automatically by backend)
        Start-Sleep -Seconds 3
        if (-not (Wait-ForService -Url "http://localhost:8081/health" -ServiceName "Context Manager" -MaxAttempts 20)) {
            Write-Warning "Context Manager may not have started. Backend is running but Context Manager is not responding."
            Write-Info "Check logs at: $logFile"
        }
    }
    finally {
        Pop-Location
    }
}

# Start Logging API Server
function Start-LoggingAPI {
    if ($SkipLogging) {
        Write-Info "Skipping Logging API server (-SkipLogging flag)"
        return
    }

    $loggingPath = Join-Path (Get-Location) ".ai-agents/logging"
    $startScript = Join-Path $loggingPath "start-logging-api.js"

    if (-not (Test-Path $startScript)) {
        Write-Warning "[!] Logging API start script not found at: $startScript"
        Write-Info "Logging/tracing MCP tools will have limited functionality"
        return
    }

    # Check if already running
    if (Test-PortInUse -Port 8083) {
        Write-Warning "[!] Port 8083 is already in use (Logging API)"
        $response = Read-Host "Stop existing service and restart? (y/N)"
        if ($response -eq "y" -or $response -eq "Y") {
            Stop-ProcessOnPort -Port 8083
        }
        else {
            Write-Info "Keeping existing Logging API running"
            return
        }
    }

    Write-Info "Starting Logging API Server..."

    $logDir = Join-Path $loggingPath "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $logFile = Join-Path $logDir "api-$timestamp.log"
    $errorFile = Join-Path $logDir "api-$timestamp.err"

    try {
        # Use VBScript to start the process hidden (avoids stdio redirection issues)
        $vbsScript = Join-Path $loggingPath "start-hidden.vbs"

        if (Test-Path $vbsScript) {
            Start-Process -FilePath "wscript.exe" -ArgumentList $vbsScript -WindowStyle Hidden
            Write-Success "[OK] Logging API process started (logs: $logFile)"
        }
        else {
            Write-Warning "[!] VBScript launcher not found, using fallback method"
            Start-Process -FilePath "node" -ArgumentList $startScript -WorkingDirectory $loggingPath -WindowStyle Hidden
            Write-Success "[OK] Logging API process started (logs: $logFile)"
        }

        # Wait for Logging API to be ready
        Start-Sleep -Seconds 3
        if (-not (Wait-ForService -Url "http://localhost:8083/api/status" -ServiceName "Logging API" -MaxAttempts 15)) {
            Write-Warning "[!] Logging API may not have started properly"
            Write-Info "Check logs at: $logFile"
            Write-Info "Logging/tracing MCP tools will have limited functionality"
        }
    }
    catch {
        Write-Warning "[!] Failed to start Logging API: $_"
        Write-Info "Logging/tracing MCP tools will have limited functionality"
    }
}

# Start OAuth MCP Server
function Start-OAuthMCPServer {
    $mcpServerPath = Join-Path (Get-Location) ".ai-agents/context-injection/mcp-server"
    $vbsScript = Join-Path $mcpServerPath "start-oauth-mcp-hidden.vbs"

    if (-not (Test-Path $vbsScript)) {
        Write-Warning "[!] OAuth MCP server VBScript launcher not found at: $vbsScript"
        Write-Info "Claude custom connector functionality will not be available"
        return
    }

    # Check if already running
    if (Test-PortInUse -Port 8084) {
        Write-Warning "[!] Port 8084 is already in use (OAuth MCP Server)"
        $response = Read-Host "Stop existing service and restart? (y/N)"
        if ($response -eq "y" -or $response -eq "Y") {
            Stop-ProcessOnPort -Port 8084
        }
        else {
            Write-Info "Keeping existing OAuth MCP server running"
            return
        }
    }

    Write-Info "Starting OAuth MCP Server for Claude Custom Connectors..."

    try {
        Start-Process -FilePath "wscript.exe" -ArgumentList $vbsScript -WindowStyle Hidden
        Write-Success "[OK] OAuth MCP Server process started"

        # Wait for OAuth MCP Server to be ready
        Start-Sleep -Seconds 3
        if (-not (Wait-ForService -Url "http://localhost:8084/health" -ServiceName "OAuth MCP Server" -MaxAttempts 15)) {
            Write-Warning "[!] OAuth MCP Server may not have started properly"
            Write-Info "Claude custom connector functionality may not be available"
        }
        else {
            # Get OAuth credentials from the health endpoint
            try {
                $healthResponse = Invoke-RestMethod -Uri "http://localhost:8084/health" -Method Get -ErrorAction SilentlyContinue
                Write-Success "[OK] OAuth MCP Server running with $($healthResponse.tools) tools"
            }
            catch {
                Write-Success "[OK] OAuth MCP Server is running"
            }
        }
    }
    catch {
        Write-Warning "[!] Failed to start OAuth MCP Server: $_"
        Write-Info "Claude custom connector functionality will not be available"
    }
}

# Show status and instructions
function Show-Status {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Green
    Write-Success "[OK] OpenMemory is running!"
    Write-Host ("=" * 70) -ForegroundColor Green
    Write-Host ""

    Write-Info "Services:"
    Write-Host "  • OpenMemory Backend:  " -NoNewline
    Write-Success "http://localhost:8080"
    Write-Host "  • Context Manager:     " -NoNewline
    Write-Success "http://localhost:8081"

    if (-not $SkipLogging -and (Test-PortInUse -Port 8083)) {
        Write-Host "  • Logging API:         " -NoNewline
        Write-Success "http://localhost:8083"
    }
    else {
        Write-Host "  • Logging API:         " -NoNewline
        Write-Warning "Not running (limited tracing functionality)"
    }

    Write-Host "  • MCP Server:          " -NoNewline
    Write-Success "Ready for Claude Code (48 tools available)"

    if (Test-PortInUse -Port 8084) {
        Write-Host "  • OAuth MCP Server:    " -NoNewline
        Write-Success "http://localhost:8084 (for Claude Custom Connectors)"
    }
    else {
        Write-Host "  • OAuth MCP Server:    " -NoNewline
        Write-Warning "Not running (custom connector unavailable)"
    }
    Write-Host ""

    Write-Info "MCP Server Configuration:"
    Write-Host "  The global MCP server 'openmemory-code-global' is configured in:"
    Write-Host "  $env:USERPROFILE\.claude.json" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  It will automatically work with all Claude Code instances!" -ForegroundColor Green
    Write-Host ""

    Write-Info "Available MCP Tools:"
    Write-Host "  • 42 OpenMemory tools (memory, validation, learning, intelligence)"
    if (Test-PortInUse -Port 8083) {
        Write-Host "  • 6 Logging/Tracing tools " -NoNewline
        Write-Success "(FULL FUNCTIONALITY [OK])"
    }
    else {
        Write-Host "  • 6 Logging/Tracing tools " -NoNewline
        Write-Warning "(LIMITED - Logging API not running)"
    }
    Write-Host ""

    Write-Info "To stop OpenMemory:"
    Write-Host "  Run: " -NoNewline
    Write-Host ".\stop-openmemory.ps1" -ForegroundColor Yellow
    Write-Host "  Or:  " -NoNewline
    Write-Host "Kill processes on ports 8080, 8081, 8083, and 8084" -ForegroundColor Yellow
    Write-Host ""

    Write-Host ("=" * 70) -ForegroundColor Green
    Write-Host ""
}

# Main execution
try {
    Show-Banner
    Test-Prerequisites
    Start-OpenMemory -DevMode:$Dev
    Start-LoggingAPI
    Start-OAuthMCPServer
    Show-Status

    Write-Success "OpenMemory is ready to use with Claude Code!"
    Write-Info "Restart Claude Code CLI to use the new logging/tracing tools"
    if (Test-PortInUse -Port 8084) {
        Write-Info "OAuth MCP Server is ready for Claude Custom Connectors via ngrok"
    }
}
catch {
    Write-Error "Error: $_"
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}
