## selfhosted-services
The services that will be running on hubbe.club
In kubernetes, once I'm done porting and testing

## Setup
- Set up control-plane single-node "cluster" with `kubeadm-init.sh` script
    - This also sets up `Calico` for pod networking
- NFS shares for `service-nfs-pv.yaml` and `array-nfs-pv.yaml` need to be created
    - Must be accessible from the IPs nodes in the k8s cluster
    - Unclear how to do permissions properly
        - Should probably use `all_squash` on NFS server to squash all access to a known UID/GID pair
        - Containers then need to run as this UID to not break things when trying to `chown`
        - Might also work by just setting the proper `runAsUser` for every app?
- Services deployed with `kubectl apply -f <file_name>`
    - Note that `service-nfs-pv.yaml` and `array-nfs-pv.yaml` need to be deployed first
    - Beyond that, files in `apps` shouldn't be dependant on each other, beyond maybe some stuff needing `mariadb.yaml`
