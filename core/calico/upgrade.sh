#!/bin/bash
# https://docs.tigera.io/calico/latest/operations/upgrading/kubernetes-upgrade#upgrading-an-installation-that-uses-the-operator
kubectl apply --server-side --force-conflicts -f 1-v1_crd_projectcalico_org.yaml
kubectl apply --server-side --force-conflicts -f 2-tigera-operator.yaml
