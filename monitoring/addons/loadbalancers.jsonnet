{
    // add loadbalancer definition to services
    prometheus+: {
        service+: {
            spec+: {
                type: "LoadBalancer", 
                loadBalancerIP: "192.168.1.10",
                ports: [
                    {
                        name: "web",
                        port: 9090,
                        targetPort: "web"
                    },
                ],
            },
        },
    },
    grafana+: {
        service+: {
            spec+: {
                type: "LoadBalancer", 
                loadBalancerIP: "192.168.1.11",
                ports: [
                    {
                        name: "http",
                        port: 3000,
                        targetPort: "http"
                    },
                ],
            },
        },
    },
    alertmanager+: {
        service+: {
            spec+: {
                type: "LoadBalancer", 
                loadBalancerIP: "192.168.1.12",
                ports: [
                    {
                        name: "web",
                        port: 9093,
                        targetPort: "web"
                    },
                ],
            },
        },
    },
}