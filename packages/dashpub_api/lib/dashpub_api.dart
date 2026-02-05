import 'package:json_annotation/json_annotation.dart';

import 'src/models/user.dart';

export 'src/models/package.dart';
export 'src/models/user.dart';
export 'src/api_client.dart';

part 'dashpub_api.g.dart';

@JsonSerializable(explicitToJson: true)
class ListApi {
  final int count;
  final List<ListApiPackage> packages;

  ListApi(this.count, this.packages);

  factory ListApi.fromJson(Map<String, dynamic> map) => _$ListApiFromJson(map);
  Map<String, dynamic> toJson() => _$ListApiToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ListApiPackage {
  final String name;
  final String? description;
  final List<String> tags;
  final String latest;
  final DateTime updatedAt;

  ListApiPackage(
    this.name,
    this.description,
    this.tags,
    this.latest,
    this.updatedAt,
  );

  factory ListApiPackage.fromJson(Map<String, dynamic> map) =>
      _$ListApiPackageFromJson(map);
  Map<String, dynamic> toJson() => _$ListApiPackageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DetailViewVersion {
  final String version;
  final DateTime createdAt;

  DetailViewVersion(this.version, this.createdAt);

  factory DetailViewVersion.fromJson(Map<String, dynamic> map) =>
      _$DetailViewVersionFromJson(map);

  Map<String, dynamic> toJson() => _$DetailViewVersionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WebapiDetailView {
  final String name;
  final String version;
  final String description;
  final String homepage;
  final List<String> uploaders;
  final DateTime createdAt;
  final String? readme;
  final String? changelog;
  final String? license;
  final List<DetailViewVersion> versions;
  final List<String?> authors;
  final List<WebapiDependency> dependencies;
  final List<String> tags;
  final bool? isPrivate;
  final List<String> topics;
  final String? repository;
  final String? issueTracker;
  final List<String>? platforms;

  WebapiDetailView(
    this.name,
    this.version,
    this.description,
    this.homepage,
    this.uploaders,
    this.createdAt,
    this.readme,
    this.changelog,
    this.license,
    this.versions,
    this.authors,
    this.dependencies,
    this.tags,
    this.isPrivate,
    this.topics,
    this.repository,
    this.issueTracker,
    this.platforms,
  );

  factory WebapiDetailView.fromJson(Map<String, dynamic> map) =>
      _$WebapiDetailViewFromJson(map);

  Map<String, dynamic> toJson() => _$WebapiDetailViewToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WebapiDependency {
  final String name;
  final String version;
  final bool isLocal;
  final String? gitUrl;
  final String? hostedUrl;

  WebapiDependency(
    this.name,
    this.version,
    this.isLocal,
    this.gitUrl,
    this.hostedUrl,
  );

  factory WebapiDependency.fromJson(Map<String, dynamic> json) =>
      _$WebapiDependencyFromJson(json);
  Map<String, dynamic> toJson() => _$WebapiDependencyToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final String token;
  final User user;

  AuthResponse(this.token, this.user);

  factory AuthResponse.fromJson(Map<String, dynamic> map) =>
      _$AuthResponseFromJson(map);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
