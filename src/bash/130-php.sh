# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

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
