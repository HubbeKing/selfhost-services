## selfhosted-services
The services that will be running on hubbe.club
In kubernetes, once I'm done porting and testing

## Setup
- TBD
- NFS shares for `service-nfs-pv` and `array-nfs-pv` need to be created
    - Must be accessible from the IPs that k8s decides to use?
- Services deployed with `kubectl apply -f <file_name>`
    - Note that `service-nfs-pv` and `array-nfs-pv` need to be deployed first
    - Then whatever secrets I need to have
    - Then deployments in whichever order
