# Sleep and shutdown timers. Each countdown runs in a detached hidden PowerShell
# process, so it survives this terminal closing; its PID is parked in a file so any
# session can cancel it. One pending timer per action; sleep and shutdown timers are
# independent of each other.

function Get-PowerTimerPidFile {
    param([Parameter(Mandatory)][string]$Name)

    Join-Path $env:TEMP "csh-$Name-timer.pid"
}

# Replaces any pending timer of the same name. Returns the trigger time as HH:mm.
function Register-PowerTimer {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Minutes,
        [Parameter(Mandatory)][string]$Command
    )

    [void](Unregister-PowerTimer -Name $Name)

    $seconds = $Minutes * 60
    $script = "Start-Sleep -Seconds $seconds; $Command"

    $timer = Start-Process -FilePath 'powershell.exe' -PassThru -WindowStyle Hidden -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden', '-Command', $script
    Set-Content -Path (Get-PowerTimerPidFile -Name $Name) -Value $timer.Id -Encoding ascii

    (Get-Date).AddMinutes($Minutes).ToString('HH:mm')
}

# Returns $true when a pending timer was stopped, $false when there was none.
function Unregister-PowerTimer {
    param([Parameter(Mandatory)][string]$Name)

    $pidFile = Get-PowerTimerPidFile -Name $Name
    $timerPid = 0

    if (Test-Path $pidFile) {
        [void][int]::TryParse((Get-Content -Path $pidFile -TotalCount 1), [ref]$timerPid)
        Remove-Item -Path $pidFile -Force
    }

    if ($timerPid -le 0) { return $false }

    # Check the name too: a stale PID may have been recycled by an unrelated process.
    $timer = Get-Process -Id $timerPid -ErrorAction SilentlyContinue
    if (-not $timer -or $timer.Name -ne 'powershell') { return $false }

    Stop-Process -Id $timerPid -Force -ErrorAction SilentlyContinue
    return $true
}

function sleepin {
    param([int]$Minutes = 10)

    if ($Minutes -lt 1) {
        Write-Host 'Minutes must be 1 or more.'
        return
    }

    $suspend = "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Application]::SetSuspendState('Suspend', `$false, `$false)"
    $at = Register-PowerTimer -Name 'sleep' -Minutes $Minutes -Command $suspend
    Write-Host "Sleeping at $at (in $Minutes min). Cancel with: sleepcancel"
}

function sleepcancel {
    param([switch]$Quiet)

    $cancelled = Unregister-PowerTimer -Name 'sleep'
    if ($Quiet) { return }

    if ($cancelled) { Write-Host 'Sleep timer cancelled.' } else { Write-Host 'No sleep timer pending.' }
}

function shutdownin {
    param([int]$Minutes = 10)

    if ($Minutes -lt 1) {
        Write-Host 'Minutes must be 1 or more.'
        return
    }

    # No /f, matching sleepin's non-forced suspend: an app holding unsaved work can block it.
    $at = Register-PowerTimer -Name 'shutdown' -Minutes $Minutes -Command 'shutdown.exe /s /t 0'
    Write-Host "Shutting down at $at (in $Minutes min). Cancel with: shutdowncancel"
}

function shutdowncancel {
    param([switch]$Quiet)

    $cancelled = Unregister-PowerTimer -Name 'shutdown'
    if ($Quiet) { return }

    if ($cancelled) { Write-Host 'Shutdown timer cancelled.' } else { Write-Host 'No shutdown timer pending.' }
}
