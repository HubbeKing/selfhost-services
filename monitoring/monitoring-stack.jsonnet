local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  (import 'kube-prometheus/addons/strip-limits.libsonnet') +
  (import 'kube-prometheus/addons/all-namespaces.libsonnet') +
  // add ingress definitions
  (import 'addons/ingress.jsonnet') +
  // add alertmanager config
  (import 'addons/alertmanager.jsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring',
      },
      // add kubeadm mixin
      kubePrometheus+: {
        platform: "kubeadm"
      },
      // monitor etcd
      etcd+: {
        ips: ["192.168.1.122", "192.168.1.123", "192.168.1.101"],
        clientCA: importstr "addons/etcd/ca.crt",
        clientKey: importstr "addons/etcd/peer.key",
        clientCert: importstr "addons/etcd/peer.crt",
        insecureSkipVerify: true,
      },
      // we monitor all namespaces through an addon rather than defining them all here
      prometheus+: {
        namespaces+: [],
      },
      // add grafana dashboards
      grafana+: {
        dashboards+:: {
          'blocky.json': (import 'dashboards/blocky.json'),
          'etcd.json': (import 'dashboards/etcd.json'),
          'longhorn.json': (import 'dashboards/longhorn.json'),
          'nginx.json': (import 'dashboards/nginx.json'),
          'zfs.json': (import 'dashboards/zfs.json'),
        },
      },
    },
    // set up prometheus retention
    prometheus+:: {
      prometheus+: {
        spec+: {
          retention: "14d",
          storage: {
            volumeClaimTemplate: {
              apiVersion: "v1",
              kind: "PersistentVolumeClaim",
              spec: {
                accessModes: ["ReadWriteOnce"],
                resources: { requests: { storage: "20Gi" } },
                storageClassName: "longhorn",
              },
            },
          },
        },
      },
    },
  };

{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
//{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ [name + '-ingress']: kp.ingress[name] for name in std.objectFields(kp.ingress) }
