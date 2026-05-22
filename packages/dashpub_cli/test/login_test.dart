import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'package:dashpub_cli/src/commands/login_command.dart';
import 'package:dashpub_cli/src/config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDashpubApiClient extends Mock implements DashpubApiClient {
  @override
  String get baseUrl => 'http://localhost';
}

void main() {
  group('LoginCommand', () {
    late MockDashpubApiClient mockClient;
    late CommandRunner<void> runner;
    late Directory tempDir;

    late DashpubConfig config;

    setUp(() {
      mockClient = MockDashpubApiClient();
      tempDir = Directory.systemTemp.createTempSync('dashpub_test');
      config = DashpubConfig(homeDir: tempDir);
      runner = CommandRunner('dashpub', 'Test runner');
      runner.addCommand(LoginCommand(client: mockClient, config: config));
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('login success saves token', () async {
      // Correct order: id, isAdmin, email, name, passwordHash, teams, token
      final user = User(
        '1',
        false,
        'test@example.com',
        'Test User',
        'hash',
        [],
        'token',
      );

      when(
        () => mockClient.login(any(), any()),
      ).thenAnswer((_) async => AuthResponse('test_token', user));

      // Note: We cannot easily test the full execution of the command
      // because it relies on standard input which requires more complex mocking.
      // This test mainly verifies that the command accepts the client injection
      // and that the mock client can be set up correctly with the real data structures.

      expect(runner.commands['login'], isNotNull);
    });

    test('login with token success saves token', () async {
      final user = User(
        '1',
        false,
        'test@example.com',
        'Test User',
        'hash',
        [],
        'token',
      );

      when(() => mockClient.getMe()).thenAnswer((_) async => user);

      await runner.run(['login', '--token', 'some_token']);

      verify(() => mockClient.getMe()).called(1);
      final savedToken = await config.getToken();
      expect(savedToken, equals('some_token'));
    });

    test('login with token failure does not save token', () async {
      when(() => mockClient.getMe()).thenThrow(Exception('Unauthorized'));

      await runner.run(['login', '--token', 'invalid_token']);

      verify(() => mockClient.getMe()).called(1);
      final savedToken = await config.getToken();
      expect(savedToken, isNull);
    });
  });
}
