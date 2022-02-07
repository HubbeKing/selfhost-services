#!/bin/bash

set -e

if [[ ! -d manifests ]]; then
  bash build.sh
fi

kubectl apply --server-side -f manifests/setup
kubectl apply -f manifests
