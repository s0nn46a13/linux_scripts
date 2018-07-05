# Update OS
sudo yum -y update

# Install common tools
sudo yum -y install open-vm-tools yum-utils nano wget git mlocate zip unzip file
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

# Add settings to /etc/my.cnf
sudo sed -i "\$a[mysqld]" /etc/my.cnf
sudo sed -i "\$amax_allowed_packet=2097652" /etc/my.cnf

# Install, start, and secure MariaDB
sudo cat << EOF >/etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
sudo yum -y install mariadb mariadb-server mariadb-devel MariaDB-shared
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql_secure_installation << EOF

y
iTopDB
iTopDB
y
y
y
y
EOF

# Install PHP 5.6
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php56
sudo yum install -y php php-mysql php-mcrypt php-xml php-cli php-soap php-ldap graphviz php-gd

# Reconfigure /etc/php.ini
sudo sed -i '672 s/8M/32M/' /etc/php.ini
sudo systemctl restart httpd

# Download, unzip, and move iTop
sudo mkdir /var/www/html/itop
cd /var/www/html/itop
sudo wget -c https://sourceforge.net/projects/itop/files/itop/2.4.1/iTop-2.4.1-3714.zip
sudo unzip iTop-2.4.1-3714.zip
sudo chown -R apache:apache /var/www/html/itop
sudo rm -f *
sudo mv web/* .
sudo rmdir web

# Set SElinux rule for /var/www/html folder
sudo chcon -R -t httpd_sys_content_rw_t /var/www/html/

reboot
