import '../project_config.dart';

/// Builds the app's entrypoint around [body], the framework's start-up lines.
///
/// Without `--flavor` this is the plain `main()` it has always been. With
/// flavors, `main()` delegates to a `bootstrap` the per-flavor entrypoints also
/// call. The shape differs rather than being parameterised with an unused
/// argument, so a project that does not use flavors carries no trace of them.
String mainEntrypoint(ProjectConfig c, String body) {
  if (!c.flavors) {
    return 'void main() async {\n'
        '  WidgetsFlutterBinding.ensureInitialized();\n'
        '$body'
        '}\n';
  }

  return 'void main() => bootstrap(AppEnvironment.dev);\n'
      '\n'
      '/// Shared start-up for every entrypoint.\n'
      '///\n'
      '/// `main.dart` runs as dev; `main_staging.dart` and `main_prod.dart`\n'
      '/// call this with their own environment.\n'
      'Future<void> bootstrap(AppEnvironment env) async {\n'
      '  WidgetsFlutterBinding.ensureInitialized();\n'
      '  initEnvironment(env);\n'
      '$body'
      '}\n';
}

/// The `app_environment.dart` import, only when flavors are enabled.
String flavorBootstrapImport(ProjectConfig c) =>
    c.flavors ? "import 'app/config/app_environment.dart';\n" : '';
