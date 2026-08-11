import '../project_config.dart';
import '../version.dart';

String rootPubspec(ProjectConfig c) => '''
name: ${c.name}_workspace
publish_to: 'none'

environment:
  sdk: $generatedSdkConstraint

workspace:
  - ${c.app}
  - packages/core
  - packages/ui
  - packages/network
  - packages/l10n
''';

String rootGitignore() => '''
# Dart/Flutter
.dart_tool/
.packages
build/
pubspec.lock

# IDE
.idea/
*.iml
.vscode/

# OS
.DS_Store
Thumbs.db

# Env
.env
.env.*
''';

String analysisOptions() => '''
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    missing_return: error
    dead_code: warning
  language:
    strict-casts: true
    strict-raw-types: true
    strict-inference: true

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_locals
    - prefer_final_in_for_each
    - prefer_single_quotes
    - sort_child_properties_last
    - use_colored_box
    - use_decorated_box
    - sized_box_for_whitespace
    - sized_box_shrink_expand
    - use_super_parameters
    - always_declare_return_types
    - avoid_empty_else
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - avoid_type_to_string
    - avoid_types_as_parameter_names
    - cancel_subscriptions
    - close_sinks
    - no_duplicate_case_values
    - throw_in_finally
    - unnecessary_statements
    - valid_regexps
    - use_build_context_synchronously
    - use_key_in_widget_constructors
    - no_logic_in_create_state
    - avoid_unnecessary_containers
    - prefer_is_empty
    - prefer_is_not_empty
    - unnecessary_null_checks
    - unnecessary_late
    - unnecessary_this
    - prefer_null_aware_operators
    - prefer_conditional_assignment
    - prefer_spread_collections
    - prefer_if_elements_to_conditional_expressions
''';

String readmeMd(ProjectConfig c) {
  final licenseBadge = c.licenseType == LicenseType.proprietary
      ? 'Proprietary'
      : c.licenseType.displayName;
  return '''
# ${c.pascal}

> A production-ready Flutter monorepo bootstrapped with [flutter_monorepo](https://pub.dev/packages/flutter_monorepo).

## Tech Stack

| Category | Choice |
|----------|--------|
| State Management | ${c.stateManagement.name} |
| HTTP Client | ${c.httpClient.name} |
| Locales | ${c.locales.join(', ')} |
| Platforms | ${c.platforms.join(', ')} |
| License | $licenseBadge |

## Project Structure

```
${c.name}/
\u251c\u2500\u2500 ${c.app}/                  # Main Flutter application
\u251c\u2500\u2500 packages/
\u2502   \u251c\u2500\u2500 core/              # Business logic, models, use cases
\u2502   \u251c\u2500\u2500 ui/                # Shared widgets, theme, assets
\u2502   \u251c\u2500\u2500 network/           # API client, interceptors, repositories
\u2502   \u2514\u2500\u2500 l10n/              # Localization (ARB files, formatters)
\u251c\u2500\u2500 pubspec.yaml               # Workspace root
\u251c\u2500\u2500 analysis_options.yaml       # Linter rules
\u2514\u2500\u2500 README.md
```

## Getting Started

### Prerequisites

- Flutter SDK \u2265 3.10
- Dart SDK \u2265 3.10

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd ${c.name}

# Install dependencies (workspace-wide)
dart pub get

# Run the app
cd ${c.app}
flutter run
```

### Running Tests

```bash
# Run all tests from workspace root
dart test packages/core/test
dart test packages/ui/test
dart test packages/network/test
flutter test ${c.app}/test
```

### Code Analysis

```bash
dart analyze
```

## Architecture

This monorepo follows a **layered architecture** with clear package boundaries:

- **core** \u2014 Pure Dart package containing business rules, models, use cases, and extensions. No Flutter dependency.
- **ui** \u2014 Flutter package with shared widgets, theme system, responsive utilities, and asset declarations.
- **network** \u2014 HTTP client abstraction with interceptors and repository implementations.
- **l10n** \u2014 Localization package with ARB files, formatters, and RTL support.
- **${c.app}** \u2014 The main Flutter application wiring everything together with ${c.stateManagement.name} state management.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

See [LICENSE](LICENSE) for details.
''';
}

String contributingMd(ProjectConfig c) => '''
# Contributing to ${c.pascal}

Thank you for considering contributing to this project! This guide will help
you get started.

## Development Setup

1. Fork and clone the repository.
2. Run `dart pub get` at the workspace root.
3. Create a new branch for your work.

## Branch Naming

Use the following prefixes:

| Prefix | Purpose |
|--------|---------|
| `feature/` | New features |
| `fix/` | Bug fixes |
| `chore/` | Maintenance, refactoring, tooling |
| `docs/` | Documentation updates |
| `test/` | Test additions or fixes |

Example: `feature/user-profile-screen`, `fix/login-timeout`

## Code Style

This project uses strict Dart analysis rules defined in
[analysis_options.yaml](analysis_options.yaml). Before submitting:

```bash
# Run the analyzer
dart analyze

# Format your code
dart format .
```

Ensure **zero warnings** and **zero errors** before opening a PR.

## Testing

All packages have their own test directories. Write tests for any new
functionality:

```bash
# Core package
dart test packages/core/test

# UI package
flutter test packages/ui/test

# Network package
dart test packages/network/test

# App
flutter test ${c.app}/test
```

## Pull Request Guidelines

1. **Keep PRs focused** \u2014 one feature or fix per PR.
2. **Write descriptive titles** \u2014 summarize the change in under 70 characters.
3. **Include a description** \u2014 explain *what* changed and *why*.
4. **Add tests** \u2014 cover new logic with unit or widget tests.
5. **Pass all checks** \u2014 `dart analyze` and all tests must pass.

## Package Boundaries

Respect the monorepo layering:

- **core** must not import `ui`, `network`, or the app package.
- **ui** may import `core` only.
- **network** may import `core` only.
- **l10n** is standalone \u2014 no internal dependencies.
- **${c.app}** may import all packages.

## Reporting Issues

Use GitHub Issues with a clear title and steps to reproduce. Include:

- Expected behavior
- Actual behavior
- Flutter/Dart version (`flutter doctor -v`)
- Relevant logs or screenshots
''';
