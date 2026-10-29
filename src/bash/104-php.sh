# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias phppick='sudo update-alternatives --config php'
alias phplist='sudo update-alternatives --list php'
alias php56='sudo update-alternatives --set php /usr/bin/php5.6 && sudo systemctl restart apache2'
alias php70='sudo update-alternatives --set php /usr/bin/php7.0 && sudo systemctl restart apache2'
alias php74='sudo update-alternatives --set php /usr/bin/php7.4 && sudo systemctl restart apache2'
alias php81='sudo update-alternatives --set php /usr/bin/php8.1 && sudo systemctl restart apache2'
alias php82='sudo update-alternatives --set php /usr/bin/php8.2 && sudo systemctl restart apache2'
alias php83='sudo update-alternatives --set php /usr/bin/php8.3 && sudo systemctl restart apache2'
alias php84='sudo update-alternatives --set php /usr/bin/php8.4 && sudo systemctl restart apache2'
alias php85='sudo update-alternatives --set php /usr/bin/php8.5 && sudo systemctl restart apache2'
alias phpsetup='rm -rf vendor ; composer install'

# Syntax-check every PHP file under the current folder, skipping vendor, node_modules and .git
phpl() {
    if ! command -v php >/dev/null 2>&1; then
        echo "php not found"
        return 1
    fi

    local file output total=0 failed=0

    while IFS= read -r -d '' file; do
        total=$((total + 1))
        if ! output=$(php -l "$file" 2>&1); then
            echo "$output"
            failed=$((failed + 1))
        fi
    done < <(find . -type d \( -name vendor -o -name node_modules -o -name .git \) -prune -o -type f -name '*.php' -print0)

    if [ "$failed" -gt 0 ]; then
        echo "$failed of $total PHP files have syntax errors"
        return 1
    fi

    echo "$total PHP files linted, no syntax errors"
}
