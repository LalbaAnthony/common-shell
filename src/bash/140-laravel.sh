# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

alias art='php artisan'

artlogs() {
    tail -f storage/logs/laravel.log | grep --color=always -E "ERROR|CRITICAL|ALERT|EMERGENCY"
}

artlogsc() {
    : > storage/logs/laravel.log
}

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
