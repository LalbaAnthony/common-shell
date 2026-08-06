# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

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
