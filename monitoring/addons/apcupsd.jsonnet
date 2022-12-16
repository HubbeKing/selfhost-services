{
    prometheusRule+:: {
        'apcupsd': {
            'apiVersion': 'monitoring.coreos.com/v1',
            'kind': 'PrometheusRule',
            'metadata': {
                'labels': {
                    'app': 'apcupsd-exporter',
                    'prometheus': 'k8s',
                    'role': 'alert-rules'
                },
                'name': 'apcupsd-exporter',
                'namespace': 'monitoring'
            },
            'spec': {
                'groups': [
                    {
                        'name': 'apcupsd.rules',
                        'rules': [
                            {
                                'alert': 'UPSInputACLost',
                                'annotations': {
                                    'description': 'UPS {{$labels.ups}} has lost AC power! Current AC voltage is {{$value}}V.',
                                    'summary': 'UPS is on battery power.'
                                },
                                'expr': 'apcupsd_line_volts < 190',
                                'for': '10s',
                                'labels': {
                                    'issue': 'UPS {{$labels.ups}} has lost AC power!',
                                    'severity': 'critical'
                                },
                            },
                            {
                                'alert': 'UPSOnBattery',
                                'annotations': {
                                    'description': 'UPS {{$labels.ups}} has gone on battery power! Currently been on battery for {{$value}} seconds.',
                                    'summary': 'UPS is on battery power.'
                                },
                                'expr': 'apcupsd_battery_time_on_seconds > 0',
                                'for': '10s',
                                'labels': {
                                    'issue': 'UPS {{$labels.ups}} is on battery power!',
                                    'severity': 'critical'
                                },
                            },
                            {
                                'alert': 'UPSBatteryCritical',
                                'annotations': {
                                    'description': 'UPS {{$labels.ups}} is at critical battery and going offline in less than {{$value}} seconds!',
                                    'summary': 'UPS is going offline.'
                                },
                                'expr': 'apcupsd_battery_time_left_seconds < 180',
                                'for': '5s',
                                'labels': {
                                    'issue': 'UPS {{$labels.ups}} is at critical battery levels!',
                                    'severity': 'critical'
                                },
                            },
                            {
                                'alert': 'UPSLoadHigh',
                                'annotations': {
                                    'description': 'UPS {{$labels.ups}} load is higher than ideal. Currently at {{$value}}% load.',
                                    'summary': 'UPS under high load'
                                },
                                'expr': 'apcupsd_ups_load_percent > 60',
                                'for': '15m',
                                'labels': {
                                    'issue': 'UPS {{$labels.ups}} is under high load.',
                                    'severity': 'warning'
                                },
                            },
                            {
                                'alert': 'UPSRuntimeEstimateLow',
                                'annotations': {
                                    'description': 'UPS {{$labels.ups}} estimated runtime on battery is very low. Currently at {{$value|humanizeDuration}}.',
                                    'summary': 'UPS estimated runtime low.'
                                },
                                'expr': '(apcupsd_battery_charge_percentage > 90) and (apcupsd_battery_time_left_seconds < (4*60)) ',
                                'for': '15m',
                                'labels': {
                                    'issue': 'UPS {{$labels.ups}} estimated runtime is low.',
                                    'severity': 'warning'
                                },
                            },
                        ],
                    },
                ],
            },
        },
    },
    serviceMonitor+:: {
        'apcupsd': {
            'apiVersion': 'monitoring.coreos.com/v1',
            'kind': 'ServiceMonitor',
            'metadata': {
                'labels': {
                    'app': 'apcupsd-exporter'
                },
                'name': 'apcupsd-exporter',
                'namespace': 'monitoring'
            },
            'spec': {
                'endpoints': [
                    {
                        'interval': '5s',
                        'port': 'metrics',
                        'scheme': 'http',
                    },
                ],
                'namespaceSelector': {
                    'matchNames': [
                        'monitoring'
                    ],
                },
                'selector': {
                    'matchLabels': {
                        'app': 'apcupsd-exporter'
                    },
                },
            },
        }
    },
    service+:: {
        'apcupsd': {
            'apiVersion': 'v1',
            'kind': 'Service',
            'metadata': {
                'labels': {
                    'app': 'apcupsd-exporter'
                },
                'name': 'apcupsd-exporter',
                'namespace': 'monitoring'
            },
            'spec': {
                'ports': [
                    {
                        'name': 'metrics',
                        'port': 9162
                    },
                ],
            },
        },
    },
    endpoints+:: {
        'apcupsd': {
            'apiVersion': 'v1',
            'kind': 'Endpoints',
            'metadata': {
                'labels': {
                    'app': 'apcupsd-exporter'
                },
                'name': 'apcupsd-exporter',
                'namespace': 'monitoring'
            },
            'subsets': [
                {
                    'addresses': [
                        {
                            'ip': '192.168.1.107'
                        },
                    ],
                    'ports': [
                        {
                            'name': 'metrics',
                            'port': 9162,
                            'protocol': 'TCP'
                        },
                    ],
                },
            ],
        },
    },
}
