function nr { npm run @args }
function nrb { npm run build }
function nrd { npm run dev }
function nrt { npm run test }
function nstart { npm start }
function nsetup {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue node_modules, .vite, .cache, package-lock.json
    npm i
}

function yr { yarn run @args }
function yrb { yarn run build }
function yrd { yarn run dev }
function yrt { yarn run test }
function ystart { yarn start }
function ysetup {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue node_modules, .vite, .cache, yarn.lock
    yarn install
}

# Run npm run dev in front(end)/ and back(end)/ folders concurrently
function npdev {
    $front = @('front', 'frontend') | Where-Object { Test-Path $_ -PathType Container } | Select-Object -Last 1
    $back  = @('back', 'backend')   | Where-Object { Test-Path $_ -PathType Container } | Select-Object -Last 1

    if (-not $front -and -not $back) {
        Write-Host "No front(end)/ or back(end)/ directory here"
        return
    }

    $names = @(); $colors = @(); $cmds = @()
    if ($front) { $names += 'front'; $colors += 'cyan';    $cmds += "cd $front && npm run dev" }
    if ($back)  { $names += 'back';  $colors += 'magenta'; $cmds += "cd $back && npm run dev" }

    npx concurrently -n ($names -join ',') -c ($colors -join ',') @cmds
}

# Quasar
function qd { quasar dev }
function qb { quasar build }
