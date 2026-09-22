# Boxstarter script for Windows 10 / 11, with a reduced install on Windows 7 SP1 and 8.x.
#
# Windows 10 gets everything. On 7 / 8.x the OS-specific tweaks are skipped and apps
# whose current releases require Windows 10 are either pinned to their last compatible
# version or left out (see the "legacy" branches below).

# --- Detect Windows version ---
$build = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
if ($build -lt 7601) {
  throw "Windows 7 SP1 (build 7601) or later is required. Detected build $build."
}
$isWin8Plus     = $build -ge 9200    # Windows 8.0: Appx apps, native ISO mounting, DISM cmdlets
$isWin10Plus    = $build -ge 10240   # Windows 10 1507
$hasWslFeature  = $build -ge 14393   # Windows 10 1607: WSL as an optional feature
$hasWinTerminal = $build -ge 18362   # Windows 10 1903: Windows Terminal
$hasWslInstall  = $build -ge 19041   # Windows 10 2004: `wsl --install`
Write-Host "Detected Windows build $build (Windows 10+: $isWin10Plus)"

# Windows 7 / 8.x default to TLS 1.0, which GitHub and most download hosts refuse.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072   # 3072 = Tls12

# --- Computer name ---
# Asked once, up front. The answer is cached so Boxstarter's post-reboot re-runs
# don't prompt again. Set BOXSTARTER_COMPUTERNAME to skip the prompt entirely.
# NetBIOS rules: 1-15 chars, letters/digits/hyphens, no leading or trailing hyphen, not all digits.
$defaultName = 'woprbox'
$nameCache = Join-Path $env:LOCALAPPDATA 'Boxstarter\computername.txt'

function Test-ComputerName($name) {
  return ($name -match '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,13}[A-Za-z0-9])?$') -and ($name -notmatch '^\d+$')
}

if ($env:BOXSTARTER_COMPUTERNAME) {
  $computername = $env:BOXSTARTER_COMPUTERNAME
} elseif (Test-Path $nameCache) {
  $computername = (Get-Content $nameCache | Select-Object -First 1).Trim()
} else {
  do {
    $computername = Read-Host "Computer name [$defaultName]"
    if ([string]::IsNullOrWhiteSpace($computername)) { $computername = $defaultName }
    $valid = Test-ComputerName $computername
    if (-not $valid) { Write-Warning "'$computername' is not a valid computer name (1-15 letters, digits or hyphens; not all digits)." }
  } until ($valid)
}
if (-not (Test-ComputerName $computername)) {
  throw "'$computername' is not a valid computer name."
}
New-Item -Path (Split-Path $nameCache) -ItemType Directory -Force | Out-Null
Set-Content -Path $nameCache -Value $computername

function Set-ComputerNameIfNeeded($name) {
  if ($env:COMPUTERNAME -ieq $name) { return }
  Write-Host "Renaming computer '$env:COMPUTERNAME' -> '$name' (takes effect after reboot)"
  if (Get-Command Rename-Computer -ErrorAction SilentlyContinue) {
    Rename-Computer -NewName $name -Force
  } else {
    # PowerShell 2 (stock Windows 7) has no Rename-Computer.
    (Get-WmiObject Win32_ComputerSystem).Rename($name) | Out-Null
  }
}

# --- Disable Settings ---
Disable-UAC

# --- Update Windows settings (all versions) ---
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions
Set-WindowsExplorerOptions -DisableOpenFileExplorerToQuickAccess -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess

# Better File Explorer
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1

# Change Windows Updates to "Notify to schedule restart"
# Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name UxOption -Type DWord -Value 1

# --- Update Windows settings (Windows 10+) ---
if ($isWin10Plus) {
  Disable-BingSearch
  Disable-GameBarTips

  # Ad Privacy
  If (-Not (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
    New-Item -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo | Out-Null
  }
  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo -Name Enabled -Type DWord -Value 0

  # Disable activity tracking
  If (-Not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System")) {
    New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Force | Out-Null
  }
  @('EnableActivityFeed','PublishUserActivities','UploadUserActivities') |% { Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Name $_ -Type DWord -Value 0 }

  # Disable Bing search results in start menu
  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name BingSearchEnabled -Type DWord -Value 0

  # Disable SmartScreen filter for store apps
  Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost -Name EnableWebContentEvaluation -Type DWord -Value 0

  # Disable Telemetry (requires a reboot to take effect)
  If (-Not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")) {
    New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection -Force | Out-Null
  }
  Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection -Name AllowTelemetry -Type DWord -Value 0
  Get-Service DiagTrack,Dmwappushservice -ErrorAction SilentlyContinue | Stop-Service | Set-Service -StartupType Disabled

  # Disable Xbox Gamebar
  Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name AppCaptureEnabled -Type DWord -Value 0
  Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name GameDVR_Enabled -Type DWord -Value 0

  # WiFi Sense: disable hotspot sharing
  # Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting -Name value -Type DWord -Value 0
  # WiFi Sense: disable hotspot auto-connect
  Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots -Name value -Type DWord -Value 0
}

# --- Uninstall Microsoft junk (Windows 8+) ---
if ($isWin8Plus) {
  Get-AppxPackage Microsoft.*3D* | Remove-AppxPackage
  Get-AppxPackage Microsoft.*advertising* | Remove-AppxPackage
  Get-AppxPackage Microsoft.549981C3F5F10 | Remove-AppxPackage   # Cortana
  Get-AppxPackage Microsoft.Bing* | Remove-AppxPackage
  Get-AppxPackage Microsoft.GetHelp | Remove-AppxPackage
  Get-AppxPackage Microsoft.Getstarted | Remove-AppxPackage
  Get-AppxPackage Microsoft.Messaging | Remove-AppxPackage
  Get-AppxPackage Microsoft.MicrosoftOfficeHub | Remove-AppxPackage
  Get-AppxPackage Microsoft.MicrosoftSolitaireCollection | Remove-AppxPackage
  Get-AppxPackage Microsoft.MicrosoftStickyNotes | Remove-AppxPackage
  Get-AppxPackage Microsoft.MixedReality.Portal | Remove-AppxPackage
  Get-AppxPackage Microsoft.Office.OneNote | Remove-AppxPackage
  Get-AppxPackage Microsoft.Office.Sway | Remove-AppxPackage
  Get-AppxPackage Microsoft.OneConnect | Remove-AppxPackage
  Get-AppxPackage Microsoft.People | Remove-AppxPackage
  Get-AppxPackage Microsoft.SkypeApp | Remove-AppxPackage
  Get-AppxPackage Microsoft.Wallet | Remove-AppxPackage
  Get-AppxPackage Microsoft.Windows.Photos | Remove-AppxPackage
  Get-AppxPackage Microsoft.WindowsAlarms | Remove-AppxPackage
  Get-AppxPackage Microsoft.WindowsFeedbackHub | Remove-AppxPackage
  Get-AppxPackage Microsoft.WindowsMaps | Remove-AppxPackage
  Get-AppxPackage Microsoft.WindowsSoundRecorder | Remove-AppxPackage
  Get-AppxPackage microsoft.windowscommunicationsapps | Remove-AppxPackage
  # Get-AppxPackage Microsoft.Xbox* | Remove-AppxPackage
  Get-AppxPackage Microsoft.Zune* | Remove-AppxPackage
}

# --- Uninstall OEM junk ---
# TBD

# --- Windows features ---
# dism.exe works on every supported version; the DISM PowerShell cmdlets only exist on Windows 8+.
dism.exe /Online /Disable-Feature /FeatureName:WindowsMediaPlayer /NoRestart /Quiet | Out-Null

if ($hasWslInstall) {
  # WSL 2: enables the Windows features and installs the kernel, no distro yet.
  wsl --install --no-distribution
} elseif ($hasWslFeature) {
  # WSL 1 on Windows 10 1607-1909.
  cinst Microsoft-Windows-Subsystem-Linux -source windowsfeatures
}
# Windows 7 / 8.x have no WSL; VirtualBox (installed below) covers Linux there.

# Rename now so one reboot covers both the rename and the WSL feature enable.
# Boxstarter resumes the script from the top afterwards; every step below is idempotent.
Set-ComputerNameIfNeeded $computername
if (Test-PendingReboot) { Invoke-Reboot }

# --- Install Software ---
$cache = "$env:userprofile\AppData\Local\ChocoCache"
New-Item -Path $cache -ItemType directory -Force

# Utilities (all versions)
cup chocolateygui --cacheLocation $cache
cup cpu-z --cacheLocation $cache
cup everything --cacheLocation $cache
cup ffmpeg --cacheLocation $cache
cup hwinfo --cacheLocation $cache
cup sysinternals --cacheLocation $cache
cup windirstat --cacheLocation $cache
cup wiztree --cacheLocation $cache

if ($isWin10Plus) {
  cup chezmoi --cacheLocation $cache
  cup handbrake --cacheLocation $cache
  cup git.install -params '"/GitAndUnixToolsOnPath /WindowsTerminal"' --cacheLocation $cache
  cup pwsh --cacheLocation $cache
  cup rufus --cacheLocation $cache
  cup tailscale --cacheLocation $cache
  cup yt-dlp --cacheLocation $cache
} else {
  # Legacy: last releases that still run on Windows 7 / 8.1.
  # chezmoi is skipped: Go 1.21+ binaries (chezmoi since late 2023) do not run on Windows 7 / 8.1.
  # Also skipped: PowerShell 7.4+, Tailscale, HandBrake 1.7+ and yt-dlp all require Windows 10.
  cup git.install --version 2.46.2 -params '"/GitAndUnixToolsOnPath"' --cacheLocation $cache
  cup rufus --version 3.22 --cacheLocation $cache
  cup virtualclonedrive --params "/NoQuickLaunch /NoDesktopShortcut" --cacheLocation $cache   # native ISO mounting arrived in Windows 8
}

if ($hasWinTerminal) {
  cup microsoft-windows-terminal --cacheLocation $cache
} else {
  cup cmder --cacheLocation $cache
}

# Basic apps (all versions)
cup autohotkey --cacheLocation $cache
cup peazip --cacheLocation $cache
cup rainmeter --cacheLocation $cache
cup vlc --cacheLocation $cache

if ($isWin10Plus) {
  cup brave --cacheLocation $cache
  cup dropbox --cacheLocation $cache
  cup flow-launcher --cacheLocation $cache
  cup googlechrome --cacheLocation $cache
  cup protonvpn --cacheLocation $cache
  cup spotify --cacheLocation $cache
} else {
  # Legacy: current Brave, Chrome, Dropbox, Spotify and ProtonVPN all require Windows 10,
  # and their last Windows 7 / 8.1 builds are no longer on Chocolatey. Install manually if needed.
  cup wox --version 1.3.524 --cacheLocation $cache   # Flow Launcher needs .NET 8, which needs Windows 10

  # Supermium: maintained Chromium fork for Windows XP through 8.1 (github.com/win32ss/supermium).
  # Not on Chocolatey, so the latest release is resolved from GitHub. The installer is a 7-Zip SFX;
  # `-y --silent` are the machine-scope switches the winget manifest uses.
  $is64 = ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') -or ($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64')
  $supermiumArch = if ($is64) { '64' } else { '32' }
  $web = New-Object Net.WebClient
  $web.Headers['User-Agent'] = 'boxstarter-install-script'   # api.github.com rejects requests without one
  try {
    $release = $web.DownloadString('https://api.github.com/repos/win32ss/supermium/releases/latest')
    # Matches supermium_<ver>_64_setup.exe but not the _setup_win10_11.exe variant.
    $supermiumUrl = [regex]::Match($release, "https://github\.com/win32ss/supermium/releases/download/[^`"]+_${supermiumArch}_setup\.exe").Value
  } catch {
    $supermiumUrl = ''
  }
  if ($supermiumUrl) {
    $supermiumInstaller = Join-Path $env:TEMP 'supermium_setup.exe'
    Write-Host "Installing Supermium from $supermiumUrl"
    $web.DownloadFile($supermiumUrl, $supermiumInstaller)
    Start-Process -FilePath $supermiumInstaller -ArgumentList '-y', '--silent' -Wait
    Remove-Item $supermiumInstaller -ErrorAction SilentlyContinue
  } else {
    Write-Warning "Could not resolve the latest Supermium installer; download it from https://github.com/win32ss/supermium/releases"
  }
}

# Game and Environment
# - not on Chocolatey; installer is downloaded to the desktop below -
# cup battle.net --cacheLocation $cache
# dosbox-staging is not packaged on Chocolatey; `dosbox-x` is the maintained alternative if 0.74 falls short.
cup dosbox --cacheLocation $cache
cup itch --cacheLocation $cache
cup virtualbox --params "/NoQuickLaunch /NoDesktopShortcut" --cacheLocation $cache

if ($isWin10Plus) {
  cup discord --cacheLocation $cache
  cup ea-app --cacheLocation $cache
  cup steam --cacheLocation $cache
} else {
  # Legacy: Steam dropped Windows 7 / 8.1 in January 2024, Discord in 2024, and the EA app
  # (Origin's replacement) is Windows 10 only. Nothing to install here.
  Write-Warning "Steam, Discord and the EA app require Windows 10; skipped."
}

# --- Host ---
Invoke-WebRequest -Uri "https://someonewhocares.org/hosts/hosts" -OutFile "${env:SystemRoot}\System32\drivers\etc\hosts"

# --- Restore Settings ---
Enable-UAC
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula -getUpdatesFromMS -SuppressReboots

# --- Manual Installers ---
Invoke-WebRequest -Uri "https://us.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe" -OutFile "${env:USERPROFILE}\desktop\Battle.net-Setup.exe"

# --- Cleanup ---
Remove-Item "$env:userprofile\AppData\Local\ChocoCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:userprofile\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# --- Setup WSL distro (Windows 10 2004+) ---
# Registers Ubuntu without launching it. Open "Ubuntu" from the Start menu
# afterwards to create the Linux user, then run chezmoi init inside it.
if ($hasWslInstall) {
  wsl --install -d Ubuntu --no-launch
}
