local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';
local g = (import 'vendor/gateway-api-libsonnet/v0.7.1/main.libsonnet').gateway;
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';


local data = {
  upstream+: parse.YAMLToObjectsGVKName(importstr 'https://github.com/nginxinc/nginx-kubernetes-gateway/raw/v0.5.0/deploy/manifests/namespace.yaml') +
             parse.YAMLToObjectsGVKName(importstr 'https://github.com/nginxinc/nginx-kubernetes-gateway/raw/v0.5.0/deploy/manifests/deployment.yaml') +
             parse.YAMLToObjectsGVKName(importstr 'https://github.com/nginxinc/nginx-kubernetes-gateway/raw/v0.5.0/deploy/manifests/nginx-conf.yaml') +
             parse.YAMLToObjectsGVKName(importstr 'https://github.com/nginxinc/nginx-kubernetes-gateway/raw/v0.5.0/deploy/manifests/rbac.yaml') +
             parse.YAMLToObjectsGVKName(importstr 'https://raw.githubusercontent.com/nginxinc/nginx-kubernetes-gateway/main/deploy/manifests/njs-modules.yaml'),
};

{

  local svc = k.core.v1.service,
  local svcPort = k.core.v1.servicePort,

  local gateway = g.v1beta1.gateway,
  local gatewayClass = g.v1beta1.gatewayClass,


  _config:: {
    listeners: {
      http: {
        port: 30080,  // This port will be used as NODEPORT for the service and is also set in kind as forward
      },
      clickhouse: {
        port: 30009,  // This port will be used as NODEPORT for the service and is also set in kind as forward
      },
    },
  },

  _upstream:: data.upstream {
    v1+: {
      ConfigMap+: {
        'njs-modules'+: {
          metadata+: {
            namespace: $._upstream['apps/v1'].Deployment['nginx-gateway'].metadata.namespace,
          },
        },
      },
    },
    'apps/v1'+: {
      Deployment+: {
        'nginx-gateway'+: {
          spec+: {
            replicas: 1,
            template+: {
              spec+: {
                containers: [
                  c {
                    ports+: (if c.name == 'nginx' then [
                               {
                                 name: 'native',
                                 containerPort: 9000,
                               },
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

  _service::
    svc.new($._upstream['apps/v1'].Deployment['nginx-gateway'].metadata.name, $._upstream['apps/v1'].Deployment['nginx-gateway'].spec.selector.matchLabels, []) +
    svc.metadata.withNamespace($._upstream['apps/v1'].Deployment['nginx-gateway'].metadata.namespace) +
    svc.spec.withPortsMixin(
      svcPort.newNamed('http', 80, 80) +
      svcPort.withNodePort(30080)
    ) +
    svc.spec.withPortsMixin(
      svcPort.newNamed('https', 443, 443) +
      svcPort.withNodePort(30443)
    ) +
    svc.spec.withPortsMixin(
      svcPort.newNamed('native', 9000, 9000) +
      svcPort.withNodePort(30009)
    ) +
    svc.spec.withType('NodePort'),

  _gatewayClass::
    gatewayClass.new($._upstream['apps/v1'].Deployment['nginx-gateway'].metadata.name) +
    gatewayClass.spec.withControllerName('k8s-gateway.nginx.org/nginx-gateway-controller'),

  _gateway::
    gateway.new($._upstream['apps/v1'].Deployment['nginx-gateway'].metadata.name) +
    gateway.metadata.withNamespace($._upstream['apps/v1'].Deployment['nginx-gateway'].metadata.namespace) +
    gateway.spec.withGatewayClassName($._gatewayClass.metadata.name) +
    gateway.spec.withListenersMixin(
      gateway.spec.listeners.withName('http') +
      gateway.spec.listeners.withProtocol('HTTP') +
      gateway.spec.listeners.withPort($._config.listeners.http.port) +
      gateway.spec.listeners.allowedRoutes.namespaces.withFrom('All')
    ) +
    gateway.spec.withListenersMixin(
      gateway.spec.listeners.withName('clickhouse') +
      gateway.spec.listeners.withProtocol('TCP') +
      gateway.spec.listeners.withPort($._config.listeners.clickhouse.port) +
      gateway.spec.listeners.allowedRoutes.namespaces.withFrom('All') +
      gateway.spec.listeners.allowedRoutes.withKindsMixin(
        gateway.spec.listeners.allowedRoutes.kinds.withKind('TCPRoute')
      )
    ),

  nginx:
    $._upstream
    {
      service: $._service,
      gatewayClass: $._gatewayClass,
      gateway: $._gateway,
    },
}
