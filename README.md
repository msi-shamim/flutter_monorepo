# Flutter Monorepo

A Dart CLI tool that bootstraps a **production-ready Flutter monorepo** in one command — with your choice of state management, HTTP client, locales, and platforms.

## Features

- **Multi-framework support** — GetX, Riverpod, Bloc, or Cubit via `--state`
- **Multi-HTTP client** — Dio, http, or Chopper via `--http`
- **Dynamic localization** — 12 built-in languages with locale-aware date/number formatters and RTL support
- **Flexible platforms** — any combination of Android, iOS, Web, Linux, macOS, Windows
- **Full Material 3 design system** — light + dark themes with 30+ component themes, responsive utilities, centralized asset management
- **Sealed error handling** — `AppException` hierarchy + `Result<T>` (Success | Failure) throughout
- **Clean architecture** — 4 framework-agnostic shared packages (core, ui, network, l10n) + 1 app package
- **Auto version resolution** — fetches latest compatible dependency versions from pub.dev at generation time
- **Production linting** — `strict-casts`, `strict-raw-types`, `strict-inference` + 30 lint rules
- **Complete documentation** — `ARCHITECTURE.md` + `PACKAGE.md` for every generated package
- **Auto git init** — initializes repository with first commit (optional)

Before use, check the [CHANGELOG](CHANGELOG.md) to ensure you have the latest features.

## Installation

Install globally via Dart:

```bash
dart pub global activate flutter_monorepo
```

Make sure `~/.pub-cache/bin` is in your PATH (Dart will prompt you if not).

## Usage

You can use this tool from any terminal to scaffold a complete Flutter monorepo with a single command.

### Basic Usage

To generate a monorepo with default settings (GetX + Dio + EN/AR):

```bash
flutter_monorepo my_app
```

This creates a `my_app/` directory with a fully configured monorepo, resolves all dependencies, generates l10n files, runs `dart analyze`, and initializes git.

### Custom Usage

You can customize every aspect of the generated monorepo:

```bash
# Riverpod + Dio + 3 locales
flutter_monorepo my_app --state riverpod --locales en,es,fr

# Bloc + http package + web platform
flutter_monorepo my_app --state bloc --http http --platforms android,ios,web

# Cubit + Chopper + single locale + custom org + no git
flutter_monorepo my_app --state cubit --http chopper --locales en --org com.mycompany --no-git

# Full example with all options
flutter_monorepo my_app \
  --state riverpod \
  --http dio \
  --locales en,es,fr,de \
  --platforms android,ios,web \
  --org com.mycompany
```

### Doctor (Structure Check)

After generating a project and sharing it with your team, use `doctor` to verify the monorepo structure is intact:

```bash
cd my_app

# Check structure — reports missing dirs/files
flutter_monorepo doctor

# Auto-fix missing items
flutter_monorepo doctor --fix
```

The doctor auto-detects your project's state management, HTTP client, and locales from existing files — no flags needed. It checks all 80+ expected directories and files, then reports what's present (✓) and what's missing (✗).

### Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--state` | `-s` | `getx` | State management: `getx`, `riverpod`, `bloc`, `cubit` |
| `--http` | | `dio` | HTTP client: `dio`, `http`, `chopper` |
| `--locales` | `-l` | `en,ar` | Comma-separated locale codes |
| `--platforms` | `-p` | `android,ios` | Comma-separated platforms |
| `--org` | `-o` | `com.example` | Organization identifier for Android/iOS bundle |
| `--[no-]git` | | on | Initialize git repository with first commit |
| `--help` | `-h` | | Show help message |
| `--version` | | | Show version |

You can use `--no-git` to skip git initialization.

## State Management

Each framework generates a complete, working app layer with theme switching, locale switching, persistence, and routing:

| Framework | Dependencies | Routing | Persistence | Screen Pattern |
|-----------|-------------|---------|-------------|----------------|
| **GetX** | get, get_storage | GetX pages | GetStorage | `GetView` + `Obx` |
| **Riverpod** | flutter_riverpod, go_router, shared_preferences | GoRouter | SharedPreferences | `ConsumerWidget` + `ref.watch` |
| **Bloc** | flutter_bloc, hydrated_bloc, go_router | GoRouter | HydratedBloc | `BlocBuilder` |
| **Cubit** | flutter_bloc, hydrated_bloc, go_router | GoRouter | HydratedCubit | `BlocBuilder` |

## HTTP Client

All three HTTP clients generate the same `ApiClient` API surface — every method returns `Result<T>` for type-safe error handling:

| Client | Package | Interceptor Pattern | Error Mapping |
|--------|---------|-------------------|---------------|
| **Dio** | `dio` | `Interceptor` class | `DioException` -> `AppException` |
| **http** | `http` | `BaseClient` wrapper | `ClientException` / `SocketException` -> `AppException` |
| **Chopper** | `chopper` | `Interceptor` interface (chain) | `Exception` -> `AppException` |

## Localization

12 languages have built-in translations: **en, ar, es, fr, de, pt, zh, ja, ko, hi, tr, ru**

Unknown locale codes generate English placeholder values with `// TODO: translate` markers.

```bash
flutter_monorepo my_app --locales en,es,fr,de,ja
```

Each generated project includes:
- ARB files per locale with `flutter gen-l10n` integration
- Locale-aware `AppDateFormatter` (short, medium, long, time)
- Locale-aware `AppNumberFormatter` (decimal, currency, compact, percent)
- `DirectionalityBuilder` widget for RTL support

## Auto Version Resolution

When the tool runs, it queries **pub.dev** to fetch the latest compatible version of every dependency. It stays within the same major version as our tested templates to ensure API compatibility, and falls back to hardcoded versions if you're offline.

```
→ Fetching latest package versions from pub.dev...
```

Example: `dio ^5.8.0+1` (fallback) resolves to `^5.9.2` (latest patch in major 5).

## Generated Structure

```
my_app/
├── my_app_app/                  # Main Flutter app
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   ├── app/
│   │   │   ├── controllers/     # GetX: theme + locale controllers
│   │   │   ├── providers/       # Riverpod: theme + locale providers
│   │   │   ├── blocs/           # Bloc/Cubit: theme + locale blocs
│   │   │   ├── routes/          # Route constants
│   │   │   └── router/          # GoRouter config (Riverpod/Bloc/Cubit)
│   │   └── screens/
│   │       └── home/            # Demo home screen
│   ├── android/
│   └── ios/
├── packages/
│   ├── core/                    # Business logic (framework-free)
│   │   └── lib/
│   │       ├── exceptions/      # Sealed AppException hierarchy
│   │       ├── models/          # BaseModel with equality
│   │       ├── repositories/    # Abstract repository contracts
│   │       ├── usecases/        # UseCase<T,P> base classes
│   │       ├── utils/           # Result<T> = Success | Failure
│   │       └── extensions/      # String, DateTime, List extensions
│   ├── ui/                      # Design system
│   │   ├── assets/              # Icons, fonts, images
│   │   └── lib/
│   │       ├── theme/           # Material 3 light + dark (30+ components)
│   │       ├── responsive/      # Breakpoints, ResponsiveBuilder
│   │       ├── assets/          # Type-safe asset constants
│   │       └── widgets/         # Reusable stateless widgets
│   ├── network/                 # HTTP layer (Dio/http/Chopper)
│   │   └── lib/
│   │       ├── client/          # ApiClient returning Result<T>
│   │       └── interceptors/    # Auth + logging interceptors
│   └── l10n/                    # Localization
│       └── lib/
│           ├── l10n/arb/        # ARB files per locale
│           ├── formatters/      # Date + number formatters
│           └── widgets/         # RTL DirectionalityBuilder
├── pubspec.yaml                 # Workspace root
├── analysis_options.yaml        # Strict production linting
└── ARCHITECTURE.md              # Full architecture documentation
```

## Programmatic Usage

You can also use this package programmatically in your Dart code:

```dart
import 'package:flutter_monorepo/flutter_monorepo.dart';

void main() async {
  final config = ProjectConfig(
    name: 'my_app',
    org: 'com.example',
    stateManagement: StateManagement.riverpod,
    httpClient: HttpClient.dio,
    locales: ['en', 'es', 'fr'],
    platforms: ['android', 'ios', 'web'],
    gitInit: true,
  );

  print(config.app);           // my_app_app
  print(config.pascal);        // MyApp
  print(config.primaryLocale); // en
  print(config.usesGoRouter);  // true

  // Generate the full monorepo
  final generator = Generator(config: config, rootPath: '/path/to/output');
  await generator.run();
}
```

## Example

Check the `example` folder for a complete example of how to use this package programmatically and a full reference of all CLI options.

To run the example:

```bash
dart run example/main.dart
```

## Requirements

- **Flutter SDK** (stable channel)
- **Dart SDK** ^3.10.4
- Internet connection (for auto version resolution — falls back to bundled versions if offline)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support the Project

If you find this package helpful, consider supporting it by Liking it on pub.dev

## Connect with Me

Feel free to reach out for questions, suggestions, or just to say hi!

- LinkedIn: [LinkedIn Profile](https://www.linkedin.com/in/msishamim)
- GitHub: [GitHub Profile](https://github.com/msi-shamim)

## Hire Me or Contact My Organization

For freelance work or larger projects:

- Upwork Individual Profile: [Individual Profile](https://upwork.com/freelancers/msifullstack)
- Upwork Agency: [Agency Profile](https://www.upwork.com/agencies/incrementsinc/)

For large scale developments or to discuss potential collaborations, please reach out via email at: im.msishamim@gmail.com

## My Organization

### Increments Inc.

Our software automates restaurants, optimizes energy, revolutionizes finance, improves healthcare, innovates education, streamlines garments, and drives paperless solutions.
Increments Inc. is Bangladesh's #1 mobile app development agency.

[Visit Increments Inc.](https://incrementsinc.com)

---

Thank you for checking out Flutter Monorepo! I hope it saves you hours of setup time. Happy Coding!
