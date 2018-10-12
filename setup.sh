#! /usr/bin/env bash

sudo yum upgrade -y

# Enable EPEL
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"

# Standard installs
sudo yum -y install open-vm-tools nano git wget mlocate elinks yum-cron yum-utils 

# Install Powershell
curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
sudo yum -y install powershell
sudo yum clean all

# Enable color coding in nano
sudo sed -i 's/# include/include/' /etc/nanorc
sudo sed -i "\$aset const" /etc/nanorc

# Enable automatic security updates
sudo sed -i 's/update_cmd = default/update_cmd = security/g' /etc/yum/yum-cron.conf
sudo sed -i 's/apply_updates = no/apply updates = yes/g' /etc/yum/yum-cron.conf

# Disable SELinux and add firewall rules
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload
