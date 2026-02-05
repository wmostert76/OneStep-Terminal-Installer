# Terminal setup installer for this machine
# - Installs: core apps, shells, fonts, and CLI tools
# - Configures: bubbles theme, history list suggestions, Windows Terminal font + default profile

$ErrorActionPreference = 'Stop'

# Enhanced logging functions with beautiful colors and animations
function Write-Section($text) {
  Write-Host ""
  Write-Host "======================================================================" -ForegroundColor Cyan
  Write-Host "  $text" -ForegroundColor White
  Write-Host "======================================================================" -ForegroundColor Cyan
}

function Write-Ok($text) {
  Write-Host "  [OK] " -NoNewline -ForegroundColor Green
  Write-Host $text -ForegroundColor White
}

function Write-Info($text) {
  Write-Host "  [->] " -NoNewline -ForegroundColor Yellow
  Write-Host $text -ForegroundColor Gray
}

function Write-Step($text) {
  Write-Host "  [>>] " -NoNewline -ForegroundColor Cyan
  Write-Host $text -ForegroundColor White
}

function Write-Success($text) {
  Write-Host "  [*] " -NoNewline -ForegroundColor Magenta
  Write-Host $text -ForegroundColor Green
}

function Show-Progress($activity, $status) {
  $dots = "." * (($global:dotCount % 3) + 1)
  $global:dotCount++
  Write-Host "`r  [~] " -NoNewline -ForegroundColor Cyan
  Write-Host "$activity$dots".PadRight(60) -NoNewline -ForegroundColor Gray
}

$global:dotCount = 0

# ASCII banner
Clear-Host
Write-Host ""
Write-Host "  ONE STEP TERMINAL INSTALLER" -ForegroundColor Magenta
Write-Host "  Setup in minutes. Clean. Repeatable." -ForegroundColor DarkGray
Write-Host ""
Write-Host "======================================================================" -ForegroundColor DarkGray
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
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
  )
  $settingsPath = $settingsCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $settingsPath) { Write-Warning 'Windows Terminal settings.json not found; skipping font/default profile.'; return }

  $settings = Get-Content -Raw -Path $settingsPath | ConvertFrom-Json
  if (-not $settings.profiles) { $settings | Add-Member -NotePropertyName profiles -NotePropertyValue @{} }
  if (-not $settings.profiles.defaults) { $settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue @{} }
  if (-not $settings.profiles.defaults.font) { $settings.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue @{} }
  $settings.profiles.defaults.font.face = 'JetBrainsMono Nerd Font'

  # Enable "Run as Administrator" by default for all profiles
  $settings.profiles.defaults | Add-Member -NotePropertyName elevate -NotePropertyValue $true -Force

  $psProfile = $settings.profiles.list | Where-Object { $_.source -eq 'Windows.Terminal.PowershellCore' -or $_.name -eq 'PowerShell' } | Select-Object -First 1
  if ($psProfile) { $settings.defaultProfile = $psProfile.guid }

  $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
  Write-Host "Updated Windows Terminal settings: $settingsPath"
  Write-Host "  - Font: JetBrainsMono Nerd Font"
  Write-Host "  - Elevate (Run as Admin): Enabled"
}

function Ensure-ThemeFile {
  # Primary location in user profile
  $themesDir = "$env:USERPROFILE\.poshthemes"
  Ensure-Dir $themesDir
  $themeFilePath = Join-Path $themesDir 'bubbles.omp.json'
  if (-not (Test-Path $themeFilePath)) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/bubbles.omp.json" -OutFile $themeFilePath
  }

  # Also ensure theme exists in standard oh-my-posh themes location (for WindowsApps installs)
  $standardThemesDir = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
  Ensure-Dir $standardThemesDir
  $standardThemePath = Join-Path $standardThemesDir 'bubbles.omp.json'
  if (-not (Test-Path $standardThemePath)) {
    Copy-Item -Path $themeFilePath -Destination $standardThemePath -Force
  }

  return $themeFilePath
}

function Update-Profile($profilePath, $shellInitLine) {
  Ensure-Dir (Split-Path $profilePath -Parent)
  if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Path $profilePath -Force | Out-Null }

  $content = Get-Content -Path $profilePath -ErrorAction SilentlyContinue
  $lines = if ($content) { $content } else { @() }

  # Ensure WindowsApps is on PATH (for MSIX-installed apps like oh-my-posh, claude)
  $windowsAppsLine = '$wa = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps"; if (($env:PATH -notlike "*$wa*") -and (Test-Path $wa)) { $env:PATH = "$wa;$env:PATH" }'
  if (-not ($lines -match 'Microsoft\\WindowsApps')) { $lines = @($windowsAppsLine) + $lines }

  # oh-my-posh init line (with guard)
  $guardedInitLine = 'if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { ' + $shellInitLine + ' }'
  $foundOmp = $false
  $lines = $lines | ForEach-Object {
    if ($_ -match 'oh-my-posh') { $foundOmp = $true; $guardedInitLine } else { $_ }
  }
  if (-not $foundOmp) { $lines = @($guardedInitLine) + $lines }

  # PSReadLine history list suggestions (wrapped in try/catch for non-interactive sessions)
  if (-not ($lines -match 'PredictionViewStyle ListView')) {
    $lines += @(
      'Import-Module PSReadLine',
      'try { Set-PSReadLineOption -HistorySaveStyle SaveIncrementally } catch { }',
      'try { Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -HistorySearchCursorMovesToEnd } catch { }',
      'try { Set-PSReadLineOption -MaximumHistoryCount 10000 } catch { }',
      'try { Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward } catch { }',
      'try { Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward } catch { }',
      'try { Set-PSReadLineKeyHandler -Key RightArrow -Function AcceptNextSuggestionWord } catch { }',
      'try { Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function AcceptSuggestion } catch { }'
    )
  } else {
    $lines = $lines | ForEach-Object { if ($_ -match 'MaximumHistoryCount') { 'try { Set-PSReadLineOption -MaximumHistoryCount 10000 } catch { }' } else { $_ } }
  }

  # Terminal-Icons
  if (-not ($lines -match 'Import-Module Terminal-Icons')) { $lines += 'Import-Module Terminal-Icons' }

  # posh-git for Git integration
  if (-not ($lines -match 'Import-Module posh-git')) { $lines += 'Import-Module posh-git' }

  # PSFzf for fuzzy finding (requires fzf binary - add guard)
  if (-not ($lines -match 'Import-Module PSFzf')) {
    $lines += 'if (Get-Command fzf -ErrorAction SilentlyContinue) { Import-Module PSFzf; Set-PsFzfOption -PSReadlineChordProvider "Ctrl+t" -PSReadlineChordReverseHistory "Ctrl+r" }'
  }

  # z module for directory jumping
  if (-not ($lines -match 'Import-Module z')) { $lines += 'Import-Module z' }

  # Ensure npm global path is in session
  $npmPathLine = '$npmPrefix = (npm config get prefix).Trim(); if ($npmPrefix -and $env:Path -notlike "*$npmPrefix*") { $env:Path += ";$npmPrefix" }'
  if (-not ($lines -match 'npm config get prefix')) { $lines += $npmPathLine }

  # zoxide (add guard for when not installed)
  if (-not ($lines -match 'zoxide init')) { $lines += 'if (Get-Command zoxide -ErrorAction SilentlyContinue) { zoxide init powershell | Out-String | Invoke-Expression }' }

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
  'Microsoft.PowerToys',
  'OpenJS.NodeJS.LTS',
  'Python.Python.3.12',
  'Python.Launcher',
  'DEVCOM.JetBrainsMonoNerdFont',
  'JanDeDobbeleer.OhMyPosh',
  'ajeetdsouza.zoxide',
  'junegunn.fzf',
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

# Refresh environment PATH after winget installations
Write-Section "Refreshing Environment"
Write-Step "Refreshing PATH to detect newly installed tools..."

# Get fresh PATH from registry (picks up winget installations)
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPathEnv = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPathEnv"

# Also add common Node.js installation paths explicitly
$nodePaths = @(
  "$env:ProgramFiles\nodejs",
  "${env:ProgramFiles(x86)}\nodejs",
  "$env:LOCALAPPDATA\Programs\nodejs"
)
foreach ($nodePath in $nodePaths) {
  if ((Test-Path $nodePath) -and ($env:Path -notlike "*$nodePath*")) {
    $env:Path += ";$nodePath"
  }
}

# Add npm global path if npm is now available
if (Get-Command npm -ErrorAction SilentlyContinue) {
  $npmPrefixVal = (npm config get prefix 2>$null)
  if ($npmPrefixVal) {
    $npmPrefixVal = $npmPrefixVal.Trim()
    if ($npmPrefixVal -and ($env:Path -notlike "*$npmPrefixVal*")) {
      $env:Path += ";$npmPrefixVal"
    }
  }
  Write-Ok "npm detected and PATH updated"
} else {
  Write-Warning "npm not found in PATH - will retry after PATH refresh"
}

Write-Success "Environment refreshed!"

Write-Section "PowerShell Modules"
# PowerShell modules (avoid NuGet prompt)
Write-Step "Ensuring NuGet provider is available..."
Ensure-NuGetProvider
Write-Ok "NuGet provider ready"

try {
  Write-Host ""
  # Modules to install for both Windows PowerShell and PowerShell 7
  $psModules = @('PSReadLine', 'Terminal-Icons', 'posh-git', 'PSFzf', 'z')

  Write-Step "Installing modules for Windows PowerShell..."
  foreach ($mod in $psModules) {
    Write-Info "  Installing $mod..."
    powershell -NoProfile -Command "Install-Module $mod -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue" 2>&1 | Out-Null
  }
  Write-Ok "Windows PowerShell modules installed"

  if (Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe') {
    Write-Step "Installing modules for PowerShell 7..."
    foreach ($mod in $psModules) {
      Write-Info "  Installing $mod..."
      & "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -Command "Install-Module $mod -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue" 2>&1 | Out-Null
    }
    Write-Ok "PowerShell 7 modules installed"
  }

  Write-Host ""
  Write-Success "PowerShell modules installed!"
} catch {
  Write-Warning "Could not install PowerShell modules: $_"
}

Write-Section "NPM Global Tools"
# NPM global packages (after Node is present) - Always latest versions
try {
  # Try to find npm - check common installation paths if not in PATH
  $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
  if (-not $npmCmd) {
    Write-Info "npm not in PATH, searching common locations..."
    $npmLocations = @(
      "$env:ProgramFiles\nodejs\npm.cmd",
      "${env:ProgramFiles(x86)}\nodejs\npm.cmd",
      "$env:LOCALAPPDATA\Programs\nodejs\npm.cmd",
      "$env:APPDATA\npm\npm.cmd"
    )
    foreach ($npmLoc in $npmLocations) {
      if (Test-Path $npmLoc) {
        $npmDir = Split-Path $npmLoc -Parent
        $env:Path = "$npmDir;$env:Path"
        Write-Ok "Found npm at: $npmDir"
        $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
        break
      }
    }
  }

  if ($npmCmd -or (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Info "Installing/updating global NPM tools to latest versions..."
    Write-Host ""

    $npmPackages = @(
      "npm",
      "@google/gemini-cli",
      "@openai/codex",
      "opencode-ai",
      "opencode-windows-x64"
    )

    $packageCount = $npmPackages.Count
    $current = 0

    foreach ($pkg in $npmPackages) {
      $current++
      $percent = [math]::Round(($current / $packageCount) * 100)
      Write-Step "[$current/$packageCount] Installing $pkg..."

      # Temporarily change error preference to continue (npm outputs warnings to stderr)
      $prevErrorAction = $ErrorActionPreference
      $ErrorActionPreference = 'Continue'
      try {
        npm install -g "$pkg@latest" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
          Write-Ok "$pkg installed"
        } else {
          Write-Warning "Failed to install $pkg (exit code: $LASTEXITCODE)"
        }
      } catch {
        Write-Warning "Error installing ${pkg}: $_"
      }
      $ErrorActionPreference = $prevErrorAction
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
  } else {
    Write-Warning "npm not found. Node.js may not have installed correctly. Try running the script again after restart."
  }
} catch {
  Write-Warning "Could not install NPM tools: $_"
}

Write-Section "Claude Code Installation"
Write-Step "Installing Claude Code via native installer..."
try {
  # Use the official Anthropic installer (recommended over npm)
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://claude.ai/install.ps1'))
  Write-Success "Claude Code installed via native installer"
} catch {
  Write-Warning "Could not install Claude Code: $_"
  Write-Info "You can install manually later with: irm https://claude.ai/install.ps1 | iex"
}

Write-Section "Shell Theme + Profiles"

Write-Step "Downloading Oh My Posh theme (bubbles)..."
$ompThemePath = Ensure-ThemeFile
Write-Ok "Theme downloaded: bubbles.omp.json"

Write-Host ""
# Detect actual Documents folder (handles OneDrive redirection)
$documentsFolder = [Environment]::GetFolderPath('MyDocuments')
if (-not $documentsFolder) {
  $documentsFolder = "$env:USERPROFILE\Documents"
}
Write-Info "Documents folder detected: $documentsFolder"

Write-Step "Configuring Windows PowerShell profile..."
Update-Profile "$documentsFolder\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" "oh-my-posh init powershell --config `"$ompThemePath`" | Out-String | Invoke-Expression"
Write-Ok "Windows PowerShell profile configured"

Write-Step "Configuring PowerShell 7 profile..."
Update-Profile "$documentsFolder\PowerShell\Microsoft.PowerShell_profile.ps1" "oh-my-posh init pwsh --config `"$ompThemePath`" | Out-String | Invoke-Expression"
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
  $userPathFinal = [Environment]::GetEnvironmentVariable("Path", "User")
  $wingetLinks = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"
  if ((Test-Path $wingetLinks) -and ($userPathFinal -notlike "*$wingetLinks*")) {
    [Environment]::SetEnvironmentVariable("Path", "$userPathFinal;$wingetLinks", "User")
    Write-Ok "WinGet links added to PATH"
  }
  Update-Environment
  Write-Ok "Environment variables refreshed"
} catch {}

Write-Section "Windows Customization"

# Set Windows to Dark Mode
Write-Step "Setting Windows to Dark Mode..."
try {
  $themeRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
  Set-ItemProperty -Path $themeRegPath -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force
  Set-ItemProperty -Path $themeRegPath -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force
  Write-Ok "Windows Dark Mode enabled"
} catch {
  Write-Warning "Could not set Dark Mode: $_"
}

# Set Chrome as Default Browser
Write-Step "Setting Google Chrome as default browser..."
try {
  $chromePathX64 = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
  $chromePathX86 = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
  $chromePath = if (Test-Path $chromePathX64) { $chromePathX64 } elseif (Test-Path $chromePathX86) { $chromePathX86 } else { $null }

  if ($chromePath) {
    # Register Chrome URL associations via registry
    $chromeProgId = "ChromeHTML"

    # Set HTTP/HTTPS associations
    reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" /v ProgId /t REG_SZ /d $chromeProgId /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" /v ProgId /t REG_SZ /d $chromeProgId /f 2>&1 | Out-Null

    # Set .htm and .html file associations
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.htm\UserChoice" /v ProgId /t REG_SZ /d $chromeProgId /f 2>&1 | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\UserChoice" /v ProgId /t REG_SZ /d $chromeProgId /f 2>&1 | Out-Null

    Write-Ok "Chrome set as default browser (registry updated)"
  } else {
    Write-Warning "Chrome not found. Ensure it is installed."
  }
} catch {
  Write-Warning "Could not set Chrome as default: $_"
}

# Remove Edge shortcut from Desktop
Write-Step "Removing Microsoft Edge shortcut from Desktop..."
try {
  $desktopPaths = @(
    "$env:USERPROFILE\Desktop\Microsoft Edge.lnk",
    "$env:PUBLIC\Desktop\Microsoft Edge.lnk",
    "$env:USERPROFILE\Desktop\Edge.lnk",
    "$env:PUBLIC\Desktop\Edge.lnk"
  )
  foreach ($edgePath in $desktopPaths) {
    if (Test-Path $edgePath) {
      Remove-Item $edgePath -Force
      Write-Ok "Removed: $edgePath"
    }
  }
  Write-Ok "Edge desktop shortcut removed"
} catch {
  Write-Warning "Could not remove Edge shortcut: $_"
}

# Clean Taskbar - Keep only Chrome and Terminal (in that order)
Write-Step "Configuring taskbar pins (Chrome, Terminal)..."
try {
  $pinnedPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

  # First, remove ALL existing pins
  if (Test-Path $pinnedPath) {
    Get-ChildItem -Path $pinnedPath -Filter "*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Ok "Cleared existing pins"
  }

  # Clear Windows 11 Taskband cache
  $taskbandPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
  if (Test-Path $taskbandPath) {
    Remove-ItemProperty -Path $taskbandPath -Name "Favorites" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $taskbandPath -Name "FavoritesResolve" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $taskbandPath -Name "FavoritesVersion" -ErrorAction SilentlyContinue
  }

  # Ensure pinned folder exists
  if (-not (Test-Path $pinnedPath)) {
    New-Item -ItemType Directory -Path $pinnedPath -Force | Out-Null
  }

  # Create Chrome shortcut
  $chromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
  if (-not (Test-Path $chromePath)) {
    $chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
  }
  if (Test-Path $chromePath) {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut((Join-Path $pinnedPath "Google Chrome.lnk"))
    $Shortcut.TargetPath = $chromePath
    $Shortcut.WorkingDirectory = Split-Path $chromePath -Parent
    $Shortcut.Save()
    Write-Ok "Chrome shortcut created"
  }

  # Create Terminal shortcut
  $wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
  if (Test-Path $wtPath) {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut((Join-Path $pinnedPath "Windows Terminal.lnk"))
    $Shortcut.TargetPath = $wtPath
    $Shortcut.Save()
    Write-Ok "Terminal shortcut created"
  }

  Write-Info "NOTE: Windows 11 may require manual pinning - see instructions below"
} catch {
  Write-Warning "Could not modify taskbar pins: $_"
}

# Disable Search box on Taskbar
Write-Step "Disabling Search box on Taskbar..."
try {
  $searchPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
  if (-not (Test-Path $searchPath)) {
    New-Item -Path $searchPath -Force | Out-Null
  }
  Set-ItemProperty -Path $searchPath -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force
  Write-Ok "Search box disabled"
} catch {
  Write-Warning "Could not disable Search box: $_"
}

# Disable Task View button on Taskbar
Write-Step "Disabling Task View button..."
try {
  $explorerPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
  Set-ItemProperty -Path $explorerPath -Name "ShowTaskViewButton" -Value 0 -Type DWord -Force
  Write-Ok "Task View button disabled"
} catch {
  Write-Warning "Could not disable Task View: $_"
}

# Disable Widgets on Taskbar (Windows 11) - Multiple methods
Write-Step "Disabling Widgets..."
try {
  # Method 1: via reg.exe (better permissions handling)
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f 2>&1 | Out-Null

  # Method 2: Disable News and Interests / Feeds
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v ShellFeedsTaskbarViewMode /t REG_DWORD /d 2 /f 2>&1 | Out-Null

  # Method 3: Policy level
  reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f 2>&1 | Out-Null

  Write-Ok "Widgets disabled"
} catch {
  Write-Warning "Could not disable Widgets: $_"
}

# Disable Copilot button on Taskbar (Windows 11)
Write-Step "Disabling Copilot button..."
try {
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f 2>&1 | Out-Null
  Write-Ok "Copilot button disabled"
} catch {
  Write-Warning "Could not disable Copilot button: $_"
}

# Disable Chat icon (Windows 11)
Write-Step "Disabling Chat icon..."
try {
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f 2>&1 | Out-Null
  Write-Ok "Chat icon disabled"
} catch {
  Write-Warning "Could not disable Chat icon: $_"
}

# Close any open Settings windows
Write-Step "Closing Settings windows..."
try {
  Get-Process SystemSettings -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Write-Ok "Settings windows closed"
} catch {}

# Restart Explorer to apply taskbar changes
Write-Step "Restarting Explorer to apply changes..."
try {
  Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  Start-Process explorer
  Write-Ok "Explorer restarted - taskbar changes applied"
} catch {
  Write-Warning "Could not restart Explorer: $_"
}

Write-Host ""
Write-Success "Windows customization complete!"

# Completion banner
Write-Host ""
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "           INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Your terminal is now supercharged!" -ForegroundColor Magenta
Write-Host ""
Write-Host "  NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  ============" -ForegroundColor DarkYellow
Write-Host "  1. Close this terminal window" -ForegroundColor White
Write-Host "  2. Open a NEW terminal to apply all PATH changes" -ForegroundColor White
Write-Host "  3. Enjoy your modern terminal setup!" -ForegroundColor White
Write-Host ""
Write-Host "  Available Commands:" -ForegroundColor Cyan
Write-Host "  --------------------" -ForegroundColor DarkCyan
Write-Host "     claude    - Anthropic Claude CLI" -ForegroundColor Gray
Write-Host "     gemini    - Google Gemini CLI" -ForegroundColor Gray
Write-Host "     codex     - OpenAI Codex CLI" -ForegroundColor Gray
Write-Host "     opencode  - OpenCode AI assistant" -ForegroundColor Gray
Write-Host "     z <path>  - Smart directory navigation (Zoxide)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Windows Customizations Applied:" -ForegroundColor Cyan
Write-Host "  ---------------------------------" -ForegroundColor DarkCyan
Write-Host "     Dark Mode enabled" -ForegroundColor Gray
Write-Host "     Search box hidden from taskbar" -ForegroundColor Gray
Write-Host "     Task View button hidden" -ForegroundColor Gray
Write-Host "     Widgets disabled (verify in Settings)" -ForegroundColor Gray
Write-Host "     Copilot and Chat icons hidden" -ForegroundColor Gray
Write-Host "     Taskbar: Chrome (1st), Terminal (2nd)" -ForegroundColor Gray
Write-Host "     Terminal always runs as Administrator" -ForegroundColor Gray
Write-Host "     Chrome set as default browser" -ForegroundColor Gray
Write-Host "     Edge shortcut removed from desktop" -ForegroundColor Gray
Write-Host ""
Write-Host ""
Write-Host "  IF TASKBAR ICONS ARE MISSING (Windows 11 limitation):" -ForegroundColor Yellow
Write-Host "  -------------------------------------------------------" -ForegroundColor DarkYellow
Write-Host "  1. Press Windows key, type 'Chrome'" -ForegroundColor White
Write-Host "     Right-click > Pin to taskbar" -ForegroundColor Gray
Write-Host "  2. Press Windows key, type 'Terminal'" -ForegroundColor White
Write-Host "     Right-click > Pin to taskbar" -ForegroundColor Gray
Write-Host ""
Write-Host "  To reload your profile: " -NoNewline -ForegroundColor Yellow
Write-Host ". `$PROFILE" -ForegroundColor White
Write-Host ""
Write-Host "======================================================================" -ForegroundColor DarkGray
Write-Host ""
