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

  LoginCommand({DashpubApiClient? client}) : _client = client {
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
      final config = DashpubConfig();
      await config.saveToken(response.token);
      print(
        'Successfully logged in as ${response.user.name ?? response.user.email}',
      );
    } catch (e) {
      print('Error: $e');
    }
  }
}
