#!/bin/bash

CERT_PATH=$1
KEY_PATH=$2

kubectl create secret --namespace=nginx-ingress tls --cert="${CERT_PATH}" --key="${KEY_PATH}" --dry-run --output=yaml --save-config > nginx/certificate.yaml
