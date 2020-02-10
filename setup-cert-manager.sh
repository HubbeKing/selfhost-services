#!/bin/bash

kubectl create namespace cert-manager

# https://cert-manager.io/docs/installation/upgrading/#upgrading-using-static-manifests
cd core
wget https://github.com/jetstack/cert-manager/releases/download/v0.13.0/cert-manager.yaml
kubectl apply -f cert-manager.yaml
kubectl apply -f cert-issuer/
