local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';
local g = (import 'vendor/gateway-api-libsonnet/v0.7.1/main.libsonnet').gateway;

local data = {
  '1.25': parse.YAMLToObjectsGVKName(importstr './upstream/release-1.25.yaml'),
};

{

  _config:: {
    version: '1.25',
  },

  _gatewayClass::
    g.v1beta1.gatewayClass.new('contour') +
    g.v1beta1.gatewayClass.spec.withControllerName('projectcontour.io/gateway-controller'),

  _gateway::
    g.v1beta1.gateway.new('contour') +
    g.v1beta1.gateway.metadata.withNamespace('projectcontour') +
    g.v1beta1.gateway.spec.withGatewayClassName($._gatewayClass.metadata.name) +
    g.v1beta1.gateway.spec.withListenersMixin(
      g.v1beta1.gateway.spec.listeners.withName('http') +
      g.v1beta1.gateway.spec.listeners.withProtocol('HTTP') +
      g.v1beta1.gateway.spec.listeners.withPort(80) +
      g.v1beta1.gateway.spec.listeners.allowedRoutes.namespaces.withFrom('All')
    ),

  _upstream:: data[$._config.version],

  objects: {
    namespaces: $._upstream.v1.Namespace,
    upstream: $._upstream,
    gateway: $._gateway,
    gatewayClass: $._gatewayClass,
  },
}
