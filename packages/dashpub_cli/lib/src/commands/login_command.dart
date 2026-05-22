import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dashpub_api/dashpub_api.dart';
import '../config.dart';

/// Command to login to the Dashpub registry.
class LoginCommand extends Command {
  @override
  final name = 'login';
  @override
  final description = 'Login to Dashpub registry.';

  final DashpubApiClient? _client;
  final DashpubConfig? _config;

  LoginCommand({DashpubApiClient? client, DashpubConfig? config})
      : _client = client,
        _config = config {
    argParser.addOption(
      'url',
      abbr: 'u',
      defaultsTo: 'http://localhost:4000',
      help: 'The Dashpub registry URL.',
    );
    argParser.addOption(
      'token',
      abbr: 't',
      help: 'Direct login using an existing API token.',
    );
  }

  @override
  Future<void> run() async {
    var url = argResults!['url'] as String;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final token = argResults!['token'] as String?;
    final config = _config ?? DashpubConfig();

    if (token != null && token.isNotEmpty) {
      final client = _client ?? DashpubApiClient(url, token: token);
      try {
        final user = await client.getMe();
        await config.saveToken(token);
        print(
          'Successfully logged in as ${user.name ?? user.email}',
        );
      } catch (e) {
        print('Error verifying token: $e');
      }
      return;
    }

    stdout.write('Email: ');
    final email = stdin.readLineSync();
    if (email == null || email.isEmpty) return;

    stdout.write('Password: ');
    stdin.echoMode = false;
    final password = stdin.readLineSync();
    stdin.echoMode = true;
    stdout.writeln();

    if (password == null || password.isEmpty) return;

    final client = _client ?? DashpubApiClient(url);
    try {
      final response = await client.login(email, password);
      await config.saveToken(response.token);
      print(
        'Successfully logged in as ${response.user.name ?? response.user.email}',
      );
    } catch (e) {
      print('Error: $e');
    }
  }
}
