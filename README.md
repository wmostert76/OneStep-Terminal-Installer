# OneStep Terminal Installer

<p align="center">
  <img src="https://raw.githubusercontent.com/wmostert76/OneStep-Terminal-Installer/master/assets/hero-v2.svg" alt="OneStep Terminal Installer" width="860" />
</p>

<p align="center">
  <img alt="PowerShell" src="https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?logo=powershell&logoColor=white">
  <img alt="Windows" src="https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-2EA44F">
</p>

A clean, repeatable, one-step installer for your terminal setup. It installs the essentials and makes PowerShell look and feel modern immediately.

## Quick start

```powershell
irm "https://raw.githubusercontent.com/wmostert76/OneStep-Terminal-Installer/master/one-step-install.ps1" | iex
```

## What you get

- Windows Terminal with a clean default profile
- PowerShell 7 and Windows PowerShell profiles aligned
- Oh My Posh with the bubbles theme
- Zoxide (smarter cd) support
- JetBrainsMono Nerd Font
- History suggestions (list view) with a clean prompt
- Terminal-Icons for nice directory listings
- Automatic UAC and Execution Policy configuration
- Node.js + npm globals (gemini-cli, codex, opencode)
- Git, GitHub CLI, 7-Zip, Midnight Commander, Chrome

## What it installs (winget)

- Microsoft.WindowsTerminal
- Microsoft.PowerShell
- OpenJS.NodeJS.LTS
- Python.Python.3.12
- Python.Launcher
- DEVCOM.JetBrainsMonoNerdFont
- JanDeDobbeleer.OhMyPosh
- ajeetdsouza.zoxide
- GNU.MidnightCommander
- Git.Git
- GitHub.cli
- 7zip.7zip
- Google.Chrome

## System Changes

- **Execution Policy:** Sets `LocalMachine` (or `CurrentUser` fallback) to `Unrestricted`.
- **UAC:** Disables User Account Control via registry (requires reboot).
- **Terminal Settings:** Configures JetBrainsMono Nerd Font as default and sets PowerShell as the default profile.

## What it installs (npm -g)

- npm@11.7.0
- @google/gemini-cli@0.23.0
- @openai/codex@0.80.0
- opencode-ai@1.1.13
- opencode-windows-x64@1.1.13

## Customization

Open `one-step-install.ps1` and edit:
- `$wingetIds` for app list
- `npm install -g ...` for global tools
- `MaximumHistoryCount` for suggestion history
- Theme path (replace `bubbles.omp.json`)

## Notes

- If PSReadLine is in use, restart PowerShell and re-run.
- If fonts do not show, restart Windows Terminal.

## License

MIT


