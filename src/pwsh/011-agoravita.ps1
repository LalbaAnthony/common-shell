#  -------- Ample --------

# Run a command in every CRIJ site: `crij git status -sb`, or `crij { git pull; composer install }`
function crij {
    if ($args.Count -eq 0) {
        Write-Host "Usage: crij <command> [args...]"
        return
    }

    # Not `$command, $commandArgs = $args`: a one-word command would splat a positional $null
    $command = $args[0]
    $commandArgs = @($args | Select-Object -Skip 1)
    $root = Join-Path $HOME 'Desktop\Projets\Ample\CRIJ'

    foreach ($site in 'auch', 'aveyron', 'herault', 'occitanie', 'po', 'tarn', 'tarn-et-garonne') {
        $dir = Join-Path $root "crij-$site"
        Write-Host "=== crij-$site ==="

        $ok = $false
        if (Test-Path -LiteralPath $dir -PathType Container) {
            Push-Location -LiteralPath $dir
            try {
                # Cmdlets and functions never set LASTEXITCODE, so a stale value would read as a failure
                $global:LASTEXITCODE = 0
                & $command @commandArgs
                $ok = $? -and $LASTEXITCODE -eq 0
            }
            catch {
                # Unknown command, or a terminating error thrown by the command itself
                Write-Host $_.Exception.Message
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "No such directory: $dir"
        }

        if (-not $ok) { Write-Host "ERREUR dans $dir" }
    }
}

#  -------- Kronos --------

# Run a command in every 3M site: `3m git status -sb`, or `3m { git pull; composer install }`
function 3m {
    if ($args.Count -eq 0) {
        Write-Host "Usage: 3m <command> [args...]"
        return
    }

    # Not `$command, $commandArgs = $args`: a one-word command would splat a positional $null
    $command = $args[0]
    $commandArgs = @($args | Select-Object -Skip 1)
    $root = Join-Path $HOME 'Desktop\Projets\Kronos\3M'

    foreach ($site in 'mousses', 'mousquetons') {
        $dir = Join-Path $root "3-$site"
        Write-Host "=== 3-$site ==="

        $ok = $false
        if (Test-Path -LiteralPath $dir -PathType Container) {
            Push-Location -LiteralPath $dir
            try {
                # Cmdlets and functions never set LASTEXITCODE, so a stale value would read as a failure
                $global:LASTEXITCODE = 0
                & $command @commandArgs
                $ok = $? -and $LASTEXITCODE -eq 0
            }
            catch {
                # Unknown command, or a terminating error thrown by the command itself
                Write-Host $_.Exception.Message
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "No such directory: $dir"
        }

        if (-not $ok) { Write-Host "ERREUR dans $dir" }
    }
}
