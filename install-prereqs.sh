#!/bin/bash
set -e

# check if docker appears to be installed
if ! [ -x "$(command -v docker)" ]; then
  echo "docker does not appear to be installed, installing..."
  # install prereqs to allow apt to use a repository over HTTPS
  sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      software-properties-common

  # add docker's official GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  # update
  sudo apt-get update

  # install latest version of docker
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# ensure docker daemon is enabled and running
sudo systemctl enable --now docker

# ensure docker is using recommended settings
sudo cp /tmp/docker-daemon.json /etc/docker/daemon.json
sudo mkdir -p /etc/systemd/system/docker.service.d

# restart docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# ensure kernel source address verification is enabled
echo 'net.ipv4.conf.all.rp_filter = 1' | sudo tee /etc/sysctl.d/99-rpfilter-1.conf
sudo sysctl net.ipv4.conf.all.rp_filter=1

# ensure iptables tooling does not use the nftables backend
# ensure legacy binaries are installed
sudo apt-get install -y iptables arptables ebtables

# switch to legacy versions for iptables
set +e  # ubuntu 18.04 LTS errors with "no alternatives for iptables", this can be safely ignored
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy

set -e
# install kubeadm, kubelet, and kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
