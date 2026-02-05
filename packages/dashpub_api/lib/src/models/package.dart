import 'package:json_annotation/json_annotation.dart';

part 'package.g.dart';

DateTime _identity(DateTime x) => x;

/// Represents a specific version of a package.
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

/// Types of permissions a user can have on a package.
enum PermissionType { read, write, admin }

/// Represents a permission grant for a package.
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

/// Represents a Dart package.
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

/// Represents a paginated list of packages.
@JsonSerializable()
class QueryResult {
  final int count;
  final List<Package> packages;

  QueryResult(this.count, this.packages);

  factory QueryResult.fromJson(Map<String, dynamic> map) =>
      _$QueryResultFromJson(map);

  Map<String, dynamic> toJson() => _$QueryResultToJson(this);
}
