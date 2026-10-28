function gs { git status -sb }
function ga { git add . }
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
function gtags { git tag -l --sort=-creatordate | Select-Object -First 10 }
function gpf { git push --force-with-lease }

# gps is a built-in ReadOnly alias for Get-Process, and aliases win over functions
if (Test-Path Alias:gps) { Remove-Item Alias:gps -Force }
function gps {
    $branch = git symbolic-ref --quiet --short HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $branch) {
        Write-Host "Not on a branch (detached HEAD or not a git repository)."
        return
    }

    # Upstream already set: plain push honours push.default and the configured target
    # '@{u}' must stay quoted, bare it parses as a hashtable literal
    git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        git push
        return
    }

    # First push of this branch: create it on origin and track it
    git push --set-upstream origin $branch
}

function gmep {
    param($targetBranch)

    if (-not $targetBranch) {
        Write-Host "Usage: gmep <branch_name>"
        return
    }

    $initialBranch = git symbolic-ref --quiet --short HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $initialBranch) {
        Write-Host "Not on a branch (detached HEAD or not a git repository)."
        return
    }

    # Every step stops on failure: a conflict must not be pushed or carried across a checkout
    git fetch
    if ($LASTEXITCODE -ne 0) { return }

    # Pull the target branch changes into the initial branch (updated CHANGELOG, ...)
    git pull --rebase
    if ($LASTEXITCODE -ne 0) { return }
    git pull origin $targetBranch
    if ($LASTEXITCODE -ne 0) { return }
    git push
    if ($LASTEXITCODE -ne 0) { return }

    # Go to the target branch to integrate changes from the initial branch
    git checkout $targetBranch
    if ($LASTEXITCODE -ne 0) { return }

    # Update the target branch with the latest changes from the remote and the initial branch
    git pull --rebase
    if ($LASTEXITCODE -ne 0) { return }
    git pull origin $initialBranch
    if ($LASTEXITCODE -ne 0) { return }
    git push
    if ($LASTEXITCODE -ne 0) { return }

    # Return to the initial branch after integrating changes
    git checkout $initialBranch
}

function grecent {
    git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)' |
        Select-Object -First 15
}

function gclear {
    $token = -join ((1..6) | ForEach-Object { [char][int]((65..90) + (48..57) | Get-Random) })
    $confirm = Read-Host "Type '$token' to confirm"

    if ($confirm -cne $token) {
        Write-Host "Aborted."
        return
    }
    git reset --hard
    git clean -fd

    Write-Host "Repository cleared."
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

function gsince {
    param($Commit)

    if (-not $Commit) {
        Write-Host "Usage: gsince <commit>"
        return
    }

    $sha = git rev-parse --verify --quiet "$Commit^{commit}" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $sha) {
        Write-Host "Not a commit: $Commit"
        return
    }

    # Net diff of the two trees: the commit itself is excluded, and a file added then
    # deleted in between appears in neither list
    # --no-renames splits a rename into delete + add, so each path lands in exactly one list
    # core.quotePath=false keeps non-ASCII paths readable instead of octal-escaped
    $lines = git -c core.quotePath=false diff-tree -r --no-renames --name-status $sha HEAD
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to diff $Commit against HEAD."
        return
    }

    $changed = @()
    $deleted = @()
    foreach ($line in $lines) {
        $status, $path = $line -split "`t", 2
        if ($status -eq 'D') {
            $deleted += $path
        }
        else {
            $changed += $path
        }
    }

    $subject = git log -1 --format='%h %s' $sha
    $count = git rev-list --count "$sha..HEAD"
    Write-Host "From $subject to HEAD, $count commit(s)"

    Write-Host "Added/updated ($($changed.Count)):"
    foreach ($path in $changed) { Write-Host "  $path" }

    Write-Host "Deleted ($($deleted.Count)):"
    foreach ($path in $deleted) { Write-Host "  $path" }
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

    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not a git repository."
        return
    }
    if ((Get-Location).Path -ne (Resolve-Path $root).Path) {
        Write-Host "Not at repo root ($root). Aborting."
        return
    }

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = Read-Host "Commit message"
    }

    # Whitespace-only counts as empty: git would reject it, but only after `git add .` ran
    if ([string]::IsNullOrWhiteSpace($message)) {
        Write-Host "Commit message required. Aborting."
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