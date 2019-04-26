#! /usr/bin/env bash

# Set Variables
SVR_PORT=8080

# Enable Extra Packages for Enterprise Linux (PEL), install useful tools, and run updates
sudo yum -y install epel-release
sudo yum -y install open-vm-tools git wget mlocate elinks yum-cron yum-utils net-tools sscep ntp ntpdate setroubleshoot-server selinux-policy-devel
sudo yum -y update

# Configure Network Time Protocol
sudo systemctl daemon-reload
sudo systemctl start ntpd
sudo systemctl enable ntpd
sudo ntpdate -u -s 0.centos.pool.ntp.org 1.centos.pool.ntp.org 2.centos.pool.ntp.org
sudo systemctl restart ntpd

# Enable colorscheme torte for user
sudo cat << EOF >.vimrc
syntax on
colorscheme torte
EOF

# Enable colorscheme torte for root
sudo cat << EOF >/root/.vimrc
syntax on
colorscheme torte
EOF
 
# Clean all cached files from any enabled repository
sudo yum clean all
sudo rm -rf /var/cache/yum

# Enable automatic security updates
sudo sed -i 's/update_cmd = default/update_cmd = security/g' /etc/yum/yum-cron.conf
sudo sed -i 's/apply_updates = no/apply updates = yes/g' /etc/yum/yum-cron.conf

sudo systemctl daemon-reload
sudo systemctl enable yum-cron
sudo systemctl start yum-cron

# Allow port in SELinux
sepolicy network -t http_port_t -p tcp $SVR_PORT
#sudo setenforce 1
#sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

sh add_kube.sh
