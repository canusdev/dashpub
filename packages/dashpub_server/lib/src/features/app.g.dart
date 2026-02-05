// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app.dart';

// **************************************************************************
// ShelfRouterGenerator
// **************************************************************************

Router _$DashpubAppRouter(DashpubApp service) {
  final router = Router();
  router.add('GET', r'/api/packages/<name>', service.getVersions);
  router.add(
    'GET',
    r'/api/packages/<name>/versions/<version>',
    service.getVersion,
  );
  router.add(
    'GET',
    r'/packages/<name>/versions/<version>.tar.gz',
    service.download,
  );
  router.add('GET', r'/webapi/packages', service.getPackages);
  router.add(
    'GET',
    r'/webapi/package/<name>/<version>',
    service.getPackageDetail,
  );
  router.add('POST', r'/api/auth/register', service.register);
  router.add('POST', r'/api/auth/login', service.login);
  router.add('GET', r'/api/auth/me', service.me);
  router.add('POST', r'/api/auth/token', service.generateToken);
  router.add('PATCH', r'/api/auth/me', service.updateMe);
  router.add('GET', r'/api/settings', service.getSettings);
  router.add('PATCH', r'/api/settings', service.updateSettings);
  router.add('GET', r'/api/teams', service.getTeams);
  router.add('POST', r'/api/teams', service.createTeam);
  return router;
}
