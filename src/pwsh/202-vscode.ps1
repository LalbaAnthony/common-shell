function vsclose {
    # Close the VS Code window hosting this terminal, by walking up the process
    # tree until an editor process that actually owns a window is found.
    $editorNames = @('Code', 'Code - Insiders', 'VSCodium')

    $target = $null
    $currentId = $PID
    $seen = @{}

    while ($currentId -and -not $seen.ContainsKey($currentId)) {
        $seen[$currentId] = $true

        $proc = Get-Process -Id $currentId -ErrorAction SilentlyContinue
        if ($proc -and ($editorNames -contains $proc.Name) -and ($proc.MainWindowHandle -ne [IntPtr]::Zero)) {
            $target = $proc
            break
        }

        $info = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $currentId" -ErrorAction SilentlyContinue
        if (-not $info) { break }

        $currentId = $info.ParentProcessId
    }

    if (-not $target) {
        Write-Host "No VS Code window found in this terminal's process tree."
        return
    }

    try {
        $closed = $target.CloseMainWindow()
    }
    catch {
        Write-Host "Failed to close VS Code: $($_.Exception.Message)"
        return
    }

    if (-not $closed) {
        Write-Host "VS Code refused the close request (unsaved changes or a modal dialog?)."
    }
}

function vsdiff {
    # Open in VS Code every file touched by a git diff. Arguments are forwarded
    # to `git diff` verbatim; with none, the range matches `gd` (current branch
    # against its origin counterpart).
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$DiffArgs)

    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not a git repository."
        return
    }

    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Host "The 'code' CLI is not on PATH."
        return
    }

    $root = git rev-parse --show-toplevel
    if ($LASTEXITCODE -ne 0) { return }

    if (-not $DiffArgs -or $DiffArgs.Count -eq 0) {
        $branch = git rev-parse --abbrev-ref HEAD
        $DiffArgs = @("origin/$branch")
    }

    # --diff-filter=d drops deletions: there is nothing left to open.
    # core.quotePath=false keeps non-ASCII paths literal instead of octal-escaped.
    $files = git -c core.quotePath=false diff --name-only --diff-filter=d @DiffArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "git diff failed."
        return
    }

    $paths = @()
    foreach ($file in $files) {
        if (-not $file) { continue }
        $path = Join-Path $root $file
        if (Test-Path -LiteralPath $path) {
            $paths += $path
        }
    }

    if ($paths.Count -eq 0) {
        Write-Host "No changed files to open."
        return
    }

    # Opening a large diff one tab at a time is rarely what is wanted
    if ($paths.Count -gt 20) {
        $confirm = Read-Host "$($paths.Count) files. Open them all? [y/N]"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Aborted."
            return
        }
    }

    code @paths
    Write-Host "Opened $($paths.Count) file(s)."
}
