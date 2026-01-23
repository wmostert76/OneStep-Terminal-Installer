# Terminal setup installer for this machine
# - Installs: core apps, shells, fonts, and CLI tools
# - Configures: bubbles theme, history list suggestions, Windows Terminal font + default profile

$ErrorActionPreference = 'Stop'

# Enhanced logging functions with beautiful colors and animations
function Write-Section($text) {
  Write-Host ""
  Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "║ " -NoNewline -ForegroundColor Cyan
  Write-Host $text.PadRight(61) -NoNewline -ForegroundColor White
  Write-Host " ║" -ForegroundColor Cyan
  Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Ok($text) {
  Write-Host "  ✓ " -NoNewline -ForegroundColor Green
  Write-Host $text -ForegroundColor White
}

function Write-Info($text) {
  Write-Host "  ➜ " -NoNewline -ForegroundColor Yellow
  Write-Host $text -ForegroundColor Gray
}

function Write-Step($text) {
  Write-Host "  ▶ " -NoNewline -ForegroundColor Cyan
  Write-Host $text -ForegroundColor White
}

function Write-Success($text) {
  Write-Host "  ★ " -NoNewline -ForegroundColor Magenta
  Write-Host $text -ForegroundColor Green
}

function Show-Progress($activity, $status) {
  $dots = "." * (($global:dotCount % 3) + 1)
  $global:dotCount++
  Write-Host "`r  ⟳ " -NoNewline -ForegroundColor Cyan
  Write-Host "$activity$dots".PadRight(60) -NoNewline -ForegroundColor Gray
}

$global:dotCount = 0

# Stunning ASCII banner
Clear-Host
Write-Host ""
Write-Host "  ██████╗ ███╗   ██╗███████╗    ███████╗████████╗███████╗██████╗ " -ForegroundColor Magenta
Write-Host " ██╔═══██╗████╗  ██║██╔════╝    ██╔════╝╚══██╔══╝██╔════╝██╔══██╗" -ForegroundColor Magenta
Write-Host " ██║   ██║██╔██╗ ██║█████╗      ███████╗   ██║   █████╗  ██████╔╝" -ForegroundColor Cyan
Write-Host " ██║   ██║██║╚██╗██║██╔══╝      ╚════██║   ██║   ██╔══╝  ██╔═══╝ " -ForegroundColor Cyan
Write-Host " ╚██████╔╝██║ ╚████║███████╗    ███████║   ██║   ███████╗██║     " -ForegroundColor Blue
Write-Host "  ╚═════╝ ╚═╝  ╚═══╝╚══════╝    ╚══════╝   ╚═╝   ╚══════╝╚═╝     " -ForegroundColor Blue
Write-Host ""
Write-Host "              TERMINAL INSTALLER" -ForegroundColor White
Write-Host "          Setup in minutes. Clean. Repeatable." -ForegroundColor DarkGray
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""
Start-Sleep -Milliseconds 500

function Ensure-Winget {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install App Installer from Microsoft Store.'
  }
}

function Disable-UAC {
  Write-Info "Disabling UAC..."
  $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
  try {
    Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 0 -ErrorAction Stop
    Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 0 -ErrorAction Stop
    Set-ItemProperty -Path $uacPath -Name "PromptOnSecureDesktop" -Value 0 -ErrorAction Stop
    Write-Ok "UAC disabled (reboot required for full effect)"
  } catch {
    Write-Warning "Failed to disable UAC: $_. Ensure you are running as Administrator."
  }
}

function Ensure-Dir($p) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

function Is-WingetInstalled($id) {
  $out = winget list --id $id --source winget 2>$null
  return ($out -match "\b$id\b")
}

function Install-WingetPkg($id) {
  Write-Step "Processing $id"
  if (Is-WingetInstalled $id) {
    Write-Info "Upgrading if available..."
    $output = winget upgrade --id $id --source winget --accept-package-agreements --accept-source-agreements 2>&1
    if ($output -match "No applicable update found" -or $output -match "No installed package found") {
      Write-Ok "Already up-to-date: $id"
    } else {
      Write-Success "Updated: $id"
    }
  } else {
    Write-Info "Installing fresh..."
    winget install --id $id --source winget --accept-package-agreements --accept-source-agreements | Out-Null
    Write-Success "Installed: $id"
  }
}

function Ensure-NuGetProvider {
  try {
    # Ensure TLS 1.2 is available for downloads
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
    $prov = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue | Where-Object { $_.Version -ge [version]'2.8.5.201' }
    if (-not $prov) {
      Write-Info "Installing NuGet provider..."
      Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -Scope CurrentUser | Out-Null
    }
  } catch {
    Write-Warning "Could not ensure NuGet provider: $_"
  }
}

function Set-WindowsTerminalFontAndDefaultProfile {
  $settingsCandidates = @(
    "$env:LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json",
    "$env:LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\\LocalState\\settings.json",
    "$env:LOCALAPPDATA\\Microsoft\\Windows Terminal\\settings.json"
  )
  $settingsPath = $settingsCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $settingsPath) { Write-Warning 'Windows Terminal settings.json not found; skipping font/default profile.'; return }

  $settings = Get-Content -Raw -Path $settingsPath | ConvertFrom-Json
  if (-not $settings.profiles) { $settings | Add-Member -NotePropertyName profiles -NotePropertyValue @{} }
  if (-not $settings.profiles.defaults) { $settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue @{} }
  if (-not $settings.profiles.defaults.font) { $settings.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue @{} }
  $settings.profiles.defaults.font.face = 'JetBrainsMono Nerd Font'

  $psProfile = $settings.profiles.list | Where-Object { $_.source -eq 'Windows.Terminal.PowershellCore' -or $_.name -eq 'PowerShell' } | Select-Object -First 1
  if ($psProfile) { $settings.defaultProfile = $psProfile.guid }

  $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
  Write-Host "Updated Windows Terminal settings: $settingsPath"
}

function Ensure-ThemeFile {
  $themesDir = "$env:USERPROFILE\.poshthemes"
  Ensure-Dir $themesDir
  $themePath = Join-Path $themesDir 'bubbles.omp.json'
  if (-not (Test-Path $themePath)) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/bubbles.omp.json" -OutFile $themePath
  }
  return $themePath
}

function Update-Profile($profilePath, $shellInitLine) {
  Ensure-Dir (Split-Path $profilePath -Parent)
  if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Path $profilePath -Force | Out-Null }

  $content = Get-Content -Path $profilePath -ErrorAction SilentlyContinue
  $lines = if ($content) { $content } else { @() }

  # oh-my-posh init line
  $foundOmp = $false
  $lines = $lines | ForEach-Object {
    if ($_ -match '^oh-my-posh init') { $foundOmp = $true; $shellInitLine } else { $_ }
  }
  if (-not $foundOmp) { $lines = @($shellInitLine) + $lines }

  # PSReadLine history list suggestions
  if (-not ($lines -match 'PredictionViewStyle ListView')) {
    $lines += @(
      'Import-Module PSReadLine',
      'Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -HistorySearchCursorMovesToEnd',
      'try { Set-PSReadLineOption -MaximumHistoryCount 10 } catch { }'
    )
  } else {
    $lines = $lines | ForEach-Object { if ($_ -match 'MaximumHistoryCount') { 'try { Set-PSReadLineOption -MaximumHistoryCount 10 } catch { }' } else { $_ } }
  }

  # Terminal-Icons
  if (-not ($lines -match 'Import-Module Terminal-Icons')) { $lines += 'Import-Module Terminal-Icons' }

  # Ensure npm global path is in session
  $npmPathLine = '$npmPrefix = (npm config get prefix).Trim(); if ($npmPrefix -and $env:Path -notlike "*$npmPrefix*") { $env:Path += ";$npmPrefix" }'
  if (-not ($lines -match 'npm config get prefix')) { $lines += $npmPathLine }

  # zoxide
  if (-not ($lines -match 'zoxide init')) { $lines += 'zoxide init powershell | Out-String | Invoke-Expression' }

  Set-Content -Path $profilePath -Value $lines
  Write-Host "Updated profile: $profilePath"
}

Write-Section "Preflight Checks"

Write-Step "Checking winget availability..."
Start-Sleep -Milliseconds 300
Ensure-Winget
Write-Ok "winget is ready and operational"

Write-Step "Configuring UAC settings..."
Start-Sleep -Milliseconds 300
Disable-UAC

Write-Step "Setting execution policy..."
Start-Sleep -Milliseconds 300
try {
  Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force
  Write-Ok "Execution policy set to Unrestricted (LocalMachine)"
} catch {
  try {
    Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force
    Write-Ok "Execution policy set to Unrestricted (CurrentUser)"
  } catch {
    Write-Warning "Could not set execution policy: $_"
  }
}

Write-Host ""
Write-Success "Preflight complete! Ready to install..."
Start-Sleep -Milliseconds 500

Write-Section "Install Apps"
# Install apps in a stable order - always latest versions
$wingetIds = @(
  'Microsoft.WindowsTerminal',
  'Microsoft.PowerShell',
  'OpenJS.NodeJS.LTS',
  'Python.Python.3.12',
  'Python.Launcher',
  'DEVCOM.JetBrainsMonoNerdFont',
  'JanDeDobbeleer.OhMyPosh',
  'ajeetdsouza.zoxide',
  'GNU.MidnightCommander',
  'Git.Git',
  'GitHub.cli',
  '7zip.7zip',
  'Google.Chrome',
  'MartiCliment.UniGetUI'
)

Write-Host ""
Write-Info "Processing $($wingetIds.Count) applications..."
Write-Host ""

$wingetIds | ForEach-Object { Install-WingetPkg $_ }

Write-Host ""
Write-Success "All applications processed!"

Write-Section "PowerShell Modules"
# PowerShell modules (avoid NuGet prompt)
Write-Step "Ensuring NuGet provider is available..."
Ensure-NuGetProvider
Write-Ok "NuGet provider ready"

try {
  Write-Host ""
  Write-Step "Installing PSReadLine for Windows PowerShell..."
  powershell -NoProfile -Command "Install-Module PSReadLine -Scope CurrentUser -Force -AllowClobber" 2>&1 | Out-Null
  Write-Ok "PSReadLine installed (Windows PowerShell)"

  Write-Step "Installing Terminal-Icons for Windows PowerShell..."
  powershell -NoProfile -Command "Install-Module Terminal-Icons -Scope CurrentUser -Force -AllowClobber" 2>&1 | Out-Null
  Write-Ok "Terminal-Icons installed (Windows PowerShell)"

  if (Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe') {
    Write-Step "Installing Terminal-Icons for PowerShell 7..."
    & "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -Command "Install-Module Terminal-Icons -Scope CurrentUser -Force -AllowClobber" 2>&1 | Out-Null
    Write-Ok "Terminal-Icons installed (PowerShell 7)"
  }

  Write-Host ""
  Write-Success "PowerShell modules installed!"
} catch {
  Write-Warning "Could not install PowerShell modules: $_"
}

Write-Section "NPM Global Tools"
# NPM global packages (after Node is present) - Always latest versions
try {
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Info "Installing/updating global NPM tools to latest versions..."
    Write-Host ""

    $npmPackages = @(
      "npm",
      "@google/gemini-cli",
      "@anthropic-ai/claude-cli",
      "@openai/codex",
      "opencode-ai",
      "opencode-windows-x64"
    )

    $packageCount = $npmPackages.Count
    $current = 0

    foreach ($pkg in $npmPackages) {
      $current++
      $percent = [math]::Round(($current / $packageCount) * 100)
      $barLength = 40
      $filled = [math]::Round(($percent / 100) * $barLength)
      $bar = ("█" * $filled).PadRight($barLength, "░")

      Write-Host "`r  [$bar] $percent% " -NoNewline -ForegroundColor Cyan
      Write-Host "Installing $pkg...".PadRight(40) -NoNewline -ForegroundColor Gray

      npm install -g $pkg@latest 2>&1 | Out-Null

      Write-Host "`r  ✓ " -NoNewline -ForegroundColor Green
      Write-Host "[$bar] $percent% " -NoNewline -ForegroundColor DarkGreen
      Write-Host "$pkg installed".PadRight(40) -ForegroundColor White
    }

    Write-Host ""

    # Ensure npm global bin is in PATH (Works for ALL npm packages)
    $npmPrefix = (npm config get prefix).Trim()
    if ($npmPrefix) {
      $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
      if ($currentPath -notlike "*$npmPrefix*") {
        Write-Info "Adding $npmPrefix to User PATH (Enables all global npm tools)..."
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$npmPrefix", "User")
        $env:Path += ";$npmPrefix"
      }
    }
    Write-Success "Global NPM tools ready (latest versions installed)"
  }
} catch {
  Write-Warning "Could not install NPM tools: $_"
}

Write-Section "Shell Theme + Profiles"

Write-Step "Downloading Oh My Posh theme (bubbles)..."
$themePath = Ensure-ThemeFile
Write-Ok "Theme downloaded: bubbles.omp.json"

Write-Host ""
Write-Step "Configuring Windows PowerShell profile..."
Update-Profile "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" "oh-my-posh init powershell --config `"$themePath`" | Out-String | Invoke-Expression"
Write-Ok "Windows PowerShell profile configured"

Write-Step "Configuring PowerShell 7 profile..."
Update-Profile "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" "oh-my-posh init pwsh --config `"$themePath`" | Out-String | Invoke-Expression"
Write-Ok "PowerShell 7 profile configured"

Write-Host ""
Write-Success "Shell profiles ready with bubbles theme!"

function Update-Environment {
  Write-Info "Refreshing environment variables..."
  $code = @'
    [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
  $type = Add-Type -MemberDefinition $code -Name "NativeMethods" -Namespace "Win32" -PassThru
  $HWND_BROADCAST = [IntPtr]0xffff
  $WM_SETTINGCHANGE = 0x001a
  $result = [UIntPtr]::Zero
  $type::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", 2, 5000, [ref]$result) | Out-Null
}

Write-Section "Windows Terminal Configuration"

Write-Step "Locating Windows Terminal settings..."
Set-WindowsTerminalFontAndDefaultProfile
Write-Ok "Windows Terminal configured with JetBrainsMono Nerd Font"

# Final PATH check for WinGet and NPM
Write-Host ""
Write-Step "Finalizing PATH environment variables..."
try {
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $wingetLinks = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"
  if ((Test-Path $wingetLinks) -and ($userPath -notlike "*$wingetLinks*")) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$wingetLinks", "User")
    Write-Ok "WinGet links added to PATH"
  }
  Update-Environment
  Write-Ok "Environment variables refreshed"
} catch {}

# Completion banner
Write-Host ""
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                               ║" -ForegroundColor Green
Write-Host "║            ✓ INSTALLATION COMPLETED SUCCESSFULLY!             ║" -ForegroundColor Green
Write-Host "║                                                               ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  🎉 Your terminal is now supercharged!" -ForegroundColor Magenta
Write-Host ""
Write-Host "  ⚠  NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  ═════════════" -ForegroundColor DarkYellow
Write-Host "  1. Close this terminal window" -ForegroundColor White
Write-Host "  2. Open a NEW terminal to apply all PATH changes" -ForegroundColor White
Write-Host "  3. Enjoy your modern terminal setup!" -ForegroundColor White
Write-Host ""
Write-Host "  📦 Available Commands:" -ForegroundColor Cyan
Write-Host "  ─────────────────────" -ForegroundColor DarkCyan
Write-Host "     • claude    - Anthropic Claude CLI" -ForegroundColor Gray
Write-Host "     • gemini    - Google Gemini CLI" -ForegroundColor Gray
Write-Host "     • codex     - OpenAI Codex CLI" -ForegroundColor Gray
Write-Host "     • opencode  - OpenCode AI assistant" -ForegroundColor Gray
Write-Host "     • z <path>  - Smart directory navigation (Zoxide)" -ForegroundColor Gray
Write-Host ""
Write-Host "  💡 To reload your profile in current shell: " -NoNewline -ForegroundColor Yellow
Write-Host ". `$PROFILE" -ForegroundColor White
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

