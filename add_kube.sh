#! /usr/bin/env bash

sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl daemon-reload

sudo sed -i "\$a192.168.x.x1 kube01" /etc/hosts
sudo sed -i "\$a192.168.x.x2 kube02" /etc/hosts
sudo sed -i "\$a192.168.x.x3 kube03" /etc/hosts
sudo sed -i "\$a192.168.x.x4 kube04" /etc/hosts
sudo sed -i "\$a192.168.x.x5 kube05" /etc/hosts

# Download, install, enable, start Docker, and add scci-admin to the docker group
sudo wget https://download.docker.com/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker.repo
sudo yum -y install docker-ce
sudo usermod -aG docker s0nn46a13

sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl daemon-reload

# Disable swap
sudo swapoff -a
sudo sed -i 's/\/dev\/mapper\/centos-swap/\#\/dev\/mapper\/centos-swap/g' /etc/fstab

# Add the Kubernetes repos and install kubelet, kubeadm, and kubectl
sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sudo yum install -y kubelet kubeadm kubectl

sudo systemctl enable kubelet
sudo systemctl start kubelet
sudo systemctl daemon-reload

# Cgroup change
sudo sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo systemctl daemon-reload
sudo systemctl restart kubelet

# MUST BE ROOT USER
# Enable br_netfilter
sudo modprobe ip_vs_wrr
sudo modprobe ip_vs_sh
sudo modprobe ip_vs
sudo modprobe ip_vs_rr
sudo modprobe nf_conntrack_ipv4
sudo modprobe br_netfilter
sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo sysctl net.ipv4.ip_forward=1

# Initialize Kubernetes cluster
# https://www.techrepublic.com/article/how-to-install-a-kubernetes-cluster-on-centos-7/
sudo kubeadm init --apiserver-advertise-address=192.168.x.x1 --pod-network-cidr=10.244.0.0/16
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
