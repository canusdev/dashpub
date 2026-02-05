import 'dart:async';
import 'dart:io';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub/dashpub.dart';
import 'package:collection/collection.dart';

class MockMetaStore implements MetaStore {
  final packages = <String, Package>{};
  final _users = <String, User>{};
  final _teams = <String, Team>{};
  GlobalSettings _settings = GlobalSettings(false, true);

  @override
  Future<Package?> queryPackage(String name) async => packages[name];

  @override
  Future<void> addVersion(
    String name,
    PackageVersion version, {
    bool? private,
    List<PackagePermission>? permissions,
  }) async {
    final package =
        packages[name] ??
        Package(
          name,
          [],
          private ?? false,
          [],
          permissions,
          DateTime.now(),
          DateTime.now(),
          0,
        );
    packages[name] = Package(
      name,
      [...package.versions, version],
      private ?? package.private,
      [
        ...package.uploaders ?? [],
        if (version.uploader != null) version.uploader!,
      ],
      permissions ?? package.permissions,
      package.createdAt,
      DateTime.now(),
      package.download,
    );
  }

  @override
  Future<void> addUploader(String name, String email) async {
    final package = packages[name]!;
    packages[name] = Package(
      name,
      package.versions,
      package.private,
      [...package.uploaders ?? [], email],
      package.permissions,
      package.createdAt,
      package.updatedAt,
      package.download,
    );
  }

  @override
  Future<void> removeUploader(String name, String email) async {
    final package = packages[name]!;
    packages[name] = Package(
      name,
      package.versions,
      package.private,
      (package.uploaders ?? []).where((e) => e != email).toList(),
      package.permissions,
      package.createdAt,
      package.updatedAt,
      package.download,
    );
  }

  @override
  void increaseDownloads(String name, String version) {
    final package = packages[name]!;
    packages[name] = Package(
      name,
      package.versions,
      package.private,
      package.uploaders,
      package.permissions,
      package.createdAt,
      package.updatedAt,
      (package.download ?? 0) + 1,
    );
  }

  @override
  Future<QueryResult> queryPackages({
    required int size,
    required int page,
    required String sort,
    String? keyword,
    String? uploader,
    String? dependency,
    User? user,
  }) async {
    var filtered = packages.values.toList();

    // Visibility filter
    filtered = filtered.where((package) {
      if (!package.private) return true;
      if (user == null) return false;

      // Check direct permissions
      final permission = package.permissions?.firstWhereOrNull(
        (p) => !p.isTeam && p.uploaderId == user.id,
      );
      if (permission != null) return true;

      // Check team permissions
      final teamPermission = package.permissions?.firstWhereOrNull(
        (p) => p.isTeam && user.teams.contains(p.uploaderId),
      );
      if (teamPermission != null) return true;

      // Legacy uploader check
      if (package.uploaders?.contains(user.email) ?? false) return true;

      return false;
    }).toList();

    if (keyword != null) {
      filtered = filtered.where((p) => p.name.contains(keyword)).toList();
    }
    return QueryResult(
      filtered.length,
      filtered.skip(page * size).take(size).toList(),
    );
  }

  @override
  Future<User?> queryUserByEmail(String email) async =>
      _users.values.firstWhereOrNull((u) => u.email == email);

  @override
  Future<User?> queryUserByToken(String token) async =>
      _users.values.firstWhereOrNull((u) => u.token == token);

  @override
  Future<User?> queryUserById(String id) async => _users[id];

  @override
  Future<void> createUser(User user) async => _users[user.id] = user;

  @override
  Future<void> updateUser(User user) async => _users[user.id] = user;

  @override
  Future<int> countUsers() async => _users.length;

  @override
  Future<List<User>> queryUsers() async => _users.values.toList();

  @override
  Future<Team?> queryTeamById(String id) async => _teams[id];

  @override
  Future<void> createTeam(Team team) async => _teams[team.id] = team;

  @override
  Future<void> updateTeam(Team team) async => _teams[team.id] = team;

  @override
  Future<List<Team>> queryTeams() async => _teams.values.toList();

  @override
  Future<GlobalSettings> getSettings() async => _settings;

  @override
  Future<void> updateSettings(GlobalSettings settings) async =>
      _settings = settings;
}

class MockPackageStore extends PackageStore {
  final contents = <String, List<int>>{};

  @override
  Future<void> uploadDocs(
    String name,
    String version,
    Directory docDir,
  ) async {}

  @override
  Stream<List<int>> downloadDoc(String name, String version, String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> upload(String name, String version, List<int> content) async {
    contents['$name-$version'] = content;
  }

  @override
  Stream<List<int>> download(String name, String version) {
    return Stream.value(contents['$name-$version']!);
  }
}
