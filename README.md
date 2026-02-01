# OneStep Terminal Installer

A clean, repeatable, one-step installer for your Windows terminal setup. Transforms your Windows terminal into a modern, AI-powered development environment in minutes.

## Quick Start

**One command. That's it.**

```powershell
irm "https://raw.githubusercontent.com/wmostert76/OneStep-Terminal-Installer/master/one-step-install.ps1" | iex
```

> Safe to run multiple times - The installer intelligently updates existing installations!

---

## What You Get

### Terminal Experience
- **Windows Terminal** with JetBrainsMono Nerd Font
- **PowerShell 7** set as default profile
- **Oh My Posh** with bubbles theme
- **Terminal-Icons** for beautiful directory listings
- **Smart history suggestions** with list view
- **Always runs as Administrator** by default

### AI-Powered CLI Tools
- **Claude Code** - Anthropic's Claude assistant (`claude`)
- **Gemini CLI** - Google's Gemini assistant (`gemini`)
- **Codex CLI** - OpenAI's Codex assistant (`codex`)
- **OpenCode** - AI coding assistant (`opencode`)

### Development Tools
- **Zoxide** - Smarter cd navigation (`z` command)
- **Node.js LTS** + latest npm
- **Python 3.12** with launcher
- **Git** + GitHub CLI
- **7-Zip** compression utility
- **Midnight Commander** file manager
- **Google Chrome** browser
- **UniGetUI** - Universal package manager GUI

### Windows Customization
- **Dark Mode** enabled system-wide
- **Taskbar cleaned up** - Search, Task View, Widgets, Copilot, Chat hidden
- **Chrome set as default browser**
- **Edge shortcuts removed** from desktop
- **UAC disabled** for smoother workflow

---

## Package List

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

### NPM Global Packages (Always Latest)
| Package | Command | Purpose |
|---------|---------|---------|
| `@anthropic-ai/claude-code` | `claude` | Claude AI assistant |
| `@google/gemini-cli` | `gemini` | Gemini AI assistant |
| `@openai/codex` | `codex` | OpenAI Codex assistant |
| `opencode-ai` | `opencode` | OpenCode AI tool |
| `opencode-windows-x64` | - | OpenCode Windows binary |

### PowerShell Modules
- `PSReadLine` - Enhanced command line editing with history suggestions
- `Terminal-Icons` - File and folder icons in terminal

---

## Windows Customization Details

| Setting | Value |
|---------|-------|
| **Theme** | Dark Mode (Apps + System) |
| **Search Box** | Hidden |
| **Task View** | Hidden |
| **Widgets** | Disabled |
| **Copilot Button** | Hidden |
| **Chat Icon** | Hidden |
| **Default Browser** | Chrome |
| **Terminal Elevation** | Always Administrator |

### Taskbar Pinning (Manual Step)
Windows 11 blocks programmatic taskbar pinning. After installation, manually pin:
1. Press `Win`, type `Chrome`, right-click > **Pin to taskbar**
2. Press `Win`, type `Terminal`, right-click > **Pin to taskbar**

---

## System Changes

| Change | Details |
|--------|---------|
| **Execution Policy** | `Unrestricted` (LocalMachine or CurrentUser) |
| **UAC** | Disabled via registry (requires reboot) |
| **Terminal Font** | JetBrainsMono Nerd Font |
| **Default Profile** | PowerShell 7 |
| **Terminal Elevation** | `elevate: true` in settings |
| **PATH Variables** | npm global and WinGet Links added |

---

## Customization

Edit `one-step-install.ps1` to personalize:

### Add/Remove Applications
```powershell
$wingetIds = @(
  'Microsoft.WindowsTerminal',
  'YourApp.PackageId'  # Add your apps
)
```

### Change AI Tools
```powershell
$npmPackages = @(
  "@anthropic-ai/claude-code",
  "your-npm-tool"  # Add more
)
```

### Change Oh My Posh Theme
Browse themes at https://ohmyposh.dev/docs/themes and update the URL in `Ensure-ThemeFile` function.

---

## Usage Tips

### First Run
1. Close your terminal after installation
2. Open a NEW terminal to apply PATH changes
3. Test AI commands: `claude`, `gemini`, `codex`
4. Navigate smartly: `z <directory>` instead of `cd`

### Updating
Just re-run the installer! It safely:
- Updates all packages to latest versions
- Preserves your customizations
- Fixes broken configurations

### Troubleshooting

| Issue | Solution |
|-------|----------|
| PSReadLine error | Restart PowerShell and re-run |
| Fonts not showing | Restart Windows Terminal |
| Commands not found | Close and reopen terminal |
| Taskbar icons missing | Manual pin (Windows 11 limitation) |
| Widgets still visible | Toggle off in Settings > Taskbar |

---

## License

MIT License - Feel free to use, modify, and distribute!

## Contributing

Found a bug? Want to add a feature? PRs welcome!
