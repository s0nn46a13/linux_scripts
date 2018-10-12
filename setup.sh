#! /usr/bin/env bash

sudo yum upgrade -y

# Enable Extra Packages for Enterprise Linux (EPEL)
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm open-vm-tools git wget mlocate elinks yum-cron yum-utils 

# Install PowerShell Core
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
sudo yum -y install powershell

# Clean all cached files from any enabled repository
sudo yum clean all

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

# Enable automatic security updates
sudo sed -i 's/update_cmd = default/update_cmd = security/g' /etc/yum/yum-cron.conf
sudo sed -i 's/apply_updates = no/apply updates = yes/g' /etc/yum/yum-cron.conf

sudo systemctl enable yum-cron
sudo systemctl start yum-cron

# Disable SELinux and add firewall rules
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload

sudo wget https://download.docker.com/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker.repo
sudo yum -y install docker-ce

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker sg-admin
