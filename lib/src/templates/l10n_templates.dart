import '../project_config.dart';

String l10nPubspec(ProjectConfig c) => '''
name: ${c.l10n}
description: Localization package for ${c.pascal} (English & Arabic).
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

String l10nYaml() => '''
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb
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

String appEnArb(ProjectConfig c) => '''
{
  "@@locale": "en",
  "appTitle": "${c.pascal}",
  "@appTitle": { "description": "The application title" },
  "welcomeMessage": "Welcome to ${c.pascal}",
  "@welcomeMessage": { "description": "Welcome message shown on the home screen" },
  "settings": "Settings",
  "@settings": { "description": "Settings label" },
  "language": "Language",
  "@language": { "description": "Language setting label" },
  "theme": "Theme",
  "@theme": { "description": "Theme setting label" },
  "darkMode": "Dark Mode",
  "@darkMode": { "description": "Dark mode toggle label" },
  "lightMode": "Light Mode",
  "@lightMode": { "description": "Light mode toggle label" }
}
''';

String appArArb(ProjectConfig c) => '''
{
  "@@locale": "ar",
  "appTitle": "${c.pascal}",
  "welcomeMessage": "مرحباً بك في ${c.pascal}",
  "settings": "الإعدادات",
  "language": "اللغة",
  "theme": "المظهر",
  "darkMode": "الوضع الداكن",
  "lightMode": "الوضع الفاتح"
}
''';

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

Localization (EN/AR), formatters, and RTL helpers.

## What belongs here

- ARB files for all supported locales
- Locale-aware date/number formatters
- RTL helper widgets (`DirectionalityBuilder`)

## What is PROHIBITED

- GetX, Flutter widgets (beyond RTL helpers), business logic, HTTP clients
''';
