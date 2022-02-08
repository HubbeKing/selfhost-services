# kube-prometheus based monitoring stack

see also https://github.com/prometheus-operator/kube-prometheus

## Creating initial manifests
- Install required packages:
    - `go-jsonnet`
    - `gojsontoyaml-git`
    - `jsonnet-bundler-bin`
- Run `jb init`
- Install kube-prometheus vendor files:
    - Run `jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@release-0.10`
- Build manifests with `./build.sh`
- Apply manifests with `./apply.sh`

## Updating manifests
- Update jsonnet-bundler (jb)
- Run `jb update`
- Build new manifests with `./build.sh`
- Apply manifests with `./apply.sh`

## Adding grafana dashboards
- Add json file to `dashboards` dir
- Add to `grafana.dashboards` key in `monitoring-stack.jsonnet` with `import` function
