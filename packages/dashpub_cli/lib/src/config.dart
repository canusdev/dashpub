import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:convert';

class DashpubConfig {
  static const _fileName = '.dashpub';
  final Directory? _homeDir;

  DashpubConfig({Directory? homeDir}) : _homeDir = homeDir;

  String get _configPath {
    if (_homeDir != null) {
      return p.join(_homeDir.path, _fileName);
    }
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    return p.join(home!, _fileName);
  }

  Future<void> saveToken(String token) async {
    final file = File(_configPath);
    await file.writeAsString(jsonEncode({'token': token}));
  }

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

  Future<void> deleteToken() async {
    final file = File(_configPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
