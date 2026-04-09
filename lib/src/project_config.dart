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

  static String _toPascalCase(String input) {
    return input
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join();
  }
}
