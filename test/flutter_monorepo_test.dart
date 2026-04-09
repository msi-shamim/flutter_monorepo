import 'package:flutter_monorepo/flutter_monorepo.dart';
import 'package:test/test.dart';

void main() {
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
      expect(
        ProjectConfig(name: 'my_app', org: 'com.example').pascal,
        'MyApp',
      );
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
      expect(config.locales, ['en', 'ar']);
      expect(config.platforms, ['android', 'ios']);
      expect(config.gitInit, isTrue);
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
}
