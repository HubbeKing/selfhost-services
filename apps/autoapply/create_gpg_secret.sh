#!/bin/bash
if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: create_gpg_secret.sh <path> <passphrase> <fingerprint> - Create a GPG secret for autoapply using kubectl"
    exit 1
fi

kubectl create secret generic gpg-secrets \
--from-file=GPG_KEY=$1 \
--from-literal=GPG_PASSPHRASE=$2 \
--from-literal=GPG_FINGERPRINT=$3
