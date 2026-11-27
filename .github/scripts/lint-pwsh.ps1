#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Lints PowerShell scripts with a pinned PSScriptAnalyzer.

.DESCRIPTION
    With no -Path, every tracked *.ps1 file in the repository is linted.
    Rules and the failing severity threshold live in PSScriptAnalyzerSettings.psd1.

    When GITHUB_ACTIONS is "true", findings are emitted as workflow annotations
    so they land on the PR diff.

.PARAMETER Path
    Explicit files to analyse instead of the tracked *.ps1 set.

.PARAMETER Version
    PSScriptAnalyzer version to pin. Defaults to $env:PSSA_VERSION, then 1.25.0.

.EXAMPLE
    ./.github/scripts/lint-pwsh.ps1
#>
#Requires -Version 5.1

[CmdletBinding()]
param(
    [string[]] $Path,
    [string] $Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Version) {
    $Version = if ($env:PSSA_VERSION) { $env:PSSA_VERSION } else { '1.25.0' }
}

Set-Location (git rev-parse --show-toplevel)

if (-not $Path) {
    # --others picks up files not yet committed; the existence test drops paths
    # that are still in the index but already deleted from the working tree.
    $Path = @(git ls-files --cached --others --exclude-standard '*.ps1')
}
$targets = @($Path | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })

if ($targets.Count -eq 0) {
    Write-Output 'No PowerShell scripts to lint.'
    exit 0
}

if (-not (Get-Module -ListAvailable PSScriptAnalyzer |
          Where-Object { $_.Version -eq [version]$Version })) {
    Write-Output "Installing PSScriptAnalyzer $Version..."
    Install-Module PSScriptAnalyzer -RequiredVersion $Version -Scope CurrentUser -Force
}
Import-Module PSScriptAnalyzer -RequiredVersion $Version

# .Path matters: -Settings silently ignores a PathInfo object.
$settings = (Resolve-Path './PSScriptAnalyzerSettings.psd1').Path
Write-Output "PSScriptAnalyzer ${Version}: linting $($targets.Count) file(s)"

# Invoke-ScriptAnalyzer takes a single -Path, so fan out over the target list.
$findings = @(
    foreach ($file in $targets) {
        Invoke-ScriptAnalyzer -Path $file -Settings $settings
    }
)

if ($findings.Count -eq 0) {
    Write-Output 'PSScriptAnalyzer: clean.'
    exit 0
}

foreach ($finding in $findings) {
    $level = if ($finding.Severity -eq 'Error') { 'error' } else { 'warning' }

    # Repo-relative, forward-slashed, so GitHub can anchor the annotation.
    $file = (Resolve-Path -Relative $finding.ScriptPath) `
        -replace '\\', '/' -replace '^\./', ''

    # Annotations are single-line: flatten any wrapped rule message.
    $message = ("$($finding.RuleName): $($finding.Message)" -replace '\s+', ' ').Trim()

    if ($env:GITHUB_ACTIONS -eq 'true') {
        Write-Output "::${level} file=${file},line=$($finding.Line),col=$($finding.Column)::${message}"
    }
    else {
        Write-Output "${file}:$($finding.Line):$($finding.Column): ${level}: ${message}"
    }
}

Write-Output "PSScriptAnalyzer reported $($findings.Count) issue(s)."
exit 1
