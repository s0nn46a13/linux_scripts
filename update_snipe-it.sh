cd /var/www/snipe-it
sudo git pull https://github.com/snipe/snipe-it.git
sudo php composer.phar install --no-dev --prefer-source
sudo php composer.phar dump-autoload
sudo php artisan migrate << EOF
yes
EOF
sudo php artisan config:clear
sudo php artisan config:cache
