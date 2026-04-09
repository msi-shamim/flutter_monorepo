import 'version_resolver.dart';

/// Supported state management frameworks.
enum StateManagement {
  /// GetX — reactive state, navigation, and DI in one package.
  getx,

  /// Riverpod — compile-safe, testable state management.
  riverpod,

  /// Bloc — event-driven state management with strict separation.
  bloc,

  /// Cubit — simplified Bloc without events, using direct emit.
  cubit,
}

/// Supported HTTP client libraries.
enum HttpClient {
  /// Dio — feature-rich HTTP client with interceptors.
  dio,

  /// http — lightweight Dart-team HTTP package.
  http,

  /// Chopper — type-safe HTTP client with interceptor chain.
  chopper,
}

/// Holds all derived names and user choices for a project.
///
/// All package names are automatically derived from [name]:
/// `name_app`, `name_core`, `name_ui`, `name_network`, `name_l10n`.
class ProjectConfig {
  /// Creates a project configuration.
  ///
  /// Only [name] and [org] are required — all other options have sensible
  /// defaults matching the most common Flutter monorepo setup.
  ProjectConfig({
    required this.name,
    required this.org,
    this.stateManagement = StateManagement.getx,
    this.locales = const ['en', 'ar'],
    this.platforms = const ['android', 'ios'],
    this.httpClient = HttpClient.dio,
    this.gitInit = true,
  })  : app = '${name}_app',
        core = '${name}_core',
        ui = '${name}_ui',
        network = '${name}_network',
        l10n = '${name}_l10n',
        pascal = _toPascalCase(name);

  /// Project name in snake_case (e.g., `my_app`).
  final String name;

  /// Organization identifier (e.g., `com.example`).
  final String org;

  /// Chosen state management framework.
  final StateManagement stateManagement;

  /// List of locale codes (e.g., `['en', 'ar', 'es']`).
  final List<String> locales;

  /// Target platforms (e.g., `['android', 'ios', 'web']`).
  final List<String> platforms;

  /// Chosen HTTP client library.
  final HttpClient httpClient;

  /// Whether to auto-initialize git with a first commit.
  final bool gitInit;

  /// Populated by [VersionResolver] before template generation.
  late final VersionResolver versions;

  /// Derived main app package name (e.g., `my_app_app`).
  final String app;

  /// Derived core package name (e.g., `my_app_core`).
  final String core;

  /// Derived UI package name (e.g., `my_app_ui`).
  final String ui;

  /// Derived network package name (e.g., `my_app_network`).
  final String network;

  /// Derived l10n package name (e.g., `my_app_l10n`).
  final String l10n;

  /// PascalCase display name (e.g., `MyApp`).
  final String pascal;

  /// The first locale in the list — used as the template ARB.
  String get primaryLocale => locales.first;

  /// Whether the chosen state management uses GoRouter.
  bool get usesGoRouter => stateManagement != StateManagement.getx;

  /// Returns the list of pub.dev packages needed for this configuration.
  List<String> get requiredPackages {
    final pkgs = <String>['flutter_lints', 'intl'];
    switch (httpClient) {
      case HttpClient.dio:
        pkgs.add('dio');
      case HttpClient.http:
        pkgs.add('http');
      case HttpClient.chopper:
        pkgs.add('chopper');
    }
    switch (stateManagement) {
      case StateManagement.getx:
        pkgs.addAll(['get', 'get_storage']);
      case StateManagement.riverpod:
        pkgs.addAll(['flutter_riverpod', 'go_router', 'shared_preferences']);
      case StateManagement.bloc:
      case StateManagement.cubit:
        pkgs.addAll(['flutter_bloc', 'hydrated_bloc', 'go_router', 'path_provider']);
    }
    return pkgs;
  }

  static String _toPascalCase(String input) {
    return input
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join();
  }
}
