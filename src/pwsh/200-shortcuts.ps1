function ayc {
    gyc
    cyc
    cshupd
}

function gyc {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\git\git_sync_projects.py')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "git_sync_projects.py script not found."
        return
    }

    python $scriptPath
}

function cyc {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\ai\claude_sync.ps1')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "claude_sync.ps1 script not found."
        return
    }

    & $scriptPath @args
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

function mdclean {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\ai\markdown_cleaner.ps1')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "markdown_cleaner.ps1 script not found."
        return
    }

    & $scriptPath @args
}

function md2pdf {
    $scriptPaths = @(
        (Join-Path $env:USERPROFILE 'projects\antho-scripts\apitemplate\markdown_to_pdf.ps1')
    )

    $scriptPath = $scriptPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $scriptPath) {
        Write-Host "markdown_to_pdf.ps1 script not found."
        return
    }

    & $scriptPath @args
}
