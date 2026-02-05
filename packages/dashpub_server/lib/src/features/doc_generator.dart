import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import '../data/package_store.dart';

class DocGenerator {
  final PackageStore packageStore;

  DocGenerator(this.packageStore);

  Future<void> generate(String name, String version) async {
    final tempDir = await Directory.systemTemp.createTemp('dashpub_doc_');
    try {
      // 1. Download tarball
      print('Generating docs for $name $version...');
      final tarballStream = packageStore.download(name, version);
      final tarballBytes = await tarballStream
          .expand((chunk) => chunk)
          .toList();

      // 2. Extract
      final tarballPath = path.join(tempDir.path, 'package.tar.gz');
      await File(tarballPath).writeAsBytes(tarballBytes);

      final tarBytes = GZipDecoder().decodeBytes(tarballBytes);
      final archive = TarDecoder().decodeBytes(tarBytes);
      final extractDir = Directory(path.join(tempDir.path, 'extracted'));
      await extractDir.create();

      for (var file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(path.join(extractDir.path, filename));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        }
      }

      // 3. Run dart doc
      // Find package root (where pubspec.yaml is)
      Directory workingDir = extractDir;
      final pubspecDetails = extractDir
          .listSync(recursive: true)
          .where((e) => e.path.endsWith('pubspec.yaml'));
      if (pubspecDetails.isNotEmpty) {
        // Use the directory of the first pubspec.yaml found
        workingDir = Directory(path.dirname(pubspecDetails.first.path));
      }

      print('Running dart pub get...');
      final pubGetResult = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: workingDir.path);

      if (pubGetResult.exitCode != 0) {
        print(
          'dart pub get failed: ${pubGetResult.stdout} \n ${pubGetResult.stderr}',
        );
      }

      final result = await Process.run('dart', [
        'doc',
        '.',
        '--output',
        'doc/api',
      ], workingDirectory: workingDir.path);

      if (result.exitCode != 0) {
        print('dart doc failed: ${result.stdout} \n ${result.stderr}');
        // Don't throw, just return. Docs are optional.
        return;
      }

      final docDir = Directory(path.join(workingDir.path, 'doc', 'api'));
      if (await docDir.exists()) {
        // 4. Upload
        print('Uploading docs for $name $version...');
        await packageStore.uploadDocs(name, version, docDir);
        print('Docs uploaded successfully.');
      } else {
        print('No doc/api directory generated.');
      }
    } catch (e, st) {
      print('Error generating docs: $e\n$st');
    } finally {
      await tempDir.delete(recursive: true);
    }
  }
}
