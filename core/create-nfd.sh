#!/bin/bash
kubectl kustomize https://github.com/kubernetes-sigs/node-feature-discovery/deployment/overlays/default?ref=v0.10.0 > nfd.yaml
