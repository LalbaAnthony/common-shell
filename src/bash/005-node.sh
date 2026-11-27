# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

# Node
alias nr='npm run'
alias nrb='npm run build'
alias nrd='npm run dev'
alias nrt='npm run test'
alias nstart='npm start'
alias nout='npm outdated'
alias nls='npm list -g --depth=0'
alias nci='npm ci'
alias node18="npm install -g n ; n 18"
alias node22="npm install -g n ; n 22"
alias node24="npm install -g n ; n 24"
alias node25="npm install -g n ; n 25"
alias nsetup='rm -rf node_modules ; rm -rf .vite .nuxt .cache ; npm i'

alias yr='yarn run'
alias yrb='yarn run build'
alias yrd='yarn run dev'
alias yrt='yarn run test'
alias ystart='yarn start'
alias ysetup='rm -rf node_modules && rm -rf .vite .nuxt .cache && yarn install'

# Quasar
alias qd='quasar dev'
alias qb='quasar build'
