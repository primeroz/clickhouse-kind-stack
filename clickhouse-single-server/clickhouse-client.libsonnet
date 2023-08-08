local kubecfg = import 'kubecfg.libsonnet';
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

{
  local container = k.core.v1.container,
  local statefulSet = k.apps.v1.statefulSet,

  _config+:: {
    client: {
      image: 'nixery.dev/shell/clickhouse/clickhouse-cli',
      tag: 'latest',
      namespace: 'clickhouse',
      resources: {
        requests: {
          cpu: '100m',
          memory: '256Mi',
        },
        limits: {
          cpu: '1',
          memory: '2Gi',
        },
      },
    },
  },

  _client_container::
    container.new('client', std.format('%s:%s', [$._config.client.image, $._config.client.tag])) +
    container.withResourcesRequests($._config.client.resources.requests.cpu, $._config.client.resources.requests.memory) +
    container.withResourcesLimits($._config.client.resources.limits.cpu, $._config.client.resources.limits.memory) +
    container.withCommand('sleep') +
    container.withArgsMixin('infinity'),

  _client_statefulSet::
    statefulSet.new('clickhouse-client', 1, [$._client_container], []) +
    statefulSet.metadata.withNamespace($._config.namespace) +
    statefulSet.mixin.spec.withServiceName('clickhouse-client') +
    statefulSet.mixin.spec.updateStrategy.withType('RollingUpdate'),

  client_resources: {
    statefulSet: $._client_statefulSet,
  },
}
