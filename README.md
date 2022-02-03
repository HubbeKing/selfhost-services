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
1. Set up machines with basic apt-based OS
    - Should support Ubuntu Server 20.04 LTS and up, both arm64 and amd64, possibly also armhf
2. Set up control-plane loadbalancer static pods
    - See `control-plane-ha` folder for details
3. Adjust settings in `init-scripts/INSTALL_SETTINGS`
    - The other scripts pull variables from this file:
        - `KUBE_VERSION` sets the kubernetes version for the cluster
        - `POD_NETWORK_CIDR` sets the pod networking subnet, this should be set to avoid conflicts with existing networking
        - `K8S_SERVICE_CIDR` sets the service subnet, this should also avoid conflicting
        - `CONTROL_PLANE_ENDPOINT` sets the kube-apiserver loadbalancer endpoint, which allows for stacked HA setups
            - This causes init and join-controlplane scripts to deploy kube-vip as a static pod
                - see https://kube-vip.io/install_static
            - See https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
            - See https://github.com/kubernetes/kubeadm/blob/master/docs/ha-considerations.md
4. (optional) Adjust kubeadm configuration in `init-scripts/kubeadm-configs`
    - `single.yaml` is used if CONTROL_PLANE_ENDPOINT is not set
    - `stacked-ha.yaml` is used if CONTROL_PLANE_ENDPOINT is set
    - This file is needed in order to set the cgroupDriver for the kubelet on kubeadm init
    - For info on what the configurations in this file control, see:
        - https://godoc.org/k8s.io/kubelet/config/v1beta1#KubeletConfiguration
        - https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2#InitConfiguration
        - https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2#ClusterConfiguration
5. Set up the first node of the control-plane with `init-scripts/kubeadm-init.sh`
    - Required packages are installed - `containerd.io`, `kubeadm`, `kubelet`, and `kubectl`
    - `kube-router` is set up as CNI provider, with all features enabled
        - see https://github.com/cloudnativelabs/kube-router/blob/master/docs/kubeadm.md
        - note: kube-proxy is still used as service proxy, for kubeadm upgrade compatibility
    - Kernel source address verification is enabled by the `init-scripts/install-prereqs.sh` script
    - Note that the master node is not un-tainted, and thus no user pods are scheduled on master by default
6. (optional) Add additional control-plane nodes with `init-scripts/kubeadm-join-controlplane.sh <node_user>@<node_address>`
    - `<node_user>` must be able to SSH to the node, and have `sudo` access
    - Same inital setup is performed as on first node
    - Nodes are then joined as control-plane nodes using `kubeadm token create --print-join-command` and `kubeadm join`
7. Add in worker nodes by running `init-scripts/kubeadm-join-worker.sh <node_user>@<node_address>`
    - `<node_user>` must be able to SSH to the node, and have `sudo` access
    - Same initial setup is performed as on first node
    - Nodes are then joined as worker nodes using `kubeadm token create --print-join-command` and `kubeadm join`

### Storage setup
- NFS shares for `volumes/nfs-volumes/` PVCs need to be created
    - Must be accessible from the IPs of the nodes in the k8s cluster
- Longhorn needs no additional setup - simply deploy `volumes/longhorn` with `kubectl apply -f volumes/longhorn`
    - The storageclass settings can be tweaked if needed for volume HA stuff - see `volumes/longhorn/storageclass.yaml`
- At this stage, restore volumes from Longhorn backups using the Longhorn UI.
    - Make sure to also create PVs/PVCs via the Longhorn UI.
- Longhorn handles backups - see Longhorn UI and/or default settings in `volumes/longhorn/deployment.yaml`

### Ingress setup
- Set up `cert-manager` for automated cert renew
    - Run `kubectl apply -f core/cert-manager.yml`
    - Check `core/cert-issuer/*.yaml.example` files
        - Alternatively, run `sops --decrypt --in-place` on existing files
    - Run `kubectl apply -f core/cert-issuer`
- Deploy ingress-nginx for reverse proxying to deployed pods
    - Run `kubectl apply -f nginx/`
    - Current configuration assumes a single wildcard cert, `ingress-nginx/tls` for all sites
    - Issued by LetsEncrypt, solved by CloudFlare DNS verification
    - See `nginx/certificate.yaml` for certificate request fulfilled by `cert-manager`

### Apps setup
- Some apps need GPU acceleration (jellyfin)
    - See https://github.com/intel/intel-device-plugins-for-kubernetes/tree/master/cmd/gpu_plugin
    - See https://github.com/RadeonOpenCompute/k8s-device-plugin
    - Run `kubectl apply -f core/intel-gpu-plugin.yaml -f core/amd-gpu-plugin.yaml`
- Check NFS server IPs and share paths in `volumes/nfs-volumes` directory
    - Deploy volumes (PV/PVC) with `kubectl apply -f volumes/nfs-volumes`
- Create configs from `*.yaml.example` files
    - Alternatively, run `sops --decrypt --in-place` on existing files
- Set PUID, PGID, and TZ variables in `apps/linuxserver-envs.yaml`
- Deploy apps
    - All apps can be deployed simply with `kubectl apply -R -f apps/` once SOPS decryption is done
    - If deploying single apps, remember to also deploy related configs
        - Most things need the `apps/linuxserver-envs.yaml` ConfigMap

### Updating kustomize-based manifests
- `kubectl kustomize <URL> > manifest.yaml`
    - example, node-feature-discovery
    - `kubectl kustomize https://github.com/kubernetes-sigs/node-feature-discovery/deployment/overlays/default?ref=$v0.10.0 > nfd.yaml`
