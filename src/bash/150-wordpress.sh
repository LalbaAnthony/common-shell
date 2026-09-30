# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias wpclisetup='cd ~ && rm -f wp-cli.phar && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar'
# alias wp='~/wp-cli.phar' # ? If you want to use wp from anywhere, uncomment this line and add ~/ to your $PATH
alias wplist='wp plugin list --field=name' # List all plugin slugs
alias wpclear='wp cache flush && wp transient delete --all && sudo systemctl reload apache2' # Clear all cache layers
alias wpexport='wp db export backup_wp_$(date +%F_%H-%M-%S).sql' # Export DB to timestamped file
alias wptestdb='sudo -u www-data php -r '\''require "wp-config.php"; $m = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME); echo $m->connect_error ? "Error: " . $m->connect_error : "Success!\n";'\'''
alias wptesturl='sudo -u www-data php -r '\''require "wp-load.php"; echo get_option("siteurl")."\n"; echo get_option("home")."\n";'\'''
