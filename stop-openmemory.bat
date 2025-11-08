@echo off
REM Stop OpenMemory services
REM This is a wrapper that calls the PowerShell script

powershell -ExecutionPolicy Bypass -File "%~dp0stop-openmemory.ps1"
pause
