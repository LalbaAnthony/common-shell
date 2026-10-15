function ccusage { npx ccusage@latest }
function ccopen { Set-Location "$HOME\.claude" }

function ccl {
    # plan usage limits as shown by /usage, read from the endpoint Claude Code itself queries
    param([switch]$Json)

    $configDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
    $credFile = Join-Path $configDir '.credentials.json'
    if (-not (Test-Path -LiteralPath $credFile)) {
        Write-Error "no Claude Code credentials found ($credFile); log in with a claude.ai account first"
        return
    }

    $oauth = (Get-Content -LiteralPath $credFile -Raw | ConvertFrom-Json).claudeAiOauth
    if (-not $oauth -or -not $oauth.accessToken) {
        Write-Error "no claude.ai OAuth token in $credFile (API-key logins have no plan limits)"
        return
    }
    if ($oauth.expiresAt -and $oauth.expiresAt -le [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) {
        Write-Error "OAuth token expired; start Claude Code once to refresh it, then retry"
        return
    }

    try {
        $usage = Invoke-RestMethod -Uri 'https://api.anthropic.com/api/oauth/usage' -TimeoutSec 10 -UseBasicParsing -Headers @{
            'Authorization'  = "Bearer $($oauth.accessToken)"
            'anthropic-beta' = 'oauth-2025-04-20'
        }
    }
    catch {
        $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { $null }
        if ($status -eq 401) {
            Write-Error "usage request failed: HTTP 401; start Claude Code once to refresh its token, then retry"
        }
        else {
            Write-Error "usage request failed: $($_.Exception.Message)"
        }
        return
    }

    if ($Json) {
        $usage | ConvertTo-Json -Depth 10
        return
    }

    # one row per limit object, in API order
    $rows = foreach ($p in $usage.PSObject.Properties) {
        if ($null -eq $p.Value -or $null -eq $p.Value.PSObject.Properties['utilization']) { continue }
        $util = $p.Value.utilization
        if ($util -isnot [double] -and $util -isnot [int] -and $util -isnot [long] -and $util -isnot [decimal]) { continue }

        $label = switch -Regex ($p.Name) {
            '^five_hour$' { 'Session (5h)'; break }
            '^seven_day$' { 'Weekly (7d)'; break }
            '^seven_day_(.+)$' { $s = $Matches[1] -replace '_', ' '; 'Weekly ' + $s.Substring(0, 1).ToUpper() + $s.Substring(1); break }
            default { $s = $p.Name -replace '_', ' '; $s.Substring(0, 1).ToUpper() + $s.Substring(1) }
        }

        # PS 7 turns ISO strings into DateTime, 5.1 leaves them as strings
        $resetAt = $p.Value.resets_at
        $reset = ''
        if ($null -ne $resetAt) {
            try {
                if ($resetAt -is [datetime]) { $resetUtc = $resetAt.ToUniversalTime() }
                elseif ($resetAt -is [DateTimeOffset]) { $resetUtc = $resetAt.UtcDateTime }
                else { $resetUtc = [DateTimeOffset]::Parse([string]$resetAt, [Globalization.CultureInfo]::InvariantCulture).UtcDateTime }

                $left = [long][Math]::Max(0, [Math]::Floor(($resetUtc - [DateTime]::UtcNow).TotalSeconds))
                $d = [Math]::Floor($left / 86400); $h = [Math]::Floor(($left % 86400) / 3600); $m = [Math]::Floor(($left % 3600) / 60)
                if ($d -gt 0) { $reset = "resets in ${d}d ${h}h" }
                elseif ($h -gt 0) { $reset = "resets in ${h}h ${m}m" }
                else { $reset = "resets in ${m}m" }
            }
            catch {
                $reset = 'resets ?'
            }
        }

        [pscustomobject]@{
            Label = $label
            Pct   = [int][Math]::Round([double]$util, [MidpointRounding]::AwayFromZero)
            Reset = $reset
        }
    }

    if (-not $rows) {
        Write-Error "no usage limits in the response; inspect it with 'ccl -Json'"
        return
    }

    $width = ($rows | ForEach-Object { $_.Label.Length } | Measure-Object -Maximum).Maximum
    foreach ($r in $rows) {
        # 20 cells, one per 5%, clamped for utilization above 100
        $filled = [int][Math]::Min(20, [Math]::Max(0, [Math]::Floor(($r.Pct + 2) / 5)))
        $color = if ($r.Pct -ge 80) { 'Red' } elseif ($r.Pct -ge 50) { 'Yellow' } else { 'Green' }

        # glyphs built from code points: a UTF-8 profile without BOM is read as ANSI by 5.1
        Write-Host ($r.Label.PadRight($width) + '  ') -NoNewline
        Write-Host ([string][char]0x2588 * $filled) -NoNewline -ForegroundColor $color
        Write-Host ([string][char]0x2591 * (20 - $filled)) -NoNewline -ForegroundColor DarkGray
        Write-Host (' {0,3}%  ' -f $r.Pct) -NoNewline
        Write-Host $r.Reset -ForegroundColor DarkGray
    }
}

function cctn {
    # resolve most recent session id for cwd, then hand it to the URI handler
    $dir = "$HOME\.claude\projects\" + ($PWD.Path -replace '[^a-zA-Z0-9]', '-')
    $sid = (Get-ChildItem "$dir\*.jsonl" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1).BaseName

    if (-not $sid) {
        Write-Error "no session transcript found in $dir"
        return
    }

    Start-Process "vscode://anthropic.claude-code/open?session=$sid"
}

function cscratchpad {
Get-ChildItem "$env:TEMP\claude" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like '*\scratchpad\*' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 30 LastWriteTime,
        @{n='Project';e={ ($_.FullName -split '\\claude\\')[1].Split('\')[0] }},
        @{n='Session';e={ ($_.FullName -split '\\claude\\')[1].Split('\')[1].Substring(0,8) }},
        Name, Length, FullName |
    Format-Table -AutoSize
}

function pwclean {
    Get-ChildItem -LiteralPath .playwright-mcp -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force
}