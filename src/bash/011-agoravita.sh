# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

#  -------- Ample --------

crij() {
    local dir
    for dir in /var/www/alalba/crij-{auch,aveyron,herault,occitanie,po,tarn,tarn-et-garonne}; do
        echo "=== $(basename "$dir") ==="
        (cd "$dir" && "$@") || echo "ERREUR dans $dir"
    done
}

#  -------- Kronos --------

3m() {
    local dir
    for dir in /var/www/html/3-{mousses,mousquetons}; do
        echo "=== $(basename "$dir") ==="
        (cd "$dir" && "$@") || echo "ERREUR dans $dir"
    done
}

kwc() {
    if [ -d "back" ]; then
        cd back || return
    fi

    php artisan kronos:wordpress:configure
}

kdev() {
    if [ ! -d "front" ] && [ ! -d "back" ]; then
        echo "No front/ or back/ directory here"
        return 1
    fi

    npx -y concurrently -n front -c cyan \
        "cd front && yarn dev"
}

kfbuild() {
    if [ ! -d "front" ]; then
        echo "No front/ directory here"
        return 1
    fi

    local env_prod=".env.prod"
    local env_backup=".env.old"
    local env=".env"

    echo "Back up .env and copy .env.prod to .env"
    mv "$env" "$env_backup"
    cp "$env_prod" "$env"

    echo "Building front..."
    local rc=0
    # Subshell: the caller's cwd never changes, and the .env restore below runs whatever the build outcome
    ( cd front && yarn build ) || rc=$?
    if (( rc == 0 )); then
        echo "Front build complete."
    else
        echo "Front build failed (exit $rc)." >&2
    fi

    echo "Cleaning up .env"
    rm "$env"
    mv "$env_backup" "$env"

    return "$rc"
}

#  -------- Atlas --------

atld() {
    if [ ! -d "front" ] && [ ! -d "back" ]; then
        echo "No front/ or back/ directory here"
        return 1
    fi

    npx -y concurrently -n front,back,back-worker -c cyan,magenta,magenta \
        "cd front && yarn dev" \
        "cd back && npm run dev" \
        "cd back && php artisan queue:work"
}

#  -------- WordPress --------

# Point a database imported from production at http://<current dir>.dev4
# Extra arguments go to every search-replace, e.g. `wpset --dry-run`
wpset() {
    local old_url old new
    old_url=$(wp option get siteurl) || return
    old=${old_url#*://}
    old=${old%%/*}
    new="$(basename "$PWD").dev4"

    if [[ -z $old ]]; then
        echo "Cannot extract a host from siteurl: '$old_url'" >&2
        return 1
    fi
    if [[ $old == "$new" ]]; then
        echo "siteurl already points at $new"
        return 0
    fi

    echo "Replacing $old with $new"
    wp search-replace "https://$old" "http://$new" --all-tables "$@" || return
    wp search-replace "http://$old" "http://$new" --all-tables "$@" || return
    wp search-replace "https:\\/\\/$old" "http:\\/\\/$new" --all-tables "$@" || return
    wp search-replace "http:\\/\\/$old" "http:\\/\\/$new" --all-tables "$@" || return
    wp search-replace "$old" "$new" --all-tables "$@" || return

    if wp plugin is-active elementor; then
        wp elementor flush-css || return
    fi

    echo "New siteurl:"
    wp option get siteurl
}

#  -------- Common --------

devs() {
    # reusable pieces
    local setnode="npm install -g n && n "
    local setphp="sudo update-alternatives --set php /usr/bin/php"
    local a2endefaultdev="sudo a2ensite dev-000-default.conf"
    local a2enmaildev="sudo a2ensite dev-000-maildev.conf"
    local a2disall="(sudo a2dissite '*.conf' || echo 'No site to disable')"
    local a2restart="sudo apache2ctl configtest && sudo systemctl restart apache2"

    # preset table: one line per preset, same position in both arrays
    local names=() cmds=()
    names+=("nuxt-wp-php7.4");                cmds+=("${setphp}7.4 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-nuxt-wp-php74.conf && $a2restart")
    names+=("nuxt-wp-php8.3");                cmds+=("${setphp}8.3 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-nuxt-wp-php83.conf && $a2restart")
    names+=("nuxt-wp-php8.5");                cmds+=("${setphp}8.5 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-nuxt-wp-php85.conf && $a2restart")
    names+=("nuxt-wp-php8.6");                cmds+=("${setphp}8.6 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-nuxt-wp-php86.conf && $a2restart")
    names+=("atlas-php8.4");                  cmds+=("${setphp}8.4 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-atlas-php84.conf && $a2restart")
    names+=("atlas-php8.5");                  cmds+=("${setphp}8.5 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-atlas-php85.conf && $a2restart")
    names+=("atlas-php8.6");                  cmds+=("${setphp}8.6 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-atlas-php86.conf && $a2restart")
    names+=("ample-php5.6");                  cmds+=("${setphp}5.6 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-ample-php56.conf && $a2restart")
    names+=("ample-php7.0");                  cmds+=("${setphp}7.0 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-ample-php70.conf && $a2restart")
    names+=("ample-php7.4");                  cmds+=("${setphp}7.4 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-ample-php74.conf && $a2restart")
    names+=("ample-php8.3");                  cmds+=("${setphp}8.3 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-ample-php83.conf && $a2restart")
    names+=("ample-php8.4");                  cmds+=("${setphp}8.4 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-ample-php84.conf && $a2restart")
    names+=("ample-php8.5");                  cmds+=("${setphp}8.5 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-ample-php85.conf && $a2restart")
    names+=("ample-php8.6");                  cmds+=("${setphp}8.6 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-ample-php86.conf && $a2restart")
    names+=("quasar-php7.4");                 cmds+=("${setphp}7.4 && ${setnode}18 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-quasar-php74.conf && $a2restart")
    names+=("quasar-php8.5");                 cmds+=("${setphp}8.5 && ${setnode}18 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-quasar-php85.conf && $a2restart")
    names+=("quasar-php8.6");                 cmds+=("${setphp}8.6 && ${setnode}18 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-quasar-php86.conf && $a2restart")
    names+=("quasar-noback-php7.4-node18");   cmds+=("${setphp}7.4 && ${setnode}18 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-quasar-noback-php74.conf && $a2restart")
    names+=("quasar-noback-php7.4-node22");   cmds+=("${setphp}7.4 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-quasar-noback-php74.conf && $a2restart")
    names+=("quasar-noback-php8.5-node18");   cmds+=("${setphp}8.5 && ${setnode}18 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-quasar-noback-php85.conf && $a2restart")
    names+=("quasar-noback-php8.5-node22");   cmds+=("${setphp}8.5 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-quasar-noback-php85.conf && $a2restart")
    names+=("quasar-noback-php8.6-node18");   cmds+=("${setphp}8.6 && ${setnode}18 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-quasar-noback-php86.conf && $a2restart")
    names+=("quasar-noback-php8.6-node22");   cmds+=("${setphp}8.6 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-quasar-noback-php86.conf && $a2restart")
    names+=("temporary-ouranos");             cmds+=("${setphp}8.3 && ${setnode}22 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-temporary-ouranos.conf && $a2restart")
    names+=("wordpress-php8.3");              cmds+=("${setphp}8.3 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-wordpress-php83.conf && $a2restart")
    names+=("wordpress-php8.5");              cmds+=("${setphp}8.5 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-wordpress-php85.conf && $a2restart")
    names+=("wordpress-php8.6");              cmds+=("${setphp}8.6 && ${setnode}24 && $a2disall && $a2endefaultdev && $a2enmaildev && sudo a2ensite dev-111-wordpress-php86.conf && $a2restart")

    # selection
    local count=${#names[@]} idx=""
    if [[ $# -gt 0 ]]; then
        idx=$1
        if ! [[ $idx =~ ^[0-9]+$ ]] || (( idx < 1 || idx > count )); then
            echo "invalid index: $1 (expected 1-$count)" >&2
            return 1
        fi
    else
        idx=$(xselect "choice" "${names[@]}") || return
    fi

    # run
    printf '\n[%s]\n%s\n\n' "${names[idx-1]}" "${cmds[idx-1]}"
    eval "${cmds[idx-1]}"
}

# Relay a directory between two hosts through this machine: pull <src> into a local staging dir, then push it to <dst>
#   rrelay [-p src_port] [-P dst_port] [-t staging_dir] <src> <dst> [rsync args...]
#   rrelay -p 2222 old@host-a:/var/www/site/uploads new@host-b:/var/www/site/uploads --exclude=cache/
# The contents of <src> land in <dst>, trailing slash or not. Extra arguments go to both legs (--exclude, --delete...).
# The push drops ownership and sets dirs 775 / files 664; a --chmod in the extra arguments is applied after that.
# Before the pull, a dry run sizes it and stops when the staging dir's filesystem lacks the room.
# A staging dir created here is removed on success and kept on failure; `-t <dir>` reruns incrementally from it.
# A dir given with -t is never removed.
rrelay() {
    local usage="Usage: rrelay [-p src_port] [-P dst_port] [-t staging_dir] <src> <dst> [rsync args...]"
    local OPTIND opt src_port="" dst_port="" tmp="" own_tmp=1
    while getopts "p:P:t:" opt; do
        case $opt in
            p) src_port=$OPTARG ;;
            P) dst_port=$OPTARG ;;
            t) tmp=$OPTARG; own_tmp=0 ;;
            *) echo "$usage" >&2; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    if (( $# < 2 )); then
        echo "$usage" >&2
        return 1
    fi
    local src=$1 dst=$2
    shift 2

    local port
    for port in "$src_port" "$dst_port"; do
        if [[ -n $port && ! $port =~ ^[0-9]+$ ]]; then
            echo "Invalid port: $port" >&2
            return 1
        fi
    done
    if ! command -v rsync >/dev/null; then
        echo "rsync not found" >&2
        return 1
    fi

    # Relay the contents, never the directory itself; a bare `host:` (remote home) is left alone
    [[ $src == */ || $src == *: ]] || src+=/
    [[ $dst == */ || $dst == *: ]] || dst+=/

    # -e only when a port is given, so ~/.ssh/config still applies otherwise
    local pull_ssh=() push_ssh=()
    [[ -n $src_port ]] && pull_ssh=(-e "ssh -p $src_port")
    [[ -n $dst_port ]] && push_ssh=(-e "ssh -p $dst_port")

    # Under $HOME, not /tmp: /tmp may be a RAM-backed tmpfs, too small for a site's uploads
    if (( own_tmp )); then
        tmp=$(mktemp -d "$HOME/rrelay.XXXXXX") || return
    else
        mkdir -p "$tmp" || return
        tmp=${tmp%/}
    fi

    # Room check, before anything is staged. A dry-run pull sizes exactly what the pull will write here: the extra
    # arguments (--exclude...) apply, and what a -t dir already holds is not counted again. A du of <src> would see
    # neither, and would need the transport (port, ssh config, host::module) rebuilt by hand
    local rc=0 stats need created avail room
    echo "=== Room check: $src -> $tmp/ ==="
    stats=$(rsync -an --stats --no-human-readable "${pull_ssh[@]}" "$@" "$src" "$tmp/") || rc=$?
    if (( rc != 0 )); then
        echo "rrelay failed (dry-run rsync exit $rc)" >&2
        (( own_tmp )) && rmdir "$tmp"
        return "$rc"
    fi
    need=$(sed -n 's/^Total transferred file size: \([0-9.,]*\) bytes.*/\1/p' <<<"$stats")
    created=$(sed -n 's/^Number of created files: \([0-9.,]*\).*/\1/p' <<<"$stats")
    avail=$(df -Pk -- "$tmp" | awk 'NR == 2 { print $4 }')
    need=${need//[.,]/}
    created=${created//[.,]/}
    [[ $created =~ ^[0-9]+$ ]] || created=0
    if [[ $need =~ ^[0-9]+$ && $avail =~ ^[0-9]+$ ]]; then
        # Bytes alone undercount many small files (thumbnails): add up to one 4 KiB block per created file or dir
        (( need += created * 4096, avail *= 1024 ))
        room=$(awk -v n="$need" -v a="$avail" '
            function h(b,  u, i) { split("B KiB MiB GiB TiB", u, " "); i = 1; while (b >= 1024 && i < 5) { b /= 1024; i++ } return sprintf("%.1f %s", b, u[i]) }
            BEGIN { printf "%s needed, %s free", h(n), h(a) }')
        if (( need > avail )); then
            echo "Not enough room in $tmp: $room. Free some space, or stage elsewhere with -t <dir>" >&2
            (( own_tmp )) && rmdir "$tmp"
            return 1
        fi
        echo "$room"
    else
        echo "Room not checked: cannot read the dry-run size or the free space of $tmp" >&2
    fi

    echo "=== Pull: $src -> $tmp/ ==="
    rsync -avz --info=progress2 "${pull_ssh[@]}" "$@" "$src" "$tmp/" || rc=$?

    if (( rc == 0 )); then
        echo "=== Push: $tmp/ -> $dst ==="
        rsync -avz --info=progress2 "${push_ssh[@]}" \
            --no-owner --no-group --chmod=Dug=rwx,Do=rx,Fug=rw,Fo=r \
            "$@" "$tmp/" "$dst" || rc=$?
    fi

    if (( rc != 0 )); then
        echo "rrelay failed (rsync exit $rc). Staging kept: $tmp (rerun with -t $tmp)" >&2
        return "$rc"
    fi
    if (( own_tmp )); then
        rm -rf "$tmp"
        echo "Done."
    else
        echo "Done. Staging kept: $tmp"
    fi
}
