import 'dart:io';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

class Ignore {
  final List<Glob> _globs = [];

  Ignore(List<String> patterns) {
    for (var pattern in patterns) {
      pattern = pattern.trim();
      if (pattern.isEmpty || pattern.startsWith('#')) continue;

      // Handle directory specific patterns
      if (pattern.endsWith('/')) {
        pattern = '$pattern**';
      }

      // Handle root-relative patterns
      if (pattern.startsWith('/')) {
        pattern = pattern.substring(1);
      }

      try {
        _globs.add(Glob(pattern, context: p.Context(style: p.Style.posix)));
      } catch (e) {
        // Ignore invalid patterns
      }
    }
  }

  bool ignores(String path) {
    // Normalize path to posix for glob matching
    final posixPath = p.posix.joinAll(p.split(path));
    return _globs.any((glob) => glob.matches(posixPath));
  }

  static Future<Ignore> load() async {
    final pubignore = File('.pubignore');
    final gitignore = File('.gitignore');

    List<String> patterns = [];

    // Always ignore these
    patterns.addAll([
      '.git/**',
      '.dart_tool/**',
      '.pub/**',
      'build/**',
      '.DS_Store',
      'pubspec.lock',
    ]);

    if (await pubignore.exists()) {
      patterns.addAll(await pubignore.readAsLines());
    } else if (await gitignore.exists()) {
      patterns.addAll(await gitignore.readAsLines());
    }

    return Ignore(patterns);
  }
}
