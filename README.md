# 🖥️ OneStep Terminal Installer

> Transform your Windows terminal into a modern, AI-powered development environment | One command setup | Beautiful & Functional

Een complete, herhaalbare one-step installer voor je Windows terminal setup. Transformeert je Windows terminal in een moderne, AI-powered development omgeving.

## ✨ Features

### Terminal Experience
- **Windows Terminal** met JetBrainsMono Nerd Font
- **PowerShell 7** als standaard profiel
- **Oh My Posh** met bubbles theme
- **Terminal-Icons** voor mooie directory listings
- **Smart history suggestions** met list view
- **Administrator by default** voor soepele workflow

### AI-Powered CLI Tools
| Tool | Command | Beschrijving |
|------|---------|--------------|
| Claude Code | `claude` | Anthropic's Claude assistant |
| Gemini CLI | `gemini` | Google's Gemini assistant |
| Codex CLI | `codex` | OpenAI's Codex assistant |
| OpenCode | `opencode` | AI coding assistant |

### Development Tools
- **Zoxide** - Slimmer cd navigatie (`z` command)
- **Node.js LTS** + latest npm
- **Python 3.12** met launcher
- **Git** + GitHub CLI
- **7-Zip**, **Midnight Commander**, **Chrome**
- **UniGetUI** - Universal package manager GUI

### Windows Customization
- 🌙 **Dark Mode** system-wide
- 🧹 **Clean Taskbar** - Search, Widgets, Copilot hidden
- 🌐 **Chrome** als default browser
- ⚡ **UAC disabled** voor snellere workflow

## 🚀 Quick Start

**One command. That's it.**

```powershell
irm "https://raw.githubusercontent.com/wmostert76/OneStep-Terminal-Installer/master/one-step-install.ps1" | iex
```

> ✅ Veilig om meerdere keren te runnen - Updates bestaande installaties intelligent!

## 📦 Package Overview

### WinGet Packages
| Package | Doel |
|---------|------|
| `Microsoft.WindowsTerminal` | Modern terminal emulator |
| `Microsoft.PowerShell` | PowerShell 7+ |
| `OpenJS.NodeJS.LTS` | Node.js runtime |
| `Python.Python.3.12` | Python |
| `DEVCOM.JetBrainsMonoNerdFont` | Developer font met icons |
| `JanDeDobbeleer.OhMyPosh` | Prompt theme engine |
| `ajeetdsouza.zoxide` | Slimmer cd command |
| `Git.Git` + `GitHub.cli` | Version control |

### NPM Global Packages
```
@anthropic-ai/claude-code → claude
@google/gemini-cli → gemini
@openai/codex → codex
opencode-ai → opencode
```

## 💡 Usage Tips

### Na Installatie
1. Sluit je terminal
2. Open een NIEUWE terminal voor PATH changes
3. Test AI commands: `claude`, `gemini`, `codex`
4. Navigeer slim: `z <directory>` ipv `cd`

### Updating
Re-run de installer! Het:
- Update alle packages naar latest
- Behoudt je customizations
- Fixt broken configurations

## 🔧 Customization

Edit `one-step-install.ps1`:

```powershell
# Apps toevoegen/verwijderen
$wingetIds = @(
  'Microsoft.WindowsTerminal',
  'YourApp.PackageId'
)

# AI tools wijzigen
$npmPackages = @(
  "@anthropic-ai/claude-code",
  "your-npm-tool"
)
```

## 🐛 Troubleshooting

| Issue | Oplossing |
|-------|-----------|
| PSReadLine error | Restart PowerShell en re-run |
| Fonts niet zichtbaar | Restart Windows Terminal |
| Commands not found | Sluit en heropen terminal |
| Widgets nog zichtbaar | Settings > Taskbar > Toggle off |

## 📄 License

MIT License - Vrij te gebruiken, wijzigen en distribueren!

