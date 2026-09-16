function fzopen {
    $sitemanager = Join-Path $env:APPDATA 'FileZilla'

    Invoke-Item $sitemanager
}