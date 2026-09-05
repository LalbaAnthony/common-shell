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

function md2pdf {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\markdown\markdown_to_pdf.ps1')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "markdown_to_pdf.ps1 script not found."
        return
    }

    & $scriptPath @args
}
