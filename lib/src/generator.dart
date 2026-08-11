import 'dart:io';

import 'project_config.dart';
import 'version_resolver.dart';
import 'templates/root_templates.dart' as root;
import 'templates/core_templates.dart' as core;
import 'templates/ui_templates.dart' as ui;
import 'templates/network_templates.dart' as net;
import 'templates/l10n_templates.dart' as l10n;
import 'templates/app/app_template_factory.dart';
import 'templates/app/app_template_strategy.dart';
import 'templates/skills_templates.dart' as skills;
import 'templates/license_templates.dart' as license;
import 'templates/github_templates.dart' as github;
import 'templates/ci_templates.dart' as ci;
import 'templates/storage_templates.dart' as storage;
import 'templates/flavor_templates.dart' as flavor;

/// Orchestrates the generation of a complete Flutter monorepo.
///
/// Creates the Flutter project, writes all package templates,
/// resolves dependencies, and optionally initializes git.
class Generator {
  /// Creates a generator for the given [config] at [rootPath].
  Generator({required this.config, required this.rootPath});

  /// The project configuration with all user choices.
  final ProjectConfig config;

  /// Absolute path where the monorepo will be created.
  final String rootPath;

  /// Steps that failed during the run, as user-facing descriptions.
  final _failures = <String>[];

  /// Runs the full generation pipeline.
  ///
  /// Returns `true` when every step succeeded. A `false` return means the
  /// project was written but is not in a usable state — the caller is expected
  /// to exit non-zero. Only [_createFlutterProject] throws, because nothing
  /// meaningful can be generated without it.
  Future<bool> run() async {
    await _resolveVersions();
    await _createFlutterProject();
    _createDirectories();
    _writeRootFiles();
    _writeGithubFiles();
    _writeCiPipeline();
    _writeCorePackage();
    _writeUiPackage();
    _writeNetworkPackage();
    _writeL10nPackage();
    _writeAppCode();
    _writeSkills();
    _writeFlavors();
    await _resolveDependencies();
    await _generateL10n();
    await _formatCode();
    await _analyze();
    await _initializeGit();

    return _failures.isEmpty ? _reportSuccess() : _reportFailure();
  }

  bool _reportSuccess() {
    stdout.writeln('');
    stdout.writeln('╔══════════════════════════════════════════════════╗');
    stdout.writeln('║  ${config.pascal} monorepo created successfully!');
    stdout.writeln('╠══════════════════════════════════════════════════╣');
    stdout.writeln('║  cd ${config.name}');
    stdout.writeln('║  cd ${config.app} && flutter run');
    stdout.writeln('╚══════════════════════════════════════════════════╝');
    stdout.writeln('');
    return true;
  }

  bool _reportFailure() {
    stderr.writeln('');
    stderr.writeln('╔══════════════════════════════════════════════════╗');
    stderr.writeln('║  ${config.pascal} monorepo is INCOMPLETE');
    stderr.writeln('╠══════════════════════════════════════════════════╣');
    for (final failure in _failures) {
      stderr.writeln('║  ✗ $failure');
    }
    stderr.writeln('╚══════════════════════════════════════════════════╝');
    stderr.writeln('');
    stderr.writeln('The project was written to $rootPath but is not ready to');
    stderr.writeln('run. Fix the issues above, or delete the directory and');
    stderr.writeln('re-run the command.');
    stderr.writeln('');
    return false;
  }

  // ── Version resolution ───────────────────────────────────
  Future<void> _resolveVersions() async {
    final resolver = VersionResolver();
    await resolver.resolveAll(config.requiredPackages);
    config.versions = resolver;
  }

  // ── Flutter create ──────────────────────────────────────
  Future<void> _createFlutterProject() async {
    _log('Creating Flutter project...');
    final result = await Process.run('flutter', [
      'create',
      '--org',
      config.org,
      '--project-name',
      config.app,
      '$rootPath/${config.app}',
      '--platforms',
      config.platforms.join(','),
      '--no-pub',
    ], runInShell: true);
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
      'packages/core/lib/states',
      'packages/core/lib/repositories',
      'packages/core/lib/usecases',
      'packages/core/lib/utils',
      'packages/core/lib/extensions',
      'packages/core/lib/storage',
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
      '${config.app}/lib/app/storage',
      '${config.app}/lib/screens/home',
      // Test directories (tests written during development)
      'packages/core/test/states',
      'packages/core/test/rules',
      'packages/core/test/models',
      'packages/ui/test/widgets',
      'packages/network/test',
      '${config.app}/test/screens',
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
      'packages/core/lib/states/.gitkeep',
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
    _write(projectMarkerFile, root.projectMarker(config));
    _write('pubspec.yaml', root.rootPubspec(config));
    _write('.gitignore', root.rootGitignore());
    _write('analysis_options.yaml', root.analysisOptions());
    _write('README.md', root.readmeMd(config));
    _write('ARCHITECTURE.md', root.architectureMd(config));
    _write('LICENSE', license.licenseText(config));
    _write('CONTRIBUTING.md', root.contributingMd(config));
  }

  // ── GitHub community files ─────────────────────────────
  void _writeGithubFiles() {
    if (!config.githubFiles) return;
    _log('Writing GitHub community files...');
    _write('CODE_OF_CONDUCT.md', github.codeOfConduct(config));
    _write('.github/FUNDING.yml', github.fundingYml(config));
    _write(
      '.github/ISSUE_TEMPLATE/bug_report.md',
      github.bugReportTemplate(config),
    );
    _write(
      '.github/ISSUE_TEMPLATE/feature_request.md',
      github.featureRequestTemplate(config),
    );
    _write(
      '.github/pull_request_template.md',
      github.pullRequestTemplate(config),
    );
  }

  // ── CI pipeline ─────────────────────────────────────────
  void _writeCiPipeline() {
    switch (config.ci) {
      case CiProvider.none:
        return;
      case CiProvider.github:
        _log('Writing GitHub Actions workflow...');
        _write('.github/workflows/ci.yml', github.ciWorkflow(config));
      case CiProvider.gitlab:
        _log('Writing GitLab CI pipeline...');
        _write('.gitlab-ci.yml', ci.gitlabCi(config));
    }
  }

  // ── Core package ────────────────────────────────────────
  void _writeCorePackage() {
    _log('Writing packages/core...');
    _write('packages/core/pubspec.yaml', core.corePubspec(config));
    _write('packages/core/PACKAGE.md', core.corePackageMd(config));
    _write('packages/core/lib/${config.core}.dart', core.coreBarrel(config));
    _write(
      'packages/core/lib/exceptions/app_exception.dart',
      core.appException(),
    );
    _write('packages/core/lib/models/base_model.dart', core.baseModel());
    _write(
      'packages/core/lib/repositories/base_repository.dart',
      core.baseRepository(),
    );
    _write('packages/core/lib/usecases/use_case.dart', core.useCase(config));
    _write('packages/core/lib/utils/result.dart', core.result(config));
    _write(
      'packages/core/lib/storage/key_value_store.dart',
      core.keyValueStore(config),
    );
    _write(
      'packages/core/lib/extensions/string_extensions.dart',
      core.stringExtensions(),
    );
    _write(
      'packages/core/lib/extensions/date_extensions.dart',
      core.dateExtensions(),
    );
    _write(
      'packages/core/lib/extensions/list_extensions.dart',
      core.listExtensions(),
    );
    _write('packages/core/test/core_test.dart', core.coreStarterTest(config));
    if (config.testScope == TestScope.full) {
      _write(
        'packages/core/test/helpers/fixtures.dart',
        ci.coreTestFixtures(config),
      );
    }
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
    _write(
      'packages/ui/lib/responsive/responsive_helper.dart',
      ui.responsiveHelper(),
    );
    _write(
      'packages/ui/lib/responsive/responsive_builder.dart',
      ui.responsiveBuilder(),
    );
    _write('packages/ui/lib/theme/app_colors.dart', ui.appColors());
    _write('packages/ui/lib/theme/app_spacing.dart', ui.appSpacing());
    _write('packages/ui/lib/theme/app_typography.dart', ui.appTypography());
    _write('packages/ui/lib/theme/app_theme.dart', ui.appTheme());
    _write('packages/ui/test/theme_test.dart', ui.uiStarterTest(config));
  }

  // ── Network package ─────────────────────────────────────
  void _writeNetworkPackage() {
    _log('Writing packages/network...');
    _write('packages/network/pubspec.yaml', net.networkPubspec(config));
    _write('packages/network/PACKAGE.md', net.networkPackageMd(config));
    _write('packages/network/lib/${config.network}.dart', net.networkBarrel());
    _write(
      'packages/network/lib/client/api_client.dart',
      net.apiClient(config),
    );
    _write(
      'packages/network/lib/interceptors/auth_interceptor.dart',
      net.authInterceptor(config),
    );
    _write(
      'packages/network/lib/interceptors/logging_interceptor.dart',
      net.loggingInterceptor(config),
    );
    _write(
      'packages/network/test/api_client_test.dart',
      net.networkStarterTest(config),
    );
  }

  // ── L10n package ────────────────────────────────────────
  void _writeL10nPackage() {
    _log('Writing packages/l10n...');
    _write('packages/l10n/pubspec.yaml', l10n.l10nPubspec(config));
    _write('packages/l10n/PACKAGE.md', l10n.l10nPackageMd(config));
    _write('packages/l10n/l10n.yaml', l10n.l10nYaml(config));
    _write('packages/l10n/lib/${config.l10n}.dart', l10n.l10nBarrel());
    // Dynamic ARB generation for each locale. A locale carrying a region or
    // script subtag also needs its base language as a fallback, or gen-l10n
    // refuses to run: "Arb file for a fallback, pt, does not exist".
    final arbLocales = <String>{};
    for (final locale in config.locales) {
      final base = locale.split('_').first;
      if (base != locale) arbLocales.add(base);
      arbLocales.add(locale);
    }
    final untranslated = <String>[];
    for (final locale in arbLocales) {
      _write(
        'packages/l10n/lib/l10n/arb/app_$locale.arb',
        l10n.arbFile(config, locale),
      );
      if (!l10n.hasTranslation(locale)) untranslated.add(locale);
    }
    if (untranslated.isNotEmpty) {
      stdout.writeln(
        '  Note: no built-in strings for '
        '${untranslated.join(', ')} — those ARB files contain English '
        'placeholders and are marked for translation.',
      );
    }
    _write(
      'packages/l10n/lib/formatters/date_formatter.dart',
      l10n.dateFormatter(),
    );
    _write(
      'packages/l10n/lib/formatters/number_formatter.dart',
      l10n.numberFormatter(),
    );
    _write(
      'packages/l10n/lib/widgets/directionality_builder.dart',
      l10n.directionalityBuilder(),
    );
  }

  // ── App code (strategy pattern) ─────────────────────────
  void _writeAppCode() {
    _log('Writing app code (${config.stateManagement.name})...');
    final tmpl = createAppTemplates(config.stateManagement);

    _write('${config.app}/pubspec.yaml', tmpl.appPubspec(config));
    _write('${config.app}/lib/main.dart', tmpl.mainDart(config));
    _write('${config.app}/lib/app/routes/app_routes.dart', appRoutes());

    // Routing
    _writeIfNotEmpty(
      '${config.app}/lib/app/routes/app_pages.dart',
      tmpl.appPages(config),
    );
    _writeIfNotEmpty(
      '${config.app}/lib/app/router/app_router.dart',
      tmpl.appRouter(config),
    );

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

    _writeIfNotEmpty(
      '${config.app}/lib/app/$stateDir/$themeFile',
      tmpl.themeController(config),
    );
    _writeIfNotEmpty(
      '${config.app}/lib/app/$stateDir/$localeFile',
      tmpl.localeController(config),
    );
    _writeIfNotEmpty(
      '${config.app}/lib/app/bindings/initial_binding.dart',
      tmpl.initialBinding(config),
    );
    _writeIfNotEmpty(
      '${config.app}/lib/app/middleware/auth_middleware.dart',
      tmpl.authMiddleware(config),
    );

    // Screen
    _writeIfNotEmpty(
      '${config.app}/lib/screens/home/home_binding.dart',
      tmpl.homeBinding(config),
    );
    _writeIfNotEmpty(
      '${config.app}/lib/screens/home/home_controller.dart',
      tmpl.homeController(config),
    );
    _write(
      '${config.app}/lib/screens/home/home_screen.dart',
      tmpl.homeScreen(config),
    );

    // Replace flutter create's default test, which references a counter app
    // that does not exist here, with one that exercises the generated code.
    final widgetTest = File('$rootPath/${config.app}/test/widget_test.dart');
    if (widgetTest.existsSync()) widgetTest.deleteSync();
    _write('${config.app}/test/app_test.dart', appStarterTest(config));
    _writeIfNotEmpty(
      '${config.app}/test/flutter_test_config.dart',
      tmpl.testSetup(config),
    );

    // Storage: one implementation of core's interface, plus the single place
    // that names it. Bloc and Cubit also get the hydrated_bloc adapter.
    _write(
      '${config.app}/lib/app/storage/${storage.keyValueStoreFileName(config)}',
      storage.keyValueStoreImpl(config),
    );
    _write(
      '${config.app}/lib/app/storage/app_store.dart',
      storage.appStore(config),
    );
    if (config.stateManagement == StateManagement.bloc ||
        config.stateManagement == StateManagement.cubit) {
      _write(
        '${config.app}/lib/app/storage/hydrated_store.dart',
        storage.hydratedStorageAdapter(config),
      );
    }
    if (config.testScope == TestScope.full) {
      _write(
        '${config.app}/integration_test/app_test.dart',
        ci.appIntegrationTest(config),
      );
    }
  }

  // ── AI Agent Skills ──────────────────────────────────────
  void _writeSkills() {
    _log('Writing AI agent skills...');
    _write('.claude/settings.json', skills.claudeSettings());
    _write(
      '.claude/skills/component-design/SKILL.md',
      skills.componentDesignSkill(config),
    );
    _write(
      '.claude/skills/screen-design/SKILL.md',
      skills.screenDesignSkill(config),
    );
    _write(
      '.claude/skills/business-logic/SKILL.md',
      skills.businessLogicSkill(config),
    );
    _write(
      '.claude/skills/monorepo-doctor/SKILL.md',
      skills.monrepoDoctorSkill(config),
    );
  }

  // ── Build flavors ───────────────────────────────────────
  void _writeFlavors() {
    if (!config.flavors) return;
    _log('Writing build flavors...');

    _write(
      '${config.app}/lib/app/config/app_environment.dart',
      flavor.appEnvironment(config),
    );
    for (final name in flavor.flavorNames) {
      _write(
        '${config.app}/lib/main_$name.dart',
        flavor.flavorEntrypoint(config, name),
      );
    }
    _write('FLAVORS.md', flavor.flavorsDoc(config));

    if (config.platforms.contains('android')) _patchAndroidFlavors();

    if (config.platforms.contains('ios')) {
      for (final name in flavor.flavorNames) {
        _write(
          '${config.app}/ios/Flutter/$name.xcconfig',
          flavor.iosFlavorConfig(config, name),
        );
      }
    }
  }

  /// Injects product flavors into the build file `flutter create` produced.
  ///
  /// Patching generated Gradle is inherently version-sensitive, so a failure
  /// to find the anchor is reported rather than silently skipped.
  void _patchAndroidFlavors() {
    final gradle = File('$rootPath/${config.app}/android/app/build.gradle.kts');
    if (!gradle.existsSync()) {
      _fail('android/app/build.gradle.kts not found — flavors not applied');
      return;
    }

    final content = gradle.readAsStringSync();
    const anchor = '    buildTypes {';
    if (!content.contains(anchor)) {
      _fail(
        'could not find the buildTypes block in build.gradle.kts — '
        'Android flavors not applied',
      );
      return;
    }

    gradle.writeAsStringSync(
      content.replaceFirst(anchor, '${flavor.androidFlavors(config)}$anchor'),
    );
    _patchAndroidManifestLabel();
  }

  /// Points the launcher label at the per-flavor `app_name` resource.
  void _patchAndroidManifestLabel() {
    final manifest = File(
      '$rootPath/${config.app}/android/app/src/main/AndroidManifest.xml',
    );
    if (!manifest.existsSync()) return;
    final content = manifest.readAsStringSync();
    final updated = content.replaceFirst(
      RegExp(r'android:label="[^"]*"'),
      r'android:label="@string/app_name"',
    );
    if (updated != content) manifest.writeAsStringSync(updated);
  }

  // ── Post-generation commands ────────────────────────────
  Future<void> _resolveDependencies() async {
    _log('Resolving dependencies...');
    final result = await Process.run(
      'dart',
      ['pub', 'get'],
      workingDirectory: rootPath,
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      _fail('dart pub get failed — dependencies are unresolved');
    }
  }

  Future<void> _generateL10n() async {
    _log('Generating l10n...');
    final result = await Process.run(
      'flutter',
      ['gen-l10n'],
      workingDirectory: '$rootPath/packages/l10n',
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      // The app package does not set `generate: true`, so building the app
      // will not produce these files later — the failure is terminal.
      _fail('flutter gen-l10n failed — AppLocalizations was not generated');
    }
  }

  /// Formats the generated tree.
  ///
  /// The templates are written for readability as source strings, not to match
  /// dart format's output, so the generated CI's `dart format
  /// --set-exit-if-changed` step failed on a freshly generated project.
  /// Formatting here keeps that guarantee without constraining the templates.
  Future<void> _formatCode() async {
    _log('Formatting generated code...');
    final result = await Process.run(
      'dart',
      ['format', '.'],
      workingDirectory: rootPath,
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      _fail('dart format failed — generated code is not format-clean');
    }
  }

  Future<void> _analyze() async {
    _log('Running dart analyze...');
    final result = await Process.run(
      'dart',
      ['analyze'],
      workingDirectory: rootPath,
      runInShell: true,
    );
    stdout.writeln(result.stdout);
    if (result.exitCode != 0) {
      stdout.writeln(result.stderr);
      _fail('dart analyze reported problems in the generated project');
    }
  }

  Future<void> _initializeGit() async {
    if (!config.gitInit) return;
    _log('Initializing git repository...');
    for (final step in [
      ['init'],
      ['add', '.'],
      ['commit', '-m', 'Initial commit: ${config.pascal} monorepo'],
    ]) {
      final result = await Process.run(
        'git',
        step,
        workingDirectory: rootPath,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        stderr.writeln(result.stderr);
        _fail('git ${step.first} failed — the repository is not initialized');
        return;
      }
    }
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

  void _fail(String description) => _failures.add(description);
}
