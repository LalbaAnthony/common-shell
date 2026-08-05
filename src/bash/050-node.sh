# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

# Node
alias nr='npm run'
alias nrb='npm run build'
alias nrd='npm run dev'
alias nrt='npm run test'
alias nstart='npm start'
alias nout='npm outdated'
alias nls='npm list -g --depth=0' # Global packages
alias nci='npm ci' # Clean install from lockfile
alias nsetup='rm -rf node_modules && rm -rf .vite .cache && rm -rf package-lock.json && npm i'
alias yr='yarn run'
alias yrb='yarn run build'
alias yrd='yarn run dev'
alias yrt='yarn run test'
alias ystart='yarn start'
alias ysetup='rm -rf node_modules && rm -rf .vite .cache && rm -rf yarn.lock && yarn install'

npdev() {
    local front="" back=""

    [ -d "front" ] && front="front"
    [ -d "frontend" ] && front="frontend"
    [ -d "back" ] && back="back"
    [ -d "backend" ] && back="backend"

    if [ -z "$front" ] && [ -z "$back" ]; then
        echo "No front(end)/ or back(end)/ directory here"
        return 1
    fi

    local names=() colors=() cmds=()
    if [ -n "$front" ]; then
        names+=("front"); colors+=("cyan"); cmds+=("cd $front && npm run dev")
    fi
    if [ -n "$back" ]; then
        names+=("back"); colors+=("magenta"); cmds+=("cd $back && npm run dev")
    fi

    npx concurrently -n "$(IFS=,; echo "${names[*]}")" -c "$(IFS=,; echo "${colors[*]}")" "${cmds[@]}"
}

# Quasar
alias qd='quasar dev'
alias qb='quasar build'
