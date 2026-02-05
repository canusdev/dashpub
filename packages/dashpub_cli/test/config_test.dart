import 'dart:io';

import 'package:dashpub_cli/src/config.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('DashpubConfig', () {
    late Directory tempDir;
    late DashpubConfig config;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dashpub_test');
      config = DashpubConfig(homeDir: tempDir);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('saveToken writes token to file', () async {
      await config.saveToken('test_token');
      final file = File(p.join(tempDir.path, '.dashpub'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('"token":"test_token"'));
    });

    test('getToken reads token from file', () async {
      final file = File(p.join(tempDir.path, '.dashpub'));
      file.writeAsStringSync('{"token": "test_token"}');

      final token = await config.getToken();
      expect(token, equals('test_token'));
    });

    test('getToken returns null if file does not exist', () async {
      final token = await config.getToken();
      expect(token, isNull);
    });
  });
}
