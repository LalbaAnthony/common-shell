# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias cshdel='bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/uninstall.sh)'
alias cshmgr='bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/migration.sh)'
alias cshupd='bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/common-shell/main/scripts/install.sh)'
alias cshall='cshupd ; cshmgr' # Migration should be after update since migration may nuke everything using cshdel but cshupd would restore everything necessary
alias cshopen='cd ~ ; ls -la .bashrc .bashrc_extra 2>/dev/null' # Go home and show the shell config files
