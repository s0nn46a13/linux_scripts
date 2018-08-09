# Install common tools
sudo yum -y install open-vm-tools yum-utils nano wget git mlocate 
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Add ntopng repo
cd /etc/yum.repos.d/
sudo wget http://packages.ntop.org/centos-stable/ntop.repo -O ntop.repo

# Update OS
sudo yum -y update

# Install redis and ntopng
sudo yum -y install pfring n2disk nprobe ntopng ntopng-data cento redis
sudo yum -y install hiredis-devel

# Start redis and ntopng services
sudo systemctl start redis
sudo systemctl enable redis
sudo systemctl start ntopng
sudo systemctl enable ntopng

# Enable ntopng through firewall
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

sudo sed -i 's/# include/include/' /etc/nanorc
sudo sed -i "\$aset const" /etc/nanorc
