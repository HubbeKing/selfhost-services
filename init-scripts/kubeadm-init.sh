#!/bin/bash
set -e

# install prereqs
./install-prereqs.sh

# ensure kubelet is running
sudo systemctl enable kubelet.service

# get required kubeadm config vars from INSTALL_SETTINGS
source INSTALL_SETTINGS

# Initialize kubernetes control-plane on this machine
KUBE_VERSION=${KUBE_VERSION} POD_NETWORK_CIDR=${POD_NETWORK_CIDR} K8S_SERVICE_CIDR=${K8S_SERVICE_CIDR} envsubst < kubeadm-config.yaml | sudo kubeadm init --config -

# set up kubectl for non-sudo use by copying config into home
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# apply Project Calico pod networking manifest
kubectl apply -f ../core/calico.yaml
