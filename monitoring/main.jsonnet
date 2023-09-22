local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  (import 'kube-prometheus/addons/all-namespaces.libsonnet') +
  // add ingress definitions
  (import 'addons/ingress.jsonnet') +
  // add alertmanager config
  (import 'addons/alertmanager.jsonnet') +
  // up resource specs for things set needlessly low
  (import 'addons/resources.jsonnet') +
  // disable networkPolicies
  (import 'kube-prometheus/addons/networkpolicies-disabled.libsonnet') +
  // add ingress-nginx monitoring
  (import 'addons/ingress-nginx.jsonnet') +
  // add APC UPS monitoring
  (import 'addons/apcupsd.jsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring',
        platform: "kubeadm",
      },
      kubernetesControlPlane+: {
        // monitor kube-proxy
        kubeProxy:: true,  // needed patching of kube-proxy daemonset to add metrics port
        // increase CPU throttling alert threshold from 25%
        mixin+: {
          _config+: {
            cpuThrottlingPercent: 60,
          },
        },
      },
      // monitor etcd
      etcd+: {
        ips: ["192.168.1.131", "192.168.1.132", "192.168.1.133"],
        clientCA: importstr "addons/etcd/ca.crt",
        clientKey: importstr "addons/etcd/peer.key",
        clientCert: importstr "addons/etcd/peer.crt",
        insecureSkipVerify: true,
      },
      // we monitor all namespaces through an addon rather than defining them all here
      prometheus+: {
        namespaces+: [],
      },
      grafana+: {
        // disable HTML sanitize for blocky dashboard buttons
        config+: {
          sections+: {
            panels+:{
              disable_sanitize_html: true,
            },
          },
        },
        // add grafana dashboards
        dashboards+:: {
          'etcd.json': (import 'dashboards/etcd.json'),
          'longhorn.json': (import 'dashboards/longhorn.json'),
          'nginx.json': (import 'dashboards/nginx.json'),
        },
        // up resource spec
        resources: {
          requests: { cpu: '50m', memory: '256Mi' },
          limits: { cpu: '250m', memory: '512Mi' },
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
{ [name + '-ingress']: kp.ingress[name] for name in std.objectFields(kp.ingress) } +
{ [name + '-service']: kp.service[name] for name in std.objectFields(kp.service) } +
{ [name + '-endpoints']: kp.endpoints[name] for name in std.objectFields(kp.endpoints) } +
{ [name + '-serviceMonitor']: kp.serviceMonitor[name] for name in std.objectFields(kp.serviceMonitor) } +
{ [name + '-prometheusRule']: kp.prometheusRule[name] for name in std.objectFields(kp.prometheusRule) }
