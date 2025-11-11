#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Configure Claude Code MCP server settings for OpenMemory

.DESCRIPTION
    Automatically detects and configures Claude Code's MCP server settings
    to include the OpenMemory MCP server. Works across different platforms
    and Claude Code installation locations.

.PARAMETER Force
    Force update even if OpenMemory MCP server is already configured

.EXAMPLE
    .\setup-claude-mcp.ps1
    Configure Claude Code MCP server

.EXAMPLE
    .\setup-claude-mcp.ps1 -Force
    Force reconfigure even if already set up
#>

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }

Write-Host ""
Write-Info "Claude Code MCP Server Configuration"
Write-Info "====================================="
Write-Host ""

# Get OpenMemory-Code installation directory
$OpenMemoryDir = Split-Path -Parent $PSCommandPath
$McpServerPath = Join-Path $OpenMemoryDir ".ai-agents\context-injection\mcp-server\dist\index.js"

# Verify MCP server exists
if (-not (Test-Path $McpServerPath)) {
    Write-Error "[X] MCP server not found at: $McpServerPath"
    Write-Info "Please ensure OpenMemory-Code is properly built (npm run build)"
    exit 1
}

Write-Success "[OK] MCP server found at: $McpServerPath"

# Verify Node.js is installed
Write-Info "Checking for Node.js installation..."
try {
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "[OK] Node.js found: $nodeVersion"
    }
    else {
        Write-Warning "[!] Node.js not found in PATH"
        Write-Info "The MCP server requires Node.js to run"
        Write-Info "Please install Node.js from: https://nodejs.org/"
        Write-Host ""
    }
}
catch {
    Write-Warning "[!] Could not verify Node.js installation"
}

# Possible Claude Code config locations
$ConfigLocations = @(
    # Claude Code CLI (most common)
    "$env:USERPROFILE\.claude.json",
    "$env:USERPROFILE\.config\claude\config.json",

    # Claude Desktop
    "$env:APPDATA\Claude\claude_desktop_config.json",
    "$env:LOCALAPPDATA\Claude\claude_desktop_config.json",

    # Alternative locations
    "$env:USERPROFILE\.config\Claude\claude_desktop_config.json",
    "$env:USERPROFILE\AppData\Roaming\Claude\claude_desktop_config.json"
)

# Search for existing config files
Write-Info "Searching for Claude Code config files..."
$FoundConfigs = @()

foreach ($location in $ConfigLocations) {
    if (Test-Path $location) {
        $FoundConfigs += $location
        Write-Success "  Found: $location"
    }
}

# If no configs found, search more broadly
if ($FoundConfigs.Count -eq 0) {
    Write-Info "  No config files found in standard locations, searching..."

    $SearchPaths = @(
        "$env:USERPROFILE",
        "$env:APPDATA",
        "$env:LOCALAPPDATA"
    )

    foreach ($searchPath in $SearchPaths) {
        if (Test-Path $searchPath) {
            $found = Get-ChildItem -Path $searchPath -Filter "*.json" -Recurse -ErrorAction SilentlyContinue -Depth 2 |
                Where-Object { $_.Name -match "(claude|\.claude)" } |
                Select-Object -First 3 -ExpandProperty FullName

            foreach ($file in $found) {
                if ($file -and (Test-Path $file)) {
                    $FoundConfigs += $file
                    Write-Success "  Found: $file"
                }
            }
        }
    }
}

# If still no configs found, create default one
if ($FoundConfigs.Count -eq 0) {
    Write-Warning "[!] No Claude Code config files found"
    Write-Info "Creating default config at: $env:USERPROFILE\.claude.json"

    $defaultConfig = @{
        mcpServers = @{
            "openmemory-code-global" = @{
                command = "node"
                args = @($McpServerPath)
                env = @{
                    CONTEXT_MANAGER_URL = "http://localhost:8081"
                    OPENMEMORY_URL = "http://localhost:8080"
                }
            }
        }
    }

    $defaultConfigPath = "$env:USERPROFILE\.claude.json"

    try {
        # Convert to JSON
        $jsonOutput = $defaultConfig | ConvertTo-Json -Depth 10 -Compress:$false

        # Validate the JSON
        $null = $jsonOutput | ConvertFrom-Json -ErrorAction Stop

        # Write with UTF-8 encoding without BOM
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($defaultConfigPath, $jsonOutput, $utf8NoBom)

        # Validate the written file
        $validateContent = [System.IO.File]::ReadAllText($defaultConfigPath, $utf8NoBom)
        $null = $validateContent | ConvertFrom-Json -ErrorAction Stop

        Write-Success "[OK] Created Claude Code config with OpenMemory MCP server"
        Write-Success "[OK] Config location: $defaultConfigPath"
        Write-Host ""
        Write-Info "Configuration complete! Restart Claude Code to use the MCP server."
        exit 0
    }
    catch {
        Write-Error "[X] Failed to create default config: $_"
        Write-Info "Please manually create the config file at: $defaultConfigPath"
        exit 1
    }
}

# Process each found config file
Write-Host ""
Write-Info "Configuring MCP server in found config files..."
Write-Host ""

$UpdatedCount = 0
$SkippedCount = 0

foreach ($configPath in $FoundConfigs) {
    Write-Info "Processing: $configPath"

    try {
        # Read and parse config with UTF-8 encoding
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $configContent = [System.IO.File]::ReadAllText($configPath, $utf8NoBom)

        # Validate and parse JSON
        if ([string]::IsNullOrWhiteSpace($configContent)) {
            throw "Config file is empty"
        }

        $config = $configContent | ConvertFrom-Json -ErrorAction Stop

        if (-not $config) {
            throw "Failed to parse config as valid JSON"
        }

        # Ensure mcpServers section exists
        if (-not $config.PSObject.Properties["mcpServers"]) {
            $config | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
        }

        # Check if OpenMemory MCP server already exists
        $hasOpenMemory = $false
        if ($config.mcpServers) {
            $mcpServers = $config.mcpServers.PSObject.Properties
            foreach ($server in $mcpServers) {
                if ($server.Name -match "openmemory") {
                    $hasOpenMemory = $true
                    if (-not $Force) {
                        Write-Success "  [OK] OpenMemory MCP server already configured (use -Force to update)"
                        $SkippedCount++
                        break
                    }
                    else {
                        Write-Info "  Updating existing OpenMemory MCP server configuration..."
                    }
                }
            }
        }

        # Add or update OpenMemory MCP server
        if (-not $hasOpenMemory -or $Force) {
            $openMemoryMcp = @{
                command = "node"
                args = @($McpServerPath)
                env = @{
                    CONTEXT_MANAGER_URL = "http://localhost:8081"
                    OPENMEMORY_URL = "http://localhost:8080"
                }
            }

            # Remove old openmemory config if forcing update
            if ($Force -and $config.mcpServers.PSObject.Properties["openmemory-code-global"]) {
                $config.mcpServers.PSObject.Properties.Remove("openmemory-code-global")
            }
            if ($Force -and $config.mcpServers.PSObject.Properties["openmemory"]) {
                $config.mcpServers.PSObject.Properties.Remove("openmemory")
            }

            # Add new configuration
            $config.mcpServers | Add-Member -MemberType NoteProperty -Name "openmemory-code-global" -Value ([PSCustomObject]$openMemoryMcp) -Force

            # Backup original config
            $backupPath = "$configPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item -Path $configPath -Destination $backupPath -Force
            Write-Info "  Backup created: $backupPath"

            # Save updated config with robust error handling
            try {
                # Convert to JSON
                $jsonOutput = $config | ConvertTo-Json -Depth 10 -Compress:$false

                # Validate the JSON can be parsed back
                $null = $jsonOutput | ConvertFrom-Json -ErrorAction Stop

                # Write to temporary file first (atomic operation)
                $tempPath = "$configPath.tmp-$(Get-Date -Format 'yyyyMMddHHmmss')"

                # Write with UTF-8 encoding without BOM
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($tempPath, $jsonOutput, $utf8NoBom)

                # Validate the temp file can be read as JSON
                $validateContent = [System.IO.File]::ReadAllText($tempPath, $utf8NoBom)
                $null = $validateContent | ConvertFrom-Json -ErrorAction Stop

                # If validation passed, replace the original file atomically
                Move-Item -Path $tempPath -Destination $configPath -Force

                Write-Success "  [OK] OpenMemory MCP server configured!"
                $UpdatedCount++
            }
            catch {
                Write-Error "  [X] Failed to save config: $_"
                Write-Info "  Original config preserved at: $configPath"
                Write-Info "  Backup available at: $backupPath"

                # Clean up temp file if it exists
                if (Test-Path $tempPath) {
                    Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
                }

                # Restore from backup if needed
                if (Test-Path $backupPath) {
                    Write-Info "  Restoring from backup..."
                    Copy-Item -Path $backupPath -Destination $configPath -Force
                }

                throw
            }
        }
    }
    catch {
        Write-Warning "  [!] Failed to process config: $_"
        Write-Info "  You may need to manually add the MCP server configuration"
    }

    Write-Host ""
}

# Summary
Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Green
Write-Success "Configuration Summary"
Write-Host ("=" * 70) -ForegroundColor Green
Write-Host ""
Write-Info "Config files processed: $($FoundConfigs.Count)"
Write-Success "  Updated: $UpdatedCount"
if ($SkippedCount -gt 0) {
    Write-Info "  Skipped (already configured): $SkippedCount"
}
Write-Host ""

if ($UpdatedCount -gt 0) {
    Write-Info "MCP Server Configuration:"
    Write-Host "  Server Name: " -NoNewline
    Write-Success "openmemory-code-global"
    Write-Host "  Command: " -NoNewline
    Write-Success "node"
    Write-Host "  Script: " -NoNewline
    Write-Success "$McpServerPath"
    Write-Host "  Environment:"
    Write-Host "    CONTEXT_MANAGER_URL: " -NoNewline
    Write-Success "http://localhost:8081"
    Write-Host "    OPENMEMORY_URL: " -NoNewline
    Write-Success "http://localhost:8080"
    Write-Host ""

    # Check if Claude Code is currently running
    $claudeProcesses = Get-Process | Where-Object { $_.ProcessName -match "claude|Claude" } -ErrorAction SilentlyContinue
    if ($claudeProcesses) {
        Write-Host ""
        Write-Host ("=" * 70) -ForegroundColor Yellow
        Write-Warning "IMPORTANT: Claude Code is currently running!"
        Write-Host ("=" * 70) -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  You MUST fully restart Claude Code for the MCP server to work:" -ForegroundColor Yellow
        Write-Host "  1. Close ALL Claude Code windows/terminals" -ForegroundColor White
        Write-Host "  2. Kill all Claude processes (or use option below)" -ForegroundColor White
        Write-Host "  3. Start Claude Code again" -ForegroundColor White
        Write-Host ""

        $response = Read-Host "Kill Claude Code processes now? (y/N)"
        if ($response -eq "y" -or $response -eq "Y") {
            Write-Info "Stopping Claude Code processes..."
            $claudeProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Success "[OK] Claude Code processes stopped. You can now restart it."
        }
        else {
            Write-Warning "Please manually restart Claude Code for changes to take effect"
        }
        Write-Host ""
    }

    Write-Info "Next Steps:"
    Write-Host "  1. " -NoNewline
    Write-Host "RESTART CLAUDE CODE COMPLETELY " -ForegroundColor Yellow -NoNewline
    Write-Host "(close all windows & restart)" -ForegroundColor White
    Write-Host "  2. Ensure OpenMemory services are running (check ports 8080, 8081)" -ForegroundColor White
    Write-Host "  3. The MCP server provides 48 tools for memory and context management" -ForegroundColor White
    Write-Host ""
    Write-Host "  NOTE: " -NoNewline -ForegroundColor Cyan
    Write-Host "If you see tools but no resources, the backend services aren't running!" -ForegroundColor Yellow
}
else {
    Write-Info "No updates were made. Use -Force to reconfigure."
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Green
Write-Host ""
