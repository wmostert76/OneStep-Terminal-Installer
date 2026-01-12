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
  $prov = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
  if (-not $prov -or $prov.Version -lt [version]'2.8.5.201') {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Host
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

  Set-Content -Path $profilePath -Value $lines
  Write-Host "Updated profile: $profilePath"
}

Write-Section "Preflight"
Ensure-Winget
Write-Ok "winget ready"

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
powershell -NoProfile -Command "Install-Module PSReadLine -Scope CurrentUser -Force" | Out-Host
powershell -NoProfile -Command "Install-Module Terminal-Icons -Scope CurrentUser -Force" | Out-Host
if (Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe') {
  & "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -Command "Install-Module Terminal-Icons -Scope CurrentUser -Force" | Out-Host
}

Write-Section "NPM Global Tools"
# NPM global packages (after Node is present)
if (Get-Command npm -ErrorAction SilentlyContinue) {
  npm install -g npm@11.7.0 | Out-Host
  npm install -g @google/gemini-cli@0.23.0 @openai/codex@0.80.0 opencode-ai@1.1.13 opencode-windows-x64@1.1.13 | Out-Host
}

Write-Section "Shell Theme + Profiles"
# Configure themes and profiles
$themePath = Ensure-ThemeFile
Update-Profile "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" "oh-my-posh init powershell --config `"$themePath`" | Invoke-Expression"
Update-Profile "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" "oh-my-posh init pwsh --config `"$themePath`" | Invoke-Expression"

Write-Section "Windows Terminal"
# Terminal settings (after Windows Terminal install)
Set-WindowsTerminalFontAndDefaultProfile

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Info "Restart Windows Terminal or run . `$PROFILE in each shell."
