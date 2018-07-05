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

# Start, create, & secure DB
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql --user=root -e "create database joomladb;"
sudo mysql --user=root -e "create user joomla@localhost identified by 'Joomla!3.8DB';"
sudo mysql --user=root -e "grant all on joomladb.* to joomla@localhost;"
sudo mysql --user=root -e "flush privileges;"
sudo mysql_secure_installation << EOF

y
Joomla!3.8DB
Joomla!3.8DB
y
y
y
y
EOF

# Install Joomla
sudo wget -c https://downloads.joomla.org/cms/joomla3/3-8-10/Joomla_3-8-10-Stable-Full_Package.tar.gz
sudo mkdir /var/www/html/joomla
sudo tar -zxvf Joomla_3-8-10-Stable-Full_Package.tar.gz  -C /var/www/html/joomla
chown -R apache:apache /var/www/html/joomla
sudo chcon -R -t httpd_sys_content_rw_t /var/www/html/joomla # Set SELinux rule for Joomla folder

# Go to http://<IP ADDRESS>/joomla
