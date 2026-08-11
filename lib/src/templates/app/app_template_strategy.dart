import '../../project_config.dart';

/// Interface for state-management-specific app templates.
///
/// Each framework (GetX, Riverpod, Bloc, Cubit) implements this.
/// Return an empty string from any method to skip that file.
abstract class AppTemplateStrategy {
  /// Generates the app's `pubspec.yaml` with framework-specific dependencies.
  String appPubspec(ProjectConfig c);

  /// Generates `main.dart` with the framework's app widget and initialization.
  String mainDart(ProjectConfig c);

  /// Generates the initial DI binding. Empty string if not applicable.
  String initialBinding(ProjectConfig c);

  /// Generates the theme controller/provider/bloc.
  String themeController(ProjectConfig c);

  /// Generates the locale controller/provider/bloc.
  String localeController(ProjectConfig c);

  /// Generates route guard middleware. Empty string if not applicable.
  String authMiddleware(ProjectConfig c);

  /// Generates the route page registry (GetX). Empty for GoRouter frameworks.
  String appPages(ProjectConfig c);

  /// Generates the GoRouter configuration. Empty for GetX.
  String appRouter(ProjectConfig c);

  /// Generates per-screen DI binding. Empty if not applicable.
  String homeBinding(ProjectConfig c);

  /// Generates the home screen widget.
  String homeScreen(ProjectConfig c);

  /// Generates the home screen controller/bloc. Empty if not applicable.
  String homeController(ProjectConfig c);

  /// Generates `test/flutter_test_config.dart` for the app package.
  ///
  /// The theme and locale state read from persistent storage as they are
  /// built, and storage plugins are not registered under `flutter test`. Any
  /// widget test that pumps the app therefore fails on the platform
  /// instance before it renders anything. Flutter runs this file
  /// automatically for every test in the directory, so the in-memory
  /// substitute is installed without each test having to know about it.
  String testSetup(ProjectConfig c);

  /// Extra dev dependencies the generated tests require, as pubspec lines.
  String testDevDependencies(ProjectConfig c) => '';
}

/// The integration_test dev dependency, for `--test full` only.
///
/// It is an SDK package, so it costs nothing to resolve but is omitted from
/// unit-scope projects to keep their pubspec to what they actually use.
String integrationTestDependency(ProjectConfig c) =>
    c.testScope == TestScope.full
    ? '  integration_test:\n    sdk: flutter\n'
    : '';

/// Framework-agnostic route constants — same for all state managers.
String appRoutes() => '''
abstract final class AppRoutes {
  static const String home = '/home';

  /// Target for the auth guard. Build the screen and register the route
  /// before enabling the guard, or it will redirect to a route that
  /// does not exist.
  static const String login = '/login';
}
''';

/// Starter test for the app package, valid for every state management choice.
String appStarterTest(ProjectConfig c) =>
    '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
${_bootTestImports(c)}import 'package:${c.l10n}/${c.l10n}.dart';

import 'package:${c.app}/app/routes/app_routes.dart';
import 'package:${c.app}/main.dart';

void main() {
  group('App', () {
    // The real proof the scaffold works: the app builds, resolves its theme
    // and locale state, routes to the initial screen and renders a frame.
    // flutter_test_config.dart installs the storage substitutes this needs.
    testWidgets('boots and renders the home screen', (tester) async {
      await tester.pumpWidget(${_rootWidget(c)});
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('AppRoutes', () {
    test('declares the initial route', () {
      expect(AppRoutes.home, '/home');
    });
  });

  group('Localizations', () {
    test('every configured locale is supported', () {
      final codes = AppLocalizations.supportedLocales
          .map((l) => l.countryCode == null
              ? l.languageCode
              : '\${l.languageCode}_\${l.countryCode}')
          .toSet();
      for (final expected in ${_localeListLiteral(c)}) {
        expect(codes, contains(expected));
      }
    });
  });
}
''';

/// Framework-specific imports the boot test needs.
String _bootTestImports(ProjectConfig c) => switch (c.stateManagement) {
  StateManagement.riverpod =>
    "import 'package:flutter_riverpod/flutter_riverpod.dart';\n",
  _ => '',
};

/// The root widget expression to pump, including any framework scope wrapper.
String _rootWidget(ProjectConfig c) => switch (c.stateManagement) {
  StateManagement.riverpod => 'const ProviderScope(child: MainApp())',
  _ => 'const MainApp()',
};

String _localeListLiteral(ProjectConfig c) =>
    '[${c.locales.map((l) => "'$l'").join(', ')}]';

/// Helper to generate dynamic locale constants for any framework.
String localeConstants(ProjectConfig c) {
  final buf = StringBuffer();
  for (final locale in c.locales) {
    buf.writeln(
      '  static const Locale ${_localeVarName(locale)} = ${localeLiteral(locale)};',
    );
  }
  buf.writeln('  static const List<Locale> supportedLocales = [');
  buf.writeln(c.locales.map((l) => '    ${_localeVarName(l)}').join(',\n'));
  buf.writeln('  ];');
  return buf.toString();
}

/// The `Locale(...)` expression for [code].
///
/// A region subtag is a separate constructor argument — `Locale('en_US')`
/// would produce a locale whose language code is the literal string `en_US`.
String localeLiteral(String code) {
  final parts = code.split('_');
  if (parts.length == 2) return "Locale('${parts[0]}', '${parts[1]}')";
  return "Locale('$code')";
}

/// The Dart identifier used for [code]'s `Locale` constant.
///
/// Single source of truth: every template that names a locale constant must
/// call this, or the declaration and its references drift apart.
String localeVarName(String code) => _localeVarName(code);

String _localeVarName(String code) {
  const names = {
    'en': 'english',
    'ar': 'arabic',
    'es': 'spanish',
    'fr': 'french',
    'de': 'german',
    'pt': 'portuguese',
    'zh': 'chinese',
    'ja': 'japanese',
    'ko': 'korean',
    'hi': 'hindi',
    'tr': 'turkish',
    'ru': 'russian',
    'it': 'italian',
    'nl': 'dutch',
    'pl': 'polish',
    'sv': 'swedish',
    'th': 'thai',
    'vi': 'vietnamese',
    'id': 'indonesian',
    'ms': 'malay',
  };
  return names[code] ?? 'locale_$code';
}
