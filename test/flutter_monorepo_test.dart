import 'dart:io';

import 'package:flutter_monorepo/flutter_monorepo.dart';
import 'package:flutter_monorepo/src/templates/license_templates.dart'
    as license;
import 'package:flutter_monorepo/src/templates/root_templates.dart' as root;
import 'package:flutter_monorepo/src/templates/core_templates.dart' as core;
import 'package:flutter_monorepo/src/templates/github_templates.dart' as github;
import 'package:test/test.dart';

void main() {
  group('packageVersion', () {
    test('matches the version in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match = RegExp(
        r'^version:\s*(\S+)\s*$',
        multiLine: true,
      ).firstMatch(pubspec);
      expect(match, isNotNull, reason: 'pubspec.yaml has no version: field');
      expect(
        match!.group(1),
        packageVersion,
        reason: 'Bump lib/src/version.dart and pubspec.yaml together',
      );
    });
  });

  group('Project marker', () {
    final config = ProjectConfig(
      name: 'my_shop',
      org: 'com.acme',
      stateManagement: StateManagement.riverpod,
      httpClient: HttpClient.chopper,
      licenseType: LicenseType.mit,
      locales: ['en', 'es', 'fr'],
      platforms: ['android', 'ios', 'web'],
      githubFiles: true,
    );

    test('records every choice that cannot be inferred from the tree', () {
      final marker = root.projectMarker(config);
      expect(marker, contains('name: my_shop'));
      expect(marker, contains('org: com.acme'));
      expect(marker, contains('state: riverpod'));
      expect(marker, contains('http: chopper'));
      expect(marker, contains('license: mit'));
      expect(marker, contains('locales: en,es,fr'));
      expect(marker, contains('platforms: android,ios,web'));
      expect(marker, contains('github: true'));
    });

    test('round-trips through detectProjectConfig', () {
      final dir = Directory.systemTemp.createTempSync('fm_marker_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(
        '${dir.path}/$projectMarkerFile',
      ).writeAsStringSync(root.projectMarker(config));

      final detected = detectProjectConfig(dir.path);
      expect(detected, isNotNull);
      expect(detected!.name, 'my_shop');
      expect(detected.org, 'com.acme');
      expect(detected.stateManagement, StateManagement.riverpod);
      expect(detected.httpClient, HttpClient.chopper);
      expect(detected.licenseType, LicenseType.mit);
      expect(detected.locales, ['en', 'es', 'fr']);
      expect(detected.platforms, ['android', 'ios', 'web']);
      expect(detected.githubFiles, isTrue);
    });

    test('preserves locale order rather than filesystem order', () {
      final dir = Directory.systemTemp.createTempSync('fm_marker_order');
      addTearDown(() => dir.deleteSync(recursive: true));
      final ordered = ProjectConfig(
        name: 'app',
        org: 'com.example',
        locales: ['en', 'ar'],
      );
      File(
        '${dir.path}/$projectMarkerFile',
      ).writeAsStringSync(root.projectMarker(ordered));

      final detected = detectProjectConfig(dir.path);
      expect(detected!.locales, ['en', 'ar']);
      expect(detected.primaryLocale, 'en');
    });
  });

  group('ARCHITECTURE.md', () {
    test('describes the real package graph and choices', () {
      final config = ProjectConfig(
        name: 'my_shop',
        org: 'com.example',
        stateManagement: StateManagement.riverpod,
        httpClient: HttpClient.chopper,
        locales: ['en', 'es'],
      );
      final doc = root.architectureMd(config);
      expect(doc, contains('my_shop_core'));
      expect(doc, contains('my_shop_network'));
      expect(doc, contains('app/providers/'));
      expect(doc, contains('chopper'));
      expect(doc, contains('en, es'));
      expect(doc, contains('GoRouter'));
    });

    test('reflects GetX routing rather than GoRouter', () {
      final doc = root.architectureMd(
        ProjectConfig(
          name: 'a',
          org: 'o',
          stateManagement: StateManagement.getx,
        ),
      );
      expect(doc, contains('app_pages.dart'));
      expect(doc, isNot(contains('GoRouter')));
    });
  });

  group('Monorepo detection', () {
    test('rejects an ordinary Dart package', () {
      final dir = Directory.systemTemp.createTempSync('fm_plain_pkg');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(
        '${dir.path}/pubspec.yaml',
      ).writeAsStringSync('name: my_cool_tool\nversion: 1.0.0\n');
      Directory('${dir.path}/lib').createSync();

      expect(detectProjectConfig(dir.path), isNull);
    });

    test('rejects a workspace root with no package tree', () {
      final dir = Directory.systemTemp.createTempSync('fm_bare_ws');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(
        '${dir.path}/pubspec.yaml',
      ).writeAsStringSync('name: thing_workspace\nworkspace:\n  - app\n');

      expect(detectProjectConfig(dir.path), isNull);
    });

    test('strips only the trailing _workspace suffix', () {
      final dir = Directory.systemTemp.createTempSync('fm_ws_name');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/pubspec.yaml').writeAsStringSync(
        'name: task_workspace_workspace\nworkspace:\n  - task_workspace_app\n',
      );
      Directory('${dir.path}/packages/core').createSync(recursive: true);
      Directory('${dir.path}/packages/l10n').createSync(recursive: true);

      expect(detectProjectConfig(dir.path)!.name, 'task_workspace');
    });

    test('accepts a pre-marker monorepo by its structure', () {
      final dir = Directory.systemTemp.createTempSync('fm_legacy');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/pubspec.yaml').writeAsStringSync(
        'name: my_app_workspace\nworkspace:\n  - my_app_app\n',
      );
      Directory('${dir.path}/packages/core').createSync(recursive: true);
      Directory('${dir.path}/packages/l10n').createSync(recursive: true);

      final detected = detectProjectConfig(dir.path);
      expect(detected, isNotNull);
      expect(detected!.name, 'my_app');
    });
  });

  group('Locale identifiers', () {
    // Every code the templates can name, plus codes with no friendly name.
    const codes = [
      'en',
      'ar',
      'es',
      'fr',
      'de',
      'pt',
      'zh',
      'ja',
      'ko',
      'hi',
      'tr',
      'ru',
      'it',
      'nl',
      'pl',
      'sv',
      'th',
      'vi',
      'id',
      'ms',
      'sw',
      'zu',
    ];

    for (final sm in StateManagement.values) {
      test('${sm.name}: every referenced locale constant is declared', () {
        for (final code in codes) {
          final config = ProjectConfig(
            name: 'my_app',
            org: 'com.example',
            stateManagement: sm,
            locales: [code, 'en'],
          );
          config.versions = VersionResolver();

          final tmpl = createAppTemplates(sm);
          final source = tmpl.localeController(config);
          if (source.trim().isEmpty) continue;

          // Collect declared constants, then confirm every locale identifier
          // the template references resolves to one of them.
          final declared = RegExp(
            r'static const Locale (\w+) =',
          ).allMatches(source).map((m) => m.group(1)!).toSet();

          final referenced = RegExp(
            r'\b(locale_[a-z0-9_]+|english|arabic|spanish|french|german|'
            r'portuguese|chinese|japanese|korean|hindi|turkish|russian|'
            r'italian|dutch|polish|swedish|thai|vietnamese|indonesian|'
            r'malay)\b',
          ).allMatches(source).map((m) => m.group(1)!).toSet();

          for (final ref in referenced) {
            expect(
              declared,
              contains(ref),
              reason:
                  '${sm.name}/$code references $ref, which is '
                  'never declared (declared: $declared)',
            );
          }
        }
      });
    }

    test('localeVarName produces a valid Dart identifier', () {
      final identifier = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');
      for (final code in [...codes, 'pt_BR', 'en_US', 'zh_Hans']) {
        expect(
          identifier.hasMatch(localeVarName(code)),
          isTrue,
          reason: '$code produced "${localeVarName(code)}"',
        );
      }
    });

    test('region subtags become a separate Locale argument', () {
      expect(localeLiteral('en'), "Locale('en')");
      expect(localeLiteral('pt_BR'), "Locale('pt', 'BR')");
      expect(localeLiteral('zh_Hans'), "Locale('zh', 'Hans')");
    });

    test('generated constants for region locales parse as Dart', () {
      final config = ProjectConfig(
        name: 'my_app',
        org: 'com.example',
        locales: ['pt_BR', 'en'],
      );
      final source = localeConstants(config);
      expect(
        source,
        contains("static const Locale locale_pt_BR = Locale('pt', 'BR');"),
      );
      expect(source, isNot(contains('-')));
    });
  });

  group('Framework detection without the app pubspec', () {
    /// Builds a pre-marker monorepo skeleton whose app has [stateDir].
    Directory skeleton(String stateDir) {
      final dir = Directory.systemTemp.createTempSync('fm_layout');
      File('${dir.path}/pubspec.yaml').writeAsStringSync(
        'name: my_app_workspace\nworkspace:\n  - my_app_app\n',
      );
      Directory('${dir.path}/packages/core').createSync(recursive: true);
      Directory('${dir.path}/packages/l10n').createSync(recursive: true);
      Directory(
        '${dir.path}/my_app_app/lib/app/$stateDir',
      ).createSync(recursive: true);
      return dir;
    }

    test('falls back to the layout instead of defaulting to GetX', () {
      final dir = skeleton('providers');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(
        detectProjectConfig(dir.path)!.stateManagement,
        StateManagement.riverpod,
      );
    });

    test('distinguishes cubit from bloc by base class', () {
      final dir = skeleton('blocs');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(
        '${dir.path}/my_app_app/lib/app/blocs/theme_bloc.dart',
      ).writeAsStringSync('class ThemeCubit extends HydratedCubit<int> {}');
      expect(
        detectProjectConfig(dir.path)!.stateManagement,
        StateManagement.cubit,
      );
    });

    test('still reports GetX for a GetX layout', () {
      final dir = skeleton('controllers');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(
        detectProjectConfig(dir.path)!.stateManagement,
        StateManagement.getx,
      );
    });

    test('cubit survives losing the files detection used to grep', () {
      // Detection distinguished cubit from bloc by finding HydratedCubit in
      // the blocs directory. With those files gone it fell back to bloc,
      // which produced bloc workflows and a bloc SKILL.md for a cubit project.
      final dir = skeleton('blocs');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/$projectMarkerFile').writeAsStringSync(
        root.projectMarker(
          ProjectConfig(
            name: 'my_app',
            org: 'com.example',
            stateManagement: StateManagement.cubit,
          ),
        ),
      );

      expect(
        detectProjectConfig(dir.path)!.stateManagement,
        StateManagement.cubit,
      );
    });

    test('a marker outranks the layout entirely', () {
      final dir = skeleton('controllers');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/$projectMarkerFile').writeAsStringSync(
        root.projectMarker(
          ProjectConfig(
            name: 'my_app',
            org: 'com.example',
            stateManagement: StateManagement.bloc,
          ),
        ),
      );
      expect(
        detectProjectConfig(dir.path)!.stateManagement,
        StateManagement.bloc,
      );
    });
  });

  group('ProjectConfig', () {
    test('derives all package names from project name', () {
      final config = ProjectConfig(name: 'my_app', org: 'com.example');
      expect(config.app, 'my_app_app');
      expect(config.core, 'my_app_core');
      expect(config.ui, 'my_app_ui');
      expect(config.network, 'my_app_network');
      expect(config.l10n, 'my_app_l10n');
    });

    test('generates PascalCase from snake_case', () {
      expect(ProjectConfig(name: 'my_app', org: 'com.example').pascal, 'MyApp');
      expect(
        ProjectConfig(name: 'hello_world', org: 'com.example').pascal,
        'HelloWorld',
      );
      expect(
        ProjectConfig(name: 'single', org: 'com.example').pascal,
        'Single',
      );
    });

    test('uses correct defaults', () {
      final config = ProjectConfig(name: 'test', org: 'com.example');
      expect(config.stateManagement, StateManagement.getx);
      expect(config.httpClient, HttpClient.dio);
      expect(config.licenseType, LicenseType.proprietary);
      expect(config.locales, ['en', 'ar']);
      expect(config.platforms, ['android', 'ios']);
      expect(config.gitInit, isTrue);
      expect(config.githubFiles, isFalse);
    });

    test('primaryLocale returns first locale', () {
      final config = ProjectConfig(
        name: 'test',
        org: 'com.example',
        locales: ['es', 'en', 'fr'],
      );
      expect(config.primaryLocale, 'es');
    });

    test('usesGoRouter is false for GetX, true for others', () {
      expect(
        ProjectConfig(
          name: 't',
          org: 'o',
          stateManagement: StateManagement.getx,
        ).usesGoRouter,
        isFalse,
      );
      expect(
        ProjectConfig(
          name: 't',
          org: 'o',
          stateManagement: StateManagement.riverpod,
        ).usesGoRouter,
        isTrue,
      );
      expect(
        ProjectConfig(
          name: 't',
          org: 'o',
          stateManagement: StateManagement.bloc,
        ).usesGoRouter,
        isTrue,
      );
      expect(
        ProjectConfig(
          name: 't',
          org: 'o',
          stateManagement: StateManagement.cubit,
        ).usesGoRouter,
        isTrue,
      );
    });

    test('requiredPackages includes correct deps for GetX', () {
      final config = ProjectConfig(
        name: 'test',
        org: 'com.example',
        stateManagement: StateManagement.getx,
        httpClient: HttpClient.dio,
      );
      final pkgs = config.requiredPackages;
      expect(pkgs, contains('get'));
      expect(pkgs, contains('get_storage'));
      expect(pkgs, contains('dio'));
      expect(pkgs, isNot(contains('flutter_riverpod')));
      expect(pkgs, isNot(contains('go_router')));
    });

    test('requiredPackages includes correct deps for Riverpod', () {
      final config = ProjectConfig(
        name: 'test',
        org: 'com.example',
        stateManagement: StateManagement.riverpod,
        httpClient: HttpClient.http,
      );
      final pkgs = config.requiredPackages;
      expect(pkgs, contains('flutter_riverpod'));
      expect(pkgs, contains('go_router'));
      expect(pkgs, contains('shared_preferences'));
      expect(pkgs, contains('http'));
      expect(pkgs, isNot(contains('get')));
      expect(pkgs, isNot(contains('dio')));
    });

    test('requiredPackages includes correct deps for Bloc', () {
      final config = ProjectConfig(
        name: 'test',
        org: 'com.example',
        stateManagement: StateManagement.bloc,
        httpClient: HttpClient.chopper,
      );
      final pkgs = config.requiredPackages;
      expect(pkgs, contains('flutter_bloc'));
      expect(pkgs, contains('hydrated_bloc'));
      expect(pkgs, contains('go_router'));
      expect(pkgs, contains('path_provider'));
      expect(pkgs, contains('chopper'));
    });
  });

  group('VersionResolver SDK pinning', () {
    test('intl is treated as SDK-pinned', () {
      expect(VersionResolver.sdkPinned, contains('intl'));
    });

    test('every SDK-pinned package has a tested fallback', () {
      for (final name in VersionResolver.sdkPinned) {
        expect(
          VersionResolver.fallbacks[name],
          isNotNull,
          reason: '$name is SDK-pinned but has no fallback to fall back to',
        );
      }
    });

    test('resolveAll uses the fallback for SDK-pinned packages', () async {
      final resolver = VersionResolver();
      await resolver.resolveAll(['intl']);
      expect(resolver['intl'], VersionResolver.fallbacks['intl']);
    });
  });

  group('VersionResolver SDK filtering', () {
    final resolver = VersionResolver();

    test('rejects versions requiring an SDK above the generated floor', () {
      expect(resolver.acceptsSdkConstraint('>=3.12.0 <4.0.0'), isFalse);
      expect(resolver.acceptsSdkConstraint('^3.12.0'), isFalse);
    });

    test('accepts versions the generated floor satisfies', () {
      expect(resolver.acceptsSdkConstraint('^3.10.4'), isTrue);
      expect(resolver.acceptsSdkConstraint('>=3.0.0 <4.0.0'), isTrue);
      expect(resolver.acceptsSdkConstraint('^3.10.0'), isTrue);
    });

    test('accepts absent or unparseable constraints', () {
      expect(resolver.acceptsSdkConstraint(null), isTrue);
      expect(resolver.acceptsSdkConstraint('any'), isTrue);
      expect(resolver.acceptsSdkConstraint(42), isTrue);
    });

    test('generatedSdkFloor is the lower bound of generatedSdkConstraint', () {
      expect(generatedSdkConstraint, '^$generatedSdkFloor');
    });
  });

  group('VersionResolver.caretSeries', () {
    final resolver = VersionResolver();

    test('groups 1.0.0 and above by major version', () {
      expect(resolver.caretSeries('4.7.2'), resolver.caretSeries('4.8.0'));
      expect(
        resolver.caretSeries('4.7.2'),
        isNot(resolver.caretSeries('5.0.0')),
      );
    });

    test('treats each 0.x as its own breaking series', () {
      expect(resolver.caretSeries('0.20.2'), resolver.caretSeries('0.20.3'));
      expect(
        resolver.caretSeries('0.20.2'),
        isNot(resolver.caretSeries('0.21.0')),
      );
    });

    test('returns null for unparseable input', () {
      expect(resolver.caretSeries('nonsense'), isNull);
      expect(resolver.caretSeries('4'), isNull);
    });
  });

  group('VersionResolver.isNewer', () {
    final resolver = VersionResolver();

    test('compares numeric components', () {
      expect(resolver.isNewer('1.2.3', '1.2.2'), isTrue);
      expect(resolver.isNewer('1.3.0', '1.2.9'), isTrue);
      expect(resolver.isNewer('2.0.0', '1.9.9'), isTrue);
      expect(resolver.isNewer('1.2.2', '1.2.3'), isFalse);
      expect(resolver.isNewer('1.2.3', '1.2.3'), isFalse);
    });

    test('build metadata breaks ties', () {
      expect(resolver.isNewer('8.0.0+1', '8.0.0'), isTrue);
      expect(resolver.isNewer('8.0.0', '8.0.0+1'), isFalse);
      expect(resolver.isNewer('8.0.0+2', '8.0.0+1'), isTrue);
    });
  });

  group('VersionResolver', () {
    test('returns fallback for known packages', () {
      final resolver = VersionResolver();
      expect(resolver['dio'], VersionResolver.fallbacks['dio']);
      expect(resolver['get'], VersionResolver.fallbacks['get']);
      expect(
        resolver['flutter_riverpod'],
        VersionResolver.fallbacks['flutter_riverpod'],
      );
    });

    test('returns "any" for unknown packages', () {
      final resolver = VersionResolver();
      expect(resolver['nonexistent_package_xyz'], 'any');
    });

    test('fallbacks all use caret syntax', () {
      for (final entry in VersionResolver.fallbacks.entries) {
        expect(
          entry.value,
          startsWith('^'),
          reason: '${entry.key} fallback should use caret syntax',
        );
      }
    });

    test('fallbacks cover all state management deps', () {
      final fb = VersionResolver.fallbacks;
      expect(fb, contains('get'));
      expect(fb, contains('get_storage'));
      expect(fb, contains('flutter_riverpod'));
      expect(fb, contains('flutter_bloc'));
      expect(fb, contains('hydrated_bloc'));
      expect(fb, contains('go_router'));
      expect(fb, contains('shared_preferences'));
      expect(fb, contains('path_provider'));
    });

    test('fallbacks cover all HTTP client deps', () {
      final fb = VersionResolver.fallbacks;
      expect(fb, contains('dio'));
      expect(fb, contains('http'));
      expect(fb, contains('chopper'));
    });
  });

  group('AppTemplateStrategy', () {
    test('factory creates correct strategy for each state management', () {
      expect(
        createAppTemplates(StateManagement.getx),
        isA<AppTemplateStrategy>(),
      );
      expect(
        createAppTemplates(StateManagement.riverpod),
        isA<AppTemplateStrategy>(),
      );
      expect(
        createAppTemplates(StateManagement.bloc),
        isA<AppTemplateStrategy>(),
      );
      expect(
        createAppTemplates(StateManagement.cubit),
        isA<AppTemplateStrategy>(),
      );
    });

    group('GetX strategy', () {
      late AppTemplateStrategy tmpl;
      late ProjectConfig config;

      setUp(() {
        tmpl = createAppTemplates(StateManagement.getx);
        config = ProjectConfig(name: 'test', org: 'com.example');
        config.versions = VersionResolver();
      });

      test('appPubspec includes get and get_storage', () {
        final pubspec = tmpl.appPubspec(config);
        expect(pubspec, contains('get:'));
        expect(pubspec, contains('get_storage:'));
        expect(pubspec, isNot(contains('flutter_riverpod')));
        expect(pubspec, isNot(contains('go_router')));
      });

      test('mainDart uses GetMaterialApp', () {
        final main = tmpl.mainDart(config);
        expect(main, contains('GetMaterialApp'));
        expect(main, contains('GetStorage.init()'));
      });

      test('initialBinding returns non-empty content', () {
        expect(tmpl.initialBinding(config).trim(), isNotEmpty);
      });

      test('appPages returns GetPage-based routes', () {
        expect(tmpl.appPages(config), contains('GetPage'));
      });

      test('appRouter returns empty (uses appPages instead)', () {
        expect(tmpl.appRouter(config).trim(), isEmpty);
      });

      test('homeScreen uses GetView and Obx', () {
        final screen = tmpl.homeScreen(config);
        expect(screen, contains('GetView'));
        expect(screen, contains('Obx'));
      });
    });

    group('Riverpod strategy', () {
      late AppTemplateStrategy tmpl;
      late ProjectConfig config;

      setUp(() {
        tmpl = createAppTemplates(StateManagement.riverpod);
        config = ProjectConfig(
          name: 'test',
          org: 'com.example',
          stateManagement: StateManagement.riverpod,
        );
        config.versions = VersionResolver();
      });

      test('appPubspec includes flutter_riverpod and go_router', () {
        final pubspec = tmpl.appPubspec(config);
        expect(pubspec, contains('flutter_riverpod:'));
        expect(pubspec, contains('go_router:'));
        expect(pubspec, contains('shared_preferences:'));
        expect(pubspec, isNot(contains('get:')));
      });

      test('mainDart uses ProviderScope', () {
        final main = tmpl.mainDart(config);
        expect(main, contains('ProviderScope'));
        expect(main, contains('ConsumerWidget'));
      });

      test('initialBinding returns empty (no bindings in Riverpod)', () {
        expect(tmpl.initialBinding(config).trim(), isEmpty);
      });

      test('appRouter returns GoRouter config', () {
        expect(tmpl.appRouter(config), contains('GoRouter'));
      });

      test('appPages returns empty (uses GoRouter)', () {
        expect(tmpl.appPages(config).trim(), isEmpty);
      });

      test('homeScreen uses ConsumerWidget', () {
        final screen = tmpl.homeScreen(config);
        expect(screen, contains('ConsumerWidget'));
        expect(screen, contains('ref.watch'));
      });
    });

    group('Bloc strategy', () {
      late AppTemplateStrategy tmpl;
      late ProjectConfig config;

      setUp(() {
        tmpl = createAppTemplates(StateManagement.bloc);
        config = ProjectConfig(
          name: 'test',
          org: 'com.example',
          stateManagement: StateManagement.bloc,
        );
        config.versions = VersionResolver();
      });

      test('appPubspec includes flutter_bloc and hydrated_bloc', () {
        final pubspec = tmpl.appPubspec(config);
        expect(pubspec, contains('flutter_bloc:'));
        expect(pubspec, contains('hydrated_bloc:'));
        expect(pubspec, contains('go_router:'));
      });

      test('mainDart uses MultiBlocProvider', () {
        expect(tmpl.mainDart(config), contains('MultiBlocProvider'));
      });

      test('themeController uses HydratedBloc with events', () {
        final theme = tmpl.themeController(config);
        expect(theme, contains('HydratedBloc'));
        expect(theme, contains('ThemeEvent'));
        expect(theme, contains('ToggleTheme'));
      });

      test('homeScreen uses BlocBuilder', () {
        expect(tmpl.homeScreen(config), contains('BlocBuilder'));
      });
    });

    group('Cubit strategy', () {
      late AppTemplateStrategy tmpl;
      late ProjectConfig config;

      setUp(() {
        tmpl = createAppTemplates(StateManagement.cubit);
        config = ProjectConfig(
          name: 'test',
          org: 'com.example',
          stateManagement: StateManagement.cubit,
        );
        config.versions = VersionResolver();
      });

      test('themeController uses HydratedCubit (no events)', () {
        final theme = tmpl.themeController(config);
        expect(theme, contains('HydratedCubit'));
        expect(theme, isNot(contains('ThemeEvent')));
        expect(theme, contains('emit('));
      });

      test('homeScreen uses BlocBuilder with Cubit types', () {
        final screen = tmpl.homeScreen(config);
        expect(screen, contains('BlocBuilder<ThemeCubit'));
        expect(screen, contains('BlocBuilder<LocaleCubit'));
      });
    });
  });

  group('core package purity', () {
    final config = ProjectConfig(name: 'my_app', org: 'com.example')
      ..versions = VersionResolver();

    test('declares no dependency on the Flutter SDK', () {
      final pubspec = core.corePubspec(config);
      expect(pubspec, isNot(contains('flutter:\n    sdk: flutter')));
      expect(pubspec, isNot(contains('flutter_test')));
    });

    test('uses package:test so dart test can run against it', () {
      expect(core.corePubspec(config), contains('test: '));
    });

    test('no core source file imports Flutter', () {
      final sources = <String>[
        core.appException(),
        core.baseModel(),
        core.baseRepository(),
        core.useCase(config),
        core.result(config),
        core.stringExtensions(),
        core.dateExtensions(),
        core.listExtensions(),
        core.coreBarrel(config),
      ];
      for (final source in sources) {
        expect(source, isNot(contains('package:flutter/')));
        expect(source, isNot(contains('dart:ui')));
      }
    });
  });

  group('Template content', () {
    late ProjectConfig config;

    setUp(() {
      config = ProjectConfig(
        name: 'my_app',
        org: 'com.test',
        locales: ['en', 'es', 'fr'],
        httpClient: HttpClient.http,
      );
      config.versions = VersionResolver();
    });

    test('localeConstants generates entries for all locales', () {
      final tmpl = createAppTemplates(StateManagement.getx);
      final controller = tmpl.localeController(config);
      expect(controller, contains("Locale('en')"));
      expect(controller, contains("Locale('es')"));
      expect(controller, contains("Locale('fr')"));
      expect(controller, contains('supportedLocales'));
    });

    test('appRoutes is framework-agnostic', () {
      final routes = appRoutes();
      expect(routes, contains("static const String home = '/home'"));
      expect(routes, isNot(contains('GetX')));
      expect(routes, isNot(contains('Riverpod')));
      expect(routes, isNot(contains('Bloc')));
    });
  });

  group('LicenseType', () {
    test('cliName returns correct identifiers', () {
      expect(LicenseType.proprietary.cliName, 'proprietary');
      expect(LicenseType.mit.cliName, 'mit');
      expect(LicenseType.apache2.cliName, 'apache-2.0');
      expect(LicenseType.bsd2clause.cliName, 'bsd-2-clause');
      expect(LicenseType.bsd3clause.cliName, 'bsd-3-clause');
      expect(LicenseType.gpl2.cliName, 'gpl-2.0');
      expect(LicenseType.gpl3.cliName, 'gpl-3.0');
      expect(LicenseType.lgpl21.cliName, 'lgpl-2.1');
      expect(LicenseType.mpl2.cliName, 'mpl-2.0');
      expect(LicenseType.unlicense.cliName, 'unlicense');
      expect(LicenseType.isc.cliName, 'isc');
    });

    test('displayName returns human-readable names', () {
      expect(LicenseType.proprietary.displayName, 'Proprietary');
      expect(LicenseType.mit.displayName, 'MIT');
      expect(LicenseType.apache2.displayName, 'Apache 2.0');
    });

    test('fromCliName round-trips all values', () {
      for (final type in LicenseType.values) {
        expect(LicenseType.fromCliName(type.cliName), type);
      }
    });

    test('fromCliName throws ArgumentError listing valid values', () {
      expect(
        () => LicenseType.fromCliName('unknown'),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.invalidValue, 'invalidValue', 'unknown')
              .having((e) => e.message, 'message', contains('apache-2.0')),
        ),
      );
    });

    test('cliNames covers every value in declaration order', () {
      expect(LicenseType.cliNames, LicenseType.values.map((e) => e.cliName));
    });
  });

  group('License templates', () {
    test('proprietary contains All Rights Reserved', () {
      final c = ProjectConfig(
        name: 'my_app',
        org: 'com.test',
        licenseType: LicenseType.proprietary,
      );
      final text = license.licenseText(c);
      expect(text, contains('All Rights Reserved'));
      expect(text, contains('MyApp'));
    });

    test('MIT contains MIT License heading', () {
      final c = ProjectConfig(
        name: 'my_app',
        org: 'com.test',
        licenseType: LicenseType.mit,
      );
      final text = license.licenseText(c);
      expect(text, contains('MIT License'));
      expect(text, contains('Permission is hereby granted'));
    });

    test('all licenses contain current year', () {
      final year = '${DateTime.now().year}';
      for (final type in LicenseType.values) {
        final c = ProjectConfig(
          name: 'test',
          org: 'com.test',
          licenseType: type,
        );
        final text = license.licenseText(c);
        // unlicense and mpl2 don't have year/copyright lines
        if (type != LicenseType.unlicense && type != LicenseType.mpl2) {
          expect(
            text,
            contains(year),
            reason: '${type.cliName} should contain year',
          );
        }
      }
    });

    test('each license type returns non-empty content', () {
      for (final type in LicenseType.values) {
        final c = ProjectConfig(
          name: 'test',
          org: 'com.test',
          licenseType: type,
        );
        expect(
          license.licenseText(c).trim(),
          isNotEmpty,
          reason: '${type.cliName} should return non-empty text',
        );
      }
    });
  });

  group('README and CONTRIBUTING templates', () {
    late ProjectConfig config;

    setUp(() {
      config = ProjectConfig(
        name: 'my_app',
        org: 'com.test',
        locales: ['en', 'ar'],
      );
    });

    test('readmeMd contains project name and structure', () {
      final readme = root.readmeMd(config);
      expect(readme, contains('# MyApp'));
      expect(readme, contains('packages/'));
      expect(readme, contains('core'));
      expect(readme, contains('my_app_app'));
    });

    test('readmeMd reflects state management choice', () {
      final readme = root.readmeMd(config);
      expect(readme, contains('getx'));
    });

    test('readmeMd reflects license type', () {
      final c = ProjectConfig(
        name: 'test',
        org: 'com.test',
        licenseType: LicenseType.mit,
      );
      final readme = root.readmeMd(c);
      expect(readme, contains('MIT'));
    });

    test('contributingMd contains contribution guidelines', () {
      final contributing = root.contributingMd(config);
      expect(contributing, contains('Contributing'));
      expect(contributing, contains('feature/'));
      expect(contributing, contains('fix/'));
      expect(contributing, contains('dart analyze'));
      expect(contributing, contains('analysis_options.yaml'));
    });

    test('contributingMd references correct app package', () {
      final contributing = root.contributingMd(config);
      expect(contributing, contains('my_app_app'));
    });
  });

  group('GitHub templates', () {
    late ProjectConfig config;

    setUp(() {
      config = ProjectConfig(name: 'my_app', org: 'com.test');
    });

    test('codeOfConduct contains Contributor Covenant', () {
      final coc = github.codeOfConduct(config);
      expect(coc, contains('Contributor Covenant'));
      expect(coc, contains('Code of Conduct'));
    });

    test('bugReportTemplate contains issue frontmatter', () {
      final tmpl = github.bugReportTemplate(config);
      expect(tmpl, contains('name: Bug Report'));
      expect(tmpl, contains('labels: bug'));
      expect(tmpl, contains('MyApp'));
    });

    test('featureRequestTemplate contains issue frontmatter', () {
      final tmpl = github.featureRequestTemplate(config);
      expect(tmpl, contains('name: Feature Request'));
      expect(tmpl, contains('labels: enhancement'));
    });

    test('pullRequestTemplate contains checklist', () {
      final tmpl = github.pullRequestTemplate(config);
      expect(tmpl, contains('- [ ]'));
      expect(tmpl, contains('dart analyze'));
      expect(tmpl, contains('dart test'));
    });

    test('ciWorkflow contains analyze and test jobs', () {
      final ci = github.ciWorkflow(config);
      expect(ci, contains('dart analyze'));
      expect(ci, contains('flutter test'));
      expect(ci, contains('dart test'));
      expect(ci, contains('my_app_app'));
    });

    test('fundingYml contains placeholder comments', () {
      final funding = github.fundingYml(config);
      expect(funding, contains('github:'));
    });
  });
}
