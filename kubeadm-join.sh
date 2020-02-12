#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: kubeadm-join.sh user@host - Joins the specified host to this k8s cluster with kubeadm join. User must have ssh login and sudo access on host."
    exit 1
fi

HOST="$1"
echo "Will join $HOST to the current k8s cluster."
echo "Generating join token..."
JOIN_CMD=$(kubeadm token create --print-join-command)

# ensure required packages are installed and using proper settings
echo "Copying install scripts to target host..."
scp docker-daemon.json $HOST:/tmp/
scp install-prereqs.sh $HOST:/tmp/
echo "Installing prereqs on target host..."
ssh -t $HOST /tmp/install-prereqs.sh

# ensure kubelet service is enabled
echo "Enabling kubelet systemd service on target host..."
ssh -t $HOST sudo systemctl enable kubelet.service

echo "Joining target host to k8s cluster using kubeadm join..."
ssh -t $HOST sudo $JOIN_CMD
