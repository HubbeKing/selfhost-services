# Control Plane load-balancer as static pods
https://github.com/kubernetes/kubeadm/blob/master/docs/ha-considerations.md#option-2-run-the-services-as-static-pods

1. Set control plane node IPs in haproxy backend config in `haproxy.cfg`
2. Set keepalived virtual IP in `keepalived.conf`,`check_apiserver.sh`, and the `haproxy.cfg` frontend section
3. Set keepalived state to `MASTER` or `BACKUP` in `keepalived.conf` - there should be one MASTER
    - Typically, one would set state to `MASTER` for the first control-plane node one spins up and `BACKUP` for any subsequent ones
    - Remember to also set `keepalived.conf` priority to higher for `MASTER` node
4. Copy files onto control plane nodes
    - `keepalived.conf` and `check_apiserver.sh` go in `/etc/keepalived/` (create folder if necessary)
    - `haproxy.cfg` goes in `/etc/haproxy/` (create folder if necessary)
5. Add manifests to control plane nodes:
    - Copy `keepalived.yaml` and `haproxy.yaml` to `/etc/kubernetes/manifests/`
6. Create DNS A record for keepalived virtual IP
7. Bootstrap cluster as normal, follwing stacked HA control plane section of `kubeadm` docs
    - Remember to specify port of control plane endpoint, as HAProxy pods will be listening on 8443 to forward to 6443
    - i.e. `kubeadm init --control-plane-endpoint apiserver.lan:8443`
