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
}

/// Framework-agnostic route constants — same for all state managers.
String appRoutes() => '''
abstract final class AppRoutes {
  static const String home = '/home';
}
''';

/// Helper to generate dynamic locale constants for any framework.
String localeConstants(ProjectConfig c) {
  final buf = StringBuffer();
  for (final locale in c.locales) {
    buf.writeln("  static const Locale ${_localeVarName(locale)} = Locale('$locale');");
  }
  buf.writeln('  static const List<Locale> supportedLocales = [');
  buf.writeln(c.locales.map((l) => '    ${_localeVarName(l)}').join(',\n'));
  buf.writeln('  ];');
  return buf.toString();
}

/// The Dart identifier used for [code]'s `Locale` constant.
///
/// Single source of truth: every template that names a locale constant must
/// call this, or the declaration and its references drift apart.
String localeVarName(String code) => _localeVarName(code);

String _localeVarName(String code) {
  const names = {
    'en': 'english', 'ar': 'arabic', 'es': 'spanish', 'fr': 'french',
    'de': 'german', 'pt': 'portuguese', 'zh': 'chinese', 'ja': 'japanese',
    'ko': 'korean', 'hi': 'hindi', 'tr': 'turkish', 'ru': 'russian',
    'it': 'italian', 'nl': 'dutch', 'pl': 'polish', 'sv': 'swedish',
    'th': 'thai', 'vi': 'vietnamese', 'id': 'indonesian', 'ms': 'malay',
  };
  return names[code] ?? 'locale_$code';
}
