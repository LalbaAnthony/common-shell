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
