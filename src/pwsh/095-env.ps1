function cpenv {
    $candidates = @(
        '.env.example'
        '.env.sample'
        '.env.dist'
        '.env.template'
    )

    $template = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1

    if (-not $template) {
        Write-Host "No env template found here (looked for: $($candidates -join ' '))."
        return
    }

    if (Test-Path -LiteralPath '.env') {
        $confirm = Read-Host "'.env' already exists. Overwrite it with '$template'? [Y/n]"
        if ($confirm -match '^[Nn]') {
            Write-Host "Aborted."
            return
        }
    }

    Copy-Item -LiteralPath $template -Destination '.env' -Force
    Write-Host "Copied '$template' to '.env'."
}
