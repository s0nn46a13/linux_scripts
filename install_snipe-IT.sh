# Update OS
sudo yum -y update

# Install common tools
sudo yum -y install open-vm-tools yum-utils nano wget git mlocate
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum-config-manager --enable epel

# Install Apache, disable SELinux, and open ports
sudo yum -y install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload

# Install PHP 7.2
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php72
sudo yum -y install php php-openssl php-pdo php-mbstring php-tokenizer php-curl php-mysql php-ldap php-zip php-fileinfo php-gd php-gd php-dom php-mcrypt php-bcmath

# Install MariaDB
sudo cat << EOF >/etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
sudo yum -y install mariadb mariadb-server mariadb-devel MariaDB-shared

# Start, secure, & create DB
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql --user=root -e "CREATE DATABASE snipedb;"
sudo mysql --user=root -e "CREATE USER 'snipe_user'@'localhost' IDENTIFIED BY 'snipeitdb';"
sudo mysql --user=root -e "GRANT ALL PRIVILEGES ON snipedb.* TO 'snipe_user'@'localhost';"
sudo mysql --user=root -e "FLUSH PRIVILEGES;"
sudo mysql_secure_installation << EOF

y
snipeitdb
snipeitdb
y
y
y
y
EOF

sudo useradd -g apache snipe_user

sudo mkdir /var/www/snipe-it
sudo git clone https://github.com/snipe/snipe-it /var/www/snipe-it

sudo cat << EOF >/var/www/snipe-it/storage/logs/laravel.log
EOF

sudo chown -R snipe_user:apache /var/www/snipe-it/storage /var/www/snipe-it/public/uploads
sudo chmod -R 777 /var/www/snipe-it/storage
sudo chmod -R g+rwx /var/www/snipe-it/storage
sudo chmod -R 777 /var/www/snipe-it/public/uploads

sudo cp /var/www/snipe-it/.env.example /var/www/snipe-it/.env
sudo sed -i 's/APP_DEBUG=false/APP_DEBUG=true/g' /var/www/snipe-it/.env
sudo sed -i 's/APP_TIMEZONE='\'UTC\''/APP_TIMEZONE=America\/Chicago/g' /var/www/snipe-it/.env
sudo sed -i 's/APP_URL=null/APP_URL=http:\/\/<YOUR HOSTNAME>.<DOMAIN>.<LOCAL>/g' /var/www/snipe-it/.env
sudo sed -i 's/DB_HOST=127.0.0.1/DB_HOST=localhost/g' /var/www/snipe-it/.env
sudo sed -i 's/DB_DATABASE=null/DB_DATABASE=snipedb/g' /var/www/snipe-it/.env
sudo sed -i 's/DB_USERNAME=null/DB_USERNAME=snipe_user/g' /var/www/snipe-it/.env
sudo sed -i 's/DB_PASSWORD=null/DB_PASSWORD=snipeitdb/g' /var/www/snipe-it/.env
sudo sed -i 's/MAIL_HOST=email-smtp.us-west-2.amazonaws.com/MAIL_HOST=<MAILSERVER>.<DOMAIN>.<LOCAL>/g' /var/www/snipe-it/.env
sudo sed -i 's/MAIL_PORT=587/MAIL_PORT=<MAILSERVER_PORT>/g' /var/www/snipe-it/.env
sudo sed -i 's/MAIL_USERNAME=YOURUSERNAME/MAIL_USERNAME=/g' /var/www/snipe-it/.env
sudo sed -i 's/MAIL_PASSWORD=YOURPASSWORD/MAIL_PASSWORD=/g' /var/www/snipe-it/.env
sudo sed -i 's/MAIL_ENCRYPTION=null/MAIL_ENCRYPTION=/g' /var/www/snipe-it/.env
sudo sed -i 's/you@example.com/<NAME@MAIL.COM>/g' /var/www/snipe-it/.env
sudo sed -i 's/''Snipe-IT''/''<ACCOUNT_NAME>''/g' /var/www/snipe-it/.env
sudo sed -i 's/SESSION_LIFETIME=12000/SESSION_LIFETIME=900/g' /var/www/snipe-it/.env
sudo sed -i 's/EXPIRE_ON_CLOSE=false/EXPIRE_ON_CLOSE=true/g' /var/www/snipe-it/.env
sudo sed -i 's/DB_PASSWORD=null/DB_PASSWORD=snipeitdb/g' /var/www/snipe-it/.env

cd /var/www/snipe-it
curl -sS https://getcomposer.org/installer | sudo php
php /var/www/snipe-it/composer.phar install --no-dev --prefer-source

sudo php artisan key:generate << EOF
yes
EOF

sudo cat << EOF >/etc/httpd/conf.d/snipeit.teamscci.local.conf
<VirtualHost *:80>
	ServerName snipe.sonny.local
	DocumentRoot /var/www/snipe-it/public
	<Directory /var/www/snipe-it/public>
		AllowOverride All
		Allow From All
		Options Indexes FollowSymLinks MultiViews
        Order allow,deny
	</Directory>
</VirtualHost>
EOF

sudo reboot
