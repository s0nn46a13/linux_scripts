# Update OS
sudo yum -y update

# Install common tools
sudo yum -y install open-vm-tools yum-utils nano wget git mlocate 
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum-config-manager --enable epel
sudo yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/r/re2c-0.14.3-2.el7.x86_64.rpm
sudo sed -i 's/# include/include/' /etc/nanorc
sudo sed -i "\$aset const" /etc/nanorc

# Install Apache, disable SELinux, and open ports
sudo yum -y install httpd httpd-devel
sudo systemctl start httpd
sudo systemctl enable httpd
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload

# Install PHP 7.2
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php72
sudo yum -y install php php-mbstring php-gd php-xml php-pear php-fpm php-mysql php-pdo php-opcache php-devel

# Install uploadprogress
sudo git clone https://github.com/Jan-E/uploadprogress
cd uploadprogress/
sudo phpize
./configure
sudo make
sudo make install
sudo echo "extension=uploadprogress.so" > /etc/php.ini

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
sudo mysql --user=root -e "create database drupaldb;"
sudo mysql --user=root -e "create user drupal@localhost identified by 'Drupal8DB';"
sudo mysql --user=root -e "grant all on drupaldb.* to drupal@localhost;"
sudo mysql --user=root -e "flush privileges;"
sudo mysql_secure_installation << EOF

y
Drupal8DB
Drupal8DB
y
y
y
y
EOF

# Install Drupal8DB
sudo wget -c https://ftp.drupal.org/files/projects/drupal-8.5.4.tar.gz
sudo tar -zxvf drupal-8.5.4.tar.gz
sudo mv drupal-8.5.4 /var/www/html/drupal
cd /var/www/html/drupal/sites/default/
sudo cp default.settings.php settings.php
sudo cp default.services.yml services.yml
sudo sed -i '25 s/cookie_lifetime: 2000000/cookie_lifetime: 0/' /var/www/html/drupal/sites/default/services.yml
sudo sed -i "\$a$settings['trusted_host_patterns'] = [" /var/www/html/drupal/sites/default/settings.php
sudo sed -i "\$a'^ilsaus-webdevIT$'," /var/www/html/drupal/sites/default/settings.php
sudo sed -i "\$a];" /var/www/html/drupal/sites/default/settings.php
sudo chown -R apache:apache /var/www/html/drupal/
sudo chcon -R -t httpd_sys_content_rw_t /var/www/html/drupal/sites/ # Set SELinux rule for Drupal folder
sudo sed -i '151 s/None/All/' /etc/httpd/conf/httpd.conf
reboot
