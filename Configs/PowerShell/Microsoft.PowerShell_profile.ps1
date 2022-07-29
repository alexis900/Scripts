oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\kali.omp.json" | Invoke-Expression
Import-Module -Name Terminal-Icons
Import-Module posh-git
#Alias

Set-Alias ll Get-ChildItem
Set-Alias -Name avenv -Value '.\venv\Scripts\activate'