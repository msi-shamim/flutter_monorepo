/// Holds all derived names for a project.
class ProjectConfig {
  ProjectConfig({
    required this.name,
    required this.org,
  })  : app = '${name}_app',
        core = '${name}_core',
        ui = '${name}_ui',
        network = '${name}_network',
        l10n = '${name}_l10n',
        pascal = _toPascalCase(name);

  final String name;
  final String org;
  final String app;
  final String core;
  final String ui;
  final String network;
  final String l10n;
  final String pascal;

  static String _toPascalCase(String input) {
    return input
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join();
  }
}
