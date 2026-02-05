import 'package:test/test.dart';
import 'package:dashpub_api/dashpub_api.dart';

void main() {
  group('ListApi', () {
    test('serialization', () {
      final packages = [
        ListApiPackage(
          'test_package',
          'A test package',
          ['flutter'],
          '1.0.0',
          DateTime(2023, 1, 1),
        ),
      ];
      final listApi = ListApi(1, packages);
      final json = listApi.toJson();

      expect(json['count'], 1);
      expect(json['packages'], isList);
      expect(json['packages'][0]['name'], 'test_package');
    });

    test('deserialization', () {
      final json = {
        'count': 1,
        'packages': [
          {
            'name': 'test_package',
            'description': 'A test package',
            'tags': ['flutter'],
            'latest': '1.0.0',
            'updatedAt': '2023-01-01T00:00:00.000',
          },
        ],
      };
      final listApi = ListApi.fromJson(json);

      expect(listApi.count, 1);
      expect(listApi.packages[0].name, 'test_package');
      expect(listApi.packages[0].updatedAt, DateTime(2023, 1, 1));
    });
  });

  group('WebapiDetailView', () {
    test('serialization', () {
      final detail = WebapiDetailView(
        'test_package',
        '1.0.0',
        'A test package',
        'https://example.com',
        ['uploader@example.com'],
        DateTime(2023, 1, 1),
        '# Readme',
        '# Changelog',
        null, // license
        [DetailViewVersion('1.0.0', DateTime(2023, 1, 1))],
        ['Author Name'],
        [WebapiDependency('path', 'any', false, null, null)],
        ['flutter'],
        false,
        ['topic1'],
        'repo',
        'issue_tracker',
        ['android'],
      );
      final json = detail.toJson();

      expect(json['name'], 'test_package');
      expect(json['version'], '1.0.0');
      expect(json['authors'], contains('Author Name'));
    });

    test('deserialization', () {
      final json = {
        'name': 'test_package',
        'version': '1.0.0',
        'description': 'A test package',
        'homepage': 'https://example.com',
        'uploaders': ['uploader@example.com'],
        'createdAt': '2023-01-01T00:00:00.000',
        'readme': '# Readme',
        'changelog': '# Changelog',
        'versions': [
          {'version': '1.0.0', 'createdAt': '2023-01-01T00:00:00.000'},
        ],
        'authors': ['Author Name'],
        'dependencies': [
          {'name': 'path', 'version': 'any', 'isLocal': false, 'gitUrl': null},
        ],
        'tags': ['flutter'],
        'topics': ['topic1'],
      };
      final detail = WebapiDetailView.fromJson(json);

      expect(detail.name, 'test_package');
      expect(detail.version, '1.0.0');
      expect(detail.versions.length, 1);
    });
  });
}
