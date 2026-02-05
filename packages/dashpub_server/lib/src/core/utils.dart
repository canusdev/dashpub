import 'package:yaml/yaml.dart';

dynamic convertYaml(dynamic value) {
  if (value is YamlMap) {
    return value.cast<String, dynamic>().map(
      (k, v) => MapEntry(k, convertYaml(v)),
    );
  }
  if (value is YamlList) {
    return value.map((e) => convertYaml(e)).toList();
  }
  return value;
}

Map<String, dynamic>? loadYamlAsMap(String? value) {
  if (value == null) return null;
  var yamlMap = loadYaml(value) as YamlMap?;
  if (yamlMap == null) return null;
  return convertYaml(yamlMap).cast<String, dynamic>();
}

List<String> getPackageTags(Map<String, dynamic> pubspec) {
  if (pubspec['flutter'] != null) {
    return ['flutter'];
  } else {
    return ['flutter', 'web', 'other'];
  }
}
