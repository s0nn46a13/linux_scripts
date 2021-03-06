#! /usr/bin/env bash

#   Do not run this as root!
#   Do not run this as root!
#   Do not run this as root!
#   Do not run this as root!

# Install common tools
sudo yum -y install open-vm-tools yum-utils nano wget git mlocate yum-cron epel-release

# Upgrade OS
sudo yum clean all
sudo yum -y upgrade

# Enable nano color coding
sudo sed -i 's/# include/include/' /etc/nanorc
sudo sed -i "\$aset const" /etc/nanorc

# Install PowerShell Core
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
sudo yum -y install powershell

# Setup yum-cron to automatically run updates
sudo sed -i 's/update_cmd = default/update_cmd = security/g' /etc/yum/yum-cron.conf
sudo sed -i 's/apply_updates = no/apply updates = yes/g' /etc/yum/yum-cron.conf
sudo sed -i 's/emit_via = stdio/emit_via = email/g' /etc/yum/yum-cron.conf
sudo sed -i 's/email_from = root/email_from = noreply/g' /etc/yum/yum-cron.conf
# Change <USERNAME>@<DOMAIN>.<TLD>
sudo sed -i 's/email_to = root/email_to = <USERNAME>@<DOMAIN>.<TLD>/g' /etc/yum/yum-cron.conf
# Change <MAILSERVER>.<DOMAIN>.<TLD>
sudo sed -i 's/email_host = localhost/email_host = <MAILSERVER>.<DOMAIN>.<TLD>/g' /etc/yum/yum-cron.conf
sudo systemctl start yum-cron
sudo systemctl enable yum-cron

# Install Apache, disable SELinux, and open ports
sudo yum -y install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload

# OPTIONAL Install PHP 7.2
<#
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php72
sudo yum -y install php php-openssl php-pdo php-mbstring php-tokenizer php-curl php-mysql php-ldap php-zip php-fileinfo php-gd php-gd php-dom php-mcrypt php-bcmath
#>

# OPTIONAL Install MariaDB
<#
sudo cat << EOF >/etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
sudo yum -y install mariadb mariadb-server mariadb-devel MariaDB-shared
#>

# Start, create, and secure DB
# Change <DB_NAME>, <DB_USER>, <DB_PASSWORD> and DO NOT REMOVE BLANK LINE
<#
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql --user=root -e "create database <DB_NAME>;"
sudo mysql --user=root -e "create user '<DB_USER>'@'localhost' identified by '<DB_PASSWORD>';"
sudo mysql --user=root -e "grant all privileges on <DB_NAME>.* to '<DB_USER>'@'localhost';"
sudo mysql --user=root -e "flush privileges;"
sudo mysql_secure_installation << EOF

y
<DB_PASSWORD>
<DB_PASSWORD>
y
y
y
y
EOF
#>
