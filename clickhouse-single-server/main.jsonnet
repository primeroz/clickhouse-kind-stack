local kubecfg = import 'kubecfg.libsonnet';
local g = (import 'vendor/gateway-api-libsonnet/v0.7.1/main.libsonnet').gateway;
local ch = import './clickhouse.libsonnet';
local client = import './clickhouse-client.libsonnet';
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

ch + client {

  local httpRoute = g.v1beta1.httpRoute,

  _config+:: {
    gateway: {
      class: 'contour',
      namespace: 'projectcontour',
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
      httpRoute.spec.parentRefs.withName($._config.gateway.class) +
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

}
