#!/bin/bash

# copy docker-daemon.json to temp location
sudo cp docker-daemon.json /tmp/docker-daemon.json

# install prereqs
./install-prereqs.sh

# ensure kubelet is running
sudo systemctl enable kubelet.service

# by default, Flannel uses 10.244.0.0/16
# so long as both Flannel and kubeadm agree on the CIDR it shouldn't matter much
DESIRED_CIDR=10.244.0.0/16

# Initialize kubernetes control-plane on this machine
sudo kubeadm init --pod-network-cidr=${DESIRED_CIDR}

# set up kubectl for non-sudo use by copying config into home
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# apply Flannel pod networking manifest
kubectl apply -f core/kube-flannel.yml
