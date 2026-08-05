# =================================================================================
# Self
# =================================================================================

function cshdel() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/uninstall.ps1 | Invoke-Expression }
function cshup() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.ps1 | Invoke-Expression }
