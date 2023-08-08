local kubecfg = import 'kubecfg.libsonnet';
local parse = import 'parse.libsonnet';


local data = {
  gatewayApi: parse.YAMLToObjectsGVKName(importstr 'https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.7.1/experimental-install.yaml'),
};

{

  _config:: {},

  _gatewayApi:: data.gatewayApi,

  gatewayApi:
    $._gatewayApi,
}
