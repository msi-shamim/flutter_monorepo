import 'dart:io';

/// Displays development workflow guides for the generated monorepo.
///
/// Workflows:
/// - `a` — Component Design Flow (widget + companion state)
/// - `b` — Screen Design Flow (GetX/Riverpod/Bloc screen)
/// - `c` — Business Logic Flow (core + network + app wiring)
class Workflow {
  /// Shows the requested workflow. Pass `null` to show the overview.
  void run(String? flow) {
    switch (flow?.toLowerCase()) {
      case 'a':
        _printComponentFlow();
      case 'b':
        _printScreenFlow();
      case 'c':
        _printBusinessLogicFlow();
      default:
        _printOverview();
    }
  }

  void _printOverview() {
    stdout.writeln('''

╔══════════════════════════════════════════════════╗
║  Flutter Monorepo — Development Workflows        ║
╚══════════════════════════════════════════════════╝

Three workflows cover everything you'll build:

  A. Component Design Flow
     Figma component → reusable widget + companion state
     Run: flutter_monorepo workflow a

  B. Screen Design Flow
     Figma screen → controller + binding + screen + sections
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
  Controller / provider    → <app>/lib/app/controllers/ (or providers/ or blocs/)
  Route definition         → <app>/lib/app/routes/
  Route guard / middleware → <app>/lib/app/middleware/
  DI binding               → <app>/lib/app/bindings/
''');
  }

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
''');
  }

  void _printScreenFlow() {
    stdout.writeln('''

╔══════════════════════════════════════════════════╗
║  Workflow B — Screen Design Flow                 ║
╚══════════════════════════════════════════════════╝

Goal: Turn a full screen design into a controller + screen + sections,
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
  <app>/lib/screens/<name>/
  ├── <name>_controller.dart    # State + logic (~100-150 lines)
  ├── <name>_binding.dart       # DI setup (~15-25 lines)
  ├── <name>_screen.dart        # Assembles sections (~50-80 lines)
  └── sections/                 # Major UI sections
      ├── header_section.dart
      ├── content_section.dart
      └── footer_section.dart

  File responsibilities:
  ─────────────────────
  Controller  → Reactive state (.obs), API calls, uses companion states
  Binding     → Get.lazyPut() for controller + dependencies
  Screen      → GetView<Controller>, assembles sections in Scaffold
  Sections    → StatelessWidget, receive data + callbacks via params

  Section rules:
  • Stateless (not GetView) — controller owns the state
  • Receive data via constructor parameters
  • Reuse packages/ui widgets
  • Translations via AppLocalizations.of(context)
  • Navigation callbacks passed from screen

Step 3 — Wire up routing
─────────────────────────
  Add route constant in app/routes/app_routes.dart
  Register GetPage in app/routes/app_pages.dart

Step 4 — Add localization strings
──────────────────────────────────
  Add to packages/l10n/lib/l10n/arb/app_en.arb (and other locales)
  Run: flutter gen-l10n

Step 5 — Write tests (during development, not after)
─────────────────────────────────────────────────────
  Controller test → <app>/test/screens/<name>/
    Test: initial state, state transitions after API calls,
    error handling, companion state wiring

Step 6 — Verify
────────────────
  Run: dart analyze && flutter test

Checklist
─────────
  [ ] Controller handles all state — sections are stateless
  [ ] Screen file under ~80 lines (assembly only)
  [ ] Each section is a separate file
  [ ] Sections reuse packages/ui widgets
  [ ] No hardcoded strings — all from AppLocalizations
  [ ] All locale strings added to ARB files
  [ ] Route registered
  [ ] Binding registers controller and dependencies
  [ ] Responsive + RTL-safe layout
  [ ] Controller test in <app>/test/screens/<name>/
''');
  }

  void _printBusinessLogicFlow() {
    stdout.writeln('''

╔══════════════════════════════════════════════════╗
║  Workflow C — Business Logic Flow                ║
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

  <app>/lib/screens/<name>/       FRAMEWORK WIRING
  ├── <name>_controller.dart      Uses rules + repository interface
  └── <name>_binding.dart         Injects network impl into core interface

  The Business Firewall:
  ┌─────────────────────────────────────────────────┐
  │  packages/core/ — PURE DART                      │
  │  • No Flutter, no GetX, no HTTP                  │
  │  • Rules are plain functions or classes           │
  │  • Repository interfaces define WHAT, not HOW    │
  │  • Unit testable with zero mocking               │
  │  • Swapping API provider = change network/ only  │
  │  • Swapping state mgmt = change app/ only        │
  └─────────────────────────────────────────────────┘

Step 3 — Wire in the binding (dependency inversion)
────────────────────────────────────────────────────
  Controller depends on abstract interface (from core)
  Binding injects concrete implementation (from network)
  Swap implementation anytime without touching business logic

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
  [ ] Controller depends on interface, not implementation
  [ ] Binding injects the concrete implementation
  [ ] Rules are unit testable without mocking
  [ ] Swapping API = changes only in packages/network/
  [ ] All exports updated in barrel files
  [ ] Rule tests in packages/core/test/rules/
  [ ] Model tests in packages/core/test/models/
''');
  }
}
