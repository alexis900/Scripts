if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

<#
.SYNOPSIS
Version: 0.4.2
This script will install and configure the following components on the target home computer in Windows 11 or later:
- Windows Update
- Install winget
- Install initial software
- Configure Windows Shell
- Import Shedule Tasks 
- Cleanup disk space

.EXAMPLE
Run the script with:
./Setup-FirstConfig-Online.ps1

.NOTES
- This script is intended to be run on a Windows 11 or later home computer.
- This script is intended to be run as an Administrator.
#>
$appsDir = "$PSScriptRoot\Apps"
$configDir = "$PSScriptRoot\Configs"

function WindowsUpdateSettings {
    $wupdate = {
        Install-WindowsUpdate -NotCategory "Drivers" -MicrosoftUpdate -AcceptAll -IgnoreReboot
    }

    if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
        Invoke-Command -ScriptBlock $wupdate
    } else {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201  -Force
        Install-Module -Name PSWindowsUpdate -Force
        Invoke-Command -ScriptBlock $wupdate
    }  
}
function TestPath ($Path) {
    if (Test-Path $Path) {
        # No action required
    } else {
        New-Item -ItemType Directory -Path $Path
    }
}

function InstallWinGet {
    Import-Module Appx
    $URLVClibs = "https://download.microsoft.com/download/4/7/c/47c6134b-d61f-4024-83bd-b9c9ea951c25/14.0.30035.0-Desktop/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $URLAppInstaller = "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $VCLibs = $URLVClibs.Split('/')[-1]
    $AppInstaller = $URLAppInstaller.Split('/')[-1]
    $VCLibsPath = "$appsDir\$VCLibs"
    $AppInstallerPath = "$appsDir\$AppInstaller"

    TestPath $appsDir

    if (Test-Path -Path "$VCLibsPath") {
        Add-AppxPackage -Path "$VCLibsPath"
    } else {
        Invoke-WebRequest -Uri $URLVClibs -OutFile $VCLibsPath
        Add-AppxPackage -Path $VCLibsPath
    }
    
    if (Test-Path -Path $AppInstallerPath) {
        Add-AppxPackage -Path $AppInstallerPath
    } else {
        Invoke-WebRequest -Uri $URLAppInstaller -OutFile $AppInstallerPath
        Add-AppxPackage -Path $AppInstallerPath
    }
}

function ExplorerSettings {
    # Set Start Menu in Left
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0
    # Hide Chat in Taskbar
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0
    # Hide Taskview in Taskbar
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 0
    # Hide Taskview in Taskbar
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_Layout' -Value 1
    # Change in Explorer the initial location to Computer and not Home Folder
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Launch to' -Value 1
    # Allwais show file extensions in Explorer
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowFileExt' -Value 1
    # Show the full path in Explorer
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowFullPathInTitle' -Value 1
    # Enable Location Settings
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' -Name 'Value' -Value 'Allow'
    # Disable Location Settings in MS Teams
    #Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location\MicrosoftTeams_8wekyb3d8bbwe' -Name 'Value' -Value 'Deny'

    # Activate the Memory Integrity Protection
    #Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard' -Name 'Enabled' -Value 1
    #HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard    
}

function InstallApps {
    winget uninstall MicrosoftTeams_8wekyb3d8bbwe --accept-source-agreements # Uninstall Microsoft Teams
    winget upgrade --all --accept-source-agreements # Update all apps
    winget install --id=Microsoft.VisualStudioCode -h --accept-package-agreements --accept-source-agreements # VisualStudioCode
    winget install --id=Git.Git -h --accept-package-agreements --accept-source-agreements # Git
    winget install --id=7zip.7zip -h --accept-package-agreements --accept-source-agreements # 7zip
    winget install --id=calibre.calibre -h --accept-package-agreements --accept-source-agreements # Calibre
    winget install --id=Valve.Steam -h --accept-package-agreements --accept-source-agreements # Steam
    winget install --id=Microsoft.OpenJDK.17 -h --accept-package-agreements --accept-source-agreements # Java
    winget install --id=TheDocumentFoundation.LibreOffice -h --accept-package-agreements --accept-source-agreements # LibreOffice
    winget install --id=9NFH4HJG2Z9H -h --accept-package-agreements --accept-source-agreements # qBittorrent
    winget install --id=XP8JK4HZBVF435 -h --accept-package-agreements --accept-source-agreements # AutoDarkModeApp
    winget install --id=9MZ1SNWT0N5D -h --accept-package-agreements --accept-source-agreements # PowerShell 7
    winget install --id=9NBDXK71NK08 -h --accept-package-agreements --accept-source-agreements # WhatsApp Beta
    winget install --id=9N97ZCKPD60Q -h --accept-package-agreements --accept-source-agreements # Unigram
    winget install --id=XPDP273C0XHQH2 -h --accept-package-agreements --accept-source-agreements # Adobe Acrobat Reader DC
    winget install --id=XPDM1ZW6815MQM -h --accept-package-agreements --accept-source-agreements # VLC
    winget install --id=9NCBCSZSJRSB -h --accept-package-agreements --accept-source-agreements # Spotify
    winget install --id=9N1Z0JXB224X -h --accept-package-agreements --accept-source-agreements # UUP Media Creator
    winget install --id=9NGHP3DX8HDX -h --accept-package-agreements --accept-source-agreements # Files
    winget install --id=9ND14WHFRGSX -h --accept-package-agreements --accept-source-agreements # Modern Winver
    winget install --id=9PMMSR1CGPWG -h --accept-package-agreements --accept-source-agreements # HEIF Image Extensions
    winget install --id=9N95Q1ZZPMH4 -h --accept-package-agreements --accept-source-agreements # MPEG-2 Video Extension
    winget install --id=9MVZQVXJBQ9V -h --accept-package-agreements --accept-source-agreements # AV1 Video Extension
    winget install --id=9PG2DK419DRG -h --accept-package-agreements --accept-source-agreements # Webp Image Extensions
    winget install --id=9N4WGH0Z6VHQ -h --accept-package-agreements --accept-source-agreements # HEVC Video Extensions
}

function ConfigAutoDarkMode {
    $AutoDarkModePath = "$env:APPDATA\AutoDarkMode"
    TestPath = $AutoDarkModePath
    # Copy the config file and initialize the AutoDarkMode
    Copy-Item -Path "$configDir\AutoDarkMode\config.yaml" -Destination "$AutoDarkModePath\config.yaml"
    Start-Process -FilePath "$env:LOCALAPPDATA\Programs\AutoDarkMode\AutoDarkModeSvc.exe"
    
}

function ConfigWindowsTerminal {
    # Set Windows Terminal as default
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'NewProgID' -Value 'Microsoft.WindowsTerminal_8wekyb3d8bbwe'
    # Copy Settings file
    Copy-Item -Path "$configDir\Windows Terminal\settings.json" -Destination "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
}

function WindowsSheduler {
    # Create Sheduler Task to Sync Time 
    Register-ScheduledTask -Xml (Get-Content ("$configDir\Scheduler\SyncTime.xml") | Out-String ) -TaskName "SyncTime"
    # Create Sheduler Task to Update Apps with winget
    Register-ScheduledTask -Xml (Get-Content ("$configDir\Scheduler\UpdateAll.xml") | Out-String ) -TaskName "UpdateAll"
}

function ConfigApps {
    ConfigAutoDarkMode
    #ConfigWindowsTerminal
}

WindowsUpdateSettings
InstallWinGet
WindowsSheduler
InstallApps
ExplorerSettings
ConfigApps


# Clean the hard disk with cleanmgr for better performance
cleanmgr /verylowdisk


Write-Host -NoNewline -Object 'Press any key to return to the main menu...' -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')