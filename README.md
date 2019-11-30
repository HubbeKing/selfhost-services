## selfhosted-services
The services that will be running on hubbe.club
In kubernetes, once I'm done porting and testing

## Setup
- Set up control-plane single-node "cluster" with `kubeadm-init.sh` script
    - This also sets up `Calico` for pod networking
- NFS shares for `service-nfs-pv.yaml` and `array-nfs-pv.yaml` need to be created
    - Must be accessible from the IPs nodes in the k8s cluster
    - Unclear how to do permissions properly
        - Should use `all_squash` on NFS server to squash all access to a known UID/GID pair
        - Containers may also need to runAsUser with this UID to not break things when trying to `chown`
- Create valid secrets from `*-secret.yaml.example` files in `apps` dir
- Services deployed with `kubectl apply -f <file_name>`
    - Note that `service-nfs-pv.yaml` and `array-nfs-pv.yaml` need to be deployed first
    - After that, `apps` can be deployed using `kubectl apply -f apps/`
        - If not all apps are needed, remember to deploy secrets along with the apps that need them
