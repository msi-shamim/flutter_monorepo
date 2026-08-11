import '../project_config.dart';

/// The flavors a `--flavor` project is built with.
const flavorNames = ['dev', 'staging', 'prod'];

/// Compile-time environment selected by the entrypoint.
///
/// Follows the same shape as the generated store: one value, assigned once
/// during bootstrap, so nothing reads configuration from a mutable global.
String appEnvironment(ProjectConfig c) =>
    '''
/// Build environment, chosen by which entrypoint launched the app.
enum AppEnvironment {
  /// Local development.
  dev,

  /// Pre-production verification.
  staging,

  /// Production.
  prod;

  /// Name shown in the app bar and on the launcher icon.
  String get displayName => switch (this) {
    dev => '${c.pascal} Dev',
    staging => '${c.pascal} Staging',
    prod => '${c.pascal}',
  };

  /// Base URL for API calls.
  ///
  /// Replace these with the real hosts for the project.
  String get apiBaseUrl => switch (this) {
    dev => 'https://dev.api.example.com',
    staging => 'https://staging.api.example.com',
    prod => 'https://api.example.com',
  };

  /// Whether verbose logging and debug affordances should be enabled.
  bool get isDebugBuild => this != prod;
}

/// The environment this build is running as. Valid after [initEnvironment].
late final AppEnvironment appEnv;

/// Records the environment for the running build.
///
/// Called by each entrypoint before anything reads [appEnv].
void initEnvironment(AppEnvironment env) => appEnv = env;
''';

/// A flavor-specific entrypoint, e.g. `main_staging.dart`.
///
/// Each is a two-line file: pick the environment, hand off to the shared
/// bootstrap. Keeping the app itself in `main.dart` means the widget tests and
/// the boot test are unaffected by whether flavors are enabled.
String flavorEntrypoint(ProjectConfig c, String flavor) =>
    '''
import 'app/config/app_environment.dart';
import 'main.dart';

/// Entrypoint for the $flavor flavor.
///
///     flutter run --flavor $flavor -t lib/main_$flavor.dart
void main() => bootstrap(AppEnvironment.$flavor);
''';

/// The Android product flavors block, injected into `build.gradle.kts`.
String androidFlavors(ProjectConfig c) =>
    '''

    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "${c.pascal} Dev")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "${c.pascal} Staging")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "${c.pascal}")
        }
    }
''';

/// iOS xcconfig for one flavor.
///
/// Generated for completeness, but note the limitation recorded in
/// FLAVORS.md: wiring these into Xcode schemes is a manual step, and the
/// result cannot be built or verified on a non-macOS machine.
String iosFlavorConfig(ProjectConfig c, String flavor) {
  final suffix = flavor == 'prod' ? '' : '.$flavor';
  final label = switch (flavor) {
    'dev' => '${c.pascal} Dev',
    'staging' => '${c.pascal} Staging',
    _ => c.pascal,
  };
  return '''
// Flavor: $flavor
#include "Generated.xcconfig"

FLUTTER_TARGET=lib/main_$flavor.dart
PRODUCT_BUNDLE_IDENTIFIER=${c.org}.${c.app}$suffix
PRODUCT_NAME=$label
''';
}

/// How to use and finish wiring the generated flavors.
String flavorsDoc(ProjectConfig c) => '''
# Flavors

This project builds as three environments: `dev`, `staging` and `prod`. Each
has its own entrypoint, application id and display name, so all three can be
installed side by side on one device.

## Running

```bash
flutter run --flavor dev     -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod    -t lib/main_prod.dart
```

```bash
flutter build apk --flavor prod -t lib/main_prod.dart
```

`lib/main.dart` still runs, defaulting to `dev`, so `flutter run` with no
arguments and every widget test keep working unchanged.

## Configuration

Per-environment values live in `lib/app/config/app_environment.dart`. The
entrypoint records the environment; everything else reads `appEnv`:

```dart
final client = ApiClient(baseUrl: appEnv.apiBaseUrl);
```

Replace the placeholder hosts there with the real ones.

## Android

Fully wired. `android/app/build.gradle.kts` declares the three product
flavors on an `env` dimension, `dev` and `staging` get an
`applicationIdSuffix`, and the launcher label comes from a per-flavor
`app_name` resource.

## iOS — needs manual finishing

`ios/Flutter/` contains an xcconfig per flavor, but Xcode schemes cannot be
created from a file on disk. In Xcode:

1. **Product → Scheme → Manage Schemes**, duplicate `Runner` once per flavor.
2. For each scheme, **Edit Scheme → Run → Build Configuration**, and point it
   at the matching configuration.
3. Under **Project → Info → Configurations**, set each configuration's
   xcconfig to `Flutter/<flavor>.xcconfig`.

These files were generated on a machine that cannot build for iOS, so unlike
the Android side they are a starting point rather than a verified
configuration. Check them before relying on them.
''';
