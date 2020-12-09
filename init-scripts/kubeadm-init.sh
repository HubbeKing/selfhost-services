#!/bin/bash
set -e

# install prereqs
./install-prereqs.sh

# ensure kubelet is running
sudo systemctl enable kubelet.service

# get required kubeadm config vars from INSTALL_SETTINGS
source INSTALL_SETTINGS

if [ -n "${CONTROL_PLANE_ENDPOINT}" ]; then
    # Initialize single control-plane cluster on this machine
    KUBE_VERSION=${KUBE_VERSION} POD_NETWORK_CIDR=${POD_NETWORK_CIDR} K8S_SERVICE_CIDR=${K8S_SERVICE_CIDR} envsubst < kubeadm-configs/single.yaml | sudo kubeadm init --config -
else
    # Initialize stacked HA control-plane cluster on this machine
    KUBE_VERSION=${KUBE_VERSION} POD_NETWORK_CIDR=${POD_NETWORK_CIDR} K8S_SERVICE_CIDR=${K8S_SERVICE_CIDR} CONTROL_PLANE_ENDPOINT=${CONTROL_PLANE_ENDPOINT} envsubst < kubeadm-configs/stacked-ha.yaml | sudo kubeadm init --upload-certs --config -
fi

# set up kubectl for non-sudo use by copying config into home
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# apply Project Calico pod networking manifest
kubectl apply -f ../core/calico.yaml
