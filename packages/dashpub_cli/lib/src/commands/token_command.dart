import 'package:args/command_runner.dart';
import 'package:dashpub_api/dashpub_api.dart';
import '../config.dart';

class TokenCommand extends Command {
  @override
  final name = 'token';
  @override
  final description = 'Manage API tokens for Dashpub.';

  final DashpubApiClient? _client;

  TokenCommand({DashpubApiClient? client}) : _client = client {
    argParser.addOption(
      'url',
      abbr: 'u',
      defaultsTo: 'http://localhost:4000',
      help: 'The Dashpub registry URL.',
    );
    argParser.addFlag(
      'generate',
      abbr: 'g',
      negatable: false,
      help: 'Generate a new API token.',
    );
  }

  @override
  Future<void> run() async {
    final url = argResults!['url'] as String;
    final generate = argResults!['generate'] as bool;
    final config = DashpubConfig();
    final currentToken = await config.getToken();

    if (currentToken == null) {
      print('Error: You must be logged in. Run "dashpub login" first.');
      return;
    }

    final client = _client ?? DashpubApiClient(url, token: currentToken);

    try {
      if (generate) {
        final newToken = await client.generateToken();
        print('New API Token generated successfully:');
        print('\n$newToken\n');
        print('You can use this token for standard pub client authentication:');
        print('  dart pub token add $url');
        print('And then paste the token when prompted.');
      } else {
        final user = await client.getMe();
        if (user.token != null) {
          print('Current API Token: ${user.token}');
        } else {
          print(
            'No API Token generated yet. Run "dashpub token --generate" to create one.',
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
