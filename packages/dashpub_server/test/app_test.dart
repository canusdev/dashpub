import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub/dashpub.dart';
import 'mocks.dart';

void main() {
  late DashpubApp app;
  late MockMetaStore metaStore;
  late MockPackageStore packageStore;

  setUp(() {
    metaStore = MockMetaStore();
    packageStore = MockPackageStore();
    app = DashpubApp(metaStore: metaStore, packageStore: packageStore);
  });

  group('API Routes', () {
    test('getVersions returns 404/redirect for non-existent package', () async {
      final request = shelf.Request(
        'GET',
        Uri.parse('http://localhost/api/packages/non_existent'),
      );
      final response = await app.router(request);

      expect(response.statusCode, 302);
      expect(response.headers['location'], contains('pub.dev'));
    });

    test('getVersions returns package versions', () async {
      final version = PackageVersion(
        '1.0.0',
        {'name': 'test_pkg'},
        null,
        null,
        null,
        null,
        null,
        DateTime.now(),
      );
      await metaStore.addVersion('test_pkg', version);

      final request = shelf.Request(
        'GET',
        Uri.parse('http://localhost/api/packages/test_pkg'),
      );
      final response = await app.router(request);

      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString());
      expect(body['name'], 'test_pkg');
      expect(body['versions'][0]['version'], '1.0.0');
    });

    test('download increases count and returns content', () async {
      final version = PackageVersion(
        '1.0.0',
        {'name': 'test_pkg'},
        null,
        null,
        null,
        null,
        null,
        DateTime.now(),
      );
      await metaStore.addVersion('test_pkg', version);
      await packageStore.upload('test_pkg', '1.0.0', [1, 2, 3]);

      final request = shelf.Request(
        'GET',
        Uri.parse('http://localhost/packages/test_pkg/versions/1.0.0.tar.gz'),
      );
      final response = await app.router(request);

      expect(response.statusCode, 200);
      expect(await response.read().expand((i) => i).toList(), [1, 2, 3]);

      final pkg = await metaStore.queryPackage('test_pkg');
      expect(pkg!.download, 1);
    });
  });

  group('WebAPI Routes', () {
    test('getPackages returns list', () async {
      final version = PackageVersion(
        '1.0.0',
        {'name': 'test_pkg', 'description': 'desc'},
        null,
        null,
        null,
        null,
        null,
        DateTime.now(),
      );
      await metaStore.addVersion('test_pkg', version);

      final request = shelf.Request(
        'GET',
        Uri.parse('http://localhost/webapi/packages'),
      );
      final response = await app.router(request);

      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString());
      expect(body['data']['count'], 1);
      expect(body['data']['packages'][0]['name'], 'test_pkg');
    });
  });
}
