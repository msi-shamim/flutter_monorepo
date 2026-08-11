import 'dart:io';

import 'config_detector.dart';
import 'project_config.dart';
import 'templates/skills_templates.dart' as skills;
import 'templates/root_templates.dart' as root;
import 'templates/license_templates.dart' as license;
import 'templates/github_templates.dart' as github;

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

  /// Sentinels keeping otherwise-empty directories in git.
  ///
  /// Restoring the directory without its sentinel is not enough: git does not
  /// track empty directories, so the next clone drops it again.
  static const _gitkeepFiles = <String>[
    'packages/core/lib/rules/.gitkeep',
    'packages/core/lib/states/.gitkeep',
    'packages/ui/lib/widgets/.gitkeep',
    'packages/ui/assets/icons/.gitkeep',
    'packages/ui/assets/fonts/.gitkeep',
    'packages/ui/assets/images/.gitkeep',
    'packages/network/lib/repositories/.gitkeep',
  ];

  int _passed = 0;
  int _missing = 0;
  int _restored = 0;
  int _unrestorable = 0;

  /// Maps relative file paths to content generators for smart restoration.
  /// Files in this map get their full content restored instead of empty files.
  late final Map<String, String> _restorableFiles;

  /// Runs the full diagnostic.
  ///
  /// Returns `true` if all checks pass, `false` if anything is missing.
  Future<bool> run() async {
    final config = _detectConfig();
    if (config == null) return false;

    // Build map of files that can be fully restored
    _restorableFiles = {
      '.claude/settings.json': skills.claudeSettings(),
      '.claude/skills/component-design/SKILL.md': skills.componentDesignSkill(
        config,
      ),
      '.claude/skills/screen-design/SKILL.md': skills.screenDesignSkill(config),
      '.claude/skills/business-logic/SKILL.md': skills.businessLogicSkill(
        config,
      ),
      '.claude/skills/monorepo-doctor/SKILL.md': skills.monrepoDoctorSkill(
        config,
      ),
      'README.md': root.readmeMd(config),
      'ARCHITECTURE.md': root.architectureMd(config),
      'LICENSE': license.licenseText(config),
      'CONTRIBUTING.md': root.contributingMd(config),
      '.gitignore': root.rootGitignore(),
      // Empty by design, unlike the placeholders _restore refuses to write.
      for (final path in _gitkeepFiles) path: '',
    };

    // GitHub community files were requested at generation time
    if (config.githubFiles) {
      _restorableFiles.addAll({
        'CODE_OF_CONDUCT.md': github.codeOfConduct(config),
        '.github/FUNDING.yml': github.fundingYml(config),
        '.github/ISSUE_TEMPLATE/bug_report.md': github.bugReportTemplate(
          config,
        ),
        '.github/ISSUE_TEMPLATE/feature_request.md': github
            .featureRequestTemplate(config),
        '.github/pull_request_template.md': github.pullRequestTemplate(config),
        '.github/workflows/ci.yml': github.ciWorkflow(config),
      });
    }

    stdout.writeln('');
    stdout.writeln(
      '→ Detected: ${config.name} (${config.stateManagement.name} + ${config.httpClient.name}, locales: ${config.locales.join(',')})',
    );
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
      stdout.writeln(
        'Result: All $_passed checks passed. Structure is intact.',
      );
    } else {
      stdout.writeln('Result: $_passed passed, $_missing missing.');
      if (fix) {
        stdout.writeln('Restored: $_restored of $_missing.');
        if (_unrestorable > 0) {
          stdout.writeln(
            '$_unrestorable file(s) have no template and were left absent — '
            'restore them from version control.',
          );
        } else {
          stdout.writeln('Structure is now intact.');
        }
      } else {
        stdout.writeln(
          'Run `flutter_monorepo doctor --fix` to restore missing items.',
        );
      }
    }

    // After a --fix run, what matters is what is still missing, not what was
    // missing on entry. Reporting failure for items we just restored makes
    // `doctor --fix && next-step` unusable.
    return _missing - _restored == 0;
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
        _restore(relativePath, fullPath, isDirectory: isDirectory);
      }
    }
  }

  void _restore(
    String relativePath,
    String fullPath, {
    required bool isDirectory,
  }) {
    if (isDirectory) {
      Directory(fullPath).createSync(recursive: true);
      stdout.writeln('    → Created directory');
      _restored++;
      return;
    }

    final content = _restorableFiles[relativePath];
    if (content == null) {
      // Deliberately leave the file absent. Writing an empty placeholder would
      // satisfy the existence check on the next run, turning a reported problem
      // into a silent one while the project stays broken.
      stdout.writeln('    → Cannot restore: no template for this file');
      _unrestorable++;
      return;
    }

    final file = File(fullPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    stdout.writeln('    → Restored with full content');
    _restored++;
  }

  // ── Detection ──────────────────────────────────────────

  ProjectConfig? _detectConfig() {
    final config = detectProjectConfig(rootPath);
    if (config == null) {
      stderr.writeln(
        'Error: Could not detect project config. '
        'Are you in a flutter_monorepo project root?',
      );
    }
    return config;
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
      // gen-l10n output. The l10n barrel exports from here unconditionally,
      // so losing it breaks every AppLocalizations import in the project.
      'packages/l10n/lib/l10n/generated',
      // App
      '${c.app}/lib/app/routes',
      '${c.app}/lib/screens/home',
      // Test directories
      'packages/core/test/states',
      'packages/core/test/rules',
      'packages/core/test/models',
      'packages/ui/test/widgets',
      'packages/network/test',
      '${c.app}/test/screens',
      // AI agent skills
      '.claude/skills/component-design',
      '.claude/skills/screen-design',
      '.claude/skills/business-logic',
      '.claude/skills/monorepo-doctor',
    ];

    switch (c.stateManagement) {
      case StateManagement.getx:
        dirs.addAll([
          '${c.app}/lib/app/bindings',
          '${c.app}/lib/app/controllers',
          '${c.app}/lib/app/middleware',
        ]);
      case StateManagement.riverpod:
        dirs.addAll(['${c.app}/lib/app/providers', '${c.app}/lib/app/router']);
      case StateManagement.bloc:
      case StateManagement.cubit:
        dirs.addAll(['${c.app}/lib/app/blocs', '${c.app}/lib/app/router']);
    }

    // GitHub community directories
    if (c.githubFiles) {
      dirs.addAll(['.github', '.github/ISSUE_TEMPLATE', '.github/workflows']);
    }

    return dirs;
  }

  List<String> _expectedFiles(ProjectConfig c) {
    final files = <String>[
      // Root
      projectMarkerFile,
      'pubspec.yaml',
      '.gitignore',
      'analysis_options.yaml',
      'README.md',
      'ARCHITECTURE.md',
      'LICENSE',
      'CONTRIBUTING.md',
      // AI agent skills
      '.claude/settings.json',
      '.claude/skills/component-design/SKILL.md',
      '.claude/skills/screen-design/SKILL.md',
      '.claude/skills/business-logic/SKILL.md',
      '.claude/skills/monorepo-doctor/SKILL.md',
      // Directory sentinels
      ..._gitkeepFiles,
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

    // GitHub community files
    if (c.githubFiles) {
      files.addAll([
        'CODE_OF_CONDUCT.md',
        '.github/FUNDING.yml',
        '.github/ISSUE_TEMPLATE/bug_report.md',
        '.github/ISSUE_TEMPLATE/feature_request.md',
        '.github/pull_request_template.md',
        '.github/workflows/ci.yml',
      ]);
    }

    return files;
  }
}
