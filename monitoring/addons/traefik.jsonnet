{
    serviceMonitor+:: {
        'traefik': {
            'apiVersion': 'monitoring.coreos.com/v1',
            'kind': 'ServiceMonitor',
            'metadata': {
                'labels': {
                    'app.kubernetes.io/name': 'traefik',
                    'app.kubernetes.io/instance': 'traefik-traefik',
                },
                'name': 'traefik',
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
                        'traefik'
                    ],
                },
                'selector': {
                    'matchLabels': {
                        'app.kubernetes.io/name': 'traefik',
                        'app.kubernetes.io/instance': 'traefik-traefik',
                    },
                },
            },
        }
    }
}
