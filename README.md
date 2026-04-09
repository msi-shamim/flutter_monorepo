# flutter_monorepo

A CLI tool that bootstraps a **production-ready Flutter GetX monorepo** in one command.

## What you get

| Layer | Included |
|-------|----------|
| **Core** | Sealed exception hierarchy, `Result<T>`, `BaseModel`, `UseCase<T,P>`, repository contracts, string/date/list extensions |
| **UI** | Full Material 3 theme (30+ component themes, light + dark), responsive utilities, centralized asset management |
| **Network** | Dio `ApiClient` with `Result<T>` returns, auth + logging interceptors, automatic error mapping |
| **L10n** | EN/AR localization, locale-aware date/number formatters, RTL `DirectionalityBuilder` |
| **App** | GetX controllers/bindings/routing, GetStorage persistence (theme + locale), route middleware |
| **Linting** | `strict-casts`, `strict-raw-types`, `strict-inference` + 30 production rules |
| **Docs** | `ARCHITECTURE.md` + `PACKAGE.md` for every package |

## Install

```bash
dart pub global activate flutter_monorepo
```

## Usage

```bash
flutter_monorepo my_app
flutter_monorepo my_app --org com.mycompany
```

This creates:

```
my_app/
├── my_app_app/                  # Main Flutter app (GetX)
├── packages/
│   ├── core/                    # Business logic (framework-free)
│   ├── ui/                      # Themes, responsive, assets
│   ├── network/                 # Dio HTTP client
│   └── l10n/                    # EN/AR localization
├── pubspec.yaml                 # Workspace root
├── analysis_options.yaml        # Strict linting
└── ARCHITECTURE.md              # Full documentation
```

## Run your new app

```bash
cd my_app/my_app_app
flutter run
```

## Architecture highlights

- **GetX confined to app** — all shared packages are framework-agnostic
- **Dependency inversion** — controllers depend on abstract interfaces from `core`, bindings inject implementations from `network`
- **Sealed error handling** — `DioException` → `AppException` → `Result<T>` → pattern match in controllers
- **Responsive design** — `Breakpoints`, `ResponsiveHelper` (BuildContext extension), `ResponsiveBuilder`
- **Theme persistence** — GetStorage saves theme mode + locale across restarts
- **Type-safe assets** — `AppIcons.home`, `AppImages.logo`, `AppFonts.primary` (no raw path strings)

## Options

```
Usage: flutter_monorepo <project_name> [options]

Options:
  -o, --org     Organization identifier (default: com.example)
  -h, --help    Show usage information
      --version Show version
```

## Requirements

- Flutter SDK (stable channel)
- Dart SDK ^3.10.4

## License

MIT
