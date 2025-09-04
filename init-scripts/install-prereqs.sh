#!/bin/bash
set -e

# get env vars from settings file
source INSTALL_SETTINGS

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

# update apt package lists
sudo apt update

# install iSCSI initiator, so that we can mount iSCSI targets as volumes
# install ipvsadm for IPVS management
# install NFS client, so we can mount NFS shares as volumes
sudo apt install -y --no-install-recommends open-iscsi ipvsadm nfs-common

# install cri-o, kubeadm, kubelet, and kubectl
# get k8s major version
KUBE_MAJOR_VERSION=${KUBE_VERSION%.*}
CRIO_VERSION=v${KUBE_MAJOR_VERSION}

# add dependencies for cri-o and k8s repos
sudo apt update
sudo apt install -y software-properties-common curl

# add google cloud signing key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBE_MAJOR_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# add k8s apt repo
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBE_MAJOR_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# add CRI-O signing key
curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

# add CRI-O apt repo
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

# install CRI-O
sudo apt update
sudo apt install -y cri-o
sudo apt-mark hold cri-o

# ensure CRI-O service is set up right
sudo mv /etc/cni/net.d/10-crio-bridge.conflist.disabled /etc/cni/net.d/10-crio-bridge.conflist
sudo systemctl enable --now crio.service

# install k8s packages
# install crictl for container debugging
# install etcd-client for etcd debugging
sudo apt update
sudo apt install -y --allow-change-held-packages kubelet=${KUBE_VERSION}-* kubeadm=${KUBE_VERSION}-* kubectl=${KUBE_VERSION}-* cri-tools etcd-client
# hold k8s packages
sudo apt-mark hold kubelet kubeadm kubectl
