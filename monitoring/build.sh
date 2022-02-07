#!/bin/bash

set -e

# Make sure to start with a clean 'manifests' dir
rm -rf manifests
mkdir -p manifests/setup

# decrypt alertmanager config addon
sops --decrypt addons/alertmanager.jsonnet.enc > addons/alertmanager.jsonnet

# generate manifests and convert to yaml for readability
jsonnet -J vendor -m manifests "main.jsonnet" | xargs -I{} bash -c 'yj --yaml {} > {}.yaml' -- {}

# Make sure to remove json files
find manifests -type f ! -name '*.yaml' -delete

# remove decrypted alertmanager config addon
rm addons/alertmanager.jsonnet
