import 'dart:io';

import 'project_config.dart';

/// Detects project configuration from existing files at [rootPath].
///
/// Reads pubspec.yaml files and source code to determine the project's
/// state management framework, HTTP client, and locales.
/// Returns `null` if [rootPath] is not a flutter_monorepo project root.
ProjectConfig? detectProjectConfig(String rootPath) {
  final rootPubspec = File('$rootPath/pubspec.yaml');
  if (!rootPubspec.existsSync()) return null;

  final rootContent = rootPubspec.readAsStringSync();
  final name =
      _extractYamlValue(rootContent, 'name')?.replaceAll('_workspace', '');
  if (name == null) return null;

  final appPubspecFile = File('$rootPath/${name}_app/pubspec.yaml');
  final stateManagement =
      _detectStateManagement(appPubspecFile, name, rootPath);

  final netPubspecFile = File('$rootPath/packages/network/pubspec.yaml');
  final httpClient = _detectHttpClient(netPubspecFile);

  final locales = _detectLocales(rootPath);

  return ProjectConfig(
    name: name,
    org: 'com.example', // not detectable, not needed for workflows or checks
    stateManagement: stateManagement,
    httpClient: httpClient,
    locales: locales,
  );
}

StateManagement _detectStateManagement(
    File pubspecFile, String name, String rootPath) {
  if (!pubspecFile.existsSync()) return StateManagement.getx;
  final content = pubspecFile.readAsStringSync();

  if (content.contains('flutter_riverpod:')) return StateManagement.riverpod;
  if (content.contains('flutter_bloc:')) {
    final blocsDir = Directory('$rootPath/${name}_app/lib/app/blocs');
    if (blocsDir.existsSync()) {
      final files = blocsDir.listSync().whereType<File>();
      for (final f in files) {
        if (f.readAsStringSync().contains('HydratedCubit')) {
          return StateManagement.cubit;
        }
      }
    }
    return StateManagement.bloc;
  }
  return StateManagement.getx;
}

HttpClient _detectHttpClient(File pubspecFile) {
  if (!pubspecFile.existsSync()) return HttpClient.dio;
  final content = pubspecFile.readAsStringSync();

  if (content.contains('chopper:')) return HttpClient.chopper;
  if (content.contains('  http:')) return HttpClient.http;
  return HttpClient.dio;
}

List<String> _detectLocales(String rootPath) {
  final arbDir = Directory('$rootPath/packages/l10n/lib/l10n/arb');
  if (!arbDir.existsSync()) return ['en', 'ar'];

  final locales = <String>[];
  for (final entity in arbDir.listSync()) {
    if (entity is File) {
      final name = entity.uri.pathSegments.last;
      final match = RegExp(r'^app_(\w+)\.arb$').firstMatch(name);
      if (match != null) locales.add(match.group(1)!);
    }
  }
  return locales.isEmpty ? ['en', 'ar'] : locales;
}

String? _extractYamlValue(String content, String key) {
  final match = RegExp('^$key:\\s*(.+)', multiLine: true).firstMatch(content);
  return match?.group(1)?.trim();
}
