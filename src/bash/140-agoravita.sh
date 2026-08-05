# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

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
