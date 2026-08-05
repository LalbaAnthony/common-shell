function cusage { npx ccusage@latest }

function ccontinue {
    # resolve most recent session id for cwd, then hand it to the URI handler
    $dir = "$HOME\.claude\projects\" + ($PWD.Path -replace '[^a-zA-Z0-9]', '-')
    $sid = (Get-ChildItem "$dir\*.jsonl" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1).BaseName

    if ($sid) {
        Start-Process "vscode://anthropic.claude-code/open?session=$sid"
    } else {
        Write-Error "no session transcript found in $dir"
    }
}
