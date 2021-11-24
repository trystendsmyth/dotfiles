# --- Disable Settings ---
Disable-UAC

# --- Update Windows settings ---
Disable-BingSearch
Disable-GameBarTips

Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions
Set-WindowsExplorerOptions -DisableOpenFileExplorerToQuickAccess -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess

# Better File Explorer
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1

# Change Windows Updates to "Notify to schedule restart"
# Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name UxOption -Type DWord -Value 1

# Ad Privacy
If (-Not (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
  New-Item -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo | Out-Null
}
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo -Name Enabled -Type DWord -Value 0

# Disable activity tracking
@('EnableActivityFeed','PublishUserActivities','UploadUserActivities') |% { Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\System -Name $_ -Type DWord -Value 0 }

# Disable Bing search results in start menu
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name BingSearchEnabled -Type DWord -Value 0

# Diable SmartScreen filter for store apps
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost -Name EnableWebContentEvaluation -Type DWord -Value 0

# Disable Telemetry (requires a reboot to take effect)
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection -Name AllowTelemetry -Type DWord -Value 0
Get-Service DiagTrack,Dmwappushservice | Stop-Service | Set-Service -StartupType Disabled

# Disable Xbox Gamebar
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name AppCaptureEnabled -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name GameDVR_Enabled -Type DWord -Value 0

# WiFi Sense: disable hotspot sharing
# Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting -Name value -Type DWord -Value 0
# WiFi Sense: disable hotspot auto-connect
Set-ItemProperty -Path HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots -Name value -Type DWord -Value 0

# --- Uninstall Microsoft junk ---
Get-AppxPackage Microsoft.*3D* | Remove-AppxPackage
Get-AppxPackage Microsoft.*advertising* | Remove-AppxPackage
Get-AppxPackage Microsoft.Bing* | Remove-AppxPackage
Get-AppxPackage Microsoft.CommsPhone | Remove-AppxPackage
Get-AppxPackage Microsoft.Getstarted | Remove-AppxPackage
Get-AppxPackage Microsoft.Messaging | Remove-AppxPackage
Get-AppxPackage Microsoft.MicrosoftOfficeHub | Remove-AppxPackage
Get-AppxPackage Microsoft.MicrosoftStickyNotes | Remove-AppxPackage
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
Get-AppxPackage Microsoft.WindowsPhone | Remove-AppxPackage
Get-AppxPackage Microsoft.WindowsSoundRecorder | Remove-AppxPackage
Get-AppxPackage microsoft.windowscommunicationsapps | Remove-AppxPackage
# Get-AppxPackage Microsoft.Xbox* | Remove-AppxPackage
Get-AppxPackage Microsoft.Zune* | Remove-AppxPackage

# --- Uninstall OEM junk ---
# TBD

# Windows features
Disable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -NoRestart -WarningAction SilentlyContinue | Out-Null
cinst Microsoft-Windows-Subsystem-Linux -source windowsfeatures

# --- Install Software ---
$cache = "$env:userprofile\AppData\Local\ChocoCache"
New-Item -Path $cache -ItemType directory -Force

# Utilities
cup chezmoi --cacheLocation $cache
cup chocolateygui --cacheLocation $cache
cup cmder --cacheLocation $cache
cup cpu-z --cacheLocation $cache
cup ffmpeg --cacheLocation $cache
cup git.install -params '"/GitAndUnixToolsOnPath /WindowsTerminal"' --cacheLocation $cache
cup rufus --cacheLocation $cache
cup sysinternals --cacheLocation $cache
cup virtualclonedrive --params "/NoQuickLaunch /NoDesktopShortcut" --cacheLocation $cache
cup windirstat --cacheLocation $cache

# Basic apps
cup autohotkey --cacheLocation $cache
cup brave --cacheLocation $cache
cup dropbox --cacheLocation $cache
cup expressvpn --cacheLocation $cache
cup googlechrome --ignore-checksums --cacheLocation $cache
cup peazip --cacheLocation $cache
cup rainmeter --cacheLocation $cache
cup spotify --cacheLocation $cache
cup vlc --cacheLocation $cache
cup wox --cacheLocation $cache

# Game and Environment
# - broken install -
# cup battle.net --cacheLocation $cache
cup discord --cacheLocation $cache
cup dosbox --cacheLocation $cache
cup gamebooster --cacheLocation $cache
cup itch --cacheLocation $cache
cup origin --cacheLocation $cache
cup steam --cacheLocation $cache
cup virtualbox --params "/NoQuickLaunch /NoDesktopShortcut" --cacheLocation $cache

# --- Host ---
Invoke-WebRequest -Uri "https://someonewhocares.org/hosts/hosts" -OutFile "${env:SystemRoot}\System32\drivers\etc\hosts"

#--- Rename the Computer ---
$computername = "woprbox"
if ($env:computername -ne $computername) {
	Rename-Computer -NewName $computername
}

# --- Restore Settings ---
Enable-UAC
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula -getUpdatesFromMS -SuppressReboots

# --- Manual Installers ---
Invoke-WebRequest -Uri "https://us.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe" -OutFile "${env:USERPROFILE}\desktop\Battle.net-Setup.exe"

# --- Cleanup ---
del $env:userprofile\AppData\Local\ChocoCache\*.*
del $env:userprofile\AppData\Local\Temp\*.*

# --- Setup WSL ---
# This requires user interaction to enter the new account's un/pw, so it's last
# iwr -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile ~/Ubuntu.appx -UseBasicParsing
# Add-AppxPackage -Path ~/Ubuntu.appx
# run the distro once and have it install locally with root user, unset password
# RefreshEnv
# ubuntu1804 install --root
# ubuntu1804 run apt update
# ubuntu1804 run apt upgrade -y