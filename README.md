## selfhosted-services
Services running on hubbe.club, in local k8s cluster

### SOPS setup for config/secret .yaml decryption
- Install sops
    - See https://github.com/mozilla/sops
- Get PGP key from backup storage
    - Import using `gpg --import`
    - Set `SOPS_PGP_FP` env var to key fingerprint

### k8s Cluster Setup
- Install `kubeadm`, `kubectl`, and `kubelet`
- Set up control-plane single-node "cluster" with `kubeadm-init.sh` script
    - Note that this script is systemd-specific
    - This also sets up `Flannel` for pod networking
    - Default pod CIDR is 10.244.0.0/16, adjust as needed - make sure to also edit `core/kube-flannel.yaml`
    - This also sets up docker with the recommended configuration for kubernetes
    - This also enables kernel source address verification
    - Note that this does not un-taint the master node, and thus no user pods are scheduled on master by default

### Storage setup
- NFS shares for things in `volumes` dir need to be created
    - Must be accessible from the IPs of the nodes in the k8s cluster
    - NFS export for `service-data` should use `no_root_squash`, as some apps run as root and may fail if NFS doesn't give files the expected owner
    - NFS is a bit slow, though. Might be better to do some ZFS zvol + iscsi thing.

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
- Set PUID, PGID, and TZ variables in `apps/0-linuxserver-envs.yaml`
- Deploy apps
    - All apps can be deployed simply with `kubectl apply -R -f apps/`
    - If deploying single apps, remember to also deploy related configs
        - Most things need the `apps/0-linuxserver-envs.yaml` ConfigMap

### Autoapply setup
Autoapply automatically applies resources defined in the repo onto the cluster every 5m
- Run `sops --decrypt apps/autoapply/secret.yaml | kubectl apply -f -`
- Run `kubectl apply -f apps/autoapply/deployment.yaml`
