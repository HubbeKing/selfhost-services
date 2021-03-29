# Control Plane load-balancer as static pods
https://github.com/kubernetes/kubeadm/blob/master/docs/ha-considerations.md#kube-vip
https://kube-vip.io/hybrid/static/

1. Generate node-specific `kube-vip.yaml` file for each control-plane node
2. Copy to first control-plane node BEFORE bootstrap
3. Create DNS A record for keepalived virtual IP
4. Bootstrap cluster as normal, follwing stacked HA control plane section of `kubeadm` docs
    - Remember to specify port of control plane endpoint, as HAProxy pods will be listening on 8443 to forward to 6443
    - i.e. `kubeadm init --control-plane-endpoint apiserver.lan:6443`
5. Join remaining control-plane nodes WITHOUT copying `kube-vip.yaml` to them
6. Copy `kube-vip.yaml` files to remaining control-plane nodes
