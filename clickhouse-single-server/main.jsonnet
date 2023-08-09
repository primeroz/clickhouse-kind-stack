local client = import './clickhouse-client.libsonnet';
local ch = import './clickhouse.libsonnet';
local kubecfg = import 'kubecfg.libsonnet';
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

ch + client {

  local svc = k.core.v1.service,
  local svcPort = k.core.v1.servicePort,
  local statefulSet = k.apps.v1.statefulSet,
  local ing = k.networking.v1.ingress,
  local ingpath = k.networking.v1.httpIngressPath,
  local ingrule = k.networking.v1.ingressRule,

  _config+:: {
    ingress: {
      hostname: 'clickhouse.127.0.0.1.nip.io',
    },
  },

  _ingress_http:
    ing.new('clickhouse-http') +
    ing.metadata.withNamespace($._server_service.metadata.namespace) +
    ing.metadata.withAnnotationsMixin({
      //'kubernetes.io/ingress.class': 'nginx',
      'kubernetes.io/tls-acme': 'true',
    }) +
    ing.spec.withIngressClassName('nginx') +
    ing.spec.withRules(
      ingrule.withHost($._config.ingress.hostname) +
      ingrule.http.withPathsMixin(
        ingpath.withPath('/') +
        ingpath.backend.service.withName('clickhouse') +
        ingpath.withPathType('Prefix') +
        ingpath.backend.service.port.withNumber(8123)
      )
    ),

  // Overwrite DATA Volume with local hostpath
  _server_data_pvc:: null,
  _server_statefulSet+::
    statefulSet.spec.template.spec.withVolumesMixin(
      {
        name: 'data',
        hostPath: {
          path: '/clickhouse-data',
        },
      }
    ),

}
