if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

<#
.SYNOPSIS
Version: 0.4.6
This script will install and configure the following components on the target home computer in Windows 11 or later:
- Change a new name to the computer
- Windows Update
- Install winget
- Install initial software from apps.json
- Configure Git*
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
Set-Variable -Name appsDir -Value "$PSScriptRoot\Apps" -Option ReadOnly
Set-Variable -Name configDir -Value "$PSScriptRoot\Configs" -Option ReadOnly
Set-Variable -Name tempDownloadDir -Value "C:\Temp" -Option ReadOnly

function TestPath ($Path) {
    if (-not(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path
    }
}

function Install-Fonts($Path){
    # Install fonts from the downloaded folder

    $fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
    foreach ($file in Get-ChildItem $Path\*.ttf) {
        $fileName = $file.Name
        if (-not(Test-Path -Path "C:\Windows\fonts\$fileName" )) {
        Write-Host $fileName
        Get-ChildItem $file | ForEach-Object { $fonts.CopyHere($_.fullname) }
        }
    }
}

# Get Windows build number

$currentWindowsBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuild').CurrentBuild

function RenameComputer {
    $computerName = Read-Host "Set the new computer name"
    if ($computerName -eq "") {
        $computerName = $env:COMPUTERNAME
    }
    $computerName = $computerName.Trim()
    $confirm = "N"
    $confirm = Read-Host "Renaming computer from $env:COMPUTERNAME to $computerName. Are you sure you want to continue? (y/N)" 
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Rename-Computer -NewName $computerName
    } else {
        Write-Host "Computer name change aborted."
    }
}
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

function InstallWinGet {
    Import-Module Appx
    $URLVClibs = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $URLAppInstaller = "https://github.com/microsoft/winget-cli/releases/download/v1.3.1391-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $VCLibs = $URLVClibs.Split('/')[-1]
    $AppInstaller = $URLAppInstaller.Split('/')[-1]
    $VCLibsPath = "$appsDir\$VCLibs"
    $AppInstallerPath = "$appsDir\$AppInstaller"

    TestPath($appsDir)
    if ((Test-Path -Path "$VCLibsPath") -and ($currentWindowsBuild -lt 22000)) {
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
    $CurrentVersionRegistryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion"
    $ExplorerRegistryPath = "$CurrentVersionRegistryPath\Explorer"
    $AdvancedRegistryPath = "$ExplorerRegistryPath\Advanced"

    # Allwais show file extensions in Explorer
    Set-ItemProperty -Path $AdvancedRegistryPath -Name 'ShowFileExt' -Value 1
    # Show the full path in Explorer
    Set-ItemProperty -Path $AdvancedRegistryPath -Name 'ShowFullPathInTitle' -Value 1

    Set-ItemProperty -Path $ExplorerRegistryPath -Name 'ShowCloudFilesInQuickAccess' -Value 0
    
    if ($currentWindowsBuild -ge 17763 ) {
        # Windows 10 1809
        #Enable Clipboard History Settings
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -Value 1
    }
    if ($currentWindowsBuild -ge 22000) {
        # Windows 11 21H2
        # Set Start Menu in Left
        Set-ItemProperty -Path $AdvancedRegistryPath -Name 'TaskbarAl' -Value 0
        # Hide Chat in Taskbar
        Set-ItemProperty -Path $AdvancedRegistryPath -Name 'TaskbarMn' -Value 0
        # Hide Taskview in Taskbar
        Set-ItemProperty -Path $AdvancedRegistryPath -Name 'ShowTaskViewButton' -Value 0
        # Hide Taskview in Taskbar
        Set-ItemProperty -Path $AdvancedRegistryPath -Name 'Start_Layout' -Value 1
        # Disable show recent files in Start Menu
        Set-ItemProperty -Path $AdvancedRegistryPath -Name 'Start_TrackDocs' -Value 0
        # Enable Location Settings
        Set-ItemProperty -Path "$CurrentVersionRegistryPath\CapabilityAccessManager\ConsentStore\location" -Name 'Value' -Value 'Allow'
    }
    if ($currentWindowsBuild -ge 22621) {
        # Windows 11 22H2
        # Change in Explorer the initial location to Computer and not Home Folder
        Set-ItemProperty -Path $AdvancedRegistryPath -Name 'Launch to' -Value 1
    }

    # Activate the Memory Integrity Protection
    #Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard' -Name 'Enabled' -Value 1
    #HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard    
}

function InstallApps {
    # Update all apps
    winget upgrade --all --accept-source-agreements
    # Import apps from apps.json file
    winget import -i "$configDir/apps.json" --ignore-unavailable --accept-package-agreements --accept-source-agreements
}

function ConfigAutoDarkMode {
    # Test if AutoDarkMode is installed
    if (Test-Path "$env:LOCALAPPDATA\Programs\AutoDarkMode\AutoDarkModeSvc.exe") {
        $AutoDarkModePath = "$env:APPDATA\AutoDarkMode"
        # Copy the config file and initialize the AutoDarkMode
        TestPath($AutoDarkModePath)
        Copy-Item -Path "$configDir\AutoDarkMode\config.yaml" -Destination "$AutoDarkModePath\config.yaml"
        Start-Process -FilePath "$env:LOCALAPPDATA\Programs\AutoDarkMode\AutoDarkModeSvc.exe"
    }
}

function ConfigGit {
    # Test if Git is installed
    if ((Test-Path -Path "C:\Program Files\Git\bin\git.exe") -or (Test-Path -Path "C:\Program Files (x86)\Git\bin\git.exe")) {
        Copy-Item -Path "$configDir\Git\.gitconfig" -Destination "$env:USERPROFILE\.gitconfig"
        Copy-Item -Path "$configDir\Git\gitconfig" -Destination "C:\Program Files\Git\etc\gitconfig"
    }
}

function ConfigWindowsTerminal {
    # Set Windows Terminal as default
    $ConsoleRegistryPath = "HKCU:\Console\%%Startup"
    New-ItemProperty –Path "HKCU:\Console" –Name "%%Startup"
    Set-ItemProperty -Path $ConsoleRegistryPath -Name 'DelegationConsole' -Value '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}'
    Set-ItemProperty -Path $ConsoleRegistryPath -Name 'DelegationTerminal' -Value '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}'
    # Copy Settings file
    #Copy-Item -Path "$configDir\Windows Terminal\settings.json" -Destination "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
}

function ConfigureOhMyPosh {
    $fontURL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Meslo.zip"
    $fontsFolder = "$tempDownloadDir\Meslo"
    if (Test-Path -Path "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe") {
        # Install Terminal-Icons from PSGallery
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force
        Install-Module -Name posh-git -Repository PSGallery -Force
        # Copy the config file of PowerShell that is used by oh-my-posh
        Copy-Item -Path $configDir/PowerShell/Microsoft.PowerShell_profile.ps1 -Destination $PROFILE
        # Create the folder for the fonts
        TestPath($tempDownloadDir)
        # Download and install the fonts
        Invoke-WebRequest -Uri $fontURL -OutFile "$fontsFolder.zip"
        Expand-Archive -Path "$fontsFolder.zip" -DestinationPath $fontsFolder
        Install-Fonts($fontsFolder)
        # Delete the temp folder
        Remove-Item -Path $tempDownloadDir -Recurse
    }
}

function WindowsSheduler {
    # Create Sheduler Task to Sync Time 
    Register-ScheduledTask -Xml (Get-Content ("$configDir\Scheduler\SyncTime.xml") | Out-String ) -TaskName "SyncTime"
    # Create Sheduler Task to Update Apps with winget
    Register-ScheduledTask -Xml (Get-Content ("$configDir\Scheduler\UpdateAll.xml") | Out-String ) -TaskName "UpdateAll"
}

function ConfigApps {
    ConfigAutoDarkMode
    ConfigWindowsTerminal
    ConfigGit
    ConfigureOhMyPosh
}

function SystemClean {
    # Cleanup the Recycle Bin
    Clear-RecycleBin -Force
    # Clean up the temp folder
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force 2> $null
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force 2> $null
    Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force 2> $null
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force 2> $null
    Remove-Item -Path "C:\Documents and Settings\*\Local Settings\temp\*" -Recurse -Force 2> $null
    Remove-Item -Path 'C:\$WINDOWS.~BT' -Recurse -Force 2> $null
    }

    cleanmgr /verylowdisk
}

RenameComputer
WindowsUpdateSettings
InstallWinGet
InstallApps
WindowsSheduler
ExplorerSettings
ConfigApps
SystemClean

# Reboot the computer to apply the changes
Restart-Computer

Write-Host -NoNewline -Object 'Press any key to return to the main menu...' -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')