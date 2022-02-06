#!/bin/bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifest files.

set -e
set -x

# Make sure to start with a clean 'manifests' dir
rm -rf manifests
mkdir -p manifests/setup

# decrypt alertmanager config addon
sops --decrypt addons/alertmanager.jsonnet.enc > addons/alertmanager.jsonnet

# generate manifests and convert to yaml for readability
jsonnet -J vendor -m manifests "$1" | xargs -I{} bash -c 'yj --yaml {} > {}.yaml' -- {}

# Make sure to remove json files
find manifests -type f ! -name '*.yaml' -delete

# remove decrypted alertmanager config addon
rm addons/alertmanager.jsonnet

# encrypt etcd certs secret
sops --encrypt --in-place manifests/prometheus-secretEtcdCerts.yaml

# encrypt alertmanger config
sops --encrypt --in-place manifests/alertmanager-secret.yaml
