// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageVersion _$PackageVersionFromJson(Map<String, dynamic> json) =>
    PackageVersion(
      json['version'] as String,
      json['pubspec'] as Map<String, dynamic>,
      json['pubspecYaml'] as String?,
      json['uploader'] as String?,
      json['readme'] as String?,
      json['changelog'] as String?,
      json['license'] as String?,
      _identity(json['createdAt'] as DateTime),
    );

Map<String, dynamic> _$PackageVersionToJson(PackageVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
      'pubspec': instance.pubspec,
      'pubspecYaml': ?instance.pubspecYaml,
      'uploader': ?instance.uploader,
      'readme': ?instance.readme,
      'changelog': ?instance.changelog,
      'license': ?instance.license,
      'createdAt': _identity(instance.createdAt),
    };

PackagePermission _$PackagePermissionFromJson(Map<String, dynamic> json) =>
    PackagePermission(
      json['uploaderId'] as String,
      json['isTeam'] as bool,
      $enumDecode(_$PermissionTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$PackagePermissionToJson(PackagePermission instance) =>
    <String, dynamic>{
      'uploaderId': instance.uploaderId,
      'isTeam': instance.isTeam,
      'type': _$PermissionTypeEnumMap[instance.type]!,
    };

const _$PermissionTypeEnumMap = {
  PermissionType.read: 'read',
  PermissionType.write: 'write',
  PermissionType.admin: 'admin',
};

Package _$PackageFromJson(Map<String, dynamic> json) => Package(
  json['name'] as String,
  (json['versions'] as List<dynamic>)
      .map((e) => PackageVersion.fromJson(e as Map<String, dynamic>))
      .toList(),
  json['private'] as bool,
  (json['uploaders'] as List<dynamic>?)?.map((e) => e as String).toList(),
  (json['permissions'] as List<dynamic>?)
      ?.map((e) => PackagePermission.fromJson(e as Map<String, dynamic>))
      .toList(),
  _identity(json['createdAt'] as DateTime),
  _identity(json['updatedAt'] as DateTime),
  (json['download'] as num?)?.toInt(),
);

Map<String, dynamic> _$PackageToJson(Package instance) => <String, dynamic>{
  'name': instance.name,
  'versions': instance.versions,
  'private': instance.private,
  'uploaders': instance.uploaders,
  'permissions': instance.permissions,
  'createdAt': _identity(instance.createdAt),
  'updatedAt': _identity(instance.updatedAt),
  'download': instance.download,
};

QueryResult _$QueryResultFromJson(Map<String, dynamic> json) => QueryResult(
  (json['count'] as num).toInt(),
  (json['packages'] as List<dynamic>)
      .map((e) => Package.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$QueryResultToJson(QueryResult instance) =>
    <String, dynamic>{'count': instance.count, 'packages': instance.packages};
