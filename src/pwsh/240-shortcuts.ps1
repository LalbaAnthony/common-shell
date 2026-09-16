function fzopen {
    $sitemanager = Join-Path $env:APPDATA 'FileZilla'

    Invoke-Item $sitemanager
}

function obsopen {
    $sitemanager = Join-Path $env:APPDATA 'obsidian'

    Invoke-Item $sitemanager
}

