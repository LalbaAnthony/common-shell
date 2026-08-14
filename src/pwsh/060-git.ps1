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
function gclean { git reset --hard; git clean -fd }
function gtags { git tag -l --sort=-creatordate | Select-Object -First 10 }
function gpf { git push --force-with-lease }

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

    $repoName = [System.IO.Path]::GetFileNameWithoutExtension($repoUrl)
    git clone $repoUrl

    if ($LASTEXITCODE -eq 0) {
        Set-Location $repoName
        code .
    }
    else {
        Write-Host "Failed to clone repository: $repoUrl"
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
    git commit -m $message
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

    # Extract OWNER/REPO from https, ssh or scp-style remote URLs
    $url = git remote get-url $Remote
    if ($url -notmatch '[:/](?<repo>[^/:]+/[^/]+?)(?:\.git)?/?$') {
        throw "Cannot resolve OWNER/REPO from: $url"
    }

    gh api -X PATCH "repos/$($Matches.repo)" -f "default_branch=$Branch" --silent
    if ($LASTEXITCODE -ne 0) { throw "Failed to set default branch to '$Branch'." }

    git remote set-head $Remote --auto | Out-Null
}