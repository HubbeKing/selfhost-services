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

# set up docker repo for containerd.io package
# requirements for docker repo
sudo apt update
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg

# check distro ID
DISTRO=$(lsb_release -is|tr '[:upper:]' '[:lower:]')

# add docker GPG key
curl -fsSL "https://download.docker.com/linux/${DISTRO}/gpg" | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# add docker repo
echo \
  "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${DISTRO} \
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
# install ipvsadm for IPVS management
# install NFS client, so we can mount NFS shares as volumes
sudo apt install -y --no-install-recommends open-iscsi ipvsadm nfs-common

# install kubeadm, kubelet, and kubectl
# get k8s major version
KUBE_MAJOR_VERSION=${KUBE_VERSION%.*}

# add google cloud signing key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBE_MAJOR_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# add k8s apt repo
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBE_MAJOR_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# install k8s packages
# install crictl for container debugging
# install etcd-client for etcd debugging
sudo apt update
sudo apt install -y --allow-change-held-packages kubelet=${KUBE_VERSION}-1.1 kubeadm=${KUBE_VERSION}-1.1 kubectl=${KUBE_VERSION}-1.1 cri-tools etcd-client
# hold k8s packages
sudo apt-mark hold kubelet kubeadm kubectl
