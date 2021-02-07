{
  grafana+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            local adjustResources(c) =
              if c.name == 'grafana'
              then c {
                  resources: {
                    requests: { cpu: "100m", memory: "128Mi" },
                    limits: { cpu: "500m", memory: "512Mi" },
                  },
                }
              else c,
            containers: std.map(adjustResources, super.containers),
          },
        },
      },
    },
  },
}