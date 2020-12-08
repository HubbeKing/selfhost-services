## selfhosted-services
Services running on hubbe.club, in local k8s cluster

### SOPS setup for config/secret .yaml decryption
- Install sops
    - See https://github.com/mozilla/sops
- Get PGP key from backup storage
    - Import using `gpg --import`
    - Set `SOPS_PGP_FP` env var to key fingerprint
- To decrypt all secrets in repo:
    - Run `find . -type f -name '*.yaml' -exec sops --decrypt --in-place '{}' \;`

### k8s Cluster Setup
1. Set up machines with basic apt-based OS
    - Should support Ubuntu 18.04 LTS and Ubuntu 20.04 LTS, both amd64 and arm64
    - Should support RPi HypriotOS for armhf support
2. Adjust kubeadm configuration in `init-scripts/kubeadm-config.yaml`
    - This file is needed in order to set the cgroupDriver for the kubelet on kubeadm init
    - The main settings of note:
        - `ClusterConfiguration.kubernetesVersion` - should match desired version and installed kubelet version
        - `ClusterConfiguration.networking.podSubnet` - CIDR for pods in the cluster, should not already be in use in the network
    - For info on what the configurations in this file control, see:
        - https://godoc.org/k8s.io/kubelet/config/v1beta1#KubeletConfiguration
        - https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2#InitConfiguration
        - https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2#ClusterConfiguration
3. Set up single-node control-plane with `init-scripts/kubeadm-init.sh`
    - TODO: add args for creating stacked-etcd HA control plane
    - Required packages are installed - `cri-o`, `cri-o-runc`, `kubeadm`, `kubelet`, and `kubectl`
        - NOTE: please see `init-scripts/install-prereqs.sh` for cri-o version/os settings
        - NOTE: please see `init-scripts/install-prereqs.sh` for kubeadm/kubelete/kubectl version settings
        - NOTE: please see `init-scripts/kubeadm-config.yaml` for kubeadm configuration
        - NOTE: cri-o and kubernetes versions MUST match across the two files for cluster initialization to work
    - `Project Calico` is set up in the cluster for pod networking - see `core/calico.yml`
        - Note: Calico auto-detects the podSubnet setting from kubeadm, there should be no need to adjust it
        - NOTE: recent versions of Calico auto-detect network MTU, there should be no need to adjust it manually.
    - Kernel source address verification is enabled by the `init-scripts/install-prereqs.sh` script
    - Note that the master node is not un-tainted, and thus no user pods are scheduled on master by default
4. Add in worker nodes by running `init-scripts/kubeadm-join-worker.sh <node_user>@<node_address>`
    - `<node_user>` must be able to SSH to the node, and have `sudo` access
    - Required packages are installed - `docker`, `kubeadm`, `kubelet`, and `kubectl`
    - Docker is configured with the recommended daemon settings for kubernetes
    - Kernel source address verification is also enabled
    - Nodes are then joined as workers using `kubeadm token create --print-join-command` and `kubeadm join`

### Storage setup
- NFS share for `volumes/array-nfs-pv.yaml` needs to be created
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
- Some apps need iGPU acceleration (jellyfin)
    - See https://github.com/intel/intel-device-plugins-for-kubernetes/tree/master/cmd/gpu_plugin
    - Run `kubectl apply -f core/gpu-plugin.yaml`
- Check NFS server IPs and share paths in `volumes` directory
    - Deploy volumes (PV/PVC) with `kubectl apply -f volumes/`
- Create configs from `*.yaml.example` files
    - Alternatively, run `sops --decrypt --in-place` on existing files
- Optional:
    - Set new MYSQL_PASSWORD environment variables for `nextcloud` and `freshrss`
- Set PUID, PGID, and TZ variables in `apps/linuxserver-envs.yaml`
- Deploy apps
    - All apps can be deployed simply with `kubectl apply -R -f apps/`
    - If deploying single apps, remember to also deploy related configs
        - Most things need the `apps/linuxserver-envs.yaml` ConfigMap

### Autoapply setup
Autoapply automatically applies resources defined in the repo onto the cluster every 5m
- Run `sops --decrypt -in-place apps/autoapply/secret.yaml`
- Run `kubectl apply -f apps/autoapply/`
