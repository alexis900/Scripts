if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

<#
.SYNOPSIS
Version: 0.3.0
This script will install and configure the following components on the target home computer in Windows 11 or later:
- Windows Update
- Install winget
- Configure Windows Shell

.EXAMPLE
Run the script with:
./Setup-FirstConfig-Online.ps1

.NOTES
- This script is intended to be run on a Windows 11 or later home computer.
- This script is intended to be run as an Administrator.
#>

function WUpdate {
    Install-WindowsUpdate -NotCategory "Drivers" -MicrosoftUpdate -AcceptAll -IgnoreReboot
}
function WindowsUpdateSettings {
    if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
        WUpdate
    } else {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201  -Force
        Install-Module -Name PSWindowsUpdate -Force
        WUpdate
    }  
}

function InstallWinGet {
    Import-Module Appx
    if (Test-Path -Path "$PSScriptRoot\Apps\") {
        
    } else {
        New-Item -Path "$PSScriptRoot\Apps\" -ItemType Directory
    }

    if (Test-Path -Path "$PSScriptRoot\Apps\Microsoft.VCLibs.x64.14.00.Desktop.appx") {
        Add-AppxPackage -Path "$PSScriptRoot\Apps\Microsoft.VCLibs.x64.14.00.Desktop.appx"
    } else {
        Invoke-WebRequest -Uri "https://download.microsoft.com/download/4/7/c/47c6134b-d61f-4024-83bd-b9c9ea951c25/14.0.30035.0-Desktop/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile "$PSScriptRoot\Apps\Microsoft.VCLibs.x64.14.00.Desktop.appx"
        Add-AppxPackage -Path "$PSScriptRoot\Apps\Microsoft.VCLibs.x64.14.00.Desktop.appx"
    }
    
    if (Test-Path -Path "$PSScriptRoot\Apps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle") {
        Add-AppxPackage -Path "$PSScriptRoot\Apps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    } else {
        Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "$PSScriptRoot\Apps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Add-AppxPackage -Path "$PSScriptRoot\Apps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    }
}

function Settings {
    # Set Start Menu in Left
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0
    # Hide Chat in Taskbar
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0
    # Change in Explorer the initial location to Computer and not Home Folder
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Launch to' -Value 1
    # Set Windows Terminal as default
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'NewProgID' -Value 'Microsoft.WindowsTerminal_8wekyb3d8bbwe'
    # Set Start Menu desing
    # Activate the Memory Integrity Protection
    #Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard' -Name 'Enabled' -Value 1
    #HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard
}

WindowsUpdateSettings
InstallWinGet
Settings

winget upgrade --all --accept-source-agreements #Update all apps
winget install --id=Microsoft.VisualStudioCode -h --accept-package-agreements --accept-source-agreements #VisualStudioCode
winget install --id=XP8JK4HZBVF435 -h --accept-package-agreements --accept-source-agreements #AutoDarkModeApp
# Clean the hard disk with cleanmgr for better performance
C:\Windows\System32\cleanmgr.exe /s /t /d
# Install AutoDarkModeApp
#$env:APPDATA\\Local\Programs\AutoDarkMode\AutoDarkModeApp.exe


Write-Host -NoNewline -Object 'Press any key to return to the main menu...' -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')