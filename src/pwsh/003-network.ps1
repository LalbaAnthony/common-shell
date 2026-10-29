# Get local IP address - loopback and APIPA (169.254.x.x) addresses are noise
function ipl {
    (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -notmatch '^169\.254\.' }).IPAddress
}
function ipp { (Invoke-RestMethod https://ifconfig.me/ip).Trim() } # Get public IP address
function ports { Get-NetTCPConnection -State Listen | Sort-Object LocalPort } # List all listening ports
function randpass { [Convert]::ToBase64String((1..20 | ForEach-Object { Get-Random -Maximum 256 })) } # Generate a random password
function nettop { Get-NetTCPConnection -State Established | Sort-Object RemoteAddress } # Show open TCP connections sorted

# Ping all DNS providers (Cloudflare, Google, Quad9)
function dnscheck {
    foreach ($d in @('1.1.1.1', '8.8.8.8', '9.9.9.9')) {
        Test-Connection -ComputerName $d -Count 2
    }
}

# Kill whatever holds a port, reporting each process by name
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
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install lighthouse"
        return
    }

    lighthouse $url
}
