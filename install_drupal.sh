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
sudo yum -y install php php-mbstring php-gd php-xml php-pear php-fpm php-mysql php-pdo php-opcache

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
sudo mysql_secure_installation << EOF
y
Drupal8DB
Drupal8DB
y
y
y
y
EOF
sudo mysql -u root -pDrupal8DB -e "create database drupaldb;"
sudo mysql -u root -pDrupal8DB -e "create user drupal@localhost identified by 'Drupal8DB';"
sudo mysql -u root -pDrupal8DB -e "grant all on drupaldb.* to drupal@localhost;"
sudo mysql -u root -pDrupal8DB -e "flush privileges;"

# Install Drupal8DB
sudo wget -c https://ftp.drupal.org/files/projects/drupal-8.5.4.tar.gz
sudo tar -zxvf drupal-8.5.4.tar.gz
sudo mv drupal-8.5.4 /var/www/html/drupal
cd /var/www/html/drupal/sites/default/
sudo cp default.settings.php settings.php
sudo chown -R apache:apache /var/www/html/drupal/
sudo chcon -R -t httpd_sys_content_rw_t /var/www/html/drupal/sites/ # Set SELinux rule for Drupal folder
sudo sed -i 's/<Directory "\/var\/www\/html">.*AllowOverride None/<Directory "\/var\/www\/html">.*AllowOverride All' /etc/httpd/conf/httpd.conf
sudo systemctl restart mariadb
sudo systemctl restart httpd

# Configure Web UI
# Go to http://192.168.0.57/drupal, choose language and profile.

# sudo nano /etc/httpd/conf/httpd.conf
# Set AllowOverride to All under <Directory "/var/www/html">

