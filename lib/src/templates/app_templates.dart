import '../project_config.dart';

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
  get: ^4.7.2
  get_storage: ^2.1.1
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
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
''';

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
      locale: const Locale('en'),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
    );
  }
}
''';

String initialBinding() => '''
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

String themeController() => '''
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

String localeController() => '''
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocaleController extends GetxController {
  static const Locale english = Locale('en');
  static const Locale arabic = Locale('ar');
  static const List<Locale> supportedLocales = [english, arabic];
  static const _storageKey = 'locale';

  final _storage = GetStorage();
  final _locale = english.obs;

  Locale get locale => _locale.value;
  bool get isArabic => _locale.value.languageCode == 'ar';
  bool get isRTL => isArabic;

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

  void toggleLocale() => setLocale(isArabic ? english : arabic);

  ui.TextDirection get textDirection =>
      isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;

  void _loadLocale() {
    final stored = _storage.read<String>(_storageKey);
    if (stored != null) {
      final locale = supportedLocales.firstWhere(
        (l) => l.languageCode == stored,
        orElse: () => english,
      );
      _locale.value = locale;
      Get.updateLocale(locale);
    }
  }
}
''';

String authMiddleware() => '''
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

String appRoutes() => '''
abstract final class AppRoutes {
  static const String home = '/home';
}
''';

String appPages() => '''
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

String homeController() => '''
import 'package:get/get.dart';

class HomeController extends GetxController {}
''';

String homeBinding() => '''
import 'package:get/get.dart';

import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
  }
}
''';

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
                localeCtrl.isArabic ? 'EN' : '\\u0639',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              tooltip: l10n.language,
              onPressed: localeCtrl.toggleLocale,
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
