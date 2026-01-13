# Terminal setup installer for this machine
# - Installs: core apps, shells, fonts, and CLI tools
# - Configures: bubbles theme, history list suggestions, Windows Terminal font + default profile

$ErrorActionPreference = 'Stop'

function Write-Section($text) {
  Write-Host ""
  Write-Host ("[ " + $text + " ]") -ForegroundColor Cyan
}

function Write-Ok($text) { Write-Host ("[OK] " + $text) -ForegroundColor Green }
function Write-Info($text) { Write-Host ("[INFO] " + $text) -ForegroundColor Yellow }

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  OneStep Terminal Installer" -ForegroundColor Magenta
Write-Host "  Setup in minutes. Clean. Repeatable." -ForegroundColor DarkMagenta
Write-Host "========================================" -ForegroundColor Magenta

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
  if (Is-WingetInstalled $id) {
    Write-Ok "Already installed: $id"
    return
  }
  winget install --id $id --source winget --accept-package-agreements --accept-source-agreements | Out-Host
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

  $lines = Get-Content -Path $profilePath

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

Write-Section "Preflight"
Ensure-Winget
Write-Ok "winget ready"
Disable-UAC
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

Write-Section "Install Apps"
# Install apps in a stable order
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
  'Google.Chrome'
)
$wingetIds | ForEach-Object { Install-WingetPkg $_ }

Write-Section "PowerShell Modules"
# PowerShell modules (avoid NuGet prompt)
Ensure-NuGetProvider
try {
  powershell -NoProfile -Command "Install-Module PSReadLine -Scope CurrentUser -Force" | Out-Host
  powershell -NoProfile -Command "Install-Module Terminal-Icons -Scope CurrentUser -Force" | Out-Host
  if (Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe') {
    & "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -Command "Install-Module Terminal-Icons -Scope CurrentUser -Force" | Out-Host
  }
} catch {
  Write-Warning "Could not install PowerShell modules: $_"
}

Write-Section "NPM Global Tools"
# NPM global packages (after Node is present)
try {
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Info "Installing global NPM tools..."
    
    $npmPackages = @(
      "npm@11.7.0",
      "@google/gemini-cli@0.23.0",
      "@openai/codex@0.80.0",
      "opencode-ai@1.1.13",
      "opencode-windows-x64@1.1.13"
    )

    foreach ($pkg in $npmPackages) {
      Write-Info "Installing $pkg..."
      npm install -g $pkg | Out-Null
    }

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
    Write-Ok "Global NPM tools ready."
  }
} catch {
  Write-Warning "Could not install NPM tools: $_"
}

Write-Section "Shell Theme + Profiles"
# Configure themes and profiles
$themePath = Ensure-ThemeFile
Update-Profile "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" "oh-my-posh init powershell --config `"$themePath`" | Out-String | Invoke-Expression"
Update-Profile "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" "oh-my-posh init pwsh --config `"$themePath`" | Out-String | Invoke-Expression"

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

Write-Section "Windows Terminal"
# ...
Set-WindowsTerminalFontAndDefaultProfile

# Final PATH check for WinGet and NPM
try {
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $wingetLinks = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"
  if ((Test-Path $wingetLinks) -and ($userPath -notlike "*$wingetLinks*")) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$wingetLinks", "User")
    Write-Info "Added WinGet links to PATH."
  }
  Update-Environment
} catch {}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "CRITICAL: Please close and RESTART your terminal to apply PATH changes." -ForegroundColor Yellow
Write-Info "After restart, you can run 'gemini', 'codex', or 'opencode' immediately."
Write-Info "Restart Windows Terminal or run . `$PROFILE in each shell."

