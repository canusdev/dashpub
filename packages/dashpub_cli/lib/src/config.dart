import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:convert';

/// Configuration manager for Dashpub CLI.
///
/// Handles saving and loading the authentication token from `~/.dashpub`.
class DashpubConfig {
  static const _fileName = '.dashpub';
  final Directory? _homeDir;

  /// Creates a configuration manager.
  DashpubConfig({Directory? homeDir}) : _homeDir = homeDir;

  String get _configPath {
    if (_homeDir != null) {
      return p.join(_homeDir.path, _fileName);
    }
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    return p.join(home!, _fileName);
  }

  /// Saves the authentication token to the config file.
  Future<void> saveToken(String token) async {
    final file = File(_configPath);
    await file.writeAsString(jsonEncode({'token': token}));
  }

  /// Retrieves the stored authentication token.
  Future<String?> getToken() async {
    final file = File(_configPath);
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Deletes the stored authentication token (logout).
  Future<void> deleteToken() async {
    final file = File(_configPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
