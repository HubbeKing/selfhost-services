#! /bin/bash

# helper script to run etcdctl commands

ETCDCTL_API=3 sudo etcdctl \
--endpoints 127.0.0.1:2379 \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key \
"$@"
