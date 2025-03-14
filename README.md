## selfhosted-services
Services running on hubbe.club, in local k8s cluster

### SOPS setup for config/secret .yaml decryption
- Install sops
    - See https://github.com/mozilla/sops
- Get age keys.txt from backup storage
    - Set `SOPS_AGE_RECIPIENTS` env var to public key
- To decrypt all secrets in repo:
    - Run `find . -type f -name '*.yaml' -exec sops --decrypt --in-place '{}' \;`

### k8s Cluster Setup
1. Set up machines with latest version of Debian
2. Adjust settings in `init-scripts/INSTALL_SETTINGS`
    - The other scripts pull variables from this file:
        - `KUBE_VERSION` sets the kubernetes version for the cluster
        - `POD_NETWORK_CIDR` sets the pod networking subnet, this should be set to avoid conflicts with existing networking
        - `K8S_SERVICE_CIDR` sets the service subnet, this should also avoid conflicting
        - `CONTROL_PLANE_ENDPOINT` sets the kube-apiserver loadbalancer endpoint, which allows for stacked HA setups
            - This causes init and join-controlplane scripts to deploy kube-vip as a static pod
                - see https://kube-vip.io/docs/installation/static/ for details
            - See https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
            - See https://github.com/kubernetes/kubeadm/blob/master/docs/ha-considerations.md
3. (optional) Adjust kubeadm configuration in `init-scripts/kubeadm-configs`
    - `single.yaml` is used if CONTROL_PLANE_ENDPOINT is not set
    - `stacked-ha.yaml` is used if CONTROL_PLANE_ENDPOINT is set
    - This file is needed in order to set the cgroupDriver for the kubelet on kubeadm init
    - For info on what the configurations in this file control, see:
        - https://pkg.go.dev/k8s.io/kubelet/config/v1beta1?utm_source=godoc#KubeletConfiguration
        - https://pkg.go.dev/k8s.io/kube-proxy/config/v1alpha1#KubeProxyConfiguration
        - https://pkg.go.dev/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2?utm_source=godoc#InitConfiguration
        - https://pkg.go.dev/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2?utm_source=godoc#ClusterConfiguration
4. Set up the first node of the control-plane with `init-scripts/kubeadm-init.sh`
    - Required packages are installed - `containerd.io`, `kubeadm`, `kubelet`, and `kubectl`
    - Project Calico is installed as a CNI plugin, see `core/calico.yaml`
    - Kernel source address verification is enabled by the `init-scripts/install-prereqs.sh` script
    - Note that the control plane nodes are not un-tainted, and thus no user pods are scheduled on them by default
    - Note that control plane nodes also have the `node.kubernetes.io/exclude-from-external-load-balancers` label, which must be removed for MetalLB to work with user pods on them.
5. (optional) Add additional control-plane nodes with `init-scripts/kubeadm-join-controlplane.sh <node_user>@<node_address>`
    - `<node_user>` must be able to SSH to the node, and have `sudo` access
    - Same inital setup is performed as on first node
    - Nodes are then joined as control-plane nodes using `kubeadm token create --print-join-command` and `kubeadm join`
6. Add in worker nodes by running `init-scripts/kubeadm-join-worker.sh <node_user>@<node_address>`
    - `<node_user>` must be able to SSH to the node, and have `sudo` access
    - Same initial setup is performed as on first node
    - Nodes are then joined as worker nodes using `kubeadm token create --print-join-command` and `kubeadm join`

### Storage setup
- NFS shares for `volumes` PVCs need to be created
    - Must be accessible from the IPs of the nodes in the k8s cluster
    - Deploy volumes (PV/PVC) with `kubectl apply -f volumes`
- Longhorn needs no additional setup - simply deploy `operators/longhorn` with `kubectl apply -f operators/longhorn`
    - The storageclass settings can be tweaked if needed for volume HA stuff - see `operators/longhorn/storageclass.yaml`
- At this stage, restore volumes from Longhorn backups using the Longhorn UI.
    - Make sure to also create PVs/PVCs via the Longhorn UI.
- Longhorn handles backups - see Longhorn UI and/or default settings in `operators/longhorn/deployment.yaml`

### Ingress setup
- Set up `cert-manager` for automated cert renew
    - Run `kubectl apply -f core/cert-manager.yml`
    - Check `core/cert-issuer/*.yaml.example` files
        - Alternatively, run `sops --decrypt --in-place` on existing files
        - Run `kubectl apply -f core/cert-issuer`
- Deploy metalLB for nginx LoadBalancer service
    - `kubectl apply -f core/metallb && sops -d core/metallb/memberlist-secret.yaml | kubectl apply -f -`
- Deploy ingress-nginx for reverse proxying to deployed pods
    - Run `kubectl apply -f core/nginx/`
    - Current configuration assumes a single wildcard cert, `ingress-nginx/tls` for all sites
    - Issued by LetsEncrypt, solved by CloudFlare DNS verification
    - See `nginx/certificate.yaml` for certificate request fulfilled by `cert-manager`

### Apps setup
- Some apps use operators, install these from `operators` folder.
    - dragonfly-operator for DragonflyDB/Redis, Cloudnative-PG for postgres
- Some apps need GPU acceleration (jellyfin)
    - This uses `node-feature-discovery` to target the gpu plugin deployment
        - `kubectl apply -f core/nfd.yaml`
    - See https://github.com/intel/intel-device-plugins-for-kubernetes/tree/master/cmd/gpu_plugin
    - See `core/gpu-plugins`
- Create configs from `*.yaml.example` files
    - Alternatively, run `sops --decrypt --in-place` on existing files
- Set PUID, PGID, and TZ variables in `apps/0-linuxserver-envs.yaml`
- Deploy apps
    - All apps can be deployed simply with `kubectl apply -R -f apps/` once SOPS decryption is done
    - If deploying single apps, remember to also deploy related configs
        - Most things need the `apps/0-linuxserver-envs.yaml` ConfigMap

### Monitoring setup
- See `monitoring/README.md`
    - mainly `monitoring/build.sh` and `monitoring/apply.sh`
- After deployment of monitoring stack, deploy extra rules from `extras` folder
