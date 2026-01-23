# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a PowerShell-based installer script that configures a complete Windows terminal environment. The entire installer is contained in a single file (`one-step-install.ps1`) designed to be run via web invocation:

```powershell
irm "https://raw.githubusercontent.com/wmostert76/OneStep-Terminal-Installer/master/one-step-install.ps1" | iex
```

## Architecture

### Single-File Design

The installer follows a linear, procedural flow without external dependencies. All functionality is self-contained within `one-step-install.ps1`. The script must remain idempotent - safe to run multiple times without breaking existing installations.

### Key Phases

1. **Preflight**: UAC disabling, execution policy configuration, winget verification
2. **App Installation**: Winget-based package installation (Terminal, PowerShell 7, Node, Python, fonts, CLI tools)
3. **PowerShell Modules**: PSReadLine and Terminal-Icons installation for both Windows PowerShell and PowerShell 7
4. **NPM Global Tools**: Installation of AI CLI tools (gemini-cli, codex, opencode) and npm itself
5. **Profile Configuration**: Oh My Posh theme setup and PowerShell profile modifications
6. **Environment Updates**: PATH modifications and Windows broadcast for environment variable refresh

### Critical Implementation Details

**PATH Management Strategy:**
- npm global tools path is added to User PATH environment variable via `[Environment]::SetEnvironmentVariable()`
- WinGet Links directory is added to User PATH if present
- PowerShell profiles include runtime npm path detection: `npm config get prefix` is invoked in profiles to ensure session PATH includes npm globals
- System broadcasts environment changes via `SendMessageTimeout` Win32 API to notify running applications

**Profile Modification Pattern:**
- Two profiles are maintained: Windows PowerShell (`WindowsPowerShell\Microsoft.PowerShell_profile.ps1`) and PowerShell 7 (`PowerShell\Microsoft.PowerShell_profile.ps1`)
- `Update-Profile` function reads existing profiles, intelligently updates or appends configuration blocks
- Oh My Posh init line is detected by regex `'^oh-my-posh init'` and replaced if found
- Configuration blocks are idempotent - re-running the installer updates existing config rather than duplicating lines

**Windows Terminal Configuration:**
- Settings JSON is located in `LocalState\settings.json` (checks multiple candidate paths for Stable/Preview/portable versions)
- Sets `JetBrainsMono Nerd Font` as the default font for all profiles
- Identifies PowerShell 7 profile by source property `Windows.Terminal.PowershellCore` or name `PowerShell`, then sets it as default profile via GUID

## Testing the Installer

Since this is a system-level installer, testing requires careful consideration:

1. **Test in a VM or sandbox**: The script modifies system registry (UAC), execution policy, and global PATH
2. **Verify idempotency**: Run the script twice to ensure it doesn't duplicate configuration or fail on second run
3. **Check module detection**: PSReadLine sometimes locks its assembly; the installer detects this and asks for restart/rerun
4. **Test PATH changes**: After install, open a new terminal and verify npm global commands (`gemini`, `codex`, `opencode`) are accessible without full path

## Customization Points

Users customize the installer by editing these sections:

- **`$wingetIds` array** (~line 195): List of winget package IDs to install
- **`$npmPackages` array** (~line 230): Global npm packages (always install @latest)
- **Theme path** (~line 97): URL to Oh My Posh theme JSON (default: bubbles.omp.json)
- **MaximumHistoryCount** (~line 120): PSReadLine history suggestion count

**Important Change**: As of latest version, ALL packages install at `@latest` - no version pinning!

## Update Capability

The installer is **fully idempotent** and handles both fresh installs and updates:

**Winget Packages:**
- Uses `winget upgrade` for already-installed packages
- Uses `winget install` for new packages
- Always attempts to get the latest version

**NPM Packages:**
- Uses `npm install -g package@latest` to always install/update to latest
- NO version pinning - always gets the newest release
- Includes: npm, @anthropic-ai/claude-cli, @google/gemini-cli, @openai/codex, opencode-ai, opencode-windows-x64

**PowerShell Modules:**
- Uses `-Force` flag to allow updates
- Installs for both Windows PowerShell AND PowerShell 7

**Profile Configuration:**
- Intelligently updates existing profiles without duplicating entries
- Replaces old Oh My Posh init lines with new ones
- Safely handles empty profiles

## Visual Enhancements

The installer includes stunning visual feedback:

**ASCII Art Banner:**
- Large "ONE STEP" banner on startup
- Colorful section headers with box drawing characters
- Progress indicators with Unicode symbols (✓, ➜, ▶, ★, ⟳)

**Progress Feedback:**
- NPM packages show animated progress bar: `[████████████░░░░] 60%`
- Each operation shows clear status with emoji/symbol prefixes
- Color-coded output: Green (success), Yellow (info), Cyan (steps), Magenta (special)

**Completion Banner:**
- Success message in green box drawing frame
- List of available commands with descriptions
- Clear next steps for the user

## Common Modifications

When modifying the installer:

**Adding a winget package:**
```powershell
$wingetIds = @(
  'Microsoft.WindowsTerminal',
  # ... existing packages ...
  'Your.PackageId'  # Add new package
)
```

**Adding an npm global package:**
```powershell
$npmPackages = @(
  "npm",
  "@anthropic-ai/claude-cli",
  # ... existing packages ...
  "your-package"  # Add new package (no version - gets @latest)
)
```

**Changing the Oh My Posh theme:**
Replace the theme URL in `Ensure-ThemeFile` function with any theme from: https://ohmyposh.dev/docs/themes

## Error Handling Philosophy

- `$ErrorActionPreference = 'Stop'` is set globally for fail-fast behavior
- Individual operations that may fail (UAC disable, execution policy, module installs) use try-catch with warnings
- Winget operations output to console (`Out-Host`) for user visibility
- PATH modification failures are silently caught to avoid blocking completion
