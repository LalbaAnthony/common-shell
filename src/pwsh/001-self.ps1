function cshdel() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.ps1 | Invoke-Expression }
function cshmgr() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/migration.ps1 | Invoke-Expression }
function cshupd() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.ps1 | Invoke-Expression }
function cshall() { cshupd ; cshmgr } # Migration should be after update since migration may nuke everything using cshdel but cshupd would restore everything necessary
function cshopen() { Set-Location "$HOME" ; Get-ChildItem -Force -ErrorAction SilentlyContinue @("$HOME\profile_extra.ps1", $PROFILE) }
