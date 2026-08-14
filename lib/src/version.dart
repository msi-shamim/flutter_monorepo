/// The current version of the `flutter_monorepo` package.
///
/// This is the single source of truth for the version reported by
/// `flutter_monorepo --version`. It must stay in sync with the `version:`
/// field in `pubspec.yaml` — a test asserts the two match, so bumping one
/// without the other fails the suite.
const packageVersion = '1.7.0';

/// The Dart SDK constraint declared by every generated pubspec.
///
/// This is the compatibility contract a generated project makes with its
/// users, so it also bounds which package versions may be resolved into it:
/// a dependency requiring a newer SDK than this would make `pub get` fail for
/// anyone on the declared floor. [generatedSdkFloor] is its lower bound.
const generatedSdkConstraint = '^3.10.4';

/// Lower bound of [generatedSdkConstraint], used for version filtering.
const generatedSdkFloor = '3.10.4';
