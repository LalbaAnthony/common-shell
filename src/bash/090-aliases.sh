# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

hxy () {
    local location=${1:-Toulouse}
    npx @lalba-anthony/hexasky "$location"
}

mdclean () {
    npx @lalba-anthony/md-cleaner $1
}

ayc () {
    cshupd
}
