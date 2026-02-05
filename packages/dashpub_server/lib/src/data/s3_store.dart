import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:minio/minio.dart';
import 'package_store.dart';

class S3Store extends PackageStore {
  final Minio minio;
  final String bucket;
  final String? prefix;

  S3Store(this.minio, this.bucket, {this.prefix}) {
    supportsDownloadUrl = true;
  }

  String _getObjectKey(String name, String version) {
    var key = '$name/$version.tar.gz';
    if (prefix != null) {
      key = '$prefix/$key';
    }
    return key;
  }

  @override
  Future<void> upload(String name, String version, List<int> content) async {
    final key = _getObjectKey(name, version);
    final data = Uint8List.fromList(content);
    await minio.putObject(bucket, key, Stream.value(data), size: data.length);
  }

  @override
  Stream<List<int>> download(String name, String version) async* {
    final key = _getObjectKey(name, version);
    final stream = await minio.getObject(bucket, key);
    yield* stream;
  }

  @override
  Future<String> downloadUrl(String name, String version) async {
    final key = _getObjectKey(name, version);
    return minio.presignedGetObject(bucket, key, expires: 3600);
  }

  String _getDocObjectKey(String name, String version, String path) {
    var key = '$name/$version/doc/$path';
    if (prefix != null) {
      key = '$prefix/$key';
    }
    return key;
  }

  @override
  Future<void> uploadDocs(String name, String version, Directory docDir) async {
    await _uploadDirectory(name, version, docDir, docDir.path);
  }

  Future<void> _uploadDirectory(
    String name,
    String version,
    Directory source,
    String rootPath,
  ) async {
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        await _uploadDirectory(name, version, entity, rootPath);
      } else if (entity is File) {
        final relativePath = path.relative(entity.path, from: rootPath);
        final key = _getDocObjectKey(name, version, relativePath);

        final content = await entity.readAsBytes();
        final mimeType =
            lookupMimeType(entity.path) ?? 'application/octet-stream';

        await minio.putObject(
          bucket,
          key,
          Stream.value(content),
          size: content.length,
          metadata: {'content-type': mimeType},
        );
      }
    }
  }

  @override
  Stream<List<int>> downloadDoc(
    String name,
    String version,
    String path,
  ) async* {
    final key = _getDocObjectKey(name, version, path);
    final stream = await minio.getObject(bucket, key);
    yield* stream;
  }
}
