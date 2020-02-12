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
echo "Configuring docker on target host..."
scp docker-daemon.json $HOST:/tmp/daemon.json
ssh $HOST sudo cp /tmp/daemon.json /etc/docker/daemon.json
ssh $HOST sudo mkdir -p /etc/systemd/system/docker.service.d

# restart docker
echo "Restarting docker on target host..."
ssh $HOST sudo systemctl daemon-reload
ssh $HOST sudo systemctl restart docker

# ensure kernel source address verification is enabled
echo "Enabling kernel source address verification on target host..."
ssh $HOST bash -c "echo 'net.ipv4.conf.all.rp_filter = 1' | sudo tee /usr/lib/sysctl.d/99-rpfilter-1.conf"
ssh $HOST sudo sysctl net.ipv4.conf.all.rp_filter=1

echo "Joining target host to k8s cluster using kubeadm join..."
ssh $HOST sudo $JOIN_CMD
