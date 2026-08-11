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

> **Note:** the command above is the target state. `--ci`, `--flavor` and
> `--auth` are not implemented yet — see the roadmap below for what ships
> today. Everything marked "Planned" is rejected by the current CLI.

No other pub.dev package does this comprehensively.

---

## v1.0 — Core Options (5x audience)

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
```
Platforms must be listed explicitly; there is no `all` shorthand.
Web and desktop are growing fast in 2026.

### `--git` — Auto Git Init
```bash
flutter_monorepo my_app --git         # git init + initial commit (default: on)
flutter_monorepo my_app --no-git
```

---

## Shipped — HTTP Client

### `--http` — HTTP Client Choice
```bash
flutter_monorepo my_app --http dio          # default
flutter_monorepo my_app --http http
flutter_monorepo my_app --http chopper
```

## Planned — Production-Ready (not implemented)

### `--storage` — Local Persistence Choice
```bash
flutter_monorepo my_app --storage get_storage      # default
flutter_monorepo my_app --storage shared_prefs
flutter_monorepo my_app --storage hive
```

### `--ci` — CI/CD Templates
```bash
flutter_monorepo my_app --ci github       # GitHub Actions
flutter_monorepo my_app --ci gitlab
flutter_monorepo my_app --ci none         # default
```
Generates workflow files for lint, test, build.

### `--flavor` — Build Flavors (dev/staging/prod)
```bash
flutter_monorepo my_app --flavor
```
Generates environment configs, `.env` file pattern, and flavor-specific launch configs.

---

## Planned — Full Scaffolding Platform (not implemented)

### `--auth` — Auth Scaffolding
```bash
flutter_monorepo my_app --auth firebase
flutter_monorepo my_app --auth supabase
flutter_monorepo my_app --auth custom       # just interfaces
flutter_monorepo my_app --auth none         # default
```
Generates login/register screens, auth controller, token storage, route guards wired up.

### `--template` — Project Templates
```bash
flutter_monorepo my_app --template blank          # default
flutter_monorepo my_app --template ecommerce
flutter_monorepo my_app --template social
flutter_monorepo my_app --template dashboard
```
Pre-built screen sets with navigation, bottom tabs, drawers.

### `--test` — Testing Setup
```bash
flutter_monorepo my_app --test unit        # unit tests only (default)
flutter_monorepo my_app --test full        # unit + widget + integration
```
Generates test directory structure, mock helpers, and example tests for each package.

---

## Release Roadmap

| Version | Features | Impact |
|---------|----------|--------|
| **v1.0** | `--state` (getx/riverpod/bloc/cubit), `--locales`, `--platforms`, `--git` | 5x audience |
| **v1.1** | `--http` (dio/http/chopper), `doctor`, `workflow` | Production-ready |
| **v1.2** | AI Agent Skills (`.claude/skills/`), smart `doctor --fix` | AI-assisted development |
| **v1.3** | `--license` (11 types), `--github` (community files), README/LICENSE/CONTRIBUTING | Top-tier GitHub repo |
| **v1.4** | Audit fixes: working dependency resolution, honest exit codes, project marker file, `ARCHITECTURE.md`, starter tests, green CI | Generated projects actually build |

---

## Current State (v1.4.0)

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
- Full Material 3 theme (light + dark, 24 component themes)
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
