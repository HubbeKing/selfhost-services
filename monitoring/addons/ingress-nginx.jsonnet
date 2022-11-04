{
    serviceMonitor+:: {
        'ingress-nginx': {
            'apiVersion': 'monitoring.coreos.com/v1',
            'kind': 'ServiceMonitor',
            'metadata': {
                'labels': {
                    'app.kubernetes.io/name': 'ingress-nginx',
                    'app.kubernetes.io/instance': 'ingress-nginx',
                    'app.kubernetes.io/component': 'controller',
                },
                'name': 'ingress-nginx-controller',
                'namespace': 'monitoring'
            },
            'spec': {
                'endpoints': [
                    {
                        'interval': '30s',
                        'port': 'metrics',
                        'scheme': 'http',
                    },
                ],
                'namespaceSelector': {
                    'matchNames': [
                        'ingress-nginx'
                    ],
                },
                'selector': {
                    'matchLabels': {
                        'app.kubernetes.io/name': 'ingress-nginx',
                        'app.kubernetes.io/instance': 'ingress-nginx',
                        'app.kubernetes.io/component': 'controller',
                    },
                },
            },
        }
    }
}
