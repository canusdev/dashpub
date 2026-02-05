import 'package:dashpub_api/dashpub_api.dart';

/// Interface for storing metadata about packages, users, and teams.
abstract class MetaStore {
  /// Queries a package by [name].
  Future<Package?> queryPackage(String name);

  /// Adds a new version to a package.
  ///
  /// If the package does not exist, it will be created.
  Future<void> addVersion(
    String name,
    PackageVersion version, {
    bool? private,
    List<PackagePermission>? permissions,
  });

  /// Adds a user as an uploader to a package.
  Future<void> addUploader(String name, String email);

  /// Removes a user from the package uploaders list.
  Future<void> removeUploader(String name, String email);

  /// Increments the download count for a version.
  void increaseDownloads(String name, String version);

  /// Queries packages with filtering and pagination.
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

  /// Finds a user by email.
  Future<User?> queryUserByEmail(String email);

  /// Finds a user by their API token.
  Future<User?> queryUserByToken(String token);

  /// Finds a user by their ID.
  Future<User?> queryUserById(String id);

  /// Creates a new user.
  Future<void> createUser(User user);

  /// Updates an existing user.
  Future<void> updateUser(User user);

  /// Returns a list of all users.
  Future<List<User>> queryUsers();

  /// Returns the total number of users.
  Future<int> countUsers();

  // Team management

  /// Finds a team by its ID.
  Future<Team?> queryTeamById(String id);

  /// Creates a new team.
  Future<void> createTeam(Team team);

  /// Updates an existing team.
  Future<void> updateTeam(Team team);

  /// Returns a list of all teams.
  Future<List<Team>> queryTeams();

  // Settings

  /// Retrieves the global server settings.
  Future<GlobalSettings> getSettings();

  /// Updates the global server settings.
  Future<void> updateSettings(GlobalSettings settings);
}
