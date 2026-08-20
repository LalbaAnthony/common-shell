# Sleep timer. The countdown runs in a detached hidden PowerShell process, so it
# survives this terminal closing; its PID is parked in a file so any session can
# cancel it. One pending timer at a time.

function Get-SleepTimerPidFile { Join-Path $env:TEMP 'csh-sleep-timer.pid' }

function sleepin {
    param([int]$Minutes = 10)

    if ($Minutes -lt 1) {
        Write-Host 'Minutes must be 1 or more.'
        return
    }

    sleepcancel -Quiet

    $seconds = $Minutes * 60
    $suspend = "Start-Sleep -Seconds $seconds; Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Application]::SetSuspendState('Suspend', `$false, `$false)"

    $timer = Start-Process -FilePath 'powershell.exe' -PassThru -WindowStyle Hidden -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden', '-Command', $suspend
    Set-Content -Path (Get-SleepTimerPidFile) -Value $timer.Id -Encoding ascii

    $at = (Get-Date).AddMinutes($Minutes).ToString('HH:mm')
    Write-Host "Sleeping at $at (in $Minutes min). Cancel with: sleepcancel"
}

function sleepcancel {
    param([switch]$Quiet)

    $pidFile = Get-SleepTimerPidFile
    $timerPid = 0

    if (Test-Path $pidFile) {
        [void][int]::TryParse((Get-Content -Path $pidFile -TotalCount 1), [ref]$timerPid)
        Remove-Item -Path $pidFile -Force
    }

    if ($timerPid -le 0) {
        if (-not $Quiet) { Write-Host 'No sleep timer pending.' }
        return
    }

    # Check the name too: a stale PID may have been recycled by an unrelated process.
    $timer = Get-Process -Id $timerPid -ErrorAction SilentlyContinue
    if (-not $timer -or $timer.Name -ne 'powershell') {
        if (-not $Quiet) { Write-Host 'No sleep timer pending.' }
        return
    }

    Stop-Process -Id $timerPid -Force -ErrorAction SilentlyContinue
    if (-not $Quiet) { Write-Host 'Sleep timer cancelled.' }
}
