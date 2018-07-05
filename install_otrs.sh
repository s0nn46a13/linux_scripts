# Update OS
sudo yum -y update

# Install common tools
sudo yum -y install open-vm-tools yum-utils nano wget git mlocate gcc
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum-config-manager --enable epel

#Install, configure, and start Apache
sudo yum -y install httpd httpd-devel
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

sudo systemctl start httpd
sudo systemctl enable httpd

sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload

sudo systemctl restart firewalld

# Install MariaDB
sudo cat << EOF >/etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
sudo yum -y install mariadb mariadb-server mariadb-devel MariaDB-shared

sudo sed -i "\$a[mysqld]" /etc/my.cnf
sudo sed -i "\$amax_allowed_packet   = 64M" /etc/my.cnf
sudo sed -i "\$aquery_cache_size     = 32M" /etc/my.cnf
sudo sed -i "\$ainnodb_log_file_size = 256M" /etc/my.cnf
sudo sed -i "\$acharacter-set-server=utf8" /etc/my.cnf
sudo sed -i "\$acollation-server=utf8_general_ci" /etc/my.cnf

# Start, secure, & create DB
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql --user=root -e "create database otrsdb character set='utf8' collate='utf8_general_ci';"
sudo mysql --user=root -e "create user otrs_usr@localhost identified by 'otrs60801';"
sudo mysql --user=root -e "grant all on otrsdb.* to otrs_usr@localhost;"
sudo mysql --user=root -e "flush privileges;"
sudo mysql_secure_installation << EOF

y
otrs60801
otrs60801
y
y
y
y
EOF

# Install OTRS
sudo yum -y install https://ftp.otrs.org/pub/otrs/RPMS/rhel/7/otrs-6.0.8-01.noarch.rpm
sudo systemctl restart httpd

# Check and install additional Perl Modules
sudo yum install -y "perl(Crypt::Eksblowfish::Bcrypt)" "perl(DBD::Pg)" "perl(Encode::HanExtra)" "perl(JSON::XS)" "perl(Mail::IMAPClient)" "perl(Authen::NTLM)" "perl(ModPerl::Util)" "perl(Text::CSV_XS)" "perl(YAML::XS)"
sudo /opt/otrs/bin/otrs.CheckModules.pl

reboot
