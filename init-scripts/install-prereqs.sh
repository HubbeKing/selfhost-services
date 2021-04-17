#!/bin/bash
set -e

# get env vars from settings file
source INSTALL_SETTINGS
# cri-o version and OS information environment variables
# see https://github.com/cri-o/cri-o/blob/master/install.md for more information
export VERSION=${KUBE_VERSION%.*}
export OS=$OS

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
net.ipv4.conf.all.rp_filter = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# load sysctl parameters immediately
sudo sysctl --system

# add cri-o repos to apt sources.list.d directory
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

# get cri-o release keys
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -

# install cri-o
sudo apt update
sudo apt install -y --allow-change-held-packages cri-o cri-o-runc
sudo apt-mark hold cri-o cri-o-runc

# enable and start crio systemd daemon
sudo systemctl daemon-reload
sudo systemctl enable --now crio

# update apt package lists
sudo apt update

# install iSCSI initiator, so that we can mount iSCSI targets as volumes
# install NFS client, so we can mount NFS shares as volumes
sudo apt install -y open-iscsi nfs-common

# install kubeadm, kubelet, and kubectl
sudo apt install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt update
sudo apt install -y --allow-change-held-packages kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00
sudo apt-mark hold kubelet kubeadm kubectl
