# Claude Code MCP Setup - Robustness Improvements

## Problem
The previous version of `setup-claude-mcp.ps1` could corrupt Claude Code's configuration file, causing a JSON syntax error that prevented Claude Code from starting. The error was: `SyntaxError: Unexpected token 'C', "Claude con"... is not valid JSON`

## Root Causes
1. **BOM (Byte Order Mark) Issues**: PowerShell's `Set-Content -Encoding UTF8` adds a BOM to UTF-8 files, which can cause JSON parsers to fail
2. **No Validation**: The script didn't validate JSON before saving, so corrupted JSON could be written
3. **No Atomic Writes**: Writing directly to the config file meant partial writes could leave it corrupted
4. **Poor Error Handling**: Errors during JSON conversion could write error messages instead of JSON

## Fixes Applied

### 1. UTF-8 Without BOM
```powershell
# OLD (could add BOM):
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8

# NEW (no BOM):
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($configPath, $jsonOutput, $utf8NoBom)
```

### 2. JSON Validation
```powershell
# Validate JSON can be parsed back before saving
$jsonOutput = $config | ConvertTo-Json -Depth 10 -Compress:$false
$null = $jsonOutput | ConvertFrom-Json -ErrorAction Stop
```

### 3. Atomic File Operations
```powershell
# Write to temporary file first
$tempPath = "$configPath.tmp-$(Get-Date -Format 'yyyyMMddHHmmss')"
[System.IO.File]::WriteAllText($tempPath, $jsonOutput, $utf8NoBom)

# Validate temp file
$validateContent = [System.IO.File]::ReadAllText($tempPath, $utf8NoBom)
$null = $validateContent | ConvertFrom-Json -ErrorAction Stop

# Only replace original if validation passes
Move-Item -Path $tempPath -Destination $configPath -Force
```

### 4. Automatic Backup and Recovery
```powershell
# Always create backup before modifying
$backupPath = "$configPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -Path $configPath -Destination $backupPath -Force

# If anything fails, restore from backup
if (Test-Path $backupPath) {
    Write-Info "Restoring from backup..."
    Copy-Item -Path $backupPath -Destination $configPath -Force
}
```

### 5. Additional Validations
- Check if config file is empty before parsing
- Verify Node.js is installed (required for MCP server)
- Consistent UTF-8 encoding for both reading and writing

## Usage

The script is automatically called by `start-openmemory.bat`. It will:

1. Search for Claude Code config files in standard locations
2. Create a timestamped backup before any modifications
3. Safely add or update the OpenMemory MCP server configuration
4. Validate all JSON before saving
5. Restore from backup if anything goes wrong

### Manual Usage
```powershell
# Normal run
.\setup-claude-mcp.ps1

# Force update even if already configured
.\setup-claude-mcp.ps1 -Force
```

## Safety Features

1. **Automatic Backups**: Every config file is backed up with timestamp before modification
2. **JSON Validation**: Triple validation (before save, after save, on read)
3. **Atomic Operations**: Temp file ensures no partial writes
4. **Error Recovery**: Automatic restoration from backup on failure
5. **No Direct Modification**: Claude Code won't edit its own config (done by external script)

## What Changed in Files

### setup-claude-mcp.ps1
- Lines 125-150: Robust JSON writing for default config creation
- Lines 165-178: UTF-8 reading with validation
- Lines 200-242: Atomic file operations with validation and recovery
- Lines 53-69: Node.js installation verification

### start-openmemory.bat
- No changes needed - already calls the PowerShell script correctly

## Testing Recommendations

1. **Backup Your Config First**: Before running, manually backup:
   - `%USERPROFILE%\.claude.json`
   - Or check `%APPDATA%\Claude\` for config files

2. **Run the Script**: Execute `start-openmemory.bat` or run the PowerShell script directly

3. **Verify**: Check that Claude Code still starts and the MCP server appears in settings

4. **Backups Available**: If anything goes wrong, backups are created with timestamps:
   - Look for `*.backup-YYYYMMDD-HHMMSS` files next to your config

## Recovery Instructions

If Claude Code fails to start after running this script:

1. Find your Claude Code config directory:
   - Usually `%USERPROFILE%\.claude.json`
   - Or `%APPDATA%\Claude\claude_desktop_config.json`

2. Look for backup files in the same directory:
   - Named like `.claude.json.backup-20250110-143022`

3. Restore the most recent backup:
   ```powershell
   Copy-Item "path\to\.claude.json.backup-20250110-143022" "path\to\.claude.json" -Force
   ```

4. Restart Claude Code

## Technical Details

### JSON Structure Added
```json
{
  "mcpServers": {
    "openmemory-code-global": {
      "command": "node",
      "args": [
        "C:\\path\\to\\OpenMemory-Code\\.ai-agents\\context-injection\\mcp-server\\dist\\index.js"
      ],
      "env": {
        "CONTEXT_MANAGER_URL": "http://localhost:8081",
        "OPENMEMORY_URL": "http://localhost:8080"
      }
    }
  }
}
```

### Cross-Platform Compatibility
- Works on any Windows device
- Automatically detects OpenMemory installation path
- No hardcoded paths (except Node.js which must be in PATH)
- Handles different Claude Code installation types (CLI, Desktop)

## Summary

The script is now production-ready with multiple layers of safety:
- ✅ Prevents JSON corruption
- ✅ Automatic backups
- ✅ Validation at every step
- ✅ Atomic file operations
- ✅ Error recovery
- ✅ Cross-device compatibility

The risk of breaking Claude Code has been minimized to near zero.
