import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_monorepo/flutter_monorepo.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('org',
        abbr: 'o',
        defaultsTo: 'com.example',
        help: 'Organization identifier (e.g., com.example)')
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show usage information')
    ..addFlag('version',
        negatable: false, help: 'Show version');

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('');
    _printUsage(parser);
    exit(1);
  }

  if (args['version'] as bool) {
    stdout.writeln('flutter_monorepo 0.1.0');
    exit(0);
  }

  if (args['help'] as bool || args.rest.isEmpty) {
    _printUsage(parser);
    exit(args['help'] as bool ? 0 : 1);
  }

  final projectName = args.rest.first;

  // Validate project name
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(projectName)) {
    stderr.writeln(
        'Error: Project name must be lowercase with underscores (e.g., my_app)');
    exit(1);
  }

  final config = ProjectConfig(
    name: projectName,
    org: args['org'] as String,
  );

  final targetDir = Directory('${Directory.current.path}/$projectName');
  if (targetDir.existsSync()) {
    stderr.writeln('Error: Directory "$projectName" already exists.');
    exit(1);
  }

  stdout.writeln('');
  stdout.writeln('╔══════════════════════════════════════════════════╗');
  stdout.writeln('║  Flutter GetX Monorepo Bootstrap                 ║');
  stdout.writeln('╠══════════════════════════════════════════════════╣');
  stdout.writeln('║  Project:  ${config.name}');
  stdout.writeln('║  App:      ${config.app}');
  stdout.writeln('║  Org:      ${config.org}');
  stdout.writeln('║  Path:     ${targetDir.path}');
  stdout.writeln('╚══════════════════════════════════════════════════╝');
  stdout.writeln('');

  final generator = Generator(config: config, rootPath: targetDir.path);

  try {
    await generator.run();
  } catch (e) {
    stderr.writeln('');
    stderr.writeln('Error: $e');
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage: flutter_monorepo <project_name> [options]');
  stdout.writeln('');
  stdout.writeln('Creates a production-ready Flutter GetX monorepo.');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(parser.usage);
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  flutter_monorepo my_app');
  stdout.writeln('  flutter_monorepo my_app --org com.mycompany');
}
