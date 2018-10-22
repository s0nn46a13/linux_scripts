#! /usr/bin/env bash

yum remove -y vim-minimal
yum install -y vim-enhanced
yum install -y sudo

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

sh base.sh
