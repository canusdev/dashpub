import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:dashpub_api/dashpub_api.dart';
import '../config.dart';

import '../ignore.dart';

/// Command to publish a package to the Dashpub registry.
class PublishCommand extends Command {
  @override
  final name = 'publish';
  @override
  final description = 'Publish a package to the Dashpub registry.';

  final DashpubApiClient? _client;

  PublishCommand({DashpubApiClient? client}) : _client = client {
    argParser.addOption(
      'url',
      abbr: 'u',
      defaultsTo: 'http://localhost:4000',
      help: 'The Dashpub registry URL.',
    );
  }

  @override
  Future<void> run() async {
    final url = argResults!['url'] as String;
    final config = DashpubConfig();
    final token = await config.getToken();

    if (token == null) {
      print(
        'Error: You must be logged in to publish. Run "dashpub login" first.',
      );
      return;
    }

    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      print('Error: No pubspec.yaml found in the current directory.');
      return;
    }

    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = loadYaml(pubspecContent);
    final packageName = pubspec['name'] as String?;
    final packageVersion = pubspec['version'] as String?;

    if (packageName == null || packageVersion == null) {
      print('Error: Invalid pubspec.yaml. Name and version are required.');
      return;
    }

    // Validation warnings
    if (!File('LICENSE').existsSync() &&
        !File('LICENSE.md').existsSync() &&
        !File('LICENSE.txt').existsSync()) {
      print(
        'Warning: No LICENSE file found. It is recommended to include a license.',
      );
    }
    if (!File('CHANGELOG.md').existsSync()) {
      print(
        'Warning: No CHANGELOG.md file found. It is recommended to include a changelog.',
      );
    }
    if (!File('README.md').existsSync()) {
      print(
        'Warning: No README.md file found. It is recommended to include a readme.',
      );
    }

    final deps = pubspec['dependencies'] as Map?;
    if (deps != null) {
      for (final key in deps.keys) {
        final dep = deps[key];
        if (dep is Map && dep.containsKey('path')) {
          print(
            'Warning: Dependency "$key" has a local path dependency. This may break for other users.',
          );
        }
      }
    }

    print('Publishing $packageName $packageVersion to $url...');

    try {
      final bytes = await _createArchive();
      final client = _client ?? DashpubApiClient(url, token: token);
      await client.publish(bytes!);
      print('Package published successfully!');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<List<int>?> _createArchive() async {
    final encoder = TarFileEncoder();
    final tempDir = Directory.systemTemp.createTempSync('dashpub_publish');
    final tarFile = File(p.join(tempDir.path, 'package.tar'));

    encoder.create(tarFile.path);

    final currentDir = Directory.current;
    final ignore = await Ignore.load();

    for (final entity in currentDir.listSync(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: currentDir.path);

        if (ignore.ignores(relativePath)) {
          continue;
        }

        encoder.addFile(entity, relativePath);
      }
    }
    encoder.close();

    final tarBytes = tarFile.readAsBytesSync();
    final gzipped = GZipEncoder().encode(tarBytes);

    tempDir.deleteSync(recursive: true);

    return gzipped;
  }
}
