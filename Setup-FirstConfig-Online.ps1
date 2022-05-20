if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
function WUpdate {
    Install-WindowsUpdate -NotCategory "Drivers" -MicrosoftUpdate -AcceptAll -IgnoreReboot
}

function WindowsUpdateSettings {
    if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
        Write-Host 'Modulo PSWindowsUpdate instalado'
        WUpdate
    } else {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201  -Force
        Install-Module -Name PSWindowsUpdate -Force
        WUpdate
    }  
}

function AppUpdateSettings {
    Import-Module Appx
    $url = 'https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
    $filename = $url.split('/') | Select-Object -Last 1
    
    If (Test-Path $filename) {
        Add-AppxPackage -Path $filename
        } Else {
            Invoke-WebRequest -Uri $url -OutFile $filename
            Add-AppxPackage -Path $filename
}
}

function Settings {
    Write-Host 'Configurando la barra de Tareas'
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0
    Write-Host 'Configurando Explorador'
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Launch to' -Value 1

    #Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard' -Name 'Enabled' -Value 1
    #HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard
}

function VscodeInstall {
    winget install vscode
    code --install-extension ms-vscode.powershell --force     
}

WindowsUpdateSettings
AppUpdateSettings
Settings
#VscodeInstall

#winget install --id=XP8JK4HZBVF435 --force

#$env:APPDATA\\Local\Programs\AutoDarkMode\AutoDarkModeApp.exe


Write-Host -NoNewline -Object 'Press any key to return to the main menu...' -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')