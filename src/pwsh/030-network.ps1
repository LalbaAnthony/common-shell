function ports { Get-NetTCPConnection -State Listen | Sort-Object LocalPort }

function killport {
    param($port)

    if (-not $port) {
        Write-Host "Usage: killport <port_number>"
        return
    }

    $pids = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique |
        Where-Object { $_ -ne 0 -and $_ -ne $PID }

    if (-not $pids) {
        Write-Host "Nothing listening on port $port"
        return
    }

    foreach ($processId in $pids) {
        $name = (Get-Process -Id $processId -ErrorAction SilentlyContinue).ProcessName
        Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
        if ($?) {
            Write-Host "Killed $name ($processId) on port $port"
        }
        else {
            Write-Host "Failed to kill $name ($processId) - try an elevated shell"
        }
    }
}

function nlighthouse {
    param($url)

    if (-not $url) {
        Write-Host "Usage: nlighthouse <url>"
        return
    }

    npm install -g lighthouse | Out-Null
    lighthouse $url
}
