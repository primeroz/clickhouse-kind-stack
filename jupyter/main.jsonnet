local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

local data = {
  '2.0.0': importbin './upstream/jupyterhub-2.0.0.tgz',
};

{
  local ing = k.networking.v1.ingress,
  local ingpath = k.networking.v1.httpIngressPath,
  local ingrule = k.networking.v1.ingressRule,

  _config:: {
    version: '2.0.0',
    namespace: 'jupyterhub',
    ingress: {
      hostname: 'jupyter.127.0.0.1.nip.io',
    },
  },

  _values:: {
    singleuser: {
      image: {
        name: 'jupyter/datascience-notebook',
        tag: 'latest',
      },
    },
    proxy: {
      service: {
        type: 'ClusterIP',
      },
    },
    scheduling: {
      userScheduler: {
        enabled: false,
      },
    },
  },

  _namespace::
    k.core.v1.namespace.new($._config.namespace),

  _upstream:: parse.HelmToObjectsGVKName(
    kubecfg.parseHelmChart(
      data[$._config.version],
      'jupyterhub',
      $._config.namespace,
      $._values
    )
  ) {
    'policy/v1beta1'+: {
      PodDisruptionBudget+: {
        'user-placeholder'+: {
          apiVersion: 'policy/v1',
        },
        [if $._values.scheduling.userScheduler.enabled then 'user-scheduler']+: {
          apiVersion: 'policy/v1',
        },
      },
    },
  },

  _ingress_http::
    ing.new($._upstream.v1.Service['proxy-public'].metadata.name) +
    ing.metadata.withNamespace($._upstream.v1.Service['proxy-public'].metadata.namespace) +
    ing.metadata.withLabelsMixin($._upstream.v1.Service['proxy-public'].metadata.labels) +
    ing.metadata.withAnnotationsMixin({
      'kubernetes.io/tls-acme': 'true',
    }) +
    ing.spec.withIngressClassName('nginx') +
    ing.spec.withRules(
      ingrule.withHost($._config.ingress.hostname) +
      ingrule.http.withPathsMixin(
        ingpath.withPath('/') +
        ingpath.backend.service.withName($._upstream.v1.Service['proxy-public'].metadata.name) +
        ingpath.withPathType('Prefix') +
        ingpath.backend.service.port.withNumber($._upstream.v1.Service['proxy-public'].spec.ports[0].port)
      )
    ),

  objects: {
    phase0: $._namespace,
    phase1: $._upstream {
      ingress: $._ingress_http,
    },
  },
}
