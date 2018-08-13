# Install common tools
sudo yum -y install open-vm-tools yum-utils nano wget git mlocate ethtool mod_proxy_html
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Set ens224 to promiscuous mode
sudo ethtool -K ens224 gro off gso off tso off
sudo sed -i "\$aip link set ens224 promisc on" /etc/rc.d/rc.local
sudo chmod u+x /etc/rc.d/rc.local
sudo systemctl enable rc-local
sudo systemctl start rc-local

# Update OS
sudo yum clean all
sudo yum -y update

# Add ntopng repo
cd /etc/yum.repos.d/
sudo wget http://packages.ntop.org/centos-stable/ntop.repo -O ntop.repo

# Install redis
sudo yum -y install redis hiredis-devel

# Configure redis
sudo sed -i 's/dbfilename dump.rdb/dbfilename ntopng.rdb/' /etc/redis.conf
sudo sed -i 's/dir \/var\/lib\/redis/dir \/var\/db\/ntopng/' /etc/redis.conf

# Install ntopng
sudo yum -y install pfring n2disk nprobe ntopng ntopng-data cento

# Configure ntopng
sudo sed -i "\$a-d=/var/db/ntopng" /etc/ntopng/ntopng.conf
sudo sed -i "\$a-s=" /etc/ntopng/ntopng.conf
sudo sed -i "\$a-e=" /etc/ntopng/ntopng.conf
sudo sed -i "\$a-w=3000" /etc/ntopng/ntopng.conf
sudo sed -i "\$a-i='ens224'" /etc/ntopng/ntopng.conf
sudo sed -i "\$a--dns-mode='1'" /etc/ntopng/ntopng.conf
sudo sed -i "\$a--local-networks='192.168.0.0/23,172.16.0.0/16'" /etc/ntopng/ntopng.conf

# Start redis
sudo systemctl enable redis
sudo systemctl start redis

# Start ntopng 
sudo systemctl enable ntopng
sudo systemctl start ntopng

# Configure Apache proxy
sudo cat << EOF >/etc/httpd/conf.d/ntopng.conf
<VirtualHost *:80>
    ServerAdmin admin
    ServerName ntopng.teamscci.local
    ServerAlias ntopng

    <Proxy *>
        Order deny,allow
        Allow from all
    </Proxy>
    ProxyRequests Off
    RewriteEngine On

    ProxyPass / http://localhost:3000/ retry=0 timeout=5
    ProxyPassReverse / http://localhost:3000/

    <Location />
        Order allow,deny
        Allow from all
    </Location>
</VirtualHost>
EOF
sudo systemctl restart httpd

# Enable ntopng through firewall
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo firewall-cmd --zone=public --add-port=3000/tcp --permanent
sudo firewall-cmd --zone=public --add-port=6379/tcp --permanent
sudo firewall-cmd --reload

# Enable syntax color in nano
sudo sed -i 's/# include/include/' /etc/nanorc
sudo sed -i "\$aset const" /etc/nanorc
