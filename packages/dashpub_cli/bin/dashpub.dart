import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dashpub_cli/src/commands/login_command.dart';
import 'package:dashpub_cli/src/commands/publish_command.dart';
import 'package:dashpub_cli/src/commands/token_command.dart';

void main(List<String> args) async {
  final runner = CommandRunner('dashpub', 'Dashpub CLI companion.')
    ..addCommand(LoginCommand())
    ..addCommand(PublishCommand())
    ..addCommand(TokenCommand());

  try {
    await runner.run(args);
  } catch (e) {
    if (e is UsageException) {
      print(e);
      exit(64);
    }
    print(e);
    exit(1);
  }
}
