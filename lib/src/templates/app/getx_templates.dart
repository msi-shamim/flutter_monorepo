import '../../project_config.dart';
import '../../version.dart';
import 'app_template_strategy.dart';

class GetxTemplateStrategy extends AppTemplateStrategy {
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
  get: ${c.versions['get']}
  get_storage: ${c.versions['get_storage']}
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
${testDevDependencies(c)}

flutter:
  uses-material-design: true
''';

  @override
  String mainDart(ProjectConfig c) =>
      '''
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
  String localeController(ProjectConfig c) =>
      '''
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocaleController extends GetxController {
${localeConstants(c)}
  static const _storageKey = 'locale';

  final _storage = GetStorage();
  final _locale = ${localeVarName(c.primaryLocale)}.obs;

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
        orElse: () => ${localeVarName(c.primaryLocale)},
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

/// Route guard. Not attached to any route yet — add it to the pages that
/// require authentication:
///
///     GetPage(
///       name: AppRoutes.home,
///       page: () => const HomeScreen(),
///       binding: HomeBinding(),
///       middlewares: [AuthMiddleware()],
///     )
///
/// Build the login screen and register AppRoutes.login first.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // TODO: Replace with a real auth check.
    final isAuthenticated = _checkAuth();
    if (!isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
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
  String testDevDependencies(ProjectConfig c) =>
      '  path_provider_platform_interface: any\n';

  @override
  String testSetup(ProjectConfig c) => '''
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Runs automatically before every test in this directory.
///
/// The controllers read GetStorage as they initialise, and GetStorage resolves
/// its location through path_provider, which is not registered under
/// `flutter test`. Without this, any widget test that pumps the app fails
/// before rendering a frame.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dir = Directory.systemTemp.createTempSync('app_test_storage');
  PathProviderPlatform.instance = _TestPathProvider(dir.path);
  await GetStorage.init();
  await testMain();

  // Best effort: GetStorage keeps its file open, and on Windows deleting an
  // open file fails and would surface as a test failure.
  try {
    dir.deleteSync(recursive: true);
  } on FileSystemException {
    // A leftover temp directory is not worth failing a test run over.
  }
}

class _TestPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _TestPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getApplicationSupportPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}
''';

  @override
  String homeScreen(ProjectConfig c) =>
      '''
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

String _localeToggleMethod(ProjectConfig c) {
  // Always use cycleLocale for consistency
  return '''  void cycleLocale() {
    final idx = supportedLocales.indexOf(_locale.value);
    final next = (idx + 1) % supportedLocales.length;
    setLocale(supportedLocales[next]);
  }''';
}
