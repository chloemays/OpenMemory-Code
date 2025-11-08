@echo off
REM Start OpenMemory services
REM This is a wrapper that calls the PowerShell script

powershell -ExecutionPolicy Bypass -File "%~dp0start-openmemory.ps1"
pause
