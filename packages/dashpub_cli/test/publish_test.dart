import 'package:args/command_runner.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_cli/src/commands/publish_command.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDashpubApiClient extends Mock implements DashpubApiClient {
  @override
  String get baseUrl => 'http://localhost';
}

void main() {
  group('PublishCommand', () {
    late MockDashpubApiClient mockClient;
    late CommandRunner<void> runner;

    setUp(() {
      mockClient = MockDashpubApiClient();
      runner = CommandRunner('dashpub', 'Test runner');
      runner.addCommand(PublishCommand(client: mockClient));
    });

    test('publish command exists', () {
      expect(runner.commands['publish'], isNotNull);
    });
  });
}
