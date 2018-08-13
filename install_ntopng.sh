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

# Install redis and ntopng
sudo yum -y install redis hiredis-devel
sudo yum -y install pfring n2disk nprobe ntopng ntopng-data cento

# Configure ntopng
sudo sed -i "\$a--dns-mode=1" /etc/ntopng/ntopng.conf
sudo sed -i "\$a--interface=ens224" /etc/ntopng/ntopng.conf
sudo sed -i "\$a--data-dir=/var/tmp/ntopng" /etc/ntopng/ntopng.conf
sudo sed -i "\$a--daemon" /etc/ntopng/ntopng.conf
sudo sed -i "\$a--local-networks=\"192.168.0.0/23,172.16.0.0/16\"" /etc/ntopng/ntopng.conf
sudo sed -i "\$a--http-prefix=\"/ntopng\"" /etc/ntopng/ntopng.conf

# Start redis
sudo systemctl enable redis
sudo systemctl start redis

# Start ntopng 
sudo systemctl enable ntopng
sudo systemctl start ntopng

# Configure Apache proxy
sudo cat << EOF >/etc/httpd/conf.d/ntopng.conf
ProxyPass /ntopng http://localhost:3000/ntopng
ProxyPassReverse /ntopng http://localhost:3000/ntopng
<Location /ntopng>
SetOutputFilter  proxy-html
ProxyHTMLURLMap / /ntopng/
ProxyHTMLURLMap /ntopng/plugins/ntopng/ /ntopng/plugins/
RequestHeader unset Accept-Encoding
</Location>
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
