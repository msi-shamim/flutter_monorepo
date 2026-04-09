import 'version_resolver.dart';

/// Supported state management frameworks.
enum StateManagement { getx, riverpod, bloc, cubit }

/// Supported HTTP client libraries.
enum HttpClient { dio, http, chopper }

/// Holds all derived names and user choices for a project.
class ProjectConfig {
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

  final String name;
  final String org;
  final StateManagement stateManagement;
  final List<String> locales;
  final List<String> platforms;
  final HttpClient httpClient;
  final bool gitInit;

  /// Populated by [VersionResolver] before template generation.
  late final VersionResolver versions;

  final String app;
  final String core;
  final String ui;
  final String network;
  final String l10n;
  final String pascal;

  /// The first locale in the list — used as the template ARB.
  String get primaryLocale => locales.first;

  /// Whether the chosen state management uses GoRouter.
  bool get usesGoRouter => stateManagement != StateManagement.getx;

  /// Returns the list of pub.dev packages needed for this configuration.
  List<String> get requiredPackages {
    final pkgs = <String>['flutter_lints', 'intl'];
    // HTTP client
    switch (httpClient) {
      case HttpClient.dio:
        pkgs.add('dio');
      case HttpClient.http:
        pkgs.add('http');
      case HttpClient.chopper:
        pkgs.add('chopper');
    }
    // State management
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
