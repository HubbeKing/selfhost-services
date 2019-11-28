#!/bin/bash

# by default, Calico uses 192.168.0.0/16, but this conflicts with my setup
DESIRED_CIDR=10.0.0.0/16

# Initialize kubernetes control-plane on this machine
sudo kubeadm init --pod-network-cidr=${DESIRED_CIDR}

# set up kubectl for non-sudo use by copying config into home
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# fetch Calico pod networking config, alter for DESIRED_CIDR, and apply
wget https://docs.projectcalico.org/v3.10/manifests/calico.yaml
sed -i 's|192.168.0.0/16|'${DESIRED_CIDR}'|g' calico.yaml
kubectl apply -f calico.yaml

# allow scheduling pods on control-plane nodes
kubectl taint nodes --all node-role.kubernetes.io/master-
