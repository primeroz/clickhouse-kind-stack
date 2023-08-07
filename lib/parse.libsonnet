local kubecfg = import 'kubecfg.libsonnet';

// Split resources from a list into a nested map
local GVKName(list) = std.foldl(function(acc, i) acc {
  [i.apiVersion]+: {
    [i.kind]+: {
      assert !( i.metadata.name in super),
      [i.metadata.name]: i,
    },
  },
}, [object for object in list if object != null], {});

local GVKNsName(list) = std.foldl(function(acc, i) acc {
  [i.apiVersion]+: {
    [i.kind]+: {
      [std.get(i.metadata, 'namespace', default='_')]+: {
        assert !( i.metadata.name in super),
        [i.metadata.name]: i,
      },
    },
  },
}, [object for object in list if object != null], {});

local HelmToGVKName(parsedHelm) =
  local gvkName(accum, o) = accum {
    [o.apiVersion]+: {
      [o.kind]+: {
        assert !( o.metadata.name in super),
        [o.metadata.name]: o,
      },
    },
  };
  kubecfg.fold(
    gvkName,
    parsedHelm,
    {}
  );

local HelmToGVKNsName(parsedHelm) =
  local gvkNsName(accum, o) = accum {
    [o.apiVersion]+: {
      [o.kind]+: {
        [std.get(o.metadata, 'namespace', default='_')]+: {
          [std.get(o.metadata, 'namespace', default='_')]+: {
            assert !( o.metadata.name in super),
            [o.metadata.name]: o,
          },
        },
      },
    },
  };
  kubecfg.fold(
    gvkNsName,
    parsedHelm,
    {}
  );


// CleanUp Helm labels
// local CleanUpLabels(map, commonLabels) =
//   configLib.utils.ApplyLabelsToWorkloadSelectorMatchLabelsNested(
//     configLib.utils.ApplyLabelsToWorkloadTemplateMetadataNested(
//       configLib.utils.ApplyLabelsToMetadataObjects(
//         map,
//         {
//           release:: null,
//           heritage:: null,
//           'app.kubernetes.io/instance':: null,
//         } + commonLabels  // ApplyLabelsToMetadataObjects
//       ),
//       {
//         release:: null,
//         heritage:: null,
//         'app.kubernetes.io/instance':: null,
//       } + commonLabels  // ApplyLabelsToWorkloadTemplateMetadataNested
//     ),
//     {
//       release:: null,
//       heritage:: null,
//       'app.kubernetes.io/instance':: null,
//       'app.kubernetes.io/version':: null,
//       version:: null,
//     } + commonLabels  // ApplyLabelsToWorkloadSelectorMatchLabelsNested
//   );

{
  YAMLToObjectsGVKName(str):: GVKName(kubecfg.parseYaml(str)),
  HelmToObjectsGVKName(parsedHelm):: HelmToGVKName(parsedHelm),
  JsonToObjectsGVKName(str):: GVKName(kubecfg.parseJson(str)),
  YAMLToObjectsGVKNsName(str):: GVKNsName(kubecfg.parseYaml(str)),
  JsonToObjectsGVKNsName(str):: GVKNsName(kubecfg.parseJson(str)),
  HelmToObjectsGVKNsName(parsedHelm):: HelmToGVKNsName(parsedHelm),
  //CleanUpLabels(map, commonLabels={}):: CleanUpLabels(map, commonLabels),
}
