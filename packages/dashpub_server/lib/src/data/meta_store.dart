import 'package:dashpub_api/dashpub_api.dart';

abstract class MetaStore {
  Future<Package?> queryPackage(String name);

  Future<void> addVersion(
    String name,
    PackageVersion version, {
    bool? private,
    List<PackagePermission>? permissions,
  });

  Future<void> addUploader(String name, String email);

  Future<void> removeUploader(String name, String email);

  void increaseDownloads(String name, String version);

  Future<QueryResult> queryPackages({
    required int size,
    required int page,
    required String sort,
    String? keyword,
    String? uploader,
    String? dependency,
    User? user,
  });

  // User management
  Future<User?> queryUserByEmail(String email);
  Future<User?> queryUserByToken(String token);
  Future<User?> queryUserById(String id);
  Future<void> createUser(User user);
  Future<void> updateUser(User user);
  Future<List<User>> queryUsers();
  Future<int> countUsers();

  // Team management
  Future<Team?> queryTeamById(String id);
  Future<void> createTeam(Team team);
  Future<void> updateTeam(Team team);
  Future<List<Team>> queryTeams();

  // Settings
  Future<GlobalSettings> getSettings();
  Future<void> updateSettings(GlobalSettings settings);
}
