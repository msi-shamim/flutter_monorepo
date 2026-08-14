## 1.7.0

The last two roadmap options ship, so every flag VISION has ever described now
exists.

### Added

- **`--auth none|custom|firebase|supabase`** — an `AuthRepository` contract in
  `packages/core`, one implementation in the app, a login screen, and
  `AUTH.md` covering the per-provider setup. Screens and guards depend on the
  contract, never on a provider SDK.

  `custom` is complete apart from two marked network calls: token persistence
  through the project's `KeyValueStore`, restore on launch and sign-in
  broadcasting all work as written. `firebase` and `supabase` generate against
  placeholder credentials so the project builds and boots before the provider
  is configured.

  The route guard is generated but deliberately left disabled — enabling it
  before the sign-in path is finished would lock you out of your own app.
  `AUTH.md` says how to turn it on.

  **Firebase needs `flutterfire configure` before an Android build.** That is
  a property of Firebase, not of this tool, and `AUTH.md` states it plainly.
  An Android build of the Firebase variant has not been verified here.

- **`--template blank|ecommerce|social|dashboard`** — adds a model to core and
  two wired screens with routes registered. The screens are plain widgets
  taking their data as parameters, so they work with any state management, and
  the sample data is a clearly marked constant rather than a fake repository.

### Fixed

- The generated `analysis_options.yaml` listed `avoid_returning_null_for_future`,
  **removed in Dart 3.3.0**. Every generated project warned on it for anyone on
  a current SDK, and it would have failed the generated CI's `--fatal-infos`
  step. Found when this machine's SDK moved to Dart 3.13.

## 1.6.0

### Added

- **`--flavor`** — generates `dev`, `staging` and `prod` environments, each
  with its own entrypoint, application id and display name, so all three
  install side by side on one device. Per-environment values live in a single
  enum, and the entrypoint records which environment is running.

  `lib/main.dart` keeps the app and gains a `bootstrap` the per-flavor
  entrypoints call. Without the flag the entrypoint is exactly the plain
  `main()` it has always been — a project that does not use flavors carries no
  trace of them.

  **Android is fully wired and verified**: product flavors on an `env`
  dimension, `applicationIdSuffix` for dev and staging, and a per-flavor
  `app_name` resource that the manifest label points at. Confirmed by building
  a flavored APK.

  **iOS ships an xcconfig per flavor but needs manual finishing.** Xcode
  schemes cannot be created from files on disk, so `FLAVORS.md` records the
  steps. Those files were produced on a machine that cannot build for iOS, so
  unlike the Android side they are a starting point rather than a verified
  configuration.

  Patching the Gradle file that `flutter create` produced is version
  sensitive, so a missing anchor is reported as a generation failure rather
  than skipped silently.

### Fixed

- VISION grouped options under "Planned — not implemented" headings that
  contained options which had since shipped, and its opening note listed
  `--ci` and `--flavor` as unimplemented. Sections are now grouped by what is
  actually implemented, leaving only `--auth` and `--template` as planned.

## 1.5.0

Four new options, and the first release in which a generated app is verified
to actually run rather than merely to compile.

### Added

- **`--storage get_storage|shared_prefs|hive`** — persistence now goes through
  a `KeyValueStore` interface in `packages/core`, with one implementation in
  the app. Nothing in the theme or locale state names a storage package, so
  changing backend is an edit to a single file. Bloc and Cubit hydrate through
  an adapter onto the same backend instead of running `HydratedStorage`
  alongside it. Omitting the flag keeps each framework's original backend.
  `hive` resolves `hive_ce`: `hive` itself declares `sdk <3.0.0` and has not
  been published since 2022, so it cannot resolve on Dart 3.
- **`--ci none|github|gitlab`** — CI was previously available only as part of
  `--github`, and GitLab was not supported at all. The GitLab pipeline mirrors
  the Actions workflow step for step. `--github` still implies GitHub Actions,
  so existing invocations are unchanged; an explicit `--ci` wins.
- **`--test unit|full`** — `full` adds an `integration_test` suite that drives
  the real app entrypoint, plus shared fixtures for core tests. It is
  deliberately not added to the generated CI, which has no device to run it
  on.
- **`--platforms all`** — shorthand for every supported platform. Documented
  previously but rejected by the parser.
- **A boot test in every generated project.** The app starter test now pumps
  the real app, so it exercises what matters: the app builds, resolves its
  theme and locale state, routes to the initial screen and renders a frame.

### Fixed

- **Widget tests could not pump the generated app.** Theme and locale state
  read persistent storage as they build, and storage plugins are not
  registered under `flutter test`, so the first widget test anyone wrote
  failed on the platform instance before rendering — with pre-created test
  directories inviting them to try. Each project now generates
  `test/flutter_test_config.dart`, which Flutter runs automatically and which
  installs an in-memory substitute for the chosen backend.
- **Four defects in the generated AI agent skills**, each of which sent the
  developer to a command or path that could not work: `dart run
  flutter_monorepo doctor` in a project that does not depend on the CLI,
  `dart test` against the two Flutter-dependent packages, a `--fix`
  description left stale by the 1.4.0 doctor changes, and
  `packages/core/states/` missing its `lib/` segment.

### Changed

- **32 component themes**, up from 24 — adds listTile, expansionTile,
  popupMenu, slider, segmentedButton, searchBar, datePicker and timePicker to
  both light and dark, using the existing shape and colour tokens.
- Riverpod restores theme and locale synchronously during construction rather
  than through an async load after the first frame.
- The marker file records the CI provider, test scope and storage backend.
  Projects generated before 1.5.0 fall back to `none`, `unit` and their
  framework default.

### Internal

- An integration test generates a real monorepo per state management choice
  and drives it through generate, analyze, format, its tests including the
  boot test, and `doctor`. Confirmed to fail when the 1.3.0 `intl` regression
  is reintroduced.
- The repository has CI of its own for the first time, and is `dart format`
  clean.
- The unit suite now fails if generated guidance names a package path without
  its `lib/` segment, runs `dart test` against a Flutter package, or invokes
  the CLI as a project dependency.

## 1.4.0

Generated projects did not build. Version resolution emitted constraints the
Flutter SDK forbids, and the generator reported success regardless — so the
default `flutter_monorepo my_app` produced a monorepo that could not resolve
dependencies, printed "created successfully" and exited 0. This release fixes
that and 32 further defects found in a full audit of the tool.

### Fixed — generation

- **Dependency resolution failed in every generated project.** `intl` resolved
  to a version `flutter_localizations` forbids, so `dart pub get` failed and
  `dart analyze` reported 500+ errors. SDK-pinned packages are no longer
  resolved live.
- **`--state riverpod` failed version solving.** `flutter_riverpod` resolved
  above the SDK floor the generated pubspecs declare. Candidate versions are
  now filtered by their declared SDK constraint, and that floor lives in one
  constant instead of eight copies.
- **The generator claimed success no matter what failed.** `pub get`,
  `gen-l10n`, `analyze` and all three git calls had their results ignored.
  Failures are now reported and the CLI exits non-zero.
- **GetX generated uncompilable code for 8 locales.** Two locale identifier
  maps had drifted, so `--locales it,en` declared one constant and referenced
  another. There is now a single map.
- **Locales with a region subtag produced invalid Dart.** `--locales en-US`
  emitted an unparseable identifier, a wrong `Locale()` form and an ARB name
  `gen-l10n` rejects. Codes are validated and normalised, region variants emit
  `Locale('pt', 'BR')`, and the base-language fallback ARB is generated.
- **Pre-release and `0.x` versions were resolved incorrectly.** Pre-releases
  could outrank the newest stable, and `^0.20.2` accepted any `0.x` including
  breaking bumps.
- **`--http http` could not build for web** — it imported `dart:io`.
- Restored the `cupertino_icons` dependency, removing the web build font
  warning.

### Fixed — doctor

- **`doctor --fix` wrote zero-byte placeholders** for anything it had no
  template for, including every `pubspec.yaml` and barrel file. Because the
  check is an existence check, the next run then certified the broken project
  as intact. Unrestorable files are now reported and left absent.
- **`doctor --fix` silently relicensed projects.** The license is not
  recoverable from a generated tree, so an MIT project's LICENSE was rewritten
  as "PROPRIETARY AND CONFIDENTIAL" and reported as restored.
- **`doctor` treated any directory with a `pubspec.yaml` as a monorepo**, so
  `--fix` scaffolded 59 files into unrelated packages.
- **A missing app pubspec flipped framework detection to GetX**, so `--fix`
  wrote GetX scaffolding into Riverpod projects.
- **Deleting one locale's ARB, or all of `.github/`, was invisible** — those
  checklists were derived from the artifacts being checked.
- **`doctor --fix` exited 1 even after repairing everything.**
- Nine generated paths were never checked, including the gen-l10n output
  directory and the `.gitkeep` sentinels.
- A project name containing `_workspace` broke detection outright.

### Added

- **`.flutter_monorepo.yaml`** — generated projects now record the choices they
  were created with, so `doctor` and `workflow` read the configuration instead
  of guessing it. Projects generated before 1.4.0 fall back to inference.
- **`ARCHITECTURE.md`** — documented since 1.1 but never actually written. It
  adapts to the project's packages, routing, state management and locales.
- **Starter tests** for every package, exercising generated code. The CI
  workflow's test steps previously ran against empty directories and failed.
- **`AppRoutes.login`** — the GetX auth guard redirected to the route it
  guards, which would loop. All four frameworks now reference one constant.
- `workflow --help`, and an error for unknown workflow arguments, which
  previously printed the overview and exited 0.

### Changed

- **`packages/core` no longer depends on Flutter.** It is documented as a pure
  Dart package and now is one, which is also what makes
  `dart test packages/core/test` work.
- **Generated code is formatted** as part of generation, so the CI workflow's
  `dart format --set-exit-if-changed` step passes.
- **`go_router` 14 → 17 and `hydrated_bloc` 10 → 11.** Because resolution pins
  to the fallback's major, a stale fallback was a permanent floor.
- **`pubspec.lock` is committed**, not ignored — this is an application
  workspace.
- Unrecognised locales print a note and mark their ARB with
  `@@x-untranslated`, instead of silently shipping English.
- CI runs `flutter test` against the Flutter-dependent packages, not
  `dart test`.
- Better CLI errors for a missing project name, extra arguments, and an
  unknown `doctor` flag, which previously crashed with a stack trace.
- Corrected docs claims that did not match the output: component theme count,
  lint rule count, lint baseline, and the unimplemented flags in VISION.md.

## 1.3.0

- **README.md, LICENSE, CONTRIBUTING.md** — auto-generated for every new monorepo with project-specific content
- **`--license` option** — choose from 11 GitHub-supported license types (proprietary, mit, apache-2.0, bsd-2-clause, bsd-3-clause, gpl-2.0, gpl-3.0, lgpl-2.1, mpl-2.0, unlicense, isc); defaults to `proprietary`
- **`--github` flag** — opt-in generation of GitHub community files: issue templates (bug report, feature request), PR template, CI workflow, code of conduct, and funding placeholder
- **Doctor** checks for README.md, LICENSE, and CONTRIBUTING.md; conditionally checks `.github/` files when present, with full-content restoration via `--fix`

## 1.2.0

- **Framework-aware workflows** — `workflow` command auto-detects your state management (GetX/Riverpod/Bloc/Cubit) and shows framework-specific instructions for screen design and business logic wiring
- **AI Agent Skills** — generates `.claude/skills/` with 4 Claude Code skills (component-design, screen-design, business-logic, monorepo-doctor) that auto-adapt to your chosen state management framework
- **`.claude/settings.json`** — pre-approves common tools (Read, Glob, Grep, dart analyze, dart test, flutter test) for seamless AI-assisted development
- **Smart doctor fix** — `doctor --fix` restores missing skill files and settings.json with **full content**, not empty placeholders
- Doctor now checks `.claude/skills/` directories and files (4 additional checks)
- Extracted `detectProjectConfig()` as a shared utility (used by both doctor and workflow)

## 1.1.0

- **`doctor`**: Structure integrity checker — auto-detects config, reports 89 dirs/files, `--fix` to restore
- **`workflow`**: Built-in development guides (A: component, B: screen, C: business logic) with test steps and checklists
- **`--http`**: Choose HTTP client — Dio, http, or Chopper
- **Test-during-development**: Every workflow includes a test step; 6 test directories pre-created in generated projects
- **Companion states**: `packages/core/lib/states/` directory for reusable component state logic
- Auto version resolution from pub.dev — always gets latest compatible versions at generation time
- Comprehensive README with all features, tables, and examples

## 1.0.0

- **`--state`**: Choose state management — GetX, Riverpod, Bloc, or Cubit
- **`--locales`**: Dynamic locale support with 12 built-in languages (en, ar, es, fr, de, pt, zh, ja, ko, hi, tr, ru)
- **`--platforms`**: Target any Flutter platform (android, ios, web, linux, macos, windows)
- **`--git`**: Auto git init with first commit (on by default)
- Strategy pattern architecture for clean framework-specific templates
- GoRouter for Riverpod/Bloc/Cubit, GetX router for GetX
- SharedPreferences for Riverpod, HydratedBloc for Bloc/Cubit, GetStorage for GetX

## 0.1.0

- Initial release
- GetX-only monorepo scaffolding with 4 shared packages (core, ui, network, l10n)
- Material 3 theme system (light + dark, all component themes)
- Responsive design utilities (Breakpoints, ResponsiveHelper, ResponsiveBuilder)
- Centralized asset management with type-safe constants
- Dio HTTP client with sealed Result<T> error handling
- EN/AR localization with date/number formatters and RTL helpers
- GetStorage persistence for theme and locale
- Route middleware/guards pattern
- Strict production linting
- Complete documentation
