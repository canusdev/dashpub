import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:mime/mime.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:shelf/shelf.dart' as shelf;
import 'package:path/path.dart' as path;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:pub_semver/pub_semver.dart' as semver;
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:crypto/crypto.dart';
import 'doc_generator.dart';
import '../data/meta_store.dart';
import '../data/package_store.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:archive/archive.dart';
import '../core/utils.dart';

part 'app.g.dart';

/// The main application logic for the Dashpub server.
///
/// This class handles the HTTP requests, routing, authentication, and
/// interaction with the metadata and package stores.
class DashpubApp {
  final MetaStore metaStore;
  final PackageStore packageStore;
  final String upstream;
  final String? staticAssetsPath;

  /// Creates a new instance of [DashpubApp].
  ///
  /// [metaStore] is used for storing metadata (users, package info).
  /// [packageStore] is used for storing the actual package files.
  /// [upstream] is the upstream pub server to proxy requests to (default: pub.dev).
  /// [staticAssetsPath] is the path to static assets (frontend) to serve.
  DashpubApp({
    required this.metaStore,
    required this.packageStore,
    this.upstream = 'https://pub.dev',
    this.staticAssetsPath,
  });

  static shelf.Response _okWithJson(Map<String, dynamic> data) =>
      shelf.Response.ok(
        json.encode(data),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );

  static shelf.Response _error(String message, [int status = 400]) {
    print('[ERROR] $status: $message');
    return shelf.Response(
      status,
      body: json.encode({'error': message}),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    );
  }

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  String _generateToken(String userId) {
    final jwt = JWT({'id': userId});
    return jwt.sign(SecretKey('dashpub-secret-key-replace-me'));
  }

  Future<User?> _getAuthenticatedUser(shelf.Request req) async {
    final authHeader = req.headers[HttpHeaders.authorizationHeader];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      // Check for CLI token
      final token = req.headers['dashpub-token'];
      if (token != null) {
        print('[AUTH] Checking custom dashpub-token');
        final user = await metaStore.queryUserByToken(token);
        if (user == null) {
          print('[AUTH] Custom token found but user is NULL');
        } else {
          print('[AUTH] Authenticated user via custom token: ${user.email}');
        }
        return user;
      }
      return null;
    }

    final token = authHeader.substring(7);
    try {
      final jwt = JWT.verify(token, SecretKey('dashpub-secret-key-replace-me'));
      final id = jwt.payload['id'] as String;
      final user = await metaStore.queryUserByEmail(id);
      if (user != null) {
        print('[AUTH] Authenticated user via JWT: ${user.email}');
      }
      return user;
    } catch (_) {
      // Fallback to API token check for standard pub client
      print('[AUTH] JWT verification failed, trying fallback API token');
      final user = await metaStore.queryUserByToken(token);
      if (user == null) {
        print('[AUTH] API token fallback also failed (token not found)');
      } else {
        print(
          '[AUTH] Authenticated user via API token fallback: ${user.email}',
        );
      }
      return user;
    }
  }

  /// Starts the HTTP server.
  ///
  /// Binds to [host] and [port].
  /// Returns the [HttpServer] instance.
  Future<HttpServer> serve([String host = '0.0.0.0', int port = 4000]) async {
    var pipeline = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addMiddleware(_corsMiddleware());

    shelf.Handler handler;
    if (staticAssetsPath != null) {
      final staticHandler = createStaticHandler(
        staticAssetsPath!,
        defaultDocument: 'index.html',
        serveFilesOutsidePath: true,
      );

      handler = (shelf.Request request) async {
        try {
          if (request.method == 'OPTIONS') {
            return shelf.Response.ok(null);
          }
          var response = await router(request);
          if (response.statusCode == 404) {
            final staticResponse = await staticHandler(request);
            if (staticResponse.statusCode == 404 &&
                !request.url.path.startsWith('api/') &&
                !request.url.path.startsWith('webapi/') &&
                !request.url.path.startsWith('doc/')) {
              // Serve index.html for SPA routing
              final indexFile = File(
                path.join(staticAssetsPath!, 'index.html'),
              );
              if (await indexFile.exists()) {
                return shelf.Response.ok(
                  indexFile.openRead(),
                  headers: {HttpHeaders.contentTypeHeader: 'text/html'},
                );
              }
            }
            return staticResponse;
          }
          return response;
        } catch (e, stack) {
          print('[SERVER ERROR] $e\n$stack');
          return shelf.Response.internalServerError(
            body: 'Internal Server Error: $e',
          );
        }
      };
    } else {
      handler = (request) async {
        try {
          if (request.method == 'OPTIONS') {
            return shelf.Response.ok(null);
          }
          return await router(request);
        } catch (e, stack) {
          print('[SERVER ERROR] $e\n$stack');
          return shelf.Response.internalServerError(
            body: 'Internal Server Error: $e',
          );
        }
      };
    }

    var server = await shelf_io.serve(pipeline.addHandler(handler), host, port);
    return server;
  }

  shelf.Middleware _corsMiddleware() {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      'Access-Control-Allow-Headers':
          'Origin, Content-Type, X-Auth-Token, Authorization, dashpub-token',
    };

    return (shelf.Handler innerHandler) {
      return (shelf.Request request) async {
        if (request.method == 'OPTIONS') {
          return shelf.Response.ok(null, headers: corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: corsHeaders);
      };
    };
  }

  bool _checkPermission(User? user, Package package, PermissionType required) {
    if (!package.private && required == PermissionType.read) return true;
    if (user == null) {
      print('[PERMISSION] Denied: User is NULL and package is private');
      return false;
    }

    // Check direct permissions
    final permission = package.permissions?.firstWhereOrNull(
      (p) => !p.isTeam && p.uploaderId == user.id,
    );
    if (permission != null && permission.type.index >= required.index) {
      return true;
    }

    // Check team permissions
    final teamPermission = package.permissions?.firstWhereOrNull(
      (p) => p.isTeam && user.teams.contains(p.uploaderId),
    );
    if (teamPermission != null && teamPermission.type.index >= required.index) {
      return true;
    }

    // Legacy uploader check (admin by default)
    if (package.uploaders?.contains(user.email) ?? false) return true;

    print(
      '[PERMISSION] Denied: User ${user.email} lacks ${required.name} permission for ${package.name}',
    );
    return false;
  }

  /// The `shelf_router` instance generated by build_runner.
  Router get router => _$DashpubAppRouter(this);

  /// Handles GET requests for package versions.
  ///
  /// Returns a JSON response containing the available versions for the given [name].
  /// If the package is not found locally, redirects to the [upstream] server.
  @Route.get('/api/packages/<name>')
  Future<shelf.Response> getVersions(shelf.Request req, String name) async {
    var package = await metaStore.queryPackage(name);

    if (package == null) {
      return shelf.Response.found(
        Uri.parse(upstream).resolve('/api/packages/$name').toString(),
      );
    }

    final user = await _getAuthenticatedUser(req);
    if (!_checkPermission(user, package, PermissionType.read)) {
      return _error('Unauthorized', 403);
    }

    package.versions.sort((a, b) {
      return semver.Version.prioritize(
        semver.Version.parse(a.version),
        semver.Version.parse(b.version),
      );
    });

    var versionMaps = package.versions.map((item) {
      return {
        'archive_url': req.requestedUri
            .resolve(
              '/packages/${package.name}/versions/${item.version}.tar.gz',
            )
            .toString(),
        'pubspec': item.pubspec,
        'version': item.version,
      };
    }).toList();

    return _okWithJson({
      'name': name,
      'latest': versionMaps.last,
      'versions': versionMaps,
    });
  }

  /// Handles GET requests for a specific package version.
  ///
  /// Returns a JSON response containing the details of the specified [version] of [name].
  @Route.get('/api/packages/<name>/versions/<version>')
  Future<shelf.Response> getVersion(
    shelf.Request req,
    String name,
    String version,
  ) async {
    version = Uri.decodeComponent(version);
    var package = await metaStore.queryPackage(name);
    if (package == null) {
      return shelf.Response.found(
        Uri.parse(
          upstream,
        ).resolve('/api/packages/$name/versions/$version').toString(),
      );
    }

    final user = await _getAuthenticatedUser(req);
    if (!_checkPermission(user, package, PermissionType.read)) {
      return _error('Unauthorized', 403);
    }

    var packageVersion = package.versions.firstWhereOrNull(
      (item) => item.version == version,
    );
    if (packageVersion == null) {
      return shelf.Response.notFound('Not Found');
    }

    return _okWithJson({
      'archive_url': req.requestedUri
          .resolve('/packages/$name/versions/$version.tar.gz')
          .toString(),
      'pubspec': packageVersion.pubspec,
      'version': version,
    });
  }

  /// Handles package download requests.
  ///
  /// Returns the package archive (`.tar.gz`) or a redirect to the download URL.
  @Route.get('/packages/<name>/versions/<version>.tar.gz')
  Future<shelf.Response> download(
    shelf.Request req,
    String name,
    String version,
  ) async {
    var package = await metaStore.queryPackage(name);
    if (package == null) {
      return shelf.Response.found(
        Uri.parse(
          upstream,
        ).resolve('/packages/$name/versions/$version.tar.gz').toString(),
      );
    }

    final user = await _getAuthenticatedUser(req);
    if (!_checkPermission(user, package, PermissionType.read)) {
      return _error('Unauthorized', 403);
    }

    metaStore.increaseDownloads(name, version);

    if (packageStore.supportsDownloadUrl) {
      return shelf.Response.found(
        await packageStore.downloadUrl(name, version),
      );
    } else {
      return shelf.Response.ok(
        packageStore.download(name, version),
        headers: {HttpHeaders.contentTypeHeader: 'application/octet-stream'},
      );
    }
  }

  /// Internal API to get a list of packages.
  ///
  /// Supports filtering by [page], [size], [sort], and [keyword] query parameters.
  @Route.get('/webapi/packages')
  Future<shelf.Response> getPackages(shelf.Request req) async {
    var params = req.requestedUri.queryParameters;
    var size = int.tryParse(params['size'] ?? '') ?? 10;
    var page = int.tryParse(params['page'] ?? '') ?? 0;
    var sort = params['sort'] ?? 'download';
    var q = params['q'];

    String? keyword;
    String? uploader;
    String? dependency;

    if (q != null) {
      if (q.startsWith('email:')) {
        uploader = q.substring(6).trim();
      } else if (q.startsWith('dependency:')) {
        dependency = q.substring(11).trim();
      } else {
        keyword = q;
      }
    }

    final user = await _getAuthenticatedUser(req);
    final settings = await metaStore.getSettings();

    if (!settings.publicAccess && user == null) {
      return _okWithJson({'data': ListApi(0, []).toJson()});
    }

    final result = await metaStore.queryPackages(
      size: size,
      page: page,
      sort: sort,
      keyword: keyword,
      uploader: uploader,
      dependency: dependency,
      user: user,
    );

    var data = ListApi(result.count, [
      for (var package in result.packages)
        ListApiPackage(
          package.name,
          package.versions.last.pubspec['description'] as String?,
          getPackageTags(package.versions.last.pubspec),
          package.versions.last.version,
          package.updatedAt,
        ),
    ]);

    return _okWithJson({'data': data.toJson()});
  }

  /// Internal API to get detailed information about a package.
  ///
  /// Returns the [WebapiDetailView] for the given [name] and [version].
  @Route.get('/webapi/package/<name>/<version>')
  Future<shelf.Response> getPackageDetail(
    shelf.Request req,
    String name,
    String version,
  ) async {
    var package = await metaStore.queryPackage(name);
    if (package == null) {
      return _okWithJson({'error': 'package not exists'});
    }

    final user = await _getAuthenticatedUser(req);
    final settings = await metaStore.getSettings();

    if (!settings.publicAccess && user == null) {
      return _error('Unauthorized', 401);
    }
    if (!_checkPermission(user, package, PermissionType.read)) {
      return _error('Unauthorized', 403);
    }

    PackageVersion? packageVersion;
    if (version == 'latest') {
      packageVersion = package.versions.last;
    } else {
      packageVersion = package.versions.firstWhereOrNull(
        (item) => item.version == version,
      );
    }
    if (packageVersion == null) {
      return _okWithJson({'error': 'version not exists'});
    }

    var versions = package.versions
        .map((v) => DetailViewVersion(v.version, v.createdAt))
        .toList();
    versions.sort((a, b) {
      return semver.Version.prioritize(
        semver.Version.parse(b.version),
        semver.Version.parse(a.version),
      );
    });

    var pubspec = packageVersion.pubspec;
    var authors = <String>[];
    if (pubspec['author'] != null) {
      authors.add(pubspec['author'] as String);
    } else if (pubspec['authors'] is List) {
      authors.addAll((pubspec['authors'] as List).cast<String>());
    }

    var depMap = (pubspec['dependencies'] as Map? ?? {})
        .cast<String, dynamic>();

    var dependencies = <WebapiDependency>[];
    for (var entry in depMap.entries) {
      final depName = entry.key;
      final value = entry.value;
      String version = 'any';
      String? gitUrl;
      String? hostedUrl;
      bool isLocal = false;

      if (value is String) {
        version = value;
      } else if (value is Map) {
        if (value.containsKey('git')) {
          final git = value['git'];
          if (git is String) {
            gitUrl = git;
          } else if (git is Map) {
            gitUrl = git['url']?.toString();
          }
        }
        if (value.containsKey('hosted')) {
          final hosted = value['hosted'];
          if (hosted is String) {
            hostedUrl = hosted;
          } else if (hosted is Map) {
            hostedUrl = hosted['url']?.toString();
          }
        }
        if (value.containsKey('version')) {
          version = value['version']?.toString() ?? 'any';
        }
      }

      // Check local if not git
      if (gitUrl == null) {
        final localPkg = await metaStore.queryPackage(depName);
        if (localPkg != null) {
          isLocal = true;
        }
      }

      dependencies.add(
        WebapiDependency(depName, version, isLocal, gitUrl, hostedUrl),
      );
    }

    String? repository = pubspec['repository'] as String?;
    String? issueTracker = pubspec['issue_tracker'] as String?;
    List<String>? platforms;

    if (pubspec['platforms'] is List) {
      platforms = (pubspec['platforms'] as List).cast<String>();
    } else if (pubspec['platforms'] is Map) {
      platforms = (pubspec['platforms'] as Map).keys.cast<String>().toList();
    }
    // Check flutter plugin platforms
    if (platforms == null && pubspec['flutter'] is Map) {
      final flutter = pubspec['flutter'] as Map;
      if (flutter['plugin'] is Map) {
        final plugin = flutter['plugin'] as Map;
        if (plugin['platforms'] is Map) {
          platforms = (plugin['platforms'] as Map).keys.cast<String>().toList();
        }
      }
    }

    var data = WebapiDetailView(
      package.name,
      packageVersion.version,
      packageVersion.pubspec['description'] ?? '',
      packageVersion.pubspec['homepage'] ?? '',
      package.uploaders ?? [],
      packageVersion.createdAt,
      packageVersion.readme,
      packageVersion.changelog,
      packageVersion.license,
      versions,
      authors,
      dependencies,
      getPackageTags(packageVersion.pubspec),
      package.private,
      (packageVersion.pubspec['topics'] as List?)?.cast<String>() ?? [],
      repository,
      issueTracker,
      platforms,
    );

    return _okWithJson({'data': data.toJson()});
  }

  @Route.get('/api/auth/initialized')
  Future<shelf.Response> isInitialized(shelf.Request req) async {
    final count = await metaStore.countUsers();
    return _okWithJson({'initialized': count > 0});
  }

  @Route.post('/api/auth/register')
  Future<shelf.Response> register(shelf.Request req) async {
    final body = json.decode(await req.readAsString());
    final email = body['email'] as String;
    final password = body['password'] as String;
    final name = body['name'] as String?;

    final existing = await metaStore.queryUserByEmail(email);
    if (existing != null) {
      return _error('User already exists');
    }

    final count = await metaStore.countUsers();
    final isAdmin = count == 0;

    if (!isAdmin) {
      final settings = await metaStore.getSettings();
      if (!settings.registrationOpen && settings.allowedEmailDomains.isEmpty) {
        return _error('Registration is closed', 403);
      }
      if (settings.allowedEmailDomains.isNotEmpty) {
        final domain = email.split('@').last.toLowerCase();
        if (!settings.allowedEmailDomains.contains(domain)) {
          return _error('Registration is restricted to allowed domains.', 403);
        }
      }
    }

    final user = User(
      email, // Using email as ID for now
      isAdmin,
      email,
      name,
      _hashPassword(password),
      [],
      null,
    );
    await metaStore.createUser(user);

    return _okWithJson(
      AuthResponse(
        _generateToken(user.id),
        User(
          user.id,
          user.isAdmin,
          user.email,
          user.name,
          user.passwordHash,
          user.teams,
          user.token,
        ),
      ).toJson(),
    );
  }

  @Route.post('/api/auth/login')
  Future<shelf.Response> login(shelf.Request req) async {
    final body = json.decode(await req.readAsString());
    final email = body['email'] as String;
    final password = body['password'] as String;

    final user = await metaStore.queryUserByEmail(email);
    if (user == null || user.passwordHash != _hashPassword(password)) {
      return _error('Invalid email or password', 401);
    }

    return _okWithJson(
      AuthResponse(
        _generateToken(user.id),
        User(
          user.id,
          user.isAdmin,
          user.email,
          user.name,
          user.passwordHash,
          user.teams,
          user.token,
        ),
      ).toJson(),
    );
  }

  @Route.get('/api/auth/me')
  Future<shelf.Response> me(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);
    return _okWithJson(
      User(
        user.id,
        user.isAdmin,
        user.email,
        user.name,
        user.passwordHash,
        user.teams,
        user.token,
      ).toJson(),
    );
  }

  @Route.post('/api/auth/token')
  Future<shelf.Response> generateToken(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);

    final token =
        'dashpub-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';
    final newUser = User(
      user.id,
      user.isAdmin,
      user.email,
      user.name,
      user.passwordHash,
      user.teams,
      token,
    );
    await metaStore.updateUser(newUser);

    return _okWithJson({'token': token});
  }

  @Route('PATCH', '/api/auth/me')
  Future<shelf.Response> updateMe(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);

    final body = json.decode(await req.readAsString());
    final newUser = User(
      user.id,
      user.isAdmin,
      user.email,
      body['name'] as String? ?? user.name,
      body['password'] != null
          ? _hashPassword(body['password'] as String)
          : user.passwordHash,
      user.teams,
      user.token,
    );
    await metaStore.updateUser(newUser);
    return _okWithJson(
      User(
        newUser.id,
        newUser.isAdmin,
        newUser.email,
        newUser.name,
        newUser.passwordHash,
        newUser.teams,
        newUser.token,
      ).toJson(),
    );
  }

  @Route.get('/api/settings')
  Future<shelf.Response> getSettings(shelf.Request req) async {
    final settings = await metaStore.getSettings();
    // Publicly accessible to allow loading site title/logo before auth
    return _okWithJson(settings.toJson());
  }

  @Route('PATCH', '/api/settings')
  Future<shelf.Response> updateSettings(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);
    if (!user.isAdmin) return _error('Forbidden', 403);

    final body = json.decode(await req.readAsString());
    final currentSettings = await metaStore.getSettings();
    final settings = GlobalSettings(
      body['publicAccess'] as bool? ?? currentSettings.publicAccess,
      body['defaultPrivate'] as bool? ?? currentSettings.defaultPrivate,
      siteTitle: body['siteTitle'] as String? ?? currentSettings.siteTitle,
      logoUrl: body['logoUrl'] as String? ?? currentSettings.logoUrl,
      faviconUrl: body['faviconUrl'] as String? ?? currentSettings.faviconUrl,
      registrationOpen:
          body['registrationOpen'] as bool? ?? currentSettings.registrationOpen,
      allowedEmailDomains:
          (body['allowedEmailDomains'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          currentSettings.allowedEmailDomains,
    );
    await metaStore.updateSettings(settings);
    return _okWithJson(settings.toJson());
  }

  @Route.get('/api/teams')
  Future<shelf.Response> getTeams(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);

    final teams = <Team>[];
    for (final teamId in user.teams) {
      final team = await metaStore.queryTeamById(teamId);
      if (team != null) {
        teams.add(Team(team.id, team.name, team.members));
      }
    }
    return _okWithJson({'teams': teams.map((t) => t.toJson()).toList()});
  }

  @Route.post('/api/teams')
  Future<shelf.Response> createTeam(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);

    final body = json.decode(await req.readAsString());
    final teamId = DateTime.now().millisecondsSinceEpoch.toString();
    final team = Team(teamId, body['name'] as String, [user.id]);
    await metaStore.createTeam(team);

    final updatedUser = User(
      user.id,
      user.isAdmin,
      user.email,
      user.name,
      user.passwordHash,
      [...user.teams, team.id],
      user.token,
    );
    await metaStore.updateUser(updatedUser);

    return _okWithJson(Team(team.id, team.name, team.members).toJson());
  }

  @Route.get('/api/admin/users')
  Future<shelf.Response> adminGetUsers(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null || !user.isAdmin) return _error('Unauthorized', 403);
    final users = await metaStore.queryUsers();
    return _okWithJson({
      'users': users
          .map(
            (u) => User(
              u.id,
              u.isAdmin,
              u.email,
              u.name,
              u.passwordHash,
              u.teams,
              u.token,
            ).toJson(),
          )
          .toList(),
    });
  }

  @Route.post('/api/admin/users')
  Future<shelf.Response> adminCreateUser(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null || !user.isAdmin) return _error('Unauthorized', 403);

    final body = json.decode(await req.readAsString());
    final email = body['email'] as String;
    final password = body['password'] as String;
    final name = body['name'] as String?;
    final isAdmin = body['isAdmin'] as bool? ?? false;

    if (await metaStore.queryUserByEmail(email) != null) {
      return _error('User already exists');
    }

    final newUser = User(
      email,
      isAdmin,
      email,
      name,
      _hashPassword(password),
      [],
      null,
    );
    await metaStore.createUser(newUser);

    return _okWithJson(
      User(
        newUser.id,
        newUser.isAdmin,
        newUser.email,
        newUser.name,
        newUser.passwordHash,
        newUser.teams,
        newUser.token,
      ).toJson(),
    );
  }

  @Route.get('/api/admin/teams')
  Future<shelf.Response> adminGetTeams(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null || !user.isAdmin) return _error('Unauthorized', 403);
    final teams = await metaStore.queryTeams();
    return _okWithJson({
      'teams': teams
          .map((t) => Team(t.id, t.name, t.members).toJson())
          .toList(),
    });
  }

  @Route.get('/api/teams/<id>')
  Future<shelf.Response> getTeam(shelf.Request req, String id) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);

    final team = await metaStore.queryTeamById(id);
    if (team == null) return _error('Team not found', 404);

    if (!user.isAdmin && !team.members.contains(user.id)) {
      return _error('Unauthorized', 403);
    }

    return _okWithJson(Team(team.id, team.name, team.members).toJson());
  }

  @Route.post('/api/teams/<id>/members/<email>')
  Future<shelf.Response> addTeamMember(
    shelf.Request req,
    String id,
    String email,
  ) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);

    final team = await metaStore.queryTeamById(id);
    if (team == null) return _error('Team not found', 404);

    if (!user.isAdmin && !team.members.contains(user.id)) {
      return _error('Unauthorized', 403);
    }

    final newMember = await metaStore.queryUserByEmail(email);
    if (newMember == null) return _error('User not found', 404);

    if (team.members.contains(newMember.id)) {
      return _error('User already in team', 400);
    }

    final updatedTeam = Team(team.id, team.name, [
      ...team.members,
      newMember.id,
    ]);
    await metaStore.updateTeam(updatedTeam);

    final updatedUser = User(
      newMember.id,
      newMember.isAdmin,
      newMember.email,
      newMember.name,
      newMember.passwordHash,
      [...newMember.teams, team.id],
      newMember.token,
    );
    await metaStore.updateUser(updatedUser);

    return _okWithJson(updatedTeam.toJson());
  }

  @Route.delete('/api/teams/<id>/members/<userId>')
  Future<shelf.Response> removeTeamMember(
    shelf.Request req,
    String id,
    String userId,
  ) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);

    final team = await metaStore.queryTeamById(id);
    if (team == null) return _error('Team not found', 404);

    if (!user.isAdmin && !team.members.contains(user.id)) {
      return _error('Unauthorized', 403);
    }

    if (!team.members.contains(userId)) {
      return _error('User not in team', 400);
    }

    final targetUser = await metaStore.queryUserById(userId);

    final updatedMembers = team.members.where((m) => m != userId).toList();
    final updatedTeam = Team(team.id, team.name, updatedMembers);
    await metaStore.updateTeam(updatedTeam);

    if (targetUser != null) {
      final updatedUserTeams = targetUser.teams.where((t) => t != id).toList();
      final updatedUser = User(
        targetUser.id,
        targetUser.isAdmin,
        targetUser.email,
        targetUser.name,
        targetUser.passwordHash,
        updatedUserTeams,
        targetUser.token,
      );
      await metaStore.updateUser(updatedUser);
    }

    return _okWithJson(updatedTeam.toJson());
  }

  @Route.get('/api/packages/versions/new')
  Future<shelf.Response> getUploadUrl(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);

    return _okWithJson({
      'url': req.requestedUri
          .resolve('/api/packages/versions/new-upload')
          .toString(),
      'fields': <String, dynamic>{},
    });
  }

  @Route.post('/api/packages/versions/new-upload')
  Future<shelf.Response> uploadPackage(shelf.Request req) async {
    final user = await _getAuthenticatedUser(req);
    if (user == null) return _error('Unauthorized', 401);

    final form = req.formData();
    if (form == null) return _error('Not a multipart request');

    final formData = await form.formData.toList();
    final file = formData.firstWhereOrNull((d) => d.name == 'file');

    if (file == null) return _error('No file uploaded');

    final content = await file.part.readBytes();
    final tarBytes = GZipDecoder().decodeBytes(content);
    final archive = TarDecoder().decodeBytes(tarBytes);

    final pubspecFile = archive.firstWhereOrNull(
      (f) => f.name == 'pubspec.yaml',
    );
    if (pubspecFile == null) return _error('No pubspec.yaml found in archive');

    final pubspecString = utf8.decode(pubspecFile.content as List<int>);
    final pubspec = loadYamlAsMap(pubspecString);
    if (pubspec == null) return _error('Invalid pubspec.yaml');

    final name = pubspec['name'] as String;
    final version = pubspec['version'] as String;

    var package = await metaStore.queryPackage(name);
    bool isNewPackage = package == null;

    if (!isNewPackage) {
      if (!_checkPermission(user, package, PermissionType.write)) {
        return _error('Unauthorized to upload this package', 403);
      }
      if (package.versions.any((v) => v.version == version)) {
        return _error('Version $version already exists', 400);
      }
    } else {
      // For new packages, we might want to check if the name is allowed
      // or if the user has permission to create new packages.
      // For now, we allow any authenticated user to create a new package.
    }

    await metaStore.getSettings();

    // Extract Readme and Changelog if they exist
    final readmeFile = archive.firstWhereOrNull(
      (f) => f.name.toLowerCase() == 'readme.md',
    );
    final changelogFile = archive.firstWhereOrNull(
      (f) => f.name.toLowerCase() == 'changelog.md',
    );
    final licenseFile = archive.firstWhereOrNull((f) {
      final name = f.name.toUpperCase();
      return name == 'LICENSE' ||
          name == 'LICENSE.MD' ||
          name == 'LICENSE.TXT' ||
          name == 'COPYING';
    });

    final readme = readmeFile != null
        ? utf8.decode(readmeFile.content as List<int>)
        : '';
    final changelog = changelogFile != null
        ? utf8.decode(changelogFile.content as List<int>)
        : '';
    final license = licenseFile != null
        ? utf8.decode(licenseFile.content as List<int>)
        : null;

    await packageStore.upload(name, version, content);
    final settings = await metaStore.getSettings();
    await metaStore.addVersion(
      name,
      PackageVersion(
        version,
        pubspec,
        pubspecString,
        user.email,
        readme,
        changelog,
        license,
        DateTime.now(),
      ),
      private: settings.defaultPrivate,
    );

    // Trigger doc generation in background
    DocGenerator(packageStore).generate(name, version).ignore();

    return _okWithJson({'success': true});
  }

  @Route.get('/api/packages/versions/new-upload-finish')
  Future<shelf.Response> uploadFinish(shelf.Request req) async {
    return _okWithJson({'success': true});
  }

  @Route.get('/doc/<name>/<version>/<path|.*>')
  Future<shelf.Response> getDoc(
    shelf.Request req,
    String name,
    String version,
    String path,
  ) async {
    if (version == 'latest') {
      final package = await metaStore.queryPackage(name);
      if (package == null) return _error('Package not found', 404);
      if (package.versions.isEmpty) return _error('No versions found', 404);

      // Sort versions to find latest (semver would be better, but assuming latest is known or simple sort)
      // Actually package.versions usually sorted by date or semantic?
      // For now, let's redirect to the exact version from UI, but supporting 'latest' is good.
      // Let's assume latest version is last in list or we sort it.
      // Simple approach: redirect to latest version.
      final latest = package.versions.last; // naive
      return shelf.Response.found('/doc/$name/${latest.version}/$path');
    }

    try {
      final stream = packageStore.downloadDoc(name, version, path);
      // determine content type
      var mimeType = lookupMimeType(path);
      mimeType ??=
          'text/html'; // default to html for dotfiles or unknowns in docs

      return shelf.Response.ok(
        stream,
        headers: {HttpHeaders.contentTypeHeader: mimeType},
      );
    } catch (e) {
      // If path fails, try finding an index.html
      // This handles cases like:
      // /doc/pkg/1.0.0/ -> serves /doc/pkg/1.0.0/index.html
      // /doc/pkg/1.0.0/guide -> serves /doc/pkg/1.0.0/guide/index.html
      String candidate = '';
      if (path == '' || path == '/') {
        candidate = 'index.html';
      } else if (!path.endsWith('index.html')) {
        candidate = path.endsWith('/')
            ? '${path}index.html'
            : '$path/index.html';
      }

      if (candidate.isNotEmpty) {
        try {
          final stream = packageStore.downloadDoc(name, version, candidate);
          // If we found index.html but the original request didn't end in /,
          // we should redirect to the version with / to ensure relative links work.
          if (!req.url.path.endsWith('/') && !path.endsWith('index.html')) {
            return shelf.Response.found(
              req.requestedUri
                  .replace(path: '${req.requestedUri.path}/')
                  .toString(),
            );
          }

          return shelf.Response.ok(
            stream,
            headers: {HttpHeaders.contentTypeHeader: 'text/html'},
          );
        } catch (_) {}
      }
      return _error('Doc not found', 404);
    }
  }
}
