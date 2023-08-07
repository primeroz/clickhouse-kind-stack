local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';
local g = (import 'vendor/gateway-api-libsonnet/v0.7.1/main.libsonnet').gateway;
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

local data = {
  '2.0.0': importbin './upstream/jupyterhub-2.0.0.tgz',
};

{

  _config:: {
    version: '2.0.0',
    namespace: 'jupyterhub',
    gateway: {
      class: 'contour',
      namespace: 'projectcontour',
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
        'user-scheduler'+: {
          apiVersion: 'policy/v1',
        },
      },
    },
  },

  _httproute::
    g.v1beta1.httpRoute.new($._upstream.v1.Service['proxy-public'].metadata.name) +
    g.v1beta1.httpRoute.metadata.withNamespace($._upstream.v1.Service['proxy-public'].metadata.namespace) +
    g.v1beta1.httpRoute.metadata.withLabelsMixin($._upstream.v1.Service['proxy-public'].metadata.labels) +
    g.v1beta1.httpRoute.spec.withParentRefsMixin(
      g.v1beta1.httpRoute.spec.parentRefs.withGroup('gateway.networking.k8s.io') +
      g.v1beta1.httpRoute.spec.parentRefs.withKind('Gateway') +
      g.v1beta1.httpRoute.spec.parentRefs.withName($._config.gateway.class) +
      g.v1beta1.httpRoute.spec.parentRefs.withName($._config.gateway.namespace),
    ) +
    g.v1beta1.httpRoute.spec.withHostnamesMixin($._config.gateway.hostname) +
    g.v1beta1.httpRoute.spec.withRulesMixin(
      g.v1beta1.httpRoute.spec.rules.withMatchesMixin(
        g.v1beta1.httpRoute.spec.rules.matches.path.withType('PathPrefix') +
        g.v1beta1.httpRoute.spec.rules.matches.path.withValue('/')
      ) +
      g.v1beta1.httpRoute.spec.rules.withBackendRefsMixin(
        g.v1beta1.httpRoute.spec.rules.backendRefs.withKind('Service') +
        g.v1beta1.httpRoute.spec.rules.backendRefs.withName($._upstream.v1.Service['proxy-public'].metadata.name) +
        g.v1beta1.httpRoute.spec.rules.backendRefs.withPort($._upstream.v1.Service['proxy-public'].spec.ports[0].port)
      ),
    ),

  objects: {
    namespace: $._namespace,
    upstream: $._upstream {
      httpRoute: $._httproute,
    },
  },
}
