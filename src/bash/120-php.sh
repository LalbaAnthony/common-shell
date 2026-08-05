# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

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
