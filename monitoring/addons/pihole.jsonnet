{
    serviceMonitor+:: {
        'pihole': {
            'apiVersion': 'monitoring.coreos.com/v1',
            'kind': 'ServiceMonitor',
            'metadata': {
                'labels': {
                    'app': 'pihole-exporter'
                },
                'name': 'pihole-exporter',
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
                        'default'
                    ],
                },
                'selector': {
                    'matchLabels': {
                        'app': 'pihole-exporter'
                    },
                },
            },
        }
    }
}
