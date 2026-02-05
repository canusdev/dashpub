/// Shared models and API client for the Dashpub ecosystem.
///
/// This library provides the core data structures and a [DashpubApiClient]
/// for communicating with the Dashpub server.
library dashpub_api;

import 'package:json_annotation/json_annotation.dart';

import 'src/models/user.dart';

export 'src/models/package.dart';
export 'src/models/user.dart';
export 'src/api_client.dart';

part 'dashpub_api.g.dart';

/// Response wrapper for a list of packages.
@JsonSerializable(explicitToJson: true)
class ListApi {
  final int count;
  final List<ListApiPackage> packages;

  /// Creates a listing response with [count] and [packages].
  ListApi(this.count, this.packages);

  /// Creates a [ListApi] from a JSON map.
  factory ListApi.fromJson(Map<String, dynamic> map) => _$ListApiFromJson(map);

  /// Converts this response to a JSON map.
  Map<String, dynamic> toJson() => _$ListApiToJson(this);
}

/// Represents a package in the list view.
@JsonSerializable(explicitToJson: true)
class ListApiPackage {
  final String name;
  final String? description;
  final List<String> tags;
  final String latest;
  final DateTime updatedAt;

  /// Creates a package listing item.
  ListApiPackage(
    this.name,
    this.description,
    this.tags,
    this.latest,
    this.updatedAt,
  );

  /// Creates a [ListApiPackage] from a JSON map.
  factory ListApiPackage.fromJson(Map<String, dynamic> map) =>
      _$ListApiPackageFromJson(map);

  /// Converts this package to a JSON map.
  Map<String, dynamic> toJson() => _$ListApiPackageToJson(this);
}

/// Represents a version in the detail view.
@JsonSerializable(explicitToJson: true)
class DetailViewVersion {
  final String version;
  final DateTime createdAt;

  /// Creates a version detail.
  DetailViewVersion(this.version, this.createdAt);

  /// Creates a [DetailViewVersion] from a JSON map.
  factory DetailViewVersion.fromJson(Map<String, dynamic> map) =>
      _$DetailViewVersionFromJson(map);

  /// Converts this version to a JSON map.
  Map<String, dynamic> toJson() => _$DetailViewVersionToJson(this);
}

/// Detailed view of a package for the web interface.
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

  /// Creates a detailed package view.
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

  /// Creates a [WebapiDetailView] from a JSON map.
  factory WebapiDetailView.fromJson(Map<String, dynamic> map) =>
      _$WebapiDetailViewFromJson(map);

  /// Converts this view to a JSON map.
  Map<String, dynamic> toJson() => _$WebapiDetailViewToJson(this);
}

/// Check out my dependency, yo.
@JsonSerializable(explicitToJson: true)
class WebapiDependency {
  final String name;
  final String version;
  final bool isLocal;
  final String? gitUrl;
  final String? hostedUrl;

  /// Creates a dependency item.
  WebapiDependency(
    this.name,
    this.version,
    this.isLocal,
    this.gitUrl,
    this.hostedUrl,
  );

  /// Creates a [WebapiDependency] from a JSON map.
  factory WebapiDependency.fromJson(Map<String, dynamic> json) =>
      _$WebapiDependencyFromJson(json);

  /// Converts this dependency to a JSON map.
  Map<String, dynamic> toJson() => _$WebapiDependencyToJson(this);
}

/// Response from an authentication request.
@JsonSerializable()
class AuthResponse {
  final String token;
  final User user;

  /// Creates an auth response with [token] and [user].
  AuthResponse(this.token, this.user);

  /// Creates an [AuthResponse] from a JSON map.
  factory AuthResponse.fromJson(Map<String, dynamic> map) =>
      _$AuthResponseFromJson(map);

  /// Converts this response to a JSON map.
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
