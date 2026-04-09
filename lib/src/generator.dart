import 'dart:io';

import 'project_config.dart';
import 'templates/root_templates.dart' as root;
import 'templates/core_templates.dart' as core;
import 'templates/ui_templates.dart' as ui;
import 'templates/network_templates.dart' as net;
import 'templates/l10n_templates.dart' as l10n;
import 'templates/app_templates.dart' as app;

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
        '--platforms', 'android,ios',
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
    final dirs = [
      'packages/core/lib/exceptions',
      'packages/core/lib/models',
      'packages/core/lib/rules',
      'packages/core/lib/repositories',
      'packages/core/lib/usecases',
      'packages/core/lib/utils',
      'packages/core/lib/extensions',
      'packages/ui/lib/assets',
      'packages/ui/lib/responsive',
      'packages/ui/lib/theme',
      'packages/ui/lib/widgets',
      'packages/ui/assets/icons',
      'packages/ui/assets/fonts',
      'packages/ui/assets/images',
      'packages/network/lib/client',
      'packages/network/lib/interceptors',
      'packages/network/lib/repositories',
      'packages/l10n/lib/formatters',
      'packages/l10n/lib/widgets',
      'packages/l10n/lib/l10n/arb',
      'packages/l10n/lib/l10n/generated',
      '${config.app}/lib/app/bindings',
      '${config.app}/lib/app/controllers',
      '${config.app}/lib/app/middleware',
      '${config.app}/lib/app/routes',
      '${config.app}/lib/screens/home',
    ];
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
    _write('packages/l10n/l10n.yaml', l10n.l10nYaml());
    _write('packages/l10n/lib/${config.l10n}.dart', l10n.l10nBarrel());
    _write('packages/l10n/lib/l10n/arb/app_en.arb', l10n.appEnArb(config));
    _write('packages/l10n/lib/l10n/arb/app_ar.arb', l10n.appArArb(config));
    _write('packages/l10n/lib/formatters/date_formatter.dart', l10n.dateFormatter());
    _write('packages/l10n/lib/formatters/number_formatter.dart', l10n.numberFormatter());
    _write('packages/l10n/lib/widgets/directionality_builder.dart', l10n.directionalityBuilder());
  }

  // ── App code ────────────────────────────────────────────
  void _writeAppCode() {
    _log('Writing app code...');
    _write('${config.app}/pubspec.yaml', app.appPubspec(config));
    _write('${config.app}/lib/main.dart', app.mainDart(config));
    _write('${config.app}/lib/app/bindings/initial_binding.dart', app.initialBinding());
    _write('${config.app}/lib/app/controllers/theme_controller.dart', app.themeController());
    _write('${config.app}/lib/app/controllers/locale_controller.dart', app.localeController());
    _write('${config.app}/lib/app/middleware/auth_middleware.dart', app.authMiddleware());
    _write('${config.app}/lib/app/routes/app_routes.dart', app.appRoutes());
    _write('${config.app}/lib/app/routes/app_pages.dart', app.appPages());
    _write('${config.app}/lib/screens/home/home_controller.dart', app.homeController());
    _write('${config.app}/lib/screens/home/home_binding.dart', app.homeBinding());
    _write('${config.app}/lib/screens/home/home_screen.dart', app.homeScreen(config));

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

  // ── Helpers ─────────────────────────────────────────────
  void _write(String relativePath, String content) {
    final file = File('$rootPath/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  void _log(String message) => stdout.writeln('→ $message');
}
