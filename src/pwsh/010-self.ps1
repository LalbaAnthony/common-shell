function cshdel() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.ps1 | Invoke-Expression }
function cshupd() { Invoke-RestMethod https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.ps1 | Invoke-Expression }

# Go home and show the shell config files
function cshopen() {
    Set-Location "$HOME"
    Get-ChildItem -Force -ErrorAction SilentlyContinue @("$HOME\profile_extra.ps1", $PROFILE)
}
