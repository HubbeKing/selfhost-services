#!/bin/bash
set -e

# check if docker appears to be installed
if ! [ -x "$(command -v docker)" ]; then
  echo "docker does not appear to be installed, installing..."
  # install prereqs to allow apt to use a repository over HTTPS
  sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      software-properties-common

  # add docker's official GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  # add docker repo to apt
  sudo add-apt-repository \
  "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

  # update
  sudo apt-get update

  # install latest version of docker
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# ensure docker daemon is enabled and running
sudo systemctl enable --now docker

# ensure docker is using recommended settings
sudo cp /tmp/docker-daemon.json /etc/docker/daemon.json
sudo mkdir -p /etc/systemd/system/docker.service.d

# restart docker
sudo systemctl daemon-reload
sudo systemctl restart docker

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
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
