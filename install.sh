#! /usr/bin/env bash

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
syntax enable
colorscheme torte

set tabstop=2
set softtabstop=2
set expandtab
set number
set showcmd
set cursorline
filetype indent on
set wildmenu
set lazyredraw
set showmatch
set incsearch
set hlsearch
nnoremap <leader><space> :nohlsearch<CR>
set foldenable
set foldlevelstart=10
set foldnestmax=10
nnoremap <space> za
set foldmethod=indent
let mapleader=","
EOF

# Enable colorscheme torte for root
sudo cat << EOF >/root/.vimrc
syntax enable
colorscheme torte
set tabstop=2
set softtabstop=2
set expandtab
set shiftwidth=2
set autoindent
set smartindent
set number
set showcmd
set cursorline
set wildmenu
set lazyredraw
set showmatch
set incsearch
set hlsearch
set foldenable
set foldlevelstart=10
set foldnestmax=10
set foldmethod=indent

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

# Allow port in SELinux`
semanage port -m -t http_port_t -p tcp 8080

sh add_kube.sh
