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

- Create nginx ingress controller TLS secret for wildcard cert:
    - `./create-nginx-secret.sh path/to/cert.pem path/to/key.pem`
- Deploy nginx ingress controller with `kubectl apply -f nginx/`
    - To update cert on-the-fly, update the secret file with the above command
    - And then apply with `kubectl apply -f nginx/certificate.yaml`

- Deploy volumes (PV/PVC) with `kubectl apply -f volumes/`
- Deploy apps
    - All apps can be deployed simply with `kubectl apply -f apps/`
    - If deploying single apps, remember to also deploy related secrets
