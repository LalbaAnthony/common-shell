function ccusage { npx ccusage@latest }
function ccopen { Set-Location "$HOME\.claude" }

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
