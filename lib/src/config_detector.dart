import 'dart:io';

import 'project_config.dart';

/// Detects project configuration from existing files at [rootPath].
///
/// Reads pubspec.yaml files and source code to determine the project's
/// state management framework, HTTP client, and locales.
/// Returns `null` if [rootPath] is not a flutter_monorepo project root.
ProjectConfig? detectProjectConfig(String rootPath) {
  final fromMarker = _readMarker(rootPath);
  if (fromMarker != null) return fromMarker;

  final rootPubspec = File('$rootPath/pubspec.yaml');
  if (!rootPubspec.existsSync()) return null;

  final rootContent = rootPubspec.readAsStringSync();
  if (!_looksLikeMonorepo(rootPath, rootContent)) return null;

  // Strip only the suffix the generator appends. replaceAll would turn
  // task_workspace_workspace into "task", pointing every subsequent check at
  // a project that does not exist.
  final name = _extractYamlValue(
    rootContent,
    'name',
  )?.replaceFirst(RegExp(r'_workspace$'), '');
  if (name == null) return null;

  final appPubspecFile = File('$rootPath/${name}_app/pubspec.yaml');
  final stateManagement = _detectStateManagement(
    appPubspecFile,
    name,
    rootPath,
  );

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

/// Whether [rootPath] carries the structure this generator produces.
///
/// Used only for projects predating [projectMarkerFile]. Without it, any
/// directory holding a `pubspec.yaml` — an ordinary Dart package, or the app
/// package one level inside a real monorepo — was treated as a monorepo root,
/// and `doctor --fix` would scaffold a phantom tree into it.
bool _looksLikeMonorepo(String rootPath, String rootPubspecContent) {
  if (!rootPubspecContent.contains(RegExp(r'^workspace:', multiLine: true))) {
    return false;
  }
  return Directory('$rootPath/packages/core').existsSync() &&
      Directory('$rootPath/packages/l10n').existsSync();
}

/// Reads the generator's marker file, if this project carries one.
///
/// Values recorded at generation time are authoritative — unlike the
/// heuristics below, they cannot be wrong. Returns `null` when the file is
/// absent or lacks a usable `name`, in which case the caller falls back to
/// inference.
ProjectConfig? _readMarker(String rootPath) {
  final marker = File('$rootPath/$projectMarkerFile');
  if (!marker.existsSync()) return null;

  final content = marker.readAsStringSync();
  final name = _extractYamlValue(content, 'name');
  if (name == null || name.isEmpty) return null;

  final locales = _splitList(_extractYamlValue(content, 'locales'));
  final platforms = _splitList(_extractYamlValue(content, 'platforms'));
  final license = _extractYamlValue(content, 'license');

  return ProjectConfig(
    name: name,
    org: _extractYamlValue(content, 'org') ?? 'com.example',
    stateManagement:
        _parseEnum(
          _extractYamlValue(content, 'state'),
          StateManagement.values,
        ) ??
        StateManagement.getx,
    httpClient:
        _parseEnum(_extractYamlValue(content, 'http'), HttpClient.values) ??
        HttpClient.dio,
    licenseType: license == null
        ? LicenseType.proprietary
        : _parseLicense(license) ?? LicenseType.proprietary,
    locales: locales.isEmpty ? const ['en', 'ar'] : locales,
    platforms: platforms.isEmpty ? const ['android', 'ios'] : platforms,
    githubFiles: _extractYamlValue(content, 'github') == 'true',
    ci:
        _parseEnum(_extractYamlValue(content, 'ci'), CiProvider.values) ??
        CiProvider.none,
    testScope:
        _parseEnum(_extractYamlValue(content, 'test'), TestScope.values) ??
        TestScope.unit,
  );
}

T? _parseEnum<T extends Enum>(String? value, List<T> values) {
  if (value == null) return null;
  for (final v in values) {
    if (v.name == value) return v;
  }
  return null;
}

LicenseType? _parseLicense(String value) {
  for (final type in LicenseType.values) {
    if (type.cliName == value) return type;
  }
  return null;
}

List<String> _splitList(String? value) {
  if (value == null) return const [];
  return value
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

StateManagement _detectStateManagement(
  File pubspecFile,
  String name,
  String rootPath,
) {
  if (!pubspecFile.existsSync()) {
    // The pubspec is the strongest signal, but a project missing it is exactly
    // the case doctor is meant to help with. Defaulting to GetX here made a
    // Riverpod project look like a GetX one, so --fix wrote GetX scaffolding
    // into it. The framework-specific directories are the next best evidence.
    return _detectStateManagementFromLayout(name, rootPath) ??
        StateManagement.getx;
  }
  final content = pubspecFile.readAsStringSync();

  if (content.contains('flutter_riverpod:')) return StateManagement.riverpod;
  if (content.contains('flutter_bloc:')) {
    return _blocOrCubit('$rootPath/${name}_app/lib/app/blocs');
  }
  return StateManagement.getx;
}

/// Infers the framework from the directories the generator creates for it.
///
/// Returns `null` when the layout is ambiguous, leaving the caller to decide.
StateManagement? _detectStateManagementFromLayout(
  String name,
  String rootPath,
) {
  final appDir = '$rootPath/${name}_app/lib/app';
  if (Directory('$appDir/providers').existsSync()) {
    return StateManagement.riverpod;
  }
  if (Directory('$appDir/blocs').existsSync()) {
    return _blocOrCubit('$rootPath/${name}_app/lib/app/blocs');
  }
  if (Directory('$appDir/controllers').existsSync() ||
      Directory('$appDir/bindings').existsSync()) {
    return StateManagement.getx;
  }
  return null;
}

/// Distinguishes cubit from bloc by the base class the generated files use.
StateManagement _blocOrCubit(String blocsPath) {
  final blocsDir = Directory(blocsPath);
  if (blocsDir.existsSync()) {
    for (final f in blocsDir.listSync().whereType<File>()) {
      if (f.readAsStringSync().contains('HydratedCubit')) {
        return StateManagement.cubit;
      }
    }
  }
  return StateManagement.bloc;
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
