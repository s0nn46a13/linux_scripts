sudo yum install open-vm-tools yum-utils net-tools nano wget git mlocate httpd -y
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum-config-manager --enable remi-php72 -y
sudo yum install php php-openssl php-pdo php-mbstring php-tokenizer php-curl php-mysql php-ldap php-zip php-fileinfo php-gd php-gd php-dom php-mcrypt php-bcmath -y
sudo yum update -y

sudo firewall-cmd --permanent --zone=public --add-port=80/tcp

sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

sudo cat << EOF >/etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

sudo yum install mariadb-server mariadb-client -y

sudo systemctl enable httpd
sudo systemctl start httpd

sudo systemctl enable mariadb
sudo systemctl start mariadb

sudo useradd -g apache snipe_user

sudo mysql_secure_installation << EOF

y
snipeitdb
snipeitdb
y
y
y
y
EOF

sudo mysql -u root -psnipeitdb << EOF
CREATE DATABASE snipedb;
CREATE USER 'snipe_user'@'localhost' IDENTIFIED BY 'snipeitdb';
GRANT ALL PRIVILEGES ON snipedb.* TO 'snipe_user'@'localhost';
FLUSH PRIVILEGES;
exit
EOF

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
	ServerName snipe-it.teamscci.local
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
