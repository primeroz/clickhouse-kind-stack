local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';
local g = (import 'vendor/gateway-api-libsonnet/v0.7.1/main.libsonnet').gateway;
local contour = import 'vendor/contour-libsonnet/1.24/main.libsonnet';


local data = {
  '1.25': parse.YAMLToObjectsGVKName(importstr './upstream/release-1.25.yaml'),
};

{

  local gateway = g.v1beta1.gateway,
  local gatewayClass = g.v1beta1.gatewayClass,
  local deploymentConf = contour.projectcontour.v1alpha1.contourDeployment,


  _config:: {
    version: '1.25',
    name: 'contour',
    namespace: 'projectcontour',
  },

  _contourDeploymentConfiguration::
    deploymentConf.new($._config.name + '-params') +
    deploymentConf.metadata.withNamespace($._config.namespace) +
    deploymentConf.spec.envoy.networkPublishing.withType('NodePortService'),

  _gatewayClass::
    gatewayClass.new($._config.name) +
    gatewayClass.spec.withControllerName('projectcontour.io/gateway-controller') +
    gatewayClass.spec.parametersRef.withGroup('projectcontour.io') +
    gatewayClass.spec.parametersRef.withKind('ContourDeployment') +
    gatewayClass.spec.parametersRef.withName($._contourDeploymentConfiguration.metadata.name) +
    gatewayClass.spec.parametersRef.withNamespace($._contourDeploymentConfiguration.metadata.namespace),

  _gateway::
    gateway.new($._config.name) +
    gateway.metadata.withNamespace($._config.namespace) +
    gateway.spec.withGatewayClassName($._gatewayClass.metadata.name) +
    gateway.spec.withListenersMixin(
      gateway.spec.listeners.withName('http') +
      gateway.spec.listeners.withProtocol('HTTP') +
      gateway.spec.listeners.withPort(80) +
      gateway.spec.listeners.allowedRoutes.namespaces.withFrom('All')
    ),

  _upstream:: data[$._config.version],

  objects: {
    namespaces: $._upstream.v1.Namespace,
    upstream: $._upstream,
    gateway: {
      contourDeploymentConfiguration: $._contourDeploymentConfiguration,
      gateway: $._gateway,
      gatewayClass: $._gatewayClass,
    },
  },
}
