## selfhosted-services
The services that will be running on hubbe.club
In kubernetes, once I'm done porting and testing

## Setup
- Set up control-plane single-node "cluster" with `kubeadm-init.sh` script
    - This also sets up `Calico` for pod networking
- NFS shares for things in `volumes` dir need to be created
    - Sadly, it seems one PV/PVC pair can't be mounted into one pod multiple times
        - Ideally, I'd want one PV/PVC pair that just says 192.168.1.213:/mnt/hubbe/array
        - And then mount that multiple times in one pod with different subPaths
            - Tried that, k8s hung when creating, waiting for things to mount
    - Must be accessible from the IPs nodes in the k8s cluster
    - Somewhat unsure how to do permissions properly? This works, though:
        - Should use `all_squash` on NFS server to squash all access to a known UID/GID pair
        - Containers may also need to runAsUser with this UID to not break things when trying to `chown`
- Create valid secrets from `*-secret.yaml.example` files in `apps` dir
- Services deployed with `kubectl apply -f <file_name>`
    - Note that `volumes` dir should be deployed first with `kubectl apply -f volumes/`
    - After that, `apps` can be deployed using `kubectl apply -f apps/`
        - If not all apps are needed, remember to deploy secrets along with the apps that need them
