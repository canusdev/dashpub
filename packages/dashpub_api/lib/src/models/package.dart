import 'package:json_annotation/json_annotation.dart';

part 'package.g.dart';

DateTime _identity(DateTime x) => x;

@JsonSerializable(includeIfNull: false)
class PackageVersion {
  final String version;
  final Map<String, dynamic> pubspec;
  final String? pubspecYaml;
  final String? uploader;
  final String? readme;
  final String? changelog;
  final String? license;

  @JsonKey(fromJson: _identity, toJson: _identity)
  final DateTime createdAt;

  PackageVersion(
    this.version,
    this.pubspec,
    this.pubspecYaml,
    this.uploader,
    this.readme,
    this.changelog,
    this.license,
    this.createdAt,
  );

  factory PackageVersion.fromJson(Map<String, dynamic> map) =>
      _$PackageVersionFromJson(map);

  Map<String, dynamic> toJson() => _$PackageVersionToJson(this);
}

enum PermissionType { read, write, admin }

@JsonSerializable()
class PackagePermission {
  final String uploaderId;
  final bool isTeam;
  final PermissionType type;

  PackagePermission(this.uploaderId, this.isTeam, this.type);

  factory PackagePermission.fromJson(Map<String, dynamic> map) =>
      _$PackagePermissionFromJson(map);
  Map<String, dynamic> toJson() => _$PackagePermissionToJson(this);
}

@JsonSerializable()
class Package {
  final String name;
  final List<PackageVersion> versions;
  final bool private;
  final List<String>? uploaders;
  final List<PackagePermission>? permissions;

  @JsonKey(fromJson: _identity, toJson: _identity)
  final DateTime createdAt;

  @JsonKey(fromJson: _identity, toJson: _identity)
  final DateTime updatedAt;

  final int? download;

  Package(
    this.name,
    this.versions,
    this.private,
    this.uploaders,
    this.permissions,
    this.createdAt,
    this.updatedAt,
    this.download,
  );

  factory Package.fromJson(Map<String, dynamic> map) => _$PackageFromJson(map);

  Map<String, dynamic> toJson() => _$PackageToJson(this);
}

@JsonSerializable()
class QueryResult {
  final int count;
  final List<Package> packages;

  QueryResult(this.count, this.packages);

  factory QueryResult.fromJson(Map<String, dynamic> map) =>
      _$QueryResultFromJson(map);

  Map<String, dynamic> toJson() => _$QueryResultToJson(this);
}
