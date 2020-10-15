#!/bin/bash
set -e

# copy docker-daemon.json to temp location
sudo cp docker-daemon.json /tmp/docker-daemon.json

# install prereqs
./install-prereqs.sh

# ensure kubelet is running
sudo systemctl enable kubelet.service

# set a Pod network CIDR
# Calico should auto-detect this in Kubeadm, and it should work with the default IPIP overlay mode
DESIRED_CIDR=10.244.0.0/16

# Initialize kubernetes control-plane on this machine
sudo kubeadm init --pod-network-cidr=${DESIRED_CIDR}

# set up kubectl for non-sudo use by copying config into home
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# apply Project Calico pod networking manifest
kubectl apply -f ../core/calico.yaml
