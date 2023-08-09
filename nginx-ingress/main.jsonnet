local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';


local data = {
  upstream+: parse.YAMLToObjectsGVKName(importstr 'https://github.com/kubernetes/ingress-nginx/raw/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml'),
};

{

  local cm = k.core.v1.configMap,

  _config:: {
  },

  _upstream:: data.upstream {
    v1+: {
      Service+: {
        'ingress-nginx-controller'+: {
          spec+: {
            ports+: [
              {
                name: 'clickhouse',
                port: 9000,
                protocol: 'TCP',
                targetPort: 9000,
              },
            ],
          },
        },
      },
    },
    'apps/v1'+: {
      Deployment+: {
        'ingress-nginx-controller'+: {
          spec+: {
            replicas: 1,
            template+: {
              spec+: {
                containers: [
                  c {
                    ports+: (if c.name == 'controller' then [
                               {
                                 name: 'clickhouse',
                                 containerPort: 9000,
                                 hostPort: 9000,
                                 protocol: 'TCP',
                               },
                             ] else []),
                    args+: (if c.name == 'controller' then [
                              std.format('--tcp-services-configmap=%s/%s', [$._tcp_services_configmap.metadata.namespace, $._tcp_services_configmap.metadata.name]),
                            ] else []),
                  }
                  for c in super.containers
                ],
              },
            },
          },
        },
      },
    },

  },

  _tcp_services_configmap:
    cm.new('tcp-services') +
    cm.metadata.withNamespace($._upstream['apps/v1'].Deployment['ingress-nginx-controller'].metadata.namespace) +
    cm.withData(
      {
        '9000': 'clickhouse/clickhouse:9000',
      }
    ),

  nginx:
    $._upstream
    {
      tcpServicesConfigMap: $._tcp_services_configmap,
    },
}
