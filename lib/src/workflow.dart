import 'dart:io';

import 'project_config.dart';

/// Displays development workflow guides for the generated monorepo.
///
/// When [config] is provided (auto-detected from the current project),
/// instructions adapt to the project's state management framework.
/// When `null`, a generic multi-framework summary is shown.
class Workflow {
  /// Shows the requested workflow.
  ///
  /// Pass `null` for [flow] to show the overview.
  /// When [config] is provided, instructions are tailored to the
  /// detected state management framework.
  void run(String? flow, {ProjectConfig? config}) {
    switch (flow?.toLowerCase()) {
      case 'a':
        _printComponentFlow();
      case 'b':
        _printScreenFlow(config);
      case 'c':
        _printBusinessLogicFlow(config);
      default:
        _printOverview(config);
    }
  }

  // ── Overview ─────────────────────────────────────────────

  void _printOverview(ProjectConfig? config) {
    final sm = config?.stateManagement;

    // Workflow B description adapts
    final workflowBDesc = switch (sm) {
      StateManagement.getx =>
        'Figma screen → controller + binding + screen + sections',
      StateManagement.riverpod =>
        'Figma screen → provider + screen + sections',
      StateManagement.bloc =>
        'Figma screen → bloc + events + states + screen + sections',
      StateManagement.cubit =>
        'Figma screen → cubit + state + screen + sections',
      null =>
        'Figma screen → controller/provider/bloc + screen + sections',
    };

    // Quick reference: state management directory
    final stateDir = switch (sm) {
      StateManagement.getx => 'controllers/',
      StateManagement.riverpod => 'providers/',
      StateManagement.bloc || StateManagement.cubit => 'blocs/',
      null => 'controllers/ or providers/ or blocs/',
    };

    // Quick reference: DI line
    final diLine = switch (sm) {
      StateManagement.getx =>
        'DI binding               → <app>/lib/app/bindings/',
      StateManagement.riverpod =>
        'Provider declarations    → <app>/lib/app/providers/',
      StateManagement.bloc || StateManagement.cubit =>
        'BlocProvider setup       → <app>/lib/app/blocs/',
      null =>
        'DI setup                 → <app>/lib/app/(bindings/ or providers/ or blocs/)',
    };

    // Quick reference: routing
    final routeLine = switch (sm) {
      StateManagement.getx =>
        'Route definition         → <app>/lib/app/routes/',
      StateManagement.riverpod ||
      StateManagement.bloc ||
      StateManagement.cubit =>
        'Route definition         → <app>/lib/app/router/',
      null =>
        'Route definition         → <app>/lib/app/routes/ or router/',
    };

    // Quick reference: middleware/guard
    final guardLine = switch (sm) {
      StateManagement.getx =>
        'Route guard / middleware → <app>/lib/app/middleware/',
      _ => null, // Only GetX has middleware directory
    };

    stdout.writeln('''

╔══════════════════════════════════════════════════╗
║  Flutter Monorepo — Development Workflows        ║
╚══════════════════════════════════════════════════╝

Three workflows cover everything you'll build:

  A. Component Design Flow
     Figma component → reusable widget + companion state
     Run: flutter_monorepo workflow a

  B. Screen Design Flow
     $workflowBDesc
     Run: flutter_monorepo workflow b

  C. Business Logic Flow
     Business rules → core models + rules + repos + controller wiring
     Run: flutter_monorepo workflow c

Quick Reference — Where does it go?
────────────────────────────────────────────────────
  Reusable widget          → packages/ui/lib/widgets/
  Companion state          → packages/core/lib/states/
  Theme / colors / spacing → packages/ui/lib/theme/
  Responsive utilities     → packages/ui/lib/responsive/
  Assets (icons/fonts/img) → packages/ui/assets/
  Data model / entity      → packages/core/lib/models/
  Exception type           → packages/core/lib/exceptions/
  Business rule            → packages/core/lib/rules/
  Use case / interactor    → packages/core/lib/usecases/
  Repository interface     → packages/core/lib/repositories/
  Extensions               → packages/core/lib/extensions/
  API client / HTTP call   → packages/network/lib/
  Repository impl (API)    → packages/network/lib/repositories/
  Interceptor              → packages/network/lib/interceptors/
  Translatable string      → packages/l10n/lib/l10n/arb/
  Date/number formatter    → packages/l10n/lib/formatters/
  Screen with state        → <app>/lib/screens/<name>/
  Controller / provider    → <app>/lib/app/$stateDir
  $routeLine
  $diLine''');
    if (guardLine != null) stdout.writeln('  $guardLine');
    stdout.writeln('''

AI Agent Skills
────────────────────────────────────────────────────
  These workflows are also available as AI agent skills in .claude/skills/.
  When using Claude Code, the skills are auto-discovered — just describe
  what you want to build and the agent follows the correct workflow.
''');
  }

  // ── Workflow A — Component Design ────────────────────────

  void _printComponentFlow() {
    stdout.writeln('''

╔══════════════════════════════════════════════════╗
║  Workflow A — Component Design Flow              ║
╚══════════════════════════════════════════════════╝

Goal: Turn a design element into a reusable widget + companion state.
Every component ships as a PAIR.

Step 1 — Provide the design
───────────────────────────
  Paste a screenshot of the component along with:
  • Component name (e.g., "SearchBar", "OtpInput")
  • Interaction notes (tap, long-press, swipe)
  • Variants (small/medium/large, active/disabled/loading)
  • Dynamic content (what comes from data vs what's fixed)

Step 2a — Widget (packages/ui/lib/widgets/)
───────────────────────────────────────────
  Rules:
  • All content via constructor parameters
  • All text via String params (never hardcoded)
  • Callbacks via VoidCallback / ValueChanged<T>
  • Uses AppColors, AppSpacing, AppTypography
  • Responsive (LayoutBuilder / MediaQuery)
  • RTL-safe (start/end, not left/right)
  • No GetX / Riverpod / Bloc imports

Step 2b — Companion State (packages/core/lib/states/)
─────────────────────────────────────────────────────
  For components with interactive logic beyond a simple tap:

  Component        State handles
  ─────────        ─────────────
  TextField        Validation, error message, debounce, clear
  Dropdown         Selected item, search/filter, loading, multi-select
  ImageAttachment  Picked file, upload progress, status, retry
  SearchBar        Query, debounce, results, loading/empty/error
  OTP Input        Digits, auto-advance, countdown, resend
  Quantity Stepper  Value, min/max bounds, step size

  Rules:
  • Pure Dart — no Flutter, no state management framework
  • Holds state values + mutation methods
  • Constructor accepts configuration (validators, limits)
  • Unit testable without mocking

  Skip when: Component is display-only (e.g., ProductCard with just onTap)

Step 3 — Export from barrels
────────────────────────────
  Widget:  packages/ui/lib/<project>_ui.dart
  State:   packages/core/lib/<project>_core.dart

Step 4 — Write tests (during development, not after)
─────────────────────────────────────────────────────
  Companion state test → packages/core/test/states/
    Test: initial state, valid input, invalid input, clear/reset
    Pure Dart — no mocking needed

  Widget test → packages/ui/test/widgets/
    Test: renders correctly, variants, RTL layout

Step 5 — Verify
────────────────
  Run: dart analyze && dart test

Checklist
─────────
  Widget:
  [ ] No hardcoded strings
  [ ] No framework imports (GetX/Riverpod/Bloc)
  [ ] All content via constructor
  [ ] Responsive + RTL-safe
  [ ] Exported from ui barrel
  [ ] Widget test in packages/ui/test/widgets/

  Companion State (if applicable):
  [ ] Pure Dart — no Flutter imports
  [ ] State values + mutation methods
  [ ] Configurable via constructor
  [ ] Unit testable
  [ ] Exported from core barrel
  [ ] Unit test in packages/core/test/states/

AI Agent Skill
──────────────
  This workflow is automated by the component-design skill.
  See .claude/skills/component-design/SKILL.md
''');
  }

  // ── Workflow B — Screen Design ───────────────────────────

  void _printScreenFlow(ProjectConfig? config) {
    final sm = config?.stateManagement;

    if (sm == null) {
      _printScreenFlowGeneric();
      return;
    }

    // Framework-specific variables
    final frameworkName = sm.name;
    final String controllerTerm;
    final String screenBase;
    final String statePattern;
    final String diPattern;
    final String routingStep;
    final String folderTree;
    final String fileResponsibilities;
    final String sectionRulesNote;
    final String routingInstructions;
    final String testFileNote;

    switch (sm) {
      case StateManagement.getx:
        controllerTerm = 'GetxController';
        screenBase = 'GetView<Controller>';
        statePattern = '.obs reactive fields';
        diPattern = 'Get.lazyPut() in binding';
        routingStep = 'Register GetPage in app/routes/app_pages.dart';
        folderTree = '''
  <app>/lib/screens/<name>/
  ├── <name>_controller.dart    # GetxController — state + logic (~100-150 lines)
  ├── <name>_binding.dart       # Bindings — DI setup (~15-25 lines)
  ├── <name>_screen.dart        # GetView — assembles sections (~50-80 lines)
  └── sections/                 # Major UI sections
      ├── header_section.dart
      ├── content_section.dart
      └── footer_section.dart''';
        fileResponsibilities = '''
  File responsibilities:
  ─────────────────────
  Controller  → Reactive state (.obs), API calls, uses companion states
  Binding     → Get.lazyPut() for controller + dependencies
  Screen      → GetView<Controller>, assembles sections in Scaffold
  Sections    → StatelessWidget, receive data + callbacks via params''';
        sectionRulesNote = '  • Stateless (not GetView) — controller owns the state';
        routingInstructions = '''
  Add route constant in app/routes/app_routes.dart
  Register GetPage in app/routes/app_pages.dart''';
        testFileNote = '  Controller test → <app>/test/screens/<name>/';

      case StateManagement.riverpod:
        controllerTerm = 'Notifier';
        screenBase = 'ConsumerWidget';
        statePattern = 'state class + Notifier';
        diPattern = 'Provider declarations';
        routingStep = 'Add GoRoute in app/router/app_router.dart';
        folderTree = '''
  <app>/lib/screens/<name>/
  ├── <name>_provider.dart      # Notifier + provider declaration (~80-120 lines)
  ├── <name>_screen.dart        # ConsumerWidget — assembles sections (~50-80 lines)
  └── sections/                 # Major UI sections
      ├── header_section.dart
      ├── content_section.dart
      └── footer_section.dart''';
        fileResponsibilities = '''
  File responsibilities:
  ─────────────────────
  Provider    → Notifier with state class, API calls, uses companion states
  Screen      → ConsumerWidget, uses ref.watch() to read providers
  Sections    → StatelessWidget, receive data + callbacks via params''';
        sectionRulesNote = '  • Stateless (not ConsumerWidget) — provider owns the state';
        routingInstructions = '''
  Add route constant in app/routes/app_routes.dart
  Add GoRoute in app/router/app_router.dart''';
        testFileNote = '  Provider test → <app>/test/screens/<name>/';

      case StateManagement.bloc:
        controllerTerm = 'Bloc (event-driven)';
        screenBase = 'BlocBuilder';
        statePattern = 'sealed events + sealed states + on<Event> handlers';
        diPattern = 'BlocProvider at route level';
        routingStep = 'Add GoRoute in app/router/app_router.dart';
        folderTree = '''
  <app>/lib/screens/<name>/
  ├── <name>_bloc.dart          # Bloc — event handlers + logic (~80-120 lines)
  ├── <name>_event.dart         # Sealed event classes (~30-50 lines)
  ├── <name>_state.dart         # Sealed state classes (~30-50 lines)
  ├── <name>_screen.dart        # BlocBuilder — assembles sections (~50-80 lines)
  └── sections/                 # Major UI sections
      ├── header_section.dart
      ├── content_section.dart
      └── footer_section.dart''';
        fileResponsibilities = '''
  File responsibilities:
  ─────────────────────
  Bloc        → on<Event>() handlers, API calls, uses companion states
  Events      → Sealed class hierarchy (e.g., LoadData, SubmitForm)
  States      → Sealed class hierarchy (e.g., Initial, Loading, Loaded, Error)
  Screen      → BlocBuilder<Bloc, State>, assembles sections in Scaffold
  Sections    → StatelessWidget, receive data + callbacks via params''';
        sectionRulesNote = '  • Stateless (not BlocBuilder) — bloc owns the state';
        routingInstructions = '''
  Add route constant in app/routes/app_routes.dart
  Add GoRoute in app/router/app_router.dart
  Wrap with BlocProvider at the route level''';
        testFileNote = '  Bloc test → <app>/test/screens/<name>/';

      case StateManagement.cubit:
        controllerTerm = 'Cubit (direct emit)';
        screenBase = 'BlocBuilder';
        statePattern = 'state class + emit() methods';
        diPattern = 'BlocProvider at route level';
        routingStep = 'Add GoRoute in app/router/app_router.dart';
        folderTree = '''
  <app>/lib/screens/<name>/
  ├── <name>_cubit.dart         # Cubit — state + methods (~60-100 lines)
  ├── <name>_state.dart         # State classes (~30-50 lines)
  ├── <name>_screen.dart        # BlocBuilder — assembles sections (~50-80 lines)
  └── sections/                 # Major UI sections
      ├── header_section.dart
      ├── content_section.dart
      └── footer_section.dart''';
        fileResponsibilities = '''
  File responsibilities:
  ─────────────────────
  Cubit       → Methods that emit() new states, API calls, uses companion states
  States      → State class (or sealed class for multiple states)
  Screen      → BlocBuilder<Cubit, State>, assembles sections in Scaffold
  Sections    → StatelessWidget, receive data + callbacks via params''';
        sectionRulesNote = '  • Stateless (not BlocBuilder) — cubit owns the state';
        routingInstructions = '''
  Add route constant in app/routes/app_routes.dart
  Add GoRoute in app/router/app_router.dart
  Wrap with BlocProvider at the route level''';
        testFileNote = '  Cubit test → <app>/test/screens/<name>/';
    }

    stdout.writeln('''

╔══════════════════════════════════════════════════╗
║  Workflow B — Screen Design Flow ($frameworkName)${' ' * (14 - frameworkName.length)}║
╚══════════════════════════════════════════════════╝

Goal: Turn a full screen design into a $controllerTerm + screen + sections,
reusing components from packages/ui and states from packages/core.

Step 1 — Provide the design
───────────────────────────
  Paste a screenshot of the full screen along with:
  • Screen name (e.g., "ProductDetail", "Settings")
  • Section breakdown (2-5 major UI sections)
  • Dynamic parts (API data, reactive state, user input)
  • Navigation targets (back, forward, deep links)

Step 2 — Generate screen structure
───────────────────────────────────
$folderTree

$fileResponsibilities

  Section rules:
$sectionRulesNote
  • Receive data via constructor parameters
  • Reuse packages/ui widgets
  • Translations via AppLocalizations.of(context)
  • Navigation callbacks passed from screen

  State management: $controllerTerm
  State pattern:    $statePattern
  DI pattern:       $diPattern
  Screen base:      $screenBase

Step 3 — Wire up routing
─────────────────────────
$routingInstructions

Step 4 — Add localization strings
──────────────────────────────────
  Add to packages/l10n/lib/l10n/arb/app_en.arb (and other locales)
  Run: flutter gen-l10n

Step 5 — Write tests (during development, not after)
─────────────────────────────────────────────────────
$testFileNote
    Test: initial state, state transitions after API calls,
    error handling, companion state wiring

Step 6 — Verify
────────────────
  Run: dart analyze && flutter test

Checklist
─────────
  [ ] $controllerTerm handles all state — sections are stateless
  [ ] Screen file under ~80 lines (assembly only)
  [ ] Each section is a separate file
  [ ] Sections reuse packages/ui widgets
  [ ] No hardcoded strings — all from AppLocalizations
  [ ] All locale strings added to ARB files
  [ ] Route registered ($routingStep)
  [ ] Dependencies properly injected ($diPattern)
  [ ] Responsive + RTL-safe layout
  [ ] Test in <app>/test/screens/<name>/

AI Agent Skill
──────────────
  This workflow is automated by the screen-design skill.
  See .claude/skills/screen-design/SKILL.md
''');
  }

  void _printScreenFlowGeneric() {
    stdout.writeln('''

╔══════════════════════════════════════════════════╗
║  Workflow B — Screen Design Flow                 ║
╚══════════════════════════════════════════════════╝

  (Run from inside a generated project for tailored instructions.)

Goal: Turn a full screen design into a screen with state management,
split into readable sections, reusing components from packages/ui.

Step 1 — Provide the design
───────────────────────────
  Paste a screenshot of the full screen along with:
  • Screen name (e.g., "ProductDetail", "Settings")
  • Section breakdown (2-5 major UI sections)
  • Dynamic parts (API data, reactive state, user input)
  • Navigation targets (back, forward, deep links)

Step 2 — Framework comparison
──────────────────────────────

  Framework   State Class         Screen Base       DI Pattern              Routing
  ─────────   ───────────         ───────────       ──────────              ───────
  GetX        GetxController      GetView           Binding + Get.lazyPut   GetPage in app_pages.dart
  Riverpod    Notifier            ConsumerWidget    Provider declarations   GoRoute in app_router.dart
  Bloc        Bloc + on<Event>    BlocBuilder       BlocProvider            GoRoute in app_router.dart
  Cubit       Cubit + emit()      BlocBuilder       BlocProvider            GoRoute in app_router.dart

Step 3 — Screen folder structure
─────────────────────────────────

  GetX:
  <app>/lib/screens/<name>/
  ├── <name>_controller.dart    # GetxController
  ├── <name>_binding.dart       # Bindings
  ├── <name>_screen.dart        # GetView
  └── sections/

  Riverpod:
  <app>/lib/screens/<name>/
  ├── <name>_provider.dart      # Notifier + provider
  ├── <name>_screen.dart        # ConsumerWidget
  └── sections/

  Bloc:
  <app>/lib/screens/<name>/
  ├── <name>_bloc.dart          # Bloc
  ├── <name>_event.dart         # Sealed events
  ├── <name>_state.dart         # Sealed states
  ├── <name>_screen.dart        # BlocBuilder
  └── sections/

  Cubit:
  <app>/lib/screens/<name>/
  ├── <name>_cubit.dart         # Cubit
  ├── <name>_state.dart         # States
  ├── <name>_screen.dart        # BlocBuilder
  └── sections/

  Section rules (all frameworks):
  • Sections are StatelessWidget — they do not own state
  • Receive data + callbacks via constructor parameters
  • Reuse packages/ui widgets wherever possible
  • Translations via AppLocalizations.of(context)

Step 4 — Add localization strings
──────────────────────────────────
  Add to packages/l10n/lib/l10n/arb/app_en.arb (and other locales)
  Run: flutter gen-l10n

Step 5 — Write tests (during development, not after)
─────────────────────────────────────────────────────
  Controller/provider/bloc test → <app>/test/screens/<name>/

Step 6 — Verify
────────────────
  Run: dart analyze && flutter test

AI Agent Skill
──────────────
  This workflow is automated by the screen-design skill.
  See .claude/skills/screen-design/SKILL.md
''');
  }

  // ── Workflow C — Business Logic ──────────────────────────

  void _printBusinessLogicFlow(ProjectConfig? config) {
    final sm = config?.stateManagement;

    // Framework-specific wiring step
    final String wiringTitle;
    final String wiringDesc;
    final String appFolderTree;

    switch (sm) {
      case StateManagement.getx:
        wiringTitle = 'Step 3 — Wire in the binding (dependency inversion)';
        wiringDesc = '''
  Controller depends on abstract interface (from core)
  Binding injects concrete implementation (from network)
  Swap implementation anytime without touching business logic

  Example:
  ─────────
  // <name>_binding.dart
  class ScreenBinding extends Bindings {
    void dependencies() {
      Get.lazyPut<OrderRepository>(() => OrderRepositoryImpl(Get.find()));
      Get.lazyPut(() => ScreenController(Get.find()));
    }
  }''';
        appFolderTree = '''
  <app>/lib/screens/<name>/       GETX WIRING
  ├── <name>_controller.dart      Uses rules + repository interface
  └── <name>_binding.dart         Injects network impl into core interface''';

      case StateManagement.riverpod:
        wiringTitle = 'Step 3 — Wire with providers (dependency inversion)';
        wiringDesc = '''
  Provider declarations connect the abstract interface to implementation.
  Swap implementation anytime without touching business logic.

  Example:
  ─────────
  // <name>_provider.dart
  final orderRepoProvider = Provider<OrderRepository>(
    (ref) => OrderRepositoryImpl(ref.read(apiClientProvider)),
  );
  final screenNotifierProvider = NotifierProvider<ScreenNotifier, ScreenState>(
    ScreenNotifier.new,
  );''';
        appFolderTree = '''
  <app>/lib/screens/<name>/       RIVERPOD WIRING
  └── <name>_provider.dart        Notifier + provider, uses repo interface''';

      case StateManagement.bloc:
        wiringTitle = 'Step 3 — Wire with BlocProvider (dependency inversion)';
        wiringDesc = '''
  RepositoryProvider + BlocProvider wire the interface to implementation.
  Swap implementation anytime without touching business logic.

  Example:
  ─────────
  // In router or parent widget
  RepositoryProvider<OrderRepository>(
    create: (_) => OrderRepositoryImpl(apiClient),
    child: BlocProvider(
      create: (ctx) => ScreenBloc(ctx.read<OrderRepository>()),
      child: const ScreenView(),
    ),
  )''';
        appFolderTree = '''
  <app>/lib/screens/<name>/       BLOC WIRING
  ├── <name>_bloc.dart            Bloc with on<Event> handlers
  ├── <name>_event.dart           Sealed event classes
  └── <name>_state.dart           Sealed state classes''';

      case StateManagement.cubit:
        wiringTitle = 'Step 3 — Wire with BlocProvider (dependency inversion)';
        wiringDesc = '''
  RepositoryProvider + BlocProvider wire the interface to implementation.
  Swap implementation anytime without touching business logic.

  Example:
  ─────────
  // In router or parent widget
  RepositoryProvider<OrderRepository>(
    create: (_) => OrderRepositoryImpl(apiClient),
    child: BlocProvider(
      create: (ctx) => ScreenCubit(ctx.read<OrderRepository>()),
      child: const ScreenView(),
    ),
  )''';
        appFolderTree = '''
  <app>/lib/screens/<name>/       CUBIT WIRING
  ├── <name>_cubit.dart           Cubit with emit() methods
  └── <name>_state.dart           State classes''';

      case null:
        wiringTitle = 'Step 3 — Wire the dependency injection';
        wiringDesc = '''
  Controller/provider/bloc depends on abstract interface (from core).
  The DI layer injects the concrete implementation (from network).
  Swap implementation anytime without touching business logic.

  GetX:      Binding with Get.lazyPut() injects impl
  Riverpod:  Provider declarations connect interface to impl
  Bloc/Cubit: RepositoryProvider + BlocProvider at route level''';
        appFolderTree = '''
  <app>/lib/screens/<name>/       FRAMEWORK WIRING
  ├── <name>_controller.dart      GetX: uses rules + repository interface
  ├── <name>_binding.dart         GetX: injects network impl
  ├── <name>_provider.dart        Riverpod: notifier + provider
  ├── <name>_bloc.dart            Bloc: event handlers
  └── <name>_cubit.dart           Cubit: emit methods''';
    }

    final frameworkLabel = sm != null ? ' (${sm.name})' : '';

    stdout.writeln('''

╔══════════════════════════════════════════════════╗
║  Workflow C — Business Logic Flow$frameworkLabel${' ' * (16 - frameworkLabel.length)}║
╚══════════════════════════════════════════════════╝

Goal: Turn business rules into testable, framework-agnostic logic
in packages/core, with API implementation in packages/network,
wired together in the app layer.

Step 1 — Provide the business rules
────────────────────────────────────
  Paste the business rules along with:
  • Feature name (e.g., "Discount Rules", "User Verification")
  • Inputs and outputs
  • Edge cases / exceptions
  • Which parts involve API calls vs pure logic

Step 2 — Generate the layers
─────────────────────────────

  packages/core/lib/              PURE LOGIC (no framework, no API)
  ├── models/                     Entities, enums, value objects
  ├── rules/                      Pure business logic functions
  └── repositories/               Abstract interface (WHAT, not HOW)

  packages/network/lib/           API IMPLEMENTATION
  └── repositories/               Implements core interfaces

$appFolderTree

  The Business Firewall:
  ┌─────────────────────────────────────────────────┐
  │  packages/core/ — PURE DART                      │
  │  • No Flutter, no framework imports, no HTTP     │
  │  • Rules are plain functions or classes           │
  │  • Repository interfaces define WHAT, not HOW    │
  │  • Unit testable with zero mocking               │
  │  • Swapping API provider = change network/ only  │
  │  • Swapping state mgmt = change app/ only        │
  └─────────────────────────────────────────────────┘

$wiringTitle
────────────────────────────────────────────────────
$wiringDesc

Step 4 — Write tests (during development, not after)
─────────────────────────────────────────────────────
  Rule tests → packages/core/test/rules/
    Test: every input/output combination, edge cases, boundaries
    Pure Dart — zero mocking needed

  Model tests → packages/core/test/models/
    Test: fromJson/toJson round-trip, equality, edge values

Step 5 — Verify
────────────────
  Run: dart analyze && dart test

Checklist
─────────
  [ ] Business rules in packages/core/rules/ — pure Dart
  [ ] Models in packages/core/models/ — plain data classes
  [ ] Repo interface in packages/core/repositories/ — abstract only
  [ ] Repo implementation in packages/network/repositories/ — API calls
  [ ] Controller/provider/bloc depends on interface, not implementation
  [ ] DI layer injects the concrete implementation
  [ ] Rules are unit testable without mocking
  [ ] Swapping API = changes only in packages/network/
  [ ] All exports updated in barrel files
  [ ] Rule tests in packages/core/test/rules/
  [ ] Model tests in packages/core/test/models/

AI Agent Skill
──────────────
  This workflow is automated by the business-logic skill.
  See .claude/skills/business-logic/SKILL.md
''');
  }
}
