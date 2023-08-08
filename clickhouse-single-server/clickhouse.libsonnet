local kubecfg = import 'kubecfg.libsonnet';
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

// TODO: Labels
// TODO Ulimits for clickhouse
// TODO readyness and liveness probe

{
  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,
  local pvc = k.core.v1.persistentVolumeClaim,
  local volumeMount = k.core.v1.volumeMount,
  local statefulSet = k.apps.v1.statefulSet,
  local svc = k.core.v1.service,
  local svcPort = k.core.v1.servicePort,

  _config+:: {
    namespace: 'clickhouse',
    server: {
      image: 'clickhouse/clickhouse-server',
      tag: '23',
      resources: {
        requests: {
          cpu: '1',
          memory: '2Gi',
        },
        limits: {
          cpu: '3',
          memory: '6Gi',
        },
      },
      volumes: {
        data: {
          size: '10Gi',
          storageClass: 'standard',
        },
        logs: {
          enabled: true,  // Do i really need a logs volume ?
          size: '2Gi',
          storageClass: 'standard',
        },
      },
    },
  },

  _namespace::
    k.core.v1.namespace.new($._config.namespace),

  _server_container::
    container.new('clickhouse', std.format('%s:%s', [$._config.server.image, $._config.server.tag])) +
    container.withPorts([
      containerPort.newNamed(8123, 'http'),
      containerPort.newNamed(9000, 'native'),
      containerPort.newNamed(9009, 'inter'),
    ]) +
    //container.mixin.readinessProbe.httpGet.withPath('/ready') +
    //container.mixin.readinessProbe.httpGet.withPort($._config.http_listen_port) +
    //container.mixin.readinessProbe.withInitialDelaySeconds(15) +
    //container.mixin.readinessProbe.withTimeoutSeconds(1) +
    container.withResourcesRequests($._config.server.resources.requests.cpu, $._config.server.resources.requests.memory) +
    container.withResourcesLimits($._config.server.resources.limits.cpu, $._config.server.resources.limits.memory) +
    container.securityContext.capabilities.withAddMixin('NET_ADMIN') +
    container.securityContext.capabilities.withAddMixin('IPC_LOCK') +
    // TODO: ulimits nproc , nofile
    container.withVolumeMountsMixin(
      [
        volumeMount.new('data', '/var/lib/clickhouse'),
      ] + (if $._config.server.volumes.logs.enabled then
             [volumeMount.new('logs', '/var/log/clickhouse-server')]
           else []),
    ),
  // TODO: Configmap volumnes for xml snippets and initdb

  _server_logs_pvc::
    pvc.new('logs') +
    pvc.mixin.spec.resources.withRequests({ storage: $._config.server.volumes.logs.size }) +
    pvc.mixin.spec.withAccessModes(['ReadWriteOnce']) +
    pvc.mixin.spec.withStorageClassName($._config.server.volumes.logs.storageClass),

  _server_data_pvc::
    pvc.new('data') +
    pvc.mixin.spec.resources.withRequests({ storage: $._config.server.volumes.data.size }) +
    pvc.mixin.spec.withAccessModes(['ReadWriteOnce']) +
    pvc.mixin.spec.withStorageClassName($._config.server.volumes.data.storageClass),

  _server_statefulSet::
    statefulSet.new('clickhouse-server', 1, [$._server_container], [$._server_data_pvc, $._server_logs_pvc]) +
    statefulSet.metadata.withNamespace($._config.namespace) +
    statefulSet.mixin.spec.withServiceName('clickhouse') +
    //$.config_hash_mixin +
    //k.util.configVolumeMount('loki', '/etc/loki/config') +
    statefulSet.mixin.spec.updateStrategy.withType('RollingUpdate'),
  //statefulSet.mixin.spec.template.spec.securityContext.withFsGroup(10001),

  _server_service::
    svc.new('clickhouse', $._server_statefulSet.spec.selector.matchLabels, []) +
    svc.metadata.withNamespace($._config.namespace) +
    svc.spec.withPortsMixin(
      svcPort.newNamed('http', 8123, 8123)
    ) +
    svc.spec.withPortsMixin(
      svcPort.newNamed('native', 9000, 9000)
    ) +
    svc.spec.withType('ClusterIP'),


  resources: {
    namespace: $._namespace,
  },
  server_resources: {
    statefulSet: $._server_statefulSet,
    service: $._server_service,
  },
}
