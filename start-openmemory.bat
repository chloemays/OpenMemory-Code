@echo off
REM OpenMemory-Code Unified Startup Script
REM This wrapper sets up global commands and calls the PowerShell startup script

echo.
echo ========================================
echo OpenMemory-Code Complete Setup
echo ========================================
echo.

REM First, check if global commands need to be set up
echo [1/3] Checking global command configuration...
powershell -ExecutionPolicy Bypass -Command "& { $profile = $PROFILE.CurrentUserAllHosts; if (-not $profile) { $profile = \"$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1\" }; if (-not (Test-Path $profile)) { exit 1 }; $content = Get-Content $profile -Raw -ErrorAction SilentlyContinue; if ($content -match '# OpenMemory-Code Global Commands') { exit 0 } else { exit 1 } }"

if %ERRORLEVEL% NEQ 0 (
    echo Global commands not found in PowerShell profile. Setting up...
    echo.
    powershell -ExecutionPolicy Bypass -File "%~dp0setup-global-commands.ps1" -Force
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo WARNING: Failed to setup global commands
        echo You can run setup-global-commands.ps1 manually later
        echo.
        pause
    ) else (
        echo.
        echo ========================================
        echo SUCCESS: Global Commands Configured!
        echo ========================================
        echo.
        echo You can now run these commands from ANY directory:
        echo   - openmemory-init [project-path]
        echo   - start-openmemory [-Dev]
        echo   - stop-openmemory
        echo.
        echo NOTE: Close and reopen PowerShell to use these commands
        echo.
    )
) else (
    echo Global commands already configured [OK]
    echo.
)

REM Second, check if Claude Code MCP server needs to be configured
echo [2/3] Checking Claude Code MCP server configuration...
powershell -ExecutionPolicy Bypass -File "%~dp0setup-claude-mcp.ps1" -Force

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo WARNING: Failed to configure Claude Code MCP server
    echo You can run setup-claude-mcp.ps1 manually later
    echo.
) else (
    echo.
)

echo [3/3] Starting OpenMemory services...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0start-openmemory.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to start OpenMemory-Code
    echo Please check the error messages above
    pause
    exit /b %ERRORLEVEL%
)
