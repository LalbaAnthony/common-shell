function cshdel() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.ps1 | Invoke-Expression }
function cshupd() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.ps1 | Invoke-Expression }
function cshmigr() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/common-shell-migrations/main/src/main.ps1 | Invoke-Expression }
function cshopen() { Set-Location "$HOME" ; Get-ChildItem -Force -ErrorAction SilentlyContinue @("$HOME\profile_extra.ps1", $PROFILE) }
