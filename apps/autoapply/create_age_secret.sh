#!/bin/bash
if [ $# -eq 0 ]; then
    # no arguments provided
    echo "Usage: create_age_secret.sh <path_to_keys.txt> - Create an age secret for autoapply using kubectl"
    exit 1
fi

kubectl create secret generic age-keys \
--from-file=keys.txt=$1
