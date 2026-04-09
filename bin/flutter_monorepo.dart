import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_monorepo/flutter_monorepo.dart';

const _validPlatforms = {'android', 'ios', 'web', 'linux', 'macos', 'windows'};

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('org',
        abbr: 'o',
        defaultsTo: 'com.example',
        help: 'Organization identifier (e.g., com.example)')
    ..addOption('state',
        abbr: 's',
        defaultsTo: 'getx',
        allowed: ['getx', 'riverpod', 'bloc', 'cubit'],
        help: 'State management framework')
    ..addOption('locales',
        abbr: 'l',
        defaultsTo: 'en,ar',
        help: 'Comma-separated locale codes (e.g., en,ar,es,fr)')
    ..addOption('platforms',
        abbr: 'p',
        defaultsTo: 'android,ios',
        help: 'Comma-separated platforms (android,ios,web,linux,macos,windows)')
    ..addFlag('git',
        defaultsTo: true,
        negatable: true,
        help: 'Initialize git repository with first commit')
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
    stdout.writeln('flutter_monorepo 1.0.0');
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

  // Parse & validate locales
  final locales = (args['locales'] as String)
      .split(',')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (locales.isEmpty) {
    stderr.writeln('Error: At least one locale is required.');
    exit(1);
  }

  // Parse & validate platforms
  final platforms = (args['platforms'] as String)
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  if (platforms.isEmpty) {
    stderr.writeln('Error: At least one platform is required.');
    exit(1);
  }
  for (final p in platforms) {
    if (!_validPlatforms.contains(p)) {
      stderr.writeln(
          'Error: Invalid platform "$p". Valid: ${_validPlatforms.join(', ')}');
      exit(1);
    }
  }

  final stateManagement =
      StateManagement.values.byName(args['state'] as String);

  final config = ProjectConfig(
    name: projectName,
    org: args['org'] as String,
    stateManagement: stateManagement,
    locales: locales,
    platforms: platforms,
    gitInit: args['git'] as bool,
  );

  final targetDir = Directory('${Directory.current.path}/$projectName');
  if (targetDir.existsSync()) {
    stderr.writeln('Error: Directory "$projectName" already exists.');
    exit(1);
  }

  stdout.writeln('');
  stdout.writeln('╔══════════════════════════════════════════════════╗');
  stdout.writeln('║  Flutter Monorepo Bootstrap                      ║');
  stdout.writeln('╠══════════════════════════════════════════════════╣');
  stdout.writeln('║  Project:    ${config.name}');
  stdout.writeln('║  State:      ${config.stateManagement.name}');
  stdout.writeln('║  Locales:    ${config.locales.join(', ')}');
  stdout.writeln('║  Platforms:  ${config.platforms.join(', ')}');
  stdout.writeln('║  Org:        ${config.org}');
  stdout.writeln('║  Git:        ${config.gitInit ? 'yes' : 'no'}');
  stdout.writeln('║  Path:       ${targetDir.path}');
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
  stdout.writeln(
      'Creates a production-ready Flutter monorepo with your chosen stack.');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(parser.usage);
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  flutter_monorepo my_app');
  stdout.writeln(
      '  flutter_monorepo my_app --state riverpod --locales en,es,fr');
  stdout.writeln(
      '  flutter_monorepo my_app --state bloc --platforms android,ios,web');
  stdout.writeln('  flutter_monorepo my_app --state cubit --no-git');
}
