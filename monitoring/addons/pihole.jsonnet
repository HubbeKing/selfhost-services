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
        },
    },
    prometheusRule+:: {
        'pihole': {
            'apiVersion': 'monitoring.coreos.com/v1',
            'kind': 'PrometheusRule',
            'metadata': {
                'labels': {
                    'app': 'pihole-exporter',
                    'prometheus': 'k8s',
                    'role': 'alert-rules'
                },
                'name': 'pihole-exporter',
                'namespace': 'monitoring'
            },
            'spec': {
                'groups': [
                    {
                        'name': 'pihole.rules',
                        'rules': [
                            {
                                'alert': 'PiholeDown',
                                'annotations': {
                                    'description': 'Pihole instance on {{$labels.hostname}} has been down for longer than 5 minutes.',
                                    'summary': 'Pihole instance is down!'
                                },
                                'expr': 'pihole_status != 1',
                                'for': '5m',
                                'labels': {
                                    'issue': 'Pihole instance running on {{$labels.hostname}} is down!',
                                    'severity': 'critical'
                                },
                            },
                        ],
                    },
                ],
            },
        },
    },
}
