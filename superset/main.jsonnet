local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

local data = {
  '0.10.5': importbin './upstream/superset-0.10.5.tgz',
};

{
  local ing = k.networking.v1.ingress,
  local ingpath = k.networking.v1.httpIngressPath,
  local ingrule = k.networking.v1.ingressRule,

  _config:: {
    version: '0.10.5',
    name: 'superset',
    namespace: 'superset',
    ingress: {
      className: 'nginx',
      hostname: 'superset.127.0.0.1.nip.io',
    },
  },

  // https://github.com/apache/superset/blob/master/helm/superset/values.yaml
  _values:: {
    ingress: {
      enabled: true,
      ingressClassName: $._config.ingress.className,
      hosts: [$._config.ingress.hostname],
      pathType: 'Prefix',
    },


  },

  _namespace::
    k.core.v1.namespace.new($._config.namespace),

  _upstream:: parse.HelmToObjectsGVKName(
    kubecfg.parseHelmChart(
      data[$._config.version],
      $._config.name,
      $._config.namespace,
      $._values
    )
  ) {
  },

  //_ingress_http::
  //  ing.new($._upstream.v1.Service['proxy-public'].metadata.name) +
  //  ing.metadata.withNamespace($._upstream.v1.Service['proxy-public'].metadata.namespace) +
  //  ing.metadata.withLabelsMixin($._upstream.v1.Service['proxy-public'].metadata.labels) +
  //  ing.metadata.withAnnotationsMixin({
  //    'kubernetes.io/tls-acme': 'true',
  //  }) +
  //  ing.spec.withIngressClassName('nginx') +
  //  ing.spec.withRules(
  //    ingrule.withHost($._config.ingress.hostname) +
  //    ingrule.http.withPathsMixin(
  //      ingpath.withPath('/') +
  //      ingpath.backend.service.withName($._upstream.v1.Service['proxy-public'].metadata.name) +
  //      ingpath.withPathType('Prefix') +
  //      ingpath.backend.service.port.withNumber($._upstream.v1.Service['proxy-public'].spec.ports[0].port)
  //    )
  //  ),

  objects: {
    phase0: $._namespace,
    phase1: $._upstream {
    },
  },
}
