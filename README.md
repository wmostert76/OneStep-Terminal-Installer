# 🚀 OneStep Terminal Installer

<p align="center">
  <img src="https://raw.githubusercontent.com/wmostert76/OneStep-Terminal-Installer/master/assets/hero-v2.svg" alt="OneStep Terminal Installer" width="860" />
</p>

<p align="center">
  <img alt="PowerShell" src="https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?logo=powershell&logoColor=white">
  <img alt="Windows" src="https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-2EA44F">
  <img alt="Updates" src="https://img.shields.io/badge/Updates-Always%20Latest-brightgreen">
</p>

```
  ██████╗ ███╗   ██╗███████╗    ███████╗████████╗███████╗██████╗
 ██╔═══██╗████╗  ██║██╔════╝    ██╔════╝╚══██╔══╝██╔════╝██╔══██╗
 ██║   ██║██╔██╗ ██║█████╗      ███████╗   ██║   █████╗  ██████╔╝
 ██║   ██║██║╚██╗██║██╔══╝      ╚════██║   ██║   ██╔══╝  ██╔═══╝
 ╚██████╔╝██║ ╚████║███████╗    ███████║   ██║   ███████╗██║
  ╚═════╝ ╚═╝  ╚═══╝╚══════╝    ╚══════╝   ╚═╝   ╚══════╝╚═╝
```

### ✨ A clean, repeatable, one-step installer for your terminal setup
**Transforms your Windows terminal into a modern, AI-powered development environment in minutes!**

## ⚡ Quick Start

**One command. That's it.**

```powershell
irm "https://raw.githubusercontent.com/wmostert76/OneStep-Terminal-Installer/master/one-step-install.ps1" | iex
```

> 🎯 **Safe to run multiple times** - The installer intelligently updates existing installations!

---

## 🎁 What You Get

### 🖥️ Terminal Experience
- ✅ **Windows Terminal** with JetBrainsMono Nerd Font as default
- ✅ **PowerShell 7** + Windows PowerShell profiles perfectly aligned
- ✅ **Oh My Posh** with the stunning bubbles theme
- ✅ **Terminal-Icons** for beautiful directory listings
- ✅ **Smart history suggestions** with list view

### 🤖 AI-Powered CLI Tools
- 🧠 **Claude CLI** - Anthropic's Claude assistant (@anthropic-ai/claude-cli)
- 💎 **Gemini CLI** - Google's Gemini assistant (@google/gemini-cli)
- 🎨 **Codex CLI** - OpenAI's Codex assistant (@openai/codex)
- 🚀 **OpenCode** - AI coding assistant (opencode-ai)

### 🛠️ Development Tools
- 📁 **Zoxide** - Smarter cd navigation (`z` command)
- 📦 **Node.js LTS** + latest npm
- 🐍 **Python 3.12** with launcher
- 🔧 **Git** + GitHub CLI
- 🗜️ **7-Zip** compression utility
- 📂 **Midnight Commander** file manager
- 🌐 **Google Chrome** browser
- 🎛️ **UniGetUI** - Universal package manager GUI

### ⚙️ System Configuration
- 🔓 **UAC disabled** (requires reboot)
- 🔐 **Execution Policy** set to Unrestricted
- 🌍 **PATH configured** for all tools automatically

---

## 📦 Complete Package List

### WinGet Packages (Always Latest)
| Package | Purpose |
|---------|---------|
| `Microsoft.WindowsTerminal` | Modern terminal emulator |
| `Microsoft.PowerShell` | PowerShell 7+ |
| `OpenJS.NodeJS.LTS` | Node.js runtime |
| `Python.Python.3.12` | Python programming language |
| `Python.Launcher` | Python version launcher |
| `DEVCOM.JetBrainsMonoNerdFont` | Developer-friendly font with icons |
| `JanDeDobbeleer.OhMyPosh` | Prompt theme engine |
| `ajeetdsouza.zoxide` | Smarter cd command |
| `GNU.MidnightCommander` | File manager |
| `Git.Git` | Version control |
| `GitHub.cli` | GitHub command line |
| `7zip.7zip` | File compression |
| `Google.Chrome` | Web browser |
| `MartiCliment.UniGetUI` | Package manager GUI |
| `EpicGames.EpicGamesLauncher` | Epic Games Store & launcher |

### NPM Global Packages (Always Latest)
| Package | Purpose |
|---------|---------|
| `npm` | Package manager itself |
| `@anthropic-ai/claude-cli` | Claude AI assistant |
| `@google/gemini-cli` | Gemini AI assistant |
| `@openai/codex` | OpenAI Codex assistant |
| `opencode-ai` | OpenCode AI tool |
| `opencode-windows-x64` | OpenCode Windows binary |

### PowerShell Modules
- `PSReadLine` - Enhanced command line editing
- `Terminal-Icons` - File and folder icons

---

## 🔧 System Changes

| Change | Details |
|--------|---------|
| **Execution Policy** | Sets `LocalMachine` (or `CurrentUser` fallback) to `Unrestricted` |
| **UAC** | Disables User Account Control via registry (⚠️ requires reboot) |
| **Terminal Font** | JetBrainsMono Nerd Font set as default |
| **Default Profile** | PowerShell 7 set as default shell |
| **PATH Variables** | npm global and WinGet Links added automatically |

---

## 🎨 Customization

The installer is highly customizable! Edit `one-step-install.ps1` to personalize:

### 📝 Common Customizations

**Add/Remove Applications** (Line ~195)
```powershell
$wingetIds = @(
  'Microsoft.WindowsTerminal',
  'YourApp.PackageId'  # Add your favorite apps
)
```

**Change AI Tools** (Line ~230)
```powershell
$npmPackages = @(
  "@anthropic-ai/claude-cli",
  "your-favorite-npm-tool"  # Add more npm packages
)
```

**Change Oh My Posh Theme** (Line ~97)
```powershell
# Replace URL with any theme from https://ohmyposh.dev/docs/themes
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/.../your-theme.omp.json"
```

**Adjust History Size** (Line ~120)
```powershell
Set-PSReadLineOption -MaximumHistoryCount 50  # Change from 10 to any number
```

---

## 💡 Usage Tips

### First Run
1. **Close your terminal** after installation completes
2. **Open a NEW terminal** to apply PATH changes
3. **Test AI commands**: Try `claude`, `gemini`, or `codex`
4. **Navigate smartly**: Use `z <directory>` instead of `cd`

### Updating Your Setup
**Just re-run the installer!** It safely:
- ✅ Updates all packages to latest versions
- ✅ Preserves your customizations
- ✅ Fixes any broken configurations
- ✅ Adds new tools from updated script

### Troubleshooting

| Issue | Solution |
|-------|----------|
| PSReadLine in use | Restart PowerShell and re-run installer |
| Fonts not showing | Restart Windows Terminal |
| Commands not found | Close and reopen terminal (PATH update needed) |
| npm tools missing | Run installer again - it will fix PATH automatically |

---

## 🌟 Features Highlight

### Beautiful Installation Experience
- 🎨 Colorful ASCII art banner
- 📊 Progress bars for package installation
- ✓ Clear success/failure indicators
- 📝 Detailed logging with emoji indicators

### Smart & Safe
- 🔄 **Idempotent**: Safe to run multiple times
- 🆙 **Auto-updates**: Always gets latest versions
- 🛡️ **Non-destructive**: Preserves user configurations where possible
- ⚡ **Fast**: Parallel operations where applicable

---

## 📄 License

MIT License - Feel free to use, modify, and distribute!

---

## 🤝 Contributing

Found a bug? Want to add a feature? PRs welcome!

## ⭐ Show Your Support

If this saved you time, give it a star! ⭐


