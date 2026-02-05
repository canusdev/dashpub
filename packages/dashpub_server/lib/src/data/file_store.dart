import 'dart:io';
import 'package:path/path.dart' as p;
import 'package_store.dart';

/// Implementation of [PackageStore] using the local file system.
class FileStore extends PackageStore {
  String baseDir;
  String Function(String name, String version)? getFilePath;

  FileStore(this.baseDir, {this.getFilePath});

  File _getTarballFile(String name, String version) {
    final filePath =
        getFilePath?.call(name, version) ?? '$name-$version.tar.gz';
    return File(p.join(baseDir, filePath));
  }

  @override
  Future<void> upload(String name, String version, List<int> content) async {
    var file = _getTarballFile(name, version);
    await file.create(recursive: true);
    await file.writeAsBytes(content);
  }

  @override
  Stream<List<int>> download(String name, String version) {
    return _getTarballFile(name, version).openRead();
  }

  Directory _getDocDir(String name, String version) {
    return Directory(p.join(baseDir, 'docs', name, version));
  }

  @override
  Future<void> uploadDocs(String name, String version, Directory docDir) async {
    final targetDir = _getDocDir(name, version);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    await _copyDirectory(docDir, targetDir);
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        var newDirectory = Directory(
          p.join(destination.absolute.path, p.basename(entity.path)),
        );
        await newDirectory.create();
        await _copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }

  @override
  Stream<List<int>> downloadDoc(String name, String version, String path) {
    final docDir = _getDocDir(name, version);
    final file = File(p.join(docDir.path, path));
    if (!file.existsSync()) {
      throw Exception('Doc file not found: $path');
    }
    return file.openRead();
  }
}
