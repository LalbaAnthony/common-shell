Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExtraFile = Join-Path $HOME "profile_extra.ps1"

function Uninstall-Extra {
    if (Test-Path $ExtraFile) {
        Write-Host "Removing $ExtraFile..."
        Remove-Item -Path $ExtraFile -Force
    } else {
        Write-Host "$ExtraFile not found, skipping."
    }
}

function Main {
    Uninstall-Extra
    Write-Host "PowerShell extra uninstalled successfully!"
}

Main
