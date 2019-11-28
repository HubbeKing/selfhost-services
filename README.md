## selfhosted-services
The services that will be running on hubbe.club
In kubernetes, once I'm done porting and testing

## Setup
- TBD
- NFS shares for `service-nfs-pv` and `array-nfs-pv` need to be created
    - Must be accessible from the IPs nodes in the k8s cluster
    - Unclear how to do permissions properly
        - Should probably use `all_squash` on NFS server to squash all access to a known UID/GID pair
        - Containers then need to run as this UID to not break things when trying to `chown`
        - Might also work by just setting the proper `runAsUser` for every app?
- Services deployed with `kubectl apply -f <file_name>`
    - Note that `service-nfs-pv` and `array-nfs-pv` need to be deployed first
    - Then whatever secrets I need to have
    - Then deployments in whichever order
