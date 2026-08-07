function cshdel() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/uninstall.ps1 | Invoke-Expression }
function cshupd() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.ps1 | Invoke-Expression }
