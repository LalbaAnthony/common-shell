function hostsopen {
    $folder = 'C:\Windows\System32\drivers\etc'
    Invoke-Item $folder
}

function fzopen {
    $folder = Join-Path $env:APPDATA 'FileZilla'
    Invoke-Item $folder
}

function obsopen {
    $folder = Join-Path $env:APPDATA 'obsidian'
    Invoke-Item $folder
}

