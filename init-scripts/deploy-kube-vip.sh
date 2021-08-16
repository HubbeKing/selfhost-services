#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: deploy-kube-vip.sh user@host [user@host] [user@host]... - Deploy kube-vip to specified hosts as a static pod using kube-vip.template"
    echo "User(s) must have ssh login and sudo access on host(s)."
    exit 1
fi

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
