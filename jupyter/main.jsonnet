local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';
//local g = (import 'vendor/gateway-api-libsonnet/v0.7.1/main.libsonnet').gateway;
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

local data = {
  '2.0.0': importbin './upstream/jupyterhub-2.0.0.tgz',
};

{

  _config:: {
    version: '2.0.0',
    namespace: 'jupyterhub',
  },

  _values:: {


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

  objects: {
    namespace: $._namespace,
    upstream: $._upstream,
  },
}
