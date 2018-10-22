#! /usr/bin/env bash

yum remove -y vim-minimal
yum install -y vim-enhanced
yum install -y sudo

sh base.sh
