if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

<#
.SYNOPSIS
Version: 0.4.3
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

# Get Windows build number
$currentWindowsBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuild').CurrentBuild

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
    if (-not(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path
    }
}

function InstallWinGet {
    Import-Module Appx
    $URLVClibs = "https://download.microsoft.com/download/4/7/c/47c6134b-d61f-4024-83bd-b9c9ea951c25/14.0.30035.0-Desktop/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $URLAppInstaller = "https://github.com/microsoft/winget-cli/releases/download/v1.3.1391-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $VCLibs = $URLVClibs.Split('/')[-1]
    $AppInstaller = $URLAppInstaller.Split('/')[-1]
    $VCLibsPath = "$appsDir\$VCLibs"
    $AppInstallerPath = "$appsDir\$AppInstaller"

    TestPath $appsDir

    if (Test-Path -Path "$VCLibsPath" -and $currentWindowsBuild -lt 22000) {
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
    # Allwais show file extensions in Explorer
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowFileExt' -Value 1
    # Show the full path in Explorer
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowFullPathInTitle' -Value 1
    if ($currentWindowsBuild -ge 17763 ) { # Windows 10 1809
        #Enable Clipboard History Settings
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Value 1
    }

    if ($currentWindowsBuild -ge 22000) { # Windows 11 21H2
        # Set Start Menu in Left
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0
        # Hide Chat in Taskbar
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0
        # Hide Taskview in Taskbar
        Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 0
        # Hide Taskview in Taskbar
        Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_Layout' -Value 1
        # Disable show recent files in Start Menu
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\' -Name 'Start_TrackDocs' -Value 0
        # Enable Location Settings
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' -Name 'Value' -Value 'Allow'
    }

    if ($currentWindowsBuild -ge 22621) { # Windows 11 22H2
        # Change in Explorer the initial location to Computer and not Home Folder
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Launch to' -Value 1
    }

    # Activate the Memory Integrity Protection
    #Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard' -Name 'Enabled' -Value 1
    #HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard    
}

function InstallApps {
    winget uninstall MicrosoftTeams_8wekyb3d8bbwe --accept-source-agreements # Uninstall Microsoft Teams
    winget upgrade --all --accept-source-agreements # Update all apps
    $Apps = @('Git.Git', # Git
    '7zip.7zip', # 7zip
    'calibre.calibre', # Calibre
    'Valve.Steam', # Steam
    'Microsoft.OpenJDK.17', # Java
    'TheDocumentFoundation.LibreOffice', # LibreOffice
    'XP9KHM4BK9FZ7Q', # VisualStudioCode
    '9NFH4HJG2Z9H', #qBittorrent
    'XP8JK4HZBVF435', #AutoDarkModeApp
    '9MZ1SNWT0N5D', # PowerShell Core
    '9NBDXK71NK08', # WhatsApp Beta
    '9N97ZCKPD60Q', # Unigram
    'XPDP273C0XHQH2', # Adobe Acrobat Reader DC
    'XPDM1ZW6815MQM', # VLC
    '9NCBCSZSJRSB', # Spotify
    '9N1Z0JXB224X', # UUP Media Creator
    '9NGHP3DX8HDX', # Files
    '9ND14WHFRGSX', # Modern Winver
    '9PMMSR1CGPWG', # HEIF Image Extensions
    '9N95Q1ZZPMH4', # MPEG-2 Video Extension
    '9MVZQVXJBQ9V', # AV1 Video Extension
    '9PG2DK419DRG', # Webp Image Extensions
    '9N4WGH0Z6VHQ' # HEVC Video Extensions
    '9N4D0MSMP0PT' # Extensiones de vídeo VP9
    )

    foreach ($App in $Apps) {
        winget install --id=$App --silent --accept-package-agreements --accept-source-agreements
    }
}

function ConfigAutoDarkMode {
    $AutoDarkModePath = "$env:APPDATA\AutoDarkMode"
    TestPath = $AutoDarkModePath
    # Copy the config file and initialize the AutoDarkMode
    Copy-Item -Path "$configDir\AutoDarkMode\config.yaml" -Destination "$AutoDarkModePath\config.yaml"
    Start-Process -FilePath "$env:LOCALAPPDATA\Programs\AutoDarkMode\AutoDarkModeSvc.exe"
    
}

function ConfigureGit ($gitName, $gitEmail) {
    git config --global user.name $gitName
    git config --global user.email $gitEmail
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

function SystemClean {
    # Cleanup the Recycle Bin
    Clear-RecycleBin -Path 'C:\' -Force
    cleanmgr /verylowdisk
}

WindowsUpdateSettings
InstallWinGet
InstallApps
WindowsSheduler
ExplorerSettings
ConfigureGit("Alejandro Martín Pérez", "7107538+alexis900@users.noreply.github.com")
ConfigApps
SystemClean

Write-Host -NoNewline -Object 'Press any key to return to the main menu...' -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')