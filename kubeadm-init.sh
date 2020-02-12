#!/bin/bash

# ensure kubelet service is enabled
sudo systemctl enable kubelet.service

# ensure docker uses systemd for its cgroup driver
sudo ./setup-docker.sh

# ensure kernel source address verification is enabled
# this is likely Arch Linux specific
echo 'net.ipv4.conf.all.rp_filter = 1' | sudo tee /usr/lib/sysctl.d/99-rpfilter-1.conf
sudo sysctl net.ipv4.conf.all.rp_filter=1

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
