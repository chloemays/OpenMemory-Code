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
