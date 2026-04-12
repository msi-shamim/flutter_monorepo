# Flutter Monorepo

A Dart CLI tool that bootstraps a **production-ready Flutter monorepo** in one command — with your choice of state management, HTTP client, locales, and platforms.

[![pub version](https://img.shields.io/pub/v/flutter_monorepo)](https://pub.dev/packages/flutter_monorepo)
[![pub points](https://img.shields.io/pub/points/flutter_monorepo)](https://pub.dev/packages/flutter_monorepo/score)
[![license](https://img.shields.io/github/license/msi-shamim/flutter_monorepo)](LICENSE)
[![Dart](https://img.shields.io/badge/Dart-%5E3.10.4-blue?logo=dart&logoColor=white)](https://dart.dev)
[![GitHub issues](https://img.shields.io/github/issues/msi-shamim/flutter_monorepo)](https://github.com/msi-shamim/flutter_monorepo/issues)
[![GitHub stars](https://img.shields.io/github/stars/msi-shamim/flutter_monorepo?style=social)](https://github.com/msi-shamim/flutter_monorepo)

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
- **Project metadata** — auto-generated `README.md`, `LICENSE`, and `CONTRIBUTING.md` with 11 license types via `--license` (default: proprietary)
- **GitHub community setup** — opt-in `--github` flag generates issue templates, PR template, CI workflow, code of conduct, and funding placeholder
- **Monorepo doctor** — `doctor` command to verify structure integrity, report missing items, and auto-fix with `--fix`
- **Development workflows** — `workflow` command with step-by-step guides for building components, screens, and business logic
- **Test-during-development** — every workflow includes a test step; test directories are pre-created so tests are written alongside code, not bolted on later
- **AI Agent Skills** — generates `.claude/skills/` with 4 ready-to-use skills for Claude Code (component design, screen design, business logic, monorepo doctor) that auto-adapt to your chosen state management framework

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

# MIT license
flutter_monorepo my_app --license mit

# Full GitHub setup (MIT license + community files)
flutter_monorepo my_app --license mit --github

# Full example with all options
flutter_monorepo my_app \
  --state riverpod \
  --http dio \
  --license mit \
  --locales en,es,fr,de \
  --platforms android,ios,web \
  --org com.mycompany \
  --github
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

The doctor auto-detects your project's state management, HTTP client, and locales from existing files — no flags needed. It checks all 95+ expected directories and files, then reports what's present (✓) and what's missing (✗).

### Development Workflows

Get step-by-step development guides right in your terminal. When run from inside a generated project, workflows auto-detect your state management framework and show tailored instructions:

```bash
cd my_app                        # run from inside your project for tailored output

flutter_monorepo workflow        # overview + quick reference
flutter_monorepo workflow a      # Component Design Flow (widget + companion state)
flutter_monorepo workflow b      # Screen Design Flow (adapts to GetX/Riverpod/Bloc/Cubit)
flutter_monorepo workflow c      # Business Logic Flow (core + network + framework wiring)
```

Each workflow includes a **test step** — tests are written during development, not after. The generated project comes with pre-created test directories:

```
packages/core/test/{states, rules, models}/   # companion state + business logic tests
packages/ui/test/widgets/                      # widget render tests
packages/network/test/                         # API client tests
<app>/test/screens/                            # controller tests
```

### Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--state` | `-s` | `getx` | State management: `getx`, `riverpod`, `bloc`, `cubit` |
| `--http` | | `dio` | HTTP client: `dio`, `http`, `chopper` |
| `--license` | | `proprietary` | License type: `proprietary`, `mit`, `apache-2.0`, `bsd-2-clause`, `bsd-3-clause`, `gpl-2.0`, `gpl-3.0`, `lgpl-2.1`, `mpl-2.0`, `unlicense`, `isc` |
| `--locales` | `-l` | `en,ar` | Comma-separated locale codes |
| `--platforms` | `-p` | `android,ios` | Comma-separated platforms |
| `--org` | `-o` | `com.example` | Organization identifier for Android/iOS bundle |
| `--[no-]git` | | on | Initialize git repository with first commit |
| `--[no-]github` | | off | Generate GitHub community files (issue/PR templates, CI, code of conduct) |
| `--help` | `-h` | | Show help message |
| `--version` | | | Show version |

You can use `--no-git` to skip git initialization, or `--github` to include GitHub community files.

| Command | Description |
|---------|-------------|
| `doctor` | Check structure integrity of current monorepo |
| `doctor --fix` | Auto-restore missing items (skill files restored with full content) |
| `workflow` | Show development workflow overview + quick reference |
| `workflow a` | Component Design Flow (widget + companion state) |
| `workflow b` | Screen Design Flow (adapts to GetX/Riverpod/Bloc/Cubit) |
| `workflow c` | Business Logic Flow (adapts wiring step per framework) |

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
├── .claude/                     # AI agent skills
│   ├── settings.json            # Pre-approved tools
│   └── skills/
│       ├── component-design/    # Workflow A skill
│       ├── screen-design/       # Workflow B skill (adapts per framework)
│       ├── business-logic/      # Workflow C skill
│       └── monorepo-doctor/     # Structure check skill
├── pubspec.yaml                 # Workspace root
├── analysis_options.yaml        # Strict production linting
├── ARCHITECTURE.md              # Full architecture documentation
├── README.md                    # Project overview + getting started
├── LICENSE                      # License file (configurable via --license)
├── CONTRIBUTING.md              # Contribution guidelines
└── .github/                     # (opt-in via --github)
    ├── ISSUE_TEMPLATE/          # Bug report + feature request templates
    ├── pull_request_template.md # PR checklist
    └── workflows/ci.yml        # GitHub Actions CI pipeline
```

## AI Agent Skills

Every generated project includes `.claude/skills/` — pre-configured skills for [Claude Code](https://claude.ai/code) that teach the AI agent your project's architecture and workflows:

| Skill | Trigger phrases | What it does |
|-------|----------------|-------------|
| `component-design` | "Build a component", "Convert this Figma" | Workflow A — widget + companion state + tests |
| `screen-design` | "Build this screen", "Create a page" | Workflow B — controller + sections + tests |
| `business-logic` | "Implement this rule", "Add business logic" | Workflow C — core rules + network repo + wiring + tests |
| `monorepo-doctor` | "Check structure", "What's missing" | Run doctor to verify integrity |

The `screen-design` skill automatically adapts to your chosen state management (GetX controllers, Riverpod providers, Bloc events, or Cubit methods).

Skills are auto-discovered by Claude Code — no setup needed. Just open the project and start building.

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
