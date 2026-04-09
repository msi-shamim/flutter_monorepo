import '../../project_config.dart';
import 'app_template_strategy.dart';

class GetxTemplateStrategy implements AppTemplateStrategy {
  @override
  String appPubspec(ProjectConfig c) => '''
name: ${c.app}
description: "A ${c.pascal} Flutter application."
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
  get: ${c.versions['get']}
  get_storage: ${c.versions['get_storage']}
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

flutter:
  uses-material-design: true
''';

  @override
  String mainDart(ProjectConfig c) => '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:${c.l10n}/${c.l10n}.dart';
import 'package:${c.ui}/${c.ui}.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('${c.primaryLocale}'),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
    );
  }
}
''';

  @override
  String initialBinding(ProjectConfig c) => '''
import 'package:get/get.dart';

import '../controllers/locale_controller.dart';
import '../controllers/theme_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(LocaleController(), permanent: true);
  }
}
''';

  @override
  String themeController(ProjectConfig c) => '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static const _storageKey = 'theme_mode';

  final _storage = GetStorage();
  final _themeMode = ThemeMode.system.obs;

  ThemeMode get themeMode => _themeMode.value;

  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) return Get.isPlatformDarkMode;
    return _themeMode.value == ThemeMode.dark;
  }

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);
    _storage.write(_storageKey, mode.index);
  }

  void toggleTheme() => setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);

  void _loadTheme() {
    final stored = _storage.read<int>(_storageKey);
    if (stored != null && stored >= 0 && stored < ThemeMode.values.length) {
      _themeMode.value = ThemeMode.values[stored];
      Get.changeThemeMode(_themeMode.value);
    }
  }
}
''';

  @override
  String localeController(ProjectConfig c) => '''
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocaleController extends GetxController {
${localeConstants(c)}
  static const _storageKey = 'locale';

  final _storage = GetStorage();
  final _locale = ${_defaultLocaleVar(c)}.obs;

  Locale get locale => _locale.value;
  bool get isRTL => _locale.value.languageCode == 'ar';

  @override
  void onInit() {
    super.onInit();
    _loadLocale();
  }

  void setLocale(Locale locale) {
    _locale.value = locale;
    Get.updateLocale(locale);
    _storage.write(_storageKey, locale.languageCode);
  }

${_localeToggleMethod(c)}

  ui.TextDirection get textDirection =>
      isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;

  void _loadLocale() {
    final stored = _storage.read<String>(_storageKey);
    if (stored != null) {
      final locale = supportedLocales.firstWhere(
        (l) => l.languageCode == stored,
        orElse: () => ${_defaultLocaleVar(c)},
      );
      _locale.value = locale;
      Get.updateLocale(locale);
    }
  }
}
''';

  @override
  String authMiddleware(ProjectConfig c) => '''
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // TODO: Replace with actual auth check
    final isAuthenticated = _checkAuth();
    if (!isAuthenticated) {
      return RouteSettings(name: AppRoutes.home);
    }
    return null;
  }

  bool _checkAuth() => true;
}
''';

  @override
  String appPages(ProjectConfig c) => '''
import 'package:get/get.dart';

import '../../screens/home/home_binding.dart';
import '../../screens/home/home_screen.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static const initial = AppRoutes.home;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
  ];
}
''';

  @override
  String appRouter(ProjectConfig c) => ''; // GetX uses appPages, not GoRouter

  @override
  String homeController(ProjectConfig c) => '''
import 'package:get/get.dart';

class HomeController extends GetxController {}
''';

  @override
  String homeBinding(ProjectConfig c) => '''
import 'package:get/get.dart';

import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
  }
}
''';

  @override
  String homeScreen(ProjectConfig c) => '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:${c.l10n}/${c.l10n}.dart';

import '../../app/controllers/locale_controller.dart';
import '../../app/controllers/theme_controller.dart';
import 'home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCtrl = Get.find<ThemeController>();
    final localeCtrl = Get.find<LocaleController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          Obx(
            () => IconButton(
              icon: Text(
                localeCtrl.locale.languageCode.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              tooltip: l10n.language,
              onPressed: localeCtrl.cycleLocale,
            ),
          ),
          Obx(
            () => IconButton(
              icon: Icon(themeCtrl.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              tooltip: l10n.theme,
              onPressed: themeCtrl.toggleTheme,
            ),
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

String _defaultLocaleVar(ProjectConfig c) {
  const names = {
    'en': 'english', 'ar': 'arabic', 'es': 'spanish', 'fr': 'french',
    'de': 'german', 'pt': 'portuguese', 'zh': 'chinese', 'ja': 'japanese',
    'ko': 'korean', 'hi': 'hindi', 'tr': 'turkish', 'ru': 'russian',
  };
  return names[c.primaryLocale] ?? 'locale_${c.primaryLocale}';
}

String _localeToggleMethod(ProjectConfig c) {
  // Always use cycleLocale for consistency
  return '''  void cycleLocale() {
    final idx = supportedLocales.indexOf(_locale.value);
    final next = (idx + 1) % supportedLocales.length;
    setLocale(supportedLocales[next]);
  }''';
}
