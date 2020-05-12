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
echo "Uploading CA certificates and calculating key SHA256 digest..."
kubeadm init phase upload-certs --upload-certs  # this also generates a new cert key, which we need, as keys expire after 2 hours
CA_CERT_KEY=$(openssl x509 -in /etc/kubernetes/pki/ca.crt -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256)

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

echo "Joining target host to k8s control plane using kubeadm join..."
ssh -t $HOST sudo $JOIN_CMD --control-plane --certificate-key $CA_CERT_KEY
