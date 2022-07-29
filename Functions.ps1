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

Export-ModuleMember -Function TestPath, Install-Fonts