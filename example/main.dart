// example/main.dart
//
// This example demonstrates how to use flutter_monorepo programmatically.
// Most users will use the CLI directly — see "CLI Usage" below.
//
// ═══════════════════════════════════════════════════════════
// CLI USAGE (recommended)
// ═══════════════════════════════════════════════════════════
//
// Install:
//   dart pub global activate flutter_monorepo
//
// Basic (GetX + Dio + EN/AR):
//   flutter_monorepo my_app
//
// Riverpod + Dio + EN/ES/FR:
//   flutter_monorepo my_app --state riverpod --locales en,es,fr
//
// Bloc + http package + all platforms:
//   flutter_monorepo my_app --state bloc --http http --platforms android,ios,web
//
// Cubit + Chopper + single locale + no git:
//   flutter_monorepo my_app --state cubit --http chopper --locales en --no-git
//
// Custom org:
//   flutter_monorepo my_app --org com.mycompany
//
// Doctor (check structure integrity of existing project):
//   cd my_app
//   flutter_monorepo doctor
//   flutter_monorepo doctor --fix
//
// Workflow (development guides — auto-detects your framework):
//   cd my_app                          # run from inside project for tailored output
//   flutter_monorepo workflow          # overview + quick reference
//   flutter_monorepo workflow a        # Component Design Flow
//   flutter_monorepo workflow b        # Screen Design Flow (adapts to framework)
//   flutter_monorepo workflow c        # Business Logic Flow (adapts wiring step)
//
// Each workflow includes a TEST STEP — tests are written during
// development, not after. Test directories are pre-created:
//   packages/core/test/{states, rules, models}/
//   packages/ui/test/widgets/
//   packages/network/test/
//   <app>/test/screens/
//
// ═══════════════════════════════════════════════════════════
// ALL OPTIONS
// ═══════════════════════════════════════════════════════════
//
// Create:
//   -s, --state       getx (default), riverpod, bloc, cubit
//   -l, --locales     en,ar (default) — comma-separated locale codes
//   -p, --platforms   android,ios (default) — comma-separated platforms
//       --http        dio (default), http, chopper
//   -o, --org         com.example (default)
//       --[no-]git    on by default — auto git init + first commit
//   -h, --help        Show help
//       --version     Show version
//
// Doctor:
//       --fix         Auto-restore missing items (skill files restored with full content)
//   -h, --help        Show doctor help
//
// Workflow:
//   flutter_monorepo workflow          Overview + quick reference
//   flutter_monorepo workflow a        Component Design Flow
//   flutter_monorepo workflow b        Screen Design Flow
//   flutter_monorepo workflow c        Business Logic Flow
//
// ═══════════════════════════════════════════════════════════
// GENERATED STRUCTURE
// ═══════════════════════════════════════════════════════════
//
//   my_app/
//   ├── my_app_app/                  # Main Flutter app
//   │   ├── lib/
//   │   │   ├── main.dart            # App entry point
//   │   │   ├── app/
//   │   │   │   ├── controllers/     # GetX: theme + locale controllers
//   │   │   │   ├── providers/       # Riverpod: theme + locale providers
//   │   │   │   ├── blocs/           # Bloc/Cubit: theme + locale blocs
//   │   │   │   ├── routes/          # Route constants
//   │   │   │   └── router/          # GoRouter config (non-GetX)
//   │   │   └── screens/
//   │   │       └── home/            # Demo home screen
//   │   ├── android/
//   │   └── ios/
//   ├── packages/
//   │   ├── core/                    # Business logic (framework-free)
//   │   │   └── lib/
//   │   │       ├── exceptions/      # Sealed AppException hierarchy
//   │   │       ├── models/          # BaseModel with equality
//   │   │       ├── repositories/    # Abstract repository contracts
//   │   │       ├── usecases/        # UseCase<T,P> base classes
//   │   │       ├── utils/           # Result<T> = Success | Failure
//   │   │       └── extensions/      # String, DateTime, List extensions
//   │   ├── ui/                      # Design system
//   │   │   ├── assets/              # Icons, fonts, images
//   │   │   └── lib/
//   │   │       ├── theme/           # Material 3 light + dark (30+ components)
//   │   │       ├── responsive/      # Breakpoints, ResponsiveBuilder
//   │   │       ├── assets/          # Type-safe asset constants
//   │   │       └── widgets/         # Reusable stateless widgets
//   │   ├── network/                 # HTTP layer (Dio/http/Chopper)
//   │   │   └── lib/
//   │   │       ├── client/          # ApiClient with Result<T> returns
//   │   │       └── interceptors/    # Auth + logging interceptors
//   │   └── l10n/                    # Localization
//   │       └── lib/
//   │           ├── l10n/arb/        # ARB files per locale
//   │           ├── formatters/      # Date + number formatters
//   │           └── widgets/         # RTL DirectionalityBuilder
//   ├── .claude/                     # AI agent skills
//   │   ├── settings.json            # Pre-approved tools
//   │   └── skills/
//   │       ├── component-design/    # Workflow A skill
//   │       ├── screen-design/       # Workflow B skill (adapts per framework)
//   │       ├── business-logic/      # Workflow C skill
//   │       └── monorepo-doctor/     # Structure check skill
//   ├── pubspec.yaml                 # Workspace root
//   ├── analysis_options.yaml        # Strict production linting
//   └── ARCHITECTURE.md              # Full documentation
//
// ═══════════════════════════════════════════════════════════
// PROGRAMMATIC USAGE
// ═══════════════════════════════════════════════════════════

import 'package:flutter_monorepo/flutter_monorepo.dart';

void main() async {
  // 1. Create a configuration
  final config = ProjectConfig(
    name: 'my_app',
    org: 'com.example',
    stateManagement: StateManagement.riverpod,
    httpClient: HttpClient.dio,
    locales: ['en', 'es', 'fr'],
    platforms: ['android', 'ios', 'web'],
    gitInit: true,
  );

  // 2. Print derived names
  print('App package:     ${config.app}');        // my_app_app
  print('Core package:    ${config.core}');       // my_app_core
  print('UI package:      ${config.ui}');         // my_app_ui
  print('Network package: ${config.network}');    // my_app_network
  print('L10n package:    ${config.l10n}');       // my_app_l10n
  print('PascalCase:      ${config.pascal}');     // MyApp
  print('Primary locale:  ${config.primaryLocale}'); // en
  print('Uses GoRouter:   ${config.usesGoRouter}');  // true (Riverpod)
  print('');

  // 3. Check required packages for this configuration
  print('Required packages:');
  for (final pkg in config.requiredPackages) {
    print('  - $pkg');
  }
  print('');

  // 4. Version resolver (fetches latest compatible from pub.dev)
  final resolver = VersionResolver();
  print('Fallback versions (used when offline):');
  print('  dio: ${resolver['dio']}');
  print('  flutter_riverpod: ${resolver['flutter_riverpod']}');
  print('  go_router: ${resolver['go_router']}');
  print('');

  // 5. To generate a full project, use the Generator:
  // final generator = Generator(config: config, rootPath: '/path/to/output');
  // await generator.run();
  //
  // Or just use the CLI:
  //   flutter_monorepo my_app --state riverpod --locales en,es,fr

  // 6. Doctor — check structure integrity programmatically:
  // final doctor = Doctor(rootPath: '/path/to/my_app', fix: false);
  // final allGood = await doctor.run();
  //
  // Or just use the CLI:
  //   cd my_app && flutter_monorepo doctor
  //   cd my_app && flutter_monorepo doctor --fix

  // 7. Workflow — show development guides programmatically:
  // Auto-detects framework when config is provided:
  // final detected = detectProjectConfig('/path/to/my_app');
  // Workflow().run(null, config: detected);   // overview
  // Workflow().run('a');                       // component design flow
  // Workflow().run('b', config: detected);     // screen design flow (adapts to framework)
  // Workflow().run('c', config: detected);     // business logic flow (adapts wiring)
  //
  // Or just use the CLI (auto-detects when run from inside a project):
  //   cd my_app && flutter_monorepo workflow a

  // 8. AI Agent Skills — generated automatically in .claude/skills/
  // Skills teach Claude Code your project's architecture and workflows:
  //   .claude/skills/component-design/SKILL.md  — Workflow A
  //   .claude/skills/screen-design/SKILL.md     — Workflow B (adapts per framework)
  //   .claude/skills/business-logic/SKILL.md    — Workflow C
  //   .claude/skills/monorepo-doctor/SKILL.md   — Structure check
  // No setup needed — Claude Code auto-discovers skills from .claude/skills/

  print('To generate a project, run:');
  print('  flutter_monorepo my_app --state riverpod --locales en,es,fr');
  print('');
  print('To check an existing project:');
  print('  cd my_app && flutter_monorepo doctor');
  print('');
  print('To see development workflows:');
  print('  flutter_monorepo workflow a');
}
