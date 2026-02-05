import 'dart:async';
import 'dart:io';

/// Interface for storing package files (tarballs).
abstract class PackageStore {
  /// Whether to support download url.
  bool supportsDownloadUrl = false;

  /// Returns true if this store supports generating direct download URLs.
  FutureOr<String> downloadUrl(String name, String version) {
    throw 'downloadUri not implemented';
  }

  /// Downloads the package tarball as a stream of bytes.
  Stream<List<int>> download(String name, String version) {
    throw 'download not implemented';
  }

  /// Uploads a package tarball.
  Future<void> upload(String name, String version, List<int> content);

  /// Uploads package documentation.
  Future<void> uploadDocs(String name, String version, Directory docDir);

  /// Downloads a specific documentation file.
  Stream<List<int>> downloadDoc(String name, String version, String path) {
    throw 'downloadDoc not implemented';
  }
}
