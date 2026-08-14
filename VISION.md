# flutter_monorepo — Product Vision

> What takes a senior dev 1 full day (or 3-4 hours with AI) now takes 30 seconds.

```bash
flutter_monorepo my_app \
  --state riverpod \
  --locales en,es,fr \
  --http dio \
  --platforms android,ios,web \
  --ci github \
  --flavor \
  --auth supabase
```

> **Note:** every option above ships today. Sections below are grouped by what
> is implemented; anything under "Planned" is rejected by the current CLI.

No other pub.dev package does this comprehensively.

---

## Shipped — Core Options

### `--state` — State Management Choice
```bash
flutter_monorepo my_app --state getx        # default
flutter_monorepo my_app --state riverpod
flutter_monorepo my_app --state bloc
flutter_monorepo my_app --state cubit
```
GetX-only limits audience. GetX + Riverpod + Bloc covers 90%+ of Flutter devs.

### `--locales` — Custom Language Support
```bash
flutter_monorepo my_app --locales en,ar      # default
flutter_monorepo my_app --locales en,es,fr,de
flutter_monorepo my_app --locales en          # English only
```
EN/AR is niche. EN/ES or EN/FR covers far more projects globally.

### `--platforms` — Target Platforms
```bash
flutter_monorepo my_app --platforms android,ios    # default
flutter_monorepo my_app --platforms android,ios,web
flutter_monorepo my_app --platforms all
```
Web and desktop are growing fast in 2026.

### `--git` — Auto Git Init
```bash
flutter_monorepo my_app --git         # git init + initial commit (default: on)
flutter_monorepo my_app --no-git
```

---

### `--http` — HTTP Client Choice
```bash
flutter_monorepo my_app --http dio          # default
flutter_monorepo my_app --http http
flutter_monorepo my_app --http chopper
```

### `--storage` — Local Persistence Choice
```bash
flutter_monorepo my_app --storage get_storage
flutter_monorepo my_app --storage shared_prefs
flutter_monorepo my_app --storage hive          # hive_ce
```
Persistence goes through a `KeyValueStore` interface in `packages/core`, so
the backend is a wiring change in one file. Omitting the flag keeps each
framework's original backend.

### `--ci` — CI/CD Templates
```bash
flutter_monorepo my_app --ci github       # GitHub Actions
flutter_monorepo my_app --ci gitlab
flutter_monorepo my_app --ci none         # default
```
Generates a pipeline that analyzes, checks formatting and runs every
package's tests. `--github` implies `--ci github`.

### `--flavor` — Build Flavors (dev/staging/prod)
```bash
flutter_monorepo my_app --flavor
```
Generates a per-environment config, an entrypoint per flavor, Android product
flavors, and iOS xcconfigs. Android is fully wired and verified by building a
flavored APK; iOS needs the Xcode scheme steps recorded in FLAVORS.md.

---

### `--auth` — Auth Scaffolding
```bash
flutter_monorepo my_app --auth firebase
flutter_monorepo my_app --auth supabase
flutter_monorepo my_app --auth custom       # token against your own API
flutter_monorepo my_app --auth none         # default
```
An `AuthRepository` contract in core, one implementation in the app, a login
screen, and `AUTH.md` covering the per-provider setup. The route guard is
generated but left disabled until the sign-in path is finished.

### `--template` — Project Templates
```bash
flutter_monorepo my_app --template blank          # default
flutter_monorepo my_app --template ecommerce
flutter_monorepo my_app --template social
flutter_monorepo my_app --template dashboard
```
Adds a model in core and two wired screens with routes registered. The screens
are plain widgets taking their data as parameters, so they work with any state
management and the sample data is trivial to replace.

### `--test` — Testing Setup
```bash
flutter_monorepo my_app --test unit        # unit + widget tests (default)
flutter_monorepo my_app --test full        # adds integration_test + fixtures
```
Every project gets starter unit and widget tests. `full` additionally
generates an `integration_test` suite that drives the real app on a device,
and shared fixtures for core tests.

---

---

## Planned

Nothing outstanding — every option in this document ships today.



## Release Roadmap

| Version | Features | Impact |
|---------|----------|--------|
| **v1.0** | `--state` (getx/riverpod/bloc/cubit), `--locales`, `--platforms`, `--git` | 5x audience |
| **v1.1** | `--http` (dio/http/chopper), `doctor`, `workflow` | Production-ready |
| **v1.2** | AI Agent Skills (`.claude/skills/`), smart `doctor --fix` | AI-assisted development |
| **v1.3** | `--license` (11 types), `--github` (community files), README/LICENSE/CONTRIBUTING | Top-tier GitHub repo |
| **v1.4** | Audit fixes: working dependency resolution, honest exit codes, project marker file, `ARCHITECTURE.md`, starter tests, green CI | Generated projects actually build |
| **v1.5** | `--storage`, `--ci`, `--test`, `--platforms all`, 32 component themes, boot tests | Generated apps verified to run |
| **v1.6** | `--flavor` (dev/staging/prod) | Multiple environments side by side |

---

## Current State (v1.6.0)

Shipped with:
- Multi-framework support: GetX, Riverpod, Bloc, Cubit (`--state`)
- Multi-HTTP client: Dio, http, Chopper (`--http`)
- Dynamic locale support: 12 built-in languages (`--locales`)
- Platform flexibility: any Flutter platform combination (`--platforms`)
- Auto git init with first commit (`--git`)
- 11 license types with `--license` (default: proprietary)
- GitHub community files with `--github` (issue/PR templates, CI workflow, code of conduct)
- Auto-generated README.md, LICENSE, and CONTRIBUTING.md
- 4 shared packages (core, ui, network, l10n) — all framework-agnostic
- Full Material 3 theme (light + dark, 32 component themes)
- Pluggable persistence via `KeyValueStore` in core (`--storage`)
- CI pipelines for GitHub Actions or GitLab (`--ci`)
- Optional integration_test suite and shared fixtures (`--test full`)
- Build flavors for dev/staging/prod (`--flavor`)
- Auth scaffolding behind an `AuthRepository` contract (`--auth`)
- Starter screen sets for ecommerce, social and dashboard (`--template`)
- Responsive design utilities
- Centralized asset management
- Sealed exception hierarchy + Result<T>
- Persistent theme + locale (GetStorage / SharedPreferences / HydratedBloc)
- Auto version resolution from pub.dev (newest stable release in the same
  caret-compatible series, filtered to what the declared SDK floor allows)
- Route guard pattern (GetX middleware; GoRouter redirect is a documented stub)
- Strict production linting
- Complete documentation (ARCHITECTURE.md + PACKAGE.md per package)
- Monorepo doctor with template-backed `--fix` restoration; never writes empty
  placeholders
- Project marker (`.flutter_monorepo.yaml`) so doctor and workflow read the
  generation config instead of inferring it
- Generated starter tests per package and a CI workflow that passes as generated
- Development workflows (component, screen, business logic)
- AI Agent Skills for Claude Code (4 framework-aware skills)
