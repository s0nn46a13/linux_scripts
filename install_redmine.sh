# Update OS
sudo yum -y update

# Install common tools
sudo yum -y install open-vm-tools yum-utils nano wget git mlocate
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum-config-manager --enable epel

#Install, configure, and start Apache
sudo yum -y install httpd
sudo rm -f /etc/httpd/conf.d/welcome.conf
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo sed -i '86 s/root@localhost/scciadit@teamscci.com/' /etc/httpd/conf/httpd.conf
sudo sed -i '95 s/www.example.com:80/ilsaus-redmine.teamscci.local:80/' /etc/httpd/conf/httpd.conf
sudo sed -i '151 s/None/All/' /etc/httpd/conf/httpd.conf
sudo sed -i '164 s/index.html/index.html index.cgi index.php/' /etc/httpd/conf/httpd.conf
sudo sed -i "\$aServerTokens Prod" /etc/httpd/conf/httpd.conf
sudo sed -i "\$aKeepAlive On" /etc/httpd/conf/httpd.conf

sudo systemctl start httpd
sudo systemctl enable httpd

sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --reload

sudo cat << EOF >/var/www/html/index.html
<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
Test Page
</div>
</body>
</html>
EOF

sudo yum -y install postfix

# Install Postfix to configure SMTP, /etc/postfix/main.cf
sudo sed -i '75 s/#myhostname = host.domain.tld/myhostname = ilsaus-redmine.teamscci.local/' /etc/postfix/main.cf
sudo sed -i '83 s/#mydomain = domain.tld/mydomain = teamscci.local/' /etc/postfix/main.cf
sudo sed -i '99 s/#myorigin = $mydomain/myorigin = teamscci.com/' /etc/postfix/main.cf
sudo sed -i '116 s/localhost/all/' /etc/postfix/main.cf
sudo sed -i '164 s/$myhostname, localhost.$mydomain, localhost/ilsaus-redmine, localhost.teamscci.local, localhost, teamscci.local/' /etc/postfix/main.cf
sudo sed -i '264 s/#mynetworks = 168.100.189.0\/28, 127.0.0.0\/8/mynetworks = 192.168.0.0\/23, 127.0.0.0\/8/' /etc/postfix/main.cf
sudo sed -i '419 s/#home_mailbox = Maildir\//home_mailbox = Maildir\//' /etc/postfix/main.cf
sudo sed -i '572 s/#smtpd_banner = $myhostname ESMTP $mail_name/smtpd_banner = ilsaus-redmine ESMTP/' /etc/postfix/main.cf
sudo sed -i "\$amessage_size_limit = 10485760" /etc/postfix/main.cf
sudo sed -i "\$amailbox_size_limit = 1073741824" /etc/postfix/main.cf
sudo sed -i "\$asmtpd_sasl_type = dovecot" /etc/postfix/main.cf
sudo sed -i "\$asmtpd_sasl_path = private/auth" /etc/postfix/main.cf
sudo sed -i "\$asmtpd_sasl_auth_enable = yes" /etc/postfix/main.cf
sudo sed -i "\$asmtpd_sasl_security_options = noanonymous" /etc/postfix/main.cf
sudo sed -i "\$asmtpd_sasl_local_domain = ilsaus-redmine" /etc/postfix/main.cf
sudo sed -i "\$asmtpd_recipient_restrictions = permit_mynetworks,permit_auth_destination,permit_sasl_authenticated,reject" /etc/postfix/main.cf

sudo systemctl restart postfix 
sudo systemctl enable postfix

sudo firewall-cmd --add-service=smtp --permanent
sudo firewall-cmd --reload

# Install MariaDB
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
sudo ln -s '/usr/lib/systemd/system/mariadb.service' '/etc/systemd/system/multi-user.target.wants/mariadb.service'
sudo mysql --user=root -e "create database redmine;"
sudo mysql --user=root -e "grant all privileges on redmine.* to redmine@'localhost' identified by 'redmine';"
sudo mysql --user=root -e "flush privileges;"
sudo mysql_secure_installation << EOF

y
RedmineDB
RedmineDB
y
y
y
y
EOF

sudo firewall-cmd --add-service=mysql --permanent 
sudo firewall-cmd --reload 

# Install Ruby
sudo yum --enablerepo=centos-sclo-rh -y install rh-ruby22
sudo scl enable rh-ruby22 bash
sudo cat << EOF >/etc/profile.d/rh-ruby22.sh
#!/bin/bash

source /opt/rh/rh-ruby22/enable
export X_SCLS="`scl enable rh-ruby22 'echo $X_SCLS'`"
export PATH=$PATH:/opt/rh/rh-ruby22/root/usr/local/bin
EOF

sudo yum -y install ImageMagick ImageMagick-devel libcurl-devel httpd-devel mariadb-devel ipa-pgothic-fonts

sudo wget -c http://www.redmine.org/releases/redmine-3.4.6.tar.gz
sudo tar zxvf redmine-3.4.6.tar.gz
sudo mv redmine-3.4.6 /var/www/redmine
cd /var/www/redmine

sudo cat << EOF >./config/database.yml
production:
    adapter: mysql2
    # database name
    database: redmine
    host: localhost
    # database user
    username: redmine
    # password for user above
    password: redmine
    encoding: utf8
EOF

# Change dlp.srv.world
sudo cat << EOF >./config/configuration.yml
production:
    email_delivery:
        delivery_method: :smtp
        smtp_settings:
            address: "localhost"
            port: 25
            domain: 'teamscci.local'
    rmagick_font_path: /usr/share/fonts/ipa-pgothic/ipagp.ttf
EOF

gem install bundler --no-rdoc --no-ri
bundle install --without development test postgresql sqlite
bundle exec rake generate_secret_token
bundle exec rake db:migrate RAILS_ENV=production
gem install passenger --no-rdoc --no-ri
passenger-install-apache2-module

# Verify passenger version, change dlp.srv.world
sudo cat << EOF >/etc/httpd/conf.d/passenger.conf
LoadModule passenger_module /usr/lib64/ruby/gems/2.2.0/gems/passenger-5.0.13/buildout/apache2/mod_passenger.so
PassengerRoot /usr/lib64/ruby/gems/2.2.0/gems/passenger-5.0.13
PassengerDefaultRuby /usr/bin/ruby
NameVirtualHost *:80
<VirtualHost *:80>
    ServerName ilsaus-redmine.teamscci.local
    DocumentRoot /var/www/redmine/public
</VirtualHost>
EOF

sudo chown -R apache:apache /var/www/redmine
reboot
