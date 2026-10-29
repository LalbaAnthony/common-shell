function cc { ; claude }
function ccinstall { npm install -g @anthropic-ai/claude-code }
function ccgo { Set-Location "$HOME\.claude" }
function ccu { npx ccusage@latest }

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

function ccom {
    <#
    .SYNOPSIS
        Suggest a commit message using Claude Code (headless mode). Describes the staged
        diff when something is staged, otherwise the whole working tree including
        untracked files, so 'git add' is not required. All arguments are joined as an
        optional hint. Only the message goes to the output stream; status and errors
        are written to the host.
    .EXAMPLE
        ccom
        ccom fix race condition on login
        ccom | git commit -F -
    #>
    $Hint = $args -join ' '

    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    $OutputEncoding = [Text.Encoding]::UTF8

    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not a git repository." -ForegroundColor Red
        return
    }

    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Host "Claude Code CLI not found in PATH." -ForegroundColor Red
        return
    }

    # Lockfiles and minified assets carry no intent worth describing
    $exclude = @('--', '.', ':(exclude)*lock*', ':(exclude)*.min.*')

    # What is staged is what will be committed, so it wins when it exists
    $diff = (git diff --cached @exclude) -join "`n"
    $scope = 'staged changes'

    if ([string]::IsNullOrWhiteSpace($diff)) {
        $scope = 'working tree (nothing staged)'

        # On an unborn HEAD there is no commit to diff against yet
        git rev-parse --verify HEAD 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $diff = (git diff HEAD @exclude) -join "`n"
        }
        else {
            $diff = ''
        }

        # git diff never reports untracked files; synthesise one diff per file
        foreach ($file in (git ls-files --others --exclude-standard @exclude)) {
            $diff += "`n" + ((git diff --no-index -- /dev/null $file 2>$null) -join "`n")
        }
    }

    if ([string]::IsNullOrWhiteSpace($diff)) {
        Write-Host "Nothing to describe: no changes in the working tree." -ForegroundColor Red
        return
    }
    if ($diff.Length -gt 60000) { $diff = $diff.Substring(0, 60000) }

    Write-Host "Describing $scope." -ForegroundColor DarkGray

    # Recent history to match the repo's existing style
    $log = (git log --oneline -10 2>$null) -join "`n"

    $prompt = @"
Write one commit message for the diff provided on stdin, which covers the $scope.
Format: Conventional Commits, type(scope): subject, imperative mood, max 72 chars, English.
Match the style of the recent history below when it is consistent.
Output only the message, no quotes, no code fences, no explanation.

Recent history:
$log
"@
    if ($Hint) { $prompt += "`n`nContext from the author: $Hint" }

    # Claude Code prints startup notices (e.g. the sandbox warning) on stderr; hold
    # them back and only replay them when no message comes out. 5.1 wraps redirected
    # stderr lines in ErrorRecords, which a caller's 'Stop' preference would make fatal
    $ErrorActionPreference = 'Continue'
    $out = $diff | claude -p --model haiku $prompt 2>&1
    $failed = $LASTEXITCODE -ne 0
    $err = ($out | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }) -join "`n"
    $msg = ($out | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) -join "`n"
    if ($failed -or [string]::IsNullOrWhiteSpace($msg)) {
        if ($err) { Write-Host $err }
        Write-Host "Claude returned no message." -ForegroundColor Red
        return
    }
    $msg = ($msg -replace '^```\w*\s*', '' -replace '\s*```$', '').Trim()

    $msg
}
