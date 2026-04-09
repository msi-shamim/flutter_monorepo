import '../../project_config.dart';

/// Interface for state-management-specific app templates.
///
/// Each framework (GetX, Riverpod, Bloc, Cubit) implements this.
/// Return an empty string from any method to skip that file.
abstract class AppTemplateStrategy {
  String appPubspec(ProjectConfig c);
  String mainDart(ProjectConfig c);
  String initialBinding(ProjectConfig c);
  String themeController(ProjectConfig c);
  String localeController(ProjectConfig c);
  String authMiddleware(ProjectConfig c);
  String appPages(ProjectConfig c);
  String appRouter(ProjectConfig c);
  String homeBinding(ProjectConfig c);
  String homeScreen(ProjectConfig c);
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
