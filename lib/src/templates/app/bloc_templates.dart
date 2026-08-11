import '../../project_config.dart';
import '../../version.dart';
import 'app_template_strategy.dart';

class BlocTemplateStrategy extends AppTemplateStrategy {
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
  flutter_bloc: ${c.versions['flutter_bloc']}
  hydrated_bloc: ${c.versions['hydrated_bloc']}
  go_router: ${c.versions['go_router']}
  path_provider: ${c.versions['path_provider']}
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:${c.l10n}/${c.l10n}.dart';
import 'package:${c.ui}/${c.ui}.dart';

import 'app/blocs/locale_bloc.dart';
import 'app/blocs/theme_bloc.dart';
import 'app/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeBloc()),
        BlocProvider(create: (_) => LocaleBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleBloc, Locale>(
            builder: (context, locale) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: locale,
                routerConfig: appRouter,
              );
            },
          );
        },
      ),
    );
  }
}
''';

  @override
  String initialBinding(ProjectConfig c) => ''; // No bindings in Bloc

  @override
  String themeController(ProjectConfig c) => '''
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

sealed class ThemeEvent {}

class SetThemeMode extends ThemeEvent {
  SetThemeMode(this.mode);
  final ThemeMode mode;
}

class ToggleTheme extends ThemeEvent {}

class ThemeBloc extends HydratedBloc<ThemeEvent, ThemeMode> {
  ThemeBloc() : super(ThemeMode.system) {
    on<SetThemeMode>((event, emit) => emit(event.mode));
    on<ToggleTheme>((event, emit) {
      final isDark = state == ThemeMode.dark ||
          (state == ThemeMode.system &&
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark);
      emit(isDark ? ThemeMode.light : ThemeMode.dark);
    });
  }

  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    final index = json['theme_mode'] as int?;
    if (index != null && index >= 0 && index < ThemeMode.values.length) {
      return ThemeMode.values[index];
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(ThemeMode state) => {'theme_mode': state.index};
}
''';

  @override
  String localeController(ProjectConfig c) =>
      '''
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

sealed class LocaleEvent {}

class SetLocale extends LocaleEvent {
  SetLocale(this.locale);
  final Locale locale;
}

class CycleLocale extends LocaleEvent {}

class LocaleBloc extends HydratedBloc<LocaleEvent, Locale> {
${localeConstants(c)}

  LocaleBloc() : super(supportedLocales.first) {
    on<SetLocale>((event, emit) => emit(event.locale));
    on<CycleLocale>((event, emit) {
      final idx = supportedLocales.indexOf(state);
      final next = (idx + 1) % supportedLocales.length;
      emit(supportedLocales[next]);
    });
  }

  @override
  Locale? fromJson(Map<String, dynamic> json) {
    final code = json['locale'] as String?;
    if (code != null) {
      return supportedLocales.firstWhere(
        (l) => l.languageCode == code,
        orElse: () => supportedLocales.first,
      );
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(Locale state) => {'locale': state.languageCode};
}
''';

  @override
  String authMiddleware(ProjectConfig c) => ''; // Auth handled via GoRouter redirect

  @override
  String appPages(ProjectConfig c) => ''; // Bloc uses GoRouter

  @override
  String appRouter(ProjectConfig c) => '''
import 'package:go_router/go_router.dart';

import '../../screens/home/home_screen.dart';
import '../routes/app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
  // TODO: Add redirect for auth guard
  // redirect: (context, state) {
  //   final isLoggedIn = context.read<AuthBloc>().state.isLoggedIn;
  //   if (!isLoggedIn) return AppRoutes.login;
  //   return null;
  // },
);
''';

  @override
  String homeBinding(ProjectConfig c) => ''; // No bindings in Bloc

  @override
  String homeController(ProjectConfig c) => ''; // State lives in Blocs

  @override
  String testSetup(ProjectConfig c) => '''
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Runs automatically before every test in this directory.
///
/// The theme and locale blocs are HydratedBlocs, so constructing them without
/// HydratedBloc.storage set throws before any widget renders. Tests get a
/// throwaway storage directory rather than the app's real one.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('app_test_storage');
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(dir.path),
  );
  await testMain();

  // Close before removing: the storage keeps its files open, and on Windows
  // deleting them while open fails and would report as a test failure.
  await HydratedBloc.storage.close();
  try {
    dir.deleteSync(recursive: true);
  } on FileSystemException {
    // A leftover temp directory is not worth failing a test run over.
  }
}
''';

  @override
  String homeScreen(ProjectConfig c) =>
      '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:${c.l10n}/${c.l10n}.dart';

import '../../app/blocs/locale_bloc.dart';
import '../../app/blocs/theme_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          BlocBuilder<LocaleBloc, Locale>(
            builder: (context, locale) => IconButton(
              icon: Text(
                locale.languageCode.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              tooltip: l10n.language,
              onPressed: () => context.read<LocaleBloc>().add(CycleLocale()),
            ),
          ),
          BlocBuilder<ThemeBloc, ThemeMode>(
            builder: (context, themeMode) {
              final isDark = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) == Brightness.dark);
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                tooltip: l10n.theme,
                onPressed: () => context.read<ThemeBloc>().add(ToggleTheme()),
              );
            },
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
