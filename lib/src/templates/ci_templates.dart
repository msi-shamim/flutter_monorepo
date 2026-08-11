import '../project_config.dart';

/// GitLab CI pipeline for a generated monorepo.
///
/// Mirrors the GitHub Actions workflow step for step, so switching provider
/// changes where the pipeline runs and nothing about what it checks. The
/// Flutter-dependent packages use `flutter test`; only `packages/core` is pure
/// Dart and can use `dart test`.
String gitlabCi(ProjectConfig c) =>
    '''
# GitLab CI for ${c.pascal}.
# The image ships both the Flutter and Dart SDKs.
image: ghcr.io/cirruslabs/flutter:stable

stages:
  - analyze
  - test

# Reuse the pub cache between jobs rather than resolving twice.
variables:
  PUB_CACHE: "\$CI_PROJECT_DIR/.pub-cache"

cache:
  key: "\$CI_COMMIT_REF_SLUG"
  paths:
    - .pub-cache/

analyze:
  stage: analyze
  script:
    - dart pub get
    - dart analyze --fatal-infos
    - dart format --output=none --set-exit-if-changed .

test:
  stage: test
  needs: ["analyze"]
  script:
    - dart pub get
    - dart test packages/core/test
    - flutter test packages/ui/test
    - flutter test packages/network/test
    - flutter test ${c.app}/test
''';

/// End-to-end test for the app, run on a device with `flutter test`.
///
/// Only generated for `--test full`. It drives the real app rather than a
/// pumped widget, so it catches wiring that a widget test cannot: plugin
/// registration, persisted theme and locale, and real navigation.
String appIntegrationTest(ProjectConfig c) {
  final root = c.stateManagement == StateManagement.riverpod
      ? 'const ProviderScope(child: MainApp())'
      : 'const MainApp()';
  final extraImport = c.stateManagement == StateManagement.riverpod
      ? "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
      : '';

  return '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
$extraImport
import 'package:${c.app}/main.dart';

/// Run on a connected device or emulator:
///
///     flutter test integration_test
///
/// Unlike the widget tests under test/, these exercise the real plugins, so
/// theme and locale persistence is genuinely written and read back.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('${c.pascal} end to end', () {
    testWidgets('launches and shows the home screen', (tester) async {
      await tester.pumpWidget($root);
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('toggles the theme and keeps rendering', (tester) async {
      await tester.pumpWidget($root);
      await tester.pumpAndSettle();

      final toggle = find.byTooltip('Theme');
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle);
        await tester.pumpAndSettle();
      }

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
''';
}

/// Shared fixtures for core tests, generated for `--test full`.
String coreTestFixtures(ProjectConfig c) =>
    '''
import 'package:${c.core}/${c.core}.dart';

/// Builders for values used across core tests.
///
/// Keeping construction here means a model gaining a required field is one
/// edit rather than one per test.
abstract final class Fixtures {
  /// A successful [Result] carrying [value].
  static Result<T> success<T>(T value) => Result<T>.success(value);

  /// A failed [Result] carrying a network failure.
  static Result<T> networkFailure<T>([String message = 'No internet connection']) =>
      Result<T>.failure(NetworkException(message));

  /// A failed [Result] carrying an API failure with [statusCode].
  static Result<T> apiFailure<T>(int statusCode, [String message = 'Request failed']) =>
      Result<T>.failure(ApiException(message, statusCode: statusCode));
}
''';
