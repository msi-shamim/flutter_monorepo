import '../project_config.dart';

/// Returns `.claude/settings.json` content with pre-approved tools.
String claudeSettings() {
  return '''{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(dart analyze)",
      "Bash(dart test)",
      "Bash(flutter test)",
      "Bash(flutter gen-l10n)",
      "Bash(dart pub get)",
      "Bash(dart format)"
    ]
  }
}
''';
}

/// Returns the component-design SKILL.md (Workflow A).
String componentDesignSkill(ProjectConfig c) {
  return '''---
name: component-design
description: >
  Build a reusable widget in packages/ui/ with optional companion state
  in packages/core/. Trigger: "Build a component", "Create a widget",
  "Convert this Figma element".
---

# Component Design Workflow

Build reusable, framework-agnostic widgets in `packages/ui/` with optional
companion state classes in `packages/core/`.

## When to use

- Building a reusable UI component (button, card, input, etc.)
- Converting a Figma design element into a Flutter widget
- Creating interactive components that need state (validation, selection, etc.)

## File placement

'''
      '```\n'
      'packages/ui/lib/widgets/<component_name>.dart      # The widget\n'
      'packages/core/lib/states/<component_name>_state.dart # Companion state (if needed)\n'
      'packages/ui/test/widgets/<component_name>_test.dart  # Widget test\n'
      'packages/core/test/states/<component_name>_state_test.dart # State test\n'
      '```\n'
      '''

## Widget rules

| Rule | Why |
|------|-----|
| All dynamic content via constructor parameters | Reusability |
| All text via String parameters, never hardcoded | Language-agnostic (EN/AR) |
| Callbacks via VoidCallback / ValueChanged<T> | No framework coupling |
| Uses AppColors, AppSpacing, AppTypography from theme/ | Consistent design tokens |
| Uses LayoutBuilder or MediaQuery for responsive sizing | Device responsiveness |
| Supports RTL (use start/end, not left/right) | Arabic support |
'''
      '| No state management imports (GetX, Riverpod, Bloc) | Framework-agnostic |\n'
      '''

## Companion state rules

Create a companion state class when the component has interactive behavior
beyond a simple tap callback (validation, selection, upload progress, etc.).

| Rule | Why |
|------|-----|
| Pure Dart class — no Flutter, no framework imports | Unit testable |
| Holds state values + mutation methods | Single source of truth |
| Emits no UI — only data and status | Widget reads state |
'''
      '| Lives in `packages/core/lib/states/` | Available to all packages |\n'
      '''| Constructor accepts configuration (validators, limits) | Reusable per screen |

## Checklist

### Widget (packages/ui)
- [ ] No hardcoded strings
- [ ] No framework imports (GetX, Riverpod, Bloc)
- [ ] No navigation calls
- [ ] All dynamic content via constructor
- [ ] Uses AppColors / AppSpacing / AppTypography
- [ ] Responsive layout
- [ ] RTL-safe (start/end instead of left/right)
'''
      '- [ ] Exported from `packages/ui/lib/${c.ui}.dart` barrel\n'
      '- [ ] Widget test in `packages/ui/test/widgets/`\n'
      '''
### Companion state (packages/core) — if applicable
- [ ] Pure Dart — no Flutter, no framework imports
- [ ] Holds state values + mutation methods
- [ ] Accepts configuration via constructor
- [ ] Unit testable without mocking
'''
      '- [ ] Exported from `packages/core/lib/${c.core}.dart` barrel\n'
      '- [ ] Unit test in `packages/core/test/states/`\n'
      '''
## Verification

Run these commands after implementation:

'''
      '```bash\n'
      'dart analyze\n'
      'flutter test packages/ui/test/\n'
      'dart test packages/core/test/\n'
      '```\n';
}

/// Returns the screen-design SKILL.md (Workflow B).
///
/// Adapts instructions based on the chosen state management framework.
String screenDesignSkill(ProjectConfig c) {
  final smName = c.stateManagement.name;

  // Framework-specific terminology
  final String controllerTerm;
  final String bindingTerm;
  final String routingTerm;
  final String stateDir;
  final String screenStructure;

  switch (c.stateManagement) {
    case StateManagement.getx:
      controllerTerm = 'GetxController';
      bindingTerm = 'Bindings class with Get.lazyPut()';
      routingTerm = 'GetPage in app_pages.dart';
      stateDir = 'controllers';
      screenStructure =
          '''
### Screen folder structure

'''
          '```\n'
          '${c.app}/lib/screens/<screen_name>/\n'
          '├── <screen_name>_controller.dart   # GetxController — state + logic\n'
          '├── <screen_name>_binding.dart       # Bindings — DI setup\n'
          '├── <screen_name>_screen.dart        # GetView — assembles sections\n'
          '└── sections/                        # Major UI sections\n'
          '    ├── header_section.dart\n'
          '    └── content_section.dart\n'
          '```\n'
          '''

### Controller pattern

- Extend GetxController
- Use .obs for reactive state
- Companion states from packages/core/lib/states/ for component logic
- API calls through repository interfaces (injected via binding)

### Binding pattern

- Extend Bindings
- Use Get.lazyPut() to register controller and dependencies
- Inject network implementations for core interfaces

### Routing

Add route in `${c.app}/lib/app/routes/app_routes.dart` and
register GetPage in `${c.app}/lib/app/routes/app_pages.dart`.
''';
    case StateManagement.riverpod:
      controllerTerm = 'Notifier';
      bindingTerm = 'Provider declarations';
      routingTerm = 'GoRoute in app_router.dart';
      stateDir = 'providers';
      screenStructure =
          '''
### Screen folder structure

'''
          '```\n'
          '${c.app}/lib/screens/<screen_name>/\n'
          '├── <screen_name>_provider.dart   # Notifier + provider\n'
          '├── <screen_name>_screen.dart     # ConsumerWidget — assembles sections\n'
          '└── sections/                     # Major UI sections\n'
          '    ├── header_section.dart\n'
          '    └── content_section.dart\n'
          '```\n'
          '''

### Provider pattern

- Use Notifier with @riverpod or manual provider declaration
- Companion states from packages/core/lib/states/ for component logic
- Access providers via ref.watch() / ref.read()

### Routing

Add GoRoute in `${c.app}/lib/app/router/app_router.dart`.
''';
    case StateManagement.bloc:
      controllerTerm = 'Bloc (event-driven)';
      bindingTerm = 'BlocProvider in screen or router';
      routingTerm = 'GoRoute in app_router.dart';
      stateDir = 'blocs';
      screenStructure =
          '''
### Screen folder structure

'''
          '```\n'
          '${c.app}/lib/screens/<screen_name>/\n'
          '├── <screen_name>_bloc.dart       # Bloc — events + states + logic\n'
          '├── <screen_name>_event.dart      # Event classes\n'
          '├── <screen_name>_state.dart      # State classes\n'
          '├── <screen_name>_screen.dart     # BlocBuilder — assembles sections\n'
          '└── sections/                     # Major UI sections\n'
          '    ├── header_section.dart\n'
          '    └── content_section.dart\n'
          '```\n'
          '''

### Bloc pattern

- Define events (sealed class) and states (sealed class)
- Use on<Event>() handlers in Bloc constructor
- Companion states from packages/core/lib/states/ for component logic

### Routing

Add GoRoute in `${c.app}/lib/app/router/app_router.dart`.
Wrap with BlocProvider at the route level.
''';
    case StateManagement.cubit:
      controllerTerm = 'Cubit (direct emit)';
      bindingTerm = 'BlocProvider in screen or router';
      routingTerm = 'GoRoute in app_router.dart';
      stateDir = 'blocs';
      screenStructure =
          '''
### Screen folder structure

'''
          '```\n'
          '${c.app}/lib/screens/<screen_name>/\n'
          '├── <screen_name>_cubit.dart      # Cubit — state + methods\n'
          '├── <screen_name>_state.dart      # State classes\n'
          '├── <screen_name>_screen.dart     # BlocBuilder — assembles sections\n'
          '└── sections/                     # Major UI sections\n'
          '    ├── header_section.dart\n'
          '    └── content_section.dart\n'
          '```\n'
          '''

### Cubit pattern

- Extend Cubit<State> or HydratedCubit<State>
- Use emit() directly (no events)
- Companion states from packages/core/lib/states/ for component logic

### Routing

Add GoRoute in `${c.app}/lib/app/router/app_router.dart`.
Wrap with BlocProvider at the route level.
''';
  }

  return '''---
name: screen-design
description: >
  Build a full screen with $smName state management, sections pattern,
  and routing. Trigger: "Build this screen", "Create a page".
---

# Screen Design Workflow ($smName)

Turn a Figma screen design into a production-ready screen using
$controllerTerm for state, sections pattern for UI decomposition,
and $routingTerm for navigation.

## When to use

- Building a new screen/page from a Figma design
- Adding a new route to the app
- Creating a screen with API-driven content

## State management: $smName

- Controller: $controllerTerm
- DI: $bindingTerm
- Routing: $routingTerm
- App state directory: `${c.app}/lib/app/$stateDir/`

$screenStructure

## Section widget rules

| Rule | Why |
|------|-----|
| Sections are StatelessWidget | They do not own state |
| Receive data + callbacks via parameters | Decoupled from framework |
'''
      '| Reuse `${c.ui}` widgets where possible | Do not rebuild what exists |\n'
      '''| Translations via AppLocalizations.of(context) | Sections have BuildContext |

## Localization

Add new user-facing strings to ARB files:

'''
      '```\n'
      'packages/l10n/lib/l10n/arb/app_<locale>.arb\n'
      '```\n'
      '''

Then run:

'''
      '```bash\n'
      'cd packages/l10n && flutter gen-l10n\n'
      '```\n'
      '''

## Checklist

- [ ] Controller handles all state and logic — sections are stateless
- [ ] Screen file is under ~80 lines (assembly only)
- [ ] Each section is a separate file under sections/
'''
      '- [ ] Sections reuse `${c.ui}` widgets where applicable\n'
      '''- [ ] No hardcoded strings — all from AppLocalizations
- [ ] Both EN and AR strings added to ARB files
- [ ] Route registered
- [ ] Dependencies properly injected
- [ ] Responsive layout
- [ ] RTL-safe layout
'''
      '- [ ] Controller test in `${c.app}/test/screens/<name>/`\n'
      '''
## Verification

'''
      '```bash\n'
      'dart analyze\n'
      'flutter test ${c.app}/test/\n'
      '```\n';
}

/// Returns the business-logic SKILL.md (Workflow C).
String businessLogicSkill(ProjectConfig c) {
  // Framework-specific wiring examples
  final String wiringExample;
  switch (c.stateManagement) {
    case StateManagement.getx:
      wiringExample =
          '''
### Wiring in the app (GetX)

The controller depends on the abstract repository (from core), not the
concrete implementation (from network). The binding injects the implementation.

'''
          '```\n'
          '// screen_binding.dart\n'
          'class ScreenBinding extends Bindings {\n'
          '  @override\n'
          '  void dependencies() {\n'
          '    Get.lazyPut<OrderRepository>(() => OrderRepositoryImpl(Get.find()));\n'
          '    Get.lazyPut(() => ScreenController(Get.find()));\n'
          '  }\n'
          '}\n'
          '```\n';
    case StateManagement.riverpod:
      wiringExample =
          '''
### Wiring in the app (Riverpod)

Use provider overrides or ref.read() to inject the network implementation
for the core repository interface.

'''
          '```\n'
          '// screen_provider.dart\n'
          'final orderRepositoryProvider = Provider<OrderRepository>(\n'
          '  (ref) => OrderRepositoryImpl(ref.read(apiClientProvider)),\n'
          ');\n'
          '```\n';
    case StateManagement.bloc:
    case StateManagement.cubit:
      wiringExample =
          '''
### Wiring in the app (${c.stateManagement.name})

Use RepositoryProvider or constructor injection to provide the network
implementation for the core repository interface.

'''
          '```\n'
          '// In router or parent widget\n'
          'RepositoryProvider<OrderRepository>(\n'
          '  create: (_) => OrderRepositoryImpl(apiClient),\n'
          '  child: BlocProvider(\n'
          '    create: (ctx) => ScreenBloc(ctx.read<OrderRepository>()),\n'
          '    child: const ScreenView(),\n'
          '  ),\n'
          ')\n'
          '```\n';
  }

  return '''---
name: business-logic
description: >
  Implement business rules in packages/core/, API integration in
  packages/network/, and wire into the app. Trigger: "Implement this rule",
  "Add business logic", "Create a repository".
---

# Business Logic Workflow

Turn business rules into testable, framework-agnostic logic in `packages/core/`,
implement API integration in `packages/network/`, and wire it into the app
with dependency inversion.

## When to use

- Implementing business rules from a spec or Google Doc
- Adding API integration for a feature
- Creating repository interfaces and implementations

## Architecture layers

| Layer | Location | Contains | Depends on |
|-------|----------|----------|------------|
'''
      '| Rules | `packages/core/lib/rules/` | Pure business logic | Core models only |\n'
      '| Models | `packages/core/lib/models/` | Entities, enums, value objects | Nothing |\n'
      '| Repo interface | `packages/core/lib/repositories/` | Abstract contract | Core models |\n'
      '| Repo impl | `packages/network/lib/repositories/` | API calls | Core + HTTP client |\n'
      '| Controller | `${c.app}/lib/screens/*/` | State wiring | Core (injected) |\n'
      '''
## The business firewall

'''
      '```\n'
      'packages/core/ — BUSINESS RULES FIREWALL\n'
      '\n'
      '  - Pure Dart — no Flutter, no ${c.stateManagement.name}, no HTTP\n'
      '  - Rules are plain functions or classes\n'
      '  - Repository interfaces define WHAT, not HOW\n'
      '  - Unit testable with zero mocking\n'
      '  - Swapping API provider = change packages/network/ only\n'
      '  - Swapping state management = change ${c.app}/ only\n'
      '  - Business logic NEVER changes when infra changes\n'
      '```\n'
      '''

## File placement

'''
      '```\n'
      'packages/core/lib/\n'
      '├── models/           # Data classes, enums, value objects\n'
      '├── rules/            # Pure business logic functions/classes\n'
      '├── repositories/     # Abstract interfaces\n'
      '└── ${c.core}.dart    # Barrel export\n'
      '\n'
      'packages/network/lib/\n'
      '├── repositories/     # Implements core interfaces with API calls\n'
      '└── ${c.network}.dart # Barrel export\n'
      '```\n'
      '''

$wiringExample

## Persistence

Never call a storage package directly. The project persists through
`KeyValueStore`, an interface in `packages/core`, with one implementation in
`${c.app}/lib/app/storage/`. The backend is ${c.storage.cliName}.

```dart
import '../storage/app_store.dart';

appStore.write('key', value);
final value = appStore.read<int>('key');   // synchronous
```

`read` is synchronous because the store loads during bootstrap, so state can
be restored during construction rather than after a frame. Naming a storage
package anywhere outside `${c.app}/lib/app/storage/` is a defect: it defeats
the one place the backend is chosen.
${authSkillSection(c)}${environmentSkillSection(c)}
## Error handling pattern

All repository methods return Result<T>:
- Success<T> — holds the value
- Failure — holds AppException

Controllers pattern-match on Result to update UI state.

## Checklist

'''
      '- [ ] Business rules in `packages/core/lib/rules/` — pure Dart\n'
      '- [ ] Models in `packages/core/lib/models/` — plain data classes\n'
      '- [ ] Repository interface in `packages/core/lib/repositories/` — abstract only\n'
      '- [ ] Repository impl in `packages/network/lib/repositories/` — API calls\n'
      '''- [ ] Controller depends on interface, not implementation
- [ ] Binding/provider injects the concrete implementation
- [ ] Business rules unit testable without mocking
'''
      '- [ ] All exports updated in barrel files\n'
      '- [ ] Rule tests in `packages/core/test/rules/`\n'
      '- [ ] Model tests in `packages/core/test/models/`\n'
      '''
## Verification

'''
      '```bash\n'
      'dart analyze\n'
      'dart test packages/core/test/\n'
      'flutter test packages/network/test/\n'
      'flutter test ${c.app}/test/\n'
      '```\n';
}

/// Returns the monorepo-doctor SKILL.md.
String monrepoDoctorSkill(ProjectConfig c) {
  return '''---
name: monorepo-doctor
description: >
  Check monorepo structure integrity and fix missing items.
  Trigger: "Check structure", "What is missing", "Run doctor".
---

# Monorepo Doctor

Verify the monorepo structure matches the expected layout and fix any
missing directories or files.

## When to use

- After pulling changes or resolving merge conflicts
- When something feels broken or a file seems missing
- Before a release to verify structure completeness
- When onboarding a new developer

## How to run

'''
      '```bash\n'
      '# The CLI is a global tool; the project does not depend on it.\n'
      '# dart pub global activate flutter_monorepo   # once, if not installed\n'
      '\n'
      '# Check structure (report only)\n'
      'flutter_monorepo doctor\n'
      '\n'
      '# Check and fix what it can\n'
      'flutter_monorepo doctor --fix\n'
      '```\n'
      '''

## What it checks

### Directories (${c.stateManagement.name} variant)

- Root packages: core, ui, network, l10n, ${c.app}
- Core: exceptions, models, rules, states, repositories, usecases, utils, extensions
- UI: assets, responsive, theme, widgets + asset dirs (icons, fonts, images)
- Network: client, interceptors, repositories
- L10n: formatters, widgets, l10n/arb, l10n/generated
- App: routes, screens/home + framework-specific dirs
- Tests: core/test/{states,rules,models}, ui/test/widgets, network/test, ${c.app}/test/screens
- Skills: .claude/skills/{component-design,screen-design,business-logic,monorepo-doctor}

### Files

- Root: .flutter_monorepo.yaml (generation marker), README.md, ARCHITECTURE.md,
  LICENSE, CONTRIBUTING.md, .gitignore, analysis_options.yaml
- Storage: core KeyValueStore + the app implementation
${c.auth == AuthProvider.none ? '' : '- Auth: AUTH.md, core AuthRepository and AuthUser, the app implementation, login screen\n'}${c.flavors ? '- Flavors: FLAVORS.md, app_environment.dart, one entrypoint per flavor\n' : ''}${c.template == ProjectTemplate.blank ? '' : '- Template: the ${c.template.cliName} screens and their core model\n'}
- All pubspec.yaml, PACKAGE.md, barrel exports
- Core: app_exception, base_model, base_repository, use_case, result, extensions
- UI: app_icons, app_images, app_fonts, breakpoints, responsive, theme files
- Network: api_client, auth_interceptor, logging_interceptor
- L10n: l10n.yaml, formatters, directionality_builder, ARB files per locale
- App: main.dart, routes, home screen + framework-specific files
- Skills: .claude/settings.json + 4 SKILL.md files
- GitHub: .github/ files (if --github was used)

## Fixing issues

When doctor reports missing items:

1. If a **directory** is missing — it was likely deleted by accident. `--fix` recreates it.
2. If a **file** has a template — `--fix` restores its full content (README, ARCHITECTURE,
   LICENSE, CONTRIBUTING, .gitignore, the skills and settings, the directory sentinels).
3. If a file has no template — `--fix` reports it and leaves it absent, deliberately. Writing
   an empty placeholder would satisfy the next check and hide the problem. Restore it from git.
4. `--fix` never overwrites a file that already exists, so local edits are safe.
5. If many items are missing — consider re-running the generator or checking git history.
''';
}

/// `AGENTS.md` — cross-agent instructions at the project root.
///
/// Codex reads this convention, as do a growing number of other tools. It
/// carries the same architectural rules the Claude skills encode, so an agent
/// that does not read `.claude/skills/` still gets the boundaries that make
/// this layout work. Deliberately one file rather than a per-tool set:
/// four near-identical config files would drift apart independently.
String agentsMd(ProjectConfig c) {
  final stateDir = switch (c.stateManagement) {
    StateManagement.getx => 'controllers',
    StateManagement.riverpod => 'providers',
    StateManagement.bloc || StateManagement.cubit => 'blocs',
  };

  return '''
# Agent instructions

${c.pascal} is a Flutter monorepo: one app package and four shared packages.
These are the rules that keep the layout working. They apply to any change,
by a person or an agent.

## Package boundaries

| Package | Holds | May import |
|---------|-------|------------|
| `packages/core` | Models, rules, use cases, `Result<T>`, exceptions${c.auth == AuthProvider.none ? '' : ', `AuthRepository`'} | **Pure Dart only — never Flutter** |
| `packages/ui` | Theme, spacing, typography, responsive helpers, shared widgets | Flutter, `${c.core}` |
| `packages/network` | HTTP client (${c.httpClient.name}), interceptors, repositories | `${c.core}` |
| `packages/l10n` | ARB files, generated localizations, formatters | Flutter, `intl` |
| `${c.app}` | Screens, ${c.stateManagement.name} state, routing, DI | Everything above |

Adding a Flutter import to `packages/core` breaks the one invariant this
project is built on: it is what lets the rules be tested with `dart test`,
with no widget binding and no mocking of framework types.

## Non-negotiables

- **Failures are values, not throws.** Repository methods return `Result<T>`;
  callers use `.when(success:, failure:)`. Exceptions extend `AppException`.
- **Persistence goes through `KeyValueStore`.** Use `appStore` from
  `${c.app}/lib/app/storage/app_store.dart`. Never import a storage package
  outside that directory — the backend (${c.storage.cliName}) is chosen in one
  place on purpose.
${c.auth == AuthProvider.none ? '' : '- **Auth goes through `AuthRepository`.** Use `authRepository` from `${c.app}/lib/app/auth/auth.dart`. Never import a provider SDK (${c.auth.cliName}) outside that directory. See AUTH.md.\n'}${c.flavors ? '- **Environment values come from `appEnv`**, not from branching on the build. Add a getter to `AppEnvironment` instead. See FLAVORS.md.\n' : ''}- **No hardcoded user-facing strings.** Everything goes through `AppLocalizations`; add the key to every ARB file in `packages/l10n/lib/l10n/arb/`.
- **Widgets in `packages/ui` take data as parameters** and import no state
  management. That is what makes them reusable across screens.

## Where things go

```
packages/core/lib/models/        # data shapes
packages/core/lib/rules/         # business rules, pure Dart
packages/core/lib/repositories/  # interfaces only
packages/network/lib/repositories/  # implementations of those interfaces
packages/ui/lib/widgets/         # reusable widgets
${c.app}/lib/app/$stateDir/${' ' * (24 - stateDir.length)}# app-wide state
${c.app}/lib/screens/<name>/     # one folder per screen
```

## Verifying a change

```bash
dart analyze                          # must be clean
dart format .
dart test packages/core/test          # pure Dart
flutter test packages/ui/test
flutter test packages/network/test
flutter test ${c.app}/test
```

`flutter_monorepo doctor` checks the structure is intact. The CLI is a global
tool — `dart pub global activate flutter_monorepo` — not a dependency of this
project, so `dart run flutter_monorepo` will not work.

## Claude Code

`.claude/skills/` holds four task-specific skills that Claude Code discovers
automatically: component design, screen design, business logic and the
monorepo doctor. They go further than this file, with per-framework
instructions and checklists. `.claude/settings.json` pre-approves the
read-only and test commands above.

Everything in this file applies regardless of which agent is being used.
''';
}

/// Auth guidance for the business-logic skill, when a provider is configured.
///
/// Conditional so a project without `--auth` is not told about an interface it
/// does not have — the skills describe the project as generated, not the tool's
/// full option set.
String authSkillSection(ProjectConfig c) {
  if (c.auth == AuthProvider.none) return '';

  return '''

## Authentication

Auth goes through `AuthRepository` in `packages/core`, implemented in
`${c.app}/lib/app/auth/` against ${c.auth.cliName}. Screens and guards depend
on the interface, never on a provider SDK.

```dart
import '../../app/auth/auth.dart';

final result = await authRepository.signIn(email: email, password: password);
result.when(
  success: (user) => /* navigate */,
  failure: (e) => /* show e.message */,
);
```

- `authRepository.currentUser` is the signed-in user, or null.
- `authRepository.authStateChanges()` emits on sign-in and sign-out; a route
  guard should listen to this rather than polling.
- Failures arrive as `AuthException` inside a `Failure`, never as a throw.

The route guard is generated but disabled. See AUTH.md before enabling it —
turning it on before sign-in works locks you out of the app.
''';
}

/// Environment guidance, when the project was generated with `--flavor`.
String environmentSkillSection(ProjectConfig c) {
  if (!c.flavors) return '';

  return '''

## Environments

This project builds as dev, staging and prod. Per-environment values live in
`${c.app}/lib/app/config/app_environment.dart`; read them through `appEnv`:

```dart
final client = ApiClient(baseUrl: appEnv.apiBaseUrl);
if (appEnv.isDebugBuild) enableVerboseLogging();
```

Add a new setting as a getter on `AppEnvironment` with a value per
environment, rather than branching on the environment at the call site. Run a
flavor with `flutter run --flavor dev -t lib/main_dev.dart`; see FLAVORS.md.
''';
}
