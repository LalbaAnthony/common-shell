Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Repo   = "LalbaAnthony/antho-common-shell"
$Branch = "main"

$ExtraFile = Join-Path $HOME "profile_extra.ps1"
$ExtraUrl  = "https://raw.githubusercontent.com/$Repo/$Branch/src/profile_extra.ps1"

$ProfileFile = $PROFILE
$ProfileHook = 'if (Test-Path "$HOME\profile_extra.ps1") { . "$HOME\profile_extra.ps1" }'

function Download-Extra {
    Write-Host "Deleting existing PowerShell extra if it exists..."
    if (Test-Path $ExtraFile) { Remove-Item -Path $ExtraFile -Force }

    Write-Host "Downloading PowerShell extra from $ExtraUrl..."
    Invoke-WebRequest -Uri $ExtraUrl -OutFile $ExtraFile -UseBasicParsing
}

function Register-InProfile {
    if (-not (Test-Path $ProfileFile)) {
        New-Item -Path $ProfileFile -ItemType File -Force | Out-Null
    }

    $content = Get-Content -Path $ProfileFile -Raw -ErrorAction SilentlyContinue
    if ($content -and $content.Contains("profile_extra.ps1")) {
        Write-Host "Hook already present in $ProfileFile, skipping."
    } else {
        Write-Host "Registering hook in $ProfileFile..."
        Add-Content -Path $ProfileFile -Value ""
        Add-Content -Path $ProfileFile -Value $ProfileHook
    }
}

function Reload-Shell {
    Write-Host "Reloading profile..."
    # dot-sourcing may not propagate to the parent shell when run via iex
    . $ProfileFile
}

function Main {
    Download-Extra
    Register-InProfile
    Reload-Shell
    Write-Host "PowerShell extra installed successfully!"
}

Main
