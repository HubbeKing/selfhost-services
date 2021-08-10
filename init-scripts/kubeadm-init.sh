#!/bin/bash
set -e

# install prereqs
./install-prereqs.sh

# ensure kubelet is running
sudo systemctl enable kubelet.service

# get required kubeadm config vars from INSTALL_SETTINGS
source INSTALL_SETTINGS

# check if a CONTROL_PLANE_ENDPOINT has been specified
if [ -n "${CONTROL_PLANE_ENDPOINT}" ]; then
    # generate and place kube-vip.yaml manifest for the current node
    sudo mkdir -p /etc/kubernetes/manifests
    # assume CONTROL_PLANE_ENDPOINT is using an IP:PORT syntax
    VIP="${CONTROL_PLANE_ENDPOINT%%:*}"
    # assume first active interface is the one we want to use
    INTERFACE=$(ip addr show | awk '/inet.*brd/{print $NF; exit}')
    # deploy kube-vip.yaml static pod manifest
    envsubst < kube-vip.template | sudo tee /etc/kubernetes/kube-vip.yaml
    # Initialize stacked HA control-plane cluster on this machine
    KUBE_VERSION=${KUBE_VERSION} POD_NETWORK_CIDR=${POD_NETWORK_CIDR} K8S_SERVICE_CIDR=${K8S_SERVICE_CIDR} CONTROL_PLANE_ENDPOINT=${CONTROL_PLANE_ENDPOINT} envsubst < kubeadm-configs/stacked-ha.yaml > temp.yaml
    sudo kubeadm init --upload-certs --config temp.yaml
else
    # Initialize single control-plane cluster on this machine otherwise
    KUBE_VERSION=${KUBE_VERSION} POD_NETWORK_CIDR=${POD_NETWORK_CIDR} K8S_SERVICE_CIDR=${K8S_SERVICE_CIDR} envsubst < kubeadm-configs/single.yaml > temp.yaml
    sudo kubeadm init --config temp.yaml
fi

# set up kubectl for non-sudo use by copying config into home
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# apply kube-router for CNI, with all features (service proxy, firewall, pod networking)
kubectl apply -f ../core/kube-router.yaml

# remove kube-proxy, since kube-router does the things it does as well
kubectl -n kube-system delete daemonset kube-proxy

# clean up iptables configuration kube-proxy may have done
ctr run --privileged --net-host --mount="type=bind,src=/lib/modules,dst=/lib/modules" k8s.gcr.io/kube-proxy:v${KUBE_VERSION} kube-proxy --cleanup

# remove temporary kubeadm config file
rm temp.yaml
