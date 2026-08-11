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
