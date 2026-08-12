import '../../project_config.dart';
import '../../version.dart';
import '../storage_templates.dart';
import '../auth_templates.dart';
import '../flavor_helpers.dart';
import 'app_template_strategy.dart';

/// Start-up lines for the Riverpod entrypoint.
const _riverpodBootstrapBody =
    '  await initAppStore();\n'
    '  runApp(const ProviderScope(child: MainApp()));\n';

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
${storageDependency(c)}${authDependency(c)}  # Pre-wired workspace packages. core and network are not imported by the
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

${flavorBootstrapImport(c)}import 'app/providers/locale_provider.dart';
import 'app/providers/theme_provider.dart';
import 'app/router/app_router.dart';
import 'app/storage/app_store.dart';

${mainEntrypoint(c, _riverpodBootstrapBody)}

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

import '../storage/app_store.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    // Synchronous: the store is loaded before runApp, so restoring state
    // needs no async gap and no second frame.
    final stored = appStore.read<int>(_storageKey);
    if (stored != null && stored >= 0 && stored < ThemeMode.values.length) {
      return ThemeMode.values[stored];
    }
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    appStore.write(_storageKey, mode.index);
  }

  void toggleTheme() {
    final isDark = state == ThemeMode.dark ||
        (state == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
''';

  @override
  String localeController(ProjectConfig c) =>
      '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_store.dart';

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
${localeConstants(c)}
  static const _storageKey = 'locale';

  @override
  Locale build() {
    final stored = appStore.read<String>(_storageKey);
    if (stored != null) {
      return supportedLocales.firstWhere(
        (l) => l.languageCode == stored,
        orElse: () => supportedLocales.first,
      );
    }
    return supportedLocales.first;
  }

  void setLocale(Locale locale) {
    state = locale;
    appStore.write(_storageKey, locale.languageCode);
  }

  void cycleLocale() {
    final idx = supportedLocales.indexOf(state);
    final next = (idx + 1) % supportedLocales.length;
    setLocale(supportedLocales[next]);
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
