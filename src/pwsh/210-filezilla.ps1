function fzcode {
    $sitemanager = Join-Path $env:APPDATA 'FileZilla\sitemanager.xml'

    code $sitemanager
}