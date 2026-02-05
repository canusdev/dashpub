import 'dart:async';
import 'dart:io';

abstract class PackageStore {
  bool supportsDownloadUrl = false;

  FutureOr<String> downloadUrl(String name, String version) {
    throw 'downloadUri not implemented';
  }

  Stream<List<int>> download(String name, String version) {
    throw 'download not implemented';
  }

  Future<void> upload(String name, String version, List<int> content);

  Future<void> uploadDocs(String name, String version, Directory docDir);

  Stream<List<int>> downloadDoc(String name, String version, String path) {
    throw 'downloadDoc not implemented';
  }
}
