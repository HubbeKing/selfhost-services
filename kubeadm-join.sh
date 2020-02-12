#!/bin/bash

if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: kubeadm-join.sh user@host - Joins the specified host to this k8s cluster with kubeadm join. User must have ssh login and sudo access on host."
    exit 1
fi

HOST="$1"

JOIN_CMD=$(kubeadm token create --print-join-command)

# ensure kubelet service is enabled
echo "Enabling kubelet systemd service on target host..."
ssh $HOST sudo systemctl enable kubelet.service

# ensure docker is using recommended settings
echo "Installing prereqs on target host..."
scp docker-daemon.json $HOST:/tmp/daemon.json
scp install-prereqs.sh $HOST:/tmp/install-prereqs.sh
ssh -t $HOST /tmp/install-prereqs.sh

echo "Joining target host to k8s cluster using kubeadm join..."
ssh $HOST sudo $JOIN_CMD
