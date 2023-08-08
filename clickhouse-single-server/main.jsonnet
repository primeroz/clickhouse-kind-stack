local kubecfg = import 'kubecfg.libsonnet';
local g = (import 'vendor/gateway-api-libsonnet/v0.7.1/main.libsonnet').gateway;
local ch = import './clickhouse.libsonnet';
local client = import './clickhouse-client.libsonnet';
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

ch + client {

  local httpRoute = g.v1beta1.httpRoute,
  local svc = k.core.v1.service,
  local svcPort = k.core.v1.servicePort,

  _config+:: {
    gateway: {
      name: 'nginx-gateway',
      namespace: 'nginx-gateway',
      hostname: 'clickhouse.127.0.0.1.nip.io',
    },
  },

  _httproute:
    httpRoute.new($._server_service.metadata.name + '-http') +
    httpRoute.metadata.withNamespace($._server_service.metadata.namespace) +
    //httpRoute.metadata.withLabelsMixin($._server_service.metadata.labels) +
    httpRoute.spec.withParentRefsMixin(
      httpRoute.spec.parentRefs.withGroup('gateway.networking.k8s.io') +
      httpRoute.spec.parentRefs.withKind('Gateway') +
      httpRoute.spec.parentRefs.withName($._config.gateway.name) +
      httpRoute.spec.parentRefs.withNamespace($._config.gateway.namespace),
    ) +
    httpRoute.spec.withHostnamesMixin($._config.gateway.hostname) +
    httpRoute.spec.withRulesMixin(
      httpRoute.spec.rules.withMatchesMixin(
        httpRoute.spec.rules.matches.path.withType('PathPrefix') +
        httpRoute.spec.rules.matches.path.withValue('/')
      ) +
      httpRoute.spec.rules.withBackendRefsMixin(
        httpRoute.spec.rules.backendRefs.withKind('Service') +
        httpRoute.spec.rules.backendRefs.withName($._server_service.metadata.name) +
        httpRoute.spec.rules.backendRefs.withPort($._server_service.spec.ports[0].port)
      ),
    ),

  _tcproute: {
    apiVersion: 'gateway.networking.k8s.io/v1alpha2',
    kind: 'TCPRoute',
    metadata: {
      name: 'clickhouse-native',
      namespace: 'clickhouse',
    },
    spec: {
      parentRefs: [
        {
          group: 'gateway.networking.k8s.io',
          kind: 'Gateway',
          name: 'nginx-gateway',
          namespace: 'nginx-gateway',
          sectionName: 'clickhouse',
        },
      ],
      rules: [
        {
          backendRefs: [
            {
              name: 'clickhouse',
              port: 9000,
            },
          ],
        },
      ],
    },
  },

}
