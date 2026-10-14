Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExtraFile = Join-Path $HOME "profile_extra.ps1"

$ProfileFile = $PROFILE
# Must stay byte-identical to the hook written by install.ps1.
$ProfileHook = 'if (Test-Path "$HOME\profile_extra.ps1") { . "$HOME\profile_extra.ps1" }'

# Must stay identical to the shortcut name written by install.ps1.
$StartupLinkName = "common-shell-cshall.lnk"
# Must stay identical to the transcript path in that shortcut's arguments.
$StartupLogName = "common-shell-cshall.log"

function Unregister-StartupShortcut {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        Write-Host "No Startup folder on this platform, skipping startup shortcut."
        return
    }

    $linkPath = Join-Path ([Environment]::GetFolderPath('Startup')) $StartupLinkName
    if (Test-Path -LiteralPath $linkPath) {
        Write-Host "Removing $linkPath..."
        Remove-Item -LiteralPath $linkPath -Force
    } else {
        Write-Host "$linkPath not found, skipping."
    }

    $logPath = Join-Path $env:TEMP $StartupLogName
    if (Test-Path -LiteralPath $logPath) {
        Write-Host "Removing $logPath..."
        try {
            Remove-Item -LiteralPath $logPath -Force
        } catch {
            # Locked when cshall's migration step calls cshdel: this script
            # then runs inside the login run that holds the transcript open.
            Write-Warning "Could not remove ${logPath}: $($_.Exception.Message)"
        }
    }
}

function Uninstall-Extra {
    if (Test-Path $ExtraFile) {
        Write-Host "Removing $ExtraFile..."
        Remove-Item -Path $ExtraFile -Force
    } else {
        Write-Host "$ExtraFile not found, skipping."
    }
}

function Unregister-FromProfile {
    if ([string]::IsNullOrEmpty($ProfileFile)) {
        Write-Host "No profile path for this host, skipping."
        return
    }

    if (-not (Test-Path $ProfileFile)) {
        Write-Host "$ProfileFile not found, skipping."
        return
    }

    $lines = @(Get-Content -Path $ProfileFile)
    if ($lines -notcontains $ProfileHook) {
        Write-Host "Hook not present in $ProfileFile, skipping."
        return
    }

    Write-Host "Removing hook from $ProfileFile..."

    $kept = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        if ($line -eq $ProfileHook) {
            # install.ps1 writes a blank separator line just before the hook.
            # Drop it too, so repeated install/uninstall cycles do not stack
            # up blank lines at the end of the profile.
            if ($kept.Count -gt 0 -and [string]::IsNullOrWhiteSpace($kept[$kept.Count - 1])) {
                $kept.RemoveAt($kept.Count - 1)
            }
            continue
        }
        $kept.Add($line)
    }

    # No -Encoding: matching Set-Content's host default avoids introducing a
    # BOM on Windows PowerShell where the profile did not already have one.
    Set-Content -Path $ProfileFile -Value $kept
}

function Main {
    # First, so nothing is left launching against a profile that is gone.
    Unregister-StartupShortcut
    Uninstall-Extra
    Unregister-FromProfile
    Write-Host "PowerShell extra uninstalled successfully!"
}

Main
