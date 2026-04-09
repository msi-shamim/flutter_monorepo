import 'dart:convert';
import 'dart:io';

/// Resolves latest compatible package versions from pub.dev at generation time.
///
/// Fetches the latest version within the same major version as our tested
/// fallbacks. This ensures API compatibility while getting the newest patches.
/// Falls back to hardcoded defaults if offline or API fails.
class VersionResolver {
  final _cache = <String, String>{};

  /// Tested fallback versions — templates are written against these major versions.
  static const fallbacks = <String, String>{
    // State management
    'get': '^4.7.2',
    'get_storage': '^2.1.1',
    'flutter_riverpod': '^3.3.1',
    'flutter_bloc': '^9.1.0',
    'hydrated_bloc': '^10.0.0',
    // HTTP clients
    'dio': '^5.8.0+1',
    'http': '^1.3.0',
    'chopper': '^8.0.0+1',
    // Routing
    'go_router': '^14.8.1',
    // Storage
    'shared_preferences': '^2.5.3',
    'path_provider': '^2.1.5',
    // L10n
    'intl': '^0.20.2',
    // Linting
    'flutter_lints': '^6.0.0',
  };

  /// Resolves latest compatible versions for all needed packages.
  Future<void> resolveAll(List<String> packageNames) async {
    stdout.writeln('→ Fetching latest package versions from pub.dev...');
    final futures = <Future<void>>[];
    for (final name in packageNames) {
      if (!_cache.containsKey(name)) {
        futures.add(_fetchLatestCompatible(name));
      }
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

    // Extract the major version from our fallback (e.g., "^4.7.2" → 4)
    final fallbackVersion = fallback.replaceFirst('^', '').split('+').first;
    final targetMajor = int.tryParse(fallbackVersion.split('.').first) ?? 0;

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(
        Uri.parse('https://pub.dev/api/packages/$packageName'),
      );
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final versions = (json['versions'] as List<dynamic>)
            .map((v) => (v as Map<String, dynamic>)['version'] as String)
            .toList();

        // Find latest version with the same major version as our fallback
        String? bestMatch;
        for (final v in versions) {
          final clean = v.split('+').first.split('-').first; // strip build/pre-release
          final parts = clean.split('.');
          if (parts.length >= 2) {
            final major = int.tryParse(parts[0]) ?? -1;
            if (major == targetMajor) {
              if (bestMatch == null || _isNewer(v, bestMatch)) {
                bestMatch = v;
              }
            }
          }
        }

        _cache[packageName] = bestMatch != null ? '^$bestMatch' : fallback;
      } else {
        _cache[packageName] = fallback;
      }
      client.close();
    } catch (_) {
      _cache[packageName] = fallback;
    }
  }

  /// Returns true if [a] is newer than [b] using simple version comparison.
  bool _isNewer(String a, String b) {
    final aParts = a.split('+').first.split('-').first.split('.').map(int.tryParse).toList();
    final bParts = b.split('+').first.split('-').first.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final av = i < aParts.length ? (aParts[i] ?? 0) : 0;
      final bv = i < bParts.length ? (bParts[i] ?? 0) : 0;
      if (av > bv) return true;
      if (av < bv) return false;
    }
    return false;
  }
}
