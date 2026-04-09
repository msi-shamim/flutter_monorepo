import 'dart:io';

import 'project_config.dart';

/// Diagnoses a generated monorepo's structure integrity.
///
/// Detects the project's configuration from existing files, checks all
/// expected directories and files, and optionally fixes missing items.
class Doctor {
  /// Creates a doctor for the monorepo at [rootPath].
  Doctor({required this.rootPath, this.fix = false});

  /// Absolute path to the monorepo root.
  final String rootPath;

  /// When true, missing directories and files are recreated.
  final bool fix;

  int _passed = 0;
  int _missing = 0;

  /// Runs the full diagnostic.
  ///
  /// Returns `true` if all checks pass, `false` if anything is missing.
  Future<bool> run() async {
    final config = _detectConfig();
    if (config == null) return false;

    stdout.writeln('');
    stdout.writeln(
        '→ Detected: ${config.name} (${config.stateManagement.name} + ${config.httpClient.name}, locales: ${config.locales.join(',')})');
    stdout.writeln('');

    final dirs = _expectedDirectories(config);
    final files = _expectedFiles(config);

    // Check directories
    for (final dir in dirs) {
      _check(dir, isDirectory: true);
    }

    // Check files
    for (final file in files) {
      _check(file, isDirectory: false);
    }

    // Summary
    stdout.writeln('');
    if (_missing == 0) {
      stdout.writeln('Result: All $_passed checks passed. Structure is intact.');
    } else {
      stdout.writeln(
          'Result: $_passed passed, $_missing missing.');
      if (!fix) {
        stdout.writeln(
            'Run `flutter_monorepo doctor --fix` to restore missing items.');
      }
    }

    return _missing == 0;
  }

  void _check(String relativePath, {required bool isDirectory}) {
    final fullPath = '$rootPath/$relativePath';
    final exists = isDirectory
        ? Directory(fullPath).existsSync()
        : File(fullPath).existsSync();

    if (exists) {
      stdout.writeln('  ✓ $relativePath');
      _passed++;
    } else {
      stdout.writeln('  ✗ $relativePath  ← MISSING');
      _missing++;
      if (fix) {
        _restore(fullPath, isDirectory: isDirectory);
      }
    }
  }

  void _restore(String fullPath, {required bool isDirectory}) {
    if (isDirectory) {
      Directory(fullPath).createSync(recursive: true);
      stdout.writeln('    → Created directory');
    } else {
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('');
      stdout.writeln('    → Created empty file (populate manually)');
    }
  }

  // ── Detection ──────────────────────────────────────────

  ProjectConfig? _detectConfig() {
    // Read root pubspec to get project name
    final rootPubspec = File('$rootPath/pubspec.yaml');
    if (!rootPubspec.existsSync()) {
      stderr.writeln(
          'Error: No pubspec.yaml found. Are you in a flutter_monorepo project root?');
      return null;
    }

    final rootContent = rootPubspec.readAsStringSync();
    final name = _extractYamlValue(rootContent, 'name')
        ?.replaceAll('_workspace', '');
    if (name == null) {
      stderr.writeln('Error: Could not detect project name from pubspec.yaml.');
      return null;
    }

    // Detect state management from app pubspec
    final appPubspecFile = File('$rootPath/${name}_app/pubspec.yaml');
    final stateManagement = _detectStateManagement(appPubspecFile, name);

    // Detect HTTP client from network pubspec
    final netPubspecFile = File('$rootPath/packages/network/pubspec.yaml');
    final httpClient = _detectHttpClient(netPubspecFile);

    // Detect locales from ARB files
    final locales = _detectLocales();

    return ProjectConfig(
      name: name,
      org: 'com.example', // not detectable, not needed for structure check
      stateManagement: stateManagement,
      httpClient: httpClient,
      locales: locales,
    );
  }

  StateManagement _detectStateManagement(File pubspecFile, String name) {
    if (!pubspecFile.existsSync()) return StateManagement.getx;
    final content = pubspecFile.readAsStringSync();

    if (content.contains('flutter_riverpod:')) return StateManagement.riverpod;
    if (content.contains('flutter_bloc:')) {
      // Distinguish Bloc vs Cubit by checking for Cubit usage in app code
      final blocsDir = Directory('$rootPath/${name}_app/lib/app/blocs');
      if (blocsDir.existsSync()) {
        final files = blocsDir.listSync().whereType<File>();
        for (final f in files) {
          if (f.readAsStringSync().contains('HydratedCubit')) {
            return StateManagement.cubit;
          }
        }
      }
      return StateManagement.bloc;
    }
    return StateManagement.getx;
  }

  HttpClient _detectHttpClient(File pubspecFile) {
    if (!pubspecFile.existsSync()) return HttpClient.dio;
    final content = pubspecFile.readAsStringSync();

    if (content.contains('chopper:')) return HttpClient.chopper;
    if (content.contains('  http:')) return HttpClient.http;
    return HttpClient.dio;
  }

  List<String> _detectLocales() {
    final arbDir = Directory('$rootPath/packages/l10n/lib/l10n/arb');
    if (!arbDir.existsSync()) return ['en', 'ar'];

    final locales = <String>[];
    for (final entity in arbDir.listSync()) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        final match = RegExp(r'^app_(\w+)\.arb$').firstMatch(name);
        if (match != null) locales.add(match.group(1)!);
      }
    }
    return locales.isEmpty ? ['en', 'ar'] : locales;
  }

  String? _extractYamlValue(String content, String key) {
    final match = RegExp('^$key:\\s*(.+)', multiLine: true).firstMatch(content);
    return match?.group(1)?.trim();
  }

  // ── Expected structure ─────────────────────────────────

  List<String> _expectedDirectories(ProjectConfig c) {
    final dirs = <String>[
      // Root
      c.app,
      'packages/core',
      'packages/ui',
      'packages/network',
      'packages/l10n',
      // Core
      'packages/core/lib/exceptions',
      'packages/core/lib/models',
      'packages/core/lib/rules',
      'packages/core/lib/states',
      'packages/core/lib/repositories',
      'packages/core/lib/usecases',
      'packages/core/lib/utils',
      'packages/core/lib/extensions',
      // UI
      'packages/ui/lib/assets',
      'packages/ui/lib/responsive',
      'packages/ui/lib/theme',
      'packages/ui/lib/widgets',
      'packages/ui/assets/icons',
      'packages/ui/assets/fonts',
      'packages/ui/assets/images',
      // Network
      'packages/network/lib/client',
      'packages/network/lib/interceptors',
      'packages/network/lib/repositories',
      // L10n
      'packages/l10n/lib/formatters',
      'packages/l10n/lib/widgets',
      'packages/l10n/lib/l10n/arb',
      // App
      '${c.app}/lib/app/routes',
      '${c.app}/lib/screens/home',
    ];

    switch (c.stateManagement) {
      case StateManagement.getx:
        dirs.addAll([
          '${c.app}/lib/app/bindings',
          '${c.app}/lib/app/controllers',
          '${c.app}/lib/app/middleware',
        ]);
      case StateManagement.riverpod:
        dirs.addAll([
          '${c.app}/lib/app/providers',
          '${c.app}/lib/app/router',
        ]);
      case StateManagement.bloc:
      case StateManagement.cubit:
        dirs.addAll([
          '${c.app}/lib/app/blocs',
          '${c.app}/lib/app/router',
        ]);
    }

    return dirs;
  }

  List<String> _expectedFiles(ProjectConfig c) {
    final files = <String>[
      // Root
      'pubspec.yaml',
      'analysis_options.yaml',
      // Core
      'packages/core/pubspec.yaml',
      'packages/core/PACKAGE.md',
      'packages/core/lib/${c.core}.dart',
      'packages/core/lib/exceptions/app_exception.dart',
      'packages/core/lib/models/base_model.dart',
      'packages/core/lib/repositories/base_repository.dart',
      'packages/core/lib/usecases/use_case.dart',
      'packages/core/lib/utils/result.dart',
      'packages/core/lib/extensions/string_extensions.dart',
      'packages/core/lib/extensions/date_extensions.dart',
      'packages/core/lib/extensions/list_extensions.dart',
      // UI
      'packages/ui/pubspec.yaml',
      'packages/ui/PACKAGE.md',
      'packages/ui/lib/${c.ui}.dart',
      'packages/ui/lib/assets/app_icons.dart',
      'packages/ui/lib/assets/app_images.dart',
      'packages/ui/lib/assets/app_fonts.dart',
      'packages/ui/lib/responsive/breakpoints.dart',
      'packages/ui/lib/responsive/responsive_helper.dart',
      'packages/ui/lib/responsive/responsive_builder.dart',
      'packages/ui/lib/theme/app_colors.dart',
      'packages/ui/lib/theme/app_spacing.dart',
      'packages/ui/lib/theme/app_typography.dart',
      'packages/ui/lib/theme/app_theme.dart',
      // Network
      'packages/network/pubspec.yaml',
      'packages/network/PACKAGE.md',
      'packages/network/lib/${c.network}.dart',
      'packages/network/lib/client/api_client.dart',
      'packages/network/lib/interceptors/auth_interceptor.dart',
      'packages/network/lib/interceptors/logging_interceptor.dart',
      // L10n
      'packages/l10n/pubspec.yaml',
      'packages/l10n/PACKAGE.md',
      'packages/l10n/l10n.yaml',
      'packages/l10n/lib/${c.l10n}.dart',
      'packages/l10n/lib/formatters/date_formatter.dart',
      'packages/l10n/lib/formatters/number_formatter.dart',
      'packages/l10n/lib/widgets/directionality_builder.dart',
      // App
      '${c.app}/pubspec.yaml',
      '${c.app}/lib/main.dart',
      '${c.app}/lib/app/routes/app_routes.dart',
      '${c.app}/lib/screens/home/home_screen.dart',
    ];

    // Locale ARB files
    for (final locale in c.locales) {
      files.add('packages/l10n/lib/l10n/arb/app_$locale.arb');
    }

    // State-management-specific files
    switch (c.stateManagement) {
      case StateManagement.getx:
        files.addAll([
          '${c.app}/lib/app/routes/app_pages.dart',
          '${c.app}/lib/app/bindings/initial_binding.dart',
          '${c.app}/lib/app/controllers/theme_controller.dart',
          '${c.app}/lib/app/controllers/locale_controller.dart',
          '${c.app}/lib/app/middleware/auth_middleware.dart',
          '${c.app}/lib/screens/home/home_binding.dart',
          '${c.app}/lib/screens/home/home_controller.dart',
        ]);
      case StateManagement.riverpod:
        files.addAll([
          '${c.app}/lib/app/router/app_router.dart',
          '${c.app}/lib/app/providers/theme_provider.dart',
          '${c.app}/lib/app/providers/locale_provider.dart',
        ]);
      case StateManagement.bloc:
      case StateManagement.cubit:
        files.addAll([
          '${c.app}/lib/app/router/app_router.dart',
          '${c.app}/lib/app/blocs/theme_bloc.dart',
          '${c.app}/lib/app/blocs/locale_bloc.dart',
        ]);
    }

    return files;
  }
}
