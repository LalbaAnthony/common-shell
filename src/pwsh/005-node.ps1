# Node
function nr { npm run @args }
function nrb { npm run build }
function nrd { npm run dev }
function nrt { npm run test }
function nstart { npm start }
function nout { npm outdated }
function nls { npm list -g --depth=0 }
function nci { npm ci }
function nsetup {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue node_modules, .vite, .nuxt, .cache
    npm i
}

function yr { yarn run @args }
function yrb { yarn run build }
function yrt { yarn run test }
function yrd { yarn run dev }
function ystart { yarn start }
function ysetup {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue node_modules, .vite, .nuxt, .cache
    yarn install
}

# Quasar
function qd { quasar dev }
function qb { quasar build }
