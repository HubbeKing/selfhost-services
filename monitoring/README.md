# kube-prometheus based monitoring stack

see also https://github.com/prometheus-operator/kube-prometheus

## Creating initial manifests
- Install jsonnet-bundler (jb)
- Run `jb init`
- Install kube-prometheus vendor files:
    - Run `jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@release-0.7`
- Build manifests with `./build.sh monitoring-stack.jsonnet`
- Commit/Push/Apply manifests:
    - Run `kubectl apply -f manifests/setup`
    - Wait for CRDs to become available
    - Run `kubectl apply -f manifests`

## Updating manifests
- Update jsonnet-bundler (jb)
- Run `jb update`
- Build new manifests with `./build.sh monitoring-stack.jsonnet`
- Commit/Push/Apply manifests:
    - Run `kubectl apply -R -f manifests`
