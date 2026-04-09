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
