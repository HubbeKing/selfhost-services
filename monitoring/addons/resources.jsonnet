{
    values+:: {
        alertmanager+:: {
            resources: {
                requests: { cpu: '50m', memory: '100Mi' },
                limits: { cpu: '150m', memory: '100Mi'},
            },
        },
        kubeStateMetrics+:: {
            resources: {
                requests: { cpu: '50m', memory: '256Mi' },
                limits: { cpu: '150m', memory: '512Mi' },
            },
            kubeRbacProxyMain+:: {
                resources: {
                    requests: { cpu: '50m', memory: '256Mi' },
                    limits: { cpu: '150m', memory: '512Mi' },
                },
            }
        },
        nodeExporter+:: {
            resources: {
                requests: { cpu: '100m', memory: '256Mi' },
                limits: { memory: '256Mi' },
            },
        },
        prometheusAdapter+:: {
            resources: {
                requests: { cpu: '50m', memory: '256Mi' },
                limits: { cpu: '150m', memory: '256Mi' },
            },
        },
        prometheusOperator+:: {
            resources: {
                requests: { cpu: '50m', memory: '256Mi' },
                limits: { cpu: '150m', memory: '256Mi' },
            },
        },
    }
}
