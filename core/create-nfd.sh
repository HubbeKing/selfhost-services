#!/bin/bash

if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: create-nfd.sh <version> - e.g. create-nfd.sh v0.10.1"
    exit 1
fi

VERSION=$1
kubectl kustomize https://github.com/kubernetes-sigs/node-feature-discovery/deployment/overlays/default?ref=$VERSION > nfd.yaml
