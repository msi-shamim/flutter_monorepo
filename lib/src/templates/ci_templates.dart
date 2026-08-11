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
