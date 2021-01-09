#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: kubeadm-join-worker.sh user@host - Joins the specified host as a worker to the current k8s cluster using kubeadm join."
    echo "User must have ssh login and sudo access on host."
    echo "Script should be run from an existing control-plane kubeadm node."
    exit 1
fi

HOST="$1"
echo "Will join $HOST to the current k8s cluster."
echo "Generating join token..."
JOIN_CMD=$(kubeadm token create --print-join-command)

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

echo "Joining target host to k8s cluster using kubeadm join..."
ssh -t $HOST sudo $JOIN_CMD
