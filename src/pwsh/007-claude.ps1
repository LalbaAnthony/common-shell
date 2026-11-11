function cc { ; claude }
function ccinstall { npm install -g @anthropic-ai/claude-code }
function ccgo { Set-Location "$HOME\.claude" }
function ccu { npx -y ccusage@latest }

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
        untracked files, so 'git add' is not required.
        Built for pipelines: on success, the output stream carries the one-line message
        and nothing else is written anywhere. On failure, nothing is output, stderr gets
        exactly one 'ccom: <reason>' line and $LASTEXITCODE is 1. git warnings and
        Claude Code notices are discarded, never replayed.
    .EXAMPLE
        ccom
        ccom | git commit -F -
    #>
    # 5.1 wraps redirected native stderr in ErrorRecords, which a caller's 'Stop'
    # preference would make fatal. Function scope only
    $ErrorActionPreference = 'Continue'

    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    $OutputEncoding = [Text.Encoding]::UTF8

    # Straight to stderr: Write-Host lands on stdout when PowerShell runs as a child
    # process, and Write-Error adds a multi-line record around the reason
    $fail = {
        param([string]$Reason)
        [Console]::Error.WriteLine("ccom: $Reason")
        $global:LASTEXITCODE = 1
    }

    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        & $fail 'not a git repository.'
        return
    }

    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        & $fail 'Claude Code CLI not found in PATH.'
        return
    }

    # Lockfiles and minified assets carry no intent worth describing
    $exclude = @('--', '.', ':(exclude)*lock*', ':(exclude)*.min.*')

    # Every git call discards stderr (on Windows, git diff warns about line endings
    # there) and is judged by its exit code instead.
    # What is staged is what will be committed, so it wins when it exists
    $diff = (git diff --cached @exclude 2>$null) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        & $fail 'git diff failed.'
        return
    }
    $scope = 'staged changes'

    if ([string]::IsNullOrWhiteSpace($diff)) {
        $scope = 'working tree (nothing staged)'
        $diff = ''

        # On an unborn HEAD there is no commit to diff against yet
        git rev-parse --verify HEAD 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $diff = (git diff HEAD @exclude 2>$null) -join "`n"
            if ($LASTEXITCODE -ne 0) {
                & $fail 'git diff failed.'
                return
            }
        }

        $untracked = git ls-files --others --exclude-standard @exclude 2>$null
        if ($LASTEXITCODE -ne 0) {
            & $fail 'git ls-files failed.'
            return
        }

        # git diff never reports untracked files; synthesise one diff per file.
        # --no-index exits 1 whenever the two sides differ, i.e. always here
        foreach ($file in $untracked) {
            $diff += "`n" + ((git diff --no-index -- /dev/null $file 2>$null) -join "`n")
        }
    }

    if ([string]::IsNullOrWhiteSpace($diff)) {
        & $fail 'nothing to describe, the working tree is clean.'
        return
    }
    if ($diff.Length -gt 60000) { $diff = $diff.Substring(0, 60000) }

    # Recent history to match the repo's existing style; empty on an unborn HEAD
    $log = (git log --oneline -10 2>$null) -join "`n"

    $prompt = @"
Write one commit message for the diff provided on stdin, which covers the $scope.
Format: Conventional Commits, type(scope): subject, imperative mood, max 72 chars, English.
Match the style of the recent history below when it is consistent.
Output only the message, on a single line, no quotes, no code fences, no explanation.
Never use double quotes anywhere in the message; quote names or values with single quotes instead.

Recent history:
$log
"@

    # Claude Code prints startup notices (e.g. the sandbox warning) on stderr: discard them
    $out = $diff | claude -p --model haiku $prompt 2>$null
    $claudeExit = $LASTEXITCODE
    if ($claudeExit -ne 0) {
        & $fail "Claude Code failed (exit $claudeExit)."
        return
    }

    # Keep the first line shaped like a Conventional Commits subject: drops code
    # fences, blank lines and any preamble Claude adds despite the prompt. Double
    # quotes become single quotes whatever the prompt obtained
    $msg = $out |
        ForEach-Object { "$_".Trim().Replace('"', "'") } |
        Where-Object { $_ -cmatch '^[a-z]+(\([^()]+\))?!?: \S' } |
        Select-Object -First 1

    if (-not $msg) {
        & $fail 'Claude Code returned no valid commit message.'
        return
    }

    $msg
}
