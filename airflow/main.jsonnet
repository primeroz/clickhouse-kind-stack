local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';
local k = import 'vendor/k8s-libsonnet/1.26/main.libsonnet';

local data = {
  '1.10.0': importbin './upstream/airflow-1.10.0.tgz',
};

{
  local ing = k.networking.v1.ingress,
  local ingpath = k.networking.v1.httpIngressPath,
  local ingrule = k.networking.v1.ingressRule,

  _config:: {
    version: '1.10.0',
    name: 'airflow',
    namespace: 'airflow',
    ingress: {
      className: 'nginx',
      hostname: 'airflow.127.0.0.1.nip.io',
    },
  },

  // https://github.com/airflow-helm/charts/blob/main/charts/airflow/values.yaml
  _values:: {
    airflow: {
      executor: 'KubernetesExecutor',
      fernetKey: '7T512UXSSmBOkpWimFHIVb8jK6lfmSAvx4mO6Arehnc=',  // This should be changed from the default
      webserverSecretKey: 'THIS IS UNSAFE!',  // This should be changed from the default
    },
    ingress: {
      enabled: true,
      web: {
        ingressClassName: $._config.ingress.className,
        host: $._config.ingress.hostname,
      },
      flower: {
        ingressClassName: $._config.ingress.className,
        host: 'flower-' + $._config.ingress.hostname,
      },
    },
    redis: {
      // cluster: {
      //   enabled: false,
      // },
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

  objects: {
    phase0: $._namespace,
    phase1: $._upstream {
    },
  },
}
