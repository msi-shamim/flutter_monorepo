# flutter_monorepo

A CLI tool that bootstraps a **production-ready Flutter monorepo** in one command — with your choice of state management, locales, and platforms.

## What you get

| Layer | Included |
|-------|----------|
| **Core** | Sealed exception hierarchy, `Result<T>`, `BaseModel`, `UseCase<T,P>`, repository contracts, string/date/list extensions |
| **UI** | Full Material 3 theme (30+ component themes, light + dark), responsive utilities, centralized asset management |
| **Network** | HTTP client of your choice (Dio/http/Chopper), `ApiClient` with `Result<T>` returns, auth + logging interceptors |
| **L10n** | Dynamic locale support (12 languages built-in), date/number formatters, RTL helper |
| **App** | State management of your choice, persistent theme + locale, route middleware, home screen demo |
| **Linting** | `strict-casts`, `strict-raw-types`, `strict-inference` + 30 production rules |
| **Docs** | `ARCHITECTURE.md` + `PACKAGE.md` for every package |

## Install

```bash
dart pub global activate flutter_monorepo
```

## Usage

```bash
flutter_monorepo my_app
flutter_monorepo my_app --state riverpod --locales en,es,fr
flutter_monorepo my_app --state bloc --platforms android,ios,web
flutter_monorepo my_app --state cubit --http http --no-git
```

## Options

```
Usage: flutter_monorepo <project_name> [options]

Options:
  -s, --state       State management: getx, riverpod, bloc, cubit (default: getx)
  -l, --locales     Comma-separated locale codes (default: en,ar)
  -p, --platforms   Comma-separated platforms (default: android,ios)
      --http        HTTP client: dio, http, chopper (default: dio)
  -o, --org         Organization identifier (default: com.example)
      --[no-]git    Initialize git with first commit (default: on)
  -h, --help        Show usage information
      --version     Show version
```

## State Management

| Option | Dependencies | Routing | Persistence |
|--------|-------------|---------|-------------|
| `--state getx` | get, get_storage | GetX pages | GetStorage |
| `--state riverpod` | flutter_riverpod, go_router, shared_preferences | GoRouter | SharedPreferences |
| `--state bloc` | flutter_bloc, hydrated_bloc, go_router | GoRouter | HydratedBloc |
| `--state cubit` | flutter_bloc, hydrated_bloc, go_router | GoRouter | HydratedCubit |

## HTTP Client

| Option | Package | Interceptor Pattern |
|--------|---------|-------------------|
| `--http dio` | `dio` | Dio `Interceptor` class |
| `--http http` | `http` | `BaseClient` wrapper pattern |
| `--http chopper` | `chopper` | Chopper `Interceptor` interface |

> Versions are auto-resolved from pub.dev at generation time — you always get the latest compatible release.

## Auto Version Resolution

When you run the tool, it queries **pub.dev** to fetch the latest compatible version of every dependency before generating files. It stays within the same major version as our tested templates to ensure API compatibility, and falls back to hardcoded versions if you're offline.

```
→ Fetching latest package versions from pub.dev...
```

Example: `dio ^5.8.0+1` (fallback) resolves to `^5.9.2` (latest in major 5).

## Locales

12 languages with built-in translations: **en, ar, es, fr, de, pt, zh, ja, ko, hi, tr, ru**

Unknown locales get English values with TODO markers.

```bash
flutter_monorepo my_app --locales en,es,fr,de
```

## Generated Structure

```
my_app/
├── my_app_app/                  # Main Flutter app
├── packages/
│   ├── core/                    # Business logic (framework-free)
│   ├── ui/                      # Themes, responsive, assets
│   ├── network/                 # HTTP client (Dio/http/Chopper)
│   └── l10n/                    # Localization
├── pubspec.yaml                 # Workspace root
├── analysis_options.yaml        # Strict linting
└── ARCHITECTURE.md              # Documentation
```

## Requirements

- Flutter SDK (stable channel)
- Dart SDK ^3.10.4

## License

MIT
