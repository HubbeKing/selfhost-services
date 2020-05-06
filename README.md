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
- Set up machines with Ubuntu Server LTS 18.04
- Set up control-plane node with `kubeadm-init.sh` script (single node, not HA)
    - Required packages are installed - `docker`, `kubeadm`, `kubelet`, and `kubectl`
    - This also sets up `Flannel` for pod networking
    - Default pod CIDR is 10.244.0.0/16, adjust as needed - make sure to also edit `core/kube-flannel.yaml`
    - This also sets up docker with the recommended configuration for kubernetes
    - This also enables kernel source address verification
    - Note that this does not un-taint the master node, and thus no user pods are scheduled on master by default
- # TODO: add script toggles for stacked etcd HA control plane
- Add in worker nodes by running `kubeadm-join-worker.sh <node_user>@<node_address>`
    - `<node_user>` must be able to SSH to the node, and have `sudo` access
    - Required packages are installed - `docker`, `kubeadm`, `kubelet`, and `kubectl`
    - Nodes are added in as workers using `kubeadm token create --print-join-command` and `kubeadm join`
    - This sets up docker with the recommended configuration for kubernetes
    - This also enables kernel source address verification


### Storage setup
- NFS share for `volumes/array-pv.yaml` needs to be created
    - Must be accessible from the IPs of the nodes in the k8s cluster
- iSCSI server with targetd must be set up and configured - see `volumes/iscsi-provisioner`
- Longhorn needs no additional setup - see `volumes/longhorn`

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

