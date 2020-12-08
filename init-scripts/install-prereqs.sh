#!/bin/bash
set -e

# NOTE - KUBE_VERSION and VERSION need to match, see cri-o compatability matrix
# https://github.com/cri-o/cri-o#compatibility-matrix-cri-o--kubernetes

# kubeadm/kubelet/kubectl version to install
KUBE_VERSION=1.19.4-00
# cri-o version and OS information environment variables
# see https://github.com/cri-o/cri-o/blob/master/install.md for more information
export VERSION=1.19
export OS=xUbuntu_20.04

# add cri-o repos to apt sources.list.d directory
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

# get cri-o release keys
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -

# install cri-o
sudo apt update
sudo apt install cri-o cri-o-runc

# enable and start crio systemd daemon
sudo systemcrl enable --now crio

# ensure kernel source address verification is enabled
echo 'net.ipv4.conf.all.rp_filter = 1' | sudo tee /etc/sysctl.d/99-rpfilter-1.conf
sudo sysctl net.ipv4.conf.all.rp_filter=1

# make sure br_netfilter module is loaded
lsmod | grep br_netfilter
if [ $? -ne 0 ]; then
  sudo modprobe br_netfilter
  echo 'br_netfilter' | sudo tee /etc/modules-load.d/99-br-netfilter
fi

# let iptables see bridged traffic
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# update apt package lists
sudo apt-get update

# install iSCSI initiator, so that we can mount iSCSI targets as volumes
sudo apt-get install open-iscsi -y

# install kubeadm, kubelet, and kubectl
sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet=$KUBE_VERSION kubeadm=$KUBE_VERSION kubectl=$KUBE_VERSION
sudo apt-mark hold kubelet kubeadm kubectl
