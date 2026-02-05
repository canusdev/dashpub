import 'package:mongo_dart/mongo_dart.dart';
import 'package:intl/intl.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'meta_store.dart';

final packageCollection = 'packages';
final statsCollection = 'stats';
final userCollection = 'users';
final teamCollection = 'teams';
final settingsCollection = 'settings';

/// Implementation of [MetaStore] using MongoDB.
class MongoStore extends MetaStore {
  Db db;

  MongoStore(this.db);

  SelectorBuilder _selectByName(String name) => where.eq('name', name);

  Future<QueryResult> _queryPackagesBySelector(SelectorBuilder selector) async {
    final count = await db.collection(packageCollection).count(selector);
    final jsonList = await db
        .collection(packageCollection)
        .find(selector)
        .toList();
    final packages = jsonList.map((json) => Package.fromJson(json)).toList();
    return QueryResult(count, packages);
  }

  @override
  Future<Package?> queryPackage(String name) async {
    final json = await db
        .collection(packageCollection)
        .findOne(_selectByName(name));
    if (json == null) return null;
    return Package.fromJson(json);
  }

  @override
  Future<void> addVersion(
    String name,
    PackageVersion version, {
    bool? private,
    List<PackagePermission>? permissions,
  }) async {
    await db
        .collection(packageCollection)
        .update(
          _selectByName(name),
          modify
              .push('versions', version.toJson())
              .addToSet('uploaders', version.uploader)
              .setOnInsert('createdAt', version.createdAt)
              .setOnInsert('private', private ?? true)
              .setOnInsert(
                'permissions',
                permissions?.map((p) => p.toJson()).toList() ?? [],
              )
              .setOnInsert('download', 0)
              .set('updatedAt', version.createdAt),
          upsert: true,
        );
  }

  @override
  Future<void> addUploader(String name, String email) async {
    await db
        .collection(packageCollection)
        .update(_selectByName(name), modify.addToSet('uploaders', email));
  }

  @override
  Future<void> removeUploader(String name, String email) async {
    await db
        .collection(packageCollection)
        .update(_selectByName(name), modify.pull('uploaders', email));
  }

  @override
  void increaseDownloads(String name, String version) {
    var today = DateFormat('yyyyMMdd').format(DateTime.now());
    db
        .collection(packageCollection)
        .update(_selectByName(name), modify.inc('download', 1));
    db
        .collection(statsCollection)
        .update(_selectByName(name), modify.inc('d$today', 1));
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
  }) {
    final Map<String, dynamic> query = {};

    // Visibility filter
    if (user?.isAdmin != true) {
      query[r'$or'] = [
        {'private': false},
        if (user != null) ...[
          {
            'permissions': {
              r'$elemMatch': {'isTeam': false, 'uploaderId': user.id},
            },
          },
          {
            'permissions': {
              r'$elemMatch': {
                'uploaderId': {r'$in': user.teams},
                'isTeam': true,
              },
            },
          },
          {'uploaders': user.email}, // Legacy support
        ],
      ];
    }

    if (keyword != null) {
      query['name'] = {r'$regex': '.*$keyword.*', r'$options': 'i'};
    }
    if (uploader != null) {
      query['uploaders'] = uploader;
    }
    if (dependency != null) {
      query['versions'] = {
        r'$elemMatch': {
          'pubspec.dependencies.$dependency': {r'$exists': true},
        },
      };
    }

    print('DEBUG: queryPackages user=${user?.email} query=$query');

    var selector = where
        .sortBy(sort, descending: true)
        .limit(size)
        .skip(page * size);

    // Merge the query into the selector's `$query` map to ensure it's respected
    if (selector.map.containsKey(r'$query')) {
      (selector.map[r'$query'] as Map).addAll(query);
    } else {
      // Fallback if no modifiers are present (though sortBy is always there)
      selector.raw(query);
    }

    return _queryPackagesBySelector(selector);
  }

  @override
  Future<User?> queryUserByEmail(String email) async {
    final json = await db
        .collection(userCollection)
        .findOne(where.eq('email', email));
    if (json == null) return null;
    return User.fromJson(json);
  }

  @override
  Future<User?> queryUserById(String id) async {
    final json = await db
        .collection(userCollection)
        .findOne(where.eq('id', id));
    if (json == null) return null;
    return User.fromJson(json);
  }

  @override
  Future<User?> queryUserByToken(String token) async {
    final json = await db
        .collection(userCollection)
        .findOne(where.eq('token', token));
    if (json == null) return null;
    return User.fromJson(json);
  }

  @override
  Future<void> createUser(User user) async {
    await db.collection(userCollection).insert(user.toJson());
  }

  @override
  Future<void> updateUser(User user) async {
    await db
        .collection(userCollection)
        .update(where.eq('id', user.id), user.toJson());
  }

  @override
  Future<List<User>> queryUsers() async {
    final jsons = await db.collection(userCollection).find().toList();
    return jsons.map((json) => User.fromJson(json)).toList();
  }

  @override
  Future<int> countUsers() async {
    return await db.collection(userCollection).count();
  }

  @override
  Future<Team?> queryTeamById(String id) async {
    final json = await db
        .collection(teamCollection)
        .findOne(where.eq('id', id));
    if (json == null) return null;
    return Team.fromJson(json);
  }

  @override
  Future<void> createTeam(Team team) async {
    await db.collection(teamCollection).insert(team.toJson());
  }

  @override
  Future<void> updateTeam(Team team) async {
    await db
        .collection(teamCollection)
        .update(where.eq('id', team.id), team.toJson());
  }

  @override
  Future<List<Team>> queryTeams() async {
    final jsons = await db.collection(teamCollection).find().toList();
    return jsons.map((json) => Team.fromJson(json)).toList();
  }

  @override
  Future<GlobalSettings> getSettings() async {
    final json = await db.collection(settingsCollection).findOne();
    if (json == null) {
      return GlobalSettings(false, true);
    }
    return GlobalSettings.fromJson(json);
  }

  @override
  Future<void> updateSettings(GlobalSettings settings) async {
    await db
        .collection(settingsCollection)
        .update(where, settings.toJson(), upsert: true);
  }
}
