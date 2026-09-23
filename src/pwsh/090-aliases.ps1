function hxy {
    param($location)

    if (-not $location) {
        $location = "Toulouse"
    }

    npx @lalba-anthony/hexasky $location
}

function mdclean {
    param($file)

    npx @lalba-anthony/md-cleaner $file
}

function ayc {
    gyc
    Write-Host "`n"
    cshupd
}

function gyc {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\git\git_sync_repos.py')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "git_sync_repos.py script not found."
        return
    }

    python $scriptPath
}

function fzc {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\filezilla-companion\src\main.py')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "FileZilla Companion script not found."
        return
    }

    Start-Process powershell -ArgumentList "python `"$scriptPath`"" # Open in a new PowerShell window
}

function md2docx {
    param($path)

    if (-not $path) {
        Write-Host "Usage: md2docx <path>"
        return
    }

    $ErrorActionPreference = "Stop"

    $source = Resolve-Path -LiteralPath $path
    $output = [IO.Path]::ChangeExtension($source, ".docx")
    $body = [IO.File]::ReadAllBytes($source)

    Invoke-WebRequest -Method Post -Uri "http://127.0.0.1:3005/v1/convert/example?format=docx" `
        -ContentType "text/markdown; charset=utf-8" -Body $body -OutFile $output -UseBasicParsing

    Write-Host "Written $output"
}
