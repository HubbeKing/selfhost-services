#!/bin/bash
set -e

# get env vars from settings file
source INSTALL_SETTINGS

# make sure systemd-resolved is disabled
sudo systemctl disable --now systemd-resolved.service

# if /etc/resolv.conf is a symlink, replace with text file based on INSTALL_SETTINGS
if [[ -L /etc/resolv.conf ]]
then
    sudo rm /etc/resolv.conf
    echo "nameserver $NAMESERVER" | sudo tee /etc/resolv.conf
    echo "search $SEARCH" | sudo tee -a /etc/resolv.conf
fi

# make sure overlay module is loaded
if [ ! `lsmod | grep -o ^overlay` ]; then
  sudo modprobe overlay
fi

# make sure br_netfilter module is loaded
if [ ! `lsmod | grep -o ^br_netfilter` ]; then
  sudo modprobe br_netfilter
fi

# set up modules-load file for them
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

# set required sysctl params
# rp_filter=1 enables strict kernel source address verification
# bridge-nf-call ensures iptables can see bridged traffic
# ip_forward ensures traffic is bridged properly
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# load sysctl parameters immediately
sudo sysctl --system

# set up docker repo for containerd.io package
# requirements for docker repo
sudo apt update
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg

# add docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# add docker repo
echo \
  "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install containerd
sudo apt update
sudo apt install -y --allow-change-held-packages containerd.io

# hold containerd package
sudo apt-mark hold containerd.io

# configure containerd
sudo mkdir -p /etc/containerd
sudo cp containerd_config.toml /etc/containerd/config.toml

# restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# update apt package lists
sudo apt update

# install iSCSI initiator, so that we can mount iSCSI targets as volumes
# install NFS client, so we can mount NFS shares as volumes
sudo apt install -y open-iscsi nfs-common

# install kubeadm, kubelet, and kubectl
# add google cloud signing key
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# add k8s apt repo
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# install packages
sudo apt update
sudo apt install -y --allow-change-held-packages kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00
# hold k8s packages
sudo apt-mark hold kubelet kubeadm kubectl

# install ipvsadm for IPVS management
sudo apt install -y --no-install-recommends ipvsadm
