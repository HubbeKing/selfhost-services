#!/bin/bash

kubectl apply -f manifests/setup
kubectl apply -f manifests

sops --decrypt manifests/prometheus-secretEtcdCerts.yaml | kubectl apply -f -
sops --decrypt manifests/alertmanager-secret.yaml | kubectl apply -f -
