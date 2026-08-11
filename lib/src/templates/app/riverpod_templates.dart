import '../../project_config.dart';
import '../../version.dart';
import 'app_template_strategy.dart';

class RiverpodTemplateStrategy extends AppTemplateStrategy {
  @override
  String appPubspec(ProjectConfig c) =>
      '''
name: ${c.app}
description: "A ${c.pascal} Flutter application."
publish_to: 'none'
version: 0.1.0
resolution: workspace

environment:
  sdk: $generatedSdkConstraint

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ${c.versions['cupertino_icons']}
  flutter_riverpod: ${c.versions['flutter_riverpod']}
  go_router: ${c.versions['go_router']}
  shared_preferences: ${c.versions['shared_preferences']}
  # Pre-wired workspace packages. core and network are not imported by the
  # generated screens yet; they are declared so feature code can import
  # them without editing this pubspec first.
  ${c.core}:
    path: ../packages/core
  ${c.ui}:
    path: ../packages/ui
  ${c.network}:
    path: ../packages/network
  ${c.l10n}:
    path: ../packages/l10n

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ${c.versions['flutter_lints']}
${testDevDependencies(c)}${integrationTestDependency(c)}

flutter:
  uses-material-design: true
''';

  @override
  String mainDart(ProjectConfig c) =>
      '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:${c.l10n}/${c.l10n}.dart';
import 'package:${c.ui}/${c.ui}.dart';

import 'app/providers/locale_provider.dart';
import 'app/providers/theme_provider.dart';
import 'app/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: router,
    );
  }
}
''';

  @override
  String initialBinding(ProjectConfig c) => ''; // No bindings in Riverpod

  @override
  String themeController(ProjectConfig c) => '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    SharedPreferencesAsync().setInt(_storageKey, mode.index);
  }

  void toggleTheme() {
    final isDark = state == ThemeMode.dark ||
        (state == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _loadTheme() async {
    final stored = await SharedPreferencesAsync().getInt(_storageKey);
    if (stored != null && stored >= 0 && stored < ThemeMode.values.length) {
      state = ThemeMode.values[stored];
    }
  }
}
''';

  @override
  String localeController(ProjectConfig c) =>
      '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
${localeConstants(c)}
  static const _storageKey = 'locale';

  @override
  Locale build() {
    _loadLocale();
    return supportedLocales.first;
  }

  void setLocale(Locale locale) {
    state = locale;
    SharedPreferencesAsync().setString(_storageKey, locale.languageCode);
  }

  void cycleLocale() {
    final idx = supportedLocales.indexOf(state);
    final next = (idx + 1) % supportedLocales.length;
    setLocale(supportedLocales[next]);
  }

  Future<void> _loadLocale() async {
    final stored = await SharedPreferencesAsync().getString(_storageKey);
    if (stored != null) {
      final locale = supportedLocales.firstWhere(
        (l) => l.languageCode == stored,
        orElse: () => supportedLocales.first,
      );
      state = locale;
    }
  }
}
''';

  @override
  String authMiddleware(ProjectConfig c) => ''; // Auth handled via GoRouter redirect

  @override
  String appPages(ProjectConfig c) => ''; // Riverpod uses GoRouter, not GetPage

  @override
  String appRouter(ProjectConfig c) => '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/home/home_screen.dart';
import '../routes/app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    // TODO: Add redirect for auth guard
    // redirect: (context, state) {
    //   final isLoggedIn = ref.read(authProvider);
    //   if (!isLoggedIn) return AppRoutes.login;
    //   return null;
    // },
  );
});
''';

  @override
  String homeBinding(ProjectConfig c) => ''; // No bindings in Riverpod

  @override
  String testDevDependencies(ProjectConfig c) =>
      '  shared_preferences_platform_interface: any\n';

  @override
  String testSetup(ProjectConfig c) => '''
import 'dart:async';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Runs automatically before every test in this directory.
///
/// The theme and locale providers read SharedPreferences while they build, and
/// plugins are not registered under `flutter test`, so without this any widget
/// test that pumps the app fails with "The SharedPreferencesAsyncPlatform
/// instance must be set" before rendering a frame.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  await testMain();
}
''';

  @override
  String homeController(ProjectConfig c) => ''; // State lives in providers

  @override
  String homeScreen(ProjectConfig c) =>
      '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:${c.l10n}/${c.l10n}.dart';

import '../../app/providers/locale_provider.dart';
import '../../app/providers/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: Text(
              locale.languageCode.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            tooltip: l10n.language,
            onPressed: () => ref.read(localeProvider.notifier).cycleLocale(),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: l10n.theme,
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: Text(l10n.welcomeMessage, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
''';
}
