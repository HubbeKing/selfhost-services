#!/bin/bash

# Initialize kubernetes control-plane on this machine
sudo kubeadm init --pod-network-cidr=10.0.0.0/16

# set up kubectl for non-sudo use by copying config into home
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# set up calico pod networking
kubectl apply -f calico_v3.10_custom_cidr.yaml

# allow scheduling pods on control-plane nodes
kubectl taint nodes --all node-role.kubernetes.io/master-
