import 'dart:io';

import 'project_config.dart';
import 'templates/root_templates.dart' as root;
import 'templates/core_templates.dart' as core;
import 'templates/ui_templates.dart' as ui;
import 'templates/network_templates.dart' as net;
import 'templates/l10n_templates.dart' as l10n;
import 'templates/app/app_template_factory.dart';
import 'templates/app/app_template_strategy.dart';

class Generator {
  Generator({required this.config, required this.rootPath});

  final ProjectConfig config;
  final String rootPath;

  Future<void> run() async {
    await _createFlutterProject();
    _createDirectories();
    _writeRootFiles();
    _writeCorePackage();
    _writeUiPackage();
    _writeNetworkPackage();
    _writeL10nPackage();
    _writeAppCode();
    await _resolveDependencies();
    await _generateL10n();
    await _analyze();
    await _initializeGit();

    stdout.writeln('');
    stdout.writeln('╔══════════════════════════════════════════════════╗');
    stdout.writeln('║  ${config.pascal} monorepo created successfully!');
    stdout.writeln('╠══════════════════════════════════════════════════╣');
    stdout.writeln('║  cd ${config.name}');
    stdout.writeln('║  cd ${config.app} && flutter run');
    stdout.writeln('╚══════════════════════════════════════════════════╝');
    stdout.writeln('');
  }

  // ── Flutter create ──────────────────────────────────────
  Future<void> _createFlutterProject() async {
    _log('Creating Flutter project...');
    final result = await Process.run(
      'flutter',
      [
        'create',
        '--org', config.org,
        '--project-name', config.app,
        '$rootPath/${config.app}',
        '--platforms', config.platforms.join(','),
        '--no-pub',
      ],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      throw Exception('flutter create failed:\n${result.stderr}');
    }
  }

  // ── Directories ─────────────────────────────────────────
  void _createDirectories() {
    _log('Creating monorepo structure...');

    final dirs = <String>[
      // Core
      'packages/core/lib/exceptions',
      'packages/core/lib/models',
      'packages/core/lib/rules',
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
      'packages/l10n/lib/l10n/generated',
      // App — routes + screens always exist
      '${config.app}/lib/app/routes',
      '${config.app}/lib/screens/home',
    ];

    // State-management-specific app directories
    switch (config.stateManagement) {
      case StateManagement.getx:
        dirs.addAll([
          '${config.app}/lib/app/bindings',
          '${config.app}/lib/app/controllers',
          '${config.app}/lib/app/middleware',
        ]);
      case StateManagement.riverpod:
        dirs.addAll([
          '${config.app}/lib/app/providers',
          '${config.app}/lib/app/router',
        ]);
      case StateManagement.bloc:
      case StateManagement.cubit:
        dirs.addAll([
          '${config.app}/lib/app/blocs',
          '${config.app}/lib/app/router',
        ]);
    }

    for (final dir in dirs) {
      Directory('$rootPath/$dir').createSync(recursive: true);
    }

    // .gitkeep for empty dirs
    for (final path in [
      'packages/core/lib/rules/.gitkeep',
      'packages/ui/lib/widgets/.gitkeep',
      'packages/ui/assets/icons/.gitkeep',
      'packages/ui/assets/fonts/.gitkeep',
      'packages/ui/assets/images/.gitkeep',
      'packages/network/lib/repositories/.gitkeep',
    ]) {
      File('$rootPath/$path').createSync();
    }
  }

  // ── Root files ──────────────────────────────────────────
  void _writeRootFiles() {
    _log('Writing root configuration...');
    _write('pubspec.yaml', root.rootPubspec(config));
    _write('.gitignore', root.rootGitignore());
    _write('analysis_options.yaml', root.analysisOptions());
  }

  // ── Core package ────────────────────────────────────────
  void _writeCorePackage() {
    _log('Writing packages/core...');
    _write('packages/core/pubspec.yaml', core.corePubspec(config));
    _write('packages/core/PACKAGE.md', core.corePackageMd(config));
    _write('packages/core/lib/${config.core}.dart', core.coreBarrel(config));
    _write('packages/core/lib/exceptions/app_exception.dart', core.appException());
    _write('packages/core/lib/models/base_model.dart', core.baseModel());
    _write('packages/core/lib/repositories/base_repository.dart', core.baseRepository());
    _write('packages/core/lib/usecases/use_case.dart', core.useCase(config));
    _write('packages/core/lib/utils/result.dart', core.result(config));
    _write('packages/core/lib/extensions/string_extensions.dart', core.stringExtensions());
    _write('packages/core/lib/extensions/date_extensions.dart', core.dateExtensions());
    _write('packages/core/lib/extensions/list_extensions.dart', core.listExtensions());
  }

  // ── UI package ──────────────────────────────────────────
  void _writeUiPackage() {
    _log('Writing packages/ui...');
    _write('packages/ui/pubspec.yaml', ui.uiPubspec(config));
    _write('packages/ui/PACKAGE.md', ui.uiPackageMd(config));
    _write('packages/ui/lib/${config.ui}.dart', ui.uiBarrel());
    _write('packages/ui/lib/assets/app_icons.dart', ui.appIcons(config));
    _write('packages/ui/lib/assets/app_images.dart', ui.appImages(config));
    _write('packages/ui/lib/assets/app_fonts.dart', ui.appFonts());
    _write('packages/ui/lib/responsive/breakpoints.dart', ui.breakpoints());
    _write('packages/ui/lib/responsive/responsive_helper.dart', ui.responsiveHelper());
    _write('packages/ui/lib/responsive/responsive_builder.dart', ui.responsiveBuilder());
    _write('packages/ui/lib/theme/app_colors.dart', ui.appColors());
    _write('packages/ui/lib/theme/app_spacing.dart', ui.appSpacing());
    _write('packages/ui/lib/theme/app_typography.dart', ui.appTypography());
    _write('packages/ui/lib/theme/app_theme.dart', ui.appTheme());
  }

  // ── Network package ─────────────────────────────────────
  void _writeNetworkPackage() {
    _log('Writing packages/network...');
    _write('packages/network/pubspec.yaml', net.networkPubspec(config));
    _write('packages/network/PACKAGE.md', net.networkPackageMd(config));
    _write('packages/network/lib/${config.network}.dart', net.networkBarrel());
    _write('packages/network/lib/client/api_client.dart', net.apiClient(config));
    _write('packages/network/lib/interceptors/auth_interceptor.dart', net.authInterceptor());
    _write('packages/network/lib/interceptors/logging_interceptor.dart', net.loggingInterceptor());
  }

  // ── L10n package ────────────────────────────────────────
  void _writeL10nPackage() {
    _log('Writing packages/l10n...');
    _write('packages/l10n/pubspec.yaml', l10n.l10nPubspec(config));
    _write('packages/l10n/PACKAGE.md', l10n.l10nPackageMd(config));
    _write('packages/l10n/l10n.yaml', l10n.l10nYaml(config));
    _write('packages/l10n/lib/${config.l10n}.dart', l10n.l10nBarrel());
    // Dynamic ARB generation for each locale
    for (final locale in config.locales) {
      _write(
        'packages/l10n/lib/l10n/arb/app_$locale.arb',
        l10n.arbFile(config, locale),
      );
    }
    _write('packages/l10n/lib/formatters/date_formatter.dart', l10n.dateFormatter());
    _write('packages/l10n/lib/formatters/number_formatter.dart', l10n.numberFormatter());
    _write('packages/l10n/lib/widgets/directionality_builder.dart', l10n.directionalityBuilder());
  }

  // ── App code (strategy pattern) ─────────────────────────
  void _writeAppCode() {
    _log('Writing app code (${config.stateManagement.name})...');
    final tmpl = createAppTemplates(config.stateManagement);

    _write('${config.app}/pubspec.yaml', tmpl.appPubspec(config));
    _write('${config.app}/lib/main.dart', tmpl.mainDart(config));
    _write('${config.app}/lib/app/routes/app_routes.dart', appRoutes());

    // Routing
    _writeIfNotEmpty('${config.app}/lib/app/routes/app_pages.dart', tmpl.appPages(config));
    _writeIfNotEmpty('${config.app}/lib/app/router/app_router.dart', tmpl.appRouter(config));

    // State management — write to framework-specific directories
    final stateDir = switch (config.stateManagement) {
      StateManagement.getx => 'controllers',
      StateManagement.riverpod => 'providers',
      StateManagement.bloc || StateManagement.cubit => 'blocs',
    };
    final themeFile = switch (config.stateManagement) {
      StateManagement.getx => 'theme_controller.dart',
      StateManagement.riverpod => 'theme_provider.dart',
      StateManagement.bloc || StateManagement.cubit => 'theme_bloc.dart',
    };
    final localeFile = switch (config.stateManagement) {
      StateManagement.getx => 'locale_controller.dart',
      StateManagement.riverpod => 'locale_provider.dart',
      StateManagement.bloc || StateManagement.cubit => 'locale_bloc.dart',
    };

    _writeIfNotEmpty('${config.app}/lib/app/$stateDir/$themeFile', tmpl.themeController(config));
    _writeIfNotEmpty('${config.app}/lib/app/$stateDir/$localeFile', tmpl.localeController(config));
    _writeIfNotEmpty('${config.app}/lib/app/bindings/initial_binding.dart', tmpl.initialBinding(config));
    _writeIfNotEmpty('${config.app}/lib/app/middleware/auth_middleware.dart', tmpl.authMiddleware(config));

    // Screen
    _writeIfNotEmpty('${config.app}/lib/screens/home/home_binding.dart', tmpl.homeBinding(config));
    _writeIfNotEmpty('${config.app}/lib/screens/home/home_controller.dart', tmpl.homeController(config));
    _write('${config.app}/lib/screens/home/home_screen.dart', tmpl.homeScreen(config));

    // Remove flutter create's default test
    final widgetTest = File('$rootPath/${config.app}/test/widget_test.dart');
    if (widgetTest.existsSync()) widgetTest.deleteSync();
  }

  // ── Post-generation commands ────────────────────────────
  Future<void> _resolveDependencies() async {
    _log('Resolving dependencies...');
    final result = await Process.run(
      'dart', ['pub', 'get'],
      workingDirectory: rootPath,
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stdout.writeln('  Warning: dart pub get had issues: ${result.stderr}');
    }
  }

  Future<void> _generateL10n() async {
    _log('Generating l10n...');
    final result = await Process.run(
      'flutter', ['gen-l10n'],
      workingDirectory: '$rootPath/packages/l10n',
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stdout.writeln('  (gen-l10n will run on first build)');
    }
  }

  Future<void> _analyze() async {
    _log('Running dart analyze...');
    final result = await Process.run(
      'dart', ['analyze'],
      workingDirectory: rootPath,
      runInShell: true,
    );
    stdout.writeln(result.stdout);
    if (result.exitCode != 0) {
      stdout.writeln(result.stderr);
    }
  }

  Future<void> _initializeGit() async {
    if (!config.gitInit) return;
    _log('Initializing git repository...');
    await Process.run('git', ['init'], workingDirectory: rootPath, runInShell: true);
    await Process.run('git', ['add', '.'], workingDirectory: rootPath, runInShell: true);
    await Process.run(
      'git', ['commit', '-m', 'Initial commit: ${config.pascal} monorepo'],
      workingDirectory: rootPath,
      runInShell: true,
    );
  }

  // ── Helpers ─────────────────────────────────────────────
  void _write(String relativePath, String content) {
    final file = File('$rootPath/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  void _writeIfNotEmpty(String relativePath, String content) {
    if (content.trim().isNotEmpty) _write(relativePath, content);
  }

  void _log(String message) => stdout.writeln('→ $message');
}
