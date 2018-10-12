#! /usr/bin/env bash

cd /usr/src
wget https://www.python.org/ftp/python/3.5.0/Python-3.5.0.tgz
sudo gunzip Python-3.5.0.tgz && sudo tar -xvf Python-3.5.0.tar

cd Python-3.5.0
./configure --prefix=/usr/local/ --enable-optimizations
sudo make altinstall

sudo ln -s /usr/local/bin/python3.5 /usr/bin/python3

sudo sed -i "\$aalias python3='/usr/local/bin/python3.5'" ~/.bashrc
sudo sed -i "\$aalias pip3='/usr/local/bin/pip3.5'" ~/.bashrc
sudo sed -i "\$aalias pip='/usr/local/bin/pip3.5'" ~/.bashrc
sudo sed -i "\$aalias sudo='sudo '" ~/.bashrc
source ~/.bashrc

sudo sed -i 's/\$HOME\/bin/\$HOME\/bin:\/usr\/local\/bin/' ~/.bash_profile
source ~/.bash_profile

sudo pip3 install --upgrade pip setuptools wheel 
