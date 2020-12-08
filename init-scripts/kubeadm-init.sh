#!/bin/bash
set -e

# install prereqs
./install-prereqs.sh

# ensure kubelet is running
sudo systemctl enable kubelet.service

# Initialize kubernetes control-plane on this machine
sudo kubeadm init --config kubeadm-config.yaml

# set up kubectl for non-sudo use by copying config into home
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# apply Project Calico pod networking manifest
kubectl apply -f ../core/calico.yaml
