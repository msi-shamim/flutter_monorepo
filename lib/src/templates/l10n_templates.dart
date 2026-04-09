import '../project_config.dart';

String l10nPubspec(ProjectConfig c) => '''
name: ${c.l10n}
description: Localization package for ${c.pascal} (${c.locales.join(', ').toUpperCase()}).
publish_to: 'none'
version: 0.1.0
resolution: workspace

environment:
  sdk: ^3.10.4

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  generate: true
''';

String l10nYaml(ProjectConfig c) => '''
arb-dir: lib/l10n/arb
template-arb-file: app_${c.primaryLocale}.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n/generated
nullable-getter: false
''';

String l10nBarrel() => '''
export 'l10n/generated/app_localizations.dart';
export 'formatters/date_formatter.dart';
export 'formatters/number_formatter.dart';
export 'widgets/directionality_builder.dart';
''';

/// Generates an ARB file for the given [locale].
/// The primary locale (first in list) gets `@` description annotations.
String arbFile(ProjectConfig c, String locale) {
  final isPrimary = locale == c.primaryLocale;
  final t = _translations[locale] ?? _translations['en']!;

  final entries = <String, String>{
    'appTitle': (t['appTitle'] ?? '{app}').replaceAll('{app}', c.pascal),
    'welcomeMessage': (t['welcomeMessage'] ?? 'Welcome to {app}').replaceAll('{app}', c.pascal),
    'settings': t['settings'] ?? 'Settings',
    'language': t['language'] ?? 'Language',
    'theme': t['theme'] ?? 'Theme',
    'darkMode': t['darkMode'] ?? 'Dark Mode',
    'lightMode': t['lightMode'] ?? 'Light Mode',
  };

  const descriptions = {
    'appTitle': 'The application title',
    'welcomeMessage': 'Welcome message shown on the home screen',
    'settings': 'Settings label',
    'language': 'Language setting label',
    'theme': 'Theme setting label',
    'darkMode': 'Dark mode toggle label',
    'lightMode': 'Light mode toggle label',
  };

  final buf = StringBuffer();
  buf.writeln('{');
  buf.writeln('  "@@locale": "$locale",');

  final keys = entries.keys.toList();
  for (var i = 0; i < keys.length; i++) {
    final key = keys[i];
    final isLast = i == keys.length - 1;
    buf.write('  "$key": "${entries[key]}"');
    if (isPrimary) {
      buf.writeln(',');
      buf.write('  "@$key": { "description": "${descriptions[key]}" }');
    }
    if (!isLast) buf.write(',');
    buf.writeln();
  }

  buf.writeln('}');
  return buf.toString();
}

/// Known translations for common locales.
const _translations = <String, Map<String, String>>{
  'en': {
    'appTitle': '{app}',
    'welcomeMessage': 'Welcome to {app}',
    'settings': 'Settings',
    'language': 'Language',
    'theme': 'Theme',
    'darkMode': 'Dark Mode',
    'lightMode': 'Light Mode',
  },
  'ar': {
    'appTitle': '{app}',
    'welcomeMessage': '\u0645\u0631\u062d\u0628\u0627\u064b \u0628\u0643 \u0641\u064a {app}',
    'settings': '\u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a',
    'language': '\u0627\u0644\u0644\u063a\u0629',
    'theme': '\u0627\u0644\u0645\u0638\u0647\u0631',
    'darkMode': '\u0627\u0644\u0648\u0636\u0639 \u0627\u0644\u062f\u0627\u0643\u0646',
    'lightMode': '\u0627\u0644\u0648\u0636\u0639 \u0627\u0644\u0641\u0627\u062a\u062d',
  },
  'es': {
    'appTitle': '{app}',
    'welcomeMessage': 'Bienvenido a {app}',
    'settings': 'Configuraci\u00f3n',
    'language': 'Idioma',
    'theme': 'Tema',
    'darkMode': 'Modo oscuro',
    'lightMode': 'Modo claro',
  },
  'fr': {
    'appTitle': '{app}',
    'welcomeMessage': 'Bienvenue sur {app}',
    'settings': 'Param\u00e8tres',
    'language': 'Langue',
    'theme': 'Th\u00e8me',
    'darkMode': 'Mode sombre',
    'lightMode': 'Mode clair',
  },
  'de': {
    'appTitle': '{app}',
    'welcomeMessage': 'Willkommen bei {app}',
    'settings': 'Einstellungen',
    'language': 'Sprache',
    'theme': 'Design',
    'darkMode': 'Dunkelmodus',
    'lightMode': 'Hellmodus',
  },
  'pt': {
    'appTitle': '{app}',
    'welcomeMessage': 'Bem-vindo ao {app}',
    'settings': 'Configura\u00e7\u00f5es',
    'language': 'Idioma',
    'theme': 'Tema',
    'darkMode': 'Modo escuro',
    'lightMode': 'Modo claro',
  },
  'zh': {
    'appTitle': '{app}',
    'welcomeMessage': '\u6b22\u8fce\u4f7f\u7528 {app}',
    'settings': '\u8bbe\u7f6e',
    'language': '\u8bed\u8a00',
    'theme': '\u4e3b\u9898',
    'darkMode': '\u6df1\u8272\u6a21\u5f0f',
    'lightMode': '\u6d45\u8272\u6a21\u5f0f',
  },
  'ja': {
    'appTitle': '{app}',
    'welcomeMessage': '{app}\u3078\u3088\u3046\u3053\u305d',
    'settings': '\u8a2d\u5b9a',
    'language': '\u8a00\u8a9e',
    'theme': '\u30c6\u30fc\u30de',
    'darkMode': '\u30c0\u30fc\u30af\u30e2\u30fc\u30c9',
    'lightMode': '\u30e9\u30a4\u30c8\u30e2\u30fc\u30c9',
  },
  'ko': {
    'appTitle': '{app}',
    'welcomeMessage': '{app}\uc5d0 \uc624\uc2e0 \uac83\uc744 \ud658\uc601\ud569\ub2c8\ub2e4',
    'settings': '\uc124\uc815',
    'language': '\uc5b8\uc5b4',
    'theme': '\ud14c\ub9c8',
    'darkMode': '\ub2e4\ud06c \ubaa8\ub4dc',
    'lightMode': '\ub77c\uc774\ud2b8 \ubaa8\ub4dc',
  },
  'hi': {
    'appTitle': '{app}',
    'welcomeMessage': '{app} \u092e\u0947\u0902 \u0906\u092a\u0915\u093e \u0938\u094d\u0935\u093e\u0917\u0924 \u0939\u0948',
    'settings': '\u0938\u0947\u091f\u093f\u0902\u0917\u094d\u0938',
    'language': '\u092d\u093e\u0937\u093e',
    'theme': '\u0925\u0940\u092e',
    'darkMode': '\u0921\u093e\u0930\u094d\u0915 \u092e\u094b\u0921',
    'lightMode': '\u0932\u093e\u0907\u091f \u092e\u094b\u0921',
  },
  'tr': {
    'appTitle': '{app}',
    'welcomeMessage': '{app} uygulamasina hos geldiniz',
    'settings': 'Ayarlar',
    'language': 'Dil',
    'theme': 'Tema',
    'darkMode': 'Karanlik mod',
    'lightMode': 'Aydinlik mod',
  },
  'ru': {
    'appTitle': '{app}',
    'welcomeMessage': '\u0414\u043e\u0431\u0440\u043e \u043f\u043e\u0436\u0430\u043b\u043e\u0432\u0430\u0442\u044c \u0432 {app}',
    'settings': '\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438',
    'language': '\u042f\u0437\u044b\u043a',
    'theme': '\u0422\u0435\u043c\u0430',
    'darkMode': '\u0422\u0451\u043c\u043d\u044b\u0439 \u0440\u0435\u0436\u0438\u043c',
    'lightMode': '\u0421\u0432\u0435\u0442\u043b\u044b\u0439 \u0440\u0435\u0436\u0438\u043c',
  },
};

String dateFormatter() => '''
import 'package:intl/intl.dart';

abstract final class AppDateFormatter {
  static String short(DateTime date, String locale) => DateFormat.yMd(locale).format(date);
  static String medium(DateTime date, String locale) => DateFormat.yMMMd(locale).format(date);
  static String long(DateTime date, String locale) => DateFormat.yMMMMd(locale).format(date);
  static String time(DateTime date, String locale) => DateFormat.jm(locale).format(date);
  static String dateTime(DateTime date, String locale) => '\${medium(date, locale)} \${time(date, locale)}';
  static String custom(DateTime date, String pattern, String locale) => DateFormat(pattern, locale).format(date);
}
''';

String numberFormatter() => '''
import 'package:intl/intl.dart';

abstract final class AppNumberFormatter {
  static String decimal(num value, String locale, {int decimalDigits = 2}) =>
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimalDigits).format(value);
  static String currency(num value, String locale, {String? symbol, int decimalDigits = 2}) =>
      NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: decimalDigits).format(value);
  static String compact(num value, String locale) => NumberFormat.compact(locale: locale).format(value);
  static String percent(num value, String locale) => NumberFormat.percentPattern(locale).format(value);
  static String integer(num value, String locale) =>
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0).format(value);
}
''';

String directionalityBuilder() => '''
import 'package:flutter/widgets.dart';

class DirectionalityBuilder extends StatelessWidget {
  const DirectionalityBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, bool isRTL) builder;

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return builder(context, isRTL);
  }
}
''';

String l10nPackageMd(ProjectConfig c) => '''
# ${c.l10n}

Localization (${c.locales.join(', ').toUpperCase()}), formatters, and RTL helpers.

## What belongs here

- ARB files for all supported locales
- Locale-aware date/number formatters
- RTL helper widgets (`DirectionalityBuilder`)

## What is PROHIBITED

- GetX, Flutter widgets (beyond RTL helpers), business logic, HTTP clients
''';
