function ccusage { npx ccusage@latest }
function ccopen { Set-Location "$HOME\.claude" }

function pwclean {
    Get-ChildItem -LiteralPath .playwright-mcp -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force
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