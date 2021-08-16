#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: kubeadm-join-controlplane.sh user@host [user@host] [user@host]... - Joins the specified host(s) to the control plane of this k8s cluster using kubeadm join."
    echo "User(s) must have ssh login and sudo access on host(s)."
    echo "Script should be run from an existing control-plane kubeadm node."
    exit 1
fi

for host in "$@"
do
    echo "Preparing $host for kubeadm join..."
    # ensure required packages are installed and using proper settings
    echo "Copying install script..."
    scp INSTALL_SETTINGS $host:/tmp/
    scp containerd_config.toml $host:/tmp/
    scp install-prereqs.sh $host:/tmp/
    ssh -t $host "sed -i 's|INSTALL_SETTINGS|/tmp/INSTALL_SETTINGS|' /tmp/install-prereqs.sh"
    ssh -t $host "sed -i 's|containerd_config.toml|/tmp/containerd_config.toml|' /tmp/install-prereqs.sh"
    echo "Installing required packages..."
    ssh -t $host /tmp/install-prereqs.sh
    # ensure kubelet service is enabled
    echo "Enabling kubelet systemd service..."
    ssh -t $host sudo systemctl enable kubelet.service
    echo "$host ready for kubeadm join."
done

echo "All nodes ready for join."

# generate certificate key and run upload-certs phase of init using this key
echo "Generating certificate key and uploading certificates..."
CERT_KEY=$(kubeadm certs certificate-key)
sudo kubeadm init phase upload-certs --upload-certs --certificate-key $CERT_KEY

# generate a token for joining the cluster
echo "Generating join token..."
JOIN_CMD=$(kubeadm token create --print-join-command)

for host in "$@"
do
    # use token and cert key to join node as a control-plane node
    echo "Joining $host to k8s control plane using kubeadm join..."
    ssh -t $host sudo $JOIN_CMD --control-plane --certificate-key $CERT_KEY
done

# deploy kube-vip.yaml to node(s)
source INSTALL_SETTINGS
VIP="${CONTROL_PLANE_ENDPOINT%%:*}"
for host in "$@"
do
    INTERFACE=$(ssh $host ip addr show | awk '/inet.*brd/{print $NF; exit}')
    VIP=${VIP} INTERFACE=${INTERFACE} envsubst < kube-vip.template > kube-vip.yaml
    scp kube-vip.yaml $host:/tmp/
    ssh $host sudo mv /tmp/kube-vip.yaml /etc/kubernetes/manifests/
    rm kube-vip.yaml
done
