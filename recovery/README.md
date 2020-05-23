## Recovery instructions

These manifests can be used to recover PVCs and their data from stash backups.

### Usage
- Check volumeClaimTemplates in restoresessions
    - Currently assumes no PVCs exist, if needed adjust `metadata.name` for templates
    - Currently set to StorageClass `longhorn`
- Run `kubectl create -f repositories`
- Run `kubectl create -f restoresessions`
