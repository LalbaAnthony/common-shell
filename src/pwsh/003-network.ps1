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

# Flush the local DNS resolver cache
function dnsflush {
    try {
        Clear-DnsClientCache -ErrorAction Stop
        Write-Host "Flushed DNS client cache"
    }
    catch {
        Write-Host "Failed to flush DNS client cache: $($_.Exception.Message)"
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

# Measure latency, download and upload against Cloudflare's speed test - one stream, at most 10 s per direction
function speedcheck {
    $base = 'https://speed.cloudflare.com'
    $bytes = 99999999 # Largest payload the endpoint serves - 100000000 and up gets a 403

    # Five empty requests over one connection: first byte minus pre-transfer time is one round trip
    $out = curl.exe -fsS -w '%{time_starttransfer} %{time_pretransfer}\n' @(1..5 | ForEach-Object { "$base/__down?bytes=0" })
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Latency test failed"
        return
    }
    $rtts = @($out | ForEach-Object {
            $t = $_ -split ' '
            ([double]$t[0] - [double]$t[1]) * 1000
        } | Sort-Object)
    Write-Host ('Latency:  {0:F1} ms' -f $rtts[[int][math]::Floor(($rtts.Count - 1) / 2)])

    # Rates exclude handshake time; curl exit 28 is the time limit, which ends the transfer below ~80 Mbps
    $out = curl.exe -fs -o NUL --max-time 10 -w '%{size_download} %{time_starttransfer} %{time_total}' "$base/__down?bytes=$bytes"
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 28) {
        Write-Host "Download test failed (curl exit $LASTEXITCODE)"
        return
    }
    $t = $out -split ' '
    $d = [double]$t[2] - [double]$t[1]
    $mbps = 0
    if ($d -gt 0) { $mbps = [double]$t[0] * 8 / $d / 1e6 }
    Write-Host ('Download: {0:F1} Mbps' -f $mbps)

    $payload = [System.IO.Path]::GetTempFileName()
    try {
        # Sized without writing 100 MB to disk: NTFS reads past the written data as zeros
        $stream = [System.IO.File]::OpenWrite($payload)
        try { $stream.SetLength($bytes) } finally { $stream.Dispose() }
        $out = curl.exe -fs -o NUL --max-time 10 -X POST -T $payload -w '%{size_upload} %{time_pretransfer} %{time_total}' "$base/__up"
        $rc = $LASTEXITCODE
    }
    finally {
        [System.IO.File]::Delete($payload) # Not Remove-Item: it misreads the ~ of an 8.3 temp path
    }
    if ($rc -ne 0 -and $rc -ne 28) {
        Write-Host "Upload test failed (curl exit $rc)"
        return
    }
    $t = $out -split ' '
    $d = [double]$t[2] - [double]$t[1]
    $mbps = 0
    if ($d -gt 0) { $mbps = [double]$t[0] * 8 / $d / 1e6 }
    Write-Host ('Upload:   {0:F1} Mbps' -f $mbps)
}
