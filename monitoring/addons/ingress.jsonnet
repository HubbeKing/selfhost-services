local ingress(name, namespace, host, service, extraAnnotations={}) = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: name,
    namespace: namespace,
    annotations: {
      'nginx.ingress.kubernetes.io/auth-method': 'GET',
      'nginx.ingress.kubernetes.io/auth-url': 'http://authelia.authelia.svc.cluster.local:9091/api/verify',
      'nginx.ingress.kubernetes.io/auth-signin': 'https://auth.hubbe.club?rm=$request_method',
      'nginx.ingress.kubernetes.io/auth-response-headers': 'Remote-User,Remote-Name,Remote-Groups,Remote-Email',
      'nginx.ingress.kubernetes.io/auth-snippet': 'proxy_set_header X-Forwarded-Method $request_method;',
    } + extraAnnotations,
  },
  spec: { 
    ingressClassName: 'nginx',
    tls: [{
      hosts: [ host ],
    }],
    rules: [{
      host: host,
      http: {
        paths: [{
          path: '/',
          pathType: 'Prefix',
          backend: {
            service: service,
          },
        }],
      }
    }],
  },
};

{
  values+:: {
    grafana+:: {
      config+: {
        sections+: {
          server+: {
            root_url: 'https://grafana.hubbe.club/',
          },
          security+: {
            disable_initial_admin_creation: true,
          },
          auth+: {
            oauth_auto_login: true,
            signout_redirect_url: 'https://auth.hubbe.club/logout',
          },
          'auth.proxy': {
            enabled: true,
            header_name: 'X-Email',
            header_property: 'email',
            auto_sign_up: true,
          },
          users: {
            allow_sign_up: false,
            auto_assign_org: true,
            auto_assign_org_role: 'Admin',
          },
        },
      },
    },
  },
  // Configure External URL's per application
  alertmanager+:: {
    alertmanager+: {
      spec+: {
        externalUrl: 'https://alertmanager.hubbe.club',
      },
    },
  },
  prometheus+:: {
    prometheus+: {
      spec+: {
        externalUrl: 'https://prometheus.hubbe.club',
      },
    },
  },
  // Create ingress objects per application
  ingress+:: {
    'alertmanager-main': ingress(
      'alertmanager-main',
      $.values.common.namespace,
      'alertmanager.hubbe.club',
      { 
        'name': 'alertmanager-main',
        'port': { 'name': 'web' }
      }
    ),
    grafana: ingress(
      'grafana',
      $.values.common.namespace,
      'grafana.hubbe.club',
      {
        'name': 'grafana',
        'port': { 'name': 'http' },
      },
      {
        'nginx.ingress.kubernetes.io/configuration-snippet': |||
          auth_request_set $user   $upstream_http_remote_user;
          auth_request_set $email  $upstream_http_remote_email;
          proxy_set_header X-User  $user;
          proxy_set_header X-Email $email;
        |||,
      },
    ),
    'prometheus-k8s': ingress(
      'prometheus-k8s',
      $.values.common.namespace,
      'prometheus.hubbe.club',
      {
        'name': 'prometheus-k8s',
        'port': { 'name': 'web' },
      },
    ),
  },
}
