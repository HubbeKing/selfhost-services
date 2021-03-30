#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: kubeadm-join-controlplane.sh user@host - Joins the specified host to the control plane of this k8s cluster using kubeadm join."
    echo "User must have ssh login and sudo access on host."
    echo "Script should be run from an existing control-plane kubeadm node."
    exit 1
fi

HOST="$1"
echo "Will join $HOST to the current k8s control plane."

# ensure required packages are installed and using proper settings
echo "Copying install script to target host..."
scp INSTALL_SETTINGS $HOST:/tmp/
scp install-prereqs.sh $HOST:/tmp/
ssh -t $HOST "sed -i 's|INSTALL_SETTINGS|/tmp/INSTALL_SETTINGS|' /tmp/install-prereqs.sh"
echo "Installing prereqs on target host..."
ssh -t $HOST /tmp/install-prereqs.sh

# ensure kubelet service is enabled
echo "Enabling kubelet systemd service on target host..."
ssh -t $HOST sudo systemctl enable kubelet.service

# generate certificate key and run upload-certs phase of init using this key
echo "Generating certificate key and uploading certificates..."
CERT_KEY=$(kubeadm certs certificate-key)
sudo kubeadm init phase upload-certs --upload-certs --certificate-key $CERT_KEY

# generate a token for joining the cluster
echo "Generating join token..."
JOIN_CMD=$(kubeadm token create --print-join-command)

# use token and cert key to join node as a control-plane node
echo "Joining target host to k8s control plane using kubeadm join..."
ssh -t $HOST sudo $JOIN_CMD --control-plane --certificate-key $CERT_KEY
