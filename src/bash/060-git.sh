# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias gs='git status -sb'
alias ga='git add .'
alias gc='git commit -m'
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gf='git fetch'
alias gplo='git pull origin'
alias gph='git log --oneline --graph --decorate --all'
alias gd='git diff origin/$(git rev-parse --abbrev-ref HEAD)'
alias gds='git diff --shortstat origin/$(git rev-parse --abbrev-ref HEAD)'
alias gdf='git diff --stat origin/$(git rev-parse --abbrev-ref HEAD)' # Same as gds, but one line per file
alias gbd='git branch -d'
alias gundo='git reset --soft HEAD~1'
alias gclean='git reset --hard && git clean -fd'
alias gtags='git tag -l --sort=-creatordate | head -n 10'
alias gpf='git push --force-with-lease'
alias grecent='git for-each-ref --sort=-committerdate refs/heads/ --format="%(committerdate:short) %(refname:short)" | head -n 15'

grestore() {
    local file=$1
    local commit=$2

    if [ -z "$file" ]; then
        echo "Usage: grestore <file_path> [commit_hash]"
        return 1
    fi

    if [ -z "$commit" ]; then
        git restore "$file"
    else
        git restore --source "$commit" "$file"
    fi
}

gbdel () {
    if [ -z "$1" ]; then
        echo "Usage: gbdel <branch_name>"
        return 1
    fi

    git branch -D "$1" ; git push origin --delete "$1"
}

gclone() {
    if [ -z "$1" ]; then
        echo "Usage: gclone <repo_url>"
        return 1
    fi

    local repo_name
    repo_name=$(basename "$1" .git)

    git clone "$1"

    if [ $? -eq 0 ]; then
        cd "$repo_name" || return
        code .
    else
        echo "Failed to clone repository: $1"
    fi
}

gacp() {
    if [ -z "$1" ]; then
        echo "Usage: gacp <commit_message>"
        return 1
    fi

    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "Not a git repository."
        return 1
    }
    if [ "$(pwd -P)" != "$root" ]; then
        echo "Not at repo root ($root). Aborting."
        return 1
    fi

    git add . && git commit -m "$1" && git push
}

groot() {
    cd "$(git rev-parse --show-toplevel)" || return
}

gck() {
    if [ -z "$1" ]; then
        echo "Usage: gck <branch_name>"
        return 1
    fi

    local branch=$1

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "Not a git repository."
        return 1
    }

    # Existing local branch
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git checkout "$branch"
        return
    fi

    # Existing remote-tracking branch (run `git fetch` first if it is missing)
    if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        git checkout --track "origin/$branch"
        return
    fi

    local confirm
    read -r -p "Branch '$branch' does not exist. Create it? [Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "Aborted."
        return 1
    fi

    git checkout -b "$branch"
}

gbranch() {
    local branches
    branches=$(git branch | sed 's/^[* ] //')

    select branch in $branches; do
        [ -n "$branch" ] || { echo "Invalid choice"; return 1; }
        git checkout "$branch"
        break
    done
}

gopen() {
    local remote=${1:-origin}
    local url web_url

    url=$(git remote get-url "$remote" 2>/dev/null) || {
        echo "No remote '$remote' found."
        return 1
    }

    if [[ "$url" =~ ^https?:// ]]; then
        # Drop any embedded credentials and the trailing .git
        web_url=$(sed -E 's#^(https?://)[^/@]+@#\1#; s#\.git/?$##' <<< "$url")
    elif [[ "$url" =~ ^(ssh://)?([^@/]+@)?[^:/]+(:[0-9]+)?[:/].+ ]]; then
        # scp-style (git@host:owner/repo.git) and ssh:// remotes
        web_url="https://$(sed -E 's#^ssh://##; s#^[^@/]+@##; s#:[0-9]+/#/#; s#:#/#; s#\.git/?$##' <<< "$url")"
    else
        echo "Cannot build a web URL from: $url"
        return 1
    fi

    echo "$web_url"

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$web_url" >/dev/null 2>&1 &
    elif command -v open >/dev/null 2>&1; then
        open "$web_url"
    elif command -v wslview >/dev/null 2>&1; then
        wslview "$web_url"
    elif command -v explorer.exe >/dev/null 2>&1; then
        # explorer.exe exits 1 even on success
        explorer.exe "$web_url" >/dev/null 2>&1 || true
    else
        echo "No browser opener found (xdg-open, open, wslview, explorer.exe)."
        return 1
    fi
}
