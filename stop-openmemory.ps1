#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Stop OpenMemory services

.DESCRIPTION
    Stops all OpenMemory services running on ports 8080, 8081, and 8083

.EXAMPLE
    .\stop-openmemory.ps1
#>

$ErrorActionPreference = "Stop"

function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }

function Stop-ProcessOnPort {
    param([int]$Port, [string]$ServiceName)

    $connections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $Port }

    if ($connections.Count -eq 0) {
        Write-Info "No process running on port $Port"
        return
    }

    foreach ($conn in $connections) {
        $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($process) {
            Write-Warning "Stopping $ServiceName (PID: $($process.Id))..."
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            Write-Success "[OK] $ServiceName stopped"
        }
    }
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "           Stopping OpenMemory Services" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""

Stop-ProcessOnPort -Port 8080 -ServiceName "OpenMemory Backend"
Stop-ProcessOnPort -Port 8081 -ServiceName "Context Manager"
Stop-ProcessOnPort -Port 8083 -ServiceName "Logging API"

Write-Host ""
Write-Success "[OK] All OpenMemory services stopped"
Write-Host ""
