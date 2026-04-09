import '../../project_config.dart';
import 'app_template_strategy.dart';
import 'bloc_templates.dart';

/// Cubit shares most of Bloc's structure — only the state classes differ.
/// Controllers use `Cubit` with direct `emit()` instead of `Bloc` with events.
class CubitTemplateStrategy implements AppTemplateStrategy {
  final _bloc = BlocTemplateStrategy();

  @override
  String appPubspec(ProjectConfig c) => _bloc.appPubspec(c); // Same deps

  @override
  String mainDart(ProjectConfig c) => '''
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
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
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
  String initialBinding(ProjectConfig c) => '';

  @override
  String themeController(ProjectConfig c) => '''
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) => emit(mode);

  void toggleTheme() {
    final isDark = state == ThemeMode.dark ||
        (state == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    emit(isDark ? ThemeMode.light : ThemeMode.dark);
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
  String localeController(ProjectConfig c) => '''
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class LocaleCubit extends HydratedCubit<Locale> {
${localeConstants(c)}

  LocaleCubit() : super(supportedLocales.first);

  void setLocale(Locale locale) => emit(locale);

  void cycleLocale() {
    final idx = supportedLocales.indexOf(state);
    final next = (idx + 1) % supportedLocales.length;
    emit(supportedLocales[next]);
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
  String authMiddleware(ProjectConfig c) => '';

  @override
  String appPages(ProjectConfig c) => '';

  @override
  String appRouter(ProjectConfig c) => _bloc.appRouter(c); // Same GoRouter

  @override
  String homeBinding(ProjectConfig c) => '';

  @override
  String homeController(ProjectConfig c) => '';

  @override
  String homeScreen(ProjectConfig c) => '''
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
          BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) => IconButton(
              icon: Text(
                locale.languageCode.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              tooltip: l10n.language,
              onPressed: () => context.read<LocaleCubit>().cycleLocale(),
            ),
          ),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              final isDark = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) == Brightness.dark);
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                tooltip: l10n.theme,
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
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
