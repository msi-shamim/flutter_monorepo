import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_monorepo/flutter_monorepo.dart';

const _validPlatforms = {'android', 'ios', 'web', 'linux', 'macos', 'windows'};

/// Shorthand accepted by `--platforms` meaning every entry in [_validPlatforms].
const _allPlatforms = 'all';

void main(List<String> arguments) async {
  // ── Subcommands ────────────────────────────────────────
  if (arguments.isNotEmpty && arguments.first == 'doctor') {
    await _runDoctor(arguments.skip(1).toList());
    return;
  }
  if (arguments.isNotEmpty && arguments.first == 'workflow') {
    _runWorkflow(arguments.skip(1).toList());
    return;
  }

  // ── Create (default) ───────────────────────────────────
  await _runCreate(arguments);
}

// ═════════════════════════════════════════════════════════
// ── DOCTOR ───────────────────────────────────────────────
// ═════════════════════════════════════════════════════════

Future<void> _runDoctor(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'fix',
      defaultsTo: false,
      negatable: false,
      help: 'Auto-fix missing directories and files',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show doctor usage');

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('');
    stderr.writeln('Usage: flutter_monorepo doctor [options]');
    stderr.writeln(parser.usage);
    exit(1);
  }

  if (args['help'] as bool) {
    stdout.writeln('Usage: flutter_monorepo doctor [options]');
    stdout.writeln('');
    stdout.writeln(
      'Checks the current monorepo structure and reports missing items.',
    );
    stdout.writeln('Run this from inside a generated monorepo root directory.');
    stdout.writeln('');
    stdout.writeln('Options:');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final doctor = Doctor(
    rootPath: Directory.current.path,
    fix: args['fix'] as bool,
  );

  final allGood = await doctor.run();
  exit(allGood ? 0 : 1);
}

// ═════════════════════════════════════════════════════════
// ── WORKFLOW ─────────────────────────────────────────────
// ═════════════════════════════════════════════════════════

const _workflowFlows = {'a', 'b', 'c'};

void _runWorkflow(List<String> arguments) {
  final flow = arguments.isNotEmpty ? arguments.first.toLowerCase() : null;

  if (flow == '--help' || flow == '-h') {
    _printWorkflowUsage(stdout);
    exit(0);
  }

  // Falling through to the overview for any input made a typo indistinguishable
  // from a flow that ran.
  if (flow != null && !_workflowFlows.contains(flow)) {
    stderr.writeln('Error: Unknown workflow "${arguments.first}".');
    stderr.writeln('');
    _printWorkflowUsage(stderr);
    exit(1);
  }

  final config = detectProjectConfig(Directory.current.path);
  if (config != null) {
    stdout.writeln('→ Detected: ${config.stateManagement.name}');
  }
  Workflow().run(flow, config: config);
}

void _printWorkflowUsage(IOSink out) {
  out.writeln('Usage: flutter_monorepo workflow [a|b|c]');
  out.writeln('');
  out.writeln('Shows development workflow guides. Run from inside a generated');
  out.writeln('project for instructions tailored to its state management.');
  out.writeln('');
  out.writeln('  (no argument)  Overview of all workflows');
  out.writeln('  a              Component design flow');
  out.writeln('  b              Screen design flow');
  out.writeln('  c              Business logic flow');
}

// ═════════════════════════════════════════════════════════
// ── CREATE ───────────────────────────────────────────────
// ═════════════════════════════════════════════════════════

Future<void> _runCreate(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'org',
      abbr: 'o',
      defaultsTo: 'com.example',
      help: 'Organization identifier (e.g., com.example)',
    )
    ..addOption(
      'state',
      abbr: 's',
      defaultsTo: 'getx',
      allowed: ['getx', 'riverpod', 'bloc', 'cubit'],
      help: 'State management framework',
    )
    ..addOption(
      'locales',
      abbr: 'l',
      defaultsTo: 'en,ar',
      help: 'Comma-separated locale codes (e.g., en,ar,es,fr)',
    )
    ..addOption(
      'platforms',
      abbr: 'p',
      defaultsTo: 'android,ios',
      help:
          'Comma-separated platforms, or "all" '
          '(android,ios,web,linux,macos,windows)',
    )
    ..addOption(
      'http',
      defaultsTo: 'dio',
      allowed: ['dio', 'http', 'chopper'],
      help: 'HTTP client library',
    )
    ..addOption(
      'license',
      defaultsTo: 'proprietary',
      allowed: LicenseType.cliNames,
      help: 'License type for the project',
    )
    ..addOption(
      'ci',
      defaultsTo: CiProvider.none.cliName,
      allowed: CiProvider.cliNames,
      help: 'CI pipeline to generate (--github implies github)',
    )
    ..addFlag(
      'github',
      defaultsTo: false,
      negatable: true,
      help: 'Generate GitHub community files (.github/ templates, CI)',
    )
    ..addFlag(
      'git',
      defaultsTo: true,
      negatable: true,
      help: 'Initialize git repository with first commit',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information',
    )
    ..addFlag('version', negatable: false, help: 'Show version');

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
    stdout.writeln('flutter_monorepo $packageVersion');
    exit(0);
  }

  if (args['help'] as bool) {
    _printUsage(parser);
    exit(0);
  }

  if (args.rest.isEmpty) {
    stderr.writeln('Error: A project name is required.');
    stderr.writeln('');
    _printUsage(parser);
    exit(1);
  }

  if (args.rest.length > 1) {
    stderr.writeln(
      'Error: Expected one project name but got ${args.rest.length}: '
      '${args.rest.join(', ')}',
    );
    stderr.writeln('');
    stderr.writeln(
      'If the name contains spaces, quote it — though project '
      'names must be lowercase with underscores.',
    );
    exit(1);
  }

  final projectName = args.rest.first;

  // Validate project name
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(projectName)) {
    stderr.writeln(
      'Error: Project name must be lowercase with underscores (e.g., my_app)',
    );
    exit(1);
  }

  // Parse & validate locales
  final locales = <String>[];
  for (final raw in (args['locales'] as String).split(',')) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    final normalized = _normalizeLocale(trimmed);
    if (normalized == null) {
      stderr.writeln(
        'Error: Invalid locale "$trimmed". Expected a language code '
        'optionally followed by a region, e.g. en, pt_BR or zh-Hans.',
      );
      exit(1);
    }
    locales.add(normalized);
  }
  if (locales.isEmpty) {
    stderr.writeln('Error: At least one locale is required.');
    exit(1);
  }

  // Parse & validate platforms
  final requested = (args['platforms'] as String)
      .split(',')
      .map((p) => p.trim().toLowerCase())
      .where((p) => p.isNotEmpty)
      .toList();
  if (requested.isEmpty) {
    stderr.writeln('Error: At least one platform is required.');
    exit(1);
  }

  // `all` is a shorthand for every supported platform. Accepted only on its
  // own, because "all,web" has no meaning worth guessing at.
  final List<String> platforms;
  if (requested.contains(_allPlatforms)) {
    if (requested.length > 1) {
      stderr.writeln(
        'Error: "$_allPlatforms" cannot be combined with other platforms.',
      );
      exit(1);
    }
    platforms = _validPlatforms.toList();
  } else {
    for (final p in requested) {
      if (!_validPlatforms.contains(p)) {
        stderr.writeln(
          'Error: Invalid platform "$p". '
          'Valid: ${_validPlatforms.join(', ')}, or "$_allPlatforms".',
        );
        exit(1);
      }
    }
    platforms = requested;
  }

  final stateManagement = StateManagement.values.byName(
    args['state'] as String,
  );
  final httpClient = HttpClient.values.byName(args['http'] as String);
  final licenseType = LicenseType.fromCliName(args['license'] as String);
  final githubFiles = args['github'] as bool;

  // --github has always generated a workflow, so it keeps implying GitHub
  // Actions. An explicit --ci wins, which is what lets --github --ci gitlab
  // produce community files on GitHub with the pipeline on GitLab.
  final ci = args.wasParsed('ci')
      ? CiProvider.fromCliName(args['ci'] as String)
      : (githubFiles ? CiProvider.github : CiProvider.none);

  final config = ProjectConfig(
    name: projectName,
    org: args['org'] as String,
    stateManagement: stateManagement,
    httpClient: httpClient,
    licenseType: licenseType,
    locales: locales,
    platforms: platforms,
    gitInit: args['git'] as bool,
    githubFiles: githubFiles,
    ci: ci,
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
  stdout.writeln('║  HTTP:       ${config.httpClient.name}');
  stdout.writeln('║  Locales:    ${config.locales.join(', ')}');
  stdout.writeln('║  Platforms:  ${config.platforms.join(', ')}');
  stdout.writeln('║  Org:        ${config.org}');
  stdout.writeln('║  License:    ${config.licenseType.displayName}');
  stdout.writeln('║  Git:        ${config.gitInit ? 'yes' : 'no'}');
  stdout.writeln('║  GitHub:     ${config.githubFiles ? 'yes' : 'no'}');
  stdout.writeln('║  CI:         ${config.ci.cliName}');
  stdout.writeln('║  Path:       ${targetDir.path}');
  stdout.writeln('╚══════════════════════════════════════════════════╝');
  stdout.writeln('');

  final generator = Generator(config: config, rootPath: targetDir.path);

  try {
    final ok = await generator.run();
    if (!ok) exit(1);
  } catch (e) {
    stderr.writeln('');
    stderr.writeln('Error: $e');
    stderr.writeln('');
    stderr.writeln('A partial project may remain at ${targetDir.path}.');
    stderr.writeln('Delete it before re-running this command.');
    exit(1);
  }
}

/// Normalizes a `--locales` entry to the form the templates and ARB files use.
///
/// Accepts `en`, `pt-BR` and `pt_BR`, returning `en` and `pt_BR`. Returns null
/// for anything that is not a language code with an optional region subtag —
/// such input previously reached the templates and produced Dart identifiers
/// like `locale_en-US`, which do not parse.
String? _normalizeLocale(String input) {
  final match = RegExp(
    r'^([a-zA-Z]{2,3})(?:[-_]([a-zA-Z]{2,4}|\d{3}))?$',
  ).firstMatch(input);
  if (match == null) return null;

  final language = match.group(1)!.toLowerCase();
  final region = match.group(2);
  if (region == null) return language;

  // Script subtags are title case (Hans), region subtags upper case (BR).
  final normalizedRegion = region.length == 4
      ? _titleCase(region)
      : region.toUpperCase();
  return '${language}_$normalizedRegion';
}

String _titleCase(String value) =>
    value[0].toUpperCase() + value.substring(1).toLowerCase();

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage: flutter_monorepo <project_name> [options]');
  stdout.writeln('       flutter_monorepo doctor [--fix]');
  stdout.writeln('       flutter_monorepo workflow [a|b|c]');
  stdout.writeln('');
  stdout.writeln(
    'Creates a production-ready Flutter monorepo with your chosen stack.',
  );
  stdout.writeln('');
  stdout.writeln('Commands:');
  stdout.writeln('  <project_name>   Create a new monorepo');
  stdout.writeln(
    '  doctor            Check structure integrity of current monorepo',
  );
  stdout.writeln('  workflow [a|b|c]  Show development workflow guides');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(parser.usage);
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  flutter_monorepo my_app');
  stdout.writeln(
    '  flutter_monorepo my_app --state riverpod --locales en,es,fr',
  );
  stdout.writeln(
    '  flutter_monorepo my_app --state bloc --platforms android,ios,web',
  );
  stdout.writeln('  flutter_monorepo my_app --platforms all');
  stdout.writeln('  flutter_monorepo my_app --state cubit --no-git');
  stdout.writeln('  flutter_monorepo my_app --license mit --github');
  stdout.writeln('  flutter_monorepo doctor');
  stdout.writeln('  flutter_monorepo doctor --fix');
  stdout.writeln('  flutter_monorepo workflow');
  stdout.writeln('  flutter_monorepo workflow a');
}
