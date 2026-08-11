import 'dart:convert';
import 'dart:io';

import 'version.dart';

/// Resolves latest compatible package versions from pub.dev at generation time.
///
/// Fetches the latest version within the same major version as our tested
/// fallbacks, restricted to versions a project on [generatedSdkFloor] can
/// actually resolve. This ensures API compatibility while getting the newest
/// patches. Falls back to hardcoded defaults if offline or API fails.
class VersionResolver {
  final _cache = <String, String>{};

  /// Tested fallback versions — templates are written against these major versions.
  static const fallbacks = <String, String>{
    // State management
    'get': '^4.7.2',
    'get_storage': '^2.1.1',
    'flutter_riverpod': '^3.3.1',
    'flutter_bloc': '^9.1.0',
    'hydrated_bloc': '^11.0.0',
    // HTTP clients
    'dio': '^5.8.0+1',
    'http': '^1.3.0',
    'chopper': '^8.0.0+1',
    // Routing
    'go_router': '^17.5.0',
    // Storage
    'shared_preferences': '^2.5.3',
    'path_provider': '^2.1.5',
    // L10n
    'intl': '^0.20.2',
    // Linting
    'flutter_lints': '^6.0.0',
    // Testing (pure Dart packages cannot use flutter_test)
    'test': '^1.25.0',
  };

  /// Packages whose version is dictated by the Flutter SDK itself.
  ///
  /// `flutter_localizations` depends on an exact `intl` version, so any
  /// constraint we resolve that excludes it makes `pub get` fail outright.
  /// These are never fetched — the tested [fallbacks] entry is authoritative
  /// because it is the version the pinned SDK package ships against.
  /// `flutter_test` pins `test_api`, which transitively constrains `test` for
  /// every package sharing the workspace resolution, so `test` belongs here
  /// too even though nothing in the SDK depends on it directly.
  static const sdkPinned = <String>{'intl', 'test'};

  /// Resolves latest compatible versions for all needed packages.
  Future<void> resolveAll(List<String> packageNames) async {
    stdout.writeln('→ Fetching latest package versions from pub.dev...');
    final futures = <Future<void>>[];
    for (final name in packageNames) {
      if (_cache.containsKey(name)) continue;
      if (sdkPinned.contains(name)) {
        // Pinned by the Flutter SDK — resolving it would only break pub get.
        _cache[name] = fallbacks[name] ?? 'any';
        continue;
      }
      futures.add(_fetchLatestCompatible(name));
    }
    await Future.wait(futures);
  }

  /// Returns the version constraint for [packageName].
  String operator [](String packageName) {
    return _cache[packageName] ?? fallbacks[packageName] ?? 'any';
  }

  Future<void> _fetchLatestCompatible(String packageName) async {
    final fallback = fallbacks[packageName];
    if (fallback == null) {
      _cache[packageName] = 'any';
      return;
    }

    // The series a caret constraint keeps you inside. For 1.0.0 and above that
    // is the major version; below it, pub treats each 0.x as its own breaking
    // series, so ^0.20.2 must not accept 0.21.0 the way "major 0" would.
    final fallbackVersion = fallback.replaceFirst('^', '').split('+').first;
    final targetSeries = caretSeries(fallbackVersion);
    if (targetSeries == null) {
      _cache[packageName] = fallback;
      return;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(
        Uri.parse('https://pub.dev/api/packages/$packageName'),
      );
      // connectionTimeout bounds only the TCP connect, so a server that
      // accepts the connection and then stalls would hang generation forever.
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 10));
        final json = jsonDecode(body) as Map<String, dynamic>;
        final entries = (json['versions'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

        // Find latest version with the same major version as our fallback
        // that a project on [generatedSdkFloor] can actually resolve.
        String? bestMatch;
        for (final entry in entries) {
          final v = entry['version'] as String;
          // Never resolve a pre-release into a generated pubspec: during any
          // pre-release window it outranks the newest stable release.
          if (v.contains('-')) continue;
          if (caretSeries(v.split('+').first) == targetSeries &&
              _satisfiesGeneratedSdk(entry)) {
            if (bestMatch == null || isNewer(v, bestMatch)) {
              bestMatch = v;
            }
          }
        }

        _cache[packageName] = bestMatch != null ? '^$bestMatch' : fallback;
      } else {
        _cache[packageName] = fallback;
      }
    } catch (_) {
      _cache[packageName] = fallback;
    } finally {
      // Every early return and throw above used to skip this, leaking one
      // client per failed package while resolveAll fetches them concurrently.
      client.close(force: true);
    }
  }

  /// The compatibility series a caret constraint on [version] admits.
  ///
  /// `4.7.2` and `4.8.0` share the series `4`; `0.20.2` and `0.20.3` share
  /// `0.20`, but `0.21.0` does not — under pub's rules a leading zero shifts
  /// the breaking component one place right. Returns null if unparseable.
  String? caretSeries(String version) {
    final parts = version.split('.');
    if (parts.length < 2) return null;
    final major = int.tryParse(parts[0]);
    if (major == null) return null;
    if (major > 0) return '$major';
    if (int.tryParse(parts[1]) == null) return null;
    return '0.${parts[1]}';
  }

  /// Whether a project declaring [generatedSdkFloor] can resolve this version.
  ///
  /// Rejects candidates whose declared SDK lower bound is above our floor —
  /// those resolve fine on a newer local SDK but break `pub get` for anyone
  /// on the constraint the generated pubspecs actually declare.
  /// Unparseable or absent constraints are accepted; pub is the final arbiter.
  bool _satisfiesGeneratedSdk(Map<String, dynamic> versionEntry) {
    final pubspec = versionEntry['pubspec'];
    if (pubspec is! Map<String, dynamic>) return true;
    final environment = pubspec['environment'];
    if (environment is! Map<String, dynamic>) return true;
    return acceptsSdkConstraint(environment['sdk']);
  }

  /// Whether [sdkConstraint] admits a project declaring [generatedSdkFloor].
  ///
  /// Anything unparseable or absent is accepted; pub is the final arbiter.
  bool acceptsSdkConstraint(Object? sdkConstraint) {
    if (sdkConstraint is! String) return true;

    final lowerBound =
        RegExp(r'(?:\^|>=)\s*(\d+\.\d+\.\d+)').firstMatch(sdkConstraint);
    if (lowerBound == null) return true;

    return !isNewer(lowerBound.group(1)!, generatedSdkFloor);
  }

  /// Returns true if [a] is newer than [b] using simple version comparison.
  ///
  /// Build metadata breaks ties, so `8.0.0+1` ranks above `8.0.0`. Pre-release
  /// suffixes are not handled here — they are filtered out before comparison.
  bool isNewer(String a, String b) {
    final aParts = a.split('+').first.split('-').first.split('.').map(int.tryParse).toList();
    final bParts = b.split('+').first.split('-').first.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final av = i < aParts.length ? (aParts[i] ?? 0) : 0;
      final bv = i < bParts.length ? (bParts[i] ?? 0) : 0;
      if (av > bv) return true;
      if (av < bv) return false;
    }
    final aBuild = _buildNumber(a);
    final bBuild = _buildNumber(b);
    return aBuild > bBuild;
  }

  /// Numeric build metadata (`8.0.0+1` → 1), or 0 when absent or non-numeric.
  int _buildNumber(String version) {
    final plus = version.indexOf('+');
    if (plus == -1) return 0;
    return int.tryParse(version.substring(plus + 1).split('.').first) ?? 0;
  }
}
