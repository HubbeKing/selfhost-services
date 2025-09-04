#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: kubeadm-join-worker.sh user@host [user@host] [user@host]... - Joins the specified host(s) as worker nodes to the current k8s cluster using kubeadm join."
    echo "User(s) must have ssh login and sudo access on host(s)."
    echo "Script should be run from an existing control-plane kubeadm node."
    exit 1
fi

# prepare host(s) for cluster join
for host in "$@"
do
    echo "Preparing $host for kubeadm join..."
    echo "Copying install script..."
    scp INSTALL_SETTINGS install-prereqs.sh crictl.yaml $host:/tmp/
    ssh -t $host "sed -i 's|INSTALL_SETTINGS|/tmp/INSTALL_SETTINGS|' /tmp/install-prereqs.sh"
    echo "Installing required packages..."
    ssh -t $host /tmp/install-prereqs.sh
    echo "Deploying crictl config..."
    ssh -t $host sudo cp /tmp/crictl.yaml /etc/crictl.yaml
    echo "Enabling kubelet systemd service..."
    ssh -t $host sudo systemctl enable kubelet.service
    echo "$host ready for kubeadm join."
done

echo "All nodes ready for join."

echo "Generating join token..."
JOIN_CMD=$(sudo kubeadm token create --print-join-command)

# actually join host(s) to cluster
for host in "$@"
do
    echo "Joining $host to k8s cluster using kubeadm join..."
    ssh -t $host sudo $JOIN_CMD
    kubectl label node ${host%%.*} kubernetes.io/role=worker
done
