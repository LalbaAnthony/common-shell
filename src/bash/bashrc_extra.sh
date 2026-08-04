# This file is sourced from ~/.bashrc, so it carries no shebang.
# shellcheck shell=bash
#
# File-wide ShellCheck exemptions, all specific to an interactive profile:
#   SC1091 - sourced paths (e.g. .venv/bin/activate) only exist at runtime.
#   SC2034 - colour variables are consumed by PS1 and by interactive use.
#   SC2142 - `$2` inside single-quoted awk programs is an awk field, not an arg.
#   SC2154 - variables in single-quoted alias bodies are expanded by the subshell.
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

# =================================================================================
# Linux config
# =================================================================================

RED='\[\e[31m\]'
GREEN='\[\e[32m\]'
YELLOW='\[\e[33m\]'
BLUE='\[\e[34m\]'
MAGENTA='\[\e[35m\]'
CYAN='\[\e[36m\]'
WHITE='\[\e[97m\]'
GRAY='\[\e[90m\]'
RESET='\[\e[0m\]'

# Theme
export PS1="\$([ \"\$(id -u)\" = \"0\" ] && echo \"${RED}\" || echo \"${CYAN}\")\u${WHITE}@${GREEN}\h${RESET}:${YELLOW}\w\$(branch=\$(git branch 2>/dev/null | grep '^*' | colrm 1 2); [ -n \"\$branch\" ] && echo \"${GRAY} (\$branch)${RESET}\")${RESET} \$ "

# History
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTIGNORE="&:ls:cd:cd -:pwd:exit:clear"
shopt -s histappend

# =================================================================================
# Self
# =================================================================================

alias cshdel='bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/uninstall.sh)'
alias cshup='bash <(curl -fsSL https://raw.githubusercontent.com/LalbaAnthony/antho-common-shell/main/scripts/install.sh)'

# =================================================================================
# Random
# =================================================================================

# Folders
alias ll='ls -lah --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias f='find . -name' # Search for a file in the current directory

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias www='cd /var/www'
alias html='cd /var/www/html'

# Random
alias cls='clear'
alias please='sudo'
alias plz='sudo'
alias pleasefuck='sudo $(fc -ln -1)' # Repeat last command with sudo, works even if last command had arguments
alias plzfuck='sudo $(fc -ln -1)'
alias fuck='fc -e nano' # Edit last command in nano
alias again='fc -s' # Repeat last command
alias h='history | tail -n 30'
alias hfreq='history | awk "{print \$2}" | sort | uniq -c | sort -nr | head -n 20' # Most frequently used commands

# Bash
alias shp='echo "Profile file: ~/.bashrc"'

# System
alias syslog='tail -n 1000 /var/log/syslog'
alias reload='source ~/.bashrc'
alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && echo "System updated"'
alias jlog='sudo journalctl -xe' # Recent system errors

# Disk
alias du20='du -ah . | sort -rh | head -n 20' # Show top 20 largest files/folders in current directory
alias watchspace='watch -n5 "df -hT | grep -E \"Filesystem|/dev/\""' # Monitor disk space every 5 seconds

# Performance
alias topcpu='ps aux --sort=-%cpu | head -n 11' # Top 10 CPU consumers
alias topmem='ps aux --sort=-%mem | head -n 11' # Top 10 RAM consumers

# Create a folder and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Extract various archive types with a single command
extractt() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.dmg)       hdiutil mount "$1" ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.ZIP)       unzip "$1"      ;;
            *.rar)       unrar x "$1"    ;;
            *.RAR)       unrar x "$1"    ;;
            *.7z)        7z x "$1"       ;;
            *.tar.xz)    tar xJf "$1"    ;;
            *.txz)       tar xJf "$1"    ;;
            *.tar.zst)   tar --zstd -xf "$1" ;;
            *.zst)       unzstd "$1"     ;;
            *)           echo "'$1' is not handled by extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Backup any folder quickly to timestamped tar
backupp() {
    tar -czf "$1_$(date +%F_%H-%M-%S).tar.gz" "$1";
}

# Replace string in all files recursively
rreplace() {
    grep -rl "$1" . | xargs sed -i "s/$1/$2/g";
}

# Compare two dirs visually
diffd() {
    diff -qr "$1" "$2" | less;
}

# Reload or restart a systemd service with one command
reloadd() {
    if [ -z "$1" ]; then
        echo "Usage: reloadd <file_or_folder>"
        return 1
    fi

    sudo systemctl reload "$1" || sudo systemctl restart "$1" || echo "Failed to reload or restart $1"
}

# =================================================================================
# Network
# =================================================================================

alias ipl='hostname -I' # Get local IP address
alias ipp='curl ifconfig.me && echo' # Get public IP address
alias ports='netstat -tulanp' # List all listening ports
alias randpass='openssl rand -base64 20'
alias nettop='sudo netstat -tulpen | sort -k3' # Show open TCP connections sorted
alias dnscheck='for d in 1.1.1.1 8.8.8.8 9.9.9.9; do ping -c2 $d; done' # Ping all DNS providers (Cloudflare, Google, Quad9)

killport() {
    if [ -z "$1" ]; then
        echo "Usage: killport <port_number>"
        return 1
    fi

    sudo lsof -t -i:"$1" | xargs sudo kill -9
}

# =================================================================================
# Python
# =================================================================================

pysetup() {
    python -m venv .venv
    . .venv/bin/activate
    pip install -r requirements.txt
}

# =================================================================================
# Node
# =================================================================================

# Node
alias nr='npm run'
alias nrb='npm run build'
alias nrd='npm run dev'
alias nrt='npm run test'
alias nstart='npm start'
alias nout='npm outdated'
alias nls='npm list -g --depth=0' # Global packages
alias nci='npm ci' # Clean install from lockfile
alias nsetup='rm -rf node_modules && rm -rf .vite .cache && rm -rf package-lock.json && npm i'
alias yr='yarn run'
alias yrb='yarn run build'
alias yrd='yarn run dev'
alias yrt='yarn run test'
alias ystart='yarn start'
alias ysetup='rm -rf node_modules && rm -rf .vite .cache && rm -rf yarn.lock && yarn install'

npdev() {
    local front="" back=""

    [ -d "front" ] && front="front"
    [ -d "frontend" ] && front="frontend"
    [ -d "back" ] && back="back"
    [ -d "backend" ] && back="backend"

    if [ -z "$front" ] && [ -z "$back" ]; then
        echo "No front(end)/ or back(end)/ directory here"
        return 1
    fi

    local names=() colors=() cmds=()
    if [ -n "$front" ]; then
        names+=("front"); colors+=("cyan"); cmds+=("cd $front && npm run dev")
    fi
    if [ -n "$back" ]; then
        names+=("back"); colors+=("magenta"); cmds+=("cd $back && npm run dev")
    fi

    npx concurrently -n "$(IFS=,; echo "${names[*]}")" -c "$(IFS=,; echo "${colors[*]}")" "${cmds[@]}"
}

# Quasar
alias qd='quasar dev'
alias qb='quasar build'

# =================================================================================
# Git
# =================================================================================

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

# =================================================================================
# Claude
# =================================================================================

alias cusage='npx ccusage@latest'

ccontinue() {
    # resolve most recent session id for cwd, then hand it to the URI handler
    DIR="$HOME/.claude/projects/$(pwd | sed 's/[^a-zA-Z0-9]/-/g')"
    SID="$(basename "$(ls -t "$DIR"/*.jsonl | head -1)" .jsonl)"
    open "vscode://anthropic.claude-code/open?session=$SID"   # xdg-open on Linux
}

# =================================================================================
# Docker
# =================================================================================

alias dcb='docker compose up --build -d'
alias dps='docker ps'
alias dpa='docker ps -a'
alias drm='docker rm -f'
alias dst='docker stats'
alias dim='docker images'
alias dclean='docker system prune -af --volumes'
alias drestart='docker restart $(docker ps -q)' # Restart all running containers

dexec() {
    if [ -z "$1" ]; then
        echo "Usage: dexec <container_name_or_id>"
        return 1
    fi

    docker exec -it "$1" /bin/bash || docker exec -it "$1" /bin/sh
}

dlogs() {
    if [ -z "$1" ]; then
        echo "Usage: dlogs <container_name_or_id>"
        return 1
    fi

    docker logs -f "$1"
}

denv() {
    if [ -z "$1" ]; then
        echo "Usage: denv <container_name_or_id>"
        return 1
    fi

    docker exec -it "$1" env
}

derase() {
    echo "WARNING: This will destroy ALL Docker volumes."
    echo "Current state:"
    echo "  Volumes: $(docker volume ls -q 2>/dev/null | wc -l)"
    echo ""
    read -rp "Type 'ERASE' to confirm: " confirm

    if [ "$confirm" != "ERASE" ]; then
        echo "Aborted."
        return 1
    fi

    # shellcheck disable=SC2046 # word splitting is wanted: one arg per volume ID
    docker volume rm $(docker volume ls -q) 2>/dev/null

    echo "All Docker volumes removed."
}

ddown() {
    local ids
    ids=$(docker ps -aq 2>/dev/null)

    if [ -z "$ids" ]; then
        echo "No containers running."
        return 0
    fi

    echo "Stopping $(echo "$ids" | wc -l) container(s)..."
    docker stop $ids
    echo "All containers stopped."
}

dwhere() {
    if [ -z "$1" ]; then
        echo "Usage: dwhere <container_name_or_id>"
        return 1
    fi

    local id
    id=$(docker inspect --format '{{.Id}}' "$1" 2>/dev/null)
    if [ -z "$id" ]; then
        echo "Container not found: $1"
        return 1
    fi

    local compose_dir compose_project compose_service
    compose_dir=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$1")
    compose_project=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' "$1")
    compose_service=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.service"}}' "$1")

    if [ -n "$compose_dir" ]; then
        echo "Origin: docker-compose"
        echo "Project:  $compose_project"
        echo "Service:  $compose_service"
        echo "Dir:      $compose_dir"
    else
        echo "Origin: plain docker run"

        local image restart ports envs
        image=$(docker inspect --format '{{.Config.Image}}' "$1")
        restart=$(docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' "$1")
        ports=$(docker inspect --format '{{range $p, $b := .HostConfig.PortBindings}}  -p {{(index $b 0).HostPort}}:{{$p}} {{end}}' "$1")
        envs=$(docker inspect --format '{{range .Config.Env}}  -e {{.}} {{end}}' "$1")

        echo ""
        echo "Reconstructed command:"
        printf "docker run -d \\\n"
        [ -n "$ports" ]   && printf "%s\\\n" "$ports"
        [ "$restart" != "no" ] && [ -n "$restart" ] && printf "  --restart %s \\\n" "$restart"
        printf "  %s\n" "$image"
    fi

    echo ""
    echo "Created:  $(docker inspect --format '{{.Created}}' "$1")"
    echo "Started:  $(docker inspect --format '{{.State.StartedAt}}' "$1")"
}

# =================================================================================
# Apache
# =================================================================================

alias a2log='tail -f /var/log/apache2/error.log'
alias a2c='sudo apache2ctl configtest'
alias a2s='sudo systemctl status apache2'
alias a2r='sudo systemctl reload apache2'
alias a2rr='sudo apache2ctl configtest && sudo systemctl restart apache2'
alias a2sa='cd /etc/apache2/sites-available'
alias a2se='cd /etc/apache2/sites-enabled'
alias a2dall='sudo a2dissite *.conf'
alias a2lall='sudo apache2ctl -S | grep -A2 "port 80"'

webperms() {
    local TARGET=$1
    local OWNER=${2:-www-data}

    if [ -z "$TARGET" ]; then
        echo "Usage: webperms <path> [owner=www-data]"
        return 1
    fi

    if [ ! -e "$TARGET" ]; then
        echo "Error: Path does not exist"
        return 1
    fi

    if git -C "$TARGET" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
        local FILE_MODE
        FILE_MODE=$(git -C "$TARGET" config --get core.fileMode 2>/dev/null)
        if [ "$FILE_MODE" = "true" ]; then
            echo "Warning: git core.fileMode is true in this repo - chmod will be tracked as changes."
            read -r -p "Continue? [y/N] " _confirm
            [[ "$_confirm" =~ ^[Yy]$ ]] || return 1
        fi
    fi

    /bin/chmod -R 775 "$TARGET"
    /bin/chown -R "$OWNER:www-data" "$TARGET"

    echo "Set permissions 775 and owner $OWNER:www-data on '$TARGET'"
}

a2pick() {
    local sites
    sites=(/etc/apache2/sites-available/*.conf)

    select site in "${sites[@]}"; do
        [ -n "$site" ] || { echo "Invalid choice"; return 1; }
        sudo a2dissite *.conf
        sudo a2ensite "$(basename "$site")"
        sudo systemctl restart apache2
        sudo apache2ctl configtest
        break
    done
}

# =================================================================================
# SQL
# =================================================================================

__mysql_require_cnf() {
    local CNF="$HOME/.my.cnf"

    if [ ! -f "$CNF" ]; then
        echo "Missing $CNF"
        echo "Create it with:"
        echo ""
        echo "[client]"
        echo "user=your_user"
        echo "password=your_password"
        echo ""
        echo "Then secure it:"
        echo "chmod 600 ~/.my.cnf"
        return 1
    fi
}


sqlimport() {
    local FILE=$1
    local DB=$2

    __mysql_require_cnf || { echo "Requires $HOME/.my.cnf"; return 1; }

    if [ -z "$FILE" ] || [ -z "$DB" ]; then
        echo "Usage: sqlimport <sql_file.sql.gz> <database_name>"
        return 1
    fi

    mysql -e "DROP DATABASE IF EXISTS \`${DB}\`;" || return 1
    mysql -e "CREATE DATABASE \`${DB}\` CHARACTER SET utf8 COLLATE utf8_general_ci" || return 1

    # zcat -f handles both gzipped and plain .sql
    # sed strips the MariaDB sandbox-mode line that the client rejects with "Unknown command '\-'"
    # pipefail makes a mysql failure propagate instead of being masked by zcat's exit code
    set -o pipefail
    zcat -f "${FILE}" \
        | sed '1{/enable the sandbox mode/d}' \
        | mysql --max_allowed_packet=512M "${DB}"
    local rc=$?
    set +o pipefail

    if [ "$rc" -ne 0 ]; then
        echo "Import FAILED for '${FILE}' (exit ${rc})"
        return "$rc"
    fi
    echo "Imported '${FILE}' into database '${DB}'"
}

sqlexport() {
    local DB=$1
    local OUTFILE=$2

    __mysql_require_cnf || (echo "Requires $HOME/.my.cnf"; return 1)

    if [ -z "$DB" ]; then
        echo "Usage: sqlexport <database_name> <output_sql_file.sql.gz>"
        return 1
    fi

    if [ -z "$OUTFILE" ]; then
        OUTFILE="${DB}_$(date +%F_%H-%M-%S).sql.gz"
    fi

    mysqldump  --single-transaction --quick --lock-tables=false "${DB}" | gzip > "${OUTFILE}"

    echo "Exported database '${DB}' to '${OUTFILE}'"
}

# =================================================================================
# Certebot
# =================================================================================

alias certtest='sudo certbot renew --dry-run'        # Validate renewal pipeline

# =================================================================================
# PHP
# =================================================================================

# PHP
alias phpswitch='sudo update-alternatives --config php'
alias phplist='sudo update-alternatives --list php'
alias php56='sudo update-alternatives --set php /usr/bin/php5.6 && sudo systemctl restart apache2'
alias php70='sudo update-alternatives --set php /usr/bin/php7.0 && sudo systemctl restart apache2'
alias php74='sudo update-alternatives --set php /usr/bin/php7.4 && sudo systemctl restart apache2'
alias php81='sudo update-alternatives --set php /usr/bin/php8.1 && sudo systemctl restart apache2'
alias php82='sudo update-alternatives --set php /usr/bin/php8.2 && sudo systemctl restart apache2'
alias php83='sudo update-alternatives --set php /usr/bin/php8.3 && sudo systemctl restart apache2'
alias php84='sudo update-alternatives --set php /usr/bin/php8.4 && sudo systemctl restart apache2'
alias phpsetup='rm -rf vendor composer.lock && composer install'

# Wordpress
alias wpclisetup='cd ~ && rm -f wp-cli.phar && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar'
# alias wp='~/wp-cli.phar' # ? If you want to use wp from anywhere, uncomment this line and add ~/ to your $PATH
alias wplist='wp plugin list --field=name' # List all plugin slugs
alias wpclear='wp cache flush && wp transient delete --all && sudo systemctl reload apache2' # Clear all cache layers
alias wpexport='wp db export backup_wp_$(date +%F_%H-%M-%S).sql' # Export DB to timestamped file
alias wptestdb='sudo -u www-data php -r '\''require "wp-config.php"; $m = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME); echo $m->connect_error ? "Error: " . $m->connect_error : "Success!\n";'\'''
alias wptesturl='sudo -u www-data php -r '\''require "wp-load.php"; echo get_option("siteurl")."\n"; echo get_option("home")."\n";'\'''

# =================================================================================
# Laravel
# =================================================================================

alias art='php artisan'

artperms() {
    # ! This may be catched by git and show as changes, if git core.fileMode is true in this repo
    sudo chown -R www-data:www-data public storage bootstrap/cache
    sudo chmod -R 775 public storage bootstrap/cache
}

artclear() {
    rm -rf .vite .cache
    php artisan cache:clear
    php artisan config:clear
    php artisan view:clear
    php artisan route:clear
    php artisan optimize:clear
    php artisan config:cache
}

artdb() {
    php artisan migrate:fresh
    php artisan db:seed
}

artdeps() {
    if [ -f "package-lock.json" ]; then
        rm -rf node_modules
        npm i
        echo "Node modules installed"
    fi
    
    if [ -f "composer.lock" ]; then
        rm -rf vendor
        composer install
        echo "Composer dependencies installed"
    fi
}

artreset() {
    artdeps
    echo "Dependencies installed"

    artclear
    echo "Cache cleared"

    artdb
    echo "Database reset and seeded"
    
    php artisan storage:link
    php artisan key:generate
    echo "Storage linked and app key generated"
}


# =================================================================================
# Agoravita
# =================================================================================

#  -------- Kronos --------

kwc() {
    if [ -d "back" ]; then
        cd back || return
    fi

    php artisan kronos:wordpress:configure
}

#  -------- Atlas --------

atld() {
    if [ ! -d "front" ] && [ ! -d "back" ]; then
        echo "No front/ or back/ directory here"
        return 1
    fi

    npx concurrently -n front,back -c cyan,magenta \
        "cd front && yarn dev" \
        "cd back && npm run dev"
}

#  -------- Common --------

devs() {
    # reusable pieces
    local node22="npm install -g n && n 22"
    local node18="npm install -g n && n 18"
    local setphp="sudo update-alternatives --set php /usr/bin/php"
    local a2enmaildev="sudo a2ensite dev-000-maildev.conf"
    local a2disall="(sudo a2dissite '*.conf' || echo 'No site to disable')"
    local a2restart="sudo apache2ctl configtest && sudo systemctl restart apache2"

    # preset table: one line per preset, same position in both arrays
    local names=() cmds=()
    names+=("extranet");          cmds+=("$a2disall && sudo a2ensite dev-111-extranet.conf && $a2restart && $node22")
    names+=("nuxt-wp");           cmds+=("$a2disall && sudo a2ensite dev-111-nuxt-wp.conf && $a2enmaildev && $a2restart && $node22")
    names+=("atlas");             cmds+=("$a2disall && sudo a2ensite dev-111-atlas.conf && $a2enmaildev && $a2restart && $node22")
    names+=("ample-php5.6");      cmds+=("$a2disall && sudo a2ensite dev-111-ample-php5.6.conf && $a2restart && ${setphp}5.6")
    names+=("ample-php7.0");      cmds+=("$a2disall && sudo a2ensite dev-111-ample-php7.0.conf && $a2restart && ${setphp}7.0")
    names+=("ample-php7.4");      cmds+=("$a2disall && sudo a2ensite dev-111-ample-php7.4.conf && $a2restart && ${setphp}7.4")
    names+=("ample-php8.3");      cmds+=("$a2disall && sudo a2ensite dev-111-ample-php8.3.conf && $a2restart && ${setphp}8.3")
    names+=("ample-php8.4");      cmds+=("$a2disall && sudo a2ensite dev-111-ample-php8.4.conf && $a2restart && ${setphp}8.4")
    names+=("quasar");            cmds+=("$a2disall && sudo a2ensite dev-111-quasar.conf && $a2enmaildev && $a2restart && $node18")
    names+=("quasar-noback");     cmds+=("$a2disall && sudo a2ensite dev-111-quasar-noback.conf && $a2enmaildev && $a2restart && $node18")
    names+=("temporary-ouranos"); cmds+=("$a2disall && sudo a2ensite dev-111-temporary-ouranos.conf && $a2enmaildev && $a2restart && $node22")
    names+=("wordpress");         cmds+=("$a2disall && sudo a2ensite dev-111-wordpress.conf && $a2enmaildev && $a2restart")

    # selection
    local count=${#names[@]} idx="" REPLY PS3 _
    if [[ $# -gt 0 ]]; then
        idx=$1
        if ! [[ $idx =~ ^[0-9]+$ ]] || (( idx < 1 || idx > count )); then
            echo "invalid index: $1 (expected 1-$count)" >&2
            return 1
        fi
    else
        PS3="choice (1-$count): "
        select _ in "${names[@]}"; do
            if [[ ${REPLY:-} =~ ^[0-9]+$ ]] && (( REPLY >= 1 && REPLY <= count )); then
                idx=$REPLY
                break
            fi
            echo "invalid choice" >&2
        done
    fi
    [[ -n $idx ]] || return 1

    # run
    printf '\n[%s]\n%s\n\n' "${names[idx-1]}" "${cmds[idx-1]}"
    eval "${cmds[idx-1]}"
}