#!/bin/bash

# ensure kubelet service is enabled
sudo systemctl enable kubelet.service

# ensure docker is using recommended settings
sudo cp docker-daemon.json /etc/docker/daemon.json
sudo mkdir -p /etc/systemd/system/docker.service.d

# restart docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# ensure kernel source address verification is enabled
# this is likely Arch Linux specific?
echo 'net.ipv4.conf.all.rp_filter = 1' | sudo tee /usr/lib/sysctl.d/99-rpfilter-1.conf
sudo sysctl net.ipv4.conf.all.rp_filter=1

echo "Ready for join command."
echo "To get join command from a control-plane node, run 'kubeadm token create --print-join-command'"
