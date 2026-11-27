# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias a280='sudo apache2ctl -S | grep -A2 "port 80"'
alias a2log='tail -f -n 100 /var/log/apache2/error.log'
alias a2c='sudo apache2ctl configtest'
alias a2s='sudo systemctl status apache2'
alias a2start='sudo systemctl start apache2'
alias a2stop='sudo systemctl stop apache2'
alias a2r='sudo systemctl reload apache2'
alias a2rr='sudo apache2ctl configtest && sudo systemctl restart apache2'
alias a2sa='cd /etc/apache2/sites-available'
alias a2se='cd /etc/apache2/sites-enabled'
alias a2ca='cd /etc/apache2/conf-available'
alias a2ce='cd /etc/apache2/conf-enabled'
alias a2m='cd /etc/apache2/mods-available'
alias a2me='cd /etc/apache2/mods-enabled'

webperms() {
    local TARGET=$1
    local WEB_USER=${CSH_WEB_USER:-www-data}
    local OWNER=${2:-$WEB_USER}

    if [ -z "$TARGET" ]; then
        echo "Usage: webperms <path> [owner=$WEB_USER]"
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

    /bin/chmod -R 775 "$TARGET" || return
    /bin/chown -R "$OWNER:$WEB_USER" "$TARGET" || return

    echo "Set permissions 775 and owner $OWNER:$WEB_USER on '$TARGET'"
}

a2pick() {
    local sites idx
    sites=(/etc/apache2/sites-available/*.conf)

    idx=$(xselect "site" "${sites[@]}") || return
    sudo a2dissite *.conf
    sudo a2ensite "$(basename "${sites[idx-1]}")"
    sudo apache2ctl configtest && sudo systemctl restart apache2
}
