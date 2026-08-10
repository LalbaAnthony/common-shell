function prompt {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $userColor = if ($isAdmin) { "Red" } else { "Cyan" }

    # user@host
    Write-Host "$env:USERNAME" -NoNewline -ForegroundColor $userColor
    Write-Host "@" -NoNewline -ForegroundColor White
    Write-Host "$env:COMPUTERNAME" -NoNewline -ForegroundColor Green
    Write-Host ":" -NoNewline

    # working directory
    Write-Host "$($executionContext.SessionState.Path.CurrentLocation)" `
        -NoNewline -ForegroundColor Gray

    # git branch
    $branch = git branch --show-current 2>$null
    if ($branch) {
        Write-Host " ($branch)" -NoNewline -ForegroundColor DarkGray
    }

    return " $ "
}

function ps1 {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$($executionContext.SessionState.Path.CurrentLocation)'" 
}
