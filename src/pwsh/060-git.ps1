function gs { git status -sb }
function ga { git add . }
function gc { git commit -m @args }
function gpl { git pull }
function gplr { git pull --rebase }
function gf { git fetch }
function gplo { git pull origin @args }
function gph { git log --oneline --graph --decorate --all }
function gd { git diff "origin/$(git rev-parse --abbrev-ref HEAD)" }
function gds { git diff --shortstat "origin/$(git rev-parse --abbrev-ref HEAD)" }
function gdf { git diff --stat "origin/$(git rev-parse --abbrev-ref HEAD)" } # Same as gds, but one line per file
function gbd { git branch -d @args }
function gundo { git reset --soft HEAD~1 }
function gclear { git reset --hard; git clean -fd }
function gtags { git tag -l --sort=-creatordate | Select-Object -First 10 }
function gpf { git push --force-with-lease }

# Local branches, most recently committed on first
function grecent {
    git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)' |
        Select-Object -First 15
}

function deltainstall {
    if (Get-Command delta -ErrorAction SilentlyContinue) {
        delta --version
        return
    }

    winget install --id dandavison.delta -e --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install delta."
        return
    }

    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    delta --version
}

function grestore {
    param($file, $commit)

    if (-not $file) {
        Write-Host "Usage: grestore <file_path> [commit_hash]"
        return
    }

    if (-not $commit) {
        git restore -- $file
    }
    else {
        git restore --source $commit -- $file
    }
}

function gbdel {
    param($branchName)

    if (-not $branchName) {
        Write-Host "Usage: gbdel <branch_name>"
        return
    }

    git branch -D $branchName
    git push origin --delete $branchName
}

function gclone {
    param($repoUrl)

    if (-not $repoUrl) {
        Write-Host "Usage: gclone <repo_url>"
        return
    }

    $repoName = [System.IO.Path]::GetFileNameWithoutExtension($repoUrl)
    git clone $repoUrl

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to clone repository: $repoUrl"
        return
    }

    if (Get-Command code -ErrorAction SilentlyContinue) {
        code $repoName
    }
    else {
        Set-Location $repoName
    }
}

function gacp {
    param($message)

    if (-not $message) {
        Write-Host "Usage: gacp <commit_message>"
        return
    }

    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not a git repository."
        return
    }
    if ((Get-Location).Path -ne (Resolve-Path $root).Path) {
        Write-Host "Not at repo root ($root). Aborting."
        return
    }

    git add .
    if ($LASTEXITCODE -ne 0) { return }
    git commit -m $message
    if ($LASTEXITCODE -ne 0) { return }
    git push
}

function groot {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        Set-Location $root
    }
    else {
        Write-Host "Not a git repository."
    }
}

# Append a pattern to the repo root .gitignore (current directory outside a repo)
function gitign {
    param([string]$pattern)

    if (-not $pattern) {
        Write-Host "Usage: gitign <pattern>"
        return
    }

    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $root) {
        $root = (Get-Location).Path
    }
    $file = Join-Path $root '.gitignore'

    if (-not (Test-Path -LiteralPath $file)) {
        New-Item -ItemType File -Path $file | Out-Null
        Write-Host "Created $file"
    }

    $content = [System.IO.File]::ReadAllText($file)
    $lines = $content -split "\r?\n"
    if ($lines -contains $pattern) {
        Write-Host "'$pattern' is already in $file"
        return
    }

    # Keep the existing line ending style and never glue onto an unterminated last line
    $eol = if ($content -match "\r\n") { "`r`n" } else { "`n" }
    $prefix = if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) { $eol } else { '' }

    # AppendAllText writes UTF-8 without BOM; Add-Content on 5.1 would use the ANSI codepage
    [System.IO.File]::AppendAllText($file, "$prefix$pattern$eol")
    Write-Host "Added '$pattern' to $file"
}

function gck {
    param($branchName)

    if (-not $branchName) {
        Write-Host "Usage: gck <branch_name>"
        return
    }

    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not a git repository."
        return
    }

    # Existing local branch
    git show-ref --verify --quiet "refs/heads/$branchName"
    if ($LASTEXITCODE -eq 0) {
        git checkout $branchName
        return
    }

    # Existing remote-tracking branch (run `git fetch` first if it is missing)
    git show-ref --verify --quiet "refs/remotes/origin/$branchName"
    if ($LASTEXITCODE -eq 0) {
        git checkout --track "origin/$branchName"
        return
    }

    $confirm = Read-Host "Branch '$branchName' does not exist. Create it? [Y/n]"
    if ($confirm -match '^[Nn]') {
        Write-Host "Aborted."
        return
    }

    git checkout -b $branchName
}

function gbranch {
    $branches = git branch | ForEach-Object { $_.TrimStart('* ').Trim() }
    $i = 1
    foreach ($b in $branches) { Write-Host "$i) $b"; $i++ }
    $choice = Read-Host "Select branch"
    $branch = $branches[$choice - 1]
    if ($branch) {
        git checkout $branch
    }
    else {
        Write-Host "Invalid choice"
    }
}

function gopen {
    param([string]$Remote = 'origin')

    $url = git remote get-url $Remote 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $url) {
        Write-Host "No remote '$Remote' found."
        return
    }

    if ($url -match '^https?://') {
        # Drop any embedded credentials and the trailing .git
        $webUrl = $url -replace '^(https?://)[^/@]+@', '$1' -replace '\.git/?$', ''
    }
    elseif ($url -match '^(?:ssh://)?(?:[^@/]+@)?(?<host>[^:/]+?)(?::\d+)?[:/](?<path>.+?)(?:\.git)?/?$') {
        # scp-style (git@host:owner/repo.git) and ssh:// remotes
        $webUrl = "https://$($Matches.host)/$($Matches.path)"
    }
    else {
        Write-Host "Cannot build a web URL from: $url"
        return
    }

    Write-Host $webUrl
    Start-Process $webUrl
}

function ghSetDefaultBranch {
    param(
        [Parameter(Mandatory, Position = 0)][string]$Branch,
        [string]$Remote = 'origin'
    )

    $url = git remote get-url $Remote 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $url) {
        Write-Host "No remote '$Remote' found."
        return
    }

    # Extract OWNER/REPO from https, ssh or scp-style remote URLs
    if ($url -notmatch '[:/](?<repo>[^/:]+/[^/]+?)(?:\.git)?/?$') {
        Write-Host "Cannot resolve OWNER/REPO from: $url"
        return
    }

    gh api -X PATCH "repos/$($Matches.repo)" -f "default_branch=$Branch" --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to set default branch to '$Branch'."
        return
    }

    git remote set-head $Remote --auto | Out-Null
}

function gprune {
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not a git repository."
        return
    }

    # Prune first, otherwise a stale ref cache makes "gone" meaningless
    git fetch --prune
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to fetch from the remote. Aborting."
        return
    }

    $current = git rev-parse --abbrev-ref HEAD
    # A gone upstream on these means the remote is broken, not that the branch is disposable
    $keep = @('main', 'master', 'develop')
    $format = '%(refname:short) %(upstream:track)'

    $gone = git for-each-ref --format=$format refs/heads/ |
        Where-Object { $_ -match '\[gone\]$' } |
        ForEach-Object { ($_ -split '\s+')[0] } |
        Where-Object { $_ -ne $current -and $keep -notcontains $_ }

    $deleted = @()
    $skipped = @()

    foreach ($branch in $gone) {
        # -d only, never -D: unmerged work must not disappear silently
        git branch -d $branch 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $deleted += $branch
        }
        else {
            $skipped += $branch
        }
    }

    if ($deleted.Count -eq 0 -and $skipped.Count -eq 0) {
        Write-Host "Nothing to delete: no local branch has a gone upstream."
        return
    }

    if ($deleted.Count -gt 0) {
        Write-Host "Deleted $($deleted.Count) branch(es):"
        foreach ($branch in $deleted) { Write-Host "  $branch" }
    }

    if ($skipped.Count -gt 0) {
        Write-Host "Skipped $($skipped.Count) unmerged branch(es), use 'git branch -D <branch>' if you are sure:"
        foreach ($branch in $skipped) { Write-Host "  $branch" }
    }
}